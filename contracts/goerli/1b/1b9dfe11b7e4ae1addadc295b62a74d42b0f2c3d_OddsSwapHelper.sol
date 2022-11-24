/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


abstract contract Context{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


interface IMarketOddsFactory{
  function calcOdds(MarketDomain.MarketBetBo calldata MarketBetBo,MarketDomain.MarketBetOptionBo [] calldata options) pure external returns (bool exceed,uint256 currentOdds,MarketDomain.MarketBetOptionBo [] memory currOptions);
}

interface IOddsSwap{
  function oddsFactoryOf(uint256 poolType) view external returns (address);
  function findMarketPoolBetAllOption(uint256 poolId) view external returns(uint256 [] memory optionArr,uint256 [] memory currOddsArr,uint256 [] memory betTotalAmountArr);
}


contract  MarketDomain{

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


contract OddsSwapHelpService is MarketDomain{

  address private oddsSwapAddress;

  function _setOddsSwapAddress(address _oddsSwapAddress)internal{
    require(_oddsSwapAddress!=address(0),"OddsSwapHelpService: Address can not be zero.");
    oddsSwapAddress = _oddsSwapAddress;
  }

  function _getOddsSwapAddress()internal view returns(address){
    return oddsSwapAddress;
  }

  function _getPoolAllOptions(uint256 poolId) view internal returns(MarketBetOptionBo [] memory options){
    uint256 [] memory optionArr;
    uint256 [] memory oddsArr;
    uint256 [] memory amountArr;
  (optionArr,oddsArr,amountArr) = IOddsSwap(oddsSwapAddress).findMarketPoolBetAllOption(poolId);   
  require(optionArr.length>0,"OddsSwapHelpService: options not found.");
  options = new MarketBetOptionBo[] (optionArr.length);
    for(uint256 i =0; i<optionArr.length; i++){
      options[i]=MarketBetOptionBo({
        option:optionArr[i],
        currOdds:oddsArr[i],
        betTotalAmount:amountArr[i]
      });
  }
    
  }


 function _swapEstimate(
   MarketBetBo memory betBo 
 ) internal view returns(uint256 finalOdds,uint256 originOdds){
  MarketBetOptionBo [] memory optionBos = _getPoolAllOptions(betBo.poolId);   

  bool finded = false;
  for(uint256 i =0;i< optionBos.length;i ++){   
    if(betBo.option == optionBos[i].option){
      finded = true;
      originOdds = optionBos[i].currOdds;
      break;
    }
  }
  require(finded,"OddsSwapHelpService: Invalid option.");

  bool exceed;
  uint256 currentOdds;
  MarketBetOptionBo [] memory optionsRes;
  address oddsFactoryAddress = IOddsSwap(oddsSwapAddress).oddsFactoryOf(betBo.poolType);
  require(oddsFactoryAddress!=address(0),"OddsSwapHelpService: oddsFactoryAddress not found!");
  (exceed,currentOdds,optionsRes) = IMarketOddsFactory(oddsFactoryAddress).calcOdds(betBo,optionBos);
  return (currentOdds,originOdds);
 }

}


interface IOddsSwapHelper{
  function getOddsSwapAddress()external  returns (address);
  function setOddsSwapAddress(address swapAddress)external;
 function swapEstimate(
    uint256 poolId,
    uint256 poolType,
    uint256 betMinAmount,
    uint256 fee,
    uint256 option,
    uint256 betAmount,
    uint256 slide
 ) external returns(uint256 finalOdds,uint256 originOdds);

}

contract OddsSwapHelper is IOddsSwapHelper,Ownable,OddsSwapHelpService{
  function getOddsSwapAddress()external view override returns (address){
    return _getOddsSwapAddress();
  }
  function setOddsSwapAddress(address oddsSwapAddress)external override onlyOwner{
    _setOddsSwapAddress(oddsSwapAddress);
  }

  function swapEstimate(
    uint256 poolId,
    uint256 poolType,
    uint256 betMinAmount,
    uint256 fee,
    uint256 option,
    uint256 betAmount,
    uint256 slide
    )external view override returns(uint256 finalOdds,uint256 originOdds){
    MarketBetBo memory betBo = MarketBetBo({
    poolId:poolId,
    poolType:poolType,
    user:msg.sender,
    option:option,
    betAmount:betAmount,
    slide:slide,
    minUnit:betMinAmount,
    fee:fee
  });
    (finalOdds,originOdds) = _swapEstimate(betBo);
  }

  constructor(address oddsSwapAddress){
    _setOddsSwapAddress(oddsSwapAddress);
  }
}