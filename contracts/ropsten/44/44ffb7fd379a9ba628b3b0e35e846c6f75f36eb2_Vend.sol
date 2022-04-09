/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Vend{
    address public admin;
    uint256 public Super = 25 wei;
    uint256 public Rio = 25 wei;
    uint256 public AppleJuice = 50 wei;
     constructor(){
         admin = msg.sender;
     }



    event Items(address _buyer, uint256 _amount);

    function Buy(uint256 _items) payable public {
        require(msg.value >= _items,"Items Cost More ");
        emit Items(msg.sender,msg.value);
    }
    function funds() public view  returns(uint256){
        return address(this).balance;
    }
    function withdraw() public payable  {
    payable(msg.sender).transfer(address(this).balance);
}
  

   







}