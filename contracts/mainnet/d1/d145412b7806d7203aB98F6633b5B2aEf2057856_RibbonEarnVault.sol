// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Detailed} from "../../interfaces/IERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {RibbonEarnVaultStorage} from "../../storage/RibbonEarnVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {VaultLifecycleEarn} from "../../libraries/VaultLifecycleEarn.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {IVaultPauser} from "../../interfaces/IVaultPauser.sol";

/**
 * Earn Vault Error Codes
 * R1: loan allocation in USD must be 0
 * R2: option allocation in USD must be 0
 * R3: invalid owner address
 * R4: msg.sender is not keeper
 * R5: msg.sender borrower weight is 0
 * R6: msg.sender is not option seller
 * R7: invalid keeper address
 * R8: invalid fee recipient address
 * R9: invalid option seller
 * R10: time lock still active
 * R11: management fee greater than 100%
 * R12: performance fee greater than 100%
 * R13: deposit cap is zero
 * R14: loan allocation is greater than 100%
 * R15: loan term length is less than a day
 * R16: option purchase frequency is zero
 * R17: option purchase frequency is greater than loan term length
 * R18: cannot use depositETH in non-eth vault
 * R19: cannot use depositETH with msg.value = 0
 * R20: vault asset is not USDC
 * R21: deposit amount is 0
 * R22: deposit amount exceeds vault cap
 * R23: deposit amount less than minimum supply
 * R24: cannot initiate withdraw on 0 shares
 * R25: a withdraw has already been initiated
 * R26: cannot complete withdraw when not initiated
 * R27: cannot complete withdraw when round not closed yet
 * R28: withdraw amount in complete withdraw is zero
 * R29: cannot redeem zero shares
 * R30: cannot redeem more shares than available
 * R31: cannot instantly withdraw zero
 * R32: cannot withdraw in current round
 * R33: exceeding amount withdrawable instantly
 * R34: purchasing option to early since last purchase  * R35: vault asset not recoverable
 * R36: vault share not recoverable
 * R37: recipient cannot be vault
 * R38: transfer failed  * R39: premature roll to next round
 * R40: array length mismatch
 * R41: invalid token name
 * R42: invalid token symbol
 * R43: invalid vault asset
 * R44: invalid vault minimum supply
 * R45: deposit cap must be higher than minimum supply
 * R46: next loan term length must be 0
 * R47: next option purchase frequency must be 0
 * R48: current loan term length must be >= 1 day
 * R49: current option purchase freq must be < loan term length
 * R50: loan pct + option pct == total PCT
 * R51: invalid pending option seller
 */

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in RibbonEarnVaultStorage.
 * RibbonEarnVault should not inherit from any other contract aside from RibbonVault, RibbonEarnVaultStorage
 */
contract RibbonEarnVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    RibbonEarnVaultStorage
{
    using SafeERC20 for IERC20;
    using ShareMath for Vault.DepositReceipt;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to RibbonEarnVaultStorage.
    // Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint32 public constant TOTAL_PCT = 1000000; // Equals 100%

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event BorrowerBasketUpdated(address[] borrowers, uint128[] borrowerWeights);

    event CommitBorrowerBasket(uint256 totalBorrowerWeight);

    event OptionSellerSet(address oldOptionSeller, address newOptionSeller);

    event NewAllocationSet(
        uint256 oldLoanAllocation,
        uint256 oldOptionAllocation,
        uint256 newLoanAllocation,
        uint256 newOptionAllocation
    );

    event NewLoanTermLength(
        uint256 oldLoanTermLength,
        uint256 newLoanTermLength
    );

    event NewOptionPurchaseFrequency(
        uint256 oldOptionPurchaseFrequency,
        uint256 newOptionPurchaseFrequency
    );

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    event OpenLoan(uint256 amount, address indexed borrower);

    event CloseLoan(uint256 amount, uint256 yield, address indexed borrower);

    event PurchaseOption(uint256 premium, address indexed seller);

    event PayOptionYield(
        uint256 yield,
        uint256 netYield,
        address indexed seller
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _borrowers is the addresses of the basket of borrowing entities (EX: Wintermute, GSR, Alameda, Genesis)
     * @param _borrowerWeights is the borrow weight of the addresses
     * @param _optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address[] _borrowers;
        uint128[] _borrowerWeights;
        address _optionSeller;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     * @param _allocationState is the struct with vault loan/option allocation data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams,
        Vault.AllocationState calldata _allocationState
    ) external initializer {
        require(_initParams._owner != address(0), "R3");

        VaultLifecycleEarn.verifyInitializerParams(
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._optionSeller,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams,
            _allocationState,
            TOTAL_PCT
        );

        __ReentrancyGuard_init();
        __ERC20_init(_initParams._tokenName, _initParams._tokenSymbol);
        __Ownable_init();
        transferOwnership(_initParams._owner);

        keeper = _initParams._keeper;

        feeRecipient = _initParams._feeRecipient;
        optionSeller = _initParams._optionSeller;
        performanceFee = _initParams._performanceFee;
        managementFee =
            (_initParams._managementFee * Vault.FEE_MULTIPLIER) /
            ((365 days * Vault.FEE_MULTIPLIER) /
                _allocationState.currentLoanTermLength);
        vaultParams = _vaultParams;
        allocationState = _allocationState;

        _updateBorrowerBasket(
            _initParams._borrowers,
            _initParams._borrowerWeights
        );

        uint256 assetBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "R4");
        _;
    }

    /**
     * @dev Throws if called by any account other than the borrower.
     */
    modifier onlyBorrower() {
        require(borrowerWeights[msg.sender].borrowerWeight > 0, "R5");
        _;
    }

    /**
     * @dev Throws if called by any account other than the option seller.
     */
    modifier onlyOptionSeller() {
        require(msg.sender == optionSeller, "R6");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "R7");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "R8");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Updates the basket of borrowers (this overrides current pending update to basket)
     * @param borrowers is the array of borrowers to update
     * @param borrowerWeights is the array of corresponding borrow weights for the borrower
     */
    function updateBorrowerBasket(
        address[] calldata borrowers,
        uint128[] calldata borrowerWeights
    ) external onlyOwner {
        _updateBorrowerBasket(borrowers, borrowerWeights);
        lastBorrowerBasketChange = block.timestamp;
    }

    /**
     * @notice Sets the new option seller
     * @param newOptionSeller is the address of the new option seller
     */
    function setOptionSeller(address newOptionSeller) external onlyOwner {
        require(newOptionSeller != address(0), "R9");
        emit OptionSellerSet(optionSeller, newOptionSeller);
        pendingOptionSeller = newOptionSeller;
        lastOptionSellerChange = block.timestamp;
    }

    /**
     * @notice Commits the option seller
     */
    function commitOptionSeller() external onlyOwner {
        require(pendingOptionSeller != address(0), "R51");

        optionSeller = pendingOptionSeller;
        pendingOptionSeller = address(0);
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(newManagementFee < 100 * Vault.FEE_MULTIPLIER, "R11");

        // We are dividing annualized management fee by loanTermLength
        uint256 tmpManagementFee =
            (newManagementFee * Vault.FEE_MULTIPLIER) /
                ((365 days * Vault.FEE_MULTIPLIER) /
                    allocationState.currentLoanTermLength);

        emit ManagementFeeSet(managementFee, tmpManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(newPerformanceFee < 100 * Vault.FEE_MULTIPLIER, "R12");

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "R13");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Sets new loan and option allocation percentage
     * @dev Can be called by admin
     * @param _loanAllocationPCT new allocation for loan
     * @param _optionAllocationPCT new allocation for option
     */
    function setAllocationPCT(
        uint32 _loanAllocationPCT,
        uint32 _optionAllocationPCT
    ) external onlyOwner {
        require(_loanAllocationPCT + _optionAllocationPCT <= TOTAL_PCT, "R14");

        emit NewAllocationSet(
            uint256(allocationState.loanAllocationPCT),
            uint256(_loanAllocationPCT),
            uint256(allocationState.optionAllocationPCT),
            uint256(_optionAllocationPCT)
        );

        allocationState.loanAllocationPCT = _loanAllocationPCT;
        allocationState.optionAllocationPCT = _optionAllocationPCT;
    }

    /**
     * @notice Sets loan term length
     * @dev Can be called by admin
     * @param _loanTermLength new loan term length
     */
    function setLoanTermLength(uint32 _loanTermLength) external onlyOwner {
        require(_loanTermLength >= 1 days, "R15");

        allocationState.nextLoanTermLength = _loanTermLength;
        emit NewLoanTermLength(
            allocationState.currentLoanTermLength,
            _loanTermLength
        );
    }

    /**
     * @notice Sets option purchase frequency
     * @dev Can be called by admin
     * @param _optionPurchaseFreq new option purchase frequency
     */
    function setOptionPurchaseFrequency(uint32 _optionPurchaseFreq)
        external
        onlyOwner
    {
        require(_optionPurchaseFreq > 0, "R16");

        require(
            (allocationState.nextLoanTermLength == 0 &&
                _optionPurchaseFreq <= allocationState.currentLoanTermLength) ||
                _optionPurchaseFreq <= allocationState.nextLoanTermLength,
            "R17"
        );
        allocationState.nextOptionPurchaseFreq = _optionPurchaseFreq;
        emit NewOptionPurchaseFrequency(
            allocationState.currentOptionPurchaseFreq,
            _optionPurchaseFreq
        );
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @param newVaultPauser is the address of the new vaultPauser contract
     */
    function setVaultPauser(address newVaultPauser) external onlyOwner {
        vaultPauser = newVaultPauser;
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits the `asset` from msg.sender without an approve
     * `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments
     * @param amount is the amount of `asset` to deposit
     * @param deadline must be a timestamp in the future
     * @param v is a valid signature
     * @param r is a valid signature
     * @param s is a valid signature
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(vaultParams.asset == USDC, "R20");
        require(amount > 0, "R21");

        // Sign for transfer approval
        IERC20Permit(vaultParams.asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "R21");

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "R21");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance() + amount;

        require(totalWithDepositedAmount <= vaultParams.cap, "R22");
        require(totalWithDepositedAmount >= vaultParams.minimumSupply, "R23");

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount) + amount;
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "R24");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares + numShares;
        } else {
            require(existingShares == 0, "R25");
            withdrawalShares = numShares;
            withdrawal.round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawal.shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "R26");

        require(withdrawalRound < vaultState.round, "R27");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawal.shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares) - withdrawalShares
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "R29");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "R30");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares - numShares
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "R31");
        require(depositReceipt.round == currentRound, "R32");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "R33");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount - amount);
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending) - amount
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        IERC20(vaultParams.asset).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares + numShares;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();

        require(withdrawAmount > 0, "R28");
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount) - withdrawAmount
        );
        IERC20(vaultParams.asset).safeTransfer(msg.sender, withdrawAmount);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares - heldByAccount, false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     */
    function rollToNextRound() external onlyKeeper nonReentrant {
        vaultState.lastLockedAmount = uint104(vaultState.lockedAmount);

        (uint256 lockedBalance, uint256 queuedWithdrawAmount) =
            _rollToNextRound();

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares) +
                currentQueuedWithdrawShares;

        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        ShareMath.assertUint104(lockedBalance);

        vaultState.lockedAmount = uint104(lockedBalance);
        vaultState.optionsBoughtInRound = 0;
        vaultState.amtFundsReturned = 0;

        uint256 loanAllocation = allocationState.loanAllocation;

        for (uint256 i = 0; i < borrowers.length; i++) {
            // Amount to lending = total USD loan allocation * weight of current borrower / total weight of all borrowers
            uint256 amtToLendToBorrower =
                (loanAllocation *
                    borrowerWeights[borrowers[i]].borrowerWeight) /
                    totalBorrowerWeight;

            if (amtToLendToBorrower == 0) {
                continue;
            }

            // Lend funds to borrower
            IERC20(vaultParams.asset).safeTransfer(
                borrowers[i],
                amtToLendToBorrower
            );

            emit OpenLoan(amtToLendToBorrower, borrowers[i]);
        }
    }

    /**
     * @notice Buys the option by transferring premiums to option seller
     */
    function buyOption() external onlyKeeper {
        require(
            vaultState.optionsBoughtInRound == 0 ||
                block.timestamp >=
                uint256(vaultState.lastOptionPurchaseTime) +
                    allocationState.currentOptionPurchaseFreq,
            "R34"
        );

        uint256 optionAllocation =
            allocationState.optionAllocation /
                (uint256(allocationState.currentLoanTermLength) /
                    allocationState.currentOptionPurchaseFreq);

        vaultState.optionsBoughtInRound += uint128(optionAllocation);
        vaultState.lastOptionPurchaseTime = uint64(
            block.timestamp - (block.timestamp % (24 hours)) + (8 hours)
        );

        IERC20(vaultParams.asset).safeTransfer(optionSeller, optionAllocation);

        emit PurchaseOption(optionAllocation, optionSeller);
    }

    /**
     * @notice Pays option yield if option is ITM
     * `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments
     * @param amount is the amount of yield to pay
     * @param deadline must be a timestamp in the future
     * @param v is a valid signature
     * @param r is a valid signature
     * @param s is a valid signature
     */
    function payOptionYield(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOptionSeller {
        // Sign for transfer approval
        IERC20Permit(vaultParams.asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Pay option yields to contract
        _payOptionYield(amount);
    }

    /**
     * @notice Pays option yield if option is ITM
     * @param amount is the amount of yield to pay
     */
    function payOptionYield(uint256 amount) external onlyOptionSeller {
        // Pay option yields to contract
        _payOptionYield(amount);
    }

    /**
     * @notice Return lend funds
     * `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments
     * @param amount is the amount to return (principal + interest)
     * @param deadline must be a timestamp in the future
     * @param v is a valid signature
     * @param r is a valid signature
     * @param s is a valid signature
     */
    function returnLentFunds(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyBorrower {
        // Sign for transfer approval
        IERC20Permit(vaultParams.asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Return lent funds
        _returnLentFunds(amount);
    }

    /**
     * @notice Return lend funds
     * @param amount is the amount to return (principal + interest)
     */
    function returnLentFunds(uint256 amount) external onlyBorrower {
        // Return lent funds
        _returnLentFunds(amount);
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     */
    function recoverTokens(address token, address recipient)
        external
        onlyOwner
    {
        require(token != vaultParams.asset, "R35");
        require(token != address(this), "R36");
        require(recipient != address(this), "R37");

        IERC20(token).safeTransfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     * @notice pause a user's vault position
     */
    function pausePosition() external {
        address _vaultPauserAddress = vaultPauser;
        require(_vaultPauserAddress != address(0)); // Removed revert msgs due to contract size limit
        _redeem(0, true);
        uint256 heldByAccount = balanceOf(msg.sender);
        _approve(msg.sender, _vaultPauserAddress, heldByAccount);
        IVaultPauser(_vaultPauserAddress).pausePosition(
            msg.sender,
            heldByAccount
        );
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as minting new shares, getting vault fees, etc.
     * @return lockedBalance is the new balance used to calculate next option purchase size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _rollToNextRound()
        internal
        returns (uint256 lockedBalance, uint256 queuedWithdrawAmount)
    {
        require(
            block.timestamp >=
                uint256(vaultState.lastEpochTime) +
                    allocationState.currentLoanTermLength,
            "R39"
        );

        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;
            (
                lockedBalance,
                queuedWithdrawAmount,
                newPricePerShare,
                mintShares,
                performanceFeeInAsset,
                totalVaultFee
            ) = VaultLifecycleEarn.rollover(
                vaultState,
                VaultLifecycleEarn.RolloverParams(
                    vaultParams.decimals,
                    IERC20(vaultParams.asset).balanceOf(address(this)),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares
                )
            );

            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);
            vaultState.lastEpochTime = uint64(
                block.timestamp - (block.timestamp % (24 hours)) + (8 hours)
            );
        }

        _mint(address(this), mintShares);

        if (totalVaultFee > 0) {
            IERC20(vaultParams.asset).safeTransfer(recipient, totalVaultFee);
        }

        _updateAllocationState(lockedBalance);
        _commitBorrowerBasket();

        return (lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function that transfers funds from option
     * seller
     * @param amount is the amount of yield to pay
     */
    function _payOptionYield(uint256 amount) internal {
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 optionAllocation =
            allocationState.optionAllocation /
                (uint256(allocationState.currentLoanTermLength) /
                    allocationState.currentOptionPurchaseFreq);

        emit PayOptionYield(
            amount,
            amount > optionAllocation ? amount - optionAllocation : 0,
            msg.sender
        );
    }

    function _returnLentFunds(uint256 amount) internal {
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Amount lent = total USD loan allocation * weight of current borrower / total weight of all borrowers
        uint256 loanAllocation =
            (allocationState.loanAllocation *
                borrowerWeights[msg.sender].borrowerWeight) /
                totalBorrowerWeight;

        vaultState.amtFundsReturned += amount;

        emit CloseLoan(
            amount,
            amount > loanAllocation ? amount - loanAllocation : 0,
            msg.sender
        );
    }

    /**
     * @notice Helper function that updates allocation state
     * such as loan term length, option purchase frequency, loan / option
     * allocation split, etc.
     * @param lockedBalance is the locked balance for newest epoch
     */
    function _updateAllocationState(uint256 lockedBalance) internal {
        Vault.AllocationState memory _allocationState = allocationState;

        // Set next loan term length
        if (_allocationState.nextLoanTermLength != 0) {
            uint256 tmpManagementFee = managementFee;
            managementFee =
                (tmpManagementFee * _allocationState.nextLoanTermLength) /
                _allocationState.currentLoanTermLength;

            allocationState.currentLoanTermLength = _allocationState
                .nextLoanTermLength;
            allocationState.nextLoanTermLength = 0;

            emit ManagementFeeSet(tmpManagementFee, managementFee);
        }

        // Set next option purchase frequency
        if (_allocationState.nextOptionPurchaseFreq != 0) {
            allocationState.currentOptionPurchaseFreq = _allocationState
                .nextOptionPurchaseFreq;
            allocationState.nextOptionPurchaseFreq = 0;
        }

        // Set next loan allocation from vault in USD
        allocationState.loanAllocation =
            (uint256(_allocationState.loanAllocationPCT) * lockedBalance) /
            TOTAL_PCT;

        // Set next option allocation from vault per purchase in USD
        allocationState.optionAllocation =
            (uint256(_allocationState.optionAllocationPCT) * lockedBalance) /
            TOTAL_PCT;
    }

    /**
     * @notice Helper function to update basket of borrowers
     * @param pendingBorrowers is the array of borrowers to add
     * @param pendingBorrowWeights is the array of corresponding borrow weights for the borrower
     */
    function _updateBorrowerBasket(
        address[] calldata pendingBorrowers,
        uint128[] calldata pendingBorrowWeights
    ) internal {
        uint256 borrowerArrLen = pendingBorrowers.length;

        require(borrowerArrLen == pendingBorrowWeights.length, "R40");

        // Set current pending changes to basket of borrowers
        for (uint256 i = 0; i < borrowerArrLen; i++) {
            if (pendingBorrowers[i] == address(0)) {
                continue;
            }

            // Borrower does not exist
            if (!borrowerWeights[pendingBorrowers[i]].exists) {
                borrowers.push(pendingBorrowers[i]);
                borrowerWeights[pendingBorrowers[i]].exists = true;
            }

            // Set pending borrower weight
            borrowerWeights[pendingBorrowers[i]]
                .pendingBorrowerWeight = pendingBorrowWeights[i];
        }

        emit BorrowerBasketUpdated(pendingBorrowers, pendingBorrowWeights);
    }

    /**
     * @notice Helper function that commits borrower basket
     */
    function _commitBorrowerBasket() internal {
        require(block.timestamp >= (lastBorrowerBasketChange + 3 days), "R10");

        // Set current pending changes to basket of borrowers
        for (uint256 i = 0; i < borrowers.length; i++) {
            uint128 borrowWeight = borrowerWeights[borrowers[i]].borrowerWeight;
            uint128 pendingBorrowWeight =
                borrowerWeights[borrowers[i]].pendingBorrowerWeight;
            // Set borrower weight to pending borrower weight
            if (borrowWeight != pendingBorrowWeight) {
                borrowerWeights[borrowers[i]]
                    .borrowerWeight = pendingBorrowWeight;
                // Update total borrowing weight
                totalBorrowerWeight += pendingBorrowWeight;
                totalBorrowerWeight -= borrowWeight;
            }
        }

        emit CommitBorrowerBasket(totalBorrowerWeight);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount + heldByVault;
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts lent out
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        uint256 lockedForLoan = allocationState.loanAllocation;

        uint256 amtPrincipalReturned =
            vaultState.amtFundsReturned > lockedForLoan
                ? lockedForLoan
                : vaultState.amtFundsReturned;

        // Does not include funds allocated for options purchases
        // Includes funds set aside in vault that guarantee base yield
        // We subtract the amount of principal returned to avoid double counting in locked amount / USDC balance
        return
            lockedForLoan +
            IERC20(vaultParams.asset).balanceOf(address(this)) -
            amtPrincipalReturned;
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
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
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "../libraries/Vault.sol";

abstract contract RibbonEarnVaultStorageV1 {
    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the allocation between lending and buying options
    Vault.AllocationState public allocationState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextRound and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice borrowers is the array of borrowing addresses (EX: Wintermute, GSR, Alameda, Genesis)
    address[] public borrowers;

    /// @notice borrowerMapping is the mapping from borrower to their borrow weight. EX: {Wintermute -> 0.4, GSR -> 0.2}
    mapping(address => Vault.BorrowerState) public borrowerWeights;

    /// @notice totalBorrowerWeight is the total borrowing weight
    uint256 public totalBorrowerWeight;

    /// @notice lastBorrowerBasketChange is the last time the basket of borrowers was changed (add / remove / set)
    uint256 public lastBorrowerBasketChange;

    /// @notice optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
    address public optionSeller;

    /// @notice pendingOptionSeller is the pending address of the entity that we will be buying options from (EX: Orbit)
    address public pendingOptionSeller;

    /// @notice lastOptionSellerChange is the last time option seller was set
    uint256 public lastOptionSellerChange;

    /// @notice Performance fee charged on premiums earned in rollToNextRound. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextRound. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;

    /// @notice Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;

    /// @notice Vault Pauser Contract for the vault
    address public vaultPauser;

    /// @notice LiquidityGauge contract for the vault
    address public liquidityGauge;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonEarnVaultStorage
// e.g. RibbonEarnVaultStorage<versionNumber>, so finally it would look like
// contract RibbonEarnVaultStorage is RibbonEarnVaultStorageV1, RibbonEarnVaultStorageV2
abstract contract RibbonEarnVaultStorage is RibbonEarnVaultStorageV1 {

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Yield is scaled by 100 (10 ** 2) for PCT.
    uint256 internal constant YIELD_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in vault
        address asset;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct AllocationState {
        // Next Loan Term Length
        uint32 nextLoanTermLength;
        // Next Option Purchase Frequency
        uint32 nextOptionPurchaseFreq;
        // Current Loan Term Length
        uint32 currentLoanTermLength;
        // Current Option Purchase Frequency
        uint32 currentOptionPurchaseFreq;
        // Current Loan Allocation Percent
        uint32 loanAllocationPCT;
        // Current Option Purchase Allocation Percent
        uint32 optionAllocationPCT;
        // Loan Allocation in USD
        uint256 loanAllocation;
        // Option Purchase Allocation across all purchases
        uint256 optionAllocation;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for the strategy
        uint104 lockedAmount;
        // Amount that was locked for the strategy in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint128 queuedWithdrawShares;
        // Last Loan Allocation Date
        uint64 lastEpochTime;
        // Last Option Purchase Date
        uint64 lastOptionPurchaseTime;
        // Amount of options bought in current round
        uint128 optionsBoughtInRound;
        // Amount of funds returned this round
        uint256 amtFundsReturned;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    /**
     * @param borrowerWeight is the borrow weight of the borrower
     * @param pendingBorrowerWeight is the pending borrow weight
     * @param exists is whether the borrower has already been added
     */
    struct BorrowerState {
        // Borrower exists
        bool exists;
        // Borrower weight
        uint128 borrowerWeight;
        // Borrower weight
        uint128 pendingBorrowerWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";

import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";

library VaultLifecycleEarn {
    using SupportsNonCompliantERC20 for IERC20;

    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the vaults total balance of the asset
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the total amount queued for withdrawals
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     * @param currentQueuedWithdrawShares is amount of queued withdrawals from the current round
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 currentQueuedWithdrawShares;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees =
            currentBalance - params.lastQueuedWithdrawAmount;

        {
            (performanceFeeInAsset, , totalVaultFee) = VaultLifecycleEarn
                .getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                params.managementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance - totalVaultFee;

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply - lastQueuedWithdrawShares,
                currentBalance - params.lastQueuedWithdrawAmount,
                pendingAmount,
                params.decimals
            );

            queuedWithdrawAmount =
                params.lastQueuedWithdrawAmount +
                ShareMath.sharesToAsset(
                    params.currentQueuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );
        }

        return (
            currentBalance - queuedWithdrawAmount, // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount ? currentBalance - pendingAmount : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? ((lockedBalanceSansPending - lastLockedAmount) *
                    performanceFeePercent) / (100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? (lockedBalanceSansPending * managementFeePercent) /
                    (100 * Vault.FEE_MULTIPLIER)
                : 0;

            _vaultFee = _performanceFeeInAsset + _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     * @param _allocationState is the struct with vault loan/option allocation data
     */
    function verifyInitializerParams(
        address keeper,
        address feeRecipient,
        address optionSeller,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams,
        Vault.AllocationState calldata _allocationState,
        uint256 totalPCT
    ) external pure {
        require(keeper != address(0), "R7");
        require(feeRecipient != address(0), "R8");
        require(optionSeller != address(0), "R9");

        require(performanceFee < 100 * Vault.FEE_MULTIPLIER, "R12");
        require(managementFee < 100 * Vault.FEE_MULTIPLIER, "R11");
        require(bytes(tokenName).length > 0, "R41");
        require(bytes(tokenSymbol).length > 0, "R42");

        require(_vaultParams.asset != address(0), "R43");
        require(_vaultParams.minimumSupply > 0, "R44");
        require(_vaultParams.cap > 0, "R13");
        require(_vaultParams.cap > _vaultParams.minimumSupply, "R45");

        require(_allocationState.nextLoanTermLength == 0, "R46");
        require(_allocationState.nextOptionPurchaseFreq == 0, "R47");
        require(_allocationState.currentLoanTermLength >= 1 days, "R48");
        require(
            _allocationState.currentOptionPurchaseFreq > 0 &&
                _allocationState.currentOptionPurchaseFreq <=
                _allocationState.currentLoanTermLength,
            "R49"
        );
        require(
            uint256(_allocationState.loanAllocationPCT) +
                _allocationState.optionAllocationPCT <=
                totalPCT,
            "R50"
        );
        require(_allocationState.loanAllocation == 0, "R1");
        require(_allocationState.optionAllocation == 0, "R2");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "./Vault.sol";

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * (10**decimals)) / assetPerShare;
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * assetPerShare) / (10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound =
                assetToShares(depositReceipt.amount, assetPerShare, decimals);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? (singleShare * (totalBalance - pendingAmount)) / totalSupply
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILiquidityGauge {
    function balanceOf(address) external view returns (uint256);

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IVaultPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice resume vault position of an account with max amount
    /// @param _vaultAddress the address of vault
    function resumePosition(address _vaultAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * This library supports ERC20s that have quirks in their behavior.
 * One such ERC20 is USDT, which requires allowance to be 0 before calling approve.
 * We plan to update this library with ERC20s that display such idiosyncratic behavior.
 */
library SupportsNonCompliantERC20 {
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function safeApproveNonCompliant(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (address(token) == USDT) {
            SafeERC20.safeApprove(token, spender, 0);
        }
        SafeERC20.safeApprove(token, spender, amount);
    }
}