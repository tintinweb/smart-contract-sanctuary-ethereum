/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract PaymentSplitterNew{
    address payable public adminAddress;
    address payable public recieverAddress;
    address payable public royaltyAddress;
    uint public adminPercentage;
    uint public royaltyPercentage;
 event TransferRecieved(address _from,uint amount);
    // constructor(address payable _adminAddress,address payable _recieverAddress){
        
    //     adminAddress= _adminAddress;
    //     recieverAddress= _recieverAddress;
    // }
    function setRoyaltyAddress(address payable _addrs) public {
        adminAddress=_addrs;
        
    }
    function setRecieverAddress(address payable _addrs) public {
        recieverAddress=_addrs;
        
    }
    function setPercentageRoyalty(uint _percent)public{
        adminPercentage=_percent;
    }

    function sendTransactionWithRoyalty(address payable _adminAddress,address payable _recieverAddress ,address payable _royaltyAddress, uint _percentAdmin, uint _percentRoyalty) payable public {
        adminAddress= _adminAddress;
        recieverAddress= _recieverAddress;
        royaltyAddress=_royaltyAddress;
        adminPercentage=_percentAdmin;
        uint256 totalShare=msg.value;
        uint256 adminShare= ((totalShare/100)*adminPercentage);
        uint256 royaltyShare= ((totalShare/100)*_percentRoyalty);
        uint256 recieverShare = ((totalShare-adminShare)-royaltyShare);
        adminAddress.transfer(adminShare);
        recieverAddress.transfer(recieverShare);
        royaltyAddress.transfer(royaltyShare);
         emit TransferRecieved(msg.sender,msg.value);
    }
     function sendTransactionWithoutRoyalty(address payable _adminAddress,address payable _recieverAddress , uint _percentAdmin) payable public {
        adminAddress= _adminAddress;
        recieverAddress= _recieverAddress;
        adminPercentage=_percentAdmin;
        uint256 totalShare=msg.value;
        uint256 adminShare= ((totalShare/100)*adminPercentage);
        uint256 recieverShare = totalShare-adminShare;
        adminAddress.transfer(adminShare);
        recieverAddress.transfer(recieverShare);
         emit TransferRecieved(msg.sender,msg.value);
    }
    receive() payable external {
        //percentage=msg.value;
       // uint256 totalShare=msg.value;
        //uint256 adminShare= ((totalShare/100)*percentage);
        //uint256 recieverShare = totalShare-adminShare;
        //adminAddress.transfer(adminShare);
        //recieverAddress.transfer(recieverShare);
        // for(uint i=0;i<recipients.length;i++){
        //     recipients[i].transfer(share);
        // }

       // emit TransferRecieved(msg.sender,msg.value);
    }
}