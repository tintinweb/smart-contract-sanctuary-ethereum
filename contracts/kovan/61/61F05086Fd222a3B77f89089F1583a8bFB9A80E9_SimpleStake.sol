// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStake {
    mapping(address => mapping(address => bool)) public isStaker;
    mapping(address => mapping(address => uint256)) public amountStaked;
    mapping(address => mapping(address => uint256)) public lastRewardRedemption;
    mapping(address => mapping(address => bool)) public hasRedeemed;
    mapping(address => mapping(address => uint256)) public amountReedeemed;
    mapping(address => bool) public isAllowed;
    mapping(address => address[]) public stakers;
    mapping(address => uint256) public totalStakers; //stakers.length
    address[] public allowedTokens = [
        0xd0A1E359811322d97991E03f863a0C30C2cF029C,
        0xa36085F69e2889c224210F603D836748e7dC0088,
        0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    ];
    address public owner;
    uint256 public totalAmountStaked;

    // kovan dai/usd = 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a
    // kovan dai address

    // kovan link/usd = 0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0
    // kovan  address

    // kovan eth/usd = 0x9326BFA02ADD2366b30bacB125260Af641031331
    // kovan weth address = 0xd0A1E359811322d97991E03f863a0C30C2cF029C

    constructor() {
        owner = msg.sender;
    }

    function makeDeposit(address _token) public payable onlyAllowed(_token) {
        require(msg.value > 0, "You must deposit more than 0");
        if (!isStaker[msg.sender][_token]) {
            isStaker[msg.sender][_token] = true;
            stakers[_token].push(msg.sender);
            hasRedeemed[msg.sender][_token] = false;
        }
        amountStaked[msg.sender][_token] += msg.value;
        totalAmountStaked += msg.value;
    }

    function withdrawl(address _token) public payable onlyAllowed(_token) {
        require(isStaker[msg.sender][_token], "You dont have anything staked");
        require(
            amountStaked[msg.sender][_token] >= msg.value,
            "You dont have enough staked"
        );
        amountStaked[msg.sender][_token] -= msg.value;
        if (amountStaked[msg.sender][_token] == 0) {
            isStaker[msg.sender][_token] = false;
            for (uint256 i; i < stakers[_token].length; i++) {
                if (stakers[_token][i] == msg.sender) {
                    stakers[_token][i] = stakers[_token][
                        stakers[_token].length - 1
                    ];
                    stakers[_token].pop();
                }
            }
        }
        totalAmountStaked -= msg.value;
        payable(msg.sender).transfer(msg.value);
    }

    function claimRewards(address _token, address _priceFeedAddress)
        public
        payable
        onlyAllowed(_token)
    {
        if (!hasRedeemed[msg.sender][_token]) {
            uint256 rewards = amountStaked[msg.sender][_token] / 100;
            hasRedeemed[msg.sender][_token] = true;
            lastRewardRedemption[msg.sender][_token] = block.timestamp;
            amountReedeemed[msg.sender][_token] += rewards;
            payable(msg.sender).transfer(rewards);
        } else {
            require(
                block.timestamp - lastRewardRedemption[msg.sender][_token] > 10,
                "you cant claim rewards yet"
            );
            uint256 wholeAmountStaked = (amountStaked[msg.sender][_token] /
                (10**18));
            uint256 usdConvert = uint256(getLatestPrice(_priceFeedAddress));
            uint256 rewards = wholeAmountStaked * usdConvert;
            lastRewardRedemption[msg.sender][_token] = block.timestamp;
            amountReedeemed[msg.sender][_token] += rewards;
            payable(msg.sender).transfer(rewards);
        }
    }

    function getLatestPrice(address _priceFeedAddress)
        public
        view
        returns (int256)
    {
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        int256 formattedPrice = price / (10**8);
        return formattedPrice;
    }

    function addAllowedTokens(address _token) public {
        require(msg.sender == owner, "You can't do this");
        allowedTokens.push(_token);
    }

    modifier onlyAllowed(address _token) {
        require(isAllowed[_token], "this token is not allowed");
        _;
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