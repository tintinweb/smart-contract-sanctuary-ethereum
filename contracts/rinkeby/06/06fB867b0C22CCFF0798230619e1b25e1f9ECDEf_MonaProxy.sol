// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1967Proxy.sol";

contract MonaProxy is ERC1967Proxy {

    constructor (address _logic) ERC1967Proxy(_logic, "") {}
}