// SPDX-License-Identifier: GPL-v3

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBentoBoxMinimal.sol";

pragma solidity 0.8.7;

interface ISafeStrategy {
	function safeHarvest(
		uint256 maxBalance,
		bool rebalance,
		uint256 maxChangeAmount,
		bool harvestRewards
	) external;

    function swapExactTokens(address tokenIn, uint256 amountOutMin) external;
    function strategyToken() external view returns(address);
}

// 🚜🚜🚜
contract CombineHarvester is Ownable {

    IBentoBoxMinimal immutable public bentoBox;

    struct ExecuteDataManual {
        ISafeStrategy strategy;
        uint256 maxBalance;
        uint256 maxChangeAmount; // can be set to 0 to allow for full withdrawals / deposits from / to strategy
        address swapToken;
        uint256 minOutAmount;
        bool rebalance;
        bool harvestReward;
    }

    struct ExecuteData {
        ISafeStrategy strategy;
        uint256 maxChangeAmount; // can be set to 0 to allow for full withdrawals / deposits from / to strategy
        address swapToken;
        uint256 minOutAmount;
        bool harvestReward;
    }

    constructor(address _bentoBox) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
    }

    function executeSafeHarvestsManual(ExecuteDataManual[] calldata datas) external onlyOwner {
        
        uint256 n = datas.length;
        
        for (uint256 i = 0; i < n; i = increment(i)) {

            ExecuteDataManual memory data = datas[i];

            data.strategy.safeHarvest(data.maxBalance, data.rebalance, data.maxChangeAmount, data.harvestReward);

            if (data.swapToken != address(0)) {
                data.strategy.swapExactTokens(data.swapToken, data.minOutAmount);
            }
        }
    }

    function executeSafeHarvests(ExecuteData[] calldata datas) external onlyOwner {

        uint256 n = datas.length;

        for (uint256 i = 0; i < n; i = increment(i)) {

            ExecuteData memory data = datas[i];

            data.strategy.safeHarvest(0, _rebalanceNecessairy(data.strategy), data.maxChangeAmount, data.harvestReward);

            if (data.swapToken != address(0)) {
                data.strategy.swapExactTokens(data.swapToken, data.minOutAmount);
            }
        }
    }

    // returns true if strategy balance differs more than -+1% from the strategy target balance
    function _rebalanceNecessairy(ISafeStrategy strategy) public view returns (bool) {

        address token = strategy.strategyToken();

        IBentoBoxMinimal.StrategyData memory data = bentoBox.strategyData(token);

        uint256 targetStrategyBalance = bentoBox.totals(token).elastic * data.targetPercentage / 100; // targetPercentage ∈ [0, 100]

        if (data.balance == 0) return targetStrategyBalance != 0;

        uint256 ratio = targetStrategyBalance * 100 / data.balance;

        return ratio >= 101 || ratio <= 99;
    }

    function increment(uint256 i) internal pure returns(uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

/// @notice Minimal interface for BentoBox token vault interactions - `token` is aliased as `address` from `IERC20` for code simplicity.
interface IBentoBoxMinimal {

    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    struct StrategyData {
        uint64 strategyStartDate;
        uint64 targetPercentage;
        uint128 balance; // the balance of the strategy that BentoBox thinks is in there
    }

    function strategyData(address token) external view returns (StrategyData memory);

    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for the BentoBox.
    function registerProtocol() external;

    function totals(address token) external view returns (Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
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