/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.8.0;


contract BettingPool {
    uint256 poolA;
    uint256 poolB;

    address owner;

    mapping(address => uint256) public poolBalancesA;
    mapping(address => uint256) public poolBalancesB;

    constructor () {
        owner = msg.sender;
    }

    function depositToA(uint256 amount) public payable {
        require(amount == msg.value, "Amount deposited does not equal message value");
        poolBalancesA[msg.sender] += amount;
        poolA += amount;
    }

    function amountInPoolA(address a) public view returns (uint256) {
        return poolBalancesA[a];
    }

    function depositToB(uint256 amount) public payable {
        require(amount == msg.value, "Amount deposited does not equal message value");
        poolBalancesB[msg.sender] += amount;
        poolB += amount;
    }

    function getPoolA() public view returns (uint256) {
        return poolA;
    }

    function getPoolB() public view returns (uint256) {
        return poolB;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    //SHOULD NOT BE IMPLEMENTED -> JUST TO PREVENT USING A FAUCET AND TO STOP ETH BEING LOCKED IN CONTRACT
    //WORKAROUND -> USE CUSTOM ERC20 TOKEN
    function withdrawToOwner(uint256 amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        require((poolA + poolB) <= address(this).balance, "Something has gone terribly wrong");
        require(amount < address(this).balance - 1, "Need ether for gas calls");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "transer call gone wrong");
        poolA = 0;
        poolB = 0;

    }


}