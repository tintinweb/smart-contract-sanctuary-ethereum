/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract PaymentSplitterNew{
    address payable public royaltyAddress;
    address payable public recieverAddress;
    uint public percentage;
 event TransferRecieved(address _from,uint amount);
    // constructor(address payable [] memory _addrs){
        
    //     for(uint i=0;i<_addrs.length;i++){
    //         recipients.push(_addrs[i]);
    //     }

    // }
    function setRoyaltyAddress(address payable _addrs) public {
        royaltyAddress=_addrs;
        
    }
    function setRecieverAddress(address payable _addrs) public {
        recieverAddress=_addrs;
        
    }
    function setPercentageRoyalty(uint _percent)public{
        percentage=_percent;
    }

    receive() payable external{
        //percentage=msg.value;
        uint256 totalShare=msg.value;
        uint256 royaltyShare= ((totalShare/100)*percentage);
        uint256 recieverShare = totalShare-royaltyShare;
        royaltyAddress.transfer(royaltyShare);
        recieverAddress.transfer(recieverShare);
        // for(uint i=0;i<recipients.length;i++){
        //     recipients[i].transfer(share);
        // }

        emit TransferRecieved(msg.sender,msg.value);
    }
}