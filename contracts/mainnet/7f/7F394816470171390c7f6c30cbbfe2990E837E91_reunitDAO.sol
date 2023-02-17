/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface manageToken {
    function balanceOf(address account) external view returns (uint256);
}

contract reunitDAO {
    address     public  OWNER;
    address[]   public  ALLOWED_TOKENS;

    constructor() {
        OWNER           =   msg.sender;
    }

    function balanceOf(address account) public view returns(uint256) {
        uint256 unified_balance;
        for (uint i=0; i<ALLOWED_TOKENS.length; i++) {
            unified_balance += manageToken(ALLOWED_TOKENS[i]).balanceOf(account);
        }
        return unified_balance;
    }

    function addToken(address token) public {
        require(msg.sender == OWNER, "You are not the owner");
        ALLOWED_TOKENS.push(token);
    }
}