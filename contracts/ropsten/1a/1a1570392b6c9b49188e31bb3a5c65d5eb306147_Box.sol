// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";


contract Box is Initializable, OwnableUpgradeable, UUPSUpgradeable {  
    
    uint public val;
    function initialize() external {
        val=777;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

}