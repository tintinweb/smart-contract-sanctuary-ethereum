/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract ERC20 {
    event Transfer(address from, address to, uint noOfTokens);
    event Approval(address owner, address sender, uint noOfTokens);

    uint totalTokens;
    mapping(address => uint) public investorTokens;
    mapping(address => mapping(address => uint)) public approved;

    constructor(uint _totalTokens) {
        totalTokens = _totalTokens;
        investorTokens[msg.sender] = totalTokens;
    }

    modifier notNull(address addr) {
        require(addr != address(0), "Address null");
        _;
    }

    function getTotalSupply() external view returns(uint) {
        return(totalTokens);
    }

    function transfer(address to, uint noOfTokens) public notNull(to) {
        require(noOfTokens<= investorTokens[msg.sender] && noOfTokens > 0, "Not enough tokens");
        investorTokens[msg.sender] -= noOfTokens;
        investorTokens[to] += noOfTokens;

        emit Transfer(msg.sender, to, noOfTokens);
    }

    function approve(address spender, uint noOfTokens) public notNull(spender) {
        require(noOfTokens > 0 && noOfTokens <= investorTokens[msg.sender], "Not enough tokens");
        approved[msg.sender][spender] += noOfTokens;

        emit Approval(msg.sender, spender, noOfTokens);
    }

    function transferFrom(address from, address to, uint noOfTokens) public notNull(from) notNull(to) {
        require(approved[from][msg.sender] > 0, "Not enough tokens");
        require (noOfTokens > 0 && noOfTokens <= approved[from][msg.sender], "No. of tokens not allowed");
        investorTokens[from] -= noOfTokens;
        approved[from][msg.sender] -= noOfTokens;
        investorTokens[to] += noOfTokens;

        emit Transfer(msg.sender, to, noOfTokens);
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return(approved[owner][spender]);
    }

    function balance(address owner) public view returns(uint) {
        return (investorTokens[owner]);
    }

}