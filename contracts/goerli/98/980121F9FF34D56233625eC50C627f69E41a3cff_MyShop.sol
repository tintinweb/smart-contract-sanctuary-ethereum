/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract MyShop {
    // 0x980121F9FF34D56233625eC50C627f69E41a3cff
    address public owner; 
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    } 
    function payForItem() public payable {
        payments[msg.sender] = msg.value;
    }
    function withdrawALL() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}