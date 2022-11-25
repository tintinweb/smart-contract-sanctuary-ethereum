// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

// @title Nex Exchange smart contract

contract Exchange is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  AggregatorV3Interface internal nftFloorPriceFeed;

  AggregatorV3Interface public priceFeed;

  address public usdc;

  bool public poolInitialized; // is pool initialized
  
  uint256 public insuranceFunds;

  uint8 public discountRate = 20; //20%
  uint8 public saveLevelMargin = 60; //60%
  uint8 public maintenanceMargin = 50; //50%
  uint8 public AutoCloseMargin = 40; //40%

  uint8 public swapFee = 10; //=> 10/10000 = 0.1%
  uint256 public latestFeeUpdate;

  address[] liquidateList;

  
  struct Pool {
    uint256 vBaycPoolSize;
    uint256 vUsdPoolSize;
  }

  Pool public pool;

  struct VirtualBalance {
    int256 virtualCollateral;//funding reward of each user
    int256 uservUsdBalance;// virtual usd balance of each user;
    int256 uservBaycBalance;// virtual nft balance of each user;
  }


  address[] public activeUsers;

  mapping(address => mapping(address => uint256)) public collateral; //collateral[tokenaddress][useraddress]
  mapping(address => VirtualBalance) public virtualBalances;

  

  event NewOracle(address oracle);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  constructor(
    address _nftOracleAddress,
    address _priceFeed,
    address _usdc
  ) {
    nftFloorPriceFeed = AggregatorV3Interface(_nftOracleAddress);
    priceFeed = AggregatorV3Interface(_priceFeed);
    usdc = _usdc;
  }


  //return bayc virtual pool size of the market
  function vBaycPoolSize() public view returns(uint256){
    return pool.vBaycPoolSize;
  }

  //return usd virtual pool size of the market
  function vUsdPoolSize() public view returns(uint256){
    return pool.vUsdPoolSize;
  }

  //return virtual collateral of each user
  function virtualCollateral(address _user) public view returns(int256){
    return virtualBalances[_user].virtualCollateral;
  }

  //return virtual usd balance of each user
  function uservUsdBalance(address _user) public view returns(int256){
    return virtualBalances[_user].uservUsdBalance;
  }

  //return virtual bayc balance of each user
  function uservBaycBalance(address _user) public view returns(int256){
    return virtualBalances[_user].uservBaycBalance;
  }

  //get nft Price in ETH
  function showPriceETH() public view returns(uint){
        int nftPrice = getLatestNftPrice();
        return uint(nftPrice);
    }

  //get nft price in USD
  function showPriceUSD() public view returns(uint){
        uint price = showPriceETH();
        int ethPrice = getEthUsdPrice()*1e10;
        return price*uint(ethPrice)/1e18;
    }

  //get eth/usd price
  function getEthUsdPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
  
  function getLatestNftPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int nftFloorPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nftFloorPriceFeed.latestRoundData();
        return nftFloorPrice;
    }

  //check is user exist in activeUsers array
  function doesUserExist(address _user) public view returns (bool) {
    for (uint256 i; i < activeUsers.length; i++) {
      if (activeUsers[i] == _user) {
        return true;
      }
    }
    return false;
  }

  //add user to the active user list (first check if its not)
  function _addActiveUser(address _user) internal {
    bool isExist = doesUserExist(_user);
    if (isExist == false) {
      activeUsers.push(_user);
    }
  }

  //remove user from active users list
  function _removeActiveUser(address _user) internal {
    bool isExist = doesUserExist(_user);
    if (isExist == true) {
      for (uint256 i; i < activeUsers.length; i++) {
        if (activeUsers[i] == _user) {
          delete activeUsers[i];
        }
      }
    }
  }

  //return all active users in one array
  function getAllActiveUsers() public view returns (address[] memory) {
    return activeUsers;
  }

  //create the pool
  //for this time owner can do it
  function initialVirtualPool(uint256 _assetSize) public onlyOwner {
    require(poolInitialized == false, "You cannot initialize pool again");
    uint oraclePrice = showPriceUSD();
    pool.vBaycPoolSize = _assetSize;
    pool.vUsdPoolSize = _assetSize*oraclePrice/1e18;
    poolInitialized = true;
  }


  function changeNftOracleAddress(address _newAddress) public onlyOwner {
    nftFloorPriceFeed = AggregatorV3Interface(_newAddress);
  }

  //Notice: newFee should be between 1 to 500 (0.01% - 5%)
  function setSwapFee(uint8 _newFee) public onlyOwner {
    uint256 distance = block.timestamp - latestFeeUpdate;
    require(distance / 60 / 60 > 12, "You should wait at least 12 hours after the latest update");
    require(_newFee <= 500 && _newFee >= 1, "The newFee should be between 1 and 500 (0.01% - 5%)");
    swapFee = _newFee;
    latestFeeUpdate = block.timestamp;
  }

  //deposit collateral
  function depositCollateral(uint256 _amount) public {
    SafeERC20.safeTransferFrom(IERC20(usdc), msg.sender, address(this), _amount);
    collateral[usdc][msg.sender] = collateral[usdc][msg.sender].add(_amount);
    emit Deposit(usdc, msg.sender, _amount, collateral[usdc][msg.sender]);
  }

  

  //withdraw collateral
  //befor that the function check user margin
  function withdrawCollateral(uint256 _amount) public {
    //check new margin
    uint256 totalPositionNotional = getPositionNotional(msg.sender);
    int256 totalAccountValue = getAccountValue(msg.sender);
    if (totalPositionNotional > 0) {
      int256 newAccountValue = totalAccountValue - int(_amount);
      int256 newMargin = (100 * newAccountValue) / int(totalPositionNotional);
      require(
        newMargin > int8(saveLevelMargin),
        "You cannot withdraw because your margin is lower than the saveMargin level"
      );
    }
    //check user has enough collateral
    require(
      collateral[usdc][msg.sender] >= _amount,
      "Requested withdrawal amount is larger than the collateral balance."
    );
    //transfer tokens to the user
    SafeERC20.safeTransfer(IERC20(usdc), msg.sender, _amount);
    collateral[usdc][msg.sender] = collateral[usdc][msg.sender].sub(_amount);
    emit Withdraw(usdc, msg.sender, _amount, collateral[usdc][msg.sender]);
  }

  //give the user funding reward when position will be closed
  function _realizevirtualCollateral(address _user, int256 _amount) internal {
    require(_amount <= absoluteInt(virtualBalances[_user].virtualCollateral), "Requested amount is larger than the virtual collateral balance.");
    if (virtualBalances[_user].virtualCollateral > 0) {
      collateral[usdc][_user] += uint256(_amount);
      virtualBalances[_user].virtualCollateral -= _amount;
    } else if (virtualBalances[_user].virtualCollateral < 0) {
      collateral[usdc][_user] -= uint256(_amount);
      virtualBalances[_user].virtualCollateral += _amount;
    }
  }

  //get output Bayc by usd input amount if we want to buy(long)
  //how much Bayc we will get by paying usd for long
  function getLongBaycAmountOut(uint256 _vUsdAmount) public view returns (uint256) {
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize + _vUsdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    uint256 userBayc = pool.vBaycPoolSize - newvBaycPoolSize;
    return userBayc;
  }

  //get output usd amount by Bayc input amount if we want to buy(long)
  function getLongVusdAmountOut(uint256 _vBaycAmount) public view returns (uint256) {
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvBaycPoolSize = pool.vBaycPoolSize - _vBaycAmount;
    uint256 newvUsdPoolSize = k / newvBaycPoolSize;
    uint256 uservUsd = newvUsdPoolSize - pool.vUsdPoolSize;
    return uservUsd;
  }

  //get output Bayc by usd input amount if we want to sell(short)
  function getShortBaycAmountOut(uint256 _vUsdAmount) public view returns (uint256) {
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize - _vUsdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    uint256 userBayc = newvBaycPoolSize - pool.vBaycPoolSize;
    return userBayc;
  }

  //get output usd by Bayc input amount if we want to sell(short)
  function getShortVusdAmountOut(uint256 _vBaycAmount) public view returns (uint256) {
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvBaycPoolSize = pool.vBaycPoolSize + _vBaycAmount;
    uint256 newvUsdPoolSize = k / newvBaycPoolSize;
    uint256 uservUsd = pool.vUsdPoolSize - newvUsdPoolSize;
    return uservUsd;
  }

  //I use int for negative/positve numbers for user bayc and usd balance(wich might be negative)
  //so for some point we need to convert them to uint so they should be positive
  //f.e positive(-1)=1
  function positive(int256 _amount) public view returns (uint256) {
    if (_amount < 0) {
      int256 posAmount = -(_amount);
      return uint256(posAmount);
    } else {
      return uint256(_amount);
    }
  }

  function oraclePrice() public view returns(uint256){
    uint oraclePrice = showPriceUSD();
    return oraclePrice;
  }

  function getCurrentExchangePrice() public view returns(uint256){
    return 1e18*pool.vUsdPoolSize/pool.vBaycPoolSize;
  }

  function openLongPosition(uint256 _usdAmount) public {
    //calculate the new pool size and user bayc amount
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize + _usdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    /*
    bool isInTheRightRange = isPriceIntheRightRange(newvBaycPoolSize, newvUsdPoolSize);
    require(
      isInTheRightRange == true,
      "You can't move the price more than 10% away from the oracle price."
    );
    */
    bool isNewMarginHardLiquidateable = _isNewMarginLiquidatable(msg.sender, _usdAmount, newvBaycPoolSize, newvUsdPoolSize);
    require(
      isNewMarginHardLiquidateable == false,
      "Insufficient margin to open position with requested size."
    );

    //first we run liquidation functions
    (newvBaycPoolSize, newvUsdPoolSize) = _hardLiquidateUsers(newvBaycPoolSize, newvUsdPoolSize);
    (newvBaycPoolSize, newvUsdPoolSize) = _partialLiquidateUsers(newvBaycPoolSize, newvUsdPoolSize);
    
    uint256 userBayc = pool.vBaycPoolSize - newvBaycPoolSize;
    //update bayc and usd balance of user
    virtualBalances[msg.sender].uservBaycBalance += int256(userBayc);
    virtualBalances[msg.sender].uservUsdBalance -= int256(_usdAmount);

    //add user to the active user list
    _addActiveUser(msg.sender);

    //trade fee
    uint256 fee = (_usdAmount * swapFee) / 10000;
    collateral[usdc][msg.sender] -= fee;
    address owner = owner();
    SafeERC20.safeTransfer(IERC20(usdc), owner, fee);

    //update pool
    pool.vBaycPoolSize = newvBaycPoolSize;
    pool.vUsdPoolSize = newvUsdPoolSize;
  }


  function openShortPosition(uint256 _usdAmount) public {
    //calculate the new pool size and user bayc amount
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize - _usdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    /*
    bool isInTheRightRange = isPriceIntheRightRange(newvBaycPoolSize, newvUsdPoolSize);
    require(
      isInTheRightRange == true,
      "You can't move the price more than 10% away from the oracle price."
    );
    */
    bool isNewMarginHardLiquidateable = _isNewMarginLiquidatable(msg.sender, _usdAmount, newvBaycPoolSize, newvUsdPoolSize);
    require(
      isNewMarginHardLiquidateable == false,
      "Insufficient margin to open position with requested size."
    );
    
    //first we run liquidation functions
    (newvBaycPoolSize, newvUsdPoolSize) = _hardLiquidateUsers(newvBaycPoolSize, newvUsdPoolSize);
    (newvBaycPoolSize, newvUsdPoolSize) = _partialLiquidateUsers(newvBaycPoolSize, newvUsdPoolSize);

    k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    newvUsdPoolSize = pool.vUsdPoolSize - _usdAmount;
    newvBaycPoolSize = k / newvUsdPoolSize;
    uint256 userBayc = newvBaycPoolSize - pool.vBaycPoolSize;
    //update bayc and usd balance of user
    virtualBalances[msg.sender].uservBaycBalance -= int256(userBayc);
    virtualBalances[msg.sender].uservUsdBalance += int256(_usdAmount);

    //add user to the active user list
    _addActiveUser(msg.sender);

    //trade fee
    uint256 fee = (_usdAmount * swapFee) / 10000;
    collateral[usdc][msg.sender] -= fee;
    address owner = owner();
    SafeERC20.safeTransfer(IERC20(usdc), owner, fee);

    //update pool
    pool.vBaycPoolSize = newvBaycPoolSize;
    pool.vUsdPoolSize = newvUsdPoolSize;
  }


  

  function _closeLongPosition(address _user, uint256 _assetSize) internal {
    require(
      _assetSize <= positive(virtualBalances[_user].uservBaycBalance),
      "Reduce only order can only close long size equal or less than the outstanding asset size."
    );

    uint256 k;
    //first we run liquidation functions
    k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 vBaycNewPoolSize = pool.vBaycPoolSize + _assetSize;
    uint256 vUsdNewPoolSize = k / vBaycNewPoolSize;

    //liquidate users
    (vBaycNewPoolSize, vUsdNewPoolSize) = _hardLiquidateUsers(vBaycNewPoolSize, vUsdNewPoolSize);
    (vBaycNewPoolSize, vUsdNewPoolSize) = _partialLiquidateUsers(vBaycNewPoolSize, vUsdNewPoolSize);
    

    //get the output usd of closing position
    //f.e 1Bayc -> 2000$
    uint256 usdBaycValue = getShortVusdAmountOut(_assetSize);
    
    int256 userPartialvUsdBalance = (virtualBalances[_user].uservUsdBalance * int256(_assetSize)) /
      virtualBalances[_user].uservBaycBalance;

    //increase or decrease the user pnl for this function
    if (usdBaycValue > uint256(positive(userPartialvUsdBalance))) {
      uint256 pnl = usdBaycValue - uint256(positive(userPartialvUsdBalance));
      // collateral[usdc][_user] += pnl;
      collateral[usdc][_user] += pnl;
    } else if (usdBaycValue < uint256(positive(userPartialvUsdBalance))) {
      uint256 pnl = uint256(positive(userPartialvUsdBalance) - usdBaycValue);
      collateral[usdc][_user] -= pnl;
    }
    //realize funding reward of user;
    int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(_assetSize)) /
      virtualBalances[_user].uservBaycBalance;
    _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
    //update user balance
    virtualBalances[_user].uservBaycBalance -= int256(_assetSize);
    virtualBalances[_user].uservUsdBalance += absoluteInt(userPartialvUsdBalance);
    // if user has not vbalance so he is not active
    if (virtualBalances[_user].uservBaycBalance == 0 && virtualBalances[_user].uservUsdBalance == 0) {
      _removeActiveUser(_user);
    }

    //trade fee
    uint256 fee = (usdBaycValue * swapFee) / 10000;
    collateral[usdc][_user] -= fee;
    address owner = owner();
    SafeERC20.safeTransfer(IERC20(usdc), owner, fee);

    //update the pool
    k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    pool.vBaycPoolSize += _assetSize;
    pool.vUsdPoolSize = k / pool.vBaycPoolSize;
  }

  function _closeShortPosition(address _user, uint256 _assetSize) internal {
    require(
      _assetSize <= positive(virtualBalances[_user].uservBaycBalance),
      "Reduce only order can only close short size equal or less than the outstanding asset size."
    );

    uint256 k;
    //first we run liquidation functions
    k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 vBaycNewPoolSize = pool.vBaycPoolSize - _assetSize;
    uint256 vUsdNewPoolSize = k / vBaycNewPoolSize;
    
    //liquidate users
    (vBaycNewPoolSize, vUsdNewPoolSize) = _hardLiquidateUsers(vBaycNewPoolSize, vUsdNewPoolSize);
    (vBaycNewPoolSize, vUsdNewPoolSize) = _partialLiquidateUsers(vBaycNewPoolSize, vUsdNewPoolSize);
    //get the output usd of closing position
    uint256 usdBaycValue = getLongVusdAmountOut(_assetSize);
    int256 userPartialvUsdBalance = (virtualBalances[_user].uservUsdBalance * int256(_assetSize)) /
      virtualBalances[_user].uservBaycBalance;
    //increase or decrease pnl of the user
    if (usdBaycValue > uint256(positive(userPartialvUsdBalance))) {
      uint256 pnl = usdBaycValue - uint256(positive(userPartialvUsdBalance));
      collateral[usdc][_user] -= pnl;
    }
    if (usdBaycValue < uint256(positive(userPartialvUsdBalance))) {
      uint256 pnl = uint256(positive(userPartialvUsdBalance) - usdBaycValue);
      collateral[usdc][_user] += pnl;
    }
    //realize funding reward of user;
    int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(_assetSize)) /
      virtualBalances[_user].uservBaycBalance;
    _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
    //update user balance
    virtualBalances[_user].uservBaycBalance += int256(_assetSize);
    virtualBalances[_user].uservUsdBalance -= absoluteInt(userPartialvUsdBalance);
    // if user has not vbalance so he is not active
    if (virtualBalances[_user].uservBaycBalance == 0 && virtualBalances[_user].uservUsdBalance == 0) {
      _removeActiveUser(_user);
    }
    //trade fee
    uint256 fee = (usdBaycValue * swapFee) / 10000;
    collateral[usdc][_user] -= fee;
    address owner = owner();
    SafeERC20.safeTransfer(IERC20(usdc), owner, fee);
    //update pool
    k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    pool.vBaycPoolSize -= _assetSize;
    pool.vUsdPoolSize = k / pool.vBaycPoolSize;
  }

  function closePositionComplete() public {
    uint assetSize = positive(virtualBalances[msg.sender].uservBaycBalance);
    closePosition(assetSize);
  }

  function closePosition(uint256 _assetSize) public {
    require(
      _assetSize <= positive(virtualBalances[msg.sender].uservBaycBalance),
      "Reduce only order can only close size equal or less than the outstanding asset size."
    );
    //if user has positive vBayc balance so he/she has longPosition
    //if user has negative vBayc balance so he/she has shortPosition
    if (virtualBalances[msg.sender].uservBaycBalance > 0) {
      _closeLongPosition(msg.sender, _assetSize);
    } else if (virtualBalances[msg.sender].uservBaycBalance < 0) {
      _closeShortPosition(msg.sender, _assetSize);
    }
  }

  //return the pnl of user
  /*
  user vBayc balance = 2Bayc
  user vUsd balance = -3000
  currnent 2 vBayc value =  4000
  user pnl = 4000 - positive(-3000) = 1000$
  */
  function getPNL(address _user) public view returns (int256) {
    if (virtualBalances[_user].uservBaycBalance > 0) {
      uint256 currentBaycValue = getShortVusdAmountOut(uint256(virtualBalances[_user].uservBaycBalance));
      int256 pnl = int256(currentBaycValue) + (virtualBalances[_user].uservUsdBalance);
      return pnl;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 currentBaycValue = getLongVusdAmountOut(positive(virtualBalances[_user].uservBaycBalance));
      int256 pnl = virtualBalances[_user].uservUsdBalance - int256(currentBaycValue);
      return pnl;
    }
  }

  //get user pnl by new pool size(new price);
  function _getNewPNL(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (int256) {
    if (virtualBalances[_user].uservBaycBalance > 0) {
      uint256 k = _vBaycNewPoolSize * _vUsdNewPoolSize;
      uint256 newvBaycPoolSize = _vBaycNewPoolSize + uint256(virtualBalances[_user].uservBaycBalance);
      uint256 newvUsdPoolSize = k / newvBaycPoolSize;
      uint256 currentBaycValue = _vUsdNewPoolSize - newvUsdPoolSize;
      int256 pnl = int256(currentBaycValue) + (virtualBalances[_user].uservUsdBalance);
      return pnl;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 k = _vBaycNewPoolSize * _vUsdNewPoolSize;
      uint256 newvBaycPoolSize = _vBaycNewPoolSize - positive(virtualBalances[_user].uservBaycBalance);
      uint256 newvUsdPoolSize = k / newvBaycPoolSize;
      uint256 currentBaycValue = newvUsdPoolSize - _vUsdNewPoolSize;
      int256 pnl = virtualBalances[_user].uservUsdBalance - int256(currentBaycValue);
      return pnl;
    }
  }

  //account value = collateral +- pnl
  function getAccountValue(address _user) public view returns (int256) {
    uint256 collateralValue = collateral[usdc][_user];
    int256 pnl = getPNL(_user);
    int256 fundingReward = virtualBalances[_user].virtualCollateral;
    int256 accountValue = int256(collateralValue) + pnl + fundingReward;
    return accountValue;
  }

  //get new account value according to the new pool size (new price)
  function _getNewAccountValue(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (int256) {
    uint256 collateralValue = collateral[usdc][_user];
    int256 pnl = _getNewPNL(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    int256 fundingReward = virtualBalances[_user].virtualCollateral;
    int256 accountValue = int256(collateralValue) + pnl + fundingReward;
    // int256 accountValue = int256(collateralValue);
    return accountValue;
  }

  //get total position value of each user
  function getPositionNotional(address _user) public view returns (uint256) {
    if (virtualBalances[_user].uservBaycBalance > 0) {
      uint256 positionNotionalValue = getShortVusdAmountOut(uint256(virtualBalances[_user].uservBaycBalance));
      return positionNotionalValue;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 positionNotionalValue = getLongVusdAmountOut(positive(virtualBalances[_user].uservBaycBalance));
      return positionNotionalValue;
    } else {
      return 0;
    }
  }

  //get new position notional value according to the new pool size (new price)
  function _getNewPositionNotional(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (uint256) {
    if (virtualBalances[_user].uservBaycBalance > 0) {
      uint256 k = _vBaycNewPoolSize * _vUsdNewPoolSize;
      uint256 newvBaycPoolSize = _vBaycNewPoolSize + uint256(virtualBalances[_user].uservBaycBalance);
      uint256 newvUsdPoolSize = k / newvBaycPoolSize;
      uint256 positionNotionalValue = _vUsdNewPoolSize - newvUsdPoolSize;
      return positionNotionalValue;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 k = _vBaycNewPoolSize * _vUsdNewPoolSize;
      uint256 newvBaycPoolSize = _vBaycNewPoolSize - positive(virtualBalances[_user].uservBaycBalance);
      uint256 newvUsdPoolSize = k / newvBaycPoolSize;
      uint256 positionNotionalValue = newvUsdPoolSize - _vUsdNewPoolSize;
      return positionNotionalValue;
    } else {
      return 0;
    }
  }

  function userMargin(address _user) public view returns (int256) {
    int256 accountValue = getAccountValue(_user);
    uint256 positionNotional = getPositionNotional(_user);
    if (accountValue != 0 && positionNotional > 0) {
      int256 margin = (100 * accountValue) / int(positionNotional);
      return margin;
    }else{
      return 0;
    }
  }

  //get the new margin of user according to the new pool size (new price)
  function _userNewMargin(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (int256) {
    int256 accountValue = _getNewAccountValue(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    uint256 positionNotional = _getNewPositionNotional(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    if (accountValue != 0 && positionNotional > 0) {
      int256 margin = (100 * accountValue) / int(positionNotional);
      return margin;
    } else{
      return 0;
    }
  }

  function isHardLiquidateable(address _user) public view returns (bool) {
    int256 userMargin = userMargin(_user);
    if (userMargin != 0 && userMargin <= int8(AutoCloseMargin)) {
      return true;
    } else {
      return false;
    }
  }



  //ckeck that is user can be liquidated according to the new price
  function _isHardLiquidateable(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (bool) {
    int256 userMargin = _userNewMargin(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    if (userMargin != 0 && userMargin <= int8(AutoCloseMargin)) {
      return true;
    } else {
      return false;
    }
  }

  function _isNewMarginLiquidatable(
    address _user,
    uint256 _usdAmount,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) public view returns(bool){
    int256 accountValue = _getNewAccountValue(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    uint256 positionNotional = _getNewPositionNotional(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    uint256 newPositionNotional = positionNotional + _usdAmount;
    int newMargin = 100*(accountValue)/int(newPositionNotional);
    if (newMargin != 0 && newMargin <= int8(saveLevelMargin)) {
      return true;
    } else {
      return false;
    }
  }

  function isPartialLiquidateable(address _user) public view returns (bool) {
    
    int256 userMargin = userMargin(_user);
    if (int8(AutoCloseMargin) <= userMargin && userMargin <= int8(maintenanceMargin)) {
      return true;
    } else {
      return false;
    }
    
  }

  //ckeck that is user can be partialy liquidated according to the new price
  function _isPartialLiquidateable(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (bool) {
    int256 userMargin = _userNewMargin(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    // if ( 40 < userMargin < 50 ) => user is partial liquidatable
    if (int8(AutoCloseMargin) <= userMargin && userMargin <= int8(maintenanceMargin)) {
      return true;
    } else {
      return false;
    }
  }

  

  //this function is called if user should be liquidated by new price
  function _hardLiquidate(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal returns(uint vBaycNewPoolSize, uint vUsdNewPoolSize) {
    require(
      _isHardLiquidateable(_user, _vBaycNewPoolSize, _vUsdNewPoolSize),
      "User is not hard liquidatable."
    );
    vBaycNewPoolSize = _vBaycNewPoolSize;
    vUsdNewPoolSize = _vUsdNewPoolSize;
    if (virtualBalances[_user].uservBaycBalance > 0) {
      // _closeLongPosition(_user, uint256(uservBaycBalance[_user]));
      uint256 _assetSize = uint256(virtualBalances[_user].uservBaycBalance);
      uint256 usdBaycValue = getShortVusdAmountOut(_assetSize);
      //increase or decrease the user pnl for this function
      if (usdBaycValue > uint256(positive(virtualBalances[_user].uservUsdBalance))) {
        uint256 pnl = usdBaycValue - uint256(positive(virtualBalances[_user].uservUsdBalance));
        collateral[usdc][_user] += pnl;
      } else if (usdBaycValue < uint256(positive(virtualBalances[_user].uservUsdBalance))) {
        uint256 pnl = uint256(positive(virtualBalances[_user].uservUsdBalance) - usdBaycValue);
        collateral[usdc][_user] -= pnl;
      }
      //realize funding reward of user;
      int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(_assetSize)) /
        virtualBalances[_user].uservBaycBalance;
      _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
      //update user balance
      virtualBalances[_user].uservBaycBalance = 0;
      virtualBalances[_user].uservUsdBalance = 0;
      // if user has not vbalance so he is not active
      _removeActiveUser(_user);
      //update the pool
      uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize += _assetSize;
      pool.vUsdPoolSize = k / pool.vBaycPoolSize;
      //update the new pool size
      vBaycNewPoolSize += _assetSize;
      vUsdNewPoolSize = k / vBaycNewPoolSize;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 _assetSize = uint256(positive(virtualBalances[_user].uservBaycBalance));
      uint256 usdBaycValue = getShortVusdAmountOut(_assetSize);
      //increase or decrease the user pnl for this function
      if (usdBaycValue > uint256(virtualBalances[_user].uservUsdBalance)) {
        uint256 pnl = usdBaycValue - uint256(positive(virtualBalances[_user].uservUsdBalance));
        collateral[usdc][_user] -= pnl;
      } else if (usdBaycValue < uint256(virtualBalances[_user].uservUsdBalance)) {
        uint256 pnl = uint256(positive(virtualBalances[_user].uservUsdBalance) - usdBaycValue);
        collateral[usdc][_user] += pnl;
      }
      //realize funding reward of user;
      int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(_assetSize)) /
        virtualBalances[_user].uservBaycBalance;
      _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
      //update user balance
      virtualBalances[_user].uservBaycBalance = 0;
      virtualBalances[_user].uservUsdBalance = 0;
      // if user has not vbalance so he is not active
      _removeActiveUser(_user);
      //update the pool
      uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize -= _assetSize;
      pool.vUsdPoolSize = k / pool.vBaycPoolSize;
      //update the new pool size
      vBaycNewPoolSize -= _assetSize;
      vUsdNewPoolSize = k / vBaycNewPoolSize;
    }
    uint256 collateralValue = collateral[usdc][_user];
    uint256 discountAmount = (discountRate * collateralValue) / 100;
    collateral[usdc][_user] -= discountAmount;
    insuranceFunds += discountAmount;
  }



  //this function is called if user should be liquidated by new price
  function _hardNegativeLiquidate(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) public returns(uint256 vBaycNewPoolSize, uint256 vUsdNewPoolSize) {
    require(
      _isHardLiquidateable(_user, _vBaycNewPoolSize, _vUsdNewPoolSize),
      "User is not hard liquidatable."
    );
    vBaycNewPoolSize = _vBaycNewPoolSize;
    vUsdNewPoolSize = _vUsdNewPoolSize;
    if (virtualBalances[_user].uservBaycBalance > 0) {
      
      uint256 _assetSize = uint256(virtualBalances[_user].uservBaycBalance);
      int256 negativeValue = _getNewAccountValue(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
      
      collateral[usdc][_user] = 0;
      virtualBalances[_user].virtualCollateral = 0;
      //update user balance
      virtualBalances[_user].uservBaycBalance = 0;
      virtualBalances[_user].uservUsdBalance = 0;
      // if user has not vbalance so he is not active
        _removeActiveUser(_user);
      //update the pool
      uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize += _assetSize;
      pool.vUsdPoolSize = k / pool.vBaycPoolSize;
      //update the new pool size
      vBaycNewPoolSize += _assetSize;
      vUsdNewPoolSize = k / vBaycNewPoolSize;
      // reduce short users virtual collateral
      int256 allShortBaycBalance = getAllShortvBaycBalance();
      for (uint256 i = 0; i < activeUsers.length; i++) {
          address user = activeUsers[i];
          if (virtualBalances[_user].uservBaycBalance < 0) {
            uint256 liquidationCover = (uint(negativeValue) * positive(virtualBalances[_user].uservBaycBalance))/positive(allShortBaycBalance);
            virtualBalances[_user].virtualCollateral -= int256(liquidationCover);
          }
      }

    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      uint256 _assetSize = uint256(positive(virtualBalances[_user].uservBaycBalance));
      int256 negativeValue = _getNewAccountValue(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);

      
      collateral[usdc][_user] = 0;
      virtualBalances[_user].virtualCollateral = 0;
      
      //update user balance
      virtualBalances[_user].uservBaycBalance = 0;
      virtualBalances[_user].uservUsdBalance = 0;
      // if user has not vbalance so he is not active
      _removeActiveUser(_user);
      //update the pool
      uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize -= _assetSize;
      pool.vUsdPoolSize = k / pool.vBaycPoolSize;
      //update the new pool size
      vBaycNewPoolSize -= _assetSize;
      vUsdNewPoolSize = k / vBaycNewPoolSize;
      // reduce long users virtual collateral
      int256 allLongvBaycBalance = getAllLongvBaycBalance();
      for (uint256 i = 0; i < activeUsers.length; i++) {
          address user = activeUsers[i];
          if (virtualBalances[_user].uservBaycBalance > 0) {
             uint256 liquidationCover = ( uint(negativeValue)* uint256(virtualBalances[_user].uservBaycBalance)) /
             uint256(allLongvBaycBalance);
             virtualBalances[_user].virtualCollateral -= int256(liquidationCover);
          }
      }
    }
  }

  //calculate liquidation amount to turn back the user margin to the save level(60%)
  function calculatePartialLiquidateValue(address _user) public view returns (uint256 x) {
    int256 totalAccountValue = getAccountValue(_user);
    uint256 totalPositionNotional = getPositionNotional(_user);
    uint256 numerator =  totalPositionNotional*saveLevelMargin/100 - positive(totalAccountValue);
    uint256 denominator = saveLevelMargin - discountRate;
    x = numerator*100/denominator;
  }

  //calculate liquidation amount to turn back the user margin to the save level(60%) according to the new price
  function _calculatePartialLiquidateValue(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal view returns (uint256) {
    int256 totalAccountValue = _getNewAccountValue(_user, _vBaycNewPoolSize, _vUsdNewPoolSize);
    uint256 totalPositionNotional = _getNewPositionNotional(
      _user,
      _vBaycNewPoolSize,
      _vUsdNewPoolSize
    );
    uint256 numerator =  totalPositionNotional*saveLevelMargin/100 - positive(totalAccountValue);
    uint256 denominator = saveLevelMargin - discountRate;
    uint x = numerator*100/denominator;
    return x;
  }

  

  

  //Liquidate user partialy according to the new price
  function _partialLiquidate(
    address _user,
    uint256 _vBaycNewPoolSize,
    uint256 _vUsdNewPoolSize
  ) internal returns(uint vBaycNewPoolSize, uint vUsdNewPoolSize) {
    require(
      _isPartialLiquidateable(_user, _vBaycNewPoolSize, _vUsdNewPoolSize),
      "user can not be partially liquidated"
    );
    vBaycNewPoolSize = _vBaycNewPoolSize;
    vUsdNewPoolSize = _vUsdNewPoolSize;

    uint256 liquidateAmount = _calculatePartialLiquidateValue(
      _user,
      _vBaycNewPoolSize,
      _vUsdNewPoolSize
    );
    uint baycLiquidateAmount = liquidateAmount*pool.vBaycPoolSize/pool.vUsdPoolSize;
    // return BaycLiquidateAmount;
    if (virtualBalances[_user].uservBaycBalance > 0) {
      // _closeLongPosition(_user, baycLiquidateAmount);

      //get the output usd of closing position
      uint256 usdBaycValue = getShortVusdAmountOut(baycLiquidateAmount);
      int256 userPartialvUsdBalance = (virtualBalances[_user].uservUsdBalance * int256(baycLiquidateAmount)) /
        virtualBalances[_user].uservBaycBalance;

      //increase or decrease the user pnl for this function
      if (usdBaycValue > (positive(userPartialvUsdBalance))) {
        uint256 pnl = usdBaycValue - (positive(userPartialvUsdBalance));
        collateral[usdc][_user] += pnl;
      } else if (usdBaycValue < (positive(userPartialvUsdBalance))) {
        uint256 pnl = (positive(userPartialvUsdBalance) - usdBaycValue);
        collateral[usdc][_user] -= pnl;
      }
      //realize funding reward of user;
      int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(baycLiquidateAmount)) /
        virtualBalances[_user].uservBaycBalance;
      _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
      //update user balance
      virtualBalances[_user].uservBaycBalance -= int256(baycLiquidateAmount);
      virtualBalances[_user].uservUsdBalance += absoluteInt(userPartialvUsdBalance);
      // if user has not vbalance so he is not active
      if (virtualBalances[_user].uservBaycBalance == 0 && virtualBalances[_user].uservUsdBalance == 0) {
        _removeActiveUser(_user);
      }
      //update the pool
      uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize += baycLiquidateAmount;
      pool.vUsdPoolSize = k / pool.vBaycPoolSize;
      //update the newPoolSize
      vBaycNewPoolSize += baycLiquidateAmount;
      vUsdNewPoolSize = k/vBaycNewPoolSize;
    } else if (virtualBalances[_user].uservBaycBalance < 0) {
      //get the output usd of closing position
      uint256 usdBaycValue = getLongVusdAmountOut(baycLiquidateAmount);
      int256 userPartialvUsdBalance = (virtualBalances[_user].uservUsdBalance * int256(baycLiquidateAmount)) /
        virtualBalances[_user].uservBaycBalance;
      //increase or decrease pnl of the user
      if (usdBaycValue > uint256(positive(userPartialvUsdBalance))) {
        uint256 pnl = usdBaycValue - uint256(positive(userPartialvUsdBalance));
        collateral[usdc][_user] -= pnl;
      }
      if (usdBaycValue < (positive(userPartialvUsdBalance))) {
        uint256 pnl = (positive(userPartialvUsdBalance) - usdBaycValue);
        collateral[usdc][_user] += pnl;
      }
      //realize funding reward of user;
      int256 realizeVirtualCollAmount = (virtualBalances[_user].virtualCollateral * int256(baycLiquidateAmount)) /
        virtualBalances[_user].uservBaycBalance;
      _realizevirtualCollateral(_user, absoluteInt(realizeVirtualCollAmount));
      //update user balance
      virtualBalances[_user].uservBaycBalance += int256(baycLiquidateAmount);
      virtualBalances[_user].uservUsdBalance -= absoluteInt(userPartialvUsdBalance);
      // if user has not vbalance so he is not active
      if (virtualBalances[_user].uservBaycBalance == 0 && virtualBalances[_user].uservUsdBalance == 0) {
        _removeActiveUser(_user);
      }
      //update pool
      uint256 k2 = pool.vBaycPoolSize * pool.vUsdPoolSize;
      pool.vBaycPoolSize -= baycLiquidateAmount;
      pool.vUsdPoolSize = k2 / pool.vBaycPoolSize;
      //update the newPoolSize
      vBaycNewPoolSize -= baycLiquidateAmount;
      vUsdNewPoolSize = k2/vBaycNewPoolSize;
    }
    uint256 discountAmount = (liquidateAmount * discountRate) / 100;
    collateral[usdc][_user] -= discountAmount;
    insuranceFunds += discountAmount;
  }

  

  //liquidate users according to the new price (is used only in trade trade functions)
  function _hardLiquidateUsers(uint256 _vBaycNewPoolSize, uint256 _vUsdNewPoolSize) internal returns(uint256 vBaycNewPoolSize, uint256 vUsdNewPoolSize){
    vBaycNewPoolSize = _vBaycNewPoolSize;
    vUsdNewPoolSize = _vUsdNewPoolSize;
    for (uint256 i = 0; i < activeUsers.length; i++) {
      if(activeUsers[i] != address(0)){
      bool isLiquidateable = _isHardLiquidateable(
        activeUsers[i],
        vBaycNewPoolSize,
        vUsdNewPoolSize
      );
      if (isLiquidateable == true) {
        int256 userMargin = _userNewMargin(activeUsers[i], vBaycNewPoolSize, vUsdNewPoolSize);
        if(userMargin > 0 ){
        (vBaycNewPoolSize, vUsdNewPoolSize) = _hardLiquidate(activeUsers[i], vBaycNewPoolSize, vUsdNewPoolSize);
        } else if(userMargin < 0) {
        (vBaycNewPoolSize, vUsdNewPoolSize) = _hardNegativeLiquidate(activeUsers[i], vBaycNewPoolSize, vUsdNewPoolSize);
        }
      }
    }
    }
  }

  

  //liquidate users partialy according to the new price (is used only in trade trade functions)
  function _partialLiquidateUsers(uint256 _vBaycNewPoolSize, uint256 _vUsdNewPoolSize) internal returns(uint vBaycNewPoolSize, uint vUsdNewPoolSize) {
    vBaycNewPoolSize = _vBaycNewPoolSize;
    vUsdNewPoolSize = _vUsdNewPoolSize;
    for (uint256 i = 0; i < activeUsers.length; i++) {
      if(activeUsers[i] != address(0)){
      bool isPartialLiquidateable = _isPartialLiquidateable(
        activeUsers[i],
        vBaycNewPoolSize,
        vUsdNewPoolSize
      );
      if (isPartialLiquidateable == true) {
        (vBaycNewPoolSize, vUsdNewPoolSize) = _partialLiquidate(activeUsers[i], vBaycNewPoolSize, vUsdNewPoolSize);
      }
    }
    }
  }


  

  function getAllLongvBaycBalance() public view returns (int256) {
    int256 allLongBaycBalance;
    for (uint256 i; i < activeUsers.length; i++) {
      address user = activeUsers[i];
      int256 vBaycBalance = virtualBalances[user].uservBaycBalance;
      if (vBaycBalance > 0) {
        allLongBaycBalance += vBaycBalance;
      }
    }
    return allLongBaycBalance;
  }

  function getAllShortvBaycBalance() public view returns (int256) {
    int256 allShortBaycBalance;
    for (uint256 i; i < activeUsers.length; i++) {
      address user = activeUsers[i];
      int256 vBaycBalance = virtualBalances[user].uservBaycBalance;
      if (vBaycBalance < 0) {
        allShortBaycBalance += vBaycBalance;
      }
    }
    return allShortBaycBalance;
  }

  function setFundingRate() public onlyOwner {
    uint256 currentPrice = pool.vUsdPoolSize*1e18/pool.vBaycPoolSize;
    uint256 oraclePrice = showPriceUSD();

    //first the contract check actual vBayc positions balance of users
    int256 allLongvBaycBalance = getAllLongvBaycBalance();
    int256 allShortBaycBalance = getAllShortvBaycBalance();

    //check if we dont have one side(long or short balance = 0) this funding action will not run
    if (allLongvBaycBalance > 0 && allShortBaycBalance < 0) {
      if (currentPrice > oraclePrice) {
        int256 minOpenInterest = (
          absoluteInt(allLongvBaycBalance) > absoluteInt(allShortBaycBalance)
            ? absoluteInt(allShortBaycBalance)
            : absoluteInt(allLongvBaycBalance)
        );
        uint difference = currentPrice - oraclePrice;
        uint256 fundingFee = (uint256(minOpenInterest) * difference) / 24e18;
        for (uint256 i = 0; i < activeUsers.length; i++) {
          address user = activeUsers[i];
          if (virtualBalances[user].uservBaycBalance > 0) {
            //change vitraul collateral of user
            uint256 userFundingFee = (fundingFee * uint256(virtualBalances[user].uservBaycBalance)) /
              uint256(allLongvBaycBalance);
            virtualBalances[user].virtualCollateral -= int256(userFundingFee);
          } else if (virtualBalances[user].uservBaycBalance < 0) {
            //change vitraul collateral of user
            uint256 userFundingFee = (fundingFee * positive(virtualBalances[user].uservBaycBalance))/positive(allShortBaycBalance);
            virtualBalances[user].virtualCollateral += int256(userFundingFee);
          }
        }
      } else if (currentPrice < oraclePrice) {
        int256 minOpenInterest = (
          absoluteInt(allLongvBaycBalance) > absoluteInt(allShortBaycBalance)
            ? absoluteInt(allShortBaycBalance)
            : absoluteInt(allLongvBaycBalance)
        );
        uint difference = oraclePrice - currentPrice;
        uint256 fundingFee = (uint256(minOpenInterest)*difference)/24e18;
        for (uint256 i = 0; i < activeUsers.length; i++) {
          address user = activeUsers[i];
          if (virtualBalances[user].uservBaycBalance > 0) {
            //change vitraul collateral of user
            uint256 userFundingFee = (fundingFee * uint256(virtualBalances[user].uservBaycBalance)) /
            uint256(allLongvBaycBalance);
            virtualBalances[user].virtualCollateral += int(userFundingFee);
          } else if (virtualBalances[user].uservBaycBalance < 0) {
            //change vitraul collateral of user
            uint256 userFundingFee = (fundingFee * positive(virtualBalances[user].uservBaycBalance)) /
              positive(allShortBaycBalance);
            virtualBalances[user].virtualCollateral -= int(userFundingFee);
          }
        }
      }
    }
  }





  //return positive int
  function absoluteInt(int256 _value) public view returns (int256) {
    if (_value < 0) {
      return -(_value);
    } else {
      return _value;
    }
  }

  //return false if new price go further than the oracle price
  function isPriceIntheRightRange(uint256 _vBaycNewPoolSize, uint256 _vUsdNewPoolSize)
    public
    view
    returns (bool)
  {
    uint256 currentPrice = 1e18*pool.vUsdPoolSize / pool.vBaycPoolSize;
    uint256 oraclePrice = showPriceUSD();
    uint256 newPrice = 1e18*_vUsdNewPoolSize / _vBaycNewPoolSize;

    int256 currentDifference = int256(oraclePrice) - int256(currentPrice);
    int256 currentDifferencePercentage = (100 * currentDifference) / int256(currentPrice);
    int256 currentDifferenceDistance = absoluteInt(currentDifferencePercentage) - 10;
    
    int256 newDifference = int256(oraclePrice) - int256(newPrice);
    int256 newDifferencePercentage = (100 * newDifference) / int256(newPrice);
    int256 newDifferenceDistance = absoluteInt(newDifferencePercentage) - 10;

    if (currentDifferenceDistance > 0) {
      //we are outside the target range and need to be brought back
      if (newDifferenceDistance < currentDifferenceDistance) {
        return true; //trade allowed, we move closer
      } else {
        return false; //trade is not allowed, we move more distant
      }
    } else {
      //we are inside the target range
      if (newDifferenceDistance < 10) {
        return true; //trade allowed we stay within target range.
      } else {
        return false;
      }
    }
  }


  // remove insurance funds from contract to owner account
  function removeInsuranceFunds(uint _amount) public onlyOwner {
    require(_amount <= insuranceFunds, "Requested collect amount is larger than the ContractFee balance.");
    SafeERC20.safeTransfer(IERC20(usdc), msg.sender, _amount);
    insuranceFunds -= _amount;
  }

  function isLongInRightRange(uint256 _usdAmount) public view returns(bool){
   uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize + _usdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    bool isInTheRightRange = isPriceIntheRightRange(newvBaycPoolSize, newvUsdPoolSize);
    return isInTheRightRange;
  }

  function isShortInRightRange(uint256 _usdAmount) public view returns(bool){
    uint256 k = pool.vBaycPoolSize * pool.vUsdPoolSize;
    uint256 newvUsdPoolSize = pool.vUsdPoolSize - _usdAmount;
    uint256 newvBaycPoolSize = k / newvUsdPoolSize;
    bool isInTheRightRange = isPriceIntheRightRange(newvBaycPoolSize, newvUsdPoolSize);
    return isInTheRightRange;
  }

  function marketPrice() public view returns(uint){
    return 1e18*pool.vUsdPoolSize / pool.vBaycPoolSize;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}