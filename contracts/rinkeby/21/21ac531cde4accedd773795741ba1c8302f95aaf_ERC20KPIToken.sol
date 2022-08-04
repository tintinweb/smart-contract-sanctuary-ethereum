pragma solidity 0.8.15;

import {IERC20Upgradeable, ERC20Upgradeable} from "oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "oz-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "oz-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IOraclesManager} from "../interfaces/IOraclesManager.sol";
import {IKPITokensManager} from "../interfaces/IKPITokensManager.sol";
import {IERC20KPIToken} from "../interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../commons/Types.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token template implementation
/// @dev A KPI token template imlementation. The template produces ERC20 tokens
/// that can be distributed arbitrarily to communities or specific entities in order
/// to incentivize them to reach certain KPIs. Backing these tokens there are potentially
/// a multitude of other ERC20 tokens (up to 5), the release of which is linked to
/// reaching the predetermined KPIs or not. In order to check if these KPIs are reached
/// on-chain, oracles oracles are employed, and based on the results conveyed back to
/// the KPI token template, the collaterals are either unlocked or sent back to the
/// original KPI token creator. Interesting logic is additionally tied to the conditions
/// and collaterals, such as the possibility to have a minimum payout (a per-collateral
/// sum that will always be paid out to KPI token holders regardless of the fact that
/// KPIs are reached or not), weighted KPIs and multiple detached resolution or all-in-one
/// reaching of KPIs (explained more in details later).
/// @author Federico Luzzi - <[email protected]>
contract ERC20KPIToken is
    ERC20Upgradeable,
    IERC20KPIToken,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant INVALID_ANSWER =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant MULTIPLIER = 64;

    bool internal allOrNone;
    uint16 internal toBeFinalized;
    address public creator;
    Collateral[] internal collaterals;
    FinalizableOracle[] internal finalizableOracles;
    string public description;
    uint256 public expiration;
    IKPITokensManager.Template internal kpiTokenTemplate;
    uint256 internal initialSupply;
    uint256 internal totalWeight;
    mapping(address => uint256) internal registeredBurn;
    mapping(address => uint256) internal postFinalizationCollateralAmount;
    mapping(address => mapping(address => uint256))
        internal redeemedCollateralOf;

    error Forbidden();
    error NotInitialized();
    error InvalidCollateral();
    error InvalidFeeReceiver();
    error InvalidOraclesManager();
    error InvalidOracleBounds();
    error InvalidOracleWeights();
    error InvalidExpiration();
    error InvalidDescription();
    error TooManyCollaterals();
    error TooManyOracles();
    error InvalidName();
    error InvalidSymbol();
    error InvalidTotalSupply();
    error InvalidCreator();
    error InvalidKpiTokensManager();
    error InvalidMinimumPayoutAfterFee();
    error DuplicatedCollateral();
    error NoOracles();
    error NoCollaterals();
    error NothingToRedeem();
    error ZeroAddressToken();
    error ZeroAddressReceiver();
    error NothingToRecover();

    event Initialize(
        address indexed creator,
        uint256 indexed templateId,
        string description,
        uint256 expiration,
        bytes kpiTokenData,
        bytes oraclesData
    );
    event InitializeOracles(FinalizableOracle[] finalizableOracles);
    event CollectProtocolFees(
        TokenAmount[] collected,
        address indexed _receiver
    );
    event Finalize(address indexed oracle, uint256 result);
    event RecoverERC20(
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    event Redeem(
        address indexed account,
        uint256 burned,
        RedeemedCollateral[] redeemed
    );
    event RegisterRedemption(address indexed account, uint256 burned);
    event RedeemCollateral(
        address indexed account,
        address indexed receiver,
        address collateral,
        uint256 amount
    );

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the factory,
    /// in turn invoked by a KPI token creator.
    /// @param _creator Since the factory is assumed to be the caller of this function,
    /// it must forward the original caller (msg.sender, the KPI token creator) here.
    /// @param _kpiTokensManager The factory-forwarded address of the KPI tokens manager.
    /// @param _oraclesManager The factory-forwarded address of the oracles manager.
    /// @param _feeReceiver The factory-forwarded address of the fee receiver.
    /// @param _kpiTokenTemplateId The id of the template.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the
    /// @param _expiration A timestamp determining the expiration date of the KPI token (the
    /// expiration date is used to avoid a malicious/unresponsive oracle from locking up the
    /// funds and should be set accordingly).
    /// @param _kpiTokenData An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the ERC20 KPI token template.
    /// In particular the structure is formed in the following way:
    /// - `Collateral[] memory _collaterals`: an array of `Collateral` structs conveying
    ///   information about the collaterals to be used (a limit of maximum 5 different
    ///   collateral is enforced, and duplicates are not allowed).
    /// - `string memory _erc20Name`: The `name` of the created ERC20 token.
    /// - `string memory _erc20Symbol`: The `symbol` of the created ERC20 token.
    /// - `string memory _erc20Supply`: The initial supply of the created ERC20 token.
    /// @param _oraclesData An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the chosen oracle templates.
    /// In particular the structure is formed in the following way:
    /// - `OracleData[] memory _oracleDatas`: data about the oracle, such as:
    ///     - `uint256 _templateId`: The id of the chosed oracle template.
    ///     - `uint256 _lowerBound`: The number at which the oracle's reported result is
    ///       interpreted in a failed KPI (not reached). If the oracle linked to this lower
    ///       bound reports a final number above this, we know the KPI is at least partially
    ///       reached.
    ///     - `uint256 _higherBound`: The number at which the oracle's reported result
    ///       is interpreted in a full verification of the KPI (fully reached). If the
    ///       oracle linked to this higher bound reports a final number equal or greater
    ///       than this, we know the KPI has fully been reached.
    ///     - `uint256 _weight`: The KPI weight determines the importance of it and how
    ///       much of the collateral a specific KPI "governs". If for example we have 2
    ///       KPIs A and B with respective weights 1 and 2, a third of the deposited
    ///       collaterals goes towards incentivizing A, while the remaining 2/3rds go
    ///       to B (i.e. B is valued as a more critical KPI to reach compared to A, and
    ///       collaterals reflect this).
    ///     - `uint256 _data`: ABI-encoded, oracle-specific data used to effectively
    ///       instantiate the oracle in charge of monitoring this KPI and reporting the
    ///       final result on-chain.
    /// - `bool _allOrNone`: Whether all KPIs should be at least partly reached in
    ///   order to unlock collaterals for KPI token holders to redeem (minus the minimum
    ///   payout amount, which is unlocked under any circumstance).
    function initialize(
        address _creator,
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _kpiTokenData,
        bytes memory _oraclesData
    ) external payable override initializer {
        initializeState(
            _creator,
            _kpiTokensManager,
            _kpiTokenTemplateId,
            _description,
            _expiration,
            _kpiTokenData
        );

        (Collateral[] memory _collaterals, , , ) = abi.decode(
            _kpiTokenData,
            (Collateral[], string, string, uint256)
        );

        collectCollateralsAndFees(_creator, _collaterals, _feeReceiver);
        initializeOracles(_creator, _oraclesManager, _oraclesData);

        emit Initialize(
            _creator,
            _kpiTokenTemplateId,
            _description,
            _expiration,
            _kpiTokenData,
            _oraclesData
        );
    }

    /// @dev Utility function used to perform checks and partially initialize the state
    /// of the KPI token. This is only invoked by the more generic `initialize` function.
    /// @param _creator Since the factory is assumed to be the caller of this function,
    /// it must forward the original caller (msg.sender, the KPI token creator) here.
    /// @param _kpiTokensManager The factory-forwarded address of the KPI tokens manager.
    /// @param _kpiTokenTemplateId The id of the template.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the
    /// @param _expiration A timestamp determining the expiration date of the KPI token (the
    /// @param _data ABI-encoded data used to configura the KPI token (see the doc of the
    /// `initialize` function for more on this).
    function initializeState(
        address _creator,
        address _kpiTokensManager,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _data
    ) internal onlyInitializing {
        if (_creator == address(0)) revert InvalidCreator();
        if (_kpiTokensManager == address(0)) revert InvalidKpiTokensManager();
        if (bytes(_description).length == 0) revert InvalidDescription();
        if (_expiration <= block.timestamp) revert InvalidExpiration();

        (
            ,
            string memory _erc20Name,
            string memory _erc20Symbol,
            uint256 _erc20Supply
        ) = abi.decode(_data, (Collateral[], string, string, uint256));

        if (bytes(_erc20Name).length == 0) revert InvalidName();
        if (bytes(_erc20Symbol).length == 0) revert InvalidSymbol();
        if (_erc20Supply == 0) revert InvalidTotalSupply();

        __ReentrancyGuard_init();
        __ERC20_init(_erc20Name, _erc20Symbol);
        _mint(_creator, _erc20Supply);

        initialSupply = _erc20Supply;
        creator = _creator;
        description = _description;
        expiration = _expiration;
        kpiTokenTemplate = IKPITokensManager(_kpiTokensManager).template(
            _kpiTokenTemplateId
        );
    }

    /// @dev Utility function used to collect collateral and fees from the KPI token
    /// creator. This is only invoked by the more generic `initialize` function.
    /// @param _creator The KPI token creator.
    /// @param _collaterals The collaterals array as taken from the ABI-encoded data
    /// passed in by the KPI token creator.
    /// @param _feeReceiver The factory-forwarded address of the fee receiver.
    function collectCollateralsAndFees(
        address _creator,
        Collateral[] memory _collaterals,
        address _feeReceiver
    ) internal onlyInitializing {
        if (_collaterals.length == 0) revert NoCollaterals();
        if (_collaterals.length > 5) revert TooManyCollaterals();
        if (_feeReceiver == address(0)) revert InvalidFeeReceiver();

        TokenAmount[] memory _collectedFees = new TokenAmount[](
            _collaterals.length
        );
        for (uint8 _i = 0; _i < _collaterals.length; _i++) {
            Collateral memory _collateral = _collaterals[_i];
            uint256 _collateralAmountBeforeFee = _collateral.amount;
            if (
                _collateral.token == address(0) ||
                _collateralAmountBeforeFee == 0 ||
                _collateral.minimumPayout >= _collateralAmountBeforeFee
            ) revert InvalidCollateral();
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
            uint256 _fee = calculateProtocolFee(_collateralAmountBeforeFee);
            uint256 _amountMinusFees;
            unchecked {
                _amountMinusFees = _collateralAmountBeforeFee - _fee;
            }
            if (_amountMinusFees <= _collateral.minimumPayout)
                revert InvalidMinimumPayoutAfterFee();
            unchecked {
                _collateral.amount = _amountMinusFees;
            }
            collaterals.push(_collateral);
            IERC20Upgradeable(_collateral.token).safeTransferFrom(
                _creator,
                address(this),
                _collateralAmountBeforeFee
            );
            if (_fee > 0) {
                IERC20Upgradeable(_collateral.token).safeTransfer(
                    _feeReceiver,
                    _fee
                );
            }
            _collectedFees[_i] = TokenAmount({
                token: _collateral.token,
                amount: _fee
            });
        }

        emit CollectProtocolFees(_collectedFees, _feeReceiver);
    }

    /// @dev Initializes the oracles tied to this KPI token (both the actual oracle
    /// instantiation and configuration data needed to interpret the relayed result
    /// at the KPI-token level). This function is only invoked by the `initialize` function.
    /// @param _creator The KPI token creator.
    /// @param _oraclesManager The address of the oracles manager, used to instantiate
    /// the oracles.
    /// @param _data ABI-encoded data used to create and configura the oracles (see
    /// the doc of the `initialize` function for more on this).
    function initializeOracles(
        address _creator,
        address _oraclesManager,
        bytes memory _data
    ) internal onlyInitializing {
        if (_oraclesManager == address(0)) revert InvalidOraclesManager();

        (OracleData[] memory _oracleDatas, bool _allOrNone) = abi.decode(
            _data,
            (OracleData[], bool)
        );

        if (_oracleDatas.length == 0) revert NoOracles();
        if (_oracleDatas.length > 5) revert TooManyOracles();

        FinalizableOracle[]
            memory _finalizableOracles = new FinalizableOracle[](
                _oracleDatas.length
            );
        for (uint16 _i = 0; _i < _oracleDatas.length; _i++) {
            OracleData memory _oracleData = _oracleDatas[_i];
            if (_oracleData.higherBound <= _oracleData.lowerBound)
                revert InvalidOracleBounds();
            if (_oracleData.weight == 0) revert InvalidOracleWeights();
            totalWeight += _oracleData.weight;
            address _instance = IOraclesManager(_oraclesManager).instantiate{
                value: _oracleData.value
            }(_creator, _oracleData.templateId, _oracleData.data);
            FinalizableOracle memory _finalizableOracle = FinalizableOracle({
                addrezz: _instance,
                lowerBound: _oracleData.lowerBound,
                higherBound: _oracleData.higherBound,
                finalResult: 0,
                weight: _oracleData.weight,
                finalized: false
            });
            _finalizableOracles[_i] = _finalizableOracle;
            finalizableOracles.push(_finalizableOracle);
        }

        toBeFinalized = uint16(_oracleDatas.length);
        allOrNone = _allOrNone;

        emit InitializeOracles(_finalizableOracles);
    }

    /// @dev Given an input address, returns a storage pointer to the
    /// `FinalizableOracle` struct associated with it. It reverts if
    /// the association does not exists.
    /// @param _address The finalizable oracle address.
    function finalizableOracle(address _address)
        internal
        view
        returns (FinalizableOracle storage)
    {
        for (uint256 _i = 0; _i < finalizableOracles.length; _i++) {
            FinalizableOracle storage _finalizableOracle = finalizableOracles[
                _i
            ];
            if (
                !_finalizableOracle.finalized &&
                _finalizableOracle.addrezz == _address
            ) return _finalizableOracle;
        }
        revert Forbidden();
    }

    /// @dev Finalizes a condition linked with the KPI token. Exclusively
    /// callable by oracles linked with the KPI token in order to report the
    /// final outcome for a KPI once everything has played out "in the real world".
    /// Based on the reported results and the template configuration, collateral is
    /// either reserved to be redeemed by KPI token holders when full finalization is
    /// reached (i.e. when all the oracles have reported their final result), or sent
    /// back to the original KPI token creator (for example when KPIs have not been
    /// met, minus any present minimum payout). The possible scenarios are the following:
    ///
    /// If a result is either invalid or below the lower bound set for the KPI:
    /// - If an "all or none" approach has been chosen at the KPI token initialization
    /// time, all the collateral is sent back to the KPI token creator and the KPI token
    /// expires worthless on the spot.
    /// - If no "all or none" condition has been set, the KPI contracts calculates how
    /// much of the collaterals the specific condition "governed" (through the weighting
    /// mechanism), subtracts any minimum payout for these and sends back the right amount
    /// of collateral to the KPI token creator.
    ///
    /// If a result is in the specified range (and NOT above the higher bound) set for
    /// the KPI, the same calculations happen and some of the collateral gets sent back
    /// to the KPI token creator depending on how far we were from reaching the full KPI
    /// progress.
    ///
    /// If a result is at or above the higher bound set for the KPI token, pretty much
    /// nothing happens to the collateral, which is fully assigned to the KPI token holders
    /// and which will become redeemable once the finalization process has ended for all
    /// the oracles assigned to the KPI token.
    ///
    /// Once all the oracles associated with the KPI token have reported their end result and
    /// finalize, the remaining collateral, if any, becomes redeemable by KPI token holders.
    /// @param _result The oracle end result.
    function finalize(uint256 _result) external override nonReentrant {
        if (!_isInitialized()) revert NotInitialized();

        FinalizableOracle storage _oracle = finalizableOracle(msg.sender);
        if (_isFinalized() || _isExpired()) {
            _oracle.finalized = true;
            emit Finalize(msg.sender, _result);
            return;
        }

        if (_result <= _oracle.lowerBound || _result == INVALID_ANSWER) {
            bool _allOrNone = allOrNone;
            handleLowOrInvalidResult(_oracle, _allOrNone);
            if (_allOrNone) {
                toBeFinalized = 0;
                _oracle.finalized = true;
                registerPostFinalizationCollateralAmounts();
                emit Finalize(msg.sender, _result);
                return;
            }
        } else {
            handleIntermediateOrOverHigherBoundResult(_oracle, _result);
        }

        _oracle.finalized = true;
        unchecked {
            --toBeFinalized;
        }

        if (_isFinalized()) registerPostFinalizationCollateralAmounts();

        emit Finalize(msg.sender, _result);
    }

    /// @dev Handles collateral state changes in case an oracle reported a low or invalid
    /// answer. In particular:
    /// - If an "all or none" approach has been chosen at the KPI token initialization
    /// level, all the collateral minus any minimum payour is marked to be recovered
    /// by the KPI token creator. From the KPI token holder's point of view, the token
    /// expires worthless on the spot.
    /// - If no "all or none" condition has been set, the KPI contract calculates how
    /// much of the collaterals the specific condition "governed" (through the weighting
    /// mechanism), subtracts any minimum payout for these and sends back the right amount
    /// of collateral to the KPI token creator.
    /// @param _oracle The oracle being finalized.
    /// @param _allOrNone Whether all the oracles are in an "all or none" configuration or not.
    function handleLowOrInvalidResult(
        FinalizableOracle storage _oracle,
        bool _allOrNone
    ) internal {
        for (uint256 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _reimboursement;
            if (_allOrNone) {
                unchecked {
                    _reimboursement =
                        _collateral.amount -
                        _collateral.minimumPayout;
                }
            } else {
                uint256 _numerator = ((_collateral.amount -
                    _collateral.minimumPayout) * _oracle.weight) << MULTIPLIER;
                _reimboursement = (_numerator / totalWeight) >> MULTIPLIER;
            }
            unchecked {
                _collateral.amount -= _reimboursement;
            }
        }
    }

    /// @dev Handles collateral state changes in case an oracle reported an intermediate answer.
    /// In particular if a result is in the specified range (and NOT above the higher bound) set
    /// for the KPI, the same calculations happen and some of the collateral gets sent back
    /// to the KPI token creator depending on how far we were from reaching the full KPI
    /// progress.
    ///
    /// If a result is at or above the higher bound set for the KPI token, pretty much
    /// nothing happens to the collateral, which is fully assigned to the KPI token holders
    /// and which will become redeemable once the finalization process has ended for all
    /// the oracles assigned to the KPI token.
    ///
    /// Once all the oracles associated with the KPI token have reported their end result and
    /// finalize, the remaining collateral, if any, becomes redeemable by KPI token holders.
    /// @param _oracle The oracle being finalized.
    /// @param _result The result the oracle is reporting.
    function handleIntermediateOrOverHigherBoundResult(
        FinalizableOracle storage _oracle,
        uint256 _result
    ) internal {
        uint256 _oracleFullRange;
        uint256 _finalOracleProgress;
        unchecked {
            _oracleFullRange = _oracle.higherBound - _oracle.lowerBound;
            _finalOracleProgress = _result >= _oracle.higherBound
                ? _oracleFullRange
                : _result - _oracle.lowerBound;
        }
        _oracle.finalResult = _result;
        if (_finalOracleProgress < _oracleFullRange) {
            for (uint8 _i = 0; _i < collaterals.length; _i++) {
                Collateral storage _collateral = collaterals[_i];
                uint256 _numerator = ((_collateral.amount -
                    _collateral.minimumPayout) *
                    _oracle.weight *
                    (_oracleFullRange - _finalOracleProgress)) << MULTIPLIER;
                uint256 _denominator = _oracleFullRange * totalWeight;
                uint256 _reimboursement = (_numerator / _denominator) >>
                    MULTIPLIER;
                unchecked {
                    _collateral.amount -= _reimboursement;
                }
            }
        }
    }

    /// @dev After the KPI token has successfully been finalized, this function registers
    /// the collaterals situation before any redemptions happens. This is used to be able
    /// to handle the separate burn/redeem feature, increasing the overall security of the
    /// solution (a subset of malicious/unresponsive tokens will not be enough to jeopardize
    /// the whole campaign).
    function registerPostFinalizationCollateralAmounts() internal {
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral memory _collateral = collaterals[_i];
            postFinalizationCollateralAmount[_collateral.token] = _collateral
                .amount;
        }
    }

    /// @dev Callable by the KPI token creator, this function lets them recover any ERC20
    /// token sent to the KPI token contract. An arbitrary receiver address can be specified
    /// so that the function can be used to also help users that did something wrong by
    /// mistake by sending ERC20 tokens here. Two scenarios are possible here:
    /// - The KPI token creator wants to recover unused collateral that has been unlocked
    ///   by the KPI token after one or more oracle finalizations.
    /// - The KPI token creator wants to recover an arbitrary ERC20 token sent by mistake
    ///   to the KPI token contract (even the ERC20 KPI token itself can be recovered from
    ///   the contract).
    /// @param _token The ERC20 token address to be rescued.
    /// @param _receiver The address to which the rescued ERC20 tokens (if any) will be sent.
    function recoverERC20(address _token, address _receiver) external override {
        if (_receiver == address(0)) revert ZeroAddressReceiver();
        if (msg.sender != creator) revert Forbidden();
        bool _expired = _isExpired();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral memory _collateral = collaterals[_i];
            if (_collateral.token == _token) {
                uint256 _balance = IERC20Upgradeable(_token).balanceOf(
                    address(this)
                );
                uint256 _unneededBalance = _balance;
                if (_expired) {
                    _collateral.amount = _collateral.minimumPayout;
                }
                unchecked {
                    _unneededBalance -= _collateral.amount;
                }
                if (_unneededBalance == 0) revert NothingToRecover();
                IERC20Upgradeable(_token).safeTransfer(
                    _receiver,
                    _unneededBalance
                );
                emit RecoverERC20(_token, _unneededBalance, _receiver);
                return;
            }
        }
        uint256 _reimboursement = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        if (_reimboursement == 0) revert NothingToRecover();
        IERC20Upgradeable(_token).safeTransfer(_receiver, _reimboursement);
        emit RecoverERC20(_token, _reimboursement, _receiver);
    }

    /// @dev Given a collateral amount, calculates the protocol fee as a percentage of it.
    /// @param _amount The collateral amount end result.
    /// @return The protocol fee amount.
    function calculateProtocolFee(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return (_amount * 3_000) / 1_000_000;
        }
    }

    /// @dev Only callable by KPI token holders, lets them redeem any collateral
    /// left in the contract after finalization, proportional to their balance
    /// compared to the total supply and left collateral amount. If the KPI token
    /// has expired worthless, this simply burns the user's KPI tokens.
    /// @param _data ABI-encoded data specifying the redeem parameters. In this
    /// specific case the ABI encoded parameter is an address that will receive
    /// the redeemed collaterals (if any).
    function redeem(bytes calldata _data) external override {
        address _receiver = abi.decode(_data, (address));
        if (_receiver == address(0)) revert ZeroAddressReceiver();
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        _burn(msg.sender, _kpiTokenBalance);
        RedeemedCollateral[]
            memory _redeemedCollaterals = new RedeemedCollateral[](
                collaterals.length
            );
        bool _expired = _isExpired();
        uint256 _initialSupply = initialSupply;
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _redeemableAmount = 0;
            unchecked {
                _redeemableAmount =
                    ((
                        _expired
                            ? _collateral.minimumPayout
                            : postFinalizationCollateralAmount[
                                _collateral.token
                            ]
                    ) * _kpiTokenBalance) /
                    _initialSupply;
                _collateral.amount -= _redeemableAmount;
            }
            IERC20Upgradeable(_collateral.token).safeTransfer(
                _receiver,
                _redeemableAmount
            );
            _redeemedCollaterals[_i] = RedeemedCollateral({
                token: _collateral.token,
                amount: _redeemableAmount
            });
        }
        emit Redeem(msg.sender, _kpiTokenBalance, _redeemedCollaterals);
    }

    /// @dev Only callable by KPI token holders, lets them register their redemption
    /// by burning the KPI tokens they have. Using this function, any collateral gained
    /// by the KPI token resolution must be explicitly requested by the user through
    /// the `redeemCollateral` function.
    function registerRedemption() external override {
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        _burn(msg.sender, _kpiTokenBalance);
        registeredBurn[msg.sender] += _kpiTokenBalance;
        emit RegisterRedemption(msg.sender, _kpiTokenBalance);
    }

    /// @dev Only callable by KPI token holders that have previously explicitly burned their
    /// KPI tokens through the `registerRedemption` function, this redeems the collateral
    /// token specified as input in the function. The function reverts if either an invalid
    /// collateral is specified or if zero of the given collateral can be redeemed.
    function redeemCollateral(address _token, address _receiver)
        external
        override
    {
        if (_token == address(0)) revert ZeroAddressToken();
        if (_receiver == address(0)) revert ZeroAddressReceiver();
        if (!_isFinalized() && block.timestamp < expiration) revert Forbidden();
        uint256 _burned = registeredBurn[msg.sender];
        if (_burned == 0) revert Forbidden();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            if (_collateral.token == _token) {
                uint256 _redeemableAmount;
                unchecked {
                    _redeemableAmount =
                        ((
                            _isExpired()
                                ? _collateral.minimumPayout
                                : postFinalizationCollateralAmount[
                                    _collateral.token
                                ]
                        ) * _burned) /
                        initialSupply -
                        redeemedCollateralOf[msg.sender][_token];
                    if (_redeemableAmount == 0) revert NothingToRedeem();
                    _collateral.amount -= _redeemableAmount;
                }
                if (_redeemableAmount == 0) revert Forbidden();
                redeemedCollateralOf[msg.sender][_token] += _redeemableAmount;
                IERC20Upgradeable(_token).safeTransfer(
                    _receiver,
                    _redeemableAmount
                );
                emit RedeemCollateral(
                    msg.sender,
                    _token,
                    _receiver,
                    _redeemableAmount
                );
                return;
            }
        }
        revert InvalidCollateral();
    }

    /// @dev Given ABI-encoded data about the collaterals a user intends to use
    /// to create a KPI token, gives back a fee breakdown detailing how much
    /// fees will be taken from the collaterals. The ABI-encoded params must be
    /// a `TokenAmount` array (with a maximum of 5 elements).
    /// @return An ABI-encoded fee breakdown represented by a `TokenAmount` array.
    function protocolFee(bytes calldata _data)
        external
        pure
        returns (bytes memory)
    {
        TokenAmount[] memory _collaterals = abi.decode(_data, (TokenAmount[]));

        if (_collaterals.length == 0) revert NoCollaterals();
        if (_collaterals.length > 5) revert TooManyCollaterals();

        TokenAmount[] memory _fees = new TokenAmount[](_collaterals.length);
        for (uint8 _i = 0; _i < _collaterals.length; _i++) {
            TokenAmount memory _collateral = _collaterals[_i];
            if (_collateral.token == address(0) || _collateral.amount == 0)
                revert InvalidCollateral();
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
            _fees[_i] = TokenAmount({
                token: _collateral.token,
                amount: calculateProtocolFee(_collateral.amount)
            });
        }

        return abi.encode(_fees);
    }

    /// @dev View function to check if the KPI token is finalized.
    /// @return A bool describing whether the token is finalized or not.
    function _isFinalized() internal view returns (bool) {
        return toBeFinalized == 0;
    }

    /// @dev View function to check if the KPI token is finalized.
    /// @return A bool describing whether the token is finalized or not.
    function finalized() external view override returns (bool) {
        return _isFinalized();
    }

    /// @dev View function to check if the KPI token is expired. A KPI token is
    /// considered expired when not finalized before the expiration date comes.
    /// @return A bool describing whether the token is finalized or not.
    function _isExpired() internal view returns (bool) {
        return !_isFinalized() && expiration <= block.timestamp;
    }

    /// @dev View function to check if the KPI token is expired. A KPI token is
    /// considered expired when not finalized before the expiration date comes.
    /// @return A bool describing whether the token is finalized or not.
    function expired() external view override returns (bool) {
        return _isExpired();
    }

    /// @dev View function to check if the KPI token is initialized.
    /// @return A bool describing whether the token is initialized or not.
    function _isInitialized() internal view returns (bool) {
        return creator != address(0);
    }

    /// @dev View function to query all the oracles associated with the KPI token at once.
    /// @return The oracles array.
    function oracles() external view override returns (address[] memory) {
        if (!_isInitialized()) revert NotInitialized();
        address[] memory _oracleAddresses = new address[](
            finalizableOracles.length
        );
        for (uint256 _i = 0; _i < _oracleAddresses.length; _i++)
            _oracleAddresses[_i] = finalizableOracles[_i].addrezz;
        return _oracleAddresses;
    }

    /// @dev View function returning all the most important data about the KPI token, in
    /// an ABI-encoded structure. The structure includes collaterals, finalizable oracles,
    /// "all-or-none" flag, initial supply of the ERC20 KPI token, along with name and symbol.
    /// @return The ABI-encoded data.
    function data() external view returns (bytes memory) {
        return
            abi.encode(
                collaterals,
                finalizableOracles,
                allOrNone,
                initialSupply,
                name(),
                symbol()
            );
    }

    /// @dev View function returning info about the template used to instantiate this KPI token.
    /// @return The template struct.
    function template()
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return kpiTokenTemplate;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity >=0.8.0;

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager interface
/// @dev Interface for the oracles manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IOraclesManager {
    struct Version {
        uint32 major;
        uint32 minor;
        uint32 patch;
    }

    struct Template {
        uint256 id;
        address addrezz;
        Version version;
        string specification;
        bool automatable;
    }

    function initialize(address _factory) external;

    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external payable returns (address);

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}

pragma solidity >=0.8.0;

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager interface
/// @dev Interface for the KPI tokens manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IKPITokensManager {
    struct Version {
        uint32 major;
        uint32 minor;
        uint32 patch;
    }

    struct Template {
        uint256 id;
        address addrezz;
        Version version;
        string specification;
    }

    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address);

    function addTemplate(address _template, string calldata _specification)
        external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}

pragma solidity >=0.8.0;

import {IERC20Upgradeable} from "oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IKPIToken} from "./IKPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token interface
/// @dev Interface for the ERC20 KPI token contract.
/// @author Federico Luzzi - <[email protected]>
interface IERC20KPIToken is IKPIToken, IERC20Upgradeable {
    struct OracleData {
        uint256 templateId;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 weight;
        uint256 value;
        bytes data;
    }

    struct Collateral {
        address token;
        uint256 amount;
        uint256 minimumPayout;
    }

    struct FinalizableOracle {
        address addrezz;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 finalResult;
        uint256 weight;
        bool finalized;
    }

    struct RedeemedCollateral {
        address token;
        uint256 amount;
    }

    function recoverERC20(address _token, address _receiver) external;

    function registerRedemption() external;

    function redeemCollateral(address _token, address _receiver) external;
}

pragma solidity >=0.8.0;

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Types
/// @dev General collection of reusable types.
/// @author Federico Luzzi - <[email protected]>

struct TokenAmount {
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity >=0.8.0;

import {IKPITokensManager} from "../IKPITokensManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI token interface
/// @dev KPI token interface.
/// @author Federico Luzzi - <[email protected]>
interface IKPIToken {
    function initialize(
        address _creator,
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _kpiTokenData,
        bytes memory _oraclesData
    ) external payable;

    function finalize(uint256 _result) external;

    function redeem(bytes memory _data) external;

    function creator() external view returns (address);

    function template()
        external
        view
        returns (IKPITokensManager.Template memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function expiration() external view returns (uint256);

    function expired() external view returns (bool);

    function protocolFee(bytes memory _data)
        external
        view
        returns (bytes memory);

    function data() external view returns (bytes memory);

    function oracles() external view returns (address[] memory);
}