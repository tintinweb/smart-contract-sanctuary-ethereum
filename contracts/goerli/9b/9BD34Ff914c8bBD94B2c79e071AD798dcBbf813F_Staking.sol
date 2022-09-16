/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
@title A contract for staking some specific tokens to earn profit with a special rate for each one by the end of 30 days that staked tokens have been locked.
@author Shack
@notice By staking your tokens, you won't be able to reach them within a month; after 30 days, you can withdraw both staked and rewarded tokens.
@dev This contract works with Chainlink AggregatorV3Interface, so ensure that contract addresses are all up to date.
*/

import "IERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "AggregatorV3Interface.sol";

contract Staking is Ownable, ReentrancyGuard {
    mapping(address => bool) public tokenIsApproved;
    mapping(address => uint8) public tokensToRate;
    mapping(address => address) public tokensToPriceFeed;
    mapping(address => mapping(address => uint256)) public tokenToUserBalance;
    mapping(address => mapping(uint256 => uint256))
        public tokenAmountToStakingTime;
    mapping(address => mapping(address => uint256)) public tokenToUserReward;
    uint256 public unstakeTime;
    IERC20 public rewardToken;
    event Staked(
        address indexed investor,
        address indexed token,
        uint256 indexed amount
    );
    event Unstaked(
        address indexed investor,
        address indexed token,
        uint256 indexed amount
    );
    event Claimed(
        address indexed investor,
        address indexed token,
        uint256 indexed amount
    );

    constructor(address _rewardToken, uint256 _unstakeTime) {
        rewardToken = IERC20(_rewardToken);
        unstakeTime = _unstakeTime;
    }

    /// @param _token A new token address that can be staked in the future.
    /// @param _rate _token will be rewarded with this rate.
    /// @param _priceFeed Chainlink data feed contract address of _token.
    /// @dev Once a token's added to the contract within this function user can stake them.
    function setTokensData(
        address _token,
        uint8 _rate,
        address _priceFeed
    ) public onlyOwner {
        tokensToRate[_token] = _rate;
        tokensToPriceFeed[_token] = _priceFeed;
        tokenIsApproved[_token] = true;
    }

    /// @param _token  Token address that should be disapproved for staking.
    /// @dev Once a token's disapproved, people won't be able to stake them.
    function changeTokenApproval(address _token) public onlyOwner {
        tokenIsApproved[_token] = !tokenIsApproved[_token];
    }

    /// @param _token An approved token address is to be staked.
    /// @param _amount A unique and not duplicated amount of token that is wished to be staked by a user.
    /// @notice The token address should be approved and be staked in a unique and not duplicated amount, so if a specific amount of a token was staked before by a user, another amount of it should be staked now.
    /// @dev Once a token's added to the contract within this function user can stake them.
    function stakeToken(address _token, uint256 _amount) external nonReentrant {
        require(tokenIsApproved[_token] == true, "Token isn't allowed");
        require(_amount > 0, "You should send at least some token!");
        require(
            tokenAmountToStakingTime[msg.sender][_amount] == 0,
            "You have already staked this amount!"
        );
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUserBalance(_token, msg.sender, _amount, block.timestamp);
        emit Staked(msg.sender, _token, _amount);
    }

    /// @param _token token address entered by a user to be staked.
    /// @param _user user address who called stakeToken().
    /// @param _amount A unique and not duplicated amount of token that is wished to be staked by a user.
    /// @param _stakingTime The block time in which the amount of a token is staked in it by a user.
    /// @dev This function is called by stakeToken() whenever a user calls that to stake some token to update the user's new balances.
    /// @dev the 30 days to be able to withdraw the staked amount by the user started by calling this function.
    function updateUserBalance(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _stakingTime
    ) private {
        uint256 _currentBalance = tokenToUserBalance[_token][_user];
        tokenAmountToStakingTime[_user][_amount] = _stakingTime;
        tokenToUserBalance[_token][_user] = _currentBalance + _amount;
    }

    /// @param _token Token address entered by a user for checking its total balance value in USD.
    /// @return uint256 Total token balance value of a user in USD, staked by the user.
    /// @notice This function returns the current token's total balance value in USD that the user staked. It gets this value off-chain using Chainlink oracles.
    /// @dev Current price and token decimals are got off-chain with Chainlink AggregatorV3Interface. Price feed addresses should be checked during time within Chainlink contract addresses for not being disabled. The owner can edit the new price feed address by calling setTokensData().
    function getUserBalanceValue(address _token) public view returns (uint256) {
        require(
            tokenToUserBalance[_token][msg.sender] > 0,
            "There's no fund in your account!"
        );
        (uint256 _price, uint256 _decimals) = getValue(_token);
        uint256 _balance = tokenToUserBalance[_token][msg.sender];
        return (_balance * _price) / (10**_decimals);
    }

    /// @param _token Token address for getting its current price.
    /// @return uint256 Price value in USD gets from Chainlink AggregatorV3Interface.
    /// @return uint256 token's decimals gets from Chainlink AggregatorV3Interface.
    /// @dev Price feed addresses should be checked during time within Chainlink contract addresses for not being disabled. The owner can edit the new price feed address by calling setTokenData().
    function getValue(address _token) private view returns (uint256, uint256) {
        address priceFeedAddress = tokensToPriceFeed[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price), uint256(priceFeed.decimals()));
    }

    /// @param _token Token address staked by the user.
    /// @param _amount Staked token amount of each staking.
    /// @notice This function unstakes the amount of token that had been staked by calling stakeToken() individually, not the total token amount that the user has staked. It also calculates the token staking reward.
    /// @notice This amount can be unstake if 30 days have passed of staked time.
    /// @dev unstakeTime was set within the constructor during contract creation.
    function unstakeToken(address _token, uint256 _amount)
        external
        nonReentrant
    {
        require(tokenToUserBalance[_token][msg.sender] >= _amount);
        uint256 _stakingTime = tokenAmountToStakingTime[msg.sender][_amount];
        require(block.timestamp >= _stakingTime + (unstakeTime * 1 days));
        tokenToUserBalance[_token][msg.sender] - _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        rewardCalculator(_token, _amount);
        delete tokenAmountToStakingTime[msg.sender][_amount];
        emit Unstaked(msg.sender, _token, _amount);
    }

    /// @dev This private function, called within unstakeToken(), calculates the user reward by multiplying the token staked amount by the token's rate and adds it to the rewards that the user hasn't claimed yet.
    function rewardCalculator(address _token, uint256 _amount) private {
        uint256 preReward = tokenToUserReward[_token][msg.sender];
        uint256 _reward = tokensToRate[_token] * _amount;
        tokenToUserReward[_token][msg.sender] = preReward + _reward;
    }

    /// @param _token Token address staked and unstaked by the user before.
    /// @notice This function transfers all the reward tokens that had been rewarded to the user for staking some _token.
    function claimRewards(address _token) external nonReentrant {
        require(
            tokenToUserReward[_token][msg.sender] != 0,
            "You should stake some token to get rewarded"
        );
        uint256 _reward = tokenToUserReward[_token][msg.sender];

        rewardToken.transfer(msg.sender, _reward);
        delete tokenToUserReward[_token][msg.sender];
        emit Claimed(msg.sender, _token, _reward);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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