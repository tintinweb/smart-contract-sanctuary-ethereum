/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/OmniAdaptive.sol


pragma solidity ^0.8.0;




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


contract OmniAdaptive is Ownable {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_FEE = 40;

    IERC20 public omniverse;
    mapping(address => bool) public pairs;

    struct TransferFees {
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
        uint256 maxTaxReceiverSellFee;
        uint256 maxTaxReceiverTransferFee;
    }
    TransferFees public transferFees;

    uint256 public maxTaxReceiversTransactionAmount = 1000 * 10**18;

    bool public feesOnNormalTransfers = true;
    bool public isBlacklistingEnabled = true;
    bool public isMaxTaxReceiversEnabled = true;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public maxTaxReceivers;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public allowTransfer;

    bool public inSwap = false;

    struct SwapbackSettings {
        bool swapEnabled;
        uint256 swapThreshold;
        IDEXRouter swapRouter;
        IERC20 swapPairedCoin;
    }
    SwapbackSettings public swapbackSettings;

    address public treasury;

    struct FeePercentages {
        uint256 treasuryPercent;
        uint256 liquidityPercent;
        uint256 burnPercent;
    }
    FeePercentages public feePercentages;

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToTreasury,
        uint256 amountToLiquidity,
        uint256 amountToBurn
    );

    modifier swapping() {
        require(!inSwap, "Already inSwap");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address ownerAddr,
        address omniverseAddr,
        address routerAddr,
        address pairedCoinAddr,
        address treasuryAddr
    )
    {
        _transferOwnership(ownerAddr);
        omniverse = IERC20(omniverseAddr);
        swapbackSettings.swapRouter = IDEXRouter(routerAddr);
        swapbackSettings.swapPairedCoin = IERC20(pairedCoinAddr);
        treasury = treasuryAddr;

        address swapPair = IDEXFactory(swapbackSettings.swapRouter.factory()).createPair(
            pairedCoinAddr,
            omniverseAddr
        );
        pairs[swapPair] = true;

        transferFees.buyFee = 10;
        transferFees.sellFee = 10;
        transferFees.transferFee = 10;
        transferFees.maxTaxReceiverSellFee = 30;
        transferFees.maxTaxReceiverTransferFee = 30;

        isFeeExempt[ownerAddr] = true;
        allowTransfer[ownerAddr] = true;

        // This is to allow creating the LP using the non-multisig address before
        // transfers are enabled. These will be set to false after the fact.
        isFeeExempt[msg.sender] = true;
        allowTransfer[msg.sender] = true;

        swapbackSettings.swapEnabled = true;
        swapbackSettings.swapThreshold = 1000 * 10**18;

        feePercentages.treasuryPercent = 60;
        feePercentages.liquidityPercent = 20;
        feePercentages.burnPercent = 20;

        omniverse.approve(routerAddr, type(uint256).max);
    }

    receive() external payable {}

    function setTradingPair(address pair, bool enabled) external onlyOwner {
        pairs[pair] = enabled;
    }

    function setFees(
        uint256 buyPercent,
        uint256 sellPercent,
        uint256 transferPercent,
        uint256 maxTaxReceiverSellPercent,
        uint256 maxTaxReceiverTransferPercent
    )
        external onlyOwner
    {
        require(buyPercent <= MAX_FEE, "Exceeded max buy fee");
        require(sellPercent <= MAX_FEE, "Exceeded max sell fee");
        require(
            transferPercent <= MAX_FEE,
            "Exceeded max transfer fee"
        );
        require(
            maxTaxReceiverSellPercent <= MAX_FEE,
            "Exceeded max tax receiver sell fee"
        );
        require(
            maxTaxReceiverTransferPercent <= MAX_FEE,
            "Exceeded max tax receiver transfer fee"
        );

        transferFees.buyFee = buyPercent;
        transferFees.sellFee = sellPercent;
        transferFees.transferFee = transferPercent;
        transferFees.maxTaxReceiverSellFee = maxTaxReceiverSellPercent;
        transferFees.maxTaxReceiverTransferFee = maxTaxReceiverTransferPercent;
    }

    function setMaxTaxReceiversTransactionAmount(uint256 amount) external onlyOwner {
        maxTaxReceiversTransactionAmount = amount;
    }

    function setFeesOnNormalTransfers(bool enabled) external onlyOwner {
        feesOnNormalTransfers = enabled;
    }

    function setBlacklistingEnabled(bool enabled) external onlyOwner {
        isBlacklistingEnabled = enabled;
    }

    function setMaxTaxReceiversEnabled(bool enabled) external onlyOwner {
        isMaxTaxReceiversEnabled = enabled;
    }

    function setBlacklist(address user, bool flag) external onlyOwner {
        blacklist[user] = flag;
    }

    function setMaxTaxReceivers(address addr, bool flag) external onlyOwner {
        maxTaxReceivers[addr] = flag;
    }

    function setFeeExempt(address addr, bool enabled) external onlyOwner {
        isFeeExempt[addr] = enabled;
    }

    function setAllowTransfer(address addr, bool allowed) external onlyOwner {
        allowTransfer[addr] = allowed;
    }

    function setSwapBackSettings(bool enabled, uint256 threshold) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        swapbackSettings.swapEnabled = enabled;
        swapbackSettings.swapThreshold = threshold;
    }

    function setRouter(address routerAddr) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        swapbackSettings.swapRouter = IDEXRouter(routerAddr);
        address swapPair = IDEXFactory(swapbackSettings.swapRouter.factory()).createPair(
            address(swapbackSettings.swapPairedCoin),
            address(omniverse)
        );
        pairs[swapPair] = true;
        omniverse.approve(routerAddr, type(uint256).max);
    }

    function setPairedCoin(address pairedCoinAddr) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        swapbackSettings.swapPairedCoin = IERC20(pairedCoinAddr);
        address swapPair = IDEXFactory(swapbackSettings.swapRouter.factory()).createPair(
            pairedCoinAddr,
            address(omniverse)
        );
        pairs[swapPair] = true;
    }

    function setTreasury(address treasuryReceiver) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        treasury = treasuryReceiver;
    }

    function setFeePercentageBreakdown(
        uint256 treasuryPercentage,
        uint256 liquidityPercentage,
        uint256 burnPercentage
    )
        external
        onlyOwner
    {
        require(!inSwap, "Can't run while inSwap");
        uint256 sum =
            treasuryPercentage +
            liquidityPercentage +
            burnPercentage;
        require(sum == 100, "Sum of percentages doesn't add to 100");

        feePercentages.treasuryPercent = treasuryPercentage;
        feePercentages.liquidityPercent = liquidityPercentage;
        feePercentages.burnPercent = burnPercentage;
    }

    function swapBack() external swapping {
        require(swapbackSettings.swapEnabled, "swapBack is disabled");

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

    /// This is to be used as the resolver function in Gelato for swapBack
    function shouldSwapback() external view returns (bool canExec, bytes memory execPayload) {
        canExec =
            !inSwap &&
            swapbackSettings.swapEnabled &&
            omniverse.balanceOf(address(this)) >= swapbackSettings.swapThreshold;
        execPayload = abi.encodeWithSelector(this.swapBack.selector);
    }

    function getTaxPercentages(address addr)
        external
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
        uint256 amount,
        bool transferPaused
    )
        external
        view
        returns (bool canTransfer, uint256 amountToTax) {
        canTransfer = !transferPaused || allowTransfer[from] || allowTransfer[to];
        canTransfer = canTransfer && !getBlacklist(from) && !getBlacklist(to);
        canTransfer =
            canTransfer &&
            (amount <= maxTaxReceiversTransactionAmount || !getMaxTaxReceiver(from));

        amountToTax = 0;
        if (shouldTakeFee(from, to)) {
            uint256 totalFee;
            if (pairs[from]) {
                totalFee = transferFees.buyFee;
            } else if (pairs[to]) {
                totalFee = getSellFee(from);
            } else {
                totalFee = getTransferFee(from);
            }

            amountToTax = amount * totalFee / 100;
        }
    }

    /// Given the from and to addresses, return if a fee should taken or not
    /// @dev maxTaxReceiver only applies to sending tokens, and it trumps isFeeExempt
    function shouldTakeFee(address from, address to) public view returns (bool) {
        if (getMaxTaxReceiver(from)) {
            return true;
        } else if (isFeeExempt[from] || isFeeExempt[to]) {
            return false;
        }
        return feesOnNormalTransfers || pairs[from] || pairs[to];
    }

    function getBlacklist(address addr) public view returns (bool) {
        return blacklist[addr] && isBlacklistingEnabled;
    }

    function getMaxTaxReceiver(address addr) public view returns (bool) {
        return maxTaxReceivers[addr] && isMaxTaxReceiversEnabled;
    }

    function swapBackPrivate(uint256 contractBalance) private {
        uint256 feeAmountToLiquidity = contractBalance * feePercentages.liquidityPercent / 100;
        uint256 feeAmountToTreasury = contractBalance * feePercentages.treasuryPercent / 100;

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
            feePercentages.liquidityPercent * 10 / 2 + feePercentages.treasuryPercent * 10;

        // The amounts of the paired coin that will go to the liquidity and treasury.
        uint256 amountLiquidityPairedCoin =
            balancePairedCoin * feePercentages.liquidityPercent * 10 / 2 / percentToPairedCoin;

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
                treasury,
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

    function addLiquidity(uint256 tokenAmount, uint256 pairedCoinAmount) private {
        swapbackSettings.swapRouter.addLiquidity(
            address(omniverse),
            address(swapbackSettings.swapPairedCoin),
            tokenAmount,
            pairedCoinAmount,
            0,
            0,
            treasury,
            block.timestamp
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

    function getSellFee(address addr) private view returns (uint256 sellPercentage) {
        sellPercentage = transferFees.sellFee;
        if (getMaxTaxReceiver(addr)) {
            sellPercentage = transferFees.maxTaxReceiverSellFee;
        }
    }

    function getTransferFee(address addr) private view returns (uint256 transferPercentage) {
        transferPercentage = transferFees.transferFee;
        if (getMaxTaxReceiver(addr)) {
            transferPercentage = transferFees.maxTaxReceiverTransferFee;
        }
    }
}