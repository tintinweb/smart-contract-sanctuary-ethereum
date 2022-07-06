// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HireMeStake {
    mapping(address => mapping(address => bool)) public isStaker;
    mapping(address => mapping(address => uint256)) public amountStaked;
    mapping(address => mapping(address => uint256)) public lastRewardRedemption;
    mapping(address => mapping(address => bool)) public hasRedeemed;
    mapping(address => mapping(address => uint256)) public amountReedeemed;
    mapping(address => bool) public isAllowed;
    mapping(address => address) public tokenPriceFeeds;
    address public owner;
    uint256 public totalAmountStaked;
    IERC20 public HireMeToken;

    event NewDeposit(
        address depositer,
        address token,
        uint256 amount,
        uint256 date
    );

    event NewWithdraw(
        address withdrawler,
        address token,
        uint256 amount,
        uint256 date
    );

    event RewardsRedeemed(
        address redeemer,
        address token,
        uint256 amount,
        uint256 date
    );

    constructor() {
        owner = msg.sender;
        HireMeToken = IERC20(0x8ADc4D9E41eeC6Ef65C310FCEbeFC28e14ed2d1B);
        isAllowed[0xd0A1E359811322d97991E03f863a0C30C2cF029C] = true;
        isAllowed[0xa36085F69e2889c224210F603D836748e7dC0088] = true;
        isAllowed[0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa] = true;
        tokenPriceFeeds[
            0xd0A1E359811322d97991E03f863a0C30C2cF029C
        ] = 0x9326BFA02ADD2366b30bacB125260Af641031331; //weth
        tokenPriceFeeds[
            0xa36085F69e2889c224210F603D836748e7dC0088
        ] = 0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0; //link
        tokenPriceFeeds[
            0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
        ] = 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a; //dai
    }

    function deposit(address _token, uint256 _amount)
        public
        onlyAllowed(_token)
    {
        require(_amount > 0, "You must deposit more than 0");
        if (!isStaker[msg.sender][_token]) {
            isStaker[msg.sender][_token] = true;
            hasRedeemed[msg.sender][_token] = false;
        }
        amountStaked[msg.sender][_token] += _amount;
        totalAmountStaked += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit NewDeposit(msg.sender, _token, _amount, block.timestamp);
    }

    function withdraw(address _token, uint256 _amount)
        public
        onlyAllowed(_token)
    {
        require(isStaker[msg.sender][_token], "You dont have anything staked");
        require(
            amountStaked[msg.sender][_token] >= _amount,
            "You dont have enough staked"
        );
        amountStaked[msg.sender][_token] -= _amount;
        totalAmountStaked -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        emit NewWithdraw(msg.sender, _token, _amount, block.timestamp);
    }

    function claimRewards(address _token, address _priceFeedAddress)
        public
        onlyAllowed(_token)
    {
        if (!hasRedeemed[msg.sender][_token]) {
            uint256 wholeAmountStaked = (amountStaked[msg.sender][_token]);
            uint256 usdConvert = uint256(getLatestPrice(_priceFeedAddress));
            uint256 usdStaked = wholeAmountStaked * usdConvert;
            uint256 rewards = usdStaked / 50;
            hasRedeemed[msg.sender][_token] = true;
            lastRewardRedemption[msg.sender][_token] = block.timestamp;
            amountReedeemed[msg.sender][_token] += rewards;
            HireMeToken.transfer(msg.sender, rewards);
            emit RewardsRedeemed(msg.sender, _token, rewards, block.timestamp);
        } else {
            require(
                (block.timestamp - lastRewardRedemption[msg.sender][_token]) >
                    10,
                "you cant claim rewards yet"
            );
            uint256 wholeAmountStaked = (amountStaked[msg.sender][_token]);
            uint256 usdConvert = uint256(getLatestPrice(_priceFeedAddress));
            uint256 usdStaked = wholeAmountStaked * usdConvert;
            uint256 rewards = usdStaked / 50;
            lastRewardRedemption[msg.sender][_token] = block.timestamp;
            amountReedeemed[msg.sender][_token] += rewards;
            HireMeToken.transfer(msg.sender, rewards);
            emit RewardsRedeemed(msg.sender, _token, rewards, block.timestamp);
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

    function addAllowedToken(address _token, address _priceFeed)
        public
        onlyOwner
    {
        isAllowed[_token] = true;
        tokenPriceFeeds[_token] = _priceFeed;
    }

    function removeAllowedToken(address _token) public onlyOwner {
        isAllowed[_token] = false;
    }

    function withdrawHMT() public onlyOwner {
        HireMeToken.transfer(msg.sender, HireMeToken.balanceOf(address(this)));
    }

    modifier onlyAllowed(address _token) {
        require(isAllowed[_token], "this token is not allowed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this");
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