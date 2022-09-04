/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721 {

    function getAddresses(uint256 i) external view returns (address);
    function getTotalSupply() external view returns (uint256);

}

contract TaxingERC20 {
    event Transfer(address from, address to, uint256 noOfTokens);
    event Approval(address owner, address sender, uint256 noOfTokens);

    IERC721 erc721;
    uint256 noTokens;
    mapping(address => uint256) public investorTokens;
    mapping(address => mapping(address => uint256)) public approved;

    constructor(uint256 _totalTokens, address _erc721) {
        investorTokens[msg.sender] = _totalTokens;
        noTokens = _totalTokens;
        erc721 = IERC721(_erc721);
    }

    modifier notNull(address addr) {
        require(addr != address(0), "Address null");
        _;
    }

    function totalSupply() external view returns(uint256) {
        return(noTokens);
    }

    function transfer(address to, uint256 noOfTokens) public notNull(to) {
        require(balance(msg.sender) > noOfTokens, "not enough tokens");
        uint256 tax = noOfTokens/10;
        investorTokens[msg.sender] -= noOfTokens;
        investorTokens[to] += noOfTokens - tax;
        uint256 temp = erc721.getTotalSupply();
        uint256 taxPart = tax/temp;
        for (uint256 i=0; i<temp; i++) {
            investorTokens[erc721.getAddresses(i)] += taxPart;
        }
        emit Transfer(msg.sender, to, noOfTokens);
    }

    function approve(address spender, uint256 noOfTokens) public notNull(spender) {
        require(noOfTokens > 0 && noOfTokens <= investorTokens[msg.sender], "Not enough tokens");
        approved[msg.sender][spender] += noOfTokens;

        emit Approval(msg.sender, spender, noOfTokens);
    }

    function transferFrom(address from, address to, uint256 noOfTokens) public notNull(from) notNull(to) {
        require(approved[from][msg.sender] > 0, "Not enough tokens");
        require (noOfTokens > 0 && noOfTokens <= approved[from][msg.sender], "No. of tokens not allowed");
        uint256 tax = noOfTokens/10;
        investorTokens[from] -= noOfTokens;
        approved[from][msg.sender] -= noOfTokens;
        investorTokens[to] += noOfTokens - tax;
        uint256 temp = erc721.getTotalSupply();
        uint256 taxPart = tax/temp;
        for (uint256 i=0; i<temp; i++) {
            investorTokens[erc721.getAddresses(i)] += taxPart;
        }

        emit Transfer(msg.sender, to, noOfTokens);
    }

    function sendTax(uint256 _amount) internal {

    }

    function allowance(address owner, address spender) public view returns(uint256) {
        return(approved[owner][spender]);
    }

    function balance(address owner) public view returns(uint256) {
        return (investorTokens[owner]);
    }

}