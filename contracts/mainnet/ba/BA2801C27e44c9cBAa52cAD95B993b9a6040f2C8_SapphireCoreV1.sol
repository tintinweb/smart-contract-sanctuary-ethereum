// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {BaseERC20} from "../token/BaseERC20.sol";
import {IERC20Metadata} from "../token/IERC20Metadata.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {Math} from "../lib/Math.sol";
import {Adminable} from "../lib/Adminable.sol";
import {Address} from "../lib/Address.sol";
import {Bytes32} from "../lib/Bytes32.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";

import {SapphireTypes} from "./SapphireTypes.sol";
import {SapphireCoreStorage} from "./SapphireCoreStorage.sol";
import {SapphireAssessor} from "./SapphireAssessor.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";
import {ISapphirePool} from "./SapphirePool/ISapphirePool.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";

contract SapphireCoreV1 is Adminable, ReentrancyGuard, SapphireCoreStorage {

    /* ========== Structs ========== */

    struct LiquidationVars {
        uint256 liquidationPrice;
        uint256 debtToRepay;
        uint256 collateralPrecisionScalar;
        uint256 collateralToSell;
        uint256 valueCollateralSold;
        uint256 profit;
        uint256 arcShare;
        uint256 liquidatorCollateralShare;
    }

    /* ========== Libraries ========== */

    using Address for address;
    using Bytes32 for bytes32;

    /* ========== Events ========== */

    event Deposited(
        address indexed _user,
        uint256 _deposit,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Withdrawn(
        address indexed _user,
        uint256 _withdrawn,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Borrowed(
        address indexed _user,
        uint256 _borrowed,
        address indexed _borrowAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Repaid(
        address indexed _user,
        address indexed _repayer,
        uint256 _repaid,
        address indexed _repayAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Liquidated(
        address indexed _userLiquidator,
        address indexed _liquidator,
        uint256 _collateralPrice,
        uint256 _assessedCRatio,
        uint256 _liquidatedCollateral,
        uint256 _repayAmount,
        address indexed _repayAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event FeesUpdated(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    );

    event LimitsUpdated(
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum,
        uint256 _defaultBorrowLimit
    );

    event IndexUpdated(
        uint256 _newIndex,
        uint256 _lastUpdateTime
    );

    event InterestRateUpdated(uint256 _value);

    event OracleUpdated(address _oracle);

    event PauseStatusUpdated(bool _pauseStatus);

    event InterestSetterUpdated(address _newInterestSetter);

    event PauseOperatorUpdated(address _newPauseOperator);

    event AssessorUpdated(address _newAssessor);

    event CollateralRatiosUpdated(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    );

    event FeeCollectorUpdated(
        address _feeCollector
    );

    event ProofProtocolSet(
        string _creditProtocol,
        string _borrowLimitProtocol
    );

    event BorrowPoolUpdated(address _borrowPool);

    /* ========== Modifiers ========== */

    /**
     * @dev Saves the precision scalar of the token, if not done already
     */
    modifier cacheAssetDecimals(address _asset) {
        _savePrecisionScalar(_asset);
        _;
    }

    /* ========== Admin Setters ========== */

    /**
     * @dev Initialize the protocol with the appropriate parameters. Can only be called once.
     *      IMPORTANT: the contract assumes the collateral contract is to be trusted.
     *      Make sure this is true before calling this function.
     *
     * @param _collateralAddress    The address of the collateral to be used
     * @param _oracleAddress        The address of the IOracle conforming contract
     * @param _interestSetter       The address which can update interest rates
     * @param _pauseOperator        The address which can pause the contract
     * @param _assessorAddress,     The address of assessor contract conforming ISapphireAssessor,
     *                              which provides credit score functionality
     * @param _feeCollector         The address of the ARC fee collector when a liquidation occurs
     * @param _highCollateralRatio  High limit of how much collateral is needed to borrow
     * @param _lowCollateralRatio   Low limit of how much collateral is needed to borrow
     */
    function init(
        address _collateralAddress,
        address _oracleAddress,
        address _interestSetter,
        address _pauseOperator,
        address _assessorAddress,
        address _feeCollector,
        uint256 _highCollateralRatio,
        uint256 _lowCollateralRatio
    )
        external
        onlyAdmin
        cacheAssetDecimals(_collateralAddress)
    {
        require(
            collateralAsset == address(0),
            "SapphireCoreV1: cannot re-initialize contract"
        );

        require(
            _collateralAddress.isContract(),
            "SapphireCoreV1: collateral is not a contract"
        );

        paused          = true;
        borrowIndex     = BASE;
        indexLastUpdate = currentTimestamp();
        collateralAsset = _collateralAddress;
        interestSetter  = _interestSetter;
        pauseOperator   = _pauseOperator;
        feeCollector    = _feeCollector;
        _scoreProtocols = [
            bytes32("arcx.credit"),
            bytes32("arcx.creditLimit")
        ];

        setAssessor(_assessorAddress);
        setOracle(_oracleAddress);
        setCollateralRatios(_lowCollateralRatio, _highCollateralRatio);
    }

    /**
     * @dev Set the instance of the oracle to report prices from. Must conform to IOracle.sol
     *
     * @notice Can only be called by the admin
     *
     * @param _oracleAddress The address of the IOracle instance
     */
    function setOracle(
        address _oracleAddress
    )
        public
        onlyAdmin
    {
        require(
            _oracleAddress.isContract(),
            "SapphireCoreV1: oracle is not a contract"
        );

        require(
            _oracleAddress != address(oracle),
            "SapphireCoreV1: the same oracle is already set"
        );

        oracle = ISapphireOracle(_oracleAddress);
        emit OracleUpdated(_oracleAddress);
    }

    /**
     * @dev Set low and high collateral ratios of collateral value to debt.
     *
     * @notice Can only be called by the admin.
     *
     * @param _lowCollateralRatio The minimal allowed ratio expressed up to 18 decimal places
     * @param _highCollateralRatio The maximum allowed ratio expressed up to 18 decimal places
     */
    function setCollateralRatios(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    )
        public
        onlyAdmin
    {
        require(
            _lowCollateralRatio <= _highCollateralRatio,
            "SapphireCoreV1: high c-ratio is lower than the low c-ratio"
        );

        require(
            _lowCollateralRatio >= BASE,
            "SapphireCoreV1: collateral ratio has to be at least 1"
        );

        require(
            (_lowCollateralRatio != lowCollateralRatio) ||
            (_highCollateralRatio != highCollateralRatio),
            "SapphireCoreV1: the same ratios are already set"
        );

        lowCollateralRatio = _lowCollateralRatio;
        highCollateralRatio = _highCollateralRatio;

        emit CollateralRatiosUpdated(lowCollateralRatio, highCollateralRatio);
    }

    /**
     * @dev Set the fees in the system.
     *
     * @notice Can only be called by the admin.
     *
     * @param _liquidatorDiscount Determines the penalty a user must pay by discounting their
     * collateral price to provide a profit incentive for liquidators.
     * @param _liquidationArcFee The percentage of the profit earned from the liquidation,
     * which the feeCollector earns.
     * @param _borrowFee The percentage of the the loan that is added as immediate interest.
     * @param _poolInterestFee The percentage of the interest paid that goes to the borrow pool.
     */
    function setFees(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    )
        public
        onlyAdmin
    {
        require(
            (_liquidatorDiscount != liquidatorDiscount) ||
            (_liquidationArcFee != liquidationArcFee) ||
            (_borrowFee != borrowFee) ||
            (_poolInterestFee != poolInterestFee),
            "SapphireCoreV1: the same fees are already set"
        );

        _setFees(
            _liquidatorDiscount,
            _liquidationArcFee,
            _borrowFee,
            _poolInterestFee
        );
    }

    /**
     * @dev Set the limits of the system to ensure value can be capped.
     *
     * @notice Can only be called by the admin
     *
     * @param _vaultBorrowMinimum The minimum allowed borrow amount for vault
     * @param _vaultBorrowMaximum The maximum allowed borrow amount for vault
     */
    function setLimits(
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum,
        uint256 _defaultBorrowLimit
    )
        public
        onlyAdmin
    {
        require(
            _vaultBorrowMinimum <= _vaultBorrowMaximum,
            "SapphireCoreV1: required condition is vaultMin <= vaultMax"
        );

        require(
            (_vaultBorrowMinimum != vaultBorrowMinimum) ||
            (_vaultBorrowMaximum != vaultBorrowMaximum) ||
            (_defaultBorrowLimit != defaultBorrowLimit),
            "SapphireCoreV1: the same limits are already set"
        );

        vaultBorrowMinimum = _vaultBorrowMinimum;
        vaultBorrowMaximum = _vaultBorrowMaximum;
        defaultBorrowLimit = _defaultBorrowLimit;

        emit LimitsUpdated(vaultBorrowMinimum, vaultBorrowMaximum, _defaultBorrowLimit);
    }

    /**
     * @dev Set the address which can set interest rate
     *
     * @notice Can only be called by the admin
     *
     * @param _interestSetter The address of the new interest rate setter
     */
    function setInterestSetter(
        address _interestSetter
    )
        external
        onlyAdmin
    {
        require(
            _interestSetter != interestSetter,
            "SapphireCoreV1: cannot set the same interest setter"
        );

        interestSetter = _interestSetter;
        emit InterestSetterUpdated(interestSetter);
    }

    function setPauseOperator(
        address _pauseOperator
    )
        external
        onlyAdmin
    {
        require(
            _pauseOperator != pauseOperator,
            "SapphireCoreV1: the same pause operator is already set"
        );

        pauseOperator = _pauseOperator;
        emit PauseOperatorUpdated(pauseOperator);
    }

    function setAssessor(
        address _assessor
    )
        public
        onlyAdmin
    {
        require(
            _assessor.isContract(),
            "SapphireCoreV1: the address is not a contract"
        );

        require(
            _assessor != address(assessor),
            "SapphireCoreV1: the same assessor is already set"
        );

        assessor = ISapphireAssessor(_assessor);
        emit AssessorUpdated(_assessor);
    }

    function setBorrowPool(
        address _borrowPool
    )
        external
        onlyAdmin
    {
        require(
            _borrowPool != address(borrowPool),
            "SapphireCoreV1: the same borrow pool is already set"
        );

        require(
            _borrowPool.isContract(),
            "SapphireCoreV1: the address is not a contract"
        );

        borrowPool = _borrowPool;
        emit BorrowPoolUpdated(_borrowPool);
    }

    function setFeeCollector(
        address _newFeeCollector
    )
        external
        onlyAdmin
    {
        require(
            _newFeeCollector != address(feeCollector),
            "SapphireCoreV1: the same fee collector is already set"
        );

        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(feeCollector);
    }

    function setPause(
        bool _value
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "SapphireCoreV1: caller is not the pause operator"
        );

        require(
            _value != paused,
            "SapphireCoreV1: cannot set the same pause value"
        );

        paused = _value;
        emit PauseStatusUpdated(paused);
    }

    /**
     * @dev Update the interest rate of the protocol. Since this rate is compounded
     *      every second rather than being purely linear, the calculate for r is expressed
     *      as the following (assuming you want 5% APY):
     *
     *      r^N = 1.05
     *      since N = 365 * 24 * 60 * 60 (number of seconds in a year)
     *      r = 1.000000001547125957863212...
     *      rate = 1547125957 (r - 1e18 decimal places solidity value)
     *
     * @notice Can only be called by the interest setter of the protocol and the maximum
     *         rate settable is 99% (21820606489)
     *
     * @param _interestRate The interest rate expressed per second
     */
    function setInterestRate(
        uint256 _interestRate
    )
        external
    {

        require(
            msg.sender == interestSetter,
            "SapphireCoreV1: caller is not interest setter"
        );

        require(
            _interestRate < 21820606489,
            "SapphireCoreV1: interest rate cannot be more than 99% - 21820606489"
        );

        interestRate = _interestRate;
        emit InterestRateUpdated(interestRate);
    }

    function setProofProtocols(
        bytes32[] memory _protocols
    )
        external
        onlyAdmin
    {

        require(
            _protocols.length == 2,
            "SapphireCoreV1: array should contain two protocols"
        );

        _scoreProtocols = _protocols;

        emit ProofProtocolSet(
            _protocols[0].toString(),
            _protocols[1].toString()
        );
    }

    /* ========== Public Functions ========== */

    /**
     * @dev Deposits the given `_amount` of collateral to the `msg.sender`'s vault.
     *
     * @param _amount           The amount of collateral to deposit
     * @param _passportProofs   The passport score proofs - optional
     *                          Index 0 - score proof
     */
    function deposit(
        uint256 _amount,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            address(0),
            SapphireTypes.Operation.Deposit,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    function withdraw(
        uint256 _amount,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            address(0),
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Borrow against an existing position
     *
     * @param _amount The amount of stablecoins to borrow
     * @param _borrowAssetAddress The address of token to borrow
     * @param _passportProofs The passport score proofs - mandatory
     *                        Index 0 - score proof
     *                        Index 1 - borrow limit proof
     */
    function borrow(
        uint256 _amount,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            _borrowAssetAddress,
            SapphireTypes.Operation.Borrow,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    function repay(
        uint256 _amount,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            _borrowAssetAddress,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Repays the entire debt and withdraws the all the collateral
     *
     * @param _borrowAssetAddress The address of token to repay
     * @param _passportProofs     The passport score proofs - optional
     *                            Index 0 - score proof
     */
    function exit(
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
        cacheAssetDecimals(_borrowAssetAddress)
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](2);
        SapphireTypes.Vault memory vault = vaults[msg.sender];

        uint256 repayAmount = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        // Repay outstanding debt
        actions[0] = SapphireTypes.Action(
            repayAmount / precisionScalars[_borrowAssetAddress],
            _borrowAssetAddress,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        // Withdraw all collateral
        actions[1] = SapphireTypes.Action(
            vault.collateralAmount,
            address(0),
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Liquidate a user's vault. When this process occurs you're essentially
     *      purchasing the user's debt at a discount in exchange for the collateral
     *      they have deposited inside their vault.
     *
     * @param _owner the owner of the vault to liquidate
     * @param _borrowAssetAddress The address of token to repay
     * @param _passportProofs     The passport score proof - optional
     *                            Index 0 - score proof
     */
    function liquidate(
        address _owner,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            0,
            _borrowAssetAddress,
            SapphireTypes.Operation.Liquidate,
            _owner
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev All other user-called functions use this function to execute the
     *      passed actions. This function first updates the indexes before
     *      actually executing the actions.
     *
     * @param _actions          An array of actions to execute
     * @param _passportProofs   The passport score proof - optional
     *                          Index 0 - score proof
     *                          Index 1 - borrow limit proof
     */
    function executeActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
        nonReentrant
    {
        require(
            !paused,
            "SapphireCoreV1: the contract is paused"
        );

        require(
            _actions.length > 0,
            "SapphireCoreV1: there must be at least one action"
        );

        require (
            _passportProofs[0].protocol == _scoreProtocols[0],
            "SapphireCoreV1: incorrect credit score protocol"
        );

        // Update the index to calculate how much interest has accrued
        updateIndex();

        // Get the c-ratio and current price if necessary. The current price only be >0 if
        // it's required by an action
        (
            uint256 assessedCRatio,
            uint256 currentPrice
        ) = _getVariablesForActions(_actions, _passportProofs[0]);

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            if (action.operation == SapphireTypes.Operation.Deposit) {
                _deposit(action.amount);

            } else if (action.operation == SapphireTypes.Operation.Withdraw){
                _withdraw(action.amount, assessedCRatio, currentPrice);

            } else if (action.operation == SapphireTypes.Operation.Borrow) {
                _borrow(action.amount, action.borrowAssetAddress, assessedCRatio, currentPrice, _passportProofs[1]);

            }  else if (action.operation == SapphireTypes.Operation.Repay) {
                _repay(
                    msg.sender,
                    msg.sender,
                    action.amount,
                    action.borrowAssetAddress,
                    false
                );

            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
                _liquidate(action.userToLiquidate, currentPrice, assessedCRatio, action.borrowAssetAddress);
            }
        }
    }

    function updateIndex()
        public
        returns (uint256)
    {
        if (indexLastUpdate == currentTimestamp()) {
            return borrowIndex;
        }

        borrowIndex = currentBorrowIndex();
        indexLastUpdate = currentTimestamp();

        emit IndexUpdated(borrowIndex, indexLastUpdate);

        return borrowIndex;
    }

    /* ========== Public Getters ========== */

    function accumulatedInterest()
        public
        view
        returns (uint256)
    {
        return interestRate * (currentTimestamp() - indexLastUpdate);
    }

    function currentBorrowIndex()
        public
        view
        returns (uint256)
    {
        return borrowIndex * accumulatedInterest() / BASE + borrowIndex;
    }

    function getProofProtocol(uint8 index)
        external
        view
        returns (string memory)
    {
        return _scoreProtocols[index].toString();
    }

    function getSupportedBorrowAssets()
        external
        view
        returns (address[] memory)
    {
        return ISapphirePool(borrowPool).getDepositAssets();
    }

    /**
     * @dev Check if the vault is collateralized or not
     *
     * @param _owner The owner of the vault
     * @param _currentPrice The current price of the collateral
     * @param _assessedCRatio The assessed collateral ratio of the owner
     */
    function isCollateralized(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio
    )
        public
        view
        returns (bool)
    {
        SapphireTypes.Vault memory vault = vaults[_owner];

        if (
            vault.normalizedBorrowedAmount == 0 ||
            vault.collateralAmount == 0
        ) {
            return true;
        }

        uint256 currentCRatio = calculateCollateralRatio(
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.collateralAmount,
            _currentPrice
        );

        return currentCRatio >= _assessedCRatio;
    }

    /* ========== Developer Functions ========== */

    /**
     * @dev Returns current block's timestamp
     *
     * @notice This function is introduced in order to properly test time delays in this contract
     */
    function currentTimestamp()
        public
        virtual
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Calculate how much collateralRatio you would have
     *      with a certain borrow and collateral amount
     *
     * @param _denormalizedBorrowAmount The denormalized borrow amount (NOT principal)
     * @param _collateralAmount The amount of collateral, in its original decimals
     * @param _collateralPrice What price do you want to calculate the inverse at
     * @return                  The calculated c-ratio
     */
    function calculateCollateralRatio(
        uint256 _denormalizedBorrowAmount,
        uint256 _collateralAmount,
        uint256 _collateralPrice
    )
        public
        view
        returns (uint256)
    {
        return _collateralAmount *
             precisionScalars[collateralAsset] *
            _collateralPrice /
            _denormalizedBorrowAmount;
    }

    /* ========== Private Functions ========== */

    /**
     * @dev Normalize the given borrow amount by dividing it with the borrow index.
     *      It is used when manipulating with other borrow values
     *      in order to take in account current borrowIndex.
     */
    function _normalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        uint256 currentBIndex = currentBorrowIndex();

        if (_roundUp) {
            return Math.roundUpDiv(_amount, currentBIndex);
        }

        return _amount * BASE / currentBIndex;
    }

    /**
     * @dev Multiply the given amount by the borrow index. Used to convert
     *      borrow amounts back to their real value.
     */
    function _denormalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        if (_roundUp) {
            return Math.roundUpMul(_amount, currentBorrowIndex());
        }

        return _amount * currentBorrowIndex() / BASE;
    }

    /**
     * @dev Deposits the collateral amount in the user's vault
     */
    function _deposit(
        uint256 _amount
    )
        private
    {
        // Record deposit
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        if (_amount == 0) {
            return;
        }

        vault.collateralAmount = vault.collateralAmount + _amount;

        // Execute transfer
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransferFrom(
            collateralAsset,
            msg.sender,
            address(this),
            _amount
        );

        emit Deposited(
            msg.sender,
            _amount,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Withdraw the collateral amount in the user's vault, then ensures
     *      the withdraw amount is not greater than the deposited collateral.
     *      Afterwards ensure that collateral limit is not smaller than returned
     *      from assessor one.
     */
    function _withdraw(
        uint256 _amount,
        uint256 _assessedCRatio,
        uint256 _collateralPrice
    )
        private
    {
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        require(
            vault.collateralAmount >= _amount,
            "SapphireCoreV1: cannot withdraw more collateral than the vault balance"
        );

        vault.collateralAmount = vault.collateralAmount - _amount;

        // if we don't have debt we can withdraw as much as we want.
        if (vault.normalizedBorrowedAmount > 0) {
            uint256 collateralRatio = calculateCollateralRatio(
                _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
                vault.collateralAmount,
                _collateralPrice
            );

            require(
                collateralRatio >= _assessedCRatio,
                "SapphireCoreV1: the vault will become undercollateralized"
            );
        }

        // Execute transfer
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransfer(collateralAsset, msg.sender, _amount);

        emit Withdrawn(
            msg.sender,
            _amount,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Borrows the given borrow assets against the user's vault. It ensures the vault
     *      still maintains the required collateral ratio
     *
     * @param _amount               The amount of stablecoins to borrow
     * @param _borrowAssetAddress   The address of the stablecoin token to borrow
     * @param _assessedCRatio       The assessed c-ratio for user's credit score
     * @param _collateralPrice      The current collateral price
     */
    function _borrow(
        uint256 _amount,
        address _borrowAssetAddress,
        uint256 _assessedCRatio,
        uint256 _collateralPrice,
        SapphireTypes.ScoreProof memory _borrowLimitProof
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        require(
            _borrowLimitProof.account == msg.sender ||
            _borrowLimitProof.account == address(0),
            "SapphireCoreV1: proof.account must match msg.sender"
        );

        require(
            _borrowLimitProof.protocol == _scoreProtocols[1],
            "SapphireCoreV1: incorrect borrow limit proof protocol"
        );

        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        uint256 actualVaultBorrowAmount = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        uint256 scaledAmount = _amount * precisionScalars[_borrowAssetAddress];

        // Calculate new actual vault borrow amount with the added borrow fee
        uint256 _newActualVaultBorrowAmount = actualVaultBorrowAmount + scaledAmount;

        // Ensure the vault is collateralized if the borrow action succeeds
        uint256 collateralRatio = calculateCollateralRatio(
            _newActualVaultBorrowAmount,
            vault.collateralAmount,
            _collateralPrice
        );

        require(
            collateralRatio >= _assessedCRatio,
            "SapphireCoreV1: the vault will become undercollateralized"
        );

        if (_newActualVaultBorrowAmount > defaultBorrowLimit) {
            require(
                assessor.assessBorrowLimit(_newActualVaultBorrowAmount, _borrowLimitProof),
                "SapphireCoreV1: total borrow amount should not exceed borrow limit"
            );
        }

        // Calculate new normalized vault borrow amount, including the borrow fee, if any
        uint256 _newNormalizedVaultBorrowAmount;
        if (borrowFee > 0) {
            _newNormalizedVaultBorrowAmount = _normalizeBorrowAmount(
                _newActualVaultBorrowAmount + Math.roundUpMul(scaledAmount, borrowFee),
                true
            );
        } else {
            _newNormalizedVaultBorrowAmount = _normalizeBorrowAmount(
                _newActualVaultBorrowAmount,
                true
            );
        }

        // Record borrow amount (update vault and total amount)
        normalizedTotalBorrowed = normalizedTotalBorrowed -
            vault.normalizedBorrowedAmount +
            _newNormalizedVaultBorrowAmount;

        vault.normalizedBorrowedAmount = _newNormalizedVaultBorrowAmount;
        vault.principal = vault.principal + scaledAmount;

        // Do not borrow more than the maximum vault borrow amount
        require(
            _newActualVaultBorrowAmount <= vaultBorrowMaximum,
            "SapphireCoreV1: borrowed amount cannot be greater than vault limit"
        );

        // Do not borrow if amount is smaller than limit
        require(
            _newActualVaultBorrowAmount >= vaultBorrowMinimum,
            "SapphireCoreV1: borrowed amount cannot be less than limit"
        );

        // Borrow stablecoins from pool
        ISapphirePool(borrowPool).borrow(
            _borrowAssetAddress,
            scaledAmount,
            msg.sender
        );

        emit Borrowed(
            msg.sender,
            _amount,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Repays the given `_amount` of the stablecoin
     *
     * @param _owner The owner of the vault
     * @param _repayer The person who repays the debt
     * @param _amountScaled The amount to repay, denominated in the decimals of the borrow asset
     * @param _borrowAssetAddress The address of token to repay
     * @param _isLiquidation Indicates if it should clean the remaining debt after repayment
     */
    function _repay(
        address _owner,
        address _repayer,
        uint256 _amountScaled,
        address _borrowAssetAddress,
        bool _isLiquidation
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        require (
            ISapphirePool(borrowPool)
                .assetDepositUtilization(_borrowAssetAddress)
                .limit > 0,
            "SapphireCoreV1: not an approved asset"
        );
        
        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[_owner];

        // Calculate actual vault borrow amount
        uint256 actualVaultBorrowAmountScaled = _denormalizeBorrowAmount(
            vault.normalizedBorrowedAmount,
            true
        ) / precisionScalars[_borrowAssetAddress];

        require(
            _amountScaled <= actualVaultBorrowAmountScaled,
            "SapphireCoreV1: there is not enough debt to repay"
        );

        uint256 _interestScaled = (
            actualVaultBorrowAmountScaled -
            vault.principal / precisionScalars[_borrowAssetAddress]
        );

        uint256 _feeCollectorFeesScaled;
        uint256 _poolFeesScaled;
        uint256 _principalPaidScaled;
        uint256 _stablesLentDecreaseAmt;

        // Calculate new vault's borrowed amount
        uint256 _newNormalizedBorrowAmount = _normalizeBorrowAmount(
            (actualVaultBorrowAmountScaled - _amountScaled) * precisionScalars[_borrowAssetAddress],
            true
        );

        // Update principal
        if(_amountScaled > _interestScaled) {
            _poolFeesScaled = Math.roundUpMul(_interestScaled, poolInterestFee);
            _feeCollectorFeesScaled = _interestScaled - _poolFeesScaled;

            // User repays the entire interest and some (or all) principal
            _principalPaidScaled = _amountScaled - _interestScaled;
            vault.principal = vault.principal -
                _principalPaidScaled * precisionScalars[_borrowAssetAddress];
        } else {
            // Only interest is paid
            _poolFeesScaled = Math.roundUpMul(_amountScaled, poolInterestFee);
            _feeCollectorFeesScaled = _amountScaled - _poolFeesScaled;
        }

        // Update vault's borrowed amounts and clean debt if requested
        if (_isLiquidation) {
            normalizedTotalBorrowed -= vault.normalizedBorrowedAmount;
            _stablesLentDecreaseAmt = (actualVaultBorrowAmountScaled - _amountScaled) *
                precisionScalars[_borrowAssetAddress];

            // Can only decrease by the amount borrowed
            if (_stablesLentDecreaseAmt > vault.principal) {
                _stablesLentDecreaseAmt = vault.principal;
            }

            vault.principal = 0;
            vault.normalizedBorrowedAmount = 0;
        } else {
            normalizedTotalBorrowed = normalizedTotalBorrowed -
                vault.normalizedBorrowedAmount +
                _newNormalizedBorrowAmount;
            vault.normalizedBorrowedAmount = _newNormalizedBorrowAmount;
        }

        // Transfer fees to pool and fee collector (if any)
        if (_interestScaled > 0) {
            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                borrowPool,
                _poolFeesScaled
            );

            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                feeCollector,
                _feeCollectorFeesScaled
            );
        }

        // Swap the principal paid back into the borrow pool
        if (_principalPaidScaled > 0) {
            // Transfer tokens to the core
            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                address(this),
                _principalPaidScaled
            );

            SafeERC20.safeApprove(
                IERC20Metadata(_borrowAssetAddress),
                borrowPool,
                _principalPaidScaled
            );

            // Repay stables to pool
            ISapphirePool(borrowPool).repay(
                _borrowAssetAddress,
                _principalPaidScaled
            );
        }

        // Clean the remaining debt if requested
        if (_stablesLentDecreaseAmt > 0) {
            ISapphirePool(borrowPool).decreaseStablesLent(_stablesLentDecreaseAmt);
        }

        emit Repaid(
            _owner,
            _repayer,
            _amountScaled,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    function _liquidate(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio,
        address _borrowAssetAddress
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        // CHECKS:
        // 1. Ensure that the position is valid (check if there is a non-0x0 owner)
        // 2. Ensure that the position is indeed undercollateralized

        // EFFECTS:
        // 1. Calculate the liquidation price based on the liquidation penalty
        // 2. Calculate the amount of collateral to be sold based on the entire debt
        //    in the vault
        // 3. If the discounted collateral is more than the amount in the vault, limit
        //    the sale to that amount
        // 4. Decrease the owner's debt
        // 5. Decrease the owner's collateral

        // INTEGRATIONS
        // 1. Transfer the debt to pay from the liquidator to the pool
        // 2. Transfer the user portion of the collateral sold to the msg.sender
        // 3. Transfer Arc's portion of the profit to the fee collector
        // 4. If there is bad debt, make LPs pay for it by reducing the stablesLent on the pool
        //    by the amount of the bad debt.

        // --- CHECKS ---

        require(
            _owner != address(0),
            "SapphireCoreV1: position owner cannot be address 0"
        );

        SapphireTypes.Vault storage vault = vaults[_owner];
        // Use struct to go around the stack too deep error
        LiquidationVars memory vars;

        // Ensure that the vault is not collateralized
        require(
            !isCollateralized(
                _owner,
                _currentPrice,
                _assessedCRatio
            ),
            "SapphireCoreV1: vault is collateralized"
        );

        // --- EFFECTS ---

        // Get the liquidation price of the asset (discount for liquidator)
        vars.liquidationPrice = Math.roundUpMul(_currentPrice, BASE - liquidatorDiscount);

        // Calculate the amount of collateral to be sold based on the entire debt
        // in the vault
        vars.debtToRepay = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        vars.collateralPrecisionScalar = precisionScalars[collateralAsset];
        // Do a rounded up operation of
        // debtToRepay / LiquidationFee / collateralPrecisionScalar
        vars.collateralToSell = (
            Math.roundUpDiv(vars.debtToRepay, vars.liquidationPrice) + vars.collateralPrecisionScalar - 1
        ) / vars.collateralPrecisionScalar;

        // If the discounted collateral is more than the amount in the vault, limit
        // the sale to that amount
        if (vars.collateralToSell > vault.collateralAmount) {
            vars.collateralToSell = vault.collateralAmount;
            // Calculate the new debt to repay
            vars.debtToRepay = vars.collateralToSell * vars.collateralPrecisionScalar * vars.liquidationPrice / BASE;
        }

        // Calculate the profit made in USD
        vars.valueCollateralSold = vars.collateralToSell *
            vars.collateralPrecisionScalar *
            _currentPrice /
            BASE;

        // Total profit in dollar amount
        vars.profit = vars.valueCollateralSold - vars.debtToRepay;

        // Calculate the ARC share
        vars.arcShare = vars.profit *
            liquidationArcFee /
            vars.liquidationPrice /
            vars.collateralPrecisionScalar;

        // Calculate liquidator's share
        vars.liquidatorCollateralShare = vars.collateralToSell - vars.arcShare;

        // Update owner's vault
        vault.collateralAmount = vault.collateralAmount - vars.collateralToSell;

        // --- INTEGRATIONS ---

        // Repay the debt
        _repay(
            _owner,
            msg.sender,
            vars.debtToRepay / precisionScalars[_borrowAssetAddress],
            _borrowAssetAddress,
            true
        );

        // Transfer user collateral
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransfer(
            collateralAsset,
            msg.sender,
            vars.liquidatorCollateralShare
        );

        // Transfer Arc's share of collateral
        SafeERC20.safeTransfer(
            collateralAsset,
            feeCollector,
            vars.arcShare
        );

        emit Liquidated(
            _owner,
            msg.sender,
            _currentPrice,
            _assessedCRatio,
            vars.collateralToSell,
            vars.debtToRepay,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Gets the required variables for the actions passed, if needed. The credit score
     *      will be assessed if there is at least one action. The oracle price will only be
     *      fetched if there is at least one borrow or liquidate actions.
     *
     * @param _actions      the actions that are about to be ran
     * @param _scoreProof   the credit score proof
     * @return              the assessed c-ratio and the current collateral price
     */
    function _getVariablesForActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        private
        returns (uint256, uint256)
    {
        uint256 assessedCRatio;
        uint256 collateralPrice;
        uint256 collateralPriceTimestamp;

        bool mandatoryProof = false;
        bool needsCollateralPrice = false;

        // Check if the score proof has an address. If it's address zero,
        // replace it with msg.sender. This is to prevent users from borrowing
        // after having already registered a score on chain

        if (_scoreProof.account == address(0)) {
            _scoreProof.account = msg.sender;
        }

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            /**
            * Ensure the credit score proof refers to the correct account given
            * the action.
            */
            if (
                action.operation == SapphireTypes.Operation.Deposit ||
                action.operation == SapphireTypes.Operation.Withdraw ||
                action.operation == SapphireTypes.Operation.Borrow
            ) {
                require(
                    _scoreProof.account == msg.sender,
                    "SapphireCoreV1: proof.account must match msg.sender"
                );

                if (
                    action.operation == SapphireTypes.Operation.Borrow ||
                    action.operation == SapphireTypes.Operation.Withdraw
                ) {
                    needsCollateralPrice = true;
                }

            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
               require(
                    _scoreProof.account == action.userToLiquidate,
                    "SapphireCoreV1: proof.account does not match the user to liquidate"
                );

                needsCollateralPrice = true;

                // If the effective passport epoch of the user to liquidate is gte to the
                // current epoch, then the proof is mandatory. Otherwise, will assume the
                // high c-ratio
                (, uint256 currentEpoch) = _getPassportAndEpoch();
                if (currentEpoch >= expectedEpochWithProof[action.userToLiquidate]) {
                    mandatoryProof = true;
                }

            }
        }

        if (needsCollateralPrice) {
            require(
                address(oracle) != address(0),
                "SapphireCoreV1: the oracle is not set"
            );

            // Collateral price denominated in 18 decimals
            (collateralPrice, collateralPriceTimestamp) = oracle.fetchCurrentPrice();

            require(
                _isOracleNotOutdated(collateralPriceTimestamp),
                "SapphireCoreV1: the oracle has stale prices"
            );

            require(
                collateralPrice > 0,
                "SapphireCoreV1: the oracle returned a price of 0"
            );
        }

        // Set the effective epoch of the caller if it's not set yet
        _setEffectiveEpoch(_scoreProof);

        if (address(assessor) == address(0) || _actions.length == 0) {
            assessedCRatio = highCollateralRatio;
        } else {
            assessedCRatio = assessor.assess(
                lowCollateralRatio,
                highCollateralRatio,
                _scoreProof,
                mandatoryProof
            );
        }

        return (assessedCRatio, collateralPrice);
    }

    function _setFees(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    )
        private
    {
        require(
            _liquidatorDiscount <= BASE &&
            _liquidationArcFee <= BASE,
            "SapphireCoreV1: fees cannot be more than 100%"
        );

        require(
            _liquidatorDiscount <= BASE &&
            _poolInterestFee <= BASE &&
            _liquidationArcFee <= BASE,
            "SapphireCoreV1: invalid fees"
        );

        liquidatorDiscount = _liquidatorDiscount;
        liquidationArcFee = _liquidationArcFee;
        borrowFee = _borrowFee;
        poolInterestFee = _poolInterestFee;

        emit FeesUpdated(
            liquidatorDiscount,
            liquidationArcFee,
            _borrowFee,
            _poolInterestFee
        );
    }

    /**
     * @dev Returns true if oracle is not outdated
     */
    function _isOracleNotOutdated(
        uint256 _oracleTimestamp
    )
        internal
        virtual
        view
        returns (bool)
    {
        return _oracleTimestamp >= currentTimestamp() - 60 * 60 * 12;
    }

    /**
     * @dev Saves the token's precision scalar, if it doesn't exist in the mapping.
     */
    function _savePrecisionScalar(
        address _tokenAddress
    )
        internal
    {
        if (_tokenAddress != address(0) && precisionScalars[_tokenAddress] == 0) {
            uint8 tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
            require(
                tokenDecimals <= 18,
                "SapphireCoreV1: token has more than 18 decimals"
            );

            precisionScalars[_tokenAddress] = 10 ** (18 - uint256(tokenDecimals));
        }
    }

    /**
     * @dev Set the effective epoch of the caller if it's not set yet
     */
    function _setEffectiveEpoch(
        SapphireTypes.ScoreProof memory _scoreProof
    )
        private
    {
        (
            ISapphirePassportScores passportScores,
            uint256 currentEpoch
        ) = _getPassportAndEpoch();

        if (_scoreProof.merkleProof.length == 0) {
            // Proof is not passed. If the proof's owner has no expected epoch, set it to the next 2
            if (expectedEpochWithProof[_scoreProof.account] == 0) {
                expectedEpochWithProof[_scoreProof.account] = currentEpoch + 2;
            }
        } else {
            // Proof is passed, expected epoch for proof's account is not set yet
            require(
                passportScores.verify(_scoreProof),
                "SapphireCoreV1: invalid proof"
            );

            if (
                expectedEpochWithProof[_scoreProof.account] == 0 ||
                expectedEpochWithProof[_scoreProof.account] > currentEpoch
            ) {
                // Owner has a valid proof, so will enforce liquidations to pass a proof for this
                // user from now on
                expectedEpochWithProof[_scoreProof.account] = currentEpoch;
            }
        }
    }

    function _getPassportAndEpoch()
        private
        view
        returns (ISapphirePassportScores, uint256)
    {
        ISapphirePassportScores passportScores = ISapphirePassportScores(
            assessor.getPassportScoresContract()
        );

        return (passportScores, passportScores.currentEpoch());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20Metadata} from "./IERC20Metadata.sol";
import {Permittable} from "./Permittable.sol";

/**
 * @title ERC20 Token
 *
 * Basic ERC20 Implementation
 */
contract BaseERC20 is IERC20Metadata, Permittable {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint8   internal _decimals;
    uint256 private _totalSupply;

    string  internal _name;
    string  internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (
        string memory name_,
        string memory symbol_,
        uint8         decimals_
    )
        Permittable(name_, "1")
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name()
        public
        override
        view
        returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()
        public
        override
        view
        returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals()
        public
        override
        view
        returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    )
        public
        override
        view
        returns (uint256)
    {
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
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        override
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    )
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender] - amount
        );

        return true;
    }

    /**
    * @dev Approve by signature.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
    {
        _permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
        _approve(owner, spender, value);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    )
        internal
        virtual
    {
        require(
            sender != address(0),
            "ERC20: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
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
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from "./IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    uint256 public constant BASE = 10**18;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target * numerator / denominator;
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * BASE + b - 1) / b;
    }

    /**
     * @dev Performs a * b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * b + BASE - 1) / BASE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Storage } from "./Storage.sol";

/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Bytes32 {

    function toString(
        bytes32 _bytes
    )
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes[i] != 0; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line
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

pragma solidity 0.8.4;

interface ISapphireOracle {

    /**
     * @notice Fetches the current price of the asset
     *
     * @return price The price in 18 decimals
     * @return timestamp The timestamp when price is updated and the decimals of the asset
     */
    function fetchCurrentPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 normalizedBorrowedAmount;
        uint256 principal;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        address borrowAssetAddress;
        Operation operation;
        address userToLiquidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

import {SapphireTypes} from "./SapphireTypes.sol";

 // solhint-disable max-states-count

contract SapphireCoreStorageV1 {

    /* ========== Constants ========== */

    uint256 public constant BASE = 10**18;

    /* ========== Public Variables ========== */

    /**
     * @notice Determines whether the contract is paused or not
     */
    bool public paused;

    /**
     * @notice The details about a vault, identified by the address of the owner
     */
    mapping (address => SapphireTypes.Vault) public vaults;

    /**
    * @notice The high/default collateral ratio for an untrusted borrower.
    */
    uint256 public highCollateralRatio;

    /**
    * @notice The lowest collateral ratio for an untrusted borrower.
    */
    uint256 public lowCollateralRatio;

    /**
     * @notice How much should the liquidation penalty be, expressed as a percentage
     *      with 18 decimals
     */
    uint256 public liquidatorDiscount;

    /**
     * @notice How much of the profit acquired from a liquidation should ARC receive
     */
    uint256 public liquidationArcFee;

    /**
     * @notice The percentage fee that is added as interest for each loan
     */
    uint256 public borrowFee;

    /**
    * @notice The assessor that will determine the collateral-ratio.
    */
    ISapphireAssessor public assessor;

    /**
    * @notice The address which collects fees when liquidations occur.
    */
    address public feeCollector;

    /**
     * @notice The instance of the oracle that reports prices for the collateral
     */
    ISapphireOracle public oracle;

    /**
     * @notice If a erc20 asset is used that has less than 18 decimal places
     *      a precision scalar is required to calculate the correct values.
     */
    mapping(address => uint256) public precisionScalars;

    /**
     * @notice The actual address of the collateral used for this core system.
     */
    address public collateralAsset;

    /**
     * @notice The address of the SapphirePool - the contract where the borrowed tokens come from
     */
    address public borrowPool;

    /**
    * @notice The actual amount of collateral provided to the protocol.
    *      This amount will be multiplied by the precision scalar if the token
    *      has less than 18 decimals precision.
    *
    * Proxy upgrade: restricting this variable as it was not used, and its calculation was incorrect
    */
    uint256 private totalCollateral;

    /**
     * @notice An account of the total amount being borrowed by all depositors. This includes
     *      the amount of interest accrued.
     */
    uint256 public normalizedTotalBorrowed;

    /**
     * @notice The accumulated borrow index. Each time a borrows, their borrow amount is expressed
     *      in relation to the borrow index.
     */
    uint256 public borrowIndex;

    /**
     * @notice The last time the updateIndex() function was called. This helps to determine how much
     *      interest has accrued in the contract since a user interacted with the protocol.
     */
    uint256 public indexLastUpdate;

    /**
     * @notice The interest rate charged to borrowers. Expressed as the interest rate per second and 18 d.p
     */
    uint256 public interestRate;

    /**
     * @notice Ratio determining the portion of the interest that is being distributed to the
     * borrow pool. The remaining of the pool share will go to the feeCollector.
     */
    uint256 public poolInterestFee;

    /**
     * @notice Which address can set interest rates for this contract
     */
    address public interestSetter;

    /**
     * @notice The address that can call `setPause()`
     */
    address public pauseOperator;

    /**
     * @notice The minimum amount which has to be borrowed by a vault. This includes
     *         the amount of interest accrued.
     */
    uint256 public vaultBorrowMinimum;

    /**
     * @notice The maximum amount which has to be borrowed by a vault. This includes
     *      the amount of interest accrued.
     */
    uint256 public vaultBorrowMaximum;

    /**
     * @notice The default borrow limit to be used if a borrow limit proof is not passed
     * in the borrow action. If it is set to 0, then a borrow limit proof is required.
     */
    uint256 public defaultBorrowLimit;

    /**
     * @notice Stores the epoch (of the vault owner) at which it becomes required 
     * for the liquidator to include their score proof
     */
    mapping (address => uint256) public expectedEpochWithProof;

    /* ========== Internal Variables ========== */

    /**
     * @dev The array with protocols' values
     *      Index 0 - The protocol value to be used in the credit score proofs
     *      Index 1 - The protocol value to be used in the borrow limit proofs
     */
    bytes32[] internal _scoreProtocols;
}

// solhint-disable-next-line no-empty-blocks
contract SapphireCoreStorage is SapphireCoreStorageV1 {}

// SPDX-License-Identifier: MIT
// prettier-ignore

pragma solidity 0.8.4;

import {Ownable} from "../lib/Ownable.sol";
import {Address} from "../lib/Address.sol";
import {PassportScoreVerifiable} from "../lib/PassportScoreVerifiable.sol";
import {SapphireTypes} from "./SapphireTypes.sol";
import {ISapphireMapper} from "./ISapphireMapper.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

contract SapphireAssessor is Ownable, ISapphireAssessor, PassportScoreVerifiable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Variables ========== */

    ISapphireMapper public mapper;

    uint16 public maxScore;

    /* ========== Events ========== */

    event MapperSet(address _newMapper);

    event PassportScoreContractSet(address _newCreditScoreContract);

    event MaxScoreSet(uint16 _maxScore);

    /* ========== Constructor ========== */

    constructor(
        address _mapper,
        address _passportScores,
        uint16 _maxScore
    ) {
        require(
            _mapper.isContract() &&
            _passportScores.isContract(),
            "SapphireAssessor: mapper and passport scores must be valid contracts"
        );

        mapper = ISapphireMapper(_mapper);
        passportScoresContract = ISapphirePassportScores(_passportScores);
        setMaxScore(_maxScore);
    }

    /* ========== View Functions ========== */

    function getPassportScoresContract() 
        external 
        view
        override
        returns (address)
    {
        return address(passportScoresContract);
    }
    
    /* ========== Public Functions ========== */

    /**
     * @notice  Takes a lower and upper bound, and based on the user's credit score
     *          and given its proof, returns the appropriate value between these bounds.
     *
     * @param _lowerBound       The lower bound
     * @param _upperBound       The upper bound
     * @param _scoreProof       The score proof
     * @param _isScoreRequired  The flag, which require the proof of score if the account already
                                has a score
     * @return A value between the lower and upper bounds depending on the credit score
     */
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired
    )
        external
        view
        override
        checkScoreProof(_scoreProof, _isScoreRequired, false)
        returns (uint256)
    {
        require(
            _upperBound > 0,
            "SapphireAssessor: The upper bound cannot be zero"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireAssessor: The lower bound must be smaller than the upper bound"
        );

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        // If the proof is passed, use the score from the score proof since at this point
        // the proof should be verified if the score is > 0
        uint256 result = mapper.map(
            isProofPassed ? _scoreProof.score : 0,
            maxScore,
            _lowerBound,
            _upperBound
        );

        require(
            result >= _lowerBound &&
            result <= _upperBound,
            "SapphireAssessor: The mapper returned a value out of bounds"
        );

        return result;
    }

    function assessBorrowLimit(
        uint256 _borrowAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        view
        override
        checkScoreProof(_borrowLimitProof, true, false)
        returns (bool)
    {

        require(
            _borrowAmount > 0,
            "SapphireAssessor: The borrow amount cannot be zero"
        );

        bool _isBorrowAmountValid = _borrowAmount <= _borrowLimitProof.score;

        return _isBorrowAmountValid;
    }

    function setMapper(
        address _mapper
    )
        external
        onlyOwner
    {
        require(
            _mapper.isContract(),
            "SapphireAssessor: _mapper is not a contract"
        );

        require(
            _mapper != address(mapper),
            "SapphireAssessor: The same mapper is already set"
        );

        mapper = ISapphireMapper(_mapper);

        emit MapperSet(_mapper);
    }

    function setPassportScoreContract(
        address _creditScore
    )
        external
        onlyOwner
    {
        require(
            _creditScore.isContract(),
            "SapphireAssessor: _creditScore is not a contract"
        );

        require(
            _creditScore != address(passportScoresContract),
            "SapphireAssessor: The same credit score contract is already set"
        );

        passportScoresContract = ISapphirePassportScores(_creditScore);

        emit PassportScoreContractSet(_creditScore);
    }

    function setMaxScore(
        uint16 _maxScore
    )
        public
        onlyOwner
    {
        require(
            _maxScore > 0,
            "SapphireAssessor: max score cannot be zero"
        );

        maxScore = _maxScore;

        emit MaxScoreSet(_maxScore);
    }

    function renounceOwnership()
        public
        view
        onlyOwner
        override
    {
        revert("SapphireAssessor: cannot renounce ownership");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphireAssessor {
    function getPassportScoresContract() external view returns (address);
    
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof calldata _scoreProof,
        bool _isScoreRequired
    )
        external
        returns (uint256);

    function assessBorrowLimit(
        uint256 _borrowedAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SharedPoolStructs} from "./SharedPoolStructs.sol";

interface ISapphirePool {
    /* ========== Mutating Functions ========== */

    function setCoreBorrowLimit(address _coreAddress, uint256 _limit) external;

    function setDepositLimit(address _tokenAddress, uint256 _limit) external;

    function borrow(
        address _stablecoinAddress, 
        uint256 _scaledBorrowAmount,
        address _receiver
    ) external;

    function repay(
        address _stablecoinAddress, 
        uint256 _repayAmount
    ) external;

    function deposit(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount, address _outToken) external;

    function decreaseStablesLent(uint256 _debtDecreaseAmount) external;

    /* ========== View Functions ========== */

    function accumulatedRewardAmount() external view returns (uint256);

    function coreBorrowUtilization(address _coreAddress) 
        external 
        view 
        returns (SharedPoolStructs.AssetUtilization memory);

    function assetDepositUtilization(address _tokenAddress) 
        external 
        view 
        returns (SharedPoolStructs.AssetUtilization memory);

    function deposits(address _userAddress) external view returns (uint256);

    function getDepositAssets() external view returns (address[] memory);

    function getActiveCores() external view returns (address[] memory);

    function getPoolValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function currentEpoch() external view returns (uint256);

    function rootsHistory(uint256 _epoch) external view returns (bytes32, uint256);

    function isPaused() external view returns (bool);

    function merkleRootDelayDuration() external view returns (uint256);

    function merkleRootUpdater() external view returns (address);
    
    function pauseOperator() external view returns (address);

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata _proof) external view returns(bool);
    
    function updateMerkleRoot(bytes32 _newRoot) external;

    function setMerkleRootUpdater(address _merkleRootUpdater) external;

    function setMerkleRootDelay(uint256 _delay) external;

    function setPause(bool _status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Permittable {

    /* ============ Variables ============ */

    // solhint-disable-next-line
    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public nonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* solhint-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    constructor(
        string memory name,
        string memory version
    ) {
        DOMAIN_SEPARATOR = _initDomainSeparator(name, version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _initDomainSeparator(
        string memory name,
        string memory version
    )
        internal
        view
        returns (bytes32)
    {
        uint256 chainID;
        /* solhint-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *      Caution: If an owner signs a permit with no deadline, the corresponding spender
    *      can call permit at any time in the future to mess with the nonce, invalidating
    *      signatures to other spenders, possibly making their transactions fail.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(
            deadline == 0 || deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    nonces[owner]++,
                    deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "Permittable: Signature invalid"
        );

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Address} from "./Address.sol";

import {ISapphirePassportScores} from "../sapphire/ISapphirePassportScores.sol";
import {SapphireTypes} from "../sapphire/SapphireTypes.sol";

/**
 * @dev Provides the ability of verifying users' credit scores
 */
contract PassportScoreVerifiable {

    using Address for address;

    ISapphirePassportScores public passportScoresContract;

    /**
     * @dev Verifies that the proof is passed if the score is required, and
     *      validates it.
     *      Additionally, it checks the proof validity if `scoreProof` has a score > 0
     */
    modifier checkScoreProof(
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired,
        bool _enforceSameCaller
    ) {
        if (_scoreProof.account != address(0) && _enforceSameCaller) {
            require (
                msg.sender == _scoreProof.account,
                "PassportScoreVerifiable: proof does not belong to the caller"
            );
        }

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        if (_isScoreRequired || isProofPassed || _scoreProof.score > 0) {
            passportScoresContract.verify(_scoreProof);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISapphireMapper {

    /**
     * @notice Maps the `_score` to a value situated between
     * the given lower and upper bounds
     *
     * @param _score The user's credit score to use for the mapping
     * @param _scoreMax The maximum value the score can be
     * @param _lowerBound The lower bound
     * @param _upperBound The upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SharedPoolStructs {
    struct AssetUtilization {
        uint256 amountUsed;
        uint256 limit;
    }
}