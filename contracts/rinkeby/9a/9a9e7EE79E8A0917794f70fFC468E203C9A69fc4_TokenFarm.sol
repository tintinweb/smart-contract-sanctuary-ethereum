/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: TokenFarm.sol

/// @title A stake-and-yield contract to be interacted with via web application
/// @dev The terms "user" and "staker" are used interchangeably
contract TokenFarm is Ownable {
    IERC20 nellarium;
    address[] public allowedTokens;

    /* details of users/stakers -- keeping track of:
        - balance of each token they have staked (token => staker => amt)
        - number of unique tokens they have staked (staker => amtOfUniqueTokens)
        - who the stakers are
    */
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    address[] public stakers;

    // mapping of tokens to their price feed addresses
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _NellariumAddress) {
        nellarium = IERC20(_NellariumAddress);
    }

    /* core functions */
    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // what tokens can they stake?
        require(
            tokenIsAllowed(_token),
            "Token you are trying to stake is not permitted to be staked."
        );

        // how much can they stake?
        require(_amount > 0, "Amount to stake must be greater than 0.");

        // user is staking a token
        updateUniqueTokensStaked(msg.sender, _token);

        // transfer tokens to our farm
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // update staker details in contract
        stakingBalance[_token][msg.sender] += _amount;

        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 stakedBalance = stakingBalance[_token][msg.sender];
        require(stakedBalance > 0, "Staked balance cannot be 0.");

        IERC20(_token).transfer(msg.sender, stakedBalance);

        stakingBalance[_token][msg.sender] = 0; // re-entrancy attack?
        uniqueTokensStaked[msg.sender] -= 1;

        // remove msg.sender from stakers if they have no more staked tokens
        removeFromStakers(msg.sender);
    }

    function issueTokens() public onlyOwner {
        // issue tokens to all stakers
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];

            // send recipient a token reward based on their total value locked
            uint256 userTotalStakedValue = getUserTotalStakedValue(recipient);
            nellarium.transfer(recipient, userTotalStakedValue);
        }
    }

    /* helper functions */
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }

        return false;
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] += 1;
        }
    }

    function getUserTotalStakedValue(address _user)
        public
        view
        returns (uint256)
    {
        uint256 totalStakedValue = 0;

        if (uniqueTokensStaked[_user] > 0) {
            for (uint256 i = 0; i < allowedTokens.length; i++) {
                totalStakedValue += getUserSingleTokenStakedValue(
                    _user,
                    allowedTokens[i]
                );
            }
        }

        return totalStakedValue;
    }

    /// @notice Get the USD value of a staker's specific staked token
    /// @param _user The address of the staker
    /// @param _token The address of the specific token we want to get the USD value for
    /// @return The USD value of _user's staked _token(s)
    function getUserSingleTokenStakedValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            // user has no tokens staked -- value is obviously 0
            return 0;
        }

        // usdValue = stakingBalance[_token][_user] * price of the token in USD
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    /// @notice Get the USD value of a single unit (1) of a token, and the decimals of that token
    /// @param _token The address of the token we want the USD value for
    /// @return The USD value of 1 _token
    /// @return The decimals of _token
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());

        return (uint256(price), decimals);
    }

    /// @notice Remove a staker from the stakers list if they have no more unique tokens staked
    /// @param _user The address of the staker to potentially be removed
    function removeFromStakers(address _user) internal {
        if (uniqueTokensStaked[_user] <= 0) {
            // get the index of _user in stakers
            uint256 stakerIndex;
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == _user) {
                    stakerIndex = i;
                    break;
                }
            }

            // move the last element of stakers into the place of the staker to be deleted
            stakers[stakerIndex] = stakers[stakers.length - 1]; // this essentially removes _user from stakers list

            // remove the last element -- no duplicates
            stakers.pop();
        }
    }
}