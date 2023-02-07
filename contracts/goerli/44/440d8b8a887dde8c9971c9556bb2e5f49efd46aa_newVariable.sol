//SPDX-License-Identifier:MIT

pragma solidity 0.8.17;

import "./3-2_variableRegalia.sol";

contract newVariable is Variable {
    function set (uint256 num) public {
        number = num;
    } 
}