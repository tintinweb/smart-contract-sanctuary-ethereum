// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract FloodReliefFunds{

    uint256 totalTransferAmount;
    mapping (address => uint256) public transferRecords;
    address receiverAddress = 0x0AD54A4f010ED0C86F3716D178EC3a4CFB619Bab;

    constructor(){
    }

    function whyThis() public pure returns (string memory){
          return "Flood relief program has started to make peoples happier";
    }

    function sendFunds() public payable  {
        transferRecords[msg.sender] += msg.value;
        payable(receiverAddress).transfer(msg.value);
    }

    function viewTransferAmount() public view returns (uint256){
        return transferRecords[msg.sender];
    }

    function totalFundedAmount() public view returns(uint256){
        return msg.sender.balance;
    }

}