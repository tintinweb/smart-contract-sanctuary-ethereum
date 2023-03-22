/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FutuerHere {

    mapping(address => mapping(address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);


    function approveWithSignature(address spender, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, spender, address(this)));
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == msg.sender, "Invalid signature");

        allowances[msg.sender][spender] = type(uint256).max;

        emit Approval(msg.sender, spender, type(uint256).max);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(allowances[from][msg.sender] >= value, "Allowance insufficient");

        allowances[from][msg.sender] -= value;

        emit Transfer(from, to, value);
    }
}