// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    struct Stake {
        address token;
        uint256 amount;
        uint256 lastWithdrawTime;
    }

    // info APR expressed with 2 decimals
    // es: 17,81% -> 1781
    uint256 public APR;
    IERC20 public rewardToken;
    address[] public allowedTokens;
    address[] public stakers;
    mapping(address => Stake[]) public staker_stakes;
    mapping(address => uint256) public staker_distinctTokenNumber;
    mapping(address => mapping(address => uint256)) public token_staker_amount;
    mapping(address => address) public token_priceFeed;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
        APR = 1500; // 15%
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0 tokens");
        require(
            isTokenAllowed(_token),
            "Token not allowed on the platform yet"
        );

        if (staker_distinctTokenNumber[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        updatedistinctTokensStaked(msg.sender, _token);
        Stake memory stake = Stake(_token, _amount, block.timestamp);
        staker_stakes[msg.sender].push(stake);
        token_staker_amount[_token][msg.sender] += _amount;

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function unstakeTokenAndWithdrawMyReward(address _token) public {
        // security is vulnerable to reentrancy attacks?
        require(
            isTokenAllowed(_token),
            "Token doesn't exists on the platform yet"
        );
        uint256 balance = token_staker_amount[_token][msg.sender];
        require(balance > 0, "Staked balance is zero");

        IERC20(_token).transfer(msg.sender, balance);
        withdrawMyReward();

        token_staker_amount[_token][msg.sender] = 0;
        staker_distinctTokenNumber[msg.sender]--;

        deleteMyTokenStake(_token);

        maybeRemoveMeFromStakers();
    }

    function withdrawMyReward() public {
        uint256 myReward = getUserAccruedReward(msg.sender);
        require(myReward > 0, "You have not accrued enought RWD tokens");

        Stake[] memory myStakes = staker_stakes[msg.sender];
        for (uint256 i = 0; i < myStakes.length; i++) {
            myStakes[i].lastWithdrawTime = block.timestamp;
        }

        rewardToken.transfer(msg.sender, myReward);
    }

    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function setTokenPriceFeed(address token, address priceFeed)
        public
        onlyOwner
    {
        token_priceFeed[token] = priceFeed;
    }

    function setAPR(uint256 newAPR) public onlyOwner {
        APR = newAPR;
    }

    function getUserTVL(address user) public view returns (uint256) {
        if (staker_distinctTokenNumber[user] > 0) {
            uint256 totalValue = 0;

            for (uint256 i = 0; i < allowedTokens.length; i++) {
                address token = allowedTokens[i];
                uint256 amount = token_staker_amount[token][user];
                if (amount > 0) {
                    totalValue += getUserTokenValue(amount, token);
                }
            }
            return totalValue;
        } else return 0;
    }

    function getUserAccruedReward(address user) public view returns (uint256) {
        if (staker_distinctTokenNumber[user] > 0) {
            uint256 totalReward = 0;

            Stake[] memory myStake = staker_stakes[user];
            for (uint256 i = 0; i < myStake.length; i++) {
                uint256 annualReward = 0;
                uint256 accruedReward = 0;
                address token = myStake[i].token;
                uint256 amount = myStake[i].amount;
                uint256 stakeTime = myStake[i].lastWithdrawTime;

                uint256 value = getUserTokenValue(amount, token);
                annualReward = (amount * value * APR) / 10**4;

                uint256 year = 365 days;
                uint256 timeSinceStake = block.timestamp - stakeTime;
                uint256 accruedSoFarPercent = (timeSinceStake * 10**9) / year;

                accruedReward = (annualReward * accruedSoFarPercent) / 10**9;
                totalReward += accruedReward;
            }
            return totalReward;
        } else return 0;
    }

    function getUserTokenValue(uint256 amount, address token)
        public
        view
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = getTokenValue(token);
        return (amount * price) / 10**(decimals - 2);
    }

    function getTokenValue(address token)
        public
        view
        returns (uint256, uint256)
    {
        address tokenPriceFeed = token_priceFeed[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenPriceFeed);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();

        return (uint256(price), decimals);
    }

    function updatedistinctTokensStaked(address user, address token) internal {
        if (token_staker_amount[token][user] <= 0) {
            staker_distinctTokenNumber[user] += 1;
        }
    }

    function deleteMyTokenStake(address _token) internal {
        Stake[] storage myStakes = staker_stakes[msg.sender];
        for (uint16 i = 0; i < myStakes.length; i++) {
            if (myStakes[i].token == _token) {
                myStakes[i] = myStakes[myStakes.length - 1];
                myStakes.pop();
            }
        }
    }

    function maybeRemoveMeFromStakers() internal {
        if (staker_distinctTokenNumber[msg.sender] == 0) {
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == msg.sender) {
                    stakers[i] = stakers[stakers.length - 1];
                    stakers.pop();
                    break;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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