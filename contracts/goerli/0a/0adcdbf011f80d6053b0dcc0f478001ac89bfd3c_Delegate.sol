// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./Ownable.sol";

import "./TokenHelper.sol";
import "./NativeReceiver.sol";

import "./SimpleInitializable.sol";

import "./IWithdrawable.sol";
import "./Withdrawable.sol";

import "./IDelegate.sol";

contract Delegate is IDelegate, SimpleInitializable, Ownable, Withdrawable, NativeReceiver {
    constructor() {
        _initializeWithSender();
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }

    function setOwner(address newOwner_) external whenInitialized onlyInitializer {
        _transferOwnership(newOwner_);
    }

    function _checkWithdraw() internal view override {
        _ensureInitialized();
        _checkOwner();
    }
}