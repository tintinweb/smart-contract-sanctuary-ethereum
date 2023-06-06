// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UsingTellor} from "./UsingTellor.sol";
import {IDIVAOracleTellor} from "./interfaces/IDIVAOracleTellor.sol";
import {IDIVA} from "./interfaces/IDIVA.sol";
import {IDIVAOwnershipShared} from "./interfaces/IDIVAOwnershipShared.sol";
import {SafeDecimalMath} from "./libraries/SafeDecimalMath.sol";

contract DIVAOracleTellor is UsingTellor, IDIVAOracleTellor, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using SafeDecimalMath for uint256;

    // Ordered to optimize storage
    mapping(bytes32 => mapping(address => uint256)) private _tips; // mapping poolId => tipping token address => tip amount
    mapping(bytes32 => address[]) private _poolIdToTippingTokens; // mapping poolId to tipping tokens
    mapping(bytes32 => address) private _poolIdToReporter; // mapping poolId to reporter address
    mapping(address => bytes32[]) private _reporterToPoolIds; // mapping reporter to poolIds

    uint256 private _previousMaxDIVARewardUSD; // expressed as an integer with 18 decimals, initialized to zero at contract deployment
    uint256 private _maxDIVARewardUSD; // expressed as an integer with 18 decimals
    uint256 private _startTimeMaxDIVARewardUSD;

    address private _previousExcessDIVARewardRecipient; // initialized to zero address at contract deployment
    address private _excessDIVARewardRecipient;
    uint256 private _startTimeExcessDIVARewardRecipient;

    address private immutable _ownershipContract;
    bool private constant _CHALLENGEABLE = false;
    IDIVA private immutable _DIVA;

    uint256 private constant _ACTIVATION_DELAY = 3 days;
    uint32 private constant _MIN_PERIOD_UNDISPUTED = 10;

    modifier onlyOwner() {
        address _owner = _contractOwner();
        if (msg.sender != _owner) {
            revert NotContractOwner(msg.sender, _owner);
        }
        _;
    }

    constructor(
        address ownershipContract_,
        address payable tellorAddress_,
        address excessDIVARewardRecipient_,
        uint256 maxDIVARewardUSD_,
        address diva_
    ) UsingTellor(tellorAddress_) {
        if (ownershipContract_ == address(0)) {
            revert ZeroOwnershipContractAddress();
        }
        if (excessDIVARewardRecipient_ == address(0)) {
            revert ZeroExcessDIVARewardRecipient();
        }
        if (diva_ == address(0)) {
            revert ZeroDIVAAddress();
        }
        // Zero address check for `tellorAddress_` is done inside `UsingTellor.sol`

        _ownershipContract = ownershipContract_;
        _excessDIVARewardRecipient = excessDIVARewardRecipient_;
        _maxDIVARewardUSD = maxDIVARewardUSD_;
        _DIVA = IDIVA(diva_);
    }

    function addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external override nonReentrant {
        _addTip(_poolId, _amount, _tippingToken);
    }
    
    function _addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) private {
        // Confirm that the final value hasn't been submitted to DIVA Protocol yet,
        // in which case `_poolIdToReporter` would resolve to the zero address.
        if (_poolIdToReporter[_poolId] != address(0)) {
            revert AlreadyConfirmedPool();
        }

        // Add a new entry in the `_poolIdToTippingTokens` array if the specified
        //`_tippingToken` does not yet exist for the specified pool. 
        if (_tips[_poolId][_tippingToken] == 0) {
            _poolIdToTippingTokens[_poolId].push(_tippingToken);
        }

        // Cache tipping token instance
        IERC20Metadata _tippingTokenInstance = IERC20Metadata(_tippingToken);

        // Follow the CEI pattern by updating the balance before doing a potentially
        // unsafe `safeTransferFrom` call.
        _tips[_poolId][_tippingToken] += _amount;

        // Check tipping token balance before and after the transfer to identify
        // fee-on-transfer tokens. If no fees were charged, transfer approved
        // tipping token from `msg.sender` to `this`. Otherwise, revert.
        uint256 _before = _tippingTokenInstance.balanceOf(address(this));
        _tippingTokenInstance.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 _after = _tippingTokenInstance.balanceOf(address(this));

        if (_after - _before != _amount) {
            revert FeeTokensNotSupported();
        }

        // Log event including tipped pool, amount and tipper address.
        emit TipAdded(_poolId, _tippingToken, _amount, msg.sender);
    }

    function batchAddTip(
        ArgsBatchAddTip[] calldata _argsBatchAddTip
    ) external override nonReentrant {
        uint256 _len = _argsBatchAddTip.length;
        for (uint256 i; i < _len; ) {
            _addTip(
                _argsBatchAddTip[i].poolId,
                _argsBatchAddTip[i].amount,
                _argsBatchAddTip[i].tippingToken
            );

            unchecked {
                ++i;
            }
        }
    }

    function claimReward(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external override nonReentrant {
        _claimReward(_poolId, _tippingTokens, _claimDIVAReward);
    }

    function batchClaimReward(
        ArgsBatchClaimReward[] calldata _argsBatchClaimReward
    ) external override nonReentrant {
        uint256 _len = _argsBatchClaimReward.length;
        for (uint256 i; i < _len; ) {
            _claimReward(
                _argsBatchClaimReward[i].poolId,
                _argsBatchClaimReward[i].tippingTokens,
                _argsBatchClaimReward[i].claimDIVAReward
            );

            unchecked {
                ++i;
            }
        }
    }

    function setFinalReferenceValue(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external override nonReentrant {
        _setFinalReferenceValue(_poolId);
        _claimReward(_poolId, _tippingTokens, _claimDIVAReward);
    }

    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[] calldata _argsBatchSetFinalReferenceValue
    ) external override nonReentrant {
        uint256 _len = _argsBatchSetFinalReferenceValue.length;
        for (uint256 i; i < _len; ) {
            _setFinalReferenceValue(_argsBatchSetFinalReferenceValue[i].poolId);
            _claimReward(
                _argsBatchSetFinalReferenceValue[i].poolId,
                _argsBatchSetFinalReferenceValue[i].tippingTokens,
                _argsBatchSetFinalReferenceValue[i].claimDIVAReward
            );

            unchecked {
                ++i;
            }
        }
    }

    function updateExcessDIVARewardRecipient(address _newExcessDIVARewardRecipient)
        external
        override
        onlyOwner
    {
        // Confirm that provided excess DIVA reward recipient address
        // is not zero address
        if (_newExcessDIVARewardRecipient == address(0)) {
            revert ZeroExcessDIVARewardRecipient();
        }

        // Confirm that there is no pending excess DIVA reward recipient update.
        // Revoke to update pending value.
        if (_startTimeExcessDIVARewardRecipient > block.timestamp) {
            revert PendingExcessDIVARewardRecipientUpdate(
                block.timestamp,
                _startTimeExcessDIVARewardRecipient
            );
        }

        // Store current excess DIVA reward recipient in `_previousExcessDIVARewardRecipient`
        // variable
        _previousExcessDIVARewardRecipient = _excessDIVARewardRecipient;

        // Set time at which the new excess DIVA reward recipient will become applicable
        uint256 _startTimeNewExcessDIVARewardRecipient;
        unchecked {
            // Cannot realistically overflow
            _startTimeNewExcessDIVARewardRecipient = block.timestamp +
                _ACTIVATION_DELAY;
        }

        // Store start time and new excess DIVA reward recipient
        _startTimeExcessDIVARewardRecipient = _startTimeNewExcessDIVARewardRecipient;
        _excessDIVARewardRecipient = _newExcessDIVARewardRecipient;

        // Log the new excess DIVA reward recipient as well as the address that
        // initiated the change
        emit ExcessDIVARewardRecipientUpdated(
            msg.sender,
            _newExcessDIVARewardRecipient,
            _startTimeNewExcessDIVARewardRecipient
        );
    }

    function updateMaxDIVARewardUSD(uint256 _newMaxDIVARewardUSD)
        external
        override
        onlyOwner
    {
        // Confirm that there is no pending max DIVA reward USD update.
        // Revoke to update pending value.
        if (_startTimeMaxDIVARewardUSD > block.timestamp) {
            revert PendingMaxDIVARewardUSDUpdate(
                block.timestamp,
                _startTimeMaxDIVARewardUSD
            );
        }

        // Store current max DIVA reward USD in `_previousMaxDIVARewardUSD`
        // variable
        _previousMaxDIVARewardUSD = _maxDIVARewardUSD;

        // Set time at which the new max DIVA reward USD will become applicable
        uint256 _startTimeNewMaxDIVARewardUSD;
        unchecked {
            // Cannot realistically overflow
            _startTimeNewMaxDIVARewardUSD = block.timestamp +
                _ACTIVATION_DELAY;
        }        

        // Store start time and new max DIVA reward USD
        _startTimeMaxDIVARewardUSD = _startTimeNewMaxDIVARewardUSD;
        _maxDIVARewardUSD = _newMaxDIVARewardUSD;

        // Log the new max DIVA reward USD as well as the address that
        // initiated the change
        emit MaxDIVARewardUSDUpdated(
            msg.sender,
            _newMaxDIVARewardUSD,
            _startTimeNewMaxDIVARewardUSD
        );
    }

    function revokePendingExcessDIVARewardRecipientUpdate()
        external
        override
        onlyOwner
    {
        // Confirm that new excess DIVA reward recipient is not active yet
        if (_startTimeExcessDIVARewardRecipient <= block.timestamp) {
            revert ExcessDIVARewardRecipientAlreadyActive(
                block.timestamp,
                _startTimeExcessDIVARewardRecipient
            );
        }

        // Store `_excessDIVARewardRecipient` value temporarily
        address _revokedExcessDIVARewardRecipient = _excessDIVARewardRecipient;

        // Reset excess DIVA reward recipient related variables
        _startTimeExcessDIVARewardRecipient = block.timestamp;
        _excessDIVARewardRecipient = _previousExcessDIVARewardRecipient;

        // Log the excess DIVA reward recipient revoked, the previous one that now
        // applies as well as the address that initiated the change
        emit PendingExcessDIVARewardRecipientUpdateRevoked(
            msg.sender,
            _revokedExcessDIVARewardRecipient,
            _previousExcessDIVARewardRecipient
        );
    }

    function revokePendingMaxDIVARewardUSDUpdate() external override onlyOwner {
        // Confirm that new max USD DIVA reward is not active yet
        if (_startTimeMaxDIVARewardUSD <= block.timestamp) {
            revert MaxDIVARewardUSDAlreadyActive(
                block.timestamp,
                _startTimeMaxDIVARewardUSD
            );
        }

        // Store `_maxDIVARewardUSD` value temporarily
        uint256 _revokedMaxDIVARewardUSD = _maxDIVARewardUSD;

        // Reset max DIVA reward USD related variables
        _startTimeMaxDIVARewardUSD = block.timestamp;
        _maxDIVARewardUSD = _previousMaxDIVARewardUSD;

        // Log the max DIVA reward USD revoked, the previous one that now
        // applies as well as the address that initiated the change
        emit PendingMaxDIVARewardUSDUpdateRevoked(
            msg.sender,
            _revokedMaxDIVARewardUSD,
            _previousMaxDIVARewardUSD
        );
    }

    function getChallengeable() external pure override returns (bool) {
        return _CHALLENGEABLE;
    }

    function getExcessDIVARewardRecipientInfo()
        external
        view
        override
        returns (
            address previousExcessDIVARewardRecipient,
            address excessDIVARewardRecipient,
            uint256 startTimeExcessDIVARewardRecipient
        )
    {
        (
            previousExcessDIVARewardRecipient,
            excessDIVARewardRecipient,
            startTimeExcessDIVARewardRecipient
        ) = (
            _previousExcessDIVARewardRecipient,
            _excessDIVARewardRecipient,
            _startTimeExcessDIVARewardRecipient
        );
    }

    function getMaxDIVARewardUSDInfo()
        external
        view
        override
        returns (
            uint256 previousMaxDIVARewardUSD,
            uint256 maxDIVARewardUSD,
            uint256 startTimeMaxDIVARewardUSD
        )
    {
        (previousMaxDIVARewardUSD, maxDIVARewardUSD, startTimeMaxDIVARewardUSD) = (
            _previousMaxDIVARewardUSD,
            _maxDIVARewardUSD,
            _startTimeMaxDIVARewardUSD
        );
    }

    function getMinPeriodUndisputed() external pure override returns (uint32) {
        return _MIN_PERIOD_UNDISPUTED;
    }

    function getTippingTokens(
        ArgsGetTippingTokens[] calldata _argsGetTippingTokens
    ) external view override returns (address[][] memory) {
        uint256 _len = _argsGetTippingTokens.length;
        address[][] memory _tippingTokens = new address[][](_len);
        for (uint256 i; i < _len; ) {
            address[] memory _tippingTokensForPoolId = new address[](
                _argsGetTippingTokens[i].endIndex -
                    _argsGetTippingTokens[i].startIndex
            );
            for (
                uint256 j = _argsGetTippingTokens[i].startIndex;
                j < _argsGetTippingTokens[i].endIndex;

            ) {
                if (
                    j >=
                    _poolIdToTippingTokens[_argsGetTippingTokens[i].poolId]
                        .length
                ) {
                    _tippingTokensForPoolId[
                        j - _argsGetTippingTokens[i].startIndex
                    ] = address(0);
                } else {
                    _tippingTokensForPoolId[
                        j - _argsGetTippingTokens[i].startIndex
                    ] = _poolIdToTippingTokens[_argsGetTippingTokens[i].poolId][
                        j
                    ];
                }

                unchecked {
                    ++j;
                }
            }
            _tippingTokens[i] = _tippingTokensForPoolId;

            unchecked {
                ++i;
            }
        }
        return _tippingTokens;
    }

    function getTippingTokensLengthForPoolIds(bytes32[] calldata _poolIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 _len = _poolIds.length;
        uint256[] memory _tippingTokensLength = new uint256[](_len);
        for (uint256 i; i < _len; ) {
            _tippingTokensLength[i] = _poolIdToTippingTokens[_poolIds[i]]
                .length;

            unchecked {
                ++i;
            }
        }
        return _tippingTokensLength;
    }

    function getTipAmounts(ArgsGetTipAmounts[] calldata _argsGetTipAmounts)
        external
        view
        override
        returns (uint256[][] memory)
    {
        uint256 _len = _argsGetTipAmounts.length;
        uint256[][] memory _tipAmounts = new uint256[][](_len);
        for (uint256 i; i < _len; ) {
            uint256 _tippingTokensLen = _argsGetTipAmounts[i]
                .tippingTokens
                .length;
            uint256[] memory _tipAmountsForPoolId = new uint256[](
                _tippingTokensLen
            );
            for (uint256 j = 0; j < _tippingTokensLen; ) {
                _tipAmountsForPoolId[j] = _tips[_argsGetTipAmounts[i].poolId][
                    _argsGetTipAmounts[i].tippingTokens[j]
                ];

                unchecked {
                    ++j;
                }
            }

            _tipAmounts[i] = _tipAmountsForPoolId;

            unchecked {
                ++i;
            }
        }
        return _tipAmounts;
    }

    function getDIVAAddress() external view override returns (address) {
        return address(_DIVA);
    }

    function getReporters(bytes32[] calldata _poolIds)
        external
        view
        override
        returns (address[] memory)
    {
        uint256 _len = _poolIds.length;
        address[] memory _reporters = new address[](_len);
        for (uint256 i; i < _len; ) {
            _reporters[i] = _poolIdToReporter[_poolIds[i]];

            unchecked {
                ++i;
            }
        }
        return _reporters;
    }

    function getPoolIdsForReporters(
        ArgsGetPoolIdsForReporters[] calldata _argsGetPoolIdsForReporters
    ) external view override returns (bytes32[][] memory) {
        uint256 _len = _argsGetPoolIdsForReporters.length;
        bytes32[][] memory _poolIds = new bytes32[][](_len);
        for (uint256 i; i < _len; ) {
            bytes32[] memory _poolIdsForReporter = new bytes32[](
                _argsGetPoolIdsForReporters[i].endIndex -
                    _argsGetPoolIdsForReporters[i].startIndex
            );
            for (
                uint256 j = _argsGetPoolIdsForReporters[i].startIndex;
                j < _argsGetPoolIdsForReporters[i].endIndex;

            ) {
                if (
                    j >=
                    _reporterToPoolIds[_argsGetPoolIdsForReporters[i].reporter]
                        .length
                ) {
                    _poolIdsForReporter[
                        j - _argsGetPoolIdsForReporters[i].startIndex
                    ] = 0;
                } else {
                    _poolIdsForReporter[
                        j - _argsGetPoolIdsForReporters[i].startIndex
                    ] = _reporterToPoolIds[
                        _argsGetPoolIdsForReporters[i].reporter
                    ][j];
                }

                unchecked {
                    ++j;
                }
            }
            _poolIds[i] = _poolIdsForReporter;

            unchecked {
                ++i;
            }
        }
        return _poolIds;
    }

    function getPoolIdsLengthForReporters(address[] calldata _reporters)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 _len = _reporters.length;
        uint256[] memory _poolIdsLength = new uint256[](_len);
        for (uint256 i; i < _len; ) {
            _poolIdsLength[i] = _reporterToPoolIds[_reporters[i]].length;

            unchecked {
                ++i;
            }
        }
        return _poolIdsLength;
    }

    function getOwnershipContract() external view override returns (address) {
        return _ownershipContract;
    }

    function getActivationDelay() external pure override returns (uint256) {
        return _ACTIVATION_DELAY;
    }

    function getQueryDataAndId(bytes32 _poolId)
        public
        view
        override
        returns (bytes memory queryData, bytes32 queryId)
    {
        // Construct Tellor query data
        queryData = 
                abi.encode(
                    "DIVAProtocol",
                    abi.encode(_poolId, address(_DIVA), block.chainid)
                );

        // Construct Tellor queryId
        queryId = keccak256(queryData);
    }

    function _getCurrentExcessDIVARewardRecipient() internal view returns (address) {
        // Return the new excess DIVA reward recipient if `block.timestamp` is at or
        // past the activation time, else return the current excess DIVA reward
        // recipient
        return
            block.timestamp < _startTimeExcessDIVARewardRecipient
                ? _previousExcessDIVARewardRecipient
                : _excessDIVARewardRecipient;
    }

    function _getCurrentMaxDIVARewardUSD() internal view returns (uint256) {
        // Return the new max DIVA reward USD if `block.timestamp` is at or past
        // the activation time, else return the current max DIVA reward USD
        return
            block.timestamp < _startTimeMaxDIVARewardUSD
                ? _previousMaxDIVARewardUSD
                : _maxDIVARewardUSD;
    }

    function _contractOwner() internal view returns (address) {
        return IDIVAOwnershipShared(_ownershipContract).getCurrentOwner();
    }

    function _claimReward(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) private {
        // Check that the pool has already been confirmed. The `_poolIdToReporter`
        // value is set during `setFinalReferenceValue`
        if (_poolIdToReporter[_poolId] == address(0)) {
            revert NotConfirmedPool();
        }

        // Iterate over the provided `_tippingTokens` array. Will skip the for
        // loop if no tipping tokens have been provided.
        uint256 _len = _tippingTokens.length;
        for (uint256 i; i < _len; ) {
            address _tippingToken = _tippingTokens[i];

            // Get tip amount for pool and tipping token.
            uint256 _tipAmount = _tips[_poolId][_tippingToken];

            // Set tip amount to zero to prevent multiple payouts in the event that 
            // the same tipping token is provided multiple times.
            _tips[_poolId][_tippingToken] = 0;

            // Transfer tip from `this` to eligible reporter.
            IERC20Metadata(_tippingToken).safeTransfer(
                _poolIdToReporter[_poolId],
                _tipAmount
            );

            // Log event for each tipping token claimed
            emit TipClaimed(
                _poolId,
                _poolIdToReporter[_poolId],
                _tippingToken,
                _tipAmount
            );

            unchecked {
                ++i;
            }
        }

        // Claim DIVA reward if indicated in the function call. Alternatively,
        // DIVA rewards can be claimed from the DIVA smart contract directly.
        if (_claimDIVAReward) {
            IDIVA.Pool memory _params = _DIVA.getPoolParameters(_poolId);
            _DIVA.claimFee(_params.collateralToken, _poolIdToReporter[_poolId]);
        }
    }

    function _setFinalReferenceValue(bytes32 _poolId) private {
        // Load pool information from the DIVA smart contract.
        IDIVA.Pool memory _params = _DIVA.getPoolParameters(_poolId);

        // Get queryId from poolId for the value look-up inside the Tellor contract.
        (, bytes32 _queryId) = getQueryDataAndId(_poolId);

        // Find first oracle submission after or at expiryTime, if it exists.
        (
            bytes memory _valueRetrieved,
            uint256 _timestampRetrieved
        ) = getDataAfter(_queryId, _params.expiryTime);

        // Check that data exists (_timestampRetrieved = 0 if it doesn't).
        if (_timestampRetrieved == 0) {
            revert NoOracleSubmissionAfterExpiryTime();
        }

        // Check that `_MIN_PERIOD_UNDISPUTED` has passed after `_timestampRetrieved`.
        if (block.timestamp - _timestampRetrieved < _MIN_PERIOD_UNDISPUTED) {
            revert MinPeriodUndisputedNotPassed();
        }

        // Format values (18 decimals)
        (
            uint256 _formattedFinalReferenceValue,
            uint256 _formattedCollateralToUSDRate
        ) = abi.decode(_valueRetrieved, (uint256, uint256));

        // Get address of reporter who will receive
        address _reporter = getReporterByTimestamp(
            _queryId,
            _timestampRetrieved
        );

        // Set reporter with poolId
        _poolIdToReporter[_poolId] = _reporter;
        _reporterToPoolIds[_reporter].push(_poolId);

        // Forward final value to DIVA contract. Credits the DIVA reward to `this`
        // contract as part of that process. DIVA reward claim is transferred to
        // the corresponding reporter via the `batchTransferFeeClaim` function
        // further down below.
        _DIVA.setFinalReferenceValue(
            _poolId,
            _formattedFinalReferenceValue,
            _CHALLENGEABLE
        );

        uint256 _SCALING;
        unchecked {
            // Cannot over-/underflow as collateralToken decimals are restricted to
            // a minimum of 6 and a maximum of 18 inside DIVA Protocol.
            _SCALING = uint256(
                10**(18 - IERC20Metadata(_params.collateralToken).decimals())
            );
        }        

        // Get the current DIVA reward claim allocated to this contract address (msg.sender)
        uint256 divaRewardClaim = _DIVA.getClaim(
            _params.collateralToken,
            address(this)
        ); // denominated in collateral token; integer with collateral token decimals

        uint256 divaRewardClaimUSD = (divaRewardClaim * _SCALING).multiplyDecimal(
            _formattedCollateralToUSDRate
        ); // denominated in USD; integer with 18 decimals
        uint256 divaRewardToReporter;

        uint256 _currentMaxDIVARewardUSD = _getCurrentMaxDIVARewardUSD();
        if (divaRewardClaimUSD > _currentMaxDIVARewardUSD) {
            // if _formattedCollateralToUSDRate = 0, then divaRewardClaimUSD = 0 in
            // which case it will go into the else part, hence division by zero
            // is not a problem
            divaRewardToReporter =
                _currentMaxDIVARewardUSD.divideDecimal(
                    _formattedCollateralToUSDRate
                ) /
                _SCALING; // integer with collateral token decimals
        } else {
            divaRewardToReporter = divaRewardClaim;
        }

        // Transfer DIVA reward claim to reporter and excess DIVA reward recipient.
        // Note that the transfer takes place internally inside the DIVA smart contract
        // and the reward has to be claimed separately either by setting the `_claimDIVAReward`
        // parameter to `true` when calling `setFinalReferenceValue` inside this contract
        // or later by calling the `claimReward` function. 
        IDIVA.ArgsBatchTransferFeeClaim[]
            memory _divaRewardClaimTransfers = new IDIVA.ArgsBatchTransferFeeClaim[](
                2
            );
        _divaRewardClaimTransfers[0] = IDIVA.ArgsBatchTransferFeeClaim(
            _reporter,
            _params.collateralToken,
            divaRewardToReporter
        );
        _divaRewardClaimTransfers[1] = IDIVA.ArgsBatchTransferFeeClaim(
            _getCurrentExcessDIVARewardRecipient(),
            _params.collateralToken,
            divaRewardClaim - divaRewardToReporter // integer with collateral token decimals
        );
        _DIVA.batchTransferFeeClaim(_divaRewardClaimTransfers);

        // Log event including reported information
        emit FinalReferenceValueSet(
            _poolId,
            _formattedFinalReferenceValue,
            _params.expiryTime,
            _timestampRetrieved
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Shortened version of the interface including required functions only
 */
interface IDIVA {
    // Struct for `batchTransferFeeClaim` function input
    struct ArgsBatchTransferFeeClaim {
        address recipient;
        address collateralToken;
        uint256 amount;
    }

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor; // Reference asset value at or below which the long token pays out 0 and the short token 1 (max payout) (18 decimals)
        uint256 inflection; // Reference asset value at which the long token pays out `gradient` and the short token `1-gradient` (18 decimals)
        uint256 cap; // Reference asset value at or above which the long token pays out 1 (max payout) and the short token 0 (18 decimals)
        uint256 gradient; // Long token payout at inflection (value between 0 and 1) (collateral token decimals)
        uint256 collateralBalance; // Current collateral balance of pool (collateral token decimals)
        uint256 finalReferenceValue; // Reference asset value at the time of expiration (18 decimals) - set to 0 at pool creation
        uint256 capacity; // Maximum collateral that the pool can accept (collateral token decimals)
        uint256 statusTimestamp; // Timestamp of status change - set to block.timestamp at pool creation
        address shortToken; // Short position token address
        uint96 payoutShort; // Payout amount per short position token net of fees (collateral token decimals) - set to 0 at pool creation
        address longToken; // Long position token address
        uint96 payoutLong; // Payout amount per long position token net of fees (collateral token decimals) - set to 0 at pool creation
        address collateralToken; // Address of the ERC20 collateral token
        uint96 expiryTime; // Expiration time of the pool (expressed as a unix timestamp in seconds)
        address dataProvider; // Address of data provider
        uint48 indexFees; // Index pointer to the applicable fees inside the Fees struct array
        uint48 indexSettlementPeriods; // Index pointer to the applicable periods inside the SettlementPeriods struct array
        Status statusFinalReferenceValue; // Status of final reference price (0 = Open, 1 = Submitted, 2 = Challenged, 3 = Confirmed) - set to 0 at pool creation
        string referenceAsset; // Reference asset string
    }

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        address longRecipient;
        address shortRecipient;
        address permissionedERC721Token;
    }

    /**
     * @notice Function to submit the final reference value for a given pool Id.
     * @param _poolId The pool Id for which the final value is submitted.
     * @param _finalReferenceValue Proposed final value by the data provider
     * expressed as an integer with 18 decimals.
     * @param _allowChallenge Flag indicating whether the challenge functionality
     * is enabled or disabled for the submitted value. If 0, then the submitted
     * final value will be directly confirmed and position token holders can start
     * redeeming their position tokens. If 1, then position token holders can
     * challenge the submitted value. This flag was introduced to account for
     * decentralized oracle solutions like Uniswap v3 or Chainlink where a
     * dispute mechanism doesn't make sense.
     */
    function setFinalReferenceValue(
        bytes32 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) external;

    /**
     * @notice Function to transfer fee claim from entitled address
     * to another address
     * @param _recipient Address of fee claim recipient
     * @param _collateralToken Collateral token address
     * @param _amount Amount (expressed as an integer with collateral token
     * decimals) to transfer to recipient
     */
    function transferFeeClaim(
        address _recipient,
        address _collateralToken,
        uint256 _amount
    ) external;

    /**
     * @notice Batch version of `transferFeeClaim`
     * @param _argsBatchTransferFeeClaim List containing collateral tokens,
     * recipient addresses and amounts (expressed as an integer with collateral
     * token decimals)
     */
    function batchTransferFeeClaim(
        ArgsBatchTransferFeeClaim[] calldata _argsBatchTransferFeeClaim
    ) external;

    /**
     * @notice Function to claim allocated fee
     * @dev List of collateral token addresses has to be obtained off-chain
     * (e.g., from TheGraph)
     * @param _collateralToken Collateral token address
     * @param _recipient Fee recipient address
     */
    function claimFee(address _collateralToken, address _recipient) external;

    /**
     * @notice Function to issue long and short position tokens to
     * `longRecipient` and `shortRecipient` upon collateral deposit by `msg.sender`. 
     * Provided collateral is kept inside the contract until position tokens are 
     * redeemed by calling `redeemPositionToken` or `removeLiquidity`.
     * @dev Position token supply equals `collateralAmount` (minimum 1e6).
     * Position tokens have the same number of decimals as the collateral token.
     * Only ERC20 tokens with 6 <= decimals <= 18 are accepted as collateral.
     * Tokens with flexible supply like Ampleforth should not be used. When
     * interest/yield bearing tokens are considered, only use tokens with a
     * constant balance mechanism such as Compound's cToken or the wrapped
     * version of Lido's staked ETH (wstETH).
     * ETH is not supported as collateral in v1. It has to be wrapped into WETH
       before deposit.
     * @param _poolParams Struct containing the pool specification:
     * - referenceAsset: The name of the reference asset (e.g., Tesla-USD or
         ETHGasPrice-GWEI).
     * - expiryTime: Expiration time of the position tokens expressed as a unix
         timestamp in seconds.
     * - floor: Value of underlying at or below which the short token will pay
         out the max amount and the long token zero. Expressed as an integer with
         18 decimals.
     * - inflection: Value of underlying at which the long token will payout
         out `gradient` and the short token `1-gradient`. Expressed as an
         integer with 18 decimals.
     * - cap: Value of underlying at or above which the long token will pay
         out the max amount and short token zero. Expressed as an integer with
         18 decimals.
     * - gradient: Long token payout at inflection. The short token payout at
         inflection is `1-gradient`. Expressed as an integer with collateral token
         decimals.
     * - collateralAmount: Collateral amount to be deposited into the pool to
         back the position tokens. Expressed as an integer with collateral token
         decimals.
     * - collateralToken: ERC20 collateral token address.
     * - dataProvider: Address that is supposed to report the final value of
         the reference asset.
     * - capacity: The maximum collateral amount that the pool can accept. Expressed
         as an integer with collateral token decimals.
     * - longRecipient: Address that shall receive the long position tokens. 
     *   Zero address is a valid input to enable conditional burn use cases.
     * - shortRecipient: Address that shall receive the short position tokens.
     *   Zero address is a valid input to enable conditional burn use cases.
     * - permissionedERC721Token: Address of ERC721 token that is allowed to transfer the
     *   position token. Zero address if position token is supposed to be permissionless.
     * @return poolId
     */
    function createContingentPool(PoolParams memory _poolParams)
        external
        returns (bytes32);

    /**
     * @notice Returns the pool parameters for a given pool Id. To
     * obtain the fees and settlement periods applicable for the pool,
     * use the `getFees` and `getSettlementPeriods` functions
     * respectively, passing in the returend `indexFees` and
     * `indexSettlementPeriods` as arguments.
     * @param _poolId Id of the pool.
     * @return Pool struct.
     */
    function getPoolParameters(bytes32 _poolId)
        external
        view
        returns (Pool memory);

    /**
     * @notice Returns the claims by collateral tokens for a given account.
     * @param _recipient Recipient address.
     * @param _collateralToken Collateral token address.
     * @return Fee claim amount.
     */
    function getClaim(address _collateralToken, address _recipient)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDIVAOracleTellor {
    // Thrown in the internal `_claimReward` function used in `claimReward`, 
    // `setFinalReferenceValue` and their respective batch versions if
    // rewards are claimed before a pool was confirmed.
    error NotConfirmedPool();

    // Thrown in `addTip` if user tries to add a tip for an already confirmed
    // pool.
    error AlreadyConfirmedPool();

    // Thrown in `addTip` if the tipping token implements a fee
    error FeeTokensNotSupported();

    // Thrown in `updateExcessDIVARewardRecipient` or constructor if the zero address
    // is passed as excess DIVA reward recipient address.
    error ZeroExcessDIVARewardRecipient();

    // Thrown in `setFinalReferenceValue` if there is no data reported after
    // the expiry time for the specified pool.
    error NoOracleSubmissionAfterExpiryTime();

    // Thrown in `setFinalReferenceValue` if user tries to call the function
    // before the minimum period undisputed period has passed.
    error MinPeriodUndisputedNotPassed();

    // Thrown in constructor if zero address is provided as ownershipContract.
    error ZeroOwnershipContractAddress();

    // Thrown in constructor if zero address is provided for DIVA Protocol contract.
    error ZeroDIVAAddress();

    // Thrown in governance related functions including `updateExcessDIVARewardRecipient`
    // `updateMaxDIVARewardUSD`, `revokePendingExcessDIVARewardRecipientUpdate`,
    // and `revokePendingMaxDIVARewardUSDUpdate` and `msg.sender` is not contract owner.
    error NotContractOwner(address _user, address _contractOwner);

    // Thrown in `updateExcessDIVARewardRecipient` if there is already a pending
    // excess DIVA reward recipient address update.
    error PendingExcessDIVARewardRecipientUpdate(
        uint256 _timestampBlock,
        uint256 _startTimeExcessDIVARewardRecipient
    );

    // Thrown in `updateMaxDIVARewardUSD` if there is already a pending max USD
    // DIVA reward update.
    error PendingMaxDIVARewardUSDUpdate(
        uint256 _timestampBlock,
        uint256 _startTimeMaxDIVARewardUSD
    );

    // Thrown in `revokePendingExcessDIVARewardRecipientUpdate` if the excess DIVA reward
    // recipient update to be revoked is already active.
    error ExcessDIVARewardRecipientAlreadyActive(
        uint256 _timestampBlock,
        uint256 _startTimeExcessDIVARewardRecipient
    );

    // Thrown in `revokePendingMaxDIVARewardUSDUpdate` if the max USD DIVA reward
    // update to be revoked is already active.
    error MaxDIVARewardUSDAlreadyActive(
        uint256 _timestampBlock,
        uint256 _startTimeMaxDIVARewardUSD
    );

    /**
     * @notice Emitted when the final reference value is set via the
     * `setFinalReferenceValue` function.
     * @param poolId The Id of the pool.
     * @param finalValue Tellor value expressed as an integer with 18 decimals.
     * @param expiryTime Pool expiry time as a unix timestamp in seconds.
     * @param timestamp Tellor value timestamp.
     */
    event FinalReferenceValueSet(
        bytes32 indexed poolId,
        uint256 finalValue,
        uint256 expiryTime,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a tip is added via the `addTip` function.
     * @param poolId The Id of the tipped pool.
     * @param tippingToken Tipping token address.
     * @param amount Tipping token amount expressed as an integer with
     * tipping token decimals.
     * @param tipper Tipper address.
     */
    event TipAdded(
        bytes32 poolId,
        address tippingToken,
        uint256 amount,
        address tipper
    );

    /**
     * @notice Emitted when the reward is claimed via the in `claimReward`
     * function.
     * @param poolId The Id of the pool.
     * @param recipient Address of the tip recipient.
     * @param tippingToken Tipping token address.
     * @param amount Claimed amount expressed as an integer with tipping
     * token decimals.
     */
    event TipClaimed(
        bytes32 poolId,
        address recipient,
        address tippingToken,
        uint256 amount
    );

    /**
     * @notice Emitted when the excess DIVA reward recipient is updated via
     * the `updateExcessDIVARewardRecipient` function.
     * @param from Address that initiated the change (contract owner).
     * @param excessDIVARewardRecipient New excess DIVA reward recipient address.
     * @param startTimeExcessDIVARewardRecipient Timestamp in seconds since epoch at
     * which the new excess DIVA reward recipient will be activated.
     */
    event ExcessDIVARewardRecipientUpdated(
        address indexed from,
        address indexed excessDIVARewardRecipient,
        uint256 startTimeExcessDIVARewardRecipient
    );

    /**
     * @notice Emitted when the max USD DIVA reward is updated via the
     * `updateMaxDIVARewardUSD` function.
     * @param from Address that initiated the change (contract owner).
     * @param maxDIVARewardUSD New max USD DIVA reward expressed as an
     * integer with 18 decimals.
     * @param startTimeMaxDIVARewardUSD Timestamp in seconds since epoch at
     * which the new max USD DIVA reward will be activated.
     */
    event MaxDIVARewardUSDUpdated(
        address indexed from,
        uint256 maxDIVARewardUSD,
        uint256 startTimeMaxDIVARewardUSD
    );

    /**
     * @notice Emitted when a pending excess DIVA reward recipient update is revoked
     * via the `revokePendingExcessDIVARewardRecipientUpdate` function.
     * @param revokedBy Address that initiated the revocation.
     * @param revokedExcessDIVARewardRecipient Pending excess DIVA reward recipient that was
     * revoked.
     * @param restoredExcessDIVARewardRecipient Previous excess DIVA reward recipient that was
     * restored.
     */
    event PendingExcessDIVARewardRecipientUpdateRevoked(
        address indexed revokedBy,
        address indexed revokedExcessDIVARewardRecipient,
        address indexed restoredExcessDIVARewardRecipient
    );

    /**
     * @notice Emitted when a pending max USD DIVA reward update is revoked
     * via the `revokePendingMaxDIVARewardUSDUpdate` function.
     * @param revokedBy Address that initiated the revocation.
     * @param revokedMaxDIVARewardUSD Pending max USD DIVA reward that was
     * revoked.
     * @param restoredMaxDIVARewardUSD Previous max USD DIVA reward that was
     * restored.
     */
    event PendingMaxDIVARewardUSDUpdateRevoked(
        address indexed revokedBy,
        uint256 revokedMaxDIVARewardUSD,
        uint256 restoredMaxDIVARewardUSD
    );

    // Struct for `batchSetFinalReferenceValue` function input.
    struct ArgsBatchSetFinalReferenceValue {
        bytes32 poolId;
        address[] tippingTokens;
        bool claimDIVAReward;
    }

    // Struct for `batchAddTip` function input.
    struct ArgsBatchAddTip {
        bytes32 poolId;
        uint256 amount;
        address tippingToken;
    }
    
    // Struct for `batchClaimReward` function input.
    struct ArgsBatchClaimReward {
        bytes32 poolId;
        address[] tippingTokens;
        bool claimDIVAReward;
    }

    // Struct for `getTippingTokens` function input.
    struct ArgsGetTippingTokens {
        bytes32 poolId;
        uint256 startIndex;
        uint256 endIndex;
    }

    // Struct for `getTipAmounts` function input.
    struct ArgsGetTipAmounts {
        bytes32 poolId;
        address[] tippingTokens;
    }

    // Struct for `getPoolIdsForReporters` function input.
    struct ArgsGetPoolIdsForReporters {
        address reporter;
        uint256 startIndex;
        uint256 endIndex;
    }

    /**
     * @notice Function to set the final reference value for a given `_poolId`.
     * The first value that was submitted to the Tellor contract after the pool
     * expiration and remained undisputed for at least 12 hours will be passed
     * on to the DIVA smart contract for settlement.
     * @dev Function must be triggered within the submission window of the pool.
     * @param _poolId The Id of the pool.
     * @param _tippingTokens Array of tipping tokens to claim.
     * @param _claimDIVAReward Flag indicating whether to claim the DIVA reward.
     */
    function setFinalReferenceValue(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external;

    /**
     * @notice Batch version of `setFinalReferenceValue`.
     * @param _argsBatchSetFinalReferenceValue List containing poolIds, tipping
     * tokens, and `claimDIVAReward` flag.
     */
    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[] calldata _argsBatchSetFinalReferenceValue
    ) external;

    /**
     * @notice Function to tip a pool. Tips can be added in any
     * ERC20 token until the final value has been submitted and
     * confirmed in DIVA Protocol by successfully calling the
     * `setFinalReferenceValue` function. Tips can e claimed via the
     * `claimReward` function after final value confirmation.
     * @dev Function will revert if `msg.sender` has insufficient
     * allowance.
     * @param _poolId The Id of the pool.
     * @param _amount The amount to tip expressed as an integer
     * with tipping token decimals.
     * @param _tippingToken Tipping token address.
     */
    function addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external;

    /**
     * @notice Batch version of `addTip`.
     * @param _argsBatchAddTip List containing poolIds, amounts
     * and tipping tokens.
     */
    function batchAddTip(
        ArgsBatchAddTip[] calldata _argsBatchAddTip
    ) external;

    /**
     * @notice Function to claim tips and/or DIVA reward.
     * @dev Claiming rewards is only possible after the final value has been
     * submitted and confirmed in DIVA Protocol by successfully calling
     * the `setFinalReferenceValue` function. Anyone can trigger this
     * function to transfer the rewards to the eligible reporter.
     * 
     * If no tipping tokens are provided and `_claimDIVAReward` is
     * set to `false`, the function will not execute anything, but will
     * not revert.
     * @param _poolId The Id of the pool.
     * @param _tippingTokens Array of tipping tokens to claim.
     * @param _claimDIVAReward Flag indicating whether to claim the
     * DIVA reward.
     */
    function claimReward(
        bytes32 _poolId,
        address[] memory _tippingTokens,
        bool _claimDIVAReward
    ) external;

    /**
     * @notice Batch version of `claimReward`.
     * @param _argsBatchClaimReward List containing poolIds, tipping
     * tokens, and `claimDIVAReward` flag.
     */
    function batchClaimReward(
        ArgsBatchClaimReward[] calldata _argsBatchClaimReward
    ) external;

    /**
     * @notice Function to update the excess DIVA reward recipient address.
     * @dev Activation is restricted to the contract owner and subject
     * to a 3-day delay.
     *
     * Reverts if:
     * - `msg.sender` is not contract owner.
     * - provided address equals zero address.
     * - there is already a pending excess DIVA reward recipient address update.
     * @param _newExcessDIVARewardRecipient New excess DIVA reward recipient address.
     */
    function updateExcessDIVARewardRecipient(address _newExcessDIVARewardRecipient) external;

    /**
     * @notice Function to update the maximum amount of DIVA reward that
     * a reporter can receive, denominated in USD.
     * @dev Activation is restricted to the contract owner and subject
     * to a 3-day delay.
     *
     * Reverts if:
     * - `msg.sender` is not contract owner.
     * - there is already a pending amount update.
     * @param _newMaxDIVARewardUSD New amount expressed as an integer with
     * 18 decimals.
     */
    function updateMaxDIVARewardUSD(uint256 _newMaxDIVARewardUSD) external;

    /**
     * @notice Function to revoke a pending excess DIVA reward recipient update
     * and restore the previous one.
     * @dev Reverts if:
     * - `msg.sender` is not contract owner.
     * - new excess DIVA reward recipient is already active.
     */
    function revokePendingExcessDIVARewardRecipientUpdate() external;

    /**
     * @notice Function to revoke a pending max USD DIVA reward update
     * and restore the previous one. Only callable by contract owner.
     * @dev Reverts if:
     * - `msg.sender` is not contract owner.
     * - new amount is already active.
     */
    function revokePendingMaxDIVARewardUSDUpdate() external;

    /**
     * @notice Function to return whether the Tellor adapter's data feed
     * is challengeable inside DIVA Protocol.
     * @dev In this implementation, the function always returns `false`,
     * which means that the first value submitted to DIVA Protocol
     * will determine the payouts, and users can start claiming their
     * payouts thereafter.
     */
    function getChallengeable() external pure returns (bool);

    /**
     * @notice Function to return the excess DIVA reward recipient info, including
     * the last update, its activation time and the previous value.
     * @dev The initial excess DIVA reward recipient is set when the contract is deployed.
     * The previous excess DIVA reward recipient is set to the zero address initially.
     * @return previousExcessDIVARewardRecipient Previous excess DIVA reward recipient address.
     * @return excessDIVARewardRecipient Latest update of the excess DIVA reward recipient address.
     * @return startTimeExcessDIVARewardRecipient Timestamp in seconds since epoch at which
     * `excessDIVARewardRecipient` is activated.
     */
    function getExcessDIVARewardRecipientInfo()
        external
        view
        returns (
            address previousExcessDIVARewardRecipient,
            address excessDIVARewardRecipient,
            uint256 startTimeExcessDIVARewardRecipient
        );

    /**
     * @notice Function to return the max USD DIVA reward info, including
     * the last update, its activation time and the previous value.
     * @dev The initial value is set when the contract is deployed.
     * The previous value is set to zero initially.
     * @return previousMaxDIVARewardUSD Previous value.
     * @return maxDIVARewardUSD Latest update of the value.
     * @return startTimeMaxDIVARewardUSD Timestamp in seconds since epoch at which
     * `maxDIVARewardUSD` is activated.
     */
    function getMaxDIVARewardUSDInfo()
        external
        view
        returns (
            uint256 previousMaxDIVARewardUSD,
            uint256 maxDIVARewardUSD,
            uint256 startTimeMaxDIVARewardUSD
        );

    /**
     * @notice Function to return the minimum period (in seconds) a reported
     * value has to remain undisputed in order to be considered valid.
     * Hard-coded to 12 hours (= 43'200 seconds) in this implementation.
     */
    function getMinPeriodUndisputed() external pure returns (uint32);

    /**
     * @notice Function to return the number of tipping tokens for a given
     * set of poolIds.
     * @param _poolIds Array of poolIds.
     */
    function getTippingTokensLengthForPoolIds(bytes32[] calldata _poolIds)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Function to return an array of tipping tokens for the given struct
     * array of poolIds, along with start and end indices to manage the return
     * size of the array.
     * @param _argsGetTippingTokens List containing poolId,
     * start index and end index.
     */
    function getTippingTokens(
        ArgsGetTippingTokens[] calldata _argsGetTippingTokens
    ) external view returns (address[][] memory);

    /**
     * @notice Function to return the tipping amounts for a given set of poolIds
     * and tipping tokens.
     * @param _argsGetTipAmounts List containing poolIds and tipping
     * tokens.
     */
    function getTipAmounts(ArgsGetTipAmounts[] calldata _argsGetTipAmounts)
        external
        view
        returns (uint256[][] memory);

    /**
     * @notice Function to return the list of reporter addresses that are entitled
     * to receive rewards for a given list of poolIds.
     * @dev If a value has been reported to the Tellor contract but hasn't been 
     * pulled into the DIVA contract via the `setFinalReferenceValue` function yet,
     * the function returns the zero address.
     * @param _poolIds Array of poolIds.
     */
    function getReporters(bytes32[] calldata _poolIds)
        external
        view
        returns (address[] memory);

    /**
     * @notice Function to return the number of poolIds that a given list of
     * reporter addresses are eligible to claim rewards for.
     * @param _reporters List of reporter addresses.
     */
    function getPoolIdsLengthForReporters(address[] calldata _reporters)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Function to return a list of poolIds that a given list of reporters
     * is eligible to claim rewards for.
     * @dev It takes a list of reporter addresses, as well as the start and end
     * indices as input to manage the return size of the array.
     * @param _argsGetPoolIdsForReporters List containing reporter
     * address, start index and end index.
     */
    function getPoolIdsForReporters(
        ArgsGetPoolIdsForReporters[] calldata _argsGetPoolIdsForReporters
    ) external view returns (bytes32[][] memory);

    /**
     * @notice Function to return the DIVA contract address that the
     * Tellor adapter is linked to.
     * @dev The address is set at contract deployment and cannot be modified.
     */
    function getDIVAAddress() external view returns (address);

    /**
     * @notice Returns the DIVA ownership contract address that stores
     * the contract owner.
     * @dev The owner can be obtained by calling the `getOwner` function
     * at the returned contract address.
     */
    function getOwnershipContract() external view returns (address);

    /**
     * @notice Returns the activation delay (in seconds) for governance
     * related updates. Hard-coded to 3 days (= 259'200 seconds).
     */
    function getActivationDelay() external pure returns (uint256);

    /**
     * @notice Function to return the query data and Id for a given poolId
     * which are required for reporting values via Tellor's `submitValue`
     * function.
     * @param _poolId The Id of the pool.
     */
    function getQueryDataAndId(
        bytes32 _poolId
    ) external view returns (bytes memory, bytes32);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITellor {
    //Controller
    function addresses(bytes32) external view returns (address);

    function uints(bytes32) external view returns (uint256);

    function burn(uint256 _amount) external;

    function changeDeity(address _newDeity) external;

    function changeOwner(address _newOwner) external;
    function changeUint(bytes32 _target, uint256 _amount) external;

    function migrate() external;

    function mint(address _reciever, uint256 _amount) external;

    function init() external;

    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);

    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);

    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);

    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);

    function getAddressVars(bytes32 _data) external view returns (address);

    function getUintVar(bytes32 _data) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function isMigrated(address _addy) external view returns (bool);

    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);

    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _amount)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function changeStakingStatus(address _reporter, uint256 _status) external;

    function slashReporter(address _reporter, address _disputer) external;

    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);

    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256);

    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _d,
            uint256 _t
        );

    function getNewValueCountbyQueryId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    //Governance
    enum VoteResult {
        FAILED,
        PASSED,
        INVALID
    }

    function setApprovedFunction(bytes4 _func, bool _val) external;

    function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

    function delegate(address _delegate) external;

    function delegateOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (address);

    function executeVote(uint256 _disputeId) external;

    function proposeVote(
        address _contract,
        bytes4 _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external;

    function tallyVotes(uint256 _disputeId) external;

    function governance() external view returns (address);

    function updateMinDisputeFee() external;

    function verify() external pure returns (uint256);

    function vote(
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function voteFor(
        address[] calldata _addys,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function getDelegateInfo(address _holder)
        external
        view
        returns (address, uint256);

    function isFunctionApproved(bytes4 _func) external view returns (bool);

    function isApprovedGovernanceContract(address _contract)
        external
        returns (bool);

    function getVoteRounds(bytes32 _hash)
        external
        view
        returns (uint256[] memory);

    function getVoteCount() external view returns (uint256);

    function getVoteInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256[9] memory,
            bool[2] memory,
            VoteResult,
            bytes memory,
            bytes4,
            address[2] memory
        );

    function getDisputeInfo(uint256 _disputeId)
        external
        view
        returns (
            uint256,
            uint256,
            bytes memory,
            address
        );

    function getOpenDisputesOnId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function didVote(uint256 _disputeId, address _voter)
        external
        view
        returns (bool);

    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getReportingLock() external view returns (uint256);

    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address);

    function reportingLock() external view returns (uint256);

    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;

    function changeReportingLock(uint256 _newReportingLock) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getDataBefore(bytes32 _queryId, uint256 _timestamp) external view returns(bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);
    function getTimeOfLastNewValue() external view returns(uint256);
    function depositStake(uint256 _amount) external;
    function requestStakingWithdraw(uint256 _amount) external;

    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;

    function migrateFor(address _destination, uint256 _amount) external;

    function rescue51PercentAttack(address _tokenHolder) external;

    function rescueBrokenDataReporting() external;

    function rescueFailedUpdate() external;

    //Tellor 360
    function addStakingRewards(uint256 _amount) external;

    function _sliceUint(bytes memory _b)
        external
        pure
        returns (uint256 _number);

    function claimOneTimeTip(bytes32 _queryId, uint256[] memory _timestamps)
        external;

    function claimTip(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external;

    function fee() external view returns (uint256);

    function feedsWithFunding(uint256) external view returns (bytes32);

    function fundFeed(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _amount
    ) external;

    function getCurrentFeeds(bytes32 _queryId)
        external
        view
        returns (bytes32[] memory);

    function getCurrentTip(bytes32 _queryId) external view returns (uint256);

    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory _value, uint256 _timestampRetrieved);

    function getDataFeed(bytes32 _feedId)
        external
        view
        returns (Autopay.FeedDetails memory);

    function getFundedFeeds() external view returns (bytes32[] memory);

    function getFundedQueryIds() external view returns (bytes32[] memory);

    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getMultipleValuesBefore(
        bytes32 _queryId,
        uint256 _timestamp,
        uint256 _maxAge,
        uint256 _maxCount
    )
        external
        view
        returns (uint256[] memory _values, uint256[] memory _timestamps);

    function getPastTipByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (Autopay.Tip memory);

    function getPastTipCount(bytes32 _queryId) external view returns (uint256);

    function getPastTips(bytes32 _queryId)
        external
        view
        returns (Autopay.Tip[] memory);

    function getQueryIdFromFeedId(bytes32 _feedId)
        external
        view
        returns (bytes32);

    function getRewardAmount(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external view returns (uint256 _cumulativeReward);

    function getRewardClaimedStatus(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool);

    function getTipsByAddress(address _user) external view returns (uint256);

    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool);

    function queryIdFromDataFeedId(bytes32) external view returns (bytes32);

    function queryIdsWithFunding(uint256) external view returns (bytes32);

    function queryIdsWithFundingIndex(bytes32) external view returns (uint256);

    function setupDataFeed(
        bytes32 _queryId,
        uint256 _reward,
        uint256 _startTime,
        uint256 _interval,
        uint256 _window,
        uint256 _priceThreshold,
        uint256 _rewardIncreasePerSecond,
        bytes memory _queryData,
        uint256 _amount
    ) external;

    function tellor() external view returns (address);

    function tip(
        bytes32 _queryId,
        uint256 _amount,
        bytes memory _queryData
    ) external;

    function tips(bytes32, uint256)
        external
        view
        returns (uint256 amount, uint256 timestamp);

    function token() external view returns (address);

    function userTipsTotal(address) external view returns (uint256);

    function valueFor(bytes32 _id)
        external
        view
        returns (
            int256 _value,
            uint256 _timestamp,
            uint256 _statusCode
        );
}

interface Autopay {
    struct FeedDetails {
        uint256 reward;
        uint256 balance;
        uint256 startTime;
        uint256 interval;
        uint256 window;
        uint256 priceThreshold;
        uint256 rewardIncreasePerSecond;
        uint256 feedsWithFundingIndex;
    }

    struct Tip {
        uint256 amount;
        uint256 timestamp;
    }
    function getStakeAmount() external view returns(uint256);
    function stakeAmount() external view returns(uint256);
    function token() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.13 where SafeMath is no
 * longer required to handle overflows
 */

library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands
     * as fixed-point decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is
     * evaluated, so that product must be less than 2**256. As this is an
     * integer division, the internal division always rounds down. This helps
     * save on gas. Rounding is more expensive on gas.
     */
    function multiplyDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Divide by UNIT to remove the extra factor introduced by the product
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Reintroduce the UNIT factor that will be divided out by y
        return (x * UNIT) / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ITellor} from "./interfaces/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the oracle address in storage
     * @param _tellor is the Tellor Oracle address
     */
    constructor(address payable _tellor) {
        require(_tellor != address(0), "Zero Tellor address");
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Retrieves the next value for the queryId after the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp after which to search for next value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (bool _found, uint256 _index) = getIndexForDataAfter(
            _queryId,
            _timestamp
        );
        if (!_found) {
            return ("", 0);
        }
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = retrieveData(_queryId, _timestampRetrieved);
        return (_value, _timestampRetrieved);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);
        if (_count == 0) return (false, 0);
        _count--;
        bool _search = true; // perform binary search
        uint256 _middle = 0;
        uint256 _start = 0;
        uint256 _end = _count;
        uint256 _timestampRetrieved;
        // checking boundaries to short-circuit the algorithm
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _end);
        if (_timestampRetrieved <= _timestamp) return (false, 0);
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _start);
        if (_timestampRetrieved > _timestamp) {
            // candidate found, check for disputes
            _search = false;
        }
        // since the value is within our boundaries, do a binary search
        while (_search) {
            _middle = (_end + _start) / 2;
            _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _middle
            );
            if (_timestampRetrieved > _timestamp) {
                // get immediate previous value
                uint256 _prevTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle - 1
                );
                if (_prevTime <= _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                } else {
                    // look from start to middle -1(prev value)
                    _end = _middle - 1;
                }
            } else {
                // get immediate next value
                uint256 _nextTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle + 1
                );
                if (_nextTime > _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                    _middle++;
                    _timestampRetrieved = _nextTime;
                } else {
                    // look from middle + 1(next value) to end
                    _start = _middle + 1;
                }
            }
        }
        // candidate found, check for disputed values
        if (!isInDispute(_queryId, _timestampRetrieved)) {
            // _timestampRetrieved is correct
            return (true, _middle);
        } else {
            // iterate forward until we find a non-disputed value
            while (
                isInDispute(_queryId, _timestampRetrieved) && _middle < _count
            ) {
                _middle++;
                _timestampRetrieved = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle
                );
            }
            if (
                _middle == _count && isInDispute(_queryId, _timestampRetrieved)
            ) {
                return (false, 0);
            }
            // _timestampRetrieved is correct
            return (true, _middle);
        }
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    /**
     * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find a corresponding reporter for
     * @return address of the reporter who reported the value for the data ID at the given timestamp
     */
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (address)
    {
        return tellor.getReporterByTimestamp(_queryId, _timestamp);
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the id to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return tellor.isInDispute(_queryId, _timestamp);
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }
}