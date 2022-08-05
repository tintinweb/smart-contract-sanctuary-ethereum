//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Battle{


receive () external payable{}    
    address payable Owner=payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);


function deposit() public payable {
    require(msg.value >1000 wei,"Amount Should Be Greater Than 100 WEI");
     //Owner.transfer(address(this).balance);
}
    

    function ReturnReward() public view returns(uint){
      uint total=address(this).balance;
        uint newAmount=(total *10/100);
        total -=newAmount;
        return (total);
    }

   function Winner(address payable Winer) public
   {
        Winer.transfer(ReturnReward());
     Owner.transfer(getBalance());
   }
 function getBalance() public view returns(uint256){
        return address(this).balance;
    }
  
}