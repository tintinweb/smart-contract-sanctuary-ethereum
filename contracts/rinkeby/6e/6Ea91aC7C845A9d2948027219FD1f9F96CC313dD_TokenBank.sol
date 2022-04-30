// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenBank is Ownable {
    IERC20 rewardToken;
    mapping(address => mapping(address => uint256)) stakeTokenBalance;
    mapping(address => bool) allowedTokensFlag;
    address[] allowedTokens;
    mapping(address => address) tokenPriceDataFeed;
    mapping(address => uint256) uniqueTokenStaked;
    mapping(address => bool) stakersFlag;
    address[] stakers;

    constructor(address _rewardTokenAddress) {
        rewardToken = IERC20(_rewardTokenAddress);
    }

    modifier tokenAllowed(address _token) {
        require(allowedTokensFlag[_token], "Token is not allowed!");
        _;
    }

    function issueRewards() public onlyOwner {
        for (uint256 stakerIdx = 0; stakerIdx < stakers.length; stakerIdx++) {
            address user = stakers[stakerIdx];
            if (stakersFlag[user]) {
                uint256 userTotalTokenvalue = getUserTotalTokenValue(user);
                rewardToken.transfer(user, userTotalTokenvalue);
            }
        }
    }

    function stakeTokens(address _token, uint256 _amount)
        public
        tokenAllowed(_token)
    {
        require(_amount > 0, "Staking token amount is less than zero!");
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokenStaked(_token, msg.sender);
        stakeTokenBalance[_token][msg.sender] += _amount;
        if (uniqueTokenStaked[msg.sender] == 1) {
            stakersFlag[msg.sender] = true;
            stakers.push(msg.sender);
        }
    }

    function unStakeToken(address _token) public {
        require(
            stakeTokenBalance[_token][msg.sender] > 0,
            "Not enough balance to unstake."
        );

        IERC20(_token).transfer(
            msg.sender,
            stakeTokenBalance[_token][msg.sender]
        );
        stakeTokenBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] -= 1;
        if (uniqueTokenStaked[msg.sender] == 0) {
            stakersFlag[msg.sender] = false;
        }
    }

    function updateUniqueTokenStaked(address _token, address _user) public {
        if (stakeTokenBalance[_token][_user] <= 0) {
            uniqueTokenStaked[_user] += 1;
        }
    }

    function addAlowedToken(address _token) public onlyOwner {
        require(
            allowedTokensFlag[_token] == false,
            "This Token has been allowed!"
        );
        allowedTokensFlag[_token] = true;
        allowedTokens.push(_token);
    }

    function remAlowedToken(address _token) public onlyOwner {
        allowedTokensFlag[_token] = false;
    }

    function getUserTotalTokenValue(address _user)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (
            uint256 tokenIdx = 0;
            tokenIdx < allowedTokens.length;
            tokenIdx++
        ) {
            address _token = allowedTokens[tokenIdx];
            if (
                allowedTokensFlag[_token] &&
                stakeTokenBalance[_token][_user] > 0
            ) {
                totalValue += getUserSingleTokenValue(_user, _token);
            }
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakeTokenBalance[_token][_user] * price) / 10**decimals;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            tokenPriceDataFeed[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), uint256(decimals));
    }

    function setTokenPriceFeed(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceDataFeed[_token] = _priceFeed;
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

import "../utils/Context.sol";

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