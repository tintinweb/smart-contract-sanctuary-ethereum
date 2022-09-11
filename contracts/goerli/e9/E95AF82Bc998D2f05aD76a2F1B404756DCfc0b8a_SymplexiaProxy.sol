// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./TransparentUpgradeableProxy.sol";


contract SymplexiaProxy is TransparentUpgradeableProxy {

    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) { }

}