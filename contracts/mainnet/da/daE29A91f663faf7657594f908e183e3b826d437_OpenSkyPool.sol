// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/IOpenSkyCollateralPriceOracle.sol';
import './interfaces/IOpenSkyReserveVaultFactory.sol';
import './interfaces/IOpenSkyNFTDescriptor.sol';
import './interfaces/IOpenSkyLoan.sol';
import './interfaces/IOpenSkyPool.sol';
import './interfaces/IOpenSkySettings.sol';
import './interfaces/IACLManager.sol';
import './libraries/math/MathUtils.sol';
import './libraries/math/PercentageMath.sol';
import './libraries/helpers/Errors.sol';
import './libraries/types/DataTypes.sol';
import './libraries/ReserveLogic.sol';

/**
 * @title OpenSkyPool contract
 * @author OpenSky Labs
 * @notice Main point of interaction with OpenSky protocol's pool
 * - Users can:
 *   # Deposit
 *   # Withdraw
 **/
contract OpenSkyPool is Context, Pausable, ReentrancyGuard, IOpenSkyPool {
    using PercentageMath for uint256;
    using Counters for Counters.Counter;
    using ReserveLogic for DataTypes.ReserveData;

    // Map of reserves and their data
    mapping(uint256 => DataTypes.ReserveData) public reserves;

    IOpenSkySettings public immutable SETTINGS;
    Counters.Counter private _reserveIdTracker;

    constructor(address SETTINGS_) Pausable() ReentrancyGuard() {
        SETTINGS = IOpenSkySettings(SETTINGS_);
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isPoolAdmin(_msgSender()), Errors.ACL_ONLY_POOL_ADMIN_CAN_CALL);
        _;
    }

    /**
     * @dev Only liquidator can call functions marked by this modifier.
     **/
    modifier onlyLiquidator() {
        require(SETTINGS.isLiquidator(_msgSender()), Errors.ACL_ONLY_LIQUIDATOR_CAN_CALL);
        _;
    }

    /**
     * @dev Only emergency admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isEmergencyAdmin(_msgSender()), Errors.ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL);
        _;
    }

    /**
     * @dev functions marked by this modifier can be executed only when the specific reserve exists.
     **/
    modifier checkReserveExists(uint256 reserveId) {
        require(_exists(reserveId), Errors.RESERVE_DOES_NOT_EXIST);
        _;
    }

    /**
     * @dev Pause pool for emergency case, can only be called by emergency admin.
     **/
    function pause() external onlyEmergencyAdmin {
        _pause();
    }

    /**
     * @dev Unpause pool for emergency case, can only be called by emergency admin.
     **/
    function unpause() external onlyEmergencyAdmin {
        _unpause();
    }

    /**
     * @dev Check if specific reserve exists.
     **/
    function _exists(uint256 reserveId) internal view returns (bool) {
        return reserves[reserveId].reserveId > 0;
    }

    /// @inheritdoc IOpenSkyPool
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external override onlyPoolAdmin {
        _reserveIdTracker.increment();
        uint256 reserveId = _reserveIdTracker.current();
        address oTokenAddress = IOpenSkyReserveVaultFactory(SETTINGS.vaultFactoryAddress()).create(
            reserveId,
            name,
            symbol,
            decimals,
            underlyingAsset
        );
        reserves[reserveId] = DataTypes.ReserveData({
            reserveId: reserveId,
            underlyingAsset: underlyingAsset,
            oTokenAddress: oTokenAddress,
            moneyMarketAddress: SETTINGS.moneyMarketAddress(),
            lastSupplyIndex: uint128(WadRayMath.RAY),
            borrowingInterestPerSecond: 0,
            lastMoneyMarketBalance: 0,
            lastUpdateTimestamp: 0,
            totalBorrows: 0,
            interestModelAddress: SETTINGS.interestRateStrategyAddress(),
            treasuryFactor: SETTINGS.reserveFactor(),
            isMoneyMarketOn: true
        });
        emit Create(reserveId, underlyingAsset, oTokenAddress, name, symbol, decimals);
    }

    function claimERC20Rewards(uint256 reserveId, address token) external onlyPoolAdmin {
        IOpenSkyOToken(reserves[reserveId].oTokenAddress).claimERC20Rewards(token);
    }

    /// @inheritdoc IOpenSkyPool
    function setTreasuryFactor(uint256 reserveId, uint256 factor)
        external
        override
        checkReserveExists(reserveId)
        onlyPoolAdmin
    {
        require(factor <= SETTINGS.MAX_RESERVE_FACTOR(), Errors.RESERVE_TREASURY_FACTOR_NOT_ALLOWED);
        reserves[reserveId].treasuryFactor = factor;
        emit SetTreasuryFactor(reserveId, factor);
    }

    /// @inheritdoc IOpenSkyPool
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress)
        external
        override
        checkReserveExists(reserveId)
        onlyPoolAdmin
    {
        reserves[reserveId].interestModelAddress = interestModelAddress;
        emit SetInterestModelAddress(reserveId, interestModelAddress);
    }

    /// @inheritdoc IOpenSkyPool
    function openMoneyMarket(uint256 reserveId) external override checkReserveExists(reserveId) onlyEmergencyAdmin {
        require(!reserves[reserveId].isMoneyMarketOn, Errors.RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR);
        reserves[reserveId].openMoneyMarket();
        emit OpenMoneyMarket(reserveId);
    }

    /// @inheritdoc IOpenSkyPool
    function closeMoneyMarket(uint256 reserveId) external override checkReserveExists(reserveId) onlyEmergencyAdmin {
        require(reserves[reserveId].isMoneyMarketOn, Errors.RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR);
        reserves[reserveId].closeMoneyMarket();
        emit CloseMoneyMarket(reserveId);
    }

    /// @inheritdoc IOpenSkyPool
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        checkReserveExists(reserveId)
    {
        require(amount > 0, Errors.DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO);
        reserves[reserveId].deposit(_msgSender(), amount, onBehalfOf);
        emit Deposit(reserveId, onBehalfOf, amount, referralCode);
    }

    /// @inheritdoc IOpenSkyPool
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        checkReserveExists(reserveId)
    {
        address oTokenAddress = reserves[reserveId].oTokenAddress;
        uint256 userBalance = IOpenSkyOToken(oTokenAddress).balanceOf(_msgSender());

        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        require(amountToWithdraw > 0 && amountToWithdraw <= userBalance, Errors.WITHDRAW_AMOUNT_NOT_ALLOWED);
        require(getAvailableLiquidity(reserveId) >= amountToWithdraw, Errors.WITHDRAW_LIQUIDITY_NOT_SUFFICIENT);

        reserves[reserveId].withdraw(_msgSender(), amountToWithdraw, onBehalfOf);
        emit Withdraw(reserveId, onBehalfOf, amountToWithdraw);
    }

    struct BorrowLocalParams {
        uint256 borrowLimit;
        uint256 availableLiquidity;
        uint256 amountToBorrow;
        uint256 borrowRate;
        address loanAddress;
    }

    /// @inheritdoc IOpenSkyPool
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external virtual override whenNotPaused nonReentrant checkReserveExists(reserveId) returns (uint256) {
        _validateWhitelist(reserveId, nftAddress, duration);

        BorrowLocalParams memory vars;
        vars.borrowLimit = getBorrowLimitByOracle(reserveId, nftAddress, tokenId);
        vars.availableLiquidity = getAvailableLiquidity(reserveId);

        vars.amountToBorrow = amount;

        if (amount == type(uint256).max) {
            vars.amountToBorrow = (
                vars.borrowLimit < vars.availableLiquidity ? vars.borrowLimit : vars.availableLiquidity
            );
        }

        require(vars.borrowLimit >= vars.amountToBorrow, Errors.BORROW_AMOUNT_EXCEED_BORROW_LIMIT);
        require(vars.availableLiquidity >= vars.amountToBorrow, Errors.RESERVE_LIQUIDITY_INSUFFICIENT);

        vars.loanAddress = SETTINGS.loanAddress();
        IERC721(nftAddress).safeTransferFrom(_msgSender(), vars.loanAddress, tokenId);

        vars.borrowRate = reserves[reserveId].getBorrowRate(0, 0, vars.amountToBorrow, 0);
        (uint256 loanId, DataTypes.LoanData memory loan) = IOpenSkyLoan(vars.loanAddress).mint(
            reserveId,
            onBehalfOf,
            nftAddress,
            tokenId,
            vars.amountToBorrow,
            duration,
            vars.borrowRate
        );
        reserves[reserveId].borrow(loan);

        emit Borrow(
            reserveId,
            _msgSender(),
            onBehalfOf,
            loanId
        );

        return loanId;
    }

    /// @inheritdoc IOpenSkyPool
    function repay(uint256 loanId) external virtual override whenNotPaused nonReentrant returns (uint256 repayAmount) {
        address loanAddress = SETTINGS.loanAddress();
        address onBehalfOf = IERC721(loanAddress).ownerOf(loanId);

        IOpenSkyLoan loanNFT = IOpenSkyLoan(loanAddress);
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);

        require(
            loanData.status == DataTypes.LoanStatus.BORROWING ||
                loanData.status == DataTypes.LoanStatus.EXTENDABLE ||
                loanData.status == DataTypes.LoanStatus.OVERDUE,
            Errors.REPAY_STATUS_ERROR
        );

        uint256 penalty = loanNFT.getPenalty(loanId);
        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);
        repayAmount = borrowBalance + penalty;

        uint256 reserveId = loanData.reserveId;
        require(_exists(reserveId), Errors.RESERVE_DOES_NOT_EXIST);

        reserves[reserveId].repay(loanData, repayAmount, borrowBalance);

        loanNFT.end(loanId, onBehalfOf, _msgSender());

        address nftReceiver = SETTINGS.punkGatewayAddress() == _msgSender() ? _msgSender() : onBehalfOf;
        IERC721(loanData.nftAddress).safeTransferFrom(address(loanNFT), nftReceiver, loanData.tokenId);

        emit Repay(reserveId, _msgSender(), nftReceiver, loanId, repayAmount, penalty);
    }

    struct ExtendLocalParams {
        uint256 borrowInterestOfOldLoan;
        uint256 needInAmount;
        uint256 needOutAmount;
        uint256 penalty;
        uint256 fee;
        uint256 borrowLimit;
        uint256 availableLiquidity;
        uint256 amountToExtend;
        uint256 newBorrowRate;
        DataTypes.LoanData oldLoan;
    }

    /// @inheritdoc IOpenSkyPool
    function extend(
        uint256 oldLoanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external override whenNotPaused nonReentrant returns (uint256, uint256) {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        if (_msgSender() == SETTINGS.wethGatewayAddress()) {
            require(loanNFT.ownerOf(oldLoanId) == onBehalfOf, Errors.LOAN_CALLER_IS_NOT_OWNER);
        } else {
            require(loanNFT.ownerOf(oldLoanId) == _msgSender(), Errors.LOAN_CALLER_IS_NOT_OWNER);
            onBehalfOf = _msgSender();
        }

        ExtendLocalParams memory vars;
        vars.oldLoan = loanNFT.getLoanData(oldLoanId);

        require(
            vars.oldLoan.status == DataTypes.LoanStatus.EXTENDABLE || vars.oldLoan.status == DataTypes.LoanStatus.OVERDUE,
            Errors.EXTEND_STATUS_ERROR
        );

        _validateWhitelist(vars.oldLoan.reserveId, vars.oldLoan.nftAddress, duration);

        vars.borrowLimit = getBorrowLimitByOracle(vars.oldLoan.reserveId, vars.oldLoan.nftAddress, vars.oldLoan.tokenId);

        vars.amountToExtend = amount;
        if (amount == type(uint256).max) {
            vars.amountToExtend = vars.borrowLimit; // no need to check availableLiquidity here
        }

        require(vars.borrowLimit >= vars.amountToExtend, Errors.BORROW_AMOUNT_EXCEED_BORROW_LIMIT);

        // calculate needInAmount and needOutAmount 
        vars.borrowInterestOfOldLoan = loanNFT.getBorrowInterest(oldLoanId);
        vars.penalty = loanNFT.getPenalty(oldLoanId);
        vars.fee = vars.borrowInterestOfOldLoan + vars.penalty;
        if (vars.oldLoan.amount <= vars.amountToExtend) {
            uint256 extendAmount = vars.amountToExtend - vars.oldLoan.amount;
            if (extendAmount < vars.fee) {
                vars.needInAmount = vars.fee - extendAmount;
            } else {
                vars.needOutAmount = extendAmount - vars.fee;
            }
        } else {
            vars.needInAmount = vars.oldLoan.amount - vars.amountToExtend + vars.fee;
        }

        // check availableLiquidity
        if (vars.needOutAmount > 0) {
            vars.availableLiquidity = getAvailableLiquidity(vars.oldLoan.reserveId);
            require(vars.availableLiquidity >= vars.needOutAmount, Errors.RESERVE_LIQUIDITY_INSUFFICIENT);
        }

        // end old loan
        loanNFT.end(oldLoanId, onBehalfOf, onBehalfOf);

        vars.newBorrowRate = reserves[vars.oldLoan.reserveId].getBorrowRate(
            vars.penalty,
            0,
            vars.amountToExtend,
            vars.oldLoan.amount + vars.borrowInterestOfOldLoan
        );

        // create new loan
        (uint256 loanId, DataTypes.LoanData memory newLoan) = loanNFT.mint(
            vars.oldLoan.reserveId,
            onBehalfOf,
            vars.oldLoan.nftAddress,
            vars.oldLoan.tokenId,
            vars.amountToExtend,
            duration,
            vars.newBorrowRate
        );

        // update reserve state
        reserves[vars.oldLoan.reserveId].extend(
            vars.oldLoan,
            newLoan,
            vars.borrowInterestOfOldLoan,
            vars.needInAmount,
            vars.needOutAmount,
            vars.penalty
        );

        emit Extend(vars.oldLoan.reserveId, onBehalfOf, oldLoanId, loanId);

        return (vars.needInAmount, vars.needOutAmount);
    }

    function _validateWhitelist(uint256 reserveId, address nftAddress, uint256 duration) internal view {
        require(SETTINGS.inWhitelist(reserveId, nftAddress), Errors.NFT_ADDRESS_IS_NOT_IN_WHITELIST);

        DataTypes.WhitelistInfo memory whitelistInfo = SETTINGS.getWhitelistDetail(reserveId, nftAddress);
        require(
            duration >= whitelistInfo.minBorrowDuration && duration <= whitelistInfo.maxBorrowDuration,
            Errors.BORROW_DURATION_NOT_ALLOWED
        );
    }

    /// @inheritdoc IOpenSkyPool
    function startLiquidation(uint256 loanId) external override whenNotPaused onlyLiquidator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);
        require(loanData.status == DataTypes.LoanStatus.LIQUIDATABLE, Errors.START_LIQUIDATION_STATUS_ERROR);

        reserves[loanData.reserveId].startLiquidation(loanData);

        IERC721(loanData.nftAddress).safeTransferFrom(address(loanNFT), _msgSender(), loanData.tokenId);
        loanNFT.startLiquidation(loanId);

        emit StartLiquidation(loanData.reserveId, loanId, loanData.nftAddress, loanData.tokenId, _msgSender());
    }

    /// @inheritdoc IOpenSkyPool
    function endLiquidation(uint256 loanId, uint256 amount) external override whenNotPaused onlyLiquidator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);
        require(loanData.status == DataTypes.LoanStatus.LIQUIDATING, Errors.END_LIQUIDATION_STATUS_ERROR);

        // repay money
        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);

        require(amount >= borrowBalance, Errors.END_LIQUIDATION_AMOUNT_ERROR);
        reserves[loanData.reserveId].endLiquidation(amount, borrowBalance);

        loanNFT.endLiquidation(loanId);

        emit EndLiquidation(
            loanData.reserveId,
            loanId,
            loanData.nftAddress,
            loanData.tokenId,
            _msgSender(),
            amount,
            borrowBalance
        );
    }

    /// @inheritdoc IOpenSkyPool
    function getReserveData(uint256 reserveId)
        external
        view
        override
        checkReserveExists(reserveId)
        returns (DataTypes.ReserveData memory)
    {
        return reserves[reserveId];
    }

    /// @inheritdoc IOpenSkyPool
    function getReserveNormalizedIncome(uint256 reserveId)
        external
        view
        virtual
        override
        checkReserveExists(reserveId)
        returns (uint256)
    {
        return reserves[reserveId].getNormalizedIncome();
    }

    /// @inheritdoc IOpenSkyPool
    function getAvailableLiquidity(uint256 reserveId)
        public
        view
        override
        checkReserveExists(reserveId)
        returns (uint256)
    {
        return reserves[reserveId].getMoneyMarketBalance();
    }

    /// @inheritdoc IOpenSkyPool
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) public view virtual override returns (uint256) {
        return
            IOpenSkyCollateralPriceOracle(SETTINGS.nftPriceOracleAddress())
                .getPrice(reserveId, nftAddress, tokenId)
                .percentMul(SETTINGS.getWhitelistDetail(reserveId, nftAddress).LTV);
    }
    
    /// @inheritdoc IOpenSkyPool
    function getTotalBorrowBalance(uint256 reserveId) external view override returns (uint256) {
        return reserves[reserveId].getTotalBorrowBalance();
    }

    /// @inheritdoc IOpenSkyPool
    function getTVL(uint256 reserveId) external view override checkReserveExists(reserveId) returns (uint256) {
        return reserves[reserveId].getTVL();
    }

    receive() external payable {
        revert(Errors.RECEIVE_NOT_ALLOWED);
    }

    fallback() external payable {
        revert(Errors.FALLBACK_NOT_ALLOWED);
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IOpenSkyPriceOracle
 * @author OpenSky Labs
 * @notice Defines the basic interface for a price oracle.
 **/
interface IOpenSkyCollateralPriceOracle {
    /**
     * @dev Emitted on setPriceAggregator()
     * @param operator The address of the operator
     * @param priceAggregator The new price aggregator address
     **/
    event SetPriceAggregator(address indexed operator, address priceAggregator);

    /**
     * @dev Emitted on setRoundInterval()
     * @param operator The address of the operator
     * @param roundInterval The round interval
     **/
    event SetRoundInterval(address indexed operator, uint256 roundInterval);

    /**
     * @dev Emitted on setTimeInterval()
     * @param operator The address of the operator
     * @param timeInterval The time interval
     **/
    event SetTimeInterval(address indexed operator, uint256 timeInterval);

    /**
     * @dev Emitted on updatePrice()
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     * @param roundId The round id
     **/
    event UpdatePrice(address indexed nftAddress, uint256 price, uint256 timestamp, uint256 roundId);

    /**
     * @notice Sets round interval that is used for calculating TWAP price
     * @param roundInterval The round interval will be set
     **/
    function setRoundInterval(uint256 roundInterval) external;

    /**
     * @notice Sets time interval that is used for calculating TWAP price
     * @param timeInterval The time interval will be set
     **/
    function setTimeInterval(uint256 timeInterval) external;

    /**
     * @notice Returns the NFT price in ETH
     * @param reserveId The id of the reserve
     * @param nftAddress The address of the NFT
     * @param tokenId The id of the NFT
     * @return The price of the NFT
     **/
    function getPrice(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice Updates the floor price of the NFT collection
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     **/
    function updatePrice(
        address nftAddress,
        uint256 price,
        uint256 timestamp
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyReserveVaultFactory {
    event Create(uint256 indexed reserveId, string name, string symbol, uint8 decimals, address indexed underlyingAsset);

    function create(
        uint256 reserveId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address underlyingAsset
    ) external returns (address oTokenAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyNFTDescriptor {
    function tokenURI(uint256 reserveId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyLoan
 * @author OpenSky Labs
 * @notice Defines the basic interface for OpenSkyLoan.  This loan NFT is composable and can be used in other DeFi protocols 
 **/
interface IOpenSkyLoan is IERC721 {

    /**
     * @dev Emitted on mint()
     * @param tokenId The ID of the loan
     * @param recipient The address that will receive the loan NFT
     **/
    event Mint(uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted on end()
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the user initiating the repayment()
     **/
    event End(uint256 indexed tokenId, address indexed onBehalfOf, address indexed repayer);

    /**
     * @dev Emitted on startLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event StartLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on endLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event EndLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on updateStatus()
     * @param tokenId The ID of the loan
     * @param status The status of loan
     **/
    event UpdateStatus(uint256 indexed tokenId, DataTypes.LoanStatus indexed status);

    /**
     * @dev Emitted on flashClaim()
     * @param receiver The address of the flash loan receiver contract
     * @param sender The address that will receive tokens
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of collateralized NFT
     **/
    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @dev Emitted on claimERC20Airdrop()
     * @param token The address of the ERC20 token
     * @param to The address that will receive the ERC20 tokens
     * @param amount The amount of the tokens
     **/
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted on claimERC721Airdrop()
     * @param token The address of ERC721 token
     * @param to The address that will receive the eRC721 tokens
     * @param ids The ID of the token
     **/
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

    /**
     * @dev Emitted on claimERC1155Airdrop()
     * @param token The address of the ERC1155 token
     * @param to The address that will receive the ERC1155 tokens
     * @param ids The ID of the token
     * @param amounts The amount of the tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    /**
     * @notice Mints a loan NFT to user
     * @param reserveId The ID of the reserve
     * @param borrower The address of the borrower
     * @param nftAddress The contract address of the collateralized NFT 
     * @param nftTokenId The ID of the collateralized NFT
     * @param amount The amount of the loan
     * @param duration The duration of the loan
     * @param borrowRate The borrow rate of the loan
     * @return loanId and loan data
     **/
    function mint(
        uint256 reserveId,
        address borrower,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint256 duration,
        uint256 borrowRate
    ) external returns (uint256 loanId, DataTypes.LoanData memory loan);

    /**
     * @notice Starts liquidation of the loan in default
     * @param tokenId The ID of the defaulted loan
     **/
    function startLiquidation(uint256 tokenId) external;

    /**
     * @notice Ends liquidation of a loan that is fully settled
     * @param tokenId The ID of the loan
     **/
    function endLiquidation(uint256 tokenId) external;

    /**
     * @notice Terminates the loan
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the repayer
     **/
    function end(uint256 tokenId, address onBehalfOf, address repayer) external;
    
    /**
     * @notice Returns the loan data
     * @param tokenId The ID of the loan
     * @return The details of the loan
     **/
    function getLoanData(uint256 tokenId) external view returns (DataTypes.LoanData calldata);

    /**
     * @notice Returns the status of a loan
     * @param tokenId The ID of the loan
     * @return The status of the loan
     **/
    function getStatus(uint256 tokenId) external view returns (DataTypes.LoanStatus);

    /**
     * @notice Returns the borrow interest of the loan
     * @param tokenId The ID of the loan
     * @return The borrow interest of the loan
     **/
    function getBorrowInterest(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the borrow balance of a loan, including borrow interest
     * @param tokenId The ID of the loan
     * @return The borrow balance of the loan
     **/
    function getBorrowBalance(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the penalty fee of the loan
     * @param tokenId The ID of the loan
     * @return The penalty fee of the loan
     **/
    function getPenalty(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the ID of the loan
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of the collateralized NFT
     * @return The ID of the loan
     **/
    function getLoanId(address nftAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IOpenSkyFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyPool
 * @author OpenSky Labs
 * @notice Defines the basic interface for an OpenSky Pool.
 **/

interface IOpenSkyPool {
    /*
     * @dev Emitted on create()
     * @param reserveId The ID of the reserve
     * @param underlyingAsset The address of the underlying asset
     * @param oTokenAddress The address of the oToken
     * @param name The name to use for oToken
     * @param symbol The symbol to use for oToken
     * @param decimals The decimals of the oToken
     */
    event Create(
        uint256 indexed reserveId,
        address indexed underlyingAsset,
        address indexed oTokenAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    /*
     * @dev Emitted on setTreasuryFactor()
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     */
    event SetTreasuryFactor(uint256 indexed reserveId, uint256 factor);

    /*
     * @dev Emitted on setInterestModelAddress()
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The address of the interest model contract
     */
    event SetInterestModelAddress(uint256 indexed reserveId, address interestModelAddress);

    /*
     * @dev Emitted on openMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event OpenMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on closeMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event CloseMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on deposit()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive the oTokens
     * @param amount The amount of ETH to be deposited
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     * 0 if the action is executed directly by the user, without any intermediaries
     */
    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount, uint256 referralCode);

    /*
     * @dev Emitted on withdraw()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive assets withdrawed
     * @param amount The amount to be withdrawn
     */
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);

    /*
     * @dev Emitted on borrow()
     * @param reserveId The ID of the reserve
     * @param user The address initiating the withdrawal(), owner of oTokens
     * @param onBehalfOf The address that will receive the ETH and the loan NFT
     * @param loanId The loan ID
     */
    event Borrow(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 indexed loanId
    );

    /*
     * @dev Emitted on repay()
     * @param reserveId The ID of the reserve
     * @param repayer The address initiating the repayment()
     * @param onBehalfOf The address that will receive the pledged NFT
     * @param loanId The ID of the loan
     * @param repayAmount The borrow balance of the loan when it was repaid
     * @param penalty The penalty of the loan for either early or overdue repayment
     */
    event Repay(
        uint256 indexed reserveId,
        address repayer,
        address indexed onBehalfOf,
        uint256 indexed loanId,
        uint256 repayAmount,
        uint256 penalty
    );

    /*
     * @dev Emitted on extend()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The owner address of loan NFT
     * @param oldLoanId The ID of the old loan
     * @param newLoanId The ID of the new loan
     */
    event Extend(uint256 indexed reserveId, address indexed onBehalfOf, uint256 oldLoanId, uint256 newLoanId);

    /*
     * @dev Emitted on startLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator The address initiating startLiquidation()
     */
    event StartLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator
    );

    /*
     * @dev Emitted on endLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator
     * @param repayAmount The amount used to repay, must be equal to or greater than the borrowBalance, excess part will be shared by all the lenders
     * @param borrowBalance The borrow balance of the loan
     */
    event EndLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator,
        uint256 repayAmount,
        uint256 borrowBalance
    );

    /**
     * @notice Creates a reserve
     * @dev Only callable by the pool admin role
     * @param underlyingAsset The address of the underlying asset
     * @param name The name of the oToken
     * @param symbol The symbol for the oToken
     * @param decimals The decimals of the oToken
     **/
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Updates the treasury factor of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     **/
    function setTreasuryFactor(uint256 reserveId, uint256 factor) external;

    /**
     * @notice Updates the interest model address of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The new address of the interest model contract
     **/
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress) external;

    /**
     * @notice Open the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function openMoneyMarket(uint256 reserveId) external;

    /**
     * @notice Close the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function closeMoneyMarket(uint256 reserveId) external;

    /**
     * @dev Deposits ETH into the reserve.
     * @param reserveId The ID of the reserve
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     **/
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode) external;

    /**
     * @dev withdraws the ETH from reserve.
     * @param reserveId The ID of the reserve
     * @param amount amount of oETH to withdraw and receive native ETH
     **/
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     **/
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Repays a loan, as a result the corresponding loan NFT owner will receive the collateralized NFT.
     * @param loanId The ID of the loan the user will repay
     */
    function repay(uint256 loanId) external returns (uint256);

    /**
     * @dev Extends creates a new loan and terminates the old loan.
     * @param loanId The loan ID to extend
     * @param amount The amount of ERC20 token the user will borrow in the new loan
     * @param duration The selected duration the user will borrow in the new loan
     * @param onBehalfOf The address will borrow in the new loan
     **/
    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external returns (uint256, uint256);

    /**
     * @dev Starts liquidation for a loan when it's in LIQUIDATABLE status
     * @param loanId The ID of the loan which will be liquidated
     */
    function startLiquidation(uint256 loanId) external;

    /**
     * @dev Completes liquidation for a loan which will be repaid.
     * @param loanId The ID of the liquidated loan that will be repaid.
     * @param amount The amount of the token that will be repaid.
     */
    function endLiquidation(uint256 loanId, uint256 amount) external;

    /**
     * @dev Returns the state of the reserve
     * @param reserveId The ID of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the normalized income of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the remaining liquidity of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's withdrawable balance
     */
    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the instantaneous borrow limit value of a special NFT
     * @param nftAddress The address of the NFT
     * @param tokenId The ID of the NFT
     * @return The NFT's borrow limit
     */
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the sum of all users borrow balances include borrow interest accrued
     * @param reserveId The ID of the reserve
     * @return The total borrow balance of the reserve
     */
    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns TVL (total value locked) of the reserve.
     * @param reserveId The ID of the reserve
     * @return The reserve's TVL
     */
    function getTVL(uint256 reserveId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IACLManager {
    function addEmergencyAdmin(address admin) external;
    
    function isEmergencyAdmin(address admin) external view returns (bool);
    
    function removeEmergencyAdmin(address admin) external;
    
    function addGovernance(address admin) external;
    
    function isGovernance(address admin) external view returns (bool);

    function removeGovernance(address admin) external;

    function addPoolAdmin(address admin) external;

    function isPoolAdmin(address admin) external view returns (bool);

    function removePoolAdmin(address admin) external;

    function addLiquidationOperator(address address_) external;

    function isLiquidationOperator(address address_) external view returns (bool);

    function removeLiquidationOperator(address address_) external;

    function addAirdropOperator(address address_) external;

    function isAirdropOperator(address address_) external view returns (bool);

    function removeAirdropOperator(address address_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) external view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return (rate * timeDifference) / SECONDS_PER_YEAR + WadRayMath.ray();
    }

    function calculateBorrowInterest(
        uint256 borrowRate,
        uint256 amount,
        uint256 duration
    ) external pure returns (uint256) {
        return amount.rayMul(borrowRate.rayMul(duration).rayDiv(SECONDS_PER_YEAR));
    }

    function calculateBorrowInterestPerSecond(uint256 borrowRate, uint256 amount) external pure returns (uint256) {
        return amount.rayMul(borrowRate).rayDiv(SECONDS_PER_YEAR);
    }

    function calculateLoanSupplyRate(
        uint256 availableLiquidity,
        uint256 totalBorrows,
        uint256 borrowRate
    ) external pure returns (uint256 loanSupplyRate, uint256 utilizationRate) {
        utilizationRate = (totalBorrows == 0 && availableLiquidity == 0)
            ? 0
            : totalBorrows.rayDiv(availableLiquidity + totalBorrows);
        loanSupplyRate = utilizationRate.rayMul(borrowRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './types/DataTypes.sol';
import './helpers/Errors.sol';
import './math/WadRayMath.sol';
import './math/PercentageMath.sol';

import '../interfaces/IOpenSkyInterestRateStrategy.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';

/**
 * @title ReserveLogic library
 * @author OpenSky Labs
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Implements the deposit feature.
     * @param sender The address that called deposit function
     * @param amount The amount of deposit
     * @param onBehalfOf The address that will receive otokens
     **/
    function deposit(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.mint(onBehalfOf, amount, reserve.lastSupplyIndex);

        IERC20(reserve.underlyingAsset).safeTransferFrom(sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);
    }

    /**
     * @dev Implements the withdrawal feature.
     * @param sender The address that called withdraw function
     * @param amount The withdrawal amount
     * @param onBehalfOf The address that will receive token
     **/
    function withdraw(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, 0, amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.burn(sender, amount, reserve.lastSupplyIndex);
        oToken.withdraw(amount, onBehalfOf);
    }

    /**
     * @dev Implements the borrow feature.
     * @param loan the loan data
     **/
    function borrow(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateInterestPerSecond(reserve, loan.interestPerSecond, 0);
        updateLastMoneyMarketBalance(reserve, 0, loan.amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.withdraw(loan.amount, msg.sender);

        reserve.totalBorrows = reserve.totalBorrows + loan.amount;
    }

    /**
     * @dev Implements the repay function.
     * @param loan The loan data
     * @param amount The amount that will be repaid, including penalty
     * @param borrowBalance The borrow balance
     **/
    function repay(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory loan,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Implements the extend feature.
     * @param oldLoan The data of old loan
     * @param newLoan The data of new loan
     * @param borrowInterestOfOldLoan The borrow interest of old loan
     * @param inAmount The amount of token that will be deposited
     * @param outAmount The amount of token that will be withdrawn
     * @param additionalIncome The additional income
     **/
    function extend(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory oldLoan,
        DataTypes.LoanData memory newLoan,
        uint256 borrowInterestOfOldLoan,
        uint256 inAmount,
        uint256 outAmount,
        uint256 additionalIncome
    ) external {
        updateState(reserve, additionalIncome);
        updateInterestPerSecond(reserve, newLoan.interestPerSecond, oldLoan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, inAmount, outAmount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        if (inAmount > 0) {
            IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, inAmount);
            oToken.deposit(inAmount);
        }
        if (outAmount > 0) oToken.withdraw(outAmount, msg.sender);

        uint256 sum1 = reserve.totalBorrows + newLoan.amount;
        uint256 sum2 = oldLoan.amount + borrowInterestOfOldLoan;
        reserve.totalBorrows = sum1 > sum2 ? sum1 - sum2 : 0;
    }

    /**
     * @dev Implements start liquidation mechanism.
     * @param loan Loan data
     **/
    function startLiquidation(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateLastMoneyMarketBalance(reserve, 0, 0);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
    }

    /**
     * @dev Implements end liquidation mechanism.
     * @param amount The amount of token paid
     * @param borrowBalance The borrow balance of loan
     **/
    function endLiquidation(
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Updates the liquidity cumulative index and total borrows
     * @param reserve The reserve object
     * @param additionalIncome The additional income
     **/
    function updateState(DataTypes.ReserveData storage reserve, uint256 additionalIncome) internal {
        (
            uint256 newIndex,
            ,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,

        ) = calculateIncome(reserve, additionalIncome);

        require(newIndex <= type(uint128).max, Errors.RESERVE_INDEX_OVERFLOW);
        reserve.lastSupplyIndex = uint128(newIndex);

        // treasury
        treasuryIncome = treasuryIncome / WadRayMath.ray();
        if (treasuryIncome > 0) {
            IOpenSkyOToken(reserve.oTokenAddress).mintToTreasury(treasuryIncome, reserve.lastSupplyIndex);
        }

        reserve.totalBorrows = reserve.totalBorrows + borrowingInterestDelta / WadRayMath.ray();
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @dev Updates the interest per second, when borrowing and repaying
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateInterestPerSecond(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        reserve.borrowingInterestPerSecond = reserve.borrowingInterestPerSecond + amountToAdd - amountToRemove;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateLastMoneyMarketBalance(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        uint256 moneyMarketBalance = getMoneyMarketBalance(reserve);
        reserve.lastMoneyMarketBalance = moneyMarketBalance + amountToAdd - amountToRemove;
    }

    function openMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        reserve.isMoneyMarketOn = true;

        uint256 amount = IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        IOpenSkyOToken(reserve.oTokenAddress).deposit(amount);
    }

    function closeMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        address oTokenAddress = reserve.oTokenAddress;
        uint256 amount = IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, oTokenAddress);
        IOpenSkyOToken(oTokenAddress).withdraw(amount, oTokenAddress);

        reserve.isMoneyMarketOn = false;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param additionalIncome The amount to be added
     * @return newIndex The new liquidity cumulative index from the last update
     * @return usersIncome The user's income from the last update
     * @return treasuryIncome The treasury income from the last update
     * @return borrowingInterestDelta The treasury income from the last update
     * @return moneyMarketDelta The money market income from the last update
     **/
    function calculateIncome(DataTypes.ReserveData memory reserve, uint256 additionalIncome)
        internal
        view
        returns (
            uint256 newIndex,
            uint256 usersIncome,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,
            uint256 moneyMarketDelta
        )
    {
        moneyMarketDelta = getMoneyMarketDelta(reserve) * WadRayMath.ray();
        borrowingInterestDelta = getBorrowingInterestDelta(reserve);
        // ray
        uint256 totalIncome = additionalIncome * WadRayMath.ray() + moneyMarketDelta + borrowingInterestDelta;
        treasuryIncome = totalIncome.percentMul(reserve.treasuryFactor);
        usersIncome = totalIncome - treasuryIncome;

        // index
        newIndex = reserve.lastSupplyIndex;
        uint256 scaledTotalSupply = IOpenSkyOToken(reserve.oTokenAddress).scaledTotalSupply();
        if (scaledTotalSupply > 0) {
            newIndex = usersIncome / scaledTotalSupply + reserve.lastSupplyIndex;
        }

        return (newIndex, usersIncome, treasuryIncome, borrowingInterestDelta, moneyMarketDelta);
    }

    /**
     * @dev Returns the ongoing normalized income for the reserve
     * A value of 1e27 means there is no income. As time passes, the income is accrued
     * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income. expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve) external view returns (uint256) {
        (uint256 newIndex, , , , ) = calculateIncome(reserve, 0);
        return newIndex;
    }

    /**
     * @dev Returns the available liquidity of the reserve
     * @param reserve The reserve object
     * @return The available liquidity
     **/
    function getMoneyMarketBalance(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        if (reserve.isMoneyMarketOn) {
            return IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, reserve.oTokenAddress);
        } else {
            return IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        }
    }

    /**
     * @dev Returns the money market income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from money market
     **/
    function getMoneyMarketDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp - reserve.lastUpdateTimestamp;

        if (timeDelta == 0) return 0;

        if (reserve.lastMoneyMarketBalance == 0) return 0;

        // get MoneyMarketBalance
        uint256 currentMoneyMarketBalance = getMoneyMarketBalance(reserve);
        if (currentMoneyMarketBalance < reserve.lastMoneyMarketBalance) return 0;

        return currentMoneyMarketBalance - reserve.lastMoneyMarketBalance;
    }

    /**
     * @dev Returns the borrow interest income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from the NFT loan
     **/
    function getBorrowingInterestDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = uint256(block.timestamp) - reserve.lastUpdateTimestamp;
        if (timeDelta == 0) return 0;
        return reserve.borrowingInterestPerSecond * timeDelta;
    }

    /**
     * @dev Returns the total borrow balance of the reserve
     * @param reserve The reserve object
     * @return The total borrow balance
     **/
    function getTotalBorrowBalance(DataTypes.ReserveData memory reserve) public view returns (uint256) {
        return reserve.totalBorrows + getBorrowingInterestDelta(reserve) / WadRayMath.ray();
    }

    /**
     * @dev Returns the total value locked (TVL) of the reserve
     * @param reserve The reserve object
     * @return The total value locked (TVL)
     **/
    function getTVL(DataTypes.ReserveData memory reserve) external view returns (uint256) {
        (, , uint256 treasuryIncome, , ) = calculateIncome(reserve, 0);
        return treasuryIncome / WadRayMath.RAY + IOpenSkyOToken(reserve.oTokenAddress).totalSupply();
    }

    /**
     * @dev Returns the borrow rate of the reserve
     * @param reserve The reserve object
     * @param liquidityAmountToAdd The liquidity amount will be added
     * @param liquidityAmountToRemove The liquidity amount will be removed
     * @param borrowAmountToAdd The borrow amount will be added
     * @param borrowAmountToRemove The borrow amount will be removed
     * @return The borrow rate
     **/
    function getBorrowRate(
        DataTypes.ReserveData memory reserve,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) external view returns (uint256) {
        uint256 liquidity = getMoneyMarketBalance(reserve);
        uint256 totalBorrowBalance = getTotalBorrowBalance(reserve);
        return
            IOpenSkyInterestRateStrategy(reserve.interestModelAddress).getBorrowRate(
                reserve.reserveId,
                liquidity + totalBorrowBalance + liquidityAmountToAdd - liquidityAmountToRemove,
                totalBorrowBalance + borrowAmountToAdd - borrowAmountToRemove
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Multiplies two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMulTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (a * b) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Divides two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDivTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        return (a * RAY) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
        return result;
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
pragma solidity 0.8.10;

/**
 * @title IOpenSkyInterestRateStrategy
 * @author OpenSky Labs
 * @notice Interface for the calculation of the interest rates
 */
interface IOpenSkyInterestRateStrategy {
    /**
     * @dev Emitted on setBaseBorrowRate()
     * @param reserveId The id of the reserve
     * @param baseRate The base rate has been set
     **/
    event SetBaseBorrowRate(
        uint256 indexed reserveId,
        uint256 indexed baseRate
    );

    /**
     * @notice Returns the borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @param totalDeposits The total deposits amount of the reserve
     * @param totalBorrows The total borrows amount of the reserve
     * @return The borrow rate, expressed in ray
     **/
    function getBorrowRate(uint256 reserveId, uint256 totalDeposits, uint256 totalBorrows) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenSkyOToken is IERC20 {
    event Mint(address indexed account, uint256 amount, uint256 index);
    event Burn(address indexed account, uint256 amount, uint256 index);
    event MintToTreasury(address treasury, uint256 amount, uint256 index);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    function mint(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function burn(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function mintToTreasury(uint256 amount, uint256 index) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function scaledBalanceOf(address account) external view returns (uint256);

    function principleBalanceOf(address account) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function principleTotalSupply() external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function claimERC20Rewards(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyMoneyMarket {

    function depositCall(address asset, uint256 amount) external;

    function withdrawCall(address asset, uint256 amount, address to) external;

    function getMoneyMarketToken(address asset) external view returns (address);

    function getBalance(address asset, address account) external view returns (uint256);

    function getSupplyRate(address asset) external view returns (uint256);

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