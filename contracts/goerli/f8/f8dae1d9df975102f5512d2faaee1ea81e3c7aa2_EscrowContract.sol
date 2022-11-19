/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// File: escrowcontract.sol

pragma solidity ^0.8.14;
contract EscrowContract {

    address public arbitor;
    address public Alice;
    address public Bob;
    uint contractTotal;
    uint depositedDate;

    constructor() {
        arbitor = msg.sender ;
    }

    modifier onlyArbitor{
        require (msg.sender == arbitor, "Not arbitor");
        _;
    }

    modifier onlyBob{
        require (msg.sender == Bob, "Not Bob");
        _;
    }

    function setUsers(address _Alice, address _Bob) public onlyArbitor{
        require (msg.sender == arbitor, "Not arbitor");
        Alice = _Alice;
        Bob = _Bob;
    }

    // user putting money into contract
    function deposit() public payable onlyArbitor {
        contractTotal = contractTotal + msg.value;
        depositedDate = block.timestamp;
    }

    // only Bob can withdraw
    function withdraw() public payable onlyBob{
        require (block.timestamp >= (depositedDate + 1 days), "Need to wait 1 day to withdraw");
        payable(Bob).transfer(address(this).balance);
        contractTotal = contractTotal - msg.value;
        
    }

    // return contract balance
    function balanceOfContract() public view returns (uint){
        return address(this).balance;
    }
}