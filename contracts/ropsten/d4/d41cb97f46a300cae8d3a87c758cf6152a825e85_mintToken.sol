/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract mintToken{
    address public owner;
    mapping (address => uint256) public owners;

    constructor () {
        owner = msg.sender;
        owners[owner] = 123;
    }
    function _isOwner(address ownerAddress) private {
        require(msg.sender == ownerAddress);
    }

    function getBalance() public returns (uint256) {
        return owners[msg.sender];
    }

}