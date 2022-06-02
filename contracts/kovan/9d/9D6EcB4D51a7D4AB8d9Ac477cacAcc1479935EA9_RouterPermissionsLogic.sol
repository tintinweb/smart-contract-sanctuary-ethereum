// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/**
 * @notice Contains RouterPermissions related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 */
struct RouterPermissionsInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
}

library RouterPermissionsLogic {
  // ========== Custom Errors ===========
  error RouterPermissionsLogic__setRouterRecipient_notNewRecipient();
  error RouterPermissionsLogic__onlyRouterOwner_notRouterOwner();
  error RouterPermissionsLogic__removeRouter_routerEmpty();
  error RouterPermissionsLogic__removeRouter_notAdded();
  error RouterPermissionsLogic__setupRouter_routerEmpty();
  error RouterPermissionsLogic__setupRouter_amountIsZero();
  error RouterPermissionsLogic__setRouterOwner_notNewOwner();

  /**
   * @notice Emitted when a new router is added
   * @param router - The address of the added router
   * @param caller - The account that called the function
   */
  event RouterAdded(address indexed router, address caller);

  /**
   * @notice Emitted when an existing router is removed
   * @param router - The address of the removed router
   * @param caller - The account that called the function
   */
  event RouterRemoved(address indexed router, address caller);

  /**
   * @notice Emitted when the recipient of router is updated
   * @param router - The address of the added router
   * @param prevRecipient  - The address of the previous recipient of the router
   * @param newRecipient  - The address of the new recipient of the router
   */
  event RouterRecipientSet(address indexed router, address indexed prevRecipient, address indexed newRecipient);

  /**
   * @notice Emitted when the owner of router is accepted
   * @param router - The address of the added router
   * @param prevOwner  - The address of the previous owner of the router
   * @param newOwner  - The address of the new owner of the router
   */
  event RouterOwnerUpdated(address indexed router, address indexed prevOwner, address indexed newOwner);

  /**
   * @notice Asserts caller is the router owner (if set) or the router itself
   */
  function _onlyRouterOwner(address _router, address _owner) internal view {
    if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
      revert RouterPermissionsLogic__onlyRouterOwner_notRouterOwner();
  }

  // ============ Public methods =============

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(
    address router,
    address recipient,
    RouterPermissionsInfo storage routerInfo
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check recipient is changing
    address _prevRecipient = routerInfo.routerRecipients[router];
    if (_prevRecipient == recipient) revert RouterPermissionsLogic__setRouterRecipient_notNewRecipient();

    // Set new recipient
    routerInfo.routerRecipients[router] = recipient;

    // Emit event
    emit RouterRecipientSet(router, _prevRecipient, recipient);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param owner Owner Address to set to router
   */
  function setRouterOwner(
    address router,
    address owner,
    RouterPermissionsInfo storage routerInfo
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check that proposed is different than current owner
    if (_getRouterOwner(router, routerInfo.routerOwners) == owner)
      revert RouterPermissionsLogic__setRouterOwner_notNewOwner();

    // Emit event
    emit RouterOwnerUpdated(router, routerInfo.routerOwners[router], owner);

    // Update the current owner
    routerInfo.routerOwners[router] = owner;
  }

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function setupRouter(
    address router,
    address owner,
    address recipient,
    RouterPermissionsInfo storage routerInfo
  ) internal {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsLogic__setupRouter_routerEmpty();

    // Sanity check: needs approval
    if (routerInfo.approvedRouters[router]) revert RouterPermissionsLogic__setupRouter_amountIsZero();

    // Approve router
    routerInfo.approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);

    // Update routerOwner (zero address possible)
    if (owner != address(0)) {
      routerInfo.routerOwners[router] = owner;
      emit RouterOwnerUpdated(router, address(0), owner);
    }

    // Update router recipient
    if (recipient != address(0)) {
      routerInfo.routerRecipients[router] = recipient;
      emit RouterRecipientSet(router, address(0), recipient);
    }
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function removeRouter(address router, RouterPermissionsInfo storage routerInfo) external {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsLogic__removeRouter_routerEmpty();

    // Sanity check: needs removal
    if (!routerInfo.approvedRouters[router]) revert RouterPermissionsLogic__removeRouter_notAdded();

    // Update mapping
    routerInfo.approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);

    // Remove router owner
    address _owner = routerInfo.routerOwners[router];
    if (_owner != address(0)) {
      emit RouterOwnerUpdated(router, _owner, address(0));
      routerInfo.routerOwners[router] = address(0);
    }

    // Remove router recipient
    address _recipient = routerInfo.routerRecipients[router];
    if (_recipient != address(0)) {
      emit RouterRecipientSet(router, _recipient, address(0));
      routerInfo.routerRecipients[router] = address(0);
    }
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   */
  function _getRouterOwner(address router, mapping(address => address) storage _routerOwners)
    internal
    view
    returns (address)
  {
    address _owner = _routerOwners[router];
    return _owner == address(0) ? router : _owner;
  }
}