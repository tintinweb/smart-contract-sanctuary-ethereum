/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OnOwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }
}

contract CustomInitializable {
    bool private _wasInitialized;

    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

interface IClearPoolFactory {
    function withdrawReward (address[] memory poolsList) external;
    function cpool () external view returns (IERC20);
}

/**
 * @title Represents a primitive strategy for liquidity pools.
 */
abstract contract PrimitivePoolStrategy is CustomInitializable, CustomOwnable, ReentrancyGuard {
    // The zero address
    address internal constant ZERO_ADDRESS = address(0);

    /// @notice The address of the liquidity pool.
    address public poolAddress;

    /// @notice The address of the collateral token. For example: USDC
    address public collateralTokenAddress;

    /// @notice The address authorized to deposit collateral into this contract.
    address public vaultAddress;

    /// @notice The address authorized to interact with the pool
    address public operator;

    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    event OnCollateralDeposit (uint256 depositAmount, address tokenAddr, address senderAddr);
    event OnCollateralWithdrawal (uint256 withdrawalAmount, address tokenAddr, address senderAddr);
    event OnPoolDeposit (address tokenAddress, uint256 collateralDepositAmount);
    event OnPoolWithdrawal (uint256 lpTokensAmount, uint256 collateralAmount);
    event OnVaultAddressUpdated (address prevValue, address newValue);
    event OnOperatorUpdated (address prevValue, address newValue);

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier onlyVault () {
        require(msg.sender == vaultAddress, "Unauthorized vault");
        _;
    }

    modifier onlyOwnerOrVault () {
        require(msg.sender == vaultAddress || msg.sender == _owner, "Unauthorized caller");
        _;
    }

    modifier onlyOwnerOrOperator () {
        require(msg.sender == operator || msg.sender == _owner, "Unauthorized operator");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    // ---------------------------------------------------------------
    // State changing functions
    // ---------------------------------------------------------------
    /**
     * @notice Changes the address of the Vault.
     * @param vaultAddr Specifies the address of the new vault.
     */
    function changeVaultAddress(address vaultAddr) external onlyOwnerOrOperator {
        require(vaultAddr != ZERO_ADDRESS, "Invalid address");

        emit OnVaultAddressUpdated(vaultAddress, vaultAddr);
        vaultAddress = vaultAddr;
    }

    /**
     * @notice Switches to a new operator.
     * @param operatorAddr Specifies the address of the new operator.
     */
    function changeOperator(address operatorAddr) external onlyOwner {
        require(operatorAddr != ZERO_ADDRESS, "Invalid address");

        emit OnOperatorUpdated(operator, operatorAddr);
        operator = operatorAddr;
    }

    // Deposits the token specified into this contract
    function _depositIntoThisContract (uint256 depositAmount, address senderAddr, IERC20 token) internal virtual returns (uint256) {
        // Checks
        require(depositAmount > 0, "Invalid deposit amount");
        require(token.balanceOf(senderAddr) >= depositAmount, "Insufficient balance");
        require(token.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");

        uint256 balanceBeforeTransfer = token.balanceOf(address(this));
        require(token.transferFrom(senderAddr, address(this), depositAmount), "TransferFrom failed");
        uint256 balanceAfterTransfer = token.balanceOf(address(this));
        require(balanceAfterTransfer == balanceBeforeTransfer + depositAmount, "Balance verification failed");

        emit OnCollateralDeposit(depositAmount, address(token), senderAddr);

        return balanceAfterTransfer;
    }

    // Transfers a given amount of tokens to the address specified
    function _withdrawFromThisContract (uint256 withdrawalAmount, address senderAddr, IERC20 token) internal virtual {
        // Checks
        require(withdrawalAmount > 0, "Invalid withdrawal amount");
        require(token.balanceOf(address(this)) >= withdrawalAmount, "Insufficient balance");

        // State changes
        require(token.transfer(senderAddr, withdrawalAmount), "Token transfer failed");
        emit OnCollateralWithdrawal(withdrawalAmount, address(token), senderAddr);
    }

    // ---------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------
    /**
     * @notice Gets the amount of collateral tokens owned by this contract.
     * @dev This function is provided as a handy shortcut only. Check the foreign contract otherwise.
     * @return Returns the balance of this contract, in collateral tokens.
     */
    function getCollateralBalance () external view returns (uint256) {
        return IERC20(collateralTokenAddress).balanceOf(address(this));
    }

    /**
     * @notice Gets the number of Liquidity Pool tokens owned by this contract.
     * @dev This function is provided as a handy shortcut only. Check the foreign contract otherwise.
     * @return Returns the balance of this contract, in Liquidity Pool tokens.
     */
    function getPoolBalance () external view returns (uint256) {
        return IERC20(poolAddress).balanceOf(address(this));
    }

    // ---------------------------------------------------------------
    // Abstract functions
    // ---------------------------------------------------------------
    function depositCollateral (uint256 depositAmount) external virtual;
    function withdrawCollateral (uint256 withdrawalAmount) external virtual;
    function enterPool (uint256 collateralDepositAmount) external virtual;
    function exitPool (uint256 lpTokensAmount) external virtual;
    function claimRewards () external virtual;
    function getRewardsTokenAddress () external virtual view returns (address);
}

interface IParaswapv4 {
  function getTokenTransferProxy() external view returns (address);
}

interface IClearPoolBase is IERC20 {
    function provide (uint256 currencyAmount) external;
    function redeem (uint256 tokens) external;

    function currency () external view returns (IERC20);
    function factory () external view returns (IClearPoolFactory);
    function getCurrentExchangeRate () external view returns (uint256);
    function getUtilizationRate() external view returns (uint256);
    function withdrawableRewardOf (address account) external view returns (uint256);
}

/**
 * @title Strategy for ClearPool
 */
contract ClearPoolStrategy is PrimitivePoolStrategy {
    /// @notice The address of Paraswap on the current chain
    address public paraswapAddress;

    /**
     * @notice Initializes this strategy.
     * @param pool The address of the pool
     * @param vaultAddr The address of the vault
     * @param operatorAddr The address of the operator
     * @param paraswapAddr The address of the operator
     */
    function initializeStrategy (IClearPoolBase pool, address vaultAddr, address operatorAddr, address paraswapAddr) external onlyOwner ifNotInitialized {
        // Checks
        require(vaultAddr != ZERO_ADDRESS && vaultAddr != address(this), "Invalid vault address");
        require(operatorAddr != ZERO_ADDRESS && operatorAddr != address(this), "Invalid operator address");
        require(paraswapAddr != ZERO_ADDRESS && paraswapAddr != address(this), "Invalid swap address");
        require(address(pool) != ZERO_ADDRESS, "Invalid Pool address");
        require(address(pool.currency()) != ZERO_ADDRESS, "Invalid currency address");

        // State changes
        poolAddress = address(pool);
        collateralTokenAddress = address(pool.currency());
        vaultAddress = vaultAddr;
        operator = operatorAddr;
        paraswapAddress = paraswapAddr;

        // Mark initialization as "completed"
        _initializationCompleted();
    }

    /**
     * @notice Deposits a given amount of collateral into this contract.
     * @dev The deposit amount must be expressed in the decimal precision of the collateral token.
     * @param depositAmount The amount of collateral to deposit. For example: 5000000 if the collateral is 5 USDC
     */
    function depositCollateral (uint256 depositAmount) external override onlyVault ifInitialized nonReentrant {
        _depositIntoThisContract(depositAmount, msg.sender, IERC20(collateralTokenAddress));
    }

    /**
     * @notice Withdraws the amount of collateral specified from this contract.
     * @dev The withdrawal amount must be expressed in the decimal precision of the collateral token.
     * @param withdrawalAmount The amount of collateral to withdraw.
     */
    function withdrawCollateral (uint256 withdrawalAmount) external override onlyOwnerOrVault ifInitialized nonReentrant {
        _withdrawFromThisContract(withdrawalAmount, msg.sender, IERC20(collateralTokenAddress));
    }

    /**
     * @notice Deposits a given amount of collateral into the liquidity pool specified.
     * @dev The deposit amount must be expressed in the decimal precision of the collateral. For example: 5000000 for 5 USDC
     * @param collateralDepositAmount The amount of collateral to deposit into the liquidity pool.
     */
    function enterPool (uint256 collateralDepositAmount) external override onlyOwnerOrOperator ifInitialized nonReentrant {
        // Checks
        require(collateralDepositAmount > 0, "Deposit amount required");
        require(IERC20(collateralTokenAddress).balanceOf(address(this)) >= collateralDepositAmount, "Insufficient collateral");

        // Run a spender approval, if needed.
        if (collateralDepositAmount > IERC20(collateralTokenAddress).allowance(address(this), poolAddress)) {
            require(IERC20(collateralTokenAddress).approve(poolAddress, collateralDepositAmount), "Collateral approval failed");
        }

        // Calculate the outcome in advance
        uint256 balanceBeforeDeposit = IClearPoolBase(poolAddress).balanceOf(address(this));
        uint256 exchangeRate = IClearPoolBase(poolAddress).getCurrentExchangeRate();
        uint256 minOutputTokensExpected = (collateralDepositAmount * 1e18) / exchangeRate;

        // Deposit collateral into the liquidity pool
        IClearPoolBase(poolAddress).provide(collateralDepositAmount);

        // Check the outcome
        require(IClearPoolBase(poolAddress).balanceOf(address(this)) == balanceBeforeDeposit + minOutputTokensExpected, "Balance verification failed");

        // All good. Log the event.
        emit OnPoolDeposit(collateralTokenAddress, collateralDepositAmount);
    }

    /**
     * @notice Withdraws a given amount of funds from the liquidity pool specified.
     * @param lpTokensAmount The number of tokens to withdraw from the liquidity pool, at the current exchange rate.
     */
    function exitPool (uint256 lpTokensAmount) external override onlyOwnerOrOperator ifInitialized nonReentrant {
        // Checks
        require(lpTokensAmount > 0, "Withdrawal amount required");
        require(IERC20(poolAddress).balanceOf(address(this)) >= lpTokensAmount, "Insufficient balance of LP tokens");

        uint256 balanceBefore = IERC20(collateralTokenAddress).balanceOf(address(this));
        uint256 exchangeRate = IClearPoolBase(poolAddress).getCurrentExchangeRate();
        uint256 expectedBalance = (lpTokensAmount * exchangeRate) / 1e18;

        IClearPoolBase(poolAddress).redeem(lpTokensAmount);
        require(IERC20(collateralTokenAddress).balanceOf(address(this)) == balanceBefore + expectedBalance, "Balance verification failed");
        emit OnPoolWithdrawal(lpTokensAmount, expectedBalance);
    }

    /**
     * @notice Claims rewards from the liquidity pool
     */
    function claimRewards () external override onlyOwnerOrOperator ifInitialized nonReentrant {
        uint256 claimableRewards = IClearPoolBase(poolAddress).withdrawableRewardOf(address(this));
        require(claimableRewards > 0, "No rewards to claim");

        IClearPoolFactory factory = IClearPoolBase(poolAddress).factory();

        uint256 previousBalance = factory.cpool().balanceOf(address(this));

        address[] memory poolsList = new address[](1);
        poolsList[0] = poolAddress;
        factory.withdrawReward(poolsList);

        uint256 newBalance = factory.cpool().balanceOf(address(this));
        require(newBalance > previousBalance && newBalance == previousBalance + claimableRewards, "Balance verification failed");

        // Forward funds to the authorized sender
        require(factory.cpool().transfer(msg.sender, newBalance), "Rewards transfer failed");
    }

    /**
     * @notice Swap rewards via the paraswap router. 
     * @param srcToken Token to swap from.
     * @param amount The amount of token to swap.
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swapOnParaswap (address srcToken, uint256 amount, bytes memory callData) public payable onlyOwner ifInitialized nonReentrant {
        //get TokenTransferProxy depending on chain.
        address tokenTransferProxy = IParaswapv4(paraswapAddress).getTokenTransferProxy();

        // allow TokenTransferProxy to spend srcToken of this contract
        IERC20(srcToken).approve(tokenTransferProxy, amount); 
        
        (bool success,) = paraswapAddress.call(callData);
        require(success, "swap failed");  
    }

    /**
     * @notice Gets the current value of the position.
     * @dev The value is zero if you didn't make any deposits in the liquidity pool.
     * @return Returns the value of the position expressed in collateral tokens.
     */
    function getCollateralValue () external view ifInitialized returns (uint256) {
        uint256 currentBalance = IERC20(poolAddress).balanceOf(address(this));
        uint256 exchangeRate = IClearPoolBase(poolAddress).getCurrentExchangeRate();
        return (currentBalance * exchangeRate) / 1e18;
    }

    /**
     * @notice Gets the utilization rate of the pool.
     * @return Returns the utilization rate as 18-digit decimal
     */
    function getUtilizationRate () external view ifInitialized returns (uint256) {
        return IClearPoolBase(poolAddress).getUtilizationRate();
    }

    /**
     * @notice Gets the amount of reward tokens that can be claimed from the Liquidity Pool.
     * @dev The result is expressed in the decimal precision of the rewards token.
     * @return Returns the amount of claimable rewards.
     */
    function getClaimableRewardsAmount () external view ifInitialized returns (uint256) {
        return IClearPoolBase(poolAddress).withdrawableRewardOf(address(this));
    }

    /**
     * @notice Gets the address of the rewards token.
     * @return Returns the address of the rewards token.
     */
    function getRewardsTokenAddress () external view override ifInitialized returns (address) {
        IClearPoolFactory factory = IClearPoolBase(poolAddress).factory();
        return address(factory.cpool());
    }
}