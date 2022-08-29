/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract LandExchange{

     struct LandSale {
         uint landId;
         address seller;    
         address buyer;
         uint amount;
         uint date;
     }

     mapping (uint => LandSale) public landsale;
     mapping(uint => address) public ownerOfLand;     //landId => owner address


     modifier onlyOwner(uint _landId){
         require(ownerOfLand[_landId] == msg.sender, "you are not owner");

         _;
     }

     function ownLand(uint _landId) public  {
         require(ownerOfLand[_landId] == address(0), "this land is already owned!");
         
         landsale[_landId].landId = _landId;

         ownerOfLand[_landId] = msg.sender;
     }

     function changeOwnership(uint _landId, address _buyer, uint _amount) public onlyOwner(_landId){
          landsale[_landId].buyer = _buyer;
          landsale[_landId].seller = msg.sender;
          landsale[_landId].amount = _amount;
          landsale[_landId].date = block.timestamp;

          ownerOfLand[landsale[_landId].landId] = _buyer;

     }

}