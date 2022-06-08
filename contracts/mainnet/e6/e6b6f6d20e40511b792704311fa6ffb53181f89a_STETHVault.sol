//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "./BaseVault.sol";

/**
 * @title A Vault that use variable weekly yields to buy calls
 * @author Pods Finance
 */
contract STETHVault is BaseVault {
    using TransferUtils for IERC20Metadata;
    using FixedPointMath for uint256;
    using FixedPointMath for FixedPointMath.Fractional;

    uint256 public constant DENOMINATOR = 10000;

    uint8 public immutable sharePriceDecimals;
    uint256 public lastRoundAssets;
    FixedPointMath.Fractional public lastSharePrice;

    uint256 public investorRatio = 5000;
    address public investor;

    event StartRoundData(uint256 indexed roundId, uint256 lastRoundAssets, uint256 sharePrice);
    event EndRoundData(
        uint256 indexed roundId,
        uint256 roundAccruedInterest,
        uint256 investmentYield,
        uint256 idleAssets
    );
    event SharePrice(uint256 indexed roundId, uint256 startSharePrice, uint256 endSharePrice);

    constructor(
        address _asset,
        address _strategist,
        address _investor
    ) BaseVault(_asset, _strategist) {
        investor = _investor;
        sharePriceDecimals = asset.decimals();
    }

    /**
     * @dev See {IVault-name}.
     */
    function name() external pure override returns (string memory) {
        return "stETH Vault";
    }

    function _afterRoundStart(uint256) internal override {
        lastRoundAssets = totalAssets();
        lastSharePrice = FixedPointMath.Fractional({
            numerator: totalShares == 0 ? 0 : lastRoundAssets,
            denominator: totalShares
        });

        uint256 sharePrice = lastSharePrice.denominator == 0 ? 0 : lastSharePrice.mulDivDown(10**sharePriceDecimals);
        emit StartRoundData(currentRoundId, lastRoundAssets, sharePrice);
    }

    function _afterRoundEnd() internal override {
        uint256 roundAccruedInterest;
        uint256 endSharePrice;
        uint256 investmentYield = asset.balanceOf(investor);
        uint256 idleAssets = asset.balanceOf(address(this));

        if (totalShares != 0) {
            endSharePrice = (totalAssets() + investmentYield).mulDivDown(10**sharePriceDecimals, totalShares);
            roundAccruedInterest = totalAssets() - lastRoundAssets;

            // Pulls the yields from investor
            if (investmentYield > 0) {
                asset.safeTransferFrom(investor, address(this), investmentYield);
            }

            // Sends another batch to Investor
            uint256 investmentAmount = (roundAccruedInterest * investorRatio) / DENOMINATOR;
            if (investmentAmount > 0) {
                asset.safeTransfer(investor, investmentAmount);
            }
        }
        uint256 startSharePrice = lastSharePrice.denominator == 0
            ? 0
            : lastSharePrice.mulDivDown(10**sharePriceDecimals);

        emit EndRoundData(currentRoundId, roundAccruedInterest, investmentYield, idleAssets);
        emit SharePrice(currentRoundId, startSharePrice, endSharePrice);
    }

    function _beforeWithdraw(uint256 shares, uint256) internal override {
        lastRoundAssets -= shares.mulDivDown(lastSharePrice);
    }

    /**
     * @dev See {BaseVault-totalAssets}.
     */
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IVault.sol";
import "../libs/TransferUtils.sol";
import "../libs/FixedPointMath.sol";
import "../libs/DepositQueueLib.sol";

/**
 * @title A Vault that tokenize shares of strategy
 * @author Pods Finance
 */
contract BaseVault is IVault {
    using TransferUtils for IERC20Metadata;
    using FixedPointMath for uint256;
    using DepositQueueLib for DepositQueueLib.DepositQueue;

    IERC20Metadata public immutable asset;

    address public strategist;

    uint256 public currentRoundId;
    mapping(address => uint256) userRounds;

    mapping(address => uint256) userShares;
    uint256 public totalShares;

    bool public isProcessingDeposits = false;

    DepositQueueLib.DepositQueue private depositQueue;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(address _asset, address _strategist) {
        asset = IERC20Metadata(_asset);
        strategist = _strategist;

        // Vault starts in `start` state
        emit StartRound(currentRoundId, 0);
    }

    /** Depositor **/

    /**
     * @dev See {IVault-deposit}.
     */
    function deposit(uint256 assets, address receiver) public virtual override {
        if (isProcessingDeposits) revert IVault__ForbiddenWhileProcessingDeposits();

        asset.safeTransferFrom(msg.sender, address(this), assets);
        depositQueue.push(DepositQueueLib.DepositEntry(receiver, assets));

        emit Deposit(receiver, assets);
    }

    /**
     * @dev See {IVault-withdraw}.
     */
    function withdraw(address owner) public virtual override {
        if (isProcessingDeposits) revert IVault__ForbiddenWhileProcessingDeposits();

        uint256 shares = sharesOf(owner);
        uint256 assets = _burnShares(owner, shares);

        if (msg.sender != owner) {
            _useAllowance(owner, msg.sender, shares);
        }

        // Apply custom withdraw logic
        _beforeWithdraw(shares, assets);

        asset.safeTransfer(owner, assets);

        emit Withdraw(owner, shares, assets);
    }

    /**
     * @dev See {IVault-name}.
     */
    function name() external pure virtual override returns (string memory) {
        return "Base Vault";
    }

    /**
     * @dev See {IVault-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IVault-approve}.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert IVault__ApprovalToAddressZero();

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Outputs the amount of shares and the locked shares for a given `owner` address.
     */
    function sharesOf(address owner) public view virtual returns (uint256) {
        return userShares[owner];
    }

    /**
     * @dev Outputs the amount of shares that would be generated by depositing `assets`.
     */
    function previewShares(uint256 assets) public view virtual returns (uint256) {
        uint256 shares;

        if (totalShares > 0) {
            shares = assets.mulDivUp(totalShares, totalAssets());
        }

        return shares;
    }

    /**
     * @dev Outputs the amount of underlying tokens would be withdrawn with a given amount of shares.
     */
    function previewWithdraw(uint256 shares) public view virtual returns (uint256) {
        return shares.mulDivDown(totalAssets(), totalShares);
    }

    /**
     * @dev Calculate the total amount of assets under management.
     */
    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @dev Outputs the amount of underlying tokens of an `owner` is idle, waiting for the next round.
     */
    function idleAmountOf(address owner) public view virtual returns (uint256) {
        return depositQueue.balanceOf(owner);
    }

    /**
     * @dev Outputs current size of the deposit queue.
     */
    function depositQueueSize() external view returns (uint256) {
        return depositQueue.size();
    }

    /** Strategist **/

    modifier onlyStrategist() {
        if (msg.sender != strategist) revert IVault__CallerIsNotTheStrategist();
        _;
    }

    /**
     * @dev Starts the next round, sending the idle funds to the
     * strategist where it should start accruing yield.
     */
    function startRound() public virtual onlyStrategist {
        isProcessingDeposits = false;

        uint256 idleBalance = asset.balanceOf(address(this));
        _afterRoundStart(idleBalance);

        emit StartRound(currentRoundId, idleBalance);
    }

    /**
     * @dev Closes the round, allowing deposits to the next round be processed.
     * and opens the window for withdraws.
     */
    function endRound() public virtual onlyStrategist {
        isProcessingDeposits = true;
        _afterRoundEnd();

        emit EndRound(currentRoundId++);
    }

    /**
     * @dev Mint shares for deposits accumulated, effectively including their owners in the next round.
     * `processQueuedDeposits` extracts up to but not including endIndex. For example, processQueuedDeposits(1,4)
     * extracts the second element through the fourth element (elements indexed 1, 2, and 3).
     *
     * @param startIndex Zero-based index at which to start processing deposits
     * @param endIndex The index of the first element to exclude from queue
     */
    function processQueuedDeposits(uint256 startIndex, uint256 endIndex) public {
        if (!isProcessingDeposits) revert IVault__NotProcessingDeposits();

        uint256 processedDeposits;
        for (uint256 i = startIndex; i < endIndex; i++) {
            DepositQueueLib.DepositEntry memory depositEntry = depositQueue.get(i);
            uint256 shares = _mintShares(depositEntry.owner, depositEntry.amount, processedDeposits);
            processedDeposits += depositEntry.amount;
            emit DepositProcessed(depositEntry.owner, currentRoundId, depositEntry.amount, shares);
        }
        depositQueue.remove(startIndex, endIndex);
    }

    /** Internals **/

    /**
     * @dev Mint new shares, effectively representing user participation in the Vault.
     */
    function _mintShares(
        address owner,
        uint256 assets,
        uint256 processedDeposits
    ) internal virtual returns (uint256 shares) {
        shares = assets;
        processedDeposits += totalAssets();

        if (totalShares > 0) {
            shares = assets.mulDivUp(totalShares, processedDeposits);
        }

        userShares[owner] += shares;
        totalShares += shares;
    }

    /**
     * @dev Burn shares.
     * @param owner Address owner of the shares
     * @param shares Amount of shares to lock
     */
    function _burnShares(address owner, uint256 shares) internal virtual returns (uint256 claimableUnderlying) {
        if (shares > userShares[owner]) revert IVault__CallerHasNotEnoughShares();
        claimableUnderlying = userShares[owner].mulDivDown(totalAssets(), totalShares);
        userShares[owner] -= shares;
        totalShares -= shares;
    }

    /**
     * @dev Spend allowance on behalf of the shares owner.
     * @param owner Address owner of the shares
     * @param spender Address shares spender
     * @param shares Amount of shares to spend
     */
    function _useAllowance(
        address owner,
        address spender,
        uint256 shares
    ) internal {
        uint256 allowed = _allowances[owner][spender];
        if (shares > allowed) revert IVault__SharesExceedAllowance();

        if (allowed != type(uint256).max) {
            _allowances[owner][spender] = allowed - shares;
        }
    }

    /** Hooks **/

    // solhint-disable-next-line no-empty-blocks
    function _beforeWithdraw(uint256 shares, uint256 assets) internal virtual {}

    // solhint-disable-next-line no-empty-blocks
    function _afterRoundStart(uint256 assets) internal virtual {}

    // solhint-disable-next-line no-empty-blocks
    function _afterRoundEnd() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

interface IVault {
    error IVault__CallerHasNotEnoughShares();
    error IVault__CallerIsNotTheStrategist();
    error IVault__NotProcessingDeposits();
    error IVault__ForbiddenWhileProcessingDeposits();
    error IVault__ApprovalToAddressZero();
    error IVault__SharesExceedAllowance();

    event Deposit(address indexed owner, uint amountDeposited);
    event Withdraw(address indexed owner, uint sharesBurnt, uint amountWithdrawn);
    event StartRound(uint indexed roundId, uint amountAddedToStrategy);
    event EndRound(uint indexed roundId);
    event DepositProcessed(address indexed owner, uint indexed roundId, uint assets, uint shares);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Returns the name of the Vault.
     */
    function name() external view returns(string memory);

    /**
     * @dev Deposits underlying tokens, generating shares.
     * @param assets The amount of asset token to deposit
     * @param receiver The address to be owner of the shares
     */
    function deposit(uint256 assets, address receiver) external;

    /**
     * @dev Burn shares, withdrawing underlying tokens.
     */
    function withdraw(address owner) external;

    /**
     * @dev Returns the remaining number of shares that `spender` will be
     * allowed to spend on behalf of `owner` through {withdraw}. This is
     * zero by default.
     *
     * This value changes when {approve} or {withdraw} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's shares.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Note that approving `type(uint256).max` is considered unlimited approval and should not be spent.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferUtils {
    error TransferUtils__TransferDidNotSucceed();

    function safeTransfer(IERC20 token, address to, uint value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = address(token).call(data);
        if (!success || result.length > 0) {
            // Return data is optional
            bool transferSucceeded = abi.decode(result, (bool));
            if (!transferSucceeded) revert TransferUtils__TransferDidNotSucceed();
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

library FixedPointMath {
    error FixedPointMath__DivByZero();
    using FixedPointMath for uint256;

    struct Fractional {
        uint256 numerator;
        uint256 denominator;
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        if (denominator == 0) revert FixedPointMath__DivByZero();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        if (denominator == 0) revert FixedPointMath__DivByZero();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function mulDivUp(uint256 x, Fractional memory y) internal pure returns (uint256 z) {
        return x.mulDivUp(y.numerator, y.denominator);
    }

    function mulDivDown(uint256 x, Fractional memory y) internal pure returns (uint256 z) {
        return x.mulDivDown(y.numerator, y.denominator);
    }

    function mulDivUp(Fractional memory x, uint256 y) internal pure returns (uint256 z) {
        return x.numerator.mulDivUp(y, x.denominator);
    }

    function mulDivDown(Fractional memory x, uint256 y) internal pure returns (uint256 z) {
        return x.numerator.mulDivDown(y, x.denominator);
    }

    function fractionRoundUp(Fractional memory x) internal pure returns (uint256 z) {
        return x.numerator.mulDivUp(1, x.denominator);
    }

    function fractionRoundDown(Fractional memory x) internal pure returns (uint256 z) {
        return x.numerator.mulDivDown(1, x.denominator);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

library DepositQueueLib {
    struct DepositEntry {
        address owner;
        uint amount;
    }

    struct DepositQueue {
        address[] list;
        mapping(address => uint) cache;
    }

    function push(DepositQueue storage queue, DepositEntry memory deposit) external {
        if (queue.cache[deposit.owner] == 0) {
            queue.list.push(deposit.owner);
        }

        queue.cache[deposit.owner] += deposit.amount;
    }

    function remove(DepositQueue storage queue, uint startIndex, uint endIndex) external {
        if (endIndex > startIndex) {
            // Remove the interval from the cache
            while(startIndex < endIndex) {
                queue.cache[queue.list[startIndex]] = 0;
                startIndex++;
            }

            // Update the list with the remaining entries
            address[] memory newList = new address[](queue.list.length - endIndex);
            uint i = 0;

            while(endIndex < queue.list.length) {
                newList[i++] = queue.list[endIndex++];
            }

            queue.list = newList;
        }
    }

    function get(DepositQueue storage queue, uint index) external view returns(DepositEntry memory depositEntry) {
        address owner = queue.list[index];
        depositEntry.owner = owner;
        depositEntry.amount = queue.cache[owner];
    }

    function balanceOf(DepositQueue storage queue, address owner) external view returns(uint) {
        return queue.cache[owner];
    }

    function size(DepositQueue storage queue) external view returns(uint) {
        return queue.list.length;
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