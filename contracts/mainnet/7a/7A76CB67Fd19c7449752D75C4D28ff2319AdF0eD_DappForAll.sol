//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


contract DappForAll {

    address public ownerAddress;
    constructor(){
        ownerAddress = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == ownerAddress, "You must be the owner of the contract");
        _;
    }
    function getBalance() public view returns (uint256){
        return payable(address(this)).balance;
    }
    function withdrawMoney() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        
    }
    function depositEth() public payable {
         require(msg.value > 0, "Amount must greater than zero");
          //it will send the ethers to smart contract 
    }

}