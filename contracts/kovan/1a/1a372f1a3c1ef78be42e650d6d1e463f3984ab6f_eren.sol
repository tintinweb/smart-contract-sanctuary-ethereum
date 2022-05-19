/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/demo2.sol


pragma solidity ^0.8.7;

contract eren
{
  //air1
   uint256 paidToken;
   uint256 ethToken;
   uint256 selectedAir;
   uint256 degree;
  //air2
   uint256 paidToken2;
   uint256 ethToken2;
   uint256 selectedAir2;
   uint256 degree2;
   //air3
   uint256 paidToken3;
    uint256 ethToken3;
   uint256 selectedAir3;
   uint256 degree3;
   //air4
   uint256 paidToken4;
    uint256 ethToken4;
   uint256 selectedAir4;
   uint256 degree4;
   //
   //address wallet1 = 0x0000000000000000000000000000000000000000;
   address wallet1;
   address wallet2;
   address wallet3;
   address wallet4;
   //
   ////////////MAIN////////////

   function payAir(uint256 airconditioning, uint256 tokenValue, uint256 airDegree) public returns(uint256)
   {
    require(airconditioning>0&&airconditioning<5,"We only have 4 air conditioners :( Please choose between 1-4.");
    selectedAir = airconditioning;
    if (selectedAir==1) {
    require(paidToken<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken = tokenValue;
    wallet1 = msg.sender;
    require(airDegree>15&&airDegree<31,"Values must be between 16-30.");
    degree = airDegree;
    return tokenValue;
    }
    if (selectedAir==2) {
    require(paidToken2<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken2 = tokenValue;
    wallet2 = msg.sender;
    require(airDegree>15&&airDegree<31,"Values must be between 16-30.");
    degree2 = airDegree;
    return tokenValue;
    }
     if (selectedAir==3) {
    require(paidToken2<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken3 = tokenValue;
    wallet3 = msg.sender;
    require(airDegree>15&&airDegree<31,"Values must be between 16-30.");
    degree3 = airDegree;
    return tokenValue;
    }
     if (selectedAir==4) {
    require(paidToken4<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken4 = tokenValue;
    wallet4 = msg.sender;
    require(airDegree>15&&airDegree<31,"Values must be between 16-30.");
    degree4 = airDegree;
    return tokenValue;
    }
    return airconditioning;
   }

   function air1() public view returns(uint256,uint256,address)
    {
       return (paidToken,degree,wallet1);
    }
    function air2() public view returns(uint256,uint256,address)
    {
       return (paidToken2,degree2,wallet2);
    }
     function air3() public view returns(uint256,uint256,address)
    {
       return (paidToken3,degree3,wallet3);
    }
     function air4() public view returns(uint256,uint256,address)
    {
       return (paidToken4,degree4,wallet4);
    }
}