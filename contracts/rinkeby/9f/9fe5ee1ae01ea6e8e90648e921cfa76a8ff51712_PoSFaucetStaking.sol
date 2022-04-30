/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface ChainlinkAggregatorV3Interface {
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

contract PoSFaucetStaking is Ownable {
  uint public totalStakeBalance;
  uint public cfgLockTime;
  uint public cfgMinStake;
  uint public cfgMaxStake;
  uint public cfgStakeValue;

  bool public cfgEnableDynLock;
  uint public cfgMinDynLockTime;
  uint public cfgMaxDynLockTime;

  address private _cfgPriceFeed;
  uint private _faucetEventIdx;
  mapping(address => uint) private _stakeBalance;
  mapping(address => uint) private _stakeLockTime;

  event StakeDeposit(address indexed staker, uint eventIdx, uint balance, uint locktime, int price);
  event StakeWithdraw(address indexed staker, uint eventIdx, uint balance);
  
  constructor() {
    cfgLockTime = 1 weeks;
  }

  function setStakeCfg(uint lockTime, uint minStake, uint maxStake, uint stakeValue) public onlyOwner {
    // config applies to new deposits only, so rules don't change for already deposited funds
    cfgLockTime = lockTime;
    cfgMinStake = minStake;
    cfgMaxStake = maxStake;
    cfgStakeValue = stakeValue;
  }

  function setLockCfg(bool enableDynLock, uint minLockTime, uint maxLockTime) public onlyOwner {
    // config for user defined lock-in times
    cfgEnableDynLock = enableDynLock;
    cfgMinDynLockTime = minLockTime;
    cfgMaxDynLockTime = maxLockTime;
  }

  function setPriceFeed(address priceFeed) public onlyOwner {
    _cfgPriceFeed = priceFeed;
  }

  function getPrice() public view returns (int) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = ChainlinkAggregatorV3Interface(_cfgPriceFeed).latestRoundData();
    return price;
  }

  function getStakeBalance(address addr) public view returns (uint) {
    return _stakeBalance[addr];
  }

  function getStakeLockTime(address addr) public view returns (uint) {
    return _stakeLockTime[addr];
  }

  function deposit() public payable {
    require(block.timestamp + cfgLockTime >= _stakeLockTime[msg.sender], "cannot decrease lock-in time of previously locked funds");
    depositAndLock(cfgLockTime);
  }

  function depositDynLock(uint lockTime) public payable {
    require(cfgEnableDynLock, "dynamic lock-in time disabled");
    require(lockTime >= cfgMinDynLockTime, "lock-in time lower than allowed minimum");
    require(cfgMaxDynLockTime == 0 || lockTime <= cfgMaxDynLockTime, "lock-in time higher than allowed maximum");
    require(block.timestamp + lockTime >= _stakeLockTime[msg.sender], "cannot decrease lock-in time of previously locked funds");
    depositAndLock(lockTime);
  }

  function depositAndLock(uint lockTime) private {
    uint stakedBalance = _stakeBalance[msg.sender];
    (uint stakeAmount, int price) = getDepositStakeAmount(stakedBalance);
    if(msg.value > stakeAmount) {
      // refund funds not used for staking
      (bool sent, ) = msg.sender.call{value: msg.value - stakeAmount}("");
      require(sent, "failed to send refund");
    }

    stakedBalance += stakeAmount;
    totalStakeBalance += stakeAmount;
    _stakeBalance[msg.sender] = stakedBalance;
    _stakeLockTime[msg.sender] = block.timestamp + lockTime;

    uint eventIdx = _faucetEventIdx++;
    emit StakeDeposit(msg.sender, eventIdx, stakeAmount, lockTime, price);
  }

  function getDepositStakeAmount(uint stakedBalance) private returns (uint, int) {
    uint stakeAmount;
    int price = 0;
    uint fixedStakeValue = cfgStakeValue;
    if(fixedStakeValue != 0) {
      // fixed stake value
      require(stakedBalance == 0, "sender is already staking");

      if(_cfgPriceFeed != address(0)) {
        // calculate stake amount by price
        price = getPrice();
        require(price > 0, "price feed failure");

        stakeAmount = 1000000000000000000 * fixedStakeValue / uint(price);
      }
      else {
        // fixed stake amount
        stakeAmount = fixedStakeValue;
      }

      require(msg.value >= stakeAmount, "not enough funds");
    }
    else {
      // dynamic stake value

      uint maxStake = cfgMaxStake;
      uint totalStake = stakedBalance + msg.value;
      require(totalStake >= cfgMinStake, "stake amount lower than allowed minimum");
      require(totalStake == 0 || totalStake <= maxStake, "stake amount higher than allowed maximum");

      stakeAmount = msg.value;
    }

    return (stakeAmount, price);
  }

  function withdraw() public {
    uint balance = _stakeBalance[msg.sender];

    require(balance > 0, "insufficient funds");
    require(block.timestamp > _stakeLockTime[msg.sender], "lock time has not expired");

    totalStakeBalance -= balance;
    _stakeBalance[msg.sender] = 0;

    // send the ether back to the sender
    (bool sent, ) = msg.sender.call{value: balance}("");
    require(sent, "failed to send ether");

    uint eventIdx = _faucetEventIdx++;
    emit StakeWithdraw(msg.sender, eventIdx, balance);
  }

}