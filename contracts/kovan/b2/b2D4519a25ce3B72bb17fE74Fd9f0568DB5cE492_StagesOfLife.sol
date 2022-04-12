/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract StagesOfLife{
    enum Stages{
        Infant,
        Toddler,
        Child,
        TeenAger,
        Adult,
        Old
    }
    function getStage(int256 months) public pure returns(Stages stage){
        require(months>0);
       int256 year=months/12;
       if(year==0){
           stage= Stages.Infant;
       }
       if(year>=1&&year<=2){
       stage=Stages.Toddler;}
       if(year>=3&&year<=12){
       stage=Stages.Child;}
       if(year>=13&&year<=19){
       stage=Stages.TeenAger;}
       if(year>=20&&year<=60){
       stage=Stages.Adult;}
       if(year>60){
           stage=Stages.Old;
       }
    }
}