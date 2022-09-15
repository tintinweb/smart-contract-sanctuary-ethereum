/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Lottery {

    address public manager;
    uint private winNum;
     
     struct playerDetail {
         uint lotNum;
         uint ethAmnt;
     }
     
     constructor(address _admin){
         manager = _admin;
     }

     mapping (address => playerDetail) private pDetails;
     playerDetail[] public testArr;

     modifier minimumAmount (){
         require(msg.value >= 0.1 ether,"Enter amount greater than 0.1 Ether");
         _;
     }
        modifier onlyAdmin (){
         require(msg.sender == manager,"Restricted access");
         _;
     }

     function enterNumber(uint _lotNum) public payable minimumAmount{
        playerDetail memory tempStore;
        tempStore.lotNum = _lotNum;
        tempStore.ethAmnt = msg.value;
        pDetails[msg.sender] = tempStore;
        testArr.push(tempStore);
     }

     function pickWinner(uint _num) public onlyAdmin  {
       winNum = _num;
     }

     function claim()public {
        //  require(address(this).balance==0,"ZERO Balance");
         require(pDetails[msg.sender].lotNum == winNum);
          (bool status,) = (msg.sender).call{value:address(this).balance}("");
          require(status);
     }

    function getDetail() public view returns(playerDetail memory){
        return pDetails[msg.sender];
    }
    
    function TotalParticipants()public view returns(uint) {
        return testArr.length;
    }

}