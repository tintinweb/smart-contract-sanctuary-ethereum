// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A staking farm with native reward tokens
/// @author Bilal Backer
/// @notice This smart contract deals with the staking and rewards of coins
/// @dev This smart contract deals with the staking and rewards of coins

/** LIBRARIES*/
/// ownership established
import "Ownable.sol";
/// for ERC20 interactions
import "IERC20.sol";
/// to fetch price from chainlink price feed
import "AggregatorV3Interface.sol";

// erc20 library
/** SMART CONTRACT*/
contract MetaBillFarm is Ownable {
    /** STATE VARIABLES*/
    /** ENUMS*/
    /** STRUCTS*/
    /** MAPPINGS*/
    /// mapping token address -> staker address -> amount
    /// @ stakeTokens, updateUniqueTokensStaked, getUserUniquesTokenValue, unstakeTokens
    mapping(address => mapping(address => uint256)) public stakingBalance;
    /// track the uinque tokens staked by the staker
    /// @ stakeTokens, unstakeTokens, updateUniqueTokensStaked
    /// @ getuserTotalValue, getUserUniqueTokenValue
    mapping(address => uint256) public uniqueTokenStaked;
    /// token address -> pricefeed
    /// @ setPriceFeed, getTokenValue
    mapping(address => address) public tokenPriceFeed;
    /** ARRAYS*/
    /// list of tokens availble for staking
    /// @ tokenIsAllowed,
    address[] public allowedTokens;
    /// list of stakers
    /// @ stakeTokens, issueTokens
    address[] public stakers;
    /** MODIFIERS*/
    /** EVENTS*/
    /** TOKENS*/
    /// load MetabBillCoin
    IERC20 public metaBillCoin;

    /** CONSTRUCTOR*/
    constructor(address _metaBillCoin) public {
        metaBillCoin = IERC20(_metaBillCoin);
    }

    /** FUNCTIONS*/
    /// stake the tokens
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Invalid number of tokens to be staked.");
        /// check if the token is availble for staking
        require(
            tokenIsAllowed(_token),
            "The token is not allowed for staking. Please check back later."
        );
        /// transfer request of token from the caller's address to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        /// update the number of tokens the staker staked
        updateUniqueTokensStaked(msg.sender, _token);
        /// update the staking balance of the staker
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        //////////////////////////////////////////////////////////////////
        /// CHECK ND REWORK THSI LOGIC
        /////////////////////////////////////////////////////////////////
        /// if this is the first staking by the user, add him to the stakers list
        if (uniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /// unstake the tokens
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "This token is not stked by you");
        /// check if the token is availble for staking
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] - 1;
    }

    /// Add tokens for available to be staked
    /// only by owner
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /// check if the token is availble for staking
    /// @ stakeTokens
    function tokenIsAllowed(address _token) public returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    //////////////////////////////////////////////////////////////////
    /// CHECK THE LOGIC
    /////////////////////////////////////////////////////////////////
    /// update the stakers account with each tokens staked
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            /////////////////////////////////////////////////////////////////
            /// CHECK THE IF THE NUMBER IS INCREMENTED FOR EACH TOKEN ADDITION or its 1 always
            /////////////////////////////////////////////////////////////////
            uniqueTokenStaked[_user] = uniqueTokenStaked[_user] + 1;
        }
    }

    /// issue the native tokens for stakers in the predefined ratio
    function issueTokens(address _token) public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == _token) {
                address recipient = stakers[i];
                uint256 userTotalValue = getUserTotalValue(recipient);
                ///send the token reward
                metaBillCoin.transfer(recipient, userTotalValue);
            }
        }
    }

    /// Compute the users total value staked
    /// @ issueTokens
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] > 0, "No tokens staked by the user");
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            /// compute the value of unique tokens staked
            totalValue =
                totalValue +
                getUserUniqueTokenValue(_user, allowedTokens[i]);
        }
        return totalValue;
    }

    /// compute the value of unique tokens staked
    /// @ getuserTotalValue
    function getUserUniqueTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        //////////////////////////////////////////////////////////////////
        /// CHECK THE NEED
        /////////////////////////////////////////////////////////////////
        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }
        /// get price of the staked token * staked qty of token
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * (price * 10**decimals));
    }

    /// get price of the staked token * staked qty of token
    /// @ getUserUniqueTokenValue
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeed[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    /// set the price feed address of tokens
    /// @
    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeed[_token] = _priceFeed;
    }

    /// remove the user from stakers list if he has no single coin staked
    function removeStaker() public {}
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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