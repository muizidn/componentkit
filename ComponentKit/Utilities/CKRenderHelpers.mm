/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderHelpers.h"

#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKMutex.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeWithChild.h>
#import <ComponentKit/CKTreeNodeWithChildren.h>

#import "CKScopeTreeNode.h"
#import "CKRenderTreeNode.h"

namespace CKRenderInternal {

  namespace ScopeEvents {

    // Render nodes is on, only in case comopnents as a tree is off.
    static auto userRenderNodes(const CKBuildComponentTreeParams &params) {
      return !params.unifyComponentTreeConfig.useComponentsAsTheTree;
    }

    static auto willBuildComponentTree(id<CKTreeNodeProtocol> node, const CKBuildComponentTreeParams &params) {
      // Update the scope frame of the reuse of this component in order to transfer the render scope frame.
      // When `useRenderNodes` is on , the base constructor of the `CKRenderTreeNode` will push itself to the stack.
      if (!userRenderNodes(params)) {
        [CKScopeTreeNode willBuildComponentTreeWithTreeNode:node];
      }
    }

    static auto didBuildComponentTree(id<CKTreeNodeProtocol> node, const CKBuildComponentTreeParams &params) {
      if (userRenderNodes(params)) {
        [CKRenderTreeNode didBuildComponentTreeWithNode:node];
      } else {
        [CKScopeTreeNode didBuildComponentTreeWithNode:node];
      }
    }

    static auto didReuseNode(id<CKTreeNodeWithChildProtocol> node,
                             id<CKTreeNodeWithChildProtocol> previousNode,
                             const CKBuildComponentTreeParams &params) {
      // Update the scope frame of the reuse of this component in order to transfer the render scope frame.
      if (userRenderNodes(params)) {
        [(CKRenderTreeNode *)node didReuseNode:(CKRenderTreeNode *)previousNode];
      } else {
        [CKScopeTreeNode didReuseRenderWithTreeNode:node];
      }
    }
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     id<CKTreeNodeWithChildProtocol> node,
                                     id<CKTreeNodeWithChildProtocol> previousNode,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> void {
    auto const reusedChild = previousNode.child;
    // Set the child from the previous tree node.
    node.child = reusedChild;
    // Save the reused node in the scope root for the next component creation.
    [reusedChild didReuseInScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
    // Update the new parent in the new scope root
    params.scopeRoot.rootNode.registerNode(reusedChild, node);

    // Update the scope frame of the reuse of this node.
    ScopeEvents::didReuseNode(node, previousNode, params);

    auto const prevChildComponent = [(id<CKTreeNodeWithChildProtocol>)previousNode child].component;

    if (childComponent != nullptr) {
      // Link the previous child component to the the new component.
      *childComponent = prevChildComponent;
    }

    auto const previousComponent = (id<CKRenderComponentProtocol>)previousNode.component;
    if (didReuseBlock) {
      didReuseBlock(previousComponent);
    }
    // Notify the new component about the reuse of the previous component.
    [component didReuseComponent:previousComponent];

    // Notify scope root listener
    [params.scopeRoot.analyticsListener didReuseNode:node inScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKTreeNodeWithChild *node,
                                     id<CKTreeNodeWithChildrenProtocol> parent,
                                     id<CKTreeNodeWithChildrenProtocol> previousParent,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    if (previousNode) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params, didReuseBlock);
      return YES;
    }
    return NO;
  }

  // Check if shouldComponentUpdate returns `NO`; if it does, reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponentIfComponentsAreEqual(id<CKRenderComponentProtocol> component,
                                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                         CKTreeNodeWithChild *node,
                                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                         const CKBuildComponentTreeParams &params,
                                                         CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    auto const previousComponent = (id<CKRenderComponentProtocol>)previousNode.component;
    // If there is no previous compononet, there is nothing to reuse.
    if (previousComponent) {
      // We check if the component node is dirty in the **previous** scope root.
      auto const dirtyNodeIdsForPropsUpdates = params.previousScopeRoot.rootNode.dirtyNodeIdsForPropsUpdates();
      auto const dirtyNodeId = dirtyNodeIdsForPropsUpdates.find(node.nodeIdentifier);
      if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
        [params.systraceListener willCheckShouldComponentUpdate:component];
        auto const shouldComponentUpdate = [component shouldComponentUpdate:previousComponent];
        [params.systraceListener didCheckShouldComponentUpdate:component];
        if (!shouldComponentUpdate) {
          CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params, didReuseBlock);
          return YES;
        }
      }
    }
    return NO;
  }

  static auto reusePreviousComponentForSingleChild(CKTreeNodeWithChild *node,
                                                   id<CKRenderWithChildComponentProtocol> component,
                                                   __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                   id<CKTreeNodeWithChildrenProtocol> parent,
                                                   id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                   const CKBuildComponentTreeParams &params,
                                                   BOOL parentHasStateUpdate,
                                                   CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {

    // If there is no previous parent or no childComponent, we bail early.
    if (previousParent == nil || childComponent == nullptr) {
      return NO;
    }

    // Check if the reuse components optimizations are off.
    if (params.ignoreComponentReuseOptimizations) {
      return NO;
    }

    // State update branch:
    if (params.buildTrigger == CKBuildTrigger::StateUpdate) {
      // Check if the tree node is not dirty (not in a branch of a state update).
      auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
      if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
        // We reuse the component without checking `shouldComponentUpdate:` in the following conditions:
        // 1. The component is not dirty (on a state update branch)
        // 2. No direct parent has a state update
        if (!parentHasStateUpdate) {
          // Faster state update optimizations.
          return CKRenderInternal::reusePreviousComponent(component, childComponent, node, parent, previousParent, params, didReuseBlock);
        }
        // We fallback to the props update optimization in the follwing case:
        // - The component is not dirty, but the parent has a state update.
        return (CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params, didReuseBlock));
      }
    }
    // Props update branch:
    else if (params.buildTrigger == CKBuildTrigger::PropsUpdate) {
      return CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params, didReuseBlock);
    }

    return NO;
  }

  static auto willBuildComponentTreeWithChild(id<CKTreeNodeProtocol> node,
                                              id<CKTreeNodeComponentProtocol> component,
                                              const CKBuildComponentTreeParams &params) -> void {
    // Context support
    CKComponentContextHelper::willBuildComponentTree(component);

    // Faster Props updates and context support
    params.scopeRoot.rootNode.willBuildComponentTree(node);

    // Systrace logging
    [params.systraceListener willBuildComponent:component.class];
  }

  static auto didBuildComponentTreeWithChild(id<CKTreeNodeProtocol> node,
                                             id<CKTreeNodeComponentProtocol> component,
                                             const CKBuildComponentTreeParams &params) -> void {
    // Context support
    CKComponentContextHelper::didBuildComponentTree(component);

    // Props updates and context support
    params.scopeRoot.rootNode.didBuildComponentTree(node);

    // Systrace logging
    [params.systraceListener didBuildComponent:component.class];
  }

}

namespace CKRender {
  namespace ComponentTree {
    namespace NonRender {
      auto build(id<CKTreeNodeComponentProtocol> component,
                 id<CKTreeNodeComponentProtocol> childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate) -> void
      {
        CKCAssert(component, @"component cannot be nil");

        id<CKTreeNodeProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
        } else {
          // Check if the component already have tree node (Tree Unification Mode).
          node = component.scopeHandle.treeNode;
        }

        if (node) {
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKTreeNodeWithChild alloc]
                  initWithComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

        // Report information to `debugAnalyticsListener`.
        if (params.shouldCollectTreeNodeCreationInformation) {
          [params.scopeRoot.analyticsListener didBuildTreeNodeForPrecomputedChild:component
                                                                             node:node
                                                                           parent:parent
                                                                           params:params
                                                             parentHasStateUpdate:parentHasStateUpdate];
        }

        if (childComponent) {
          [childComponent buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)node
                              previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                      params:params
                        parentHasStateUpdate:parentHasStateUpdate];
        }
      }

      auto buildWithChildren(id<CKTreeNodeComponentProtocol> component,
                             std::vector<id<CKTreeNodeComponentProtocol>> childrenComponents,
                             id<CKTreeNodeWithChildrenProtocol> parent,
                             id<CKTreeNodeWithChildrenProtocol> previousParent,
                             const CKBuildComponentTreeParams &params,
                             BOOL parentHasStateUpdate) -> void
      {
        CKCAssert(component, @"component cannot be nil");
        id<CKTreeNodeProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
        } else {
          // Check if the component already have tree node (Tree Unification Mode).
          node = component.scopeHandle.treeNode;
        }

        if (node) {
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKTreeNodeWithChildren alloc]
                  initWithComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

        for (auto const childComponent : childrenComponents) {
          if (childComponent) {
            [childComponent buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)node
                                previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                        params:params
                          parentHasStateUpdate:parentHasStateUpdate];
          }
        }
      }
    }

    namespace RenderLayout {
      auto build(id<CKRenderWithChildComponentProtocol> component,
                 __strong id<CKTreeNodeComponentProtocol> *childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate) -> id<CKTreeNodeProtocol>
      {
        CKCAssert(component, @"component cannot be nil");
        id<CKTreeNodeWithChildrenProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
        } else {
          // Check if the component already have tree node (Tree Unification Mode).
          node = (id<CKTreeNodeWithChildrenProtocol>)component.scopeHandle.treeNode;
        }

        if (node) {
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKTreeNodeWithChild alloc]
                  initWithRenderComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

        auto const child = [component render:node.state];
        if (child) {
          if (childComponent != nullptr) {
            // Set the link between the parent to its child.
            *childComponent = child;
          }
          // Call build component tree on the child component.
          [child buildComponentTree:node
                     previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                             params:params
               parentHasStateUpdate:parentHasStateUpdate];
        }

        return node;
      }

      auto buildWithChildren(id<CKRenderWithChildrenComponentProtocol> component,
                             std::vector<id<CKTreeNodeComponentProtocol>> *childrenComponents,
                             id<CKTreeNodeWithChildrenProtocol> parent,
                             id<CKTreeNodeWithChildrenProtocol> previousParent,
                             const CKBuildComponentTreeParams &params,
                             BOOL parentHasStateUpdate) -> id<CKTreeNodeProtocol>
      {
        id<CKTreeNodeWithChildrenProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
        } else {
          // Check if the component already have tree node (Tree Unification Mode).
          node = (id<CKTreeNodeWithChildrenProtocol>)component.scopeHandle.treeNode;
        }

        if (node) {
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKTreeNodeWithChildren alloc]
                  initWithRenderComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

        auto const children = [component renderChildren:node.state];
        if (childrenComponents != nullptr) {
          *childrenComponents = children;
        }
        auto const previousParentForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]];
        for (auto const child : children) {
          if (child) {
            [child buildComponentTree:node
                       previousParent:previousParentForChild
                               params:params
                 parentHasStateUpdate:parentHasStateUpdate];
          }
        }

        return node;
      }
    }

    namespace Render {
      auto build(id<CKRenderWithChildComponentProtocol> component,
                 __strong id<CKTreeNodeComponentProtocol> *childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate,
                 CKRenderDidReuseComponentBlock didReuseBlock) -> id<CKTreeNodeProtocol>
      {
        CKCAssert(component, @"component cannot be nil");
        id<CKTreeNodeWithChildrenProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKRenderTreeNode alloc]
                  initWithRenderComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }

        CKRenderInternal::willBuildComponentTreeWithChild(node, component, params);

        // Faster state/props optimizations require previous parent.
        if (CKRenderInternal::reusePreviousComponentForSingleChild((id<CKTreeNodeWithChildProtocol>)node, component, childComponent, parent, previousParent, params, parentHasStateUpdate, didReuseBlock)) {
          CKRenderInternal::didBuildComponentTreeWithChild(node, component, params);
          return node;
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

        CKRenderInternal::ScopeEvents::willBuildComponentTree(node, params);

        auto const child = [component render:node.state];
        if (child) {
          if (childComponent != nullptr) {
            // Set the link between the parent to its child.
            *childComponent = child;
          }
          // Call build component tree on the child component.
          [child buildComponentTree:node
                     previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                             params:params
               parentHasStateUpdate:parentHasStateUpdate];
        }

        CKRenderInternal::ScopeEvents::didBuildComponentTree(node, params);
        CKRenderInternal::didBuildComponentTreeWithChild(node, component, params);

        return node;
      }
    }

    namespace Leaf {
      auto build(id<CKTreeNodeComponentProtocol> component,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params) -> void {
        id<CKTreeNodeProtocol> node;
        if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
          // Use the component as the node.
          node = component;
        } else {
          node = component.scopeHandle.treeNode;
        }

        if (node) {
          [node linkComponent:component toParent:parent previousParent:previousParent params:params];
        } else {
          node = [[CKTreeNode alloc]
                  initWithComponent:component
                  parent:parent
                  previousParent:previousParent
                  scopeRoot:params.scopeRoot
                  stateUpdates:params.stateUpdates];
        }
      }
    }
    namespace Root {
      auto build(id<CKTreeNodeComponentProtocol> component, const CKBuildComponentTreeParams &params) -> void {
        auto const rootNode = params.scopeRoot.rootNode.node();

        if (component) {
          // Build the component tree from the render function.
          [component buildComponentTree:rootNode
                         previousParent:params.previousScopeRoot.rootNode.node()
                                 params:params
                   parentHasStateUpdate:NO];

          // Link the root component to the root node.
          if (params.unifyComponentTreeConfig.useComponentsAsTheTree) {
            [rootNode setChild:component forComponentKey:component.componentKey];
          }
        }
      }
    }
  }

  namespace ScopeHandle {
    namespace Render {
      auto create(id<CKRenderComponentProtocol> component,
                  Class componentClass,
                  id<CKTreeNodeProtocol> previousNode,
                  CKComponentScopeRoot *scopeRoot,
                  const CKComponentStateUpdateMap &stateUpdates) -> CKComponentScopeHandle*
      {
        CKComponentScopeHandle *scopeHandle;
        // If there is a previous node, we just duplicate the scope handle.
        if (previousNode) {
          scopeHandle = [previousNode.scopeHandle newHandleWithStateUpdates:stateUpdates
                                                         componentScopeRoot:scopeRoot];
        } else {
          // The component needs a scope handle in few cases:
          // 1. Has an initial state
          // 2. Has a controller
          // 3. Returns `YES` from `requiresScopeHandle`
          id initialState = [componentClass initialStateWithComponent:component];
          if (initialState != [CKTreeNodeEmptyState emptyState] ||
              [componentClass controllerClass] ||
              [componentClass requiresScopeHandle]) {
            scopeHandle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                            rootIdentifier:scopeRoot.globalIdentifier
                                                            componentClass:componentClass
                                                              initialState:initialState];
          }
        }

        // Finalize the node/scope regsitration.
        if (scopeHandle) {
          [component acquireScopeHandle:scopeHandle];
          [scopeRoot registerComponent:component];
          [scopeHandle resolve];
        }

        return scopeHandle;
      }
    }
  }

  auto componentHasStateUpdate(id<CKTreeNodeProtocol> node,
                               id<CKTreeNodeWithChildrenProtocol> previousParent,
                               const CKBuildComponentTreeParams &params) -> BOOL {
    if (previousParent && params.buildTrigger == CKBuildTrigger::StateUpdate) {
      auto const scopeHandle = node.scopeHandle;
      if (scopeHandle != nil) {
        auto const stateUpdateBlock = params.stateUpdates.find(scopeHandle);
        return stateUpdateBlock != params.stateUpdates.end();
      }
    }
    return NO;
  }

  auto markTreeNodeDirtyIdsFromNodeUntilRoot(CKTreeNodeIdentifier nodeIdentifier,
                                             CKRootTreeNode &previousRootNode,
                                             CKTreeNodeDirtyIds &treeNodesDirtyIds) -> void
  {
    CKTreeNodeIdentifier currentNodeIdentifier = nodeIdentifier;
    while (currentNodeIdentifier != 0) {
      auto const insertPair = treeNodesDirtyIds.insert(currentNodeIdentifier);
      // If we got to a node that is already in the set, we can stop as the path to the root is already dirty.
      if (insertPair.second == false) {
        break;
      }
      auto const parentNode = previousRootNode.parentForNodeIdentifier(currentNodeIdentifier);
      CKCAssert((parentNode || nodeIdentifier == currentNodeIdentifier),
                @"The next parent cannot be nil unless it's a root component.");
      currentNodeIdentifier = parentNode.nodeIdentifier;
    }
  }

  auto treeNodeDirtyIdsFor(CKComponentScopeRoot *previousRoot,
                           const CKComponentStateUpdateMap &stateUpdates,
                           const CKBuildTrigger &buildTrigger) -> CKTreeNodeDirtyIds
  {
    CKTreeNodeDirtyIds treeNodesDirtyIds;
    // Compute the dirtyNodeIds in case of a state update only.
    if (buildTrigger == CKBuildTrigger::StateUpdate) {
      for (auto const & stateUpdate : stateUpdates) {
        CKRender::markTreeNodeDirtyIdsFromNodeUntilRoot(stateUpdate.first.treeNodeIdentifier, previousRoot.rootNode, treeNodesDirtyIds);
      }
    }
    return treeNodesDirtyIds;
  }
}
