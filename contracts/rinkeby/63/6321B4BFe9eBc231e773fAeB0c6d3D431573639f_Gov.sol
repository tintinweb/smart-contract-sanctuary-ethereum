// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Token {
    function transferOwnership(address newOwner) external;
}

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Gov {
   
    function changeOwner (address _contract, address _newOwner) public {
        Token(_contract).transferOwnership(_newOwner);
    }
 
}