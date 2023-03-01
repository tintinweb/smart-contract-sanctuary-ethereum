// SPDX-License-Identifier: GPL-3.0                                                                                                                                                                                                                                                          
pragma solidity ^0.8.7;

import "./ERC1967Proxy.sol";

contract TradingPunk is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic) payable ERC1967Proxy(_logic, bytes("")) {}
    function implementation() public view returns (address) {
        return _implementation();
    }
}