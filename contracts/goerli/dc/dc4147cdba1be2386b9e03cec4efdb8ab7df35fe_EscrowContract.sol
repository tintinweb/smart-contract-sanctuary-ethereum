/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// File: file.sol

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

    function setUsers(address _Alice, address _Bob) public onlyArbitor{
        require (msg.sender == arbitor, "Not arbitor");
        Alice = _Alice;
        Bob = _Bob;
    }

    // user putting money into contract
    function deposit() public payable onlyArbitor {
        // payable(Alice).transfer(address(this).balance);
        payable(Alice).send(msg.value);
        contractTotal = contractTotal + msg.value;
        depositedDate = block.timestamp;
    }

    // user withdrawing money from contract
    function withdraw() public payable onlyArbitor {
    //    payable(buyer).send(address(this).balance);
        require (block.timestamp >= (depositedDate + 1 minutes), "Need to wait 1 day to withdraw");
        payable(Bob).send(address(this).balance);
        contractTotal = contractTotal - msg.value;
        
    }

    function balanceOfContract() public view returns (uint){
        return contractTotal;
    }
}