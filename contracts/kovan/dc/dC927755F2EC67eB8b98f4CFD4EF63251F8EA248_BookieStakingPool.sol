// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract BookieStakingPool is Ownable {
    //***********MAPPINGS*********************/
    mapping(address => uint256) public stakedBookBalance;
    mapping(address => mapping(address => uint256))
        public stakedRandomTokensBalance;
    mapping(address => address) public tokenPriceFeedMapping;

    //***********ARRAYS***********************/
    address[] public allowedTokens;
    address[] public bookStakers;

    //***********STATE VARIABLES**************/
    uint256 public bookPoolBalance;
    uint256 public ethPoolBalance;
    IERC20 public bookToken;

    /**
     * @notice constructor sets IERC20 implementations of WETH and BOOK
     * @param _bookTokenAddress address
     */
    constructor(address _bookTokenAddress) {
        bookToken = IERC20(_bookTokenAddress);
    }

    /**
     * @notice function for owner to set the price feed contract for each token
     * @param _token address
     * @param _priceFeed address
     */
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function getUserTotalValueInBookiePools(address _user)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    /**
     * @notice function to retrieve value of staked tokens of one variety that user has staked
     * @param _user address
     * @param _token address
     */
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // price of the token * stakingBalance[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakedRandomTokensBalance[_token][_user] * price) /
            (10**decimals));
    }

    /**
     * @notice function to retrieve token price
     * @param _token address
     *
     */
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
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    /**
     * @notice function for owner to add tokens to the allowedTokens array
     * @param _token address
     *
     */
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /**
     * @notice function to check if token is in the allowedTokens array
     * @param _token address
     *
     */
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

    /**
     * @notice function for staking only BOOK Tokens
     * @param _amount uint256
     *
     */
    function stakeBookTokens(uint256 _amount) public {
        require(_amount > 0, "Amount must be more than 0");
        bookToken.transferFrom(msg.sender, address(this), _amount);
        stakedBookBalance[msg.sender] = stakedBookBalance[msg.sender] + _amount;
        bookStakers.push(msg.sender);
        bookPoolBalance = bookPoolBalance + _amount;
    }

    /**
     * @notice function for unstaking only BOOK Tokens
     * @param _amount uint256
     *
     */
    function unstakeBookTokens(uint256 _amount) public {
        uint256 balance = stakedBookBalance[msg.sender];
        require(
            balance > _amount,
            "Staking balance cannot be less than the amount to unstake."
        );
        bookToken.transferFrom(address(this), msg.sender, _amount);
        stakedBookBalance[msg.sender] = stakedBookBalance[msg.sender] - _amount;
        bookPoolBalance = bookPoolBalance - _amount;
    }

    /**
     * @notice function for staking any Token that is in the allowedTokens array
     * @param _amount uint256
     * @param _token address
     */
    function stakeRandomTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        stakedRandomTokensBalance[_token][msg.sender] =
            stakedRandomTokensBalance[_token][msg.sender] +
            _amount;
    }

    /**
     * @notice function for unstaking any token you have staked other than BOOK
     * @param _amount uint256
     * @param _token address
     */
    function unstakeRandomTokens(address _token, uint256 _amount) public {
        uint256 balance = stakedRandomTokensBalance[_token][msg.sender];
        require(
            balance > _amount,
            "Staking balance cannot be more than the amount staked."
        );
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
        stakedRandomTokensBalance[_token][msg.sender] =
            stakedRandomTokensBalance[_token][msg.sender] -
            _amount;
    }
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