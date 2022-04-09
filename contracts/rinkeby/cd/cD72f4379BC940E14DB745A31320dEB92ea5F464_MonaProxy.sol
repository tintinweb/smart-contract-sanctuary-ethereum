// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1967Proxy.sol";

contract MonaProxy is ERC1967Proxy {

    constructor () ERC1967Proxy(0xceD548551EB75F8b7cCC472b7228E69EeE7163fe, "") {}
}