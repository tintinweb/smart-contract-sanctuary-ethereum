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
   uint256 selectedAir;
   uint256 degree;
   string name;
  //air2
   uint256 paidToken2;
   uint256 selectedAir2;
   uint256 degree2;
   string name2;
   //air3
   uint256 paidToken3;
   uint256 selectedAir3;
   uint256 degree3;
   string name3;
   //air4
   uint256 paidToken4;
   uint256 selectedAir4;
   uint256 degree4;
   string name4;

   ////////////MAIN////////////

   function payAir(uint256 airconditioning, uint256 tokenValue, uint256 _degree) public returns(uint256)
   {
    require(airconditioning>0&&airconditioning<5,"We only have 4 air conditioners :( Please choose between 1-4.");
    selectedAir = airconditioning;
    if (selectedAir==1) {
    require(paidToken<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken = tokenValue;
    require(_degree>15&&_degree<31,"Values must be between 16-30.");
    degree = _degree;
    return tokenValue;
    }
    if (selectedAir==2) {
    require(paidToken2<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken2 = tokenValue;
    require(_degree>15&&_degree<31,"Values must be between 16-30.");
    degree2 = _degree;
    return tokenValue;
    }
     if (selectedAir==3) {
    require(paidToken2<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken3 = tokenValue;
    require(_degree>15&&_degree<31,"Values must be between 16-30.");
    degree3 = _degree;
    return tokenValue;
    }
     if (selectedAir==4) {
    require(paidToken4<tokenValue,"Don't be afraid to take risks, increase the price :)");
    paidToken4 = tokenValue;
    require(_degree>15&&_degree<31,"Values must be between 16-30.");
    degree4 = _degree;
    return tokenValue;
    }
    return airconditioning;
   }

   function air1() public view returns(uint256,uint256)
    {
       return (paidToken,degree);
    }
    function air2() public view returns(uint256,uint256)
    {
       return (paidToken2,degree2);
    }
     function air3() public view returns(uint256,uint256)
    {
       return (paidToken3,degree3);
    }
     function air4() public view returns(uint256,uint256)
    {
       return (paidToken4,degree4);
    }
}