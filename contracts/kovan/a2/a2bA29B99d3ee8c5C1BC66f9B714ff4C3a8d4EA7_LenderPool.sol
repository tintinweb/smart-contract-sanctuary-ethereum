// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../Math.sol';
import '../interfaces/ISavingsAccount.sol';
import '../SavingsAccount/SavingsAccountUtil.sol';
import '../interfaces/IYield.sol';
import '../interfaces/ILenderPool.sol';
import '../interfaces/IVerification.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/IPooledCreditLine.sol';

/**
 * @title Contract that deals with pooling of capital from lenders
 * @notice Implements the functions related to lender pooling
 * @author Sublime
 **/

contract LenderPool is ERC1155Upgradeable, ReentrancyGuard, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //-------------------------------- Constants start --------------------------------//

    /**
     * @notice address of savings account
     */
    ISavingsAccount public immutable SAVINGS_ACCOUNT;
    /**
     * @notice address of pooled credit line
     */
    IPooledCreditLine public immutable POOLED_CREDIT_LINE;
    /**
     * @notice address of verification module
     */
    IVerification public immutable VERIFICATION;
    /**
     * @notice address of price oracle
     */
    IPriceOracle public immutable PRICE_ORACLE;
    // address of USDC contract
    address internal immutable USDC;
    // Factor with which certain variables/constants are multiplied to maintain precision
    uint256 constant SCALING_FACTOR = 1e18;

    //-------------------------------- Constants end --------------------------------//

    //-------------------------------- Global varibales start --------------------------------//

    /**
     * @notice fraction to total lent amount given as fee when start is invoked
     */
    uint256 public startFeeFraction;
    /**
     * @notice max fee to call start function in usdc
     */
    uint256 public maxStartFee;

    //-------------------------------- Global varibales end --------------------------------//

    //-------------------------------- State variables start --------------------------------//

    enum PooledCreditLineStatus {
        NOT_CREATED,
        REQUESTED,
        ACTIVE,
        CLOSED,
        EXPIRED,
        LIQUIDATED,
        CANCELLED
    }

    /**
     * @notice Struct that stores the info related to a lender of a specific credit line
     * @param borrowerInterestSharesWithdrawn interest paid by borroower in shares, withdrawn by lender
     * @param yieldInterestWithdrawnShares interest from yield withdrawn by lender
     */
    struct LenderInfo {
        uint256 borrowerInterestSharesWithdrawn;
        uint256 yieldInterestWithdrawnShares;
    }

    /**
     * @notice Struct that stores the constants of a pooled credit line
     * @param startTime Timestamp at which pooled credit line starts
     * @param borrowAsset address of token that is being lent by lenders & borrowed by borrower
     * @param collateralAsset address of token that is used as collateral for credit line
     * @param borrowLimit max tokens that was reqeuested by borrower
     * @param minBorrowAmount min tokens that was reqeuested by borrower
     * @param verifier address of verifier with which lenders should be verified to lend
     * @param borrowAssetStrategy address of strategy to deposit lent tokens to in savings account
     * @param areTokensTransferable boolean that represents if pool tokens for pooled credit line are transferable
     */
    struct LenderPoolConstants {
        uint256 startTime;
        address borrowAsset;
        address collateralAsset;
        uint256 borrowLimit;
        uint256 minBorrowAmount;
        address verifier;
        address borrowAssetStrategy;
        bool areTokensTransferable;
    }

    /**
     * @notice Struct that stores the variables of a pooled credit line
     * @param lenders mapping that stores lender specific info for the pooled credit line
     * @param sharesHeld total shares of borrow token held by the pooled credit line
     * @param borrowerInterestShares total interest in shares repaid by borrower
     * @param borrowerInterestSharesWithdrawn shares withdrawn from borrowerInterestShares
     * @param yieldInterestWithdrawnShares total yield interest in shares withdrawn by all lenders together
     * @param collateralHeld total collateral tokens held by pooled credit line in case of liquidation
     */
    struct LenderPoolVariables {
        mapping(address => LenderInfo) lenders;
        uint256 sharesHeld;
        uint256 borrowerInterestShares;
        uint256 borrowerInterestSharesWithdrawn;
        uint256 yieldInterestWithdrawnShares;
        uint256 collateralHeld;
    }

    /**
     * @notice Mapping that stores constants for pooledCredit creditLine against it's id
     */
    mapping(uint256 => LenderPoolConstants) public pooledCLConstants;
    /**
     * @notice Mapping that stores variables for pooledCredit creditLine against it's id
     */
    mapping(uint256 => LenderPoolVariables) public pooledCLVariables;
    /**
     * @notice Mapping that stores total pooledCreditLine token supply against the creditLineId
     * @dev Since ERC1155 tokens don't support the totalSupply function it is maintained here
     */
    mapping(uint256 => uint256) public totalSupply;

    //-------------------------------- State variables end --------------------------------//

    //-------------------------------- Modifiers start --------------------------------//

    /**
     * @notice Modifier that allows only pooled credit line to call a function
     */
    modifier onlyPooledCreditLine() {
        require(msg.sender == address(POOLED_CREDIT_LINE), 'OPCL1');
        _;
    }

    //-------------------------------- Modifiers end --------------------------------//

    //-------------------------------- Events start --------------------------------//

    //--------------------------- LenderPool events start ---------------------------//

    /**
     * @notice Emitted when lender deposits tokens for pooled credit line
     * @param id idenitifer for the pooled credit line
     * @param user address of the user
     * @param amount amount of tokens lent by user
     */
    event Lend(uint256 indexed id, address indexed user, uint256 amount);
    /**
     * @notice Emitted when liquidity provided by lender is withdrawn when pool is not cancelled
     * @param id idenitifer for the pooled credit line
     * @param user address of the lender
     * @param shares amount of shares of liquidity provided initially by lender withdrawn
     */
    event WithdrawLiquidity(uint256 indexed id, address indexed user, uint256 shares);
    /**
     * @notice Emitted when liqudity provided by lender is withdrawn as pool is cancelled
     * @param id idenitifer for the pooled credit line
     * @param user address of the lender
     * @param amount amount of tokens lent by the user which is withdrawn on pooled credit line cancellation
     */
    event WithdrawLiquidityOnCancel(uint256 indexed id, address indexed user, uint256 amount);
    /**
     * @notice Emitted when interest by yield or/and borrower is withdrawn
     * @param id idenitifer for the pooled credit line
     * @param user address of the lender
     * @param shares shares withdrawn by lender from interest accured by yield as well as supplied by borrower
     */
    event InterestWithdrawn(uint256 indexed id, address indexed user, uint256 shares);
    /**
     * @notice Emitted when a lender withdraws their share of liquidation
     * @param id idenitifer for the pooled credit line
     * @param user address of the lender
     * @param collateralShare share of collateral withdrawn by lender from liquidation
     */
    event LiquidationWithdrawn(uint256 indexed id, address indexed user, uint256 collateralShare);
    /**
     * @notice Emitted when a pooled credit line is liquidated by a lender
     * @param id idenitifer for the pooled credit line
     * @param collateralLiquidated amount of collateral that is received after liquidation
     */
    event Liquidated(uint256 indexed id, uint256 collateralLiquidated);

    //--------------------------- LenderPool events end ---------------------------//

    //--------------------------- Globa var update events start ---------------------------//

    /**
     * @notice Emitted when start fee fraction is updated
     * @param updatedStartFeeFraction updated value of start fee fraction
     */
    event StartFeeFractionUpdated(uint256 updatedStartFeeFraction);
    /**
     * @notice Emitted when  maxstart fee is updated
     * @param updatedMaxStartFee updated value of max start fee
     */
    event MaxStartFeeUpdated(uint256 updatedMaxStartFee);

    //--------------------------- Globa var update events end ---------------------------//

    //-------------------------------- Events end --------------------------------//

    //-------------------------------- Init start --------------------------------//

    /**
     * @notice constructor to initialize immutable global variables
     * @param _pooledCreditLine address of pooled credit line contract
     * @param _savingsAccount address of savings account contract
     * @param _verification address of verification contract
     * @param _priceOracle address of price oracle contract
     * @param _usdc address of USDC contract
     */
    constructor(
        address _pooledCreditLine,
        address _savingsAccount,
        address _verification,
        address _priceOracle,
        address _usdc
    ) {
        POOLED_CREDIT_LINE = IPooledCreditLine(_pooledCreditLine);
        SAVINGS_ACCOUNT = ISavingsAccount(_savingsAccount);
        VERIFICATION = IVerification(_verification);
        PRICE_ORACLE = IPriceOracle(_priceOracle);
        USDC = _usdc;
    }

    /**
     * @notice initializes the contract in context of proxy
     * @param _owner Owner of the lenderPool contract
     * @param _startFeeFraction fraction to total lent amount given as fee when start is invoked
     * @param _maxStartFee max fee to call start function in usdc
     */
    function initialize(
        address _owner,
        uint256 _startFeeFraction,
        uint256 _maxStartFee
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        OwnableUpgradeable.transferOwnership(_owner);
        __ERC1155_init('URI');

        _updateStartFeeFraction(_startFeeFraction);
        _updateMaxStartFee(_maxStartFee);
    }

    //-------------------------------- Init end --------------------------------//

    //-------------------------------- PCL creation start --------------------------------//

    /**
     * @notice function invoked when creating pooled credit line
     * @dev only pooled credit line can call the create function
     * @param _id identifier for the pooled credit line
     * @param _verifier address of verifier with which lenders should be verified to lend
     * @param _borrowAsset address of token that is being lent by lenders & borrowed by borrower
     * @param _borrowAssetStrategy address of strategy to deposit lent tokens to savings account
     * @param _borrowLimit max tokens that was reqeuested by borrower
     * @param _minBorrowAmount min tokens that was reqeuested by borrower
     * @param _collectionPeriod time for which tokens can be lent to pooled credit lines
     * @param _areTokensTransferable boolean that represents if pool tokens for credit line are transferable
     */
    function create(
        uint256 _id,
        address _verifier,
        address _borrowAsset,
        address _borrowAssetStrategy,
        uint256 _borrowLimit,
        uint256 _minBorrowAmount,
        uint256 _collectionPeriod,
        bool _areTokensTransferable
    ) external onlyPooledCreditLine nonReentrant {
        pooledCLConstants[_id].startTime = block.timestamp.add(_collectionPeriod);
        pooledCLConstants[_id].borrowAsset = _borrowAsset;
        pooledCLConstants[_id].borrowLimit = _borrowLimit;
        pooledCLConstants[_id].minBorrowAmount = _minBorrowAmount;
        pooledCLConstants[_id].verifier = _verifier;
        pooledCLConstants[_id].borrowAssetStrategy = _borrowAssetStrategy;
        pooledCLConstants[_id].areTokensTransferable = _areTokensTransferable;

        uint256 allowance = SAVINGS_ACCOUNT.allowance(address(this), _borrowAsset, address(POOLED_CREDIT_LINE));
        if (allowance != type(uint256).max) {
            SAVINGS_ACCOUNT.approve(_borrowAsset, address(POOLED_CREDIT_LINE), type(uint256).max);
        }
    }

    //-------------------------------- PCL creation end --------------------------------//

    //-------------------------------- Lend & accept start --------------------------------//

    /**
     * @notice Function used by lenders to lent to pooled credit line
     * @dev lent amount is deposited to savings account only once borrow limit is reached or if start is callled
     * @param _id identifier for the pooled credit line
     * @param _amount amount of borrow tokens to lend
     */
    function lend(uint256 _id, uint256 _amount) external nonReentrant {
        require(VERIFICATION.isUser(msg.sender, pooledCLConstants[_id].verifier), 'L1');
        require(block.timestamp < pooledCLConstants[_id].startTime, 'L2');

        uint256 _totalLent = totalSupply[_id];
        uint256 _maxLent = pooledCLConstants[_id].borrowLimit;
        require(_maxLent > _totalLent, 'L3');

        uint256 _amountToLend = _amount;
        if (_totalLent.add(_amount) > _maxLent) {
            _amountToLend = _maxLent.sub(_totalLent);
        }
        address _borrowAsset = pooledCLConstants[_id].borrowAsset;

        IERC20(_borrowAsset).safeTransferFrom(msg.sender, address(this), _amountToLend);
        _mint(msg.sender, _id, _amountToLend, '');

        emit Lend(_id, msg.sender, _amount);

        // If borrowLimit reached, accept CL
        if (_totalLent.add(_amountToLend) == _maxLent) {
            _accept(_id, _maxLent);
        }
    }

    /**
     * @notice function used to start the pooled credit line once the start time is reached
     * @dev In case borrow limit is reached, this function is not necessary
     * @param _id identifier for the pooled credit line
     * @param _to address to which start fee is sent
     */
    function start(uint256 _id, address _to) external nonReentrant {
        uint256 _startTime = pooledCLConstants[_id].startTime;
        require(_startTime != 0, 'S1');
        require(block.timestamp >= _startTime, 'S2');
        uint256 _totalLent = totalSupply[_id];

        address _borrowAsset = pooledCLConstants[_id].borrowAsset;
        uint256 _fee = _totalLent.mul(startFeeFraction).div(SCALING_FACTOR);
        uint256 _maxFee = _convertFromUSD(_borrowAsset, maxStartFee);
        _fee = Math.min(_fee, _maxFee);

        require(_totalLent.sub(_fee) >= pooledCLConstants[_id].minBorrowAmount, 'S3');

        IERC20(_borrowAsset).transfer(_to, _fee);

        _accept(_id, _totalLent.sub(_fee));
    }

    function _accept(uint256 _id, uint256 _amount) internal {
        address _borrowAsset = pooledCLConstants[_id].borrowAsset;
        address _strategy = pooledCLConstants[_id].borrowAssetStrategy;
        IERC20(_borrowAsset).safeApprove(_strategy, _amount);
        pooledCLVariables[_id].sharesHeld = SAVINGS_ACCOUNT.deposit(_borrowAsset, _strategy, address(this), _amount);

        POOLED_CREDIT_LINE.accept(_id, _amount);

        delete pooledCLConstants[_id].startTime;
        delete pooledCLConstants[_id].minBorrowAmount;
    }

    function _convertFromUSD(address _token, uint256 _usdAmount) internal view returns (uint256) {
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(PRICE_ORACLE).getLatestPrice(_token, USDC);
        uint256 _amount = _usdAmount.mul(10**_decimals).div(_ratioOfPrices);
        return _amount;
    }

    //-------------------------------- Lend & accept end --------------------------------//

    //-------------------------------- callbacks start --------------------------------//

    /**
     * @notice Function invoked on borrow from the pooled credit line
     * @dev only pooledCreditLineContract can invoke
     * @param _id identifier for the pooled credit line
     * @param _sharesBorrowed amount of shares borrowed
     */
    function borrowed(uint256 _id, uint256 _sharesBorrowed) external onlyPooledCreditLine nonReentrant {
        pooledCLVariables[_id].sharesHeld = pooledCLVariables[_id].sharesHeld.sub(_sharesBorrowed);
    }

    /**
     * @notice Function invoked when repayment is done to pooled credit line
     * @dev only pooledCreditLineContract can invoke
     * @param _id identifier for the pooled credit line
     * @param _sharesRepaid shares repaid
     * @param _interestShares interest in shares repaid
     */
    function repaid(
        uint256 _id,
        uint256 _sharesRepaid,
        uint256 _interestShares
    ) external onlyPooledCreditLine nonReentrant {
        pooledCLVariables[_id].sharesHeld = pooledCLVariables[_id].sharesHeld.add(_sharesRepaid);
        pooledCLVariables[_id].borrowerInterestShares = pooledCLVariables[_id].borrowerInterestShares.add(_interestShares);
    }

    /**
     * @notice Function invoked when pooled credit line is cancelled
     * @dev only pooledCreditLineContract can invoke
     * @param _id identifier for the pooled credit line
     */
    function requestCancelled(uint256 _id) external onlyPooledCreditLine {
        // We want *function lend* to fail, so that lenders do not keep on lending even after the CL is cancelled.
        delete pooledCLConstants[_id].startTime;

        // After this, we cannot delete *pooledCLConstants[_id]*, else we risk getting stuck with some of the lenders'
        // liquidity inside of this contract. Therefore, after this, the user must themselves call *withdrawLiquidity*
    }

    //-------------------------------- callbacks end --------------------------------//

    //-------------------------------- Interest start --------------------------------//

    /**
     * @notice Function used to withdraw interest accrued in pooled credit line
     * @dev Tokens lent are locked till end of Pooled Credit line. 
        Any interest paid by borrower can be withdrawn by lenders proportional to
        their token balances for that pooled credit line. Partial withdrawal of 
        interest is not allowed. Whenever they call the `withdrawInterest` function
        they will get the entire amount of interest that is owed to them by that time
     * @param _id identifier for the pooled credit line
     * @param _lender address of lender for whom interest is withdrawn
     */
    function withdrawInterest(uint256 _id, address _lender) external nonReentrant {
        _withdrawInterest(_id, _lender);
    }

    function _withdrawInterest(uint256 _id, address _lender) internal {
        address _strategy = pooledCLConstants[_id].borrowAssetStrategy;
        address _borrowAsset = pooledCLConstants[_id].borrowAsset;

        (uint256 _interestToWithdraw, uint256 _interestSharesToWithdraw) = _calculateInterestToWithdraw(
            _id,
            _lender,
            _strategy,
            _borrowAsset
        );

        pooledCLVariables[_id].sharesHeld = pooledCLVariables[_id].sharesHeld.sub(_interestSharesToWithdraw);

        if (_interestToWithdraw != 0) {
            SAVINGS_ACCOUNT.withdraw(_borrowAsset, _strategy, _lender, _interestToWithdraw, false);
        }
        emit InterestWithdrawn(_id, _lender, _interestSharesToWithdraw);
    }

    function _calculateInterestToWithdraw(
        uint256 _id,
        address _lender,
        address _strategy,
        address _borrowAsset
    ) internal returns (uint256, uint256) {
        uint256 _lenderBalance = balanceOf(_lender, _id);
        if (_lenderBalance == 0) {
            return (0, 0);
        }
        uint256 _totalInterestInShares;
        {
            uint256 _notBorrowed = pooledCLConstants[_id].borrowLimit.sub(POOLED_CREDIT_LINE.getPrincipal(_id));
            uint256 _notBorrowedInShares = IYield(_strategy).getSharesForTokens(_notBorrowed, _borrowAsset);
            _totalInterestInShares = pooledCLVariables[_id].sharesHeld.sub(_notBorrowedInShares);
        }

        uint256 _borrowerInterestShares = pooledCLVariables[_id].borrowerInterestShares;
        uint256 _totalSupply = totalSupply[_id];
        uint256 _borrowerInterestForLender = (_borrowerInterestShares.mul(_lenderBalance).div(_totalSupply)).sub(
            pooledCLVariables[_id].lenders[_lender].borrowerInterestSharesWithdrawn
        );

        uint256 _yieldInterestForLender;
        {
            uint256 _totalYieldInterest = _totalInterestInShares.sub(_borrowerInterestShares).add(
                pooledCLVariables[_id].yieldInterestWithdrawnShares
            );

            _yieldInterestForLender = (_totalYieldInterest.mul(_lenderBalance).div(_totalSupply)).sub(
                pooledCLVariables[_id].lenders[_lender].yieldInterestWithdrawnShares
            );
        }

        pooledCLVariables[_id].lenders[_lender].yieldInterestWithdrawnShares = pooledCLVariables[_id]
            .lenders[_lender]
            .yieldInterestWithdrawnShares
            .add(_yieldInterestForLender);
        pooledCLVariables[_id].lenders[_lender].borrowerInterestSharesWithdrawn = pooledCLVariables[_id]
            .lenders[_lender]
            .borrowerInterestSharesWithdrawn
            .add(_borrowerInterestForLender);
        pooledCLVariables[_id].borrowerInterestSharesWithdrawn = pooledCLVariables[_id].borrowerInterestSharesWithdrawn.add(
            _borrowerInterestForLender
        );
        pooledCLVariables[_id].yieldInterestWithdrawnShares = pooledCLVariables[_id].yieldInterestWithdrawnShares.add(
            _yieldInterestForLender
        );

        uint256 _interestToWithdraw = IYield(_strategy).getTokensForShares(
            _yieldInterestForLender.add(_borrowerInterestForLender),
            _borrowAsset
        );
        return (_interestToWithdraw, _yieldInterestForLender.add(_borrowerInterestForLender));
    }

    //-------------------------------- Interest end --------------------------------//

    //-------------------------------- Liquidity withdraw start --------------------------------//

    /**
     * @notice Function to withdraw liquidity by lender
     * @dev Liquidity can be withdrawn when the pooled credit line is no longer running in the following scenarios
        0. Pooled credit line gets cancelled by the borrower
        1. Pooled credit line never started because desired amount wasn't reached
        2. Credit line liquidated before it closes
        3. Credit line liquidated after it closes
        4. Credit line liquidated due to non repayment when it closes
        5. Credit line closed after all repayments
     * @param _id identifier for the pooled credit line
     */

    function withdrawLiquidity(uint256 _id) external nonReentrant {
        _withdrawLiquidity(_id, false);
    }

    function _withdrawLiquidity(uint256 _id, bool _isLiquidationWithdrawn) internal {
        uint256 _status = uint256(POOLED_CREDIT_LINE.getStatus(_id));

        uint256 _liquidityProvided = balanceOf(msg.sender, _id);

        address _borrowAsset = pooledCLConstants[_id].borrowAsset;
        if (
            (_status == uint256(PooledCreditLineStatus.CANCELLED)) ||
            (_status == uint256(PooledCreditLineStatus.REQUESTED) &&
                block.timestamp > pooledCLConstants[_id].startTime &&
                totalSupply[_id] < pooledCLConstants[_id].minBorrowAmount)
        ) {
            // Case 0:
            // Credit Line request was cancelled by the borrower, which deletes the creditLineVariables, hence status = uint256(0)
            // Cancellation can only be done in the REQUESTED state, therefore, the borrowLimit target was also not met
            // &&
            // Case 1: Pooled credit line never started because desired amount wasn't reached
            // _maxToLend is 0 if credit line is accepted so this case is never run

            //transfer liquidity provided
            IERC20(_borrowAsset).safeTransfer(msg.sender, _liquidityProvided);
            emit WithdrawLiquidityOnCancel(_id, msg.sender, _liquidityProvided);
        } else if (_status == uint256(PooledCreditLineStatus.CLOSED) || _status == uint256(PooledCreditLineStatus.LIQUIDATED)) {
            if (_status == uint256(PooledCreditLineStatus.LIQUIDATED)) {
                require(_isLiquidationWithdrawn, 'IWL1');
            }
            // all other cases distribute the sharesHeld proportional to their poolToken balances
            address _strategy = pooledCLConstants[_id].borrowAssetStrategy;
            uint256 _principalWithdrawable = _calculatePrincipalWithdrawable(_id, msg.sender);
            (uint256 _interestWithdrawable, ) = _calculateInterestToWithdraw(_id, msg.sender, _strategy, _borrowAsset);
            uint256 _amountToWithdraw = _principalWithdrawable.add(_interestWithdrawable);
            uint256 _sharesToWithdraw = IYield(_strategy).getSharesForTokens(_amountToWithdraw, _borrowAsset);
            pooledCLVariables[_id].sharesHeld = pooledCLVariables[_id].sharesHeld.sub(_sharesToWithdraw);

            SAVINGS_ACCOUNT.withdrawShares(_borrowAsset, _strategy, msg.sender, _sharesToWithdraw, false);
            emit WithdrawLiquidity(_id, msg.sender, _sharesToWithdraw);
        } else {
            revert('IWL2');
        }

        _burn(msg.sender, _id, _liquidityProvided);
    }

    /**
     * @notice Function that can be used to calculate principal withdrawable
     * @param _id identifier for the pooled credit line
     * @param _lender lender whose share of prinipal is to be withdrawn
     */
    function calculatePrincipalWithdrawable(uint256 _id, address _lender) external returns (uint256) {
        uint256 _status = uint256(POOLED_CREDIT_LINE.getStatus(_id));
        if (_status == uint256(PooledCreditLineStatus.CLOSED) || _status == uint256(PooledCreditLineStatus.LIQUIDATED)) {
            return _calculatePrincipalWithdrawable(_id, _lender);
        } else if (
            _status == uint256(PooledCreditLineStatus.REQUESTED) &&
            block.timestamp > pooledCLConstants[_id].startTime &&
            totalSupply[_id] < pooledCLConstants[_id].minBorrowAmount
        ) {
            return balanceOf(_lender, _id);
        } else {
            return 0;
        }
    }

    function _calculatePrincipalWithdrawable(uint256 _id, address _lender) internal view returns (uint256) {
        uint256 _currentSupply = totalSupply[_id];
        uint256 _totalLiquidityWithdrawable = pooledCLConstants[_id].borrowLimit.sub(POOLED_CREDIT_LINE.getPrincipal(_id));
        uint256 _principalWithdrawable = _totalLiquidityWithdrawable.mul(balanceOf(_lender, _id)).div(_currentSupply);
        return _principalWithdrawable;
    }

    //-------------------------------- Liquidity withdraw end --------------------------------//

    //-------------------------------- Liquidation start --------------------------------//

    /**
     * @notice Function used to liquidate a pooleed credit line
     * @dev only one of the lenders can liquidate their pooled credit line
     * @param _id identifier for the pooled credit line
     * @param _withdraw flag used to identify if their share of liquidated collateral 
        is also withdrawn along with liquidation
     */
    function liquidate(uint256 _id, bool _withdraw) external nonReentrant {
        uint256 _lendingShare = balanceOf(msg.sender, _id);
        require(_lendingShare != 0, 'L1');
        // This line would call the liquidate function in the pooledCreditLine contract.
        // Which would transfer the totalCollateralTokens to the pooledCreditLine contract.
        (address _collateralAsset, uint256 _collateralLiquidated) = POOLED_CREDIT_LINE.liquidate(_id);
        pooledCLConstants[_id].collateralAsset = _collateralAsset;
        pooledCLVariables[_id].collateralHeld = _collateralLiquidated;

        emit Liquidated(_id, _collateralLiquidated);

        if (_withdraw) {
            // This function would give the share of the lender who called this function from the total liquidated amount
            _withdrawLiquidation(_id, msg.sender, _lendingShare);
        }
    }

    /**
     * @notice Function used to withdraw lender's share of liquidated collateral
     * @param _id identifier for the pooled credit line
     * @param _lender address of lender for which liquidated collateral is withdrawn
     */
    function withdrawLiquidation(uint256 _id, address _lender) external nonReentrant {
        uint256 _lendingShare = balanceOf(_lender, _id);
        require(_lendingShare != 0, 'WL1');
        _withdrawLiquidation(_id, _lender, _lendingShare);
    }

    function _withdrawLiquidation(
        uint256 _id,
        address _lender,
        uint256 _balance
    ) internal {
        uint256 _collateralLiquidated = pooledCLVariables[_id].collateralHeld;
        uint256 _currentSupply = totalSupply[_id];

        uint256 _lenderCollateralShare = _balance.mul(_collateralLiquidated).div(_currentSupply);

        if (_lenderCollateralShare != 0) {
            pooledCLVariables[_id].collateralHeld = pooledCLVariables[_id].collateralHeld.sub(_lenderCollateralShare);

            IERC20(pooledCLConstants[_id].collateralAsset).safeTransfer(_lender, _lenderCollateralShare);
        }
        emit LiquidationWithdrawn(_id, _lender, _lenderCollateralShare);
        _withdrawLiquidity(_id, true);
    }

    //-------------------------------- Liquidation end --------------------------------//

    //-------------------------------- Pre token transfer start --------------------------------//

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override {
        require(from != to, 'T1');
        for (uint256 i; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(to == address(0) || VERIFICATION.isUser(to, pooledCLConstants[id].verifier), 'T2');

            uint256 amount = amounts[i];

            if (from == address(0)) {
                totalSupply[id] = totalSupply[id].add(amount);
            } else if (to == address(0)) {
                uint256 supply = totalSupply[id];
                require(supply >= amount, 'T3');
                totalSupply[id] = supply - amount;
            } else {
                require(pooledCLConstants[id].areTokensTransferable, 'T4');
            }

            if (from == address(0)) {
                return;
            }

            _rebalanceInterestWithdrawn(id, amount, from, to);
        }
    }

    function _rebalanceInterestWithdrawn(
        uint256 id,
        uint256 amount,
        address from,
        address to
    ) internal {
        if (from != address(0) && to != address(0)) {
            _withdrawInterest(id, from);
            _withdrawInterest(id, to);
        }

        uint256 fromBalance = balanceOf(from, id);

        uint256 yieldInterestOnTransferAmount = pooledCLVariables[id].lenders[from].yieldInterestWithdrawnShares.mul(amount).div(
            fromBalance
        );
        uint256 borrowerInterestOnTransferAmount = pooledCLVariables[id].lenders[from].borrowerInterestSharesWithdrawn.mul(amount).div(
            fromBalance
        );

        if (borrowerInterestOnTransferAmount != 0) {
            pooledCLVariables[id].lenders[from].borrowerInterestSharesWithdrawn = pooledCLVariables[id]
                .lenders[from]
                .borrowerInterestSharesWithdrawn
                .sub(borrowerInterestOnTransferAmount);
        }

        if (yieldInterestOnTransferAmount != 0) {
            pooledCLVariables[id].lenders[from].yieldInterestWithdrawnShares = pooledCLVariables[id]
                .lenders[from]
                .yieldInterestWithdrawnShares
                .sub(yieldInterestOnTransferAmount);
        }

        if (to != address(0)) {
            if (borrowerInterestOnTransferAmount != 0) {
                pooledCLVariables[id].lenders[to].borrowerInterestSharesWithdrawn = pooledCLVariables[id]
                    .lenders[to]
                    .borrowerInterestSharesWithdrawn
                    .add(borrowerInterestOnTransferAmount);
            }
            if (yieldInterestOnTransferAmount != 0) {
                pooledCLVariables[id].lenders[to].yieldInterestWithdrawnShares = pooledCLVariables[id]
                    .lenders[to]
                    .yieldInterestWithdrawnShares
                    .add(yieldInterestOnTransferAmount);
            }
        }
    }

    //-------------------------------- Pre token transfer end --------------------------------//

    //-------------------------------- global var update start --------------------------------//

    /**
     * @notice Function used to update startFeeFraction variable
     * @param _startFeeFraction updated value of fraction of total lent amount given as fee when start is invoked
     */
    function updateStartFeeFraction(uint256 _startFeeFraction) external onlyOwner {
        require(_startFeeFraction != startFeeFraction, 'USFF');
        _updateStartFeeFraction(_startFeeFraction);
    }

    function _updateStartFeeFraction(uint256 _startFeeFraction) internal {
        require(_startFeeFraction <= SCALING_FACTOR, 'IUSFF');
        startFeeFraction = _startFeeFraction;
        emit StartFeeFractionUpdated(_startFeeFraction);
    }

    /**
     * @notice Function used to update maxStartFee variable
     * @param _maxStartFee updated value of max fee given to address which invokes start fee
     */
    function updateMaxStartFee(uint256 _maxStartFee) external onlyOwner {
        require(maxStartFee != _maxStartFee, 'UMSF');
        _updateMaxStartFee(_maxStartFee);
    }

    function _updateMaxStartFee(uint256 _maxStartFee) internal {
        maxStartFee = _maxStartFee;
        emit MaxStartFeeUpdated(_maxStartFee);
    }

    //-------------------------------- global var update end --------------------------------//

    //-------------------------------- getters start --------------------------------//

    /**
     * @notice Function used to get withdrawal info of a lender for a specific pooled credit line
     * @param _id identifier for the pooled credit line
     * @param _lender address of the lender for which query is made
     */
    function getLenderInfo(uint256 _id, address _lender) external view returns (LenderInfo memory) {
        return pooledCLVariables[_id].lenders[_lender];
    }

    //-------------------------------- getters end --------------------------------//
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISavingsAccount {
    /**
     * @notice emitted when tokens are deposited into savings account
     * @param user address of user depositing the tokens
     * @param sharesReceived amount of shares received for deposit
     * @param token address of token that is deposited
     * @param strategy strategy into which tokens are deposited
     */
    event Deposited(address indexed user, uint256 sharesReceived, address indexed token, address indexed strategy);

    /**
     * @notice emitted when tokens are switched from one strategy to another
     * @param user address of user switching strategies
     * @param token address of token for which strategies are switched
     * @param sharesDecreasedInCurrentStrategy shares decreased in current strategy
     * @param sharesIncreasedInNewStrategy shares increased in new strategy
     * @param currentStrategy address of the strategy from which tokens are switched
     * @param newStrategy address of the strategy to which tokens are switched
     */
    event StrategySwitched(
        address indexed user,
        address indexed token,
        uint256 sharesDecreasedInCurrentStrategy,
        uint256 sharesIncreasedInNewStrategy,
        address currentStrategy,
        address indexed newStrategy
    );

    /**
     * @notice emitted when tokens are withdrawn from savings account
     * @param from address of user from which tokens are withdrawn
     * @param to address of user to which tokens are withdrawn
     * @param sharesWithdrawn amount of shares withdrawn
     * @param token address of token that is withdrawn
     * @param strategy strategy into which tokens are withdrawn
     * @param receiveShares flag to represent if shares are directly wirthdrawn
     */
    event Withdrawn(
        address indexed from,
        address indexed to,
        uint256 sharesWithdrawn,
        address indexed token,
        address strategy,
        bool receiveShares
    );

    /**
     * @notice emitted when all tokens are withdrawn
     * @param user address of user withdrawing tokens
     * @param tokenReceived amount of tokens withdrawn
     * @param token address of the token withdrawn
     */
    event WithdrawnAll(address indexed user, uint256 tokenReceived, address indexed token);

    /**
     * @notice emitted when tokens are approved
     * @param token address of token approved
     * @param from address of user from who tokens are approved
     * @param to address of user to whom tokens are approved
     * @param amount amount of tokens approved
     */
    event Approved(address indexed token, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when tokens are transferred
     * @param token address of token transferred
     * @param strategy address of strategy from which tokens are transferred
     * @param from address of user from whom tokens are transferred
     * @param to address of user to whom tokens are transferred
     * @param amount amount of tokens transferred
     */
    event Transfer(address indexed token, address strategy, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when tokens' shares are burnt by the owner
     * @param token address of the token whose shares were burnt
     * @param strategy address of the strategy from which shares were burnt
     * @param from address of the user that burnt their token shares
     * @param amount amount of token shares burnt
     */
    event Burned(address indexed token, address strategy, address indexed from, uint256 amount);

    /**
     * @notice emitted when tokens are transferred
     * @param token address of token transferred
     * @param strategy address of strategy from which tokens are transferred
     * @param from address of user from whom tokens are transferred
     * @param to address of user to whom tokens are transferred
     * @param shares amount of tokens transferred
     */
    event TransferShares(address indexed token, address strategy, address indexed from, address indexed to, uint256 shares);

    /**
     * @notice emitted when strategy registry is updated
     * @param updatedStrategyRegistry updated strategy registry address
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    function allowance(
        address user,
        address token,
        address to
    ) external returns (uint256 userAllowance);

    function deposit(
        address token,
        address strategy,
        address to,
        uint256 amount
    ) external returns (uint256 sharesReceived);

    /**
     * @dev Used to switch saving strategy of an token
     * @param currentStrategy initial strategy of token
     * @param newStrategy new strategy to invest
     * @param token address of the token
     * @param amount amount of tokens to be reinvested
     */
    function switchStrategy(
        address currentStrategy,
        address newStrategy,
        address token,
        uint256 amount
    ) external;

    /**
     * @dev Used to withdraw token from Saving Account
     * @param withdrawTo address to which token should be sent
     * @param amount amount of tokens to withdraw
     * @param token address of the token to be withdrawn
     * @param strategy strategy from where token has to withdrawn(ex:- compound,Aave etc)
     * @param receiveShares boolean indicating to withdraw in liquidity share or underlying token
     */
    function withdraw(
        address token,
        address strategy,
        address withdrawTo,
        uint256 amount,
        bool receiveShares
    ) external returns (uint256 amountWithdrawn);

    function withdrawAll(address token) external returns (uint256 tokenReceived);

    function withdrawAll(address token, address strategy) external returns (uint256 tokenReceived);

    function approve(
        address token,
        address to,
        uint256 amount
    ) external;

    function increaseAllowance(
        address token,
        address to,
        uint256 amount
    ) external;

    function decreaseAllowance(
        address token,
        address to,
        uint256 amount
    ) external;

    function transferShares(
        uint256 _shares,
        address _token,
        address _strategy,
        address _to
    ) external returns (uint256);

    function transfer(
        address token,
        address strategy,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function transferSharesFrom(
        uint256 shares,
        address token,
        address strategy,
        address from,
        address to
    ) external returns (uint256);

    function transferFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function burn(
        uint256 amount,
        address token,
        address poolSavingsStrategy
    ) external returns (uint256);

    function balanceInShares(
        address user,
        address token,
        address strategy
    ) external view returns (uint256 shareBalance);

    function withdrawFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function withdrawShares(
        address token,
        address strategy,
        address to,
        uint256 shares,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function withdrawSharesFrom(
        address token,
        address strategy,
        address from,
        address to,
        uint256 shares,
        bool receiveShares
    ) external returns (uint256 amountReceived);

    function getTotalTokens(address _user, address _token) external returns (uint256 _totalTokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/ISavingsAccount.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

library SavingsAccountUtil {
    using SafeERC20 for IERC20;

    function depositFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _withdrawShares,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        if (Address(_token) != Address(0)) {
            require(msg.value == 0, 'DFSA1');
        }
        if (_toSavingsAccount) {
            return savingsAccountTransfer(_savingsAccount, _token, _strategy, _from, _to, _amount);
        } else {
            return withdrawFromSavingsAccount(_savingsAccount, _token, _strategy, _from, _to, _amount, _withdrawShares);
        }
    }

    function directDeposit(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        if (Address(_token) != Address(0)) {
            require(msg.value == 0, 'DD1');
        }
        if (_toSavingsAccount) {
            return directSavingsAccountDeposit(_savingsAccount, _token, _strategy, _from, _to, _amount);
        } else {
            return transferTokens(_token, _from, _to, _amount);
        }
    }

    function directSavingsAccountDeposit(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        transferTokens(_token, _from, address(this), _amount);
        address _approveTo = _strategy;
        IERC20(_token).safeApprove(_approveTo, _amount);
        uint256 _sharesReceived = _savingsAccount.deposit(_token, _strategy, _to, _amount);
        return _sharesReceived;
    }

    function savingsAccountTransferShares(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _shares
    ) internal returns (uint256) {
        if (_from == address(this)) {
            _savingsAccount.transferShares(_shares, _token, _strategy, _to);
        } else {
            _savingsAccount.transferSharesFrom(_shares, _token, _strategy, _from, _to);
        }
        return _shares;
    }

    function savingsAccountTransfer(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_from == address(this)) {
            return _savingsAccount.transfer(_token, _strategy, _to, _amount);
        } else {
            return _savingsAccount.transferFrom(_token, _strategy, _from, _to, _amount);
        }
    }

    function withdrawFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _token,
        address _strategy,
        address _from,
        address _to,
        uint256 _amount,
        bool _withdrawShares
    ) internal returns (uint256) {
        uint256 _amountReceived;
        if (_from == address(this)) {
            _amountReceived = _savingsAccount.withdraw(_token, _strategy, _to, _amount, _withdrawShares);
        } else {
            _amountReceived = _savingsAccount.withdrawFrom(_token, _strategy, _from, _to, _amount, _withdrawShares);
        }
        return _amountReceived;
    }

    function transferTokens(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == 0) return 0;

        if (_from == address(this)) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            //pool
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
        }
        return _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IYield {
    /**
     * @dev emitted when tokens are locked
     * @param user the address of user, tokens locked for
     * @param investedTo the address of contract to invest in
     * @param lpTokensReceived the amount of shares received
     **/
    event LockedTokens(address indexed user, address indexed investedTo, uint256 lpTokensReceived);

    /**
     * @dev emitted when tokens are unlocked/redeemed
     * @param investedTo the address of contract invested in
     * @param collateralReceived the amount of underlying asset received
     **/
    event UnlockedTokens(address indexed investedTo, uint256 collateralReceived);

    /**
     * @notice emitted when a shares are unlocked from yield
     * @param asset address of the base token for which shares are being withdrawn
     * @param sharesReleased amount of shares unlocked
     */
    event UnlockedShares(address indexed asset, uint256 sharesReleased);

    /**
     * @notice emitted when savings account address is updated
     * @param savingsAccount updated address of the savings account contract
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

    /**
     * @dev Used to get liquidity token address from asset address
     * @param asset the address of underlying token
     * @return tokenAddress address of liquidity token
     **/
    function liquidityToken(address asset) external view returns (address tokenAddress);

    /**
     * @dev Used to lock tokens in available protocol
     * @param user the address of user locking tokens
     * @param asset the address of token to invest
     * @param amount the amount of asset
     * @return sharesReceived amount of shares received
     **/
    function lockTokens(
        address user,
        address asset,
        uint256 amount
    ) external returns (uint256 sharesReceived);

    /**
     * @dev Used to unlock tokens from available protocol
     * @param asset the address of underlying token
     * @param to the address to which tokens are transferred after unlock
     * @param amount the amount of liquidity shares to unlock
     * @return tokensReceived amount of tokens received
     **/
    function unlockTokens(
        address asset,
        address to,
        uint256 amount
    ) external returns (uint256 tokensReceived);

    function unlockShares(
        address asset,
        address to,
        uint256 amount
    ) external returns (uint256 received);

    /**
     * @dev Used to get amount of underlying tokens for current number of shares
     * @param shares the amount of shares
     * @param asset the address of token locked
     * @return amount amount of underlying tokens
     **/
    function getTokensForShares(uint256 shares, address asset) external returns (uint256 amount);

    function getSharesForTokens(uint256 amount, address asset) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ILenderPool {
    /**
     * @notice emitted when lender withdraws from pool of poole-credit-lines
     * @param amount amount that lender withdraws from borrow pool
     * @param lenderAddress address to which amount is withdrawn
     */
    event LiquidityWithdrawn(uint256 amount, address indexed lenderAddress);

    function create(
        uint256 _id,
        address _verifier,
        address _token,
        address _strategy,
        uint256 _borrowLimit,
        uint256 _minBorrowAmount,
        uint256 _collectionPeriod,
        bool _areTokensTransferable
    ) external;

    function start(uint256 _id, address _user) external;

    function borrowed(uint256 _id, uint256 _sharesBorrowed) external;

    function repaid(
        uint256 _id,
        uint256 _sharesRepaid,
        uint256 _interestShares
    ) external;

    function requestCancelled(uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVerification {
    /// @notice Event emitted when a verifier is added as valid by admin
    /// @param verifier The address of the verifier contract to be added
    event VerifierAdded(address indexed verifier);

    /// @notice Event emitted when a verifier is to be marked as invalid by admin
    /// @param verifier The address of the verified contract to be marked as invalid
    event VerifierRemoved(address indexed verifier);

    /// @notice Event emitted when a master address is verified by a valid verifier
    /// @param masterAddress The masterAddress which is verifier by the verifier
    /// @param verifier The verifier which verified the masterAddress
    /// @param activatesAt Timestamp at which master address is considered active after the cooldown period
    event UserRegistered(address indexed masterAddress, address indexed verifier, uint256 activatesAt);

    /// @notice Event emitted when a master address is marked as invalid/unregisterd by a valid verifier
    /// @param masterAddress The masterAddress which is unregistered
    /// @param verifier The verifier which verified the masterAddress
    /// @param unregisteredBy The msg.sender by which the user was unregistered
    event UserUnregistered(address indexed masterAddress, address indexed verifier, address indexed unregisteredBy);

    /// @notice Event emitted when an address is linked to masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address is linked
    /// @param activatesAt Timestamp at which linked address is considered active after the cooldown period
    event AddressLinked(address indexed linkedAddress, address indexed masterAddress, uint256 activatesAt);

    /// @notice Event emitted when an address is unlinked from a masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address was linked
    event AddressUnlinked(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address placed a request to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequested(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address cancels the request placed to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequestCancelled(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when activation delay is updated
    /// @param activationDelay updated value of activationDelay in seconds
    event ActivationDelayUpdated(uint256 activationDelay);

    function isUser(address _user, address _verifier) external view returns (bool isMsgSenderUser);

    function registerMasterAddress(address _masterAddress, bool _isMasterLinked) external;

    function unregisterMasterAddress(address _masterAddress, address _verifier) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPriceOracle {
    /**
     * @notice emitted when chainlink price feed for a token is updated
     * @param token address of token for which price feed is updated
     * @param priceOracle address of the updated price feed for the token
     */
    event ChainlinkFeedUpdated(address indexed token, address indexed priceOracle);

    /**
     * @notice emitted when uniswap price feed for a token pair is updated
     * @param token1 address of numerator address in price feed
     * @param token2 address of denominator address in price feed
     * @param feedId unique id for the token pair irrespective of the order of tokens
     * @param pool address of the pool from which price feed can be queried
     */
    event UniswapFeedUpdated(address indexed token1, address indexed token2, bytes32 feedId, address indexed pool);

    /**
     * @notice emitted when price averaging window for uniswap price feeds is updated
     * @param uniswapPriceAveragingPeriod period during which uniswap prices are averaged over to avoid attacks
     */
    event UniswapPriceAveragingPeriodUpdated(uint32 uniswapPriceAveragingPeriod);

    function getLatestPrice(address num, address den) external view returns (uint256 price, uint256 decimals);

    function doesFeedExist(address token1, address token2) external view returns (bool feedExists);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IPooledCreditLineDeclarations.sol';

interface IPooledCreditLine is IPooledCreditLineDeclarations {
    function accept(uint256 _id, uint256 _amount) external;

    function getPrincipal(uint256 _id) external view returns (uint256);

    function getStatus(uint256 _id) external returns (PooledCreditLineStatus);

    function liquidate(uint256 _id) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPooledCreditLineDeclarations {
    struct Request {
        uint256 collateralRatio;
        uint256 duration;
        address verifier;
        uint256 defaultGracePeriod;
        uint256 gracePenaltyRate;
        uint256 collectionPeriod;
        uint256 minBorrowAmount;
        uint128 borrowLimit;
        uint128 borrowRate;
        address collateralAsset;
        address borrowAssetStrategy;
        address collateralAssetStrategy;
        address borrowAsset;
        address borrowerVerifier;
        bool areTokensTransferable;
    }

    enum PooledCreditLineStatus {
        NOT_CREATED,
        REQUESTED,
        ACTIVE,
        CLOSED,
        EXPIRED,
        LIQUIDATED,
        CANCELLED
    }
}