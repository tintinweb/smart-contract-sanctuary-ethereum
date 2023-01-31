// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./Clones.sol";

import "./IOwnableAccountWhitelist.sol";

/**
 * Factory that deploys `OwnableAccountWhitelist` contract clones by making use of minimal proxy
 *
 * Meant to be utility class for internal usage only
 */
contract OwnableAccountWhitelistFactory {
    address private immutable _ownableAccountWhitelistPrototype;

    constructor(address ownableAccountWhitelistPrototype_) {
        _ownableAccountWhitelistPrototype = ownableAccountWhitelistPrototype_;
    }

    function deployClone() external returns (address ownableAccountWhitelist) {
        ownableAccountWhitelist = Clones.clone(_ownableAccountWhitelistPrototype);
        IOwnableAccountWhitelist(ownableAccountWhitelist).initialize();
        IOwnableAccountWhitelist(ownableAccountWhitelist).transferOwnership(msg.sender);
    }
}