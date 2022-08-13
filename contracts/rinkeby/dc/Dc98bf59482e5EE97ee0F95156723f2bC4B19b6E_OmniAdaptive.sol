// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "Ownable.sol";
import "Pausable.sol";
import "IERC20Metadata.sol";
import "IERC20.sol";


interface Omniverse is IERC20, IERC20Metadata {
    function omniAdaptiveTransfer(address from, address to, uint256 amount) external;
}


interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


interface IDEXRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function factory() external pure returns (address);
}


contract OmniAdaptive is Ownable, Pausable {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_FEE = 40;
    // Booleans are more expensive than uint256.
    uint256 public constant FALSE = 1;
    uint256 public constant TRUE = 2;

    Omniverse public omniverse;

    struct FreeTransferInfo {
        uint256 freeTransferEnabled;
        // freeTransferCheck maps the address to the index of the address in the freeTransfers array.
        mapping(address => uint256) freeTransferCheck;
        address[] freeTransfers;
    }
    FreeTransferInfo public freeTransferInfo;

    struct TransferFees {
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
        uint256 feesOnNormalTransfers;
        mapping(address => uint256) isFeeExempt;
        mapping(address => uint256) pairs;
    }
    TransferFees public transferFees;

    mapping(address => uint256) public allowTransfer;

    struct MaxTaxReceiversInfo {
        uint256 sellFee;
        uint256 transferFee;
        uint256 maxTransactionAmount;
        uint256 enabled;
        mapping(address => uint256) maxTaxReceivers;
    }
    MaxTaxReceiversInfo public maxTaxReceiversInfo;

    struct BlacklistingInfo {
        uint256 enabled;
        mapping(address => uint256) blacklist;
    }
    BlacklistingInfo public blacklistingInfo;

    struct SwapbackSettings {
        uint256 inSwap;
        uint256 treasuryPercent;
        uint256 liquidityPercent;
        uint256 burnPercent;
        uint256 swapThreshold;
        uint256 swapEnabled;
        IDEXRouter swapRouter;
        IERC20 swapPairedCoin;
        address treasury;
    }
    SwapbackSettings public swapbackSettings;

    event FreeTransfer(address indexed from, address indexed to, uint256 amount);
    event PairUpdated(address indexed addr, bool value);
    event BlacklistUpdated(address indexed addr, bool value);
    event MaxTaxReceiversUpdated(address indexed addr, bool value);
    event FeeExemptUpdated(address indexed addr, bool value);
    event AllowTransferUpdated(address indexed addr, bool value);
    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToTreasury,
        uint256 amountToLiquidity,
        uint256 amountToBurn
    );

    modifier swapping() {
        require(swapbackSettings.inSwap != TRUE, "Already inSwap");
        swapbackSettings.inSwap = TRUE;
        _;
        swapbackSettings.inSwap = FALSE;
    }

    constructor(
        address ownerAddr,
        address omniverseAddr,
        address routerAddr,
        address pairedCoinAddr,
        address treasuryAddr
    )
    {
        require(ownerAddr != address(0x0), "Owner can't be 0x0");
        require(omniverseAddr != address(0x0), "Omniverse can't be 0x0");
        require(routerAddr != address(0x0), "Router can't be 0x0");
        require(pairedCoinAddr != address(0x0), "Paired coin can't be 0x0");
        require(treasuryAddr != address(0x0), "Treasury can't be 0x0");

        _pause();

        _transferOwnership(ownerAddr);

        omniverse = Omniverse(omniverseAddr);

        // First element in this array should never be used.
        freeTransferInfo.freeTransfers.push(address(0x0));

        transferFees.buyFee = 10;
        transferFees.sellFee = 10;
        transferFees.transferFee = 10;
        transferFees.feesOnNormalTransfers = TRUE;
        transferFees.isFeeExempt[ownerAddr] = TRUE;
        transferFees.isFeeExempt[address(this)] = TRUE;

        allowTransfer[ownerAddr] = TRUE;
        allowTransfer[address(this)] = TRUE;

        // These two lines are to allow creating the LP using the non-multisig address before
        // transfers are enabled. These will be set to false after the fact.
        transferFees.isFeeExempt[msg.sender] = TRUE;
        allowTransfer[msg.sender] = TRUE;

        maxTaxReceiversInfo.sellFee = 30;
        maxTaxReceiversInfo.transferFee = 30;
        maxTaxReceiversInfo.maxTransactionAmount = 1000 * 10**omniverse.decimals();
        maxTaxReceiversInfo.enabled = TRUE;

        blacklistingInfo.enabled = TRUE;

        swapbackSettings.inSwap = FALSE;
        swapbackSettings.treasuryPercent = 60;
        swapbackSettings.liquidityPercent = 20;
        swapbackSettings.burnPercent = 20;
        swapbackSettings.swapThreshold = 1000 * 10**omniverse.decimals();
        swapbackSettings.swapEnabled = TRUE;
        swapbackSettings.swapRouter = IDEXRouter(routerAddr);
        swapbackSettings.swapPairedCoin = IERC20(pairedCoinAddr);
        swapbackSettings.treasury = treasuryAddr;

        address swapPair = IDEXFactory(swapbackSettings.swapRouter.factory()).createPair(
            pairedCoinAddr,
            omniverseAddr
        );
        transferFees.pairs[swapPair] = TRUE;

        omniverse.approve(routerAddr, type(uint256).max);
        swapbackSettings.swapPairedCoin.approve(routerAddr, type(uint256).max);

        emit PairUpdated(swapPair, true);
        emit FeeExemptUpdated(ownerAddr, true);
        emit FeeExemptUpdated(address(this), true);
        emit FeeExemptUpdated(msg.sender, true);
        emit AllowTransferUpdated(ownerAddr, true);
        emit AllowTransferUpdated(address(this), true);
        emit AllowTransferUpdated(msg.sender, true);
    }

    receive() external payable {}

    function transferOmni(address from, address to, uint256 amount) external {
        require(msg.sender == address(omniverse), "Can only be called by Omniverse");
        (bool canTransfer, uint256 amountToTax) = transferData(from, to, amount);
        require(canTransfer, "Transfer not allowed");
        if (amountToTax > 0) omniverse.omniAdaptiveTransfer(from, address(this), amountToTax);
        omniverse.omniAdaptiveTransfer(from, to, amount - amountToTax);
    }

    function freeTransferOmni(address to, uint256 amount) external {
        require(checkFreeTransfer(msg.sender, to, amount), "Cannot use this function");
        freeTransferInfo.freeTransferCheck[msg.sender] = freeTransferInfo.freeTransfers.length;
        freeTransferInfo.freeTransfers.push(msg.sender);
        omniverse.omniAdaptiveTransfer(msg.sender, to, amount);
        emit FreeTransfer(msg.sender, to, amount);
    }

    function enableTransfers() external onlyOwner {
        _unpause();
    }

    function disableTransfers() external onlyOwner {
        _pause();
    }

    function setFreeTransferEnabled(bool enabled) external onlyOwner {
        freeTransferInfo.freeTransferEnabled = boolToUint(enabled);
    }

    function resetFreeTransferForAddress(address addr) external onlyOwner {
        uint idx = freeTransferInfo.freeTransferCheck[addr];
        require(idx != 0, "Address already reset");
        address lastElement = freeTransferInfo.freeTransfers[freeTransferInfo.freeTransfers.length - 1];
        freeTransferInfo.freeTransfers[idx] = lastElement;
        freeTransferInfo.freeTransfers.pop();
        freeTransferInfo.freeTransferCheck[lastElement] = idx;
        delete freeTransferInfo.freeTransferCheck[addr];
    }

    function resetFreeTransfers() external onlyOwner {
        for (uint i = 1; i < freeTransferInfo.freeTransfers.length; i++) {
            delete freeTransferInfo.freeTransferCheck[freeTransferInfo.freeTransfers[i]];
        }
        delete freeTransferInfo.freeTransfers;
        // First element in this array should never be used.
        freeTransferInfo.freeTransfers.push(address(0x0));
    }

    function setTradingPair(address pair, bool enabled) external onlyOwner {
        uint256 b = boolToUint(enabled);
        if (transferFees.pairs[pair] != b) {
            transferFees.pairs[pair] = b;
            emit PairUpdated(pair, enabled);
        }
    }

    function setFeesInfo(
        uint256 buyPercent,
        uint256 sellPercent,
        uint256 transferPercent,
        bool feesOnNormalTransfersEnabled
    )
        external onlyOwner
    {
        require(buyPercent <= MAX_FEE, "Exceeded max fee");
        require(sellPercent <= MAX_FEE, "Exceeded max fee");
        require(transferPercent <= MAX_FEE, "Exceeded max fee");

        transferFees.buyFee = buyPercent;
        transferFees.sellFee = sellPercent;
        transferFees.transferFee = transferPercent;
        transferFees.feesOnNormalTransfers = boolToUint(feesOnNormalTransfersEnabled);
    }

    function setMaxTaxReceiversInfo(
        uint256 sellFee, 
        uint256 transferFee,
        uint256 maxTxnAmount,
        bool maxTaxReceiversEnabled
    )
        external
        onlyOwner
    {
        require(sellFee <= MAX_FEE, "Exceeded max fee");
        require(transferFee <= MAX_FEE, "Exceeded max fee");
        maxTaxReceiversInfo.sellFee = sellFee;
        maxTaxReceiversInfo.transferFee = transferFee;
        maxTaxReceiversInfo.maxTransactionAmount = maxTxnAmount;
        maxTaxReceiversInfo.enabled = boolToUint(maxTaxReceiversEnabled);
    }

    function setBlacklistingEnabled(bool enabled) external onlyOwner {
        blacklistingInfo.enabled = boolToUint(enabled);
    }

    function setBlacklist(address addr, bool flag) external onlyOwner {
        blacklistingInfo.blacklist[addr] = boolToUint(flag);
        emit BlacklistUpdated(addr, flag);
    }

    function setMaxTaxReceivers(address addr, bool flag) external onlyOwner {
        maxTaxReceiversInfo.maxTaxReceivers[addr] = boolToUint(flag);
        emit MaxTaxReceiversUpdated(addr, flag);
    }

    function setFeeExempt(address addr, bool enabled) external onlyOwner {
        transferFees.isFeeExempt[addr] = boolToUint(enabled);
        emit FeeExemptUpdated(addr, enabled);
    }

    function setAllowTransfer(address addr, bool allowed) external onlyOwner {
        allowTransfer[addr] = boolToUint(allowed);
        emit AllowTransferUpdated(addr, allowed);
    }

    function setSwapBackSettings(
        uint256 treasuryPercent,
        uint256 liquidityPercent,
        uint256 burnPercent,
        uint256 swapThreshold,
        bool swapEnabled,
        address routerAddr,
        address pairedCoinAddr,
        address treasuryAddr
    )
        external
        onlyOwner
    {
        require(swapbackSettings.inSwap != TRUE, "Can't run while inSwap");
        require(
            treasuryPercent + liquidityPercent + burnPercent == 100,
            "Sum of percentages doesn't add to 100"
        );
        swapbackSettings.treasuryPercent = treasuryPercent;
        swapbackSettings.liquidityPercent = liquidityPercent;
        swapbackSettings.burnPercent = burnPercent;
        swapbackSettings.swapThreshold = swapThreshold;
        swapbackSettings.swapEnabled = boolToUint(swapEnabled);
        if (routerAddr != address(0x0)) swapbackSettings.swapRouter = IDEXRouter(routerAddr);
        if (pairedCoinAddr != address(0x0)) swapbackSettings.swapPairedCoin = IERC20(pairedCoinAddr);
        if (treasuryAddr != address(0x0)) swapbackSettings.treasury = treasuryAddr;

        if (routerAddr != address(0x0) || pairedCoinAddr != address(0x0)) {
            address swapPair = IDEXFactory(swapbackSettings.swapRouter.factory()).createPair(
                address(swapbackSettings.swapPairedCoin),
                address(omniverse)
            );
            if (transferFees.pairs[swapPair] != TRUE) {
                transferFees.pairs[swapPair] = TRUE;
                emit PairUpdated(swapPair, true);
            }

            swapbackSettings.swapPairedCoin.approve(address(swapbackSettings.swapRouter), type(uint256).max);
        }

        if (routerAddr != address(0x0)) {
            omniverse.approve(routerAddr, type(uint256).max);
        }
    }

    function swapBack() external swapping {
        require(swapbackSettings.swapEnabled == TRUE, "swapBack is disabled");

        uint256 contractBalance = omniverse.balanceOf(address(this));
        require(contractBalance >= swapbackSettings.swapThreshold,  "Below swapBack threshold");

        swapBackPrivate(contractBalance);
    }

    function rescueETH(uint256 amount, address receiver) external onlyOwner {
        payable(receiver).transfer(amount);
    }

    function rescueERC20Token(address tokenAddr, uint256 tokens, address receiver) external onlyOwner {
        IERC20(tokenAddr).transfer(receiver, tokens);
    }

    function checkFreeTransfer(address from, address to, uint256 amount) public view returns (bool) {
        return (
            omniverse.balanceOf(from) >= amount &&
            amount > 0 &&
            allowedToTransfer(from, to, amount) &&
            freeTransferInfo.freeTransferEnabled == TRUE &&
            freeTransferInfo.freeTransferCheck[from] == 0
        );
    }

    /// This is to be used as the resolver function in Gelato for swapBack
    function shouldSwapback() external view returns (bool canExec, bytes memory execPayload) {
        canExec =
            swapbackSettings.inSwap != TRUE &&
            swapbackSettings.swapEnabled == TRUE &&
            omniverse.balanceOf(address(this)) >= swapbackSettings.swapThreshold;
        execPayload = abi.encodeWithSelector(this.swapBack.selector);
    }

    function getTaxPercentages(address addr)
        public
        view
        returns (
            uint256 buyPercentage,
            uint256 sellPercentage,
            uint256 transferPercentage
        )
    {
        buyPercentage = transferFees.buyFee;
        sellPercentage = getSellFee(addr);
        transferPercentage = getTransferFee(addr);
    }

    function transferData(
        address from,
        address to,
        uint256 amount
    )
        public
        view
        returns (bool canTransfer, uint256 amountToTax)
    {
        canTransfer = allowedToTransfer(from, to, amount);

        amountToTax = 0;
        if (shouldTakeFee(from, to)) {
            uint256 totalFee;
            (uint256 buyFee, uint256 sellFee, uint256 transferFee) = getTaxPercentages(from);
            if (transferFees.pairs[from] == TRUE) {
                totalFee = buyFee;
            } else if (transferFees.pairs[to] == TRUE) {
                totalFee = sellFee;
            } else {
                totalFee = transferFee;
            }

            amountToTax = amount * totalFee / 100;
        }
    }

    function shouldTakeFee(address from, address to) public view returns (bool) {
        if (maxTaxReceiverRestrictionsApply(from, to)) {
            return true;
        } else if (transferFees.isFeeExempt[from] == TRUE || transferFees.isFeeExempt[to] == TRUE) {
            return false;
        }
        return (
            transferFees.feesOnNormalTransfers == TRUE ||
            transferFees.pairs[from] == TRUE ||
            transferFees.pairs[to] == TRUE
        );
    }

    function getBlacklist(address addr) public view returns (bool) {
        return blacklistingInfo.blacklist[addr] == TRUE && blacklistingInfo.enabled == TRUE;
    }

    function maxTaxReceiverRestrictionsApply(
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        return getMaxTaxReceiver(from) && transferFees.isFeeExempt[to] != TRUE;
    }

    function getMaxTaxReceiver(address addr) public view returns (bool) {
        return maxTaxReceiversInfo.maxTaxReceivers[addr] == TRUE && maxTaxReceiversInfo.enabled == TRUE;
    }

    function swapBackPrivate(uint256 contractBalance) private {
        uint256 feeAmountToLiquidity = contractBalance * swapbackSettings.liquidityPercent / 100;
        uint256 feeAmountToTreasury = contractBalance * swapbackSettings.treasuryPercent / 100;

        // Only transfer to the paired coin half of the liquidity tokens, and all of the treasury tokens.
        uint256 amountToPairedCoin = feeAmountToLiquidity / 2 + feeAmountToTreasury;

        // Swap once to the paired coin.
        uint256 balancePairedCoin = swapbackSettings.swapPairedCoin.balanceOf(address(this));
        if (amountToPairedCoin > 0) {
            swapTokensForPairedCoin(amountToPairedCoin);
        }
        balancePairedCoin = swapbackSettings.swapPairedCoin.balanceOf(address(this)) - balancePairedCoin;

        // The percentage of the OMNI balance that has been swapped to the paired coin.
        // Multiplied by 10 for more accuracy.
        uint256 percentToPairedCoin =
            swapbackSettings.liquidityPercent * 10 / 2 + swapbackSettings.treasuryPercent * 10;

        // The amounts of the paired coin that will go to the liquidity and treasury.
        uint256 amountLiquidityPairedCoin =
            balancePairedCoin * swapbackSettings.liquidityPercent * 10 / 2 / percentToPairedCoin;

        if (amountLiquidityPairedCoin > 0) {
            // Add to liquidity the second half of the liquidity tokens,
            // and the corresponding percentage of the paired coin.
            addLiquidity(
                feeAmountToLiquidity - feeAmountToLiquidity / 2,
                amountLiquidityPairedCoin
            );
        }

        if (swapbackSettings.swapPairedCoin.balanceOf(address(this)) > 0) {
            swapbackSettings.swapPairedCoin.transfer(
                swapbackSettings.treasury,
                swapbackSettings.swapPairedCoin.balanceOf(address(this))
            );
        }

        uint256 feeAmountToBurn = omniverse.balanceOf(address(this));

        if (feeAmountToBurn > 0) {
            omniverse.transfer(DEAD, feeAmountToBurn);
        }

        emit SwapBack(
            contractBalance,
            feeAmountToTreasury,
            feeAmountToLiquidity,
            feeAmountToBurn
        );
    }

    function swapTokensForPairedCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(omniverse);
        path[1] = address(swapbackSettings.swapPairedCoin);

        swapbackSettings.swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 pairedCoinAmount) private {
        swapbackSettings.swapRouter.addLiquidity(
            address(omniverse),
            address(swapbackSettings.swapPairedCoin),
            tokenAmount,
            pairedCoinAmount,
            0,
            0,
            swapbackSettings.treasury,
            block.timestamp
        );
    }

    function allowedToTransfer(address from, address to, uint256 amount) private view returns (bool) {
        return (
            (!paused() || allowTransfer[from] == TRUE || allowTransfer[to] == TRUE) &&
            (!getBlacklist(from) && !getBlacklist(to)) &&
            (
                amount <= maxTaxReceiversInfo.maxTransactionAmount ||
                !maxTaxReceiverRestrictionsApply(from, to)
            )
        );
    }

    function getSellFee(address addr) private view returns (uint256 sellPercentage) {
        sellPercentage = transferFees.sellFee;
        if (getMaxTaxReceiver(addr)) {
            sellPercentage = maxTaxReceiversInfo.sellFee;
        }
    }

    function getTransferFee(address addr) private view returns (uint256 transferPercentage) {
        transferPercentage = transferFees.transferFee;
        if (getMaxTaxReceiver(addr)) {
            transferPercentage = maxTaxReceiversInfo.transferFee;
        }
    }

    function boolToUint(bool b) private pure returns (uint256) {
        if (b) {
            return TRUE;
        }
        return FALSE;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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