// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// importing the Ownable contract
import "Ownable.sol";
// importing the ERC20 interface
import "IERC20.sol";
// Importing AggregatorV3Interface
import "AggregatorV3Interface.sol";

// Creating the TokenFarm contract
contract TokenFarm is Ownable {
    IERC20 public malakaToken;

    //__________________________________________________________________________________________________________________________________________
    constructor(address _malakaTokenAddress) {
        malakaToken = IERC20(_malakaTokenAddress);
    }

    //__________________________________________________________________________________________________________________________________________
    // Mapping the allowedToken (key : address, value : bool)
    address[] allowedTokens;
    // Mapping the amount staked by the staker address to the token address
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // Mapping a staker account address to a token address
    // mapping (address => bool) public stakers;
    address[] public stakers;
    // Mapping the number of tokens staked by a staker address
    mapping(address => uint256) public uniqueTokensStaked;
    // Mapping the address of a pricefeed to a token address
    mapping(address => address) public tokenPriceFeedMapping;

    //__________________________________________________________________________________________________________________________________________
    // Defining the function StakeTokens that will stake an ERC Token given its address and an amount
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "The amount can't be 0");
        // Requiring that the token is an allowed one using the mapping (if not found will return a value of 0)
        require(tokenIsAllowed(_token), "Token not allowed");

        // Update the list of tokens staked by the user
        updateUniqueTokensStaked(msg.sender, _token);
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }

        // Staking the amount of token from the caller address to the TokenFarm after wrapping it to ERC20 format.
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
    }

    //__________________________________________________________________________________________________________________________________________
    // Defining the function unstakeTokens that will unstake an ERC Token given  its address
    function unstakeTokens(address _token) public {
        // Fetch staking balance
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    //__________________________________________________________________________________________________________________________________________
    // The function issueTokens will transfer to a user a reward based on its staked balance
    function issueTokens() public onlyOwner {
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            address recipient = stakers[stakerIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            malakaToken.transfer(recipient, userTotalValue);
        }
    }

    //__________________________________________________________________________________________________________________________________________
    // The function gerUserTotalTokenValue will return the balance of a user for its total tokens
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 userTotalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No token staked!");
        for (
            uint256 userTotalValueIndex = 0;
            userTotalValueIndex < allowedTokens.length;
            userTotalValueIndex++
        ) {
            userTotalValue =
                userTotalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[userTotalValueIndex]
                );
        }
        return userTotalValue;
    }

    //__________________________________________________________________________________________________________________________________________
    // The function gerUserSingleTokenValue will return the balance of a user for a specific token
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    //__________________________________________________________________________________________________________________________________________
    // The function getTokenValue will return the price of a token in USD and the number of decimals based on the token address and this
    // with calling the AggregatorV3Interface
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAdress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAdress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    //__________________________________________________________________________________________________________________________________________
    // The function tokenIsAllowed will check wether a token is in the list of allowed tokens
    function tokenIsAllowed(address _token) public returns (bool) {
        // Iterate through every element of the array and check if the address of the token is in the list of allowed tokens and returns a boolean
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

    //__________________________________________________________________________________________________________________________________________
    // The function addAllowedTokens will add a token in the list of allowed tokens
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    //__________________________________________________________________________________________________________________________________________
    // The function updateUniqueTokensStaked updates the list of tokens staked by a user
    function updateUniqueTokensStaked(address _staker, address _token)
        internal
        onlyOwner
    {
        // Check if the the balance of the staker is empty for a specific token
        if (stakingBalance[_token][_staker] == 0) {
            uniqueTokensStaked[_staker] = uniqueTokensStaked[_staker] + 1;
        }
    }

    //__________________________________________________________________________________________________________________________________________
    // Function that sets the price feed address depending on the token
    function setTokenPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
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