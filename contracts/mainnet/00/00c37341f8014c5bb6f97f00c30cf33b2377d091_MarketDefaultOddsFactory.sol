/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarketOddsFactory{
  function calcOdds(MarketDomain.MarketBetBo memory betBo,MarketDomain.MarketBetOptionBo [] memory options) pure external returns (bool exceed,uint256 currentOdds,MarketDomain.MarketBetOptionBo [] memory CurrOptions);
}

contract MarketDomain{

  struct MarketBetBo{
    uint256 poolId;
    uint256 poolType;
    address user;
    uint256 option;
    uint256 betAmount;
    uint256 slide;
    uint256 fee;
    uint256 minUnit;
  }

  struct MarketBetOptionBo{
        uint256 option;
        uint256 currOdds;
        uint256 betTotalAmount;       
  }
}

contract MarketDefaultOddsFactory is IMarketOddsFactory,MarketDomain{
  function calcOdds(MarketBetBo memory betBo,MarketBetOptionBo [] memory options) pure override external 
  returns (bool ,uint256 ,MarketDomain.MarketBetOptionBo [] memory){
    uint256 oldSelfTotalBetAcount;
    uint256 newSelfTotalBetAcount;
    uint256 opponentTotalAmount;
    uint256 oldSelfOdds;
    for(uint256 i=0;i<options.length;i++){
      MarketBetOptionBo memory optionBo = options[i];
      if(optionBo.option==betBo.option){
        oldSelfTotalBetAcount = optionBo.betTotalAmount;
        optionBo.betTotalAmount += betBo.betAmount;
        newSelfTotalBetAcount = optionBo.betTotalAmount;
        oldSelfOdds = optionBo.currOdds;
      }else{
        opponentTotalAmount +=optionBo.betTotalAmount;
      }
    }

    uint256 currentOdds = _doCalcBetCurrOdds(betBo.minUnit,100,betBo.betAmount,oldSelfTotalBetAcount,opponentTotalAmount,betBo.fee);
    uint256 absOddsDiff = currentOdds >oldSelfOdds?currentOdds-oldSelfOdds:oldSelfOdds-currentOdds;
    bool exceed = absOddsDiff / oldSelfOdds  > betBo.slide ;
    MarketBetOptionBo [] memory newOptions = _refreshOptions(options,betBo.fee);
    return (exceed,currentOdds,newOptions);
  }

  function _doCalcBetCurrOdds(uint256 minUnit,uint256 maxLoopCount,uint256 selfBetAmount,uint256 selfBetTotalAmount,uint256 opponentTotalAmount,uint256 fee)internal pure returns(uint256 currOdds){
    uint256 factor=0;
    uint256 loopCount = selfBetAmount / minUnit;
    if(loopCount >maxLoopCount){
      loopCount = maxLoopCount;
      minUnit = selfBetAmount/loopCount;
    }
    uint256 fee_up = fee*10**uint(18);
    uint256 one = 1*10**uint(18);
    uint256 radio = 10000;
    uint256 one_double = 1*10**uint(36);
    uint256 radioDiff = 1*10**uint(14);
    for(uint256 i =0; i<loopCount; i++){
      factor = factor + one_double / (selfBetTotalAmount + minUnit * i);
    }
    currOdds = (one - fee_up /radio) * (one+ opponentTotalAmount*factor/(selfBetAmount* one/minUnit))/one /radioDiff;
    currOdds = _rounding(currOdds);
  }


  function _calcOptionCurrOdds(uint256 selfBetTotalAmount,uint256 opponentTotalAmount,uint256 fee)internal pure returns(uint256 finalOdds){
    uint256 one = 1*10**uint(18);
    uint256 fee_up = fee*10**uint(18);
    uint256 radio = 10000;
     uint256 radioDiff = 1*10**uint(14);
    finalOdds = (one - fee_up /radio) * (one + opponentTotalAmount * one/selfBetTotalAmount)/one/radioDiff;
    finalOdds = _rounding(finalOdds);
  }

  function _calcTotalAmounts(MarketDomain.MarketBetOptionBo [] memory options,uint256 selfOption)internal pure returns(uint256 selfTotalAmount,uint256 opponentTotalAmount){
    for(uint256 i=0;i<options.length;i++){
      MarketBetOptionBo memory optionBo = options[i];
      if(optionBo.option==selfOption){
        selfTotalAmount = optionBo.betTotalAmount;
      }else{
        opponentTotalAmount +=optionBo.betTotalAmount;
      }
    }
  }

  function _refreshOptions(MarketDomain.MarketBetOptionBo [] memory options,uint256 fee) internal pure returns(MarketDomain.MarketBetOptionBo [] memory){
      for(uint256 i=0;i<options.length;i++){
        MarketBetOptionBo memory optionBo = options[i];
        uint256 _selfTotalBetAcount;
        uint256 _opponentTotalAmount;
        (_selfTotalBetAcount,_opponentTotalAmount) = _calcTotalAmounts(options,optionBo.option);
       optionBo.currOdds = _calcOptionCurrOdds(_selfTotalBetAcount,_opponentTotalAmount,fee);
      }
      return options;
  }

  function _rounding(uint256 number) internal pure returns(uint256){
    uint256 part1 = number / 100 * 100;
    uint256 remain = number % 100;
    if(remain>=50){
      return part1 + 100;
    }else{
      return part1;
    }
  }

  constructor(){
  }
}