// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaker.sol";

// No need for SafeMath: arithmetic operations revert on underflow and overflow starting from Solidity 0.8.0

contract Staker is Context, IStaker {
    // rinkeby eth/usd price chainlink oracle
    AggregatorV3Interface priceFeed =
        AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

    IERC20 private immutable rewardToken;

    uint8 public immutable apy = 10;
    uint constant oneYear = 365 days;

    mapping(address => uint) private stakes;
    mapping(address => uint) public startTimestamps;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function deposit() external payable {
        require(msg.value >= 5 ether, "Amount must be >= 5 ethers");

        if (startTimestamps[_msgSender()] == 0) {
            startTimestamps[_msgSender()] = block.timestamp;
        }

        stakes[_msgSender()] += msg.value;
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw() external {
        require(_stakeOf(_msgSender()) > 0, "Nothing staked");

        address payable account = payable(_msgSender());

        uint rewards = _rewardsOf(account);
        uint stake = _stakeOf(account);

        delete stakes[account];
        delete startTimestamps[account];

        rewardToken.transfer(account, rewards);
        account.transfer(stake);

        emit Withdraw(account, stake, rewards);
    }

    function withdrawRewards() external {
        require(
            _stakeOf(_msgSender()) > 0,
            "Must have deposited to start earning rewards"
        );

        uint rewards = _rewardsOf(_msgSender());
        startTimestamps[_msgSender()] = block.timestamp;

        rewardToken.transfer(_msgSender(), rewards);
        emit WithdrawRewards(_msgSender(), rewards);
    }

    function stakeOf(address account) external view returns (uint) {
        return _stakeOf(account);
    }

    function rewardsOf(address account) external view returns (uint) {
        return _rewardsOf(account);
    }

    function getLatestPrice() public view virtual returns (uint) {
        // (uint80 roundID, int price, uint startedAt, uint timestamp, uint80 answeredInRound)
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price) / priceFeed.decimals();
    }

    function _stakeOf(address account) internal view returns (uint) {
        return stakes[account];
    }

    function _rewardsOf(address account) internal view returns (uint) {
        return _calculateRewards(account);
    }

    function _calculateRewards(address account) internal view returns (uint) {
        return
            (stakes[account] *
                getLatestPrice() *
                apy *
                (block.timestamp - startTimestamps[account])) / (100 * oneYear);
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

interface IStaker {
    event Deposit(address account, uint amount);
    event WithdrawRewards(address account, uint rewards);
    event Withdraw(address account, uint stake, uint rewards);

    function deposit() external payable;

    function withdraw() external;

    function withdrawRewards() external;

    function stakeOf(address account) external view returns (uint);

    function rewardsOf(address account) external view returns (uint);
}