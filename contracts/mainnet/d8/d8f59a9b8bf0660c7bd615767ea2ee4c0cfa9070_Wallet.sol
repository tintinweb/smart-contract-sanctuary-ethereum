/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity 0.8.0;
pragma abicoder v2;

contract Ownable {

    address payable owner;
        
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }
}


contract Wallet is Ownable  {

    event AmountDeposited(address indexed from, uint amount);
    event AmountWithdrawn(address indexed to, uint amount);

    function deposit() external payable {
    
        emit AmountDeposited(msg.sender, msg.value);
    }

    function withdraw(uint amount, address destination) external onlyOwner {
        require(address(this).balance >= amount, "Not enough balance");

        uint ethAmount = (amount == 0) ? address(this).balance : amount;
        payable(destination).transfer(ethAmount);
             
        emit AmountWithdrawn(destination, ethAmount);
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }
}