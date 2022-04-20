// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingETH is ReentrancyGuard{
    /* INTERFACES */
    AggregatorV3Interface internal priceFeed;
    IERC20 public devUSDC;

    /* STATE VARIABLES */
    
    /// @notice last time this contract was called.
    uint256 private lastUpdateTime; 

    /// @notice the amount of reward rate divided by total supply in a time x, 
    /// @dev this is calculated in the rewardPerToken function.
    uint256 private rewardPerTokenStored; 

    /// @notice total amount of ETH in stake.
    uint256 private _totalSupply;

    /// @dev after a few tests this was the value that I found for have the 10%APR with 3 accounts stake 5ETH each.
    /// @dev they are in wei, so its like 0.0000000475 per second.
    /// @dev when rewards are issued they are converted to devUSDC via oracle.
    uint256 private constant REWARD_RATE = 47500000000;

    /* EVENTS */

    /// @dev Emitted when stake ETH
    event Staked(address indexed user, uint256 indexed amount);

    /// @dev Emitted when widthdraw ETH in stake
    event WithdrewStake(address indexed user, uint256 indexed amount);

    /// @dev Emitted when claim rewards
    event RewardsClaimed(address indexed user, uint256 indexed amount);


    /// @notice Update the reward when an account stake eth, withdraw eth or issue the rewards.
    /// @dev we recalculated the rewardPerTokenStored calling rewardPerToken().
    /// @dev set the new update with the last timestamp.
    /// @dev we update account rewards with the amount of earnings calling earned().
    /// @dev and then we update the userRewardPerTokenPaid with the recalculated rewardPerTokenStored.
    /// @param account who will receive the rewards update.
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    /// @notice store the rewards for rewardPerTokenStored when an account calls one of these functions: stake() ,  withdraw() or claimdevUSDC()
    mapping(address => uint256) private userRewardPerTokenPaid;

    /// @notice store the rewards when an account calls one of these functions: stake() ,  withdraw() or claimdevUSDC()
    /// @dev I made it public just for testing, but it's good practice to keep it private and create view functions to read the data
    mapping(address => uint256) public rewards;

    /// @notice store the amount of eth an account have in stake
    /// @dev I made it public just for testing, but it's good practice to keep it private and create view functions to read the data
    mapping(address => uint256) public _balances;


/*  0x8A753747A1Fa494EC906cE90E9f37563A8AF630e  rinkeby 
    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 mainnet 
    if you are going to test it locally, put the mainnet address inside the constructor
*/ 

/// @notice initializing the contract
/// @dev initializing the contract storing the oracle chainlink address 
/// @param _devUSDC  ERC20 dUSDC address
    constructor(address _devUSDC) {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        devUSDC = IERC20(_devUSDC);
    }

    /* EXTERNAL FUNCTIONS */

    /// @notice send ETH to the contract for Stake 
    function stake()
        external
        payable
        nonReentrant
        updateReward (msg.sender)
    {
        require(msg.value >= 5 ether, "need at least 5ETH to stake");
        _totalSupply += msg.value;
        _balances[msg.sender] += msg.value;
        
        emit Staked(msg.sender, msg.value);
    }


    /// @notice withdraw an amount in stake
    /// @param _amount ETH amount you want to withdraw
    function withdraw(uint256 _amount)
        external
        nonReentrant
        updateReward (msg.sender)
    {
        require(_balances[msg.sender] >= _amount, "insuficient amount");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "error");

        emit WithdrewStake(msg.sender, _amount);
    }

    /// @notice issue your rewards in USDC from your stake period
    /// @dev we use `rewardUSDC()` to get the ETH price provided by the oracle
    /// @dev so we can convert it to the amount in dUSDC
    function claimdevUSDC()
        external
        nonReentrant
        updateReward (msg.sender)
    {
        require(rewards[msg.sender] > 0, "no rewards to claim");
        uint reward = rewardUSDC(msg.sender);
        rewards[msg.sender] = 0;
        devUSDC.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    /* VIEW FUNCTIONS */

    /// @notice rewardPerTokenStored function converted to dUSDC
    function getRewardPerTokenStoredUSDC() public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (rewardPerTokenStored)/1e18);
    }

    /// @notice rewardsPerToken function converted to dUSDC
    function rewardPerTokenUSDC() public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (rewardPerToken())/1e18);
    }

    /// @notice rewards earned function converted to dUSDC
    function earnedUSDC(address account) public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (earned(account))/1e18);
    }

    /// @notice rewards mapping converted to dUSDC
    function rewardUSDC(address account) public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (rewards[account])/1e18);
    }

    /// @notice _balances mapping converted to dUSDC
    function _balancesUSDC(address account) public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (_balances[account])/1e18);
    }

    /// @notice userRewardPerTokenPaid mapping converted to dUSDC
    function userRewardPerTokenPaidUSDC(address account) public view returns (uint256) {
        return ((getEthPrice() * 10e9) * (userRewardPerTokenPaid[account])/1e18);
    }

    /// @notice Ether price from chainlink
    function getEthPrice() public view returns(uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return (uint256(price));
    }

    /// @notice last time this contract was called
    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdateTime;
    }

    /// @notice get total ETH in stake
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice get reward rate
    function getRewardRate() public pure returns (uint256) {
        return REWARD_RATE;
    }

    /* PRIVATE FUNCTIONS */
    /// @notice calculate the rewardPerTokenStored
    /// @dev the calculation is: reward rate times staked time divided by totalsupply.
    /// @dev We multiply by 1e18 because _totalSupply is in wei
    /// @return 0 if there is no eth in stake. If greater than 0, calculate the rewardPerTokenStored.
    function rewardPerToken() private view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / _totalSupply);
    }

    /// @notice calculate the amount of tokens a account earned yet.
    /// @dev the calculation is: stake balance of an account times the difference between rewardsPerToken() and rewardPerTokenStored of an account divided by 1e18 (since they are in wei). By the end we add this calculation to rewards of an account
    /// @return the calculation
    function earned(address account) private view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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