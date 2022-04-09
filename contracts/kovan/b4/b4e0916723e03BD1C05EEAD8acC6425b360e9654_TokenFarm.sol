// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// stake tokens CHECK
// unstake tokens
// issue rewards CHECK
// add allowed tokens for staking CHECK
// get eth value of the staked tokens CHECK

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // mapping for the num of unique tokens staked by each staker to then add them to the stakers list for subsequent reward distribution
    mapping(address => uint256) public uniqueTokensStaked;
    // mapping of tokens to their price feed addresses for getTokenValue()
    mapping(address => address) public tokenPriceFeedMapping;
    // list of the tokens allowed for staking
    address[] public allowedTokens;
    // list of stakers to loop through at issueRewardTokens() as we cannot loop through a mapping
    address[] public stakers;
    // storing the reward token as a global variable
    IERC20 public rewardToken;

    // adding the reward token address when initiating the contract
    constructor(address _rewardToken) public {
        rewardToken = IERC20(_rewardToken);
    }

    // to set the price feed contract for a chosen token
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    // to issue rewards in VianuToken (VIT) for stakers
    // e.g. if a staker stakes 50 ETH and 50 DAI, we want to reward 1 VIT for each 1 DAI
    function issueRewardTokens() public onlyOwner {
        // Issue tokens to all stakers by first looping through the stakers list
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            // send them a token reward based on their TVL
            // first, getting the rewardToken set in the constructor
            // second, calculating the staker's TVL
            uint256 stakerTotalValue = getStakerTotalValue(recipient);
            // transferring 1 reward token for each 1 USD of the userTotalValue
            rewardToken.transfer(recipient, stakerTotalValue);
        }
    }

    // !!! it's gonna be very gas exepensive to loop through all addresses to find the staker and their TVL across all unique tokens
    // !!! so, many dApps prefer enabling Claim function to save on the gas fees
    function getStakerTotalValue(address _staker)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        require(
            uniqueTokensStaked[_staker] > 0,
            "This user doesn't staker any tokens."
        );
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            // adding the amount the staker has in a given token to totalValue
            // however, gotta know what currency we count totalValue in and convert the amount to that currency before adding to totalValue
            totalValue += getStakerSingleTokenValue(
                _staker,
                allowedTokens[allowedTokensIndex]
            );
        }
        return totalValue;
    }

    // to convert any token value to USD and then get staker's balance of that token in terms of USD
    function getStakerSingleTokenValue(address _staker, address _token)
        public
        view
        returns (uint256)
    {
        // using 'if' and not 'require' so that our getStakerTotalValue tx wouldn't revert
        if (uniqueTokensStaked[_staker] <= 0) {
            return 0;
        }
        // price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // e.g. (10 * 1e18) ETH * (2000 * 1e8) ETH/USD / (10**8) => getting (20000 * 1e18) USD as a result
        return ((stakingBalance[_token][_staker] * price) / (10**decimals));
    }

    // to get a USD value of a chosen token
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        // getting the token's price in USD
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // we need to ensure the decimals consistency
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), uint256(decimals));
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be higher than zero.");
        // making sure the user wants to stake an allowed token
        require(
            tokenIsAllowed(_token),
            "The token is not allowed for staking."
        );
        // calling transferFrom() not transfer() because the farm contract doesn't own the tokens we want to transfer to it from the staker
        // this means the staker will firstly need to approve the farm contract to spend their tokens
        // we also need the token's ABI to call this function so we need IERC20 and then wrap _token into IERC20
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // updating the mapping for unique tokens staked by the staker
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] += _amount;
        // now, we wanna see how many unique tokens the staker stakes to then be able to send a reward for all of them
        // if the staker is already in the stakers list, we don't add them there again
        // if that's the first unique token staked by the staker, we add the staker to the stakers list for later rewards
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        // first, how many of the token the user has
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "You don't stake any of this token.");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] += 1;
        }
    }

    // to update the list of allowed tokens
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    // to check if the token the user wants to stake is allowed
    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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