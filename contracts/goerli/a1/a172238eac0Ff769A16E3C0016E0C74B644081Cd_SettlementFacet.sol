// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {LibDIVA} from "../libraries/LibDIVA.sol";
import {LibDIVAStorage} from "../libraries/LibDIVAStorage.sol";

contract SettlementFacet is ISettlement, ReentrancyGuard {
    function setFinalReferenceValue(
        uint256 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) external override {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        _setFinalReferenceValue(
            _poolId,
            _finalReferenceValue,
            _allowChallenge,
            ps,
            gs
        );
    }

    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[]
            calldata _argsBatchSetFinalReferenceValue
    ) external override {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        uint256 len = _argsBatchSetFinalReferenceValue.length;
        for (uint256 i = 0; i < len; ) {
            _setFinalReferenceValue(
                _argsBatchSetFinalReferenceValue[i].poolId,
                _argsBatchSetFinalReferenceValue[i].finalReferenceValue,
                _argsBatchSetFinalReferenceValue[i].allowChallenge,
                ps,
                gs
            );
            unchecked {
                ++i;
            }
        }
    }

    function challengeFinalReferenceValue(
        uint256 _poolId,
        uint256 _proposedFinalReferenceValue
    ) external override {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        _challengeFinalReferenceValue(
            _poolId,
            _proposedFinalReferenceValue,
            ps,
            gs
        );
    }

    function batchChallengeFinalReferenceValue(
        ArgsBatchChallengeFinalReferenceValue[]
            calldata _argsBatchChallengeFinalReferenceValue
    ) external override {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        uint256 len = _argsBatchChallengeFinalReferenceValue.length;
        for (uint256 i = 0; i < len; ) {
            _challengeFinalReferenceValue(
                _argsBatchChallengeFinalReferenceValue[i].poolId,
                _argsBatchChallengeFinalReferenceValue[i]
                    .proposedFinalReferenceValue,
                ps,
                gs
            );
            unchecked {
                ++i;
            }
        }
    }

    function redeemPositionToken(address _positionToken, uint256 _amount)
        external
        override
        nonReentrant
    {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        _redeemPositionToken(_positionToken, _amount, ps, gs);
    }

    function batchRedeemPositionToken(
        ArgsBatchRedeemPositionToken[] calldata _argsBatchRedeemPositionToken
    ) external override nonReentrant {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        uint256 len = _argsBatchRedeemPositionToken.length;
        for (uint256 i = 0; i < len; ) {
            _redeemPositionToken(
                _argsBatchRedeemPositionToken[i].positionToken,
                _argsBatchRedeemPositionToken[i].amount,
                ps,
                gs
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Updates status, timestamp and finalReferenceValue (latter if
     * status is not "Challenged". Emits a `StatusChanged` event on success.
     * @param _poolId Pool Id for which the updates are made.
     * @param _newStatus New status of `finalReferenceValue`.
     * @param _finalReferenceValue The proposed final value by the
     * caller expressed as an integer with 18 decimals.
     */
    function _updateFinalReferenceValueState(
        uint256 _poolId,
        LibDIVAStorage.Status _newStatus,
        uint256 _finalReferenceValue
    ) internal {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        if (_newStatus != LibDIVAStorage.Status.Challenged) {
            _pool.finalReferenceValue = _finalReferenceValue;
        }

        _pool.statusFinalReferenceValue = _newStatus;
        _pool.statusTimestamp = block.timestamp;

        // Log the new status, the caller, the poolId and the proposed value
        // by the challenger
        emit StatusChanged(
            _newStatus,
            msg.sender,
            _poolId,
            _finalReferenceValue
        );
    }

    /**
     * @dev Confirm final reference value, allocated fees and set payout amounts.
     * @param _poolId Pool Id for which the final reference value is confirmed.
     * @param _receiverProtocolFee Address of protocol fee recipient.
     * @param _receiverSettlementFee Address of settlement fee recipient.
     * @param _finalReferenceValue The final reference value to be
     * confirmed expressed as an integer with 18 decimals.
     */
    function _confirmFinalReferenceValue(
        uint256 _poolId,
        address _receiverProtocolFee,
        address _receiverSettlementFee,
        uint256 _finalReferenceValue
    ) internal {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        _updateFinalReferenceValueState(
            _poolId,
            LibDIVAStorage.Status.Confirmed,
            _finalReferenceValue
        );

        // Get collateral token decimals which is used for scaling
        // inside `_calcAndAllocateFeeClaim`
        uint8 _decimals = IERC20Metadata(_pool.collateralToken).decimals();

        // Get the collateral balance to use as the fee basis inside
        // `_calcAndAllocateFeeClaim`
        uint256 _collateralBalance = _pool.collateralBalance;

        // Get fee parameters applicable for given `_poolId`
        LibDIVAStorage.Fees memory _fees = LibDIVA._getFees(_poolId);

        // Allocate fees to the DIVA treasury and the data provider
        LibDIVA._calcAndAllocateFeeClaim(
            _poolId,
            _fees.protocolFee,
            _receiverProtocolFee,
            _collateralBalance,
            _decimals
        );
        LibDIVA._calcAndAllocateFeeClaim(
            _poolId,
            _fees.settlementFee,
            _receiverSettlementFee,
            _collateralBalance,
            _decimals
        );

        // Set payout amounts in pool parameters (net of fees)
        LibDIVA._setPayoutAmount(_poolId, _decimals);
    }

    function _redeemPositionToken(
        address _positionToken,
        uint256 _amount,
        LibDIVAStorage.PoolStorage storage _ps,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) private {
        // Confirm that functionality is not paused
        if (block.timestamp < _gs.pauseReturnCollateralUntil)
            revert ReturnCollateralPaused();

        // Get reference to the provided `_positionToken`. Reverts if
        // `_positionToken` is zero address
        IPositionToken _positionTokenInstance = IPositionToken(_positionToken);

        // Read the poolId from the position token
        uint256 _poolId = _positionTokenInstance.poolId();

        // Load corresponding pool data
        LibDIVAStorage.Pool storage _pool = _ps.pools[_poolId];

        // Initialize SettlemetPeriods struct
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = _gs
            .updateIdToSettlementPeriods[_gs.maxUpdateIdToSettlementPeriods];

        // Check that position token address is valid
        if (
            _pool.shortToken != _positionToken &&
            _pool.longToken != _positionToken
        ) revert InvalidPositionToken();

        // Check that a reference value was already set
        if (_pool.statusFinalReferenceValue == LibDIVAStorage.Status.Open)
            revert FinalReferenceValueNotSet();

        // Scenarios under which the submitted value will be set to Confirmed at
        // first redemption
        if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Submitted
        ) {
            // Scenario 1: Data provider submitted a final value and it was
            // not challenged during the challenge period. In that case the
            // submitted value is considered the final one.
            if (
                block.timestamp <=
                _pool.statusTimestamp + _settlementPeriods.challengePeriod
            ) revert ChallengePeriodNotExpired();

            _confirmFinalReferenceValue(
                _poolId,
                _gs.treasury,
                _pool.dataProvider,
                _pool.finalReferenceValue
            );
        } else if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Challenged
        ) {
            // Scenario 2: Submitted value was challenged, but data provider did not
            // respond during the review period. In that case, the initially submitted
            // value is considered the final one.
            if (
                block.timestamp <=
                _pool.statusTimestamp + _settlementPeriods.reviewPeriod
            ) revert ReviewPeriodNotExpired();
            _confirmFinalReferenceValue(
                _poolId,
                _gs.treasury,
                _pool.dataProvider,
                _pool.finalReferenceValue
            );
        }

        uint8 _decimals = (IERC20Metadata(_pool.collateralToken)).decimals();

        // If status is "Confirmed", burn position tokens and return collateral to user
        if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Confirmed
        ) {
            // Burn position tokens
            _positionTokenInstance.burn(msg.sender, _amount);

            uint256 _tokenPayoutAmount;

            if (_positionToken == _pool.longToken) {
                _tokenPayoutAmount = _pool.payoutLong; // net of fees
            } else {
                // Can only be shortToken due to require statement at the beginning

                _tokenPayoutAmount = _pool.payoutShort; // net of fees
            }

            // Calculate collateral amount to return
            uint256 _amountToReturn = (_tokenPayoutAmount * _amount) /
                (10**uint256(_decimals)); // decimal math with integers

            // Return collateral to caller and reduce `collateralBalance` accordingly
            LibDIVA._returnCollateral(
                _poolId,
                _pool.collateralToken,
                msg.sender,
                _amountToReturn
            );

            // Log redemption of position token
            emit PositionTokenRedeemed(
                _poolId,
                _positionToken,
                _amount,
                _amountToReturn,
                msg.sender
            );
        }
    }

    function _challengeFinalReferenceValue(
        uint256 _poolId,
        uint256 _proposedFinalReferenceValue,
        LibDIVAStorage.PoolStorage storage _ps,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) private {
        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = _ps.pools[_poolId];

        // Initialize SettlemetPeriods struct
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = _gs
            .updateIdToSettlementPeriods[_gs.maxUpdateIdToSettlementPeriods];

        // Check that user holds position tokens
        if (
            IPositionToken(_pool.shortToken).balanceOf(msg.sender) == 0 &&
            IPositionToken(_pool.longToken).balanceOf(msg.sender) == 0
        ) revert NoPositionTokens();

        if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Submitted
        ) {
            // Check that challenge period did not expire yet
            if (
                block.timestamp >
                _pool.statusTimestamp + _settlementPeriods.challengePeriod
            ) revert ChallengePeriodExpired();

            // First challenge updates the status to "Challenged"
            _updateFinalReferenceValueState(
                _poolId,
                LibDIVAStorage.Status.Challenged,
                _proposedFinalReferenceValue
            );
        } else if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Challenged
        ) {
            // Check that review period did not expire yet
            if (
                block.timestamp >
                _pool.statusTimestamp + _settlementPeriods.reviewPeriod
            ) revert ReviewPeriodExpired();

            // Log the proposed value by the challenger. Status and timestamp
            // do not change.
            emit StatusChanged(
                LibDIVAStorage.Status.Challenged,
                msg.sender,
                _poolId,
                _proposedFinalReferenceValue
            );
        } else {
            // Value cannot be challenged if status is "Open" or already "Confirmed"
            revert NothingToChallenge();
        }
    }

    function _setFinalReferenceValue(
        uint256 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge,
        LibDIVAStorage.PoolStorage storage _ps,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) private {
        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = _ps.pools[_poolId];

        // Initialize SettlemetPeriods struct
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = _gs
            .updateIdToSettlementPeriods[_gs.maxUpdateIdToSettlementPeriods];

        // Check status of final reference value
        if (
            _pool.statusFinalReferenceValue != LibDIVAStorage.Status.Open &&
            _pool.statusFinalReferenceValue != LibDIVAStorage.Status.Challenged
        ) revert AlreadySubmittedOrConfirmed();

        if (_pool.statusFinalReferenceValue == LibDIVAStorage.Status.Open) {
            // Check that the contingent pool already expired
            if (block.timestamp < _pool.expiryTime) revert PoolNotExpired();

            // Calculate end of submission period
            uint256 submissionEndTime = _pool.expiryTime +
                _settlementPeriods.submissionPeriod;

            // If within the submission period ...
            if (block.timestamp <= submissionEndTime) {
                // Check that `msg.sender` is the data provider for the given pool
                if (msg.sender != _pool.dataProvider) revert NotDataProvider();

                // If challenge is disabled, the submitted final value is directly confirmed
                if (_allowChallenge == false) {
                    // Confirm final value
                    _confirmFinalReferenceValue(
                        _poolId,
                        _gs.treasury,
                        _pool.dataProvider,
                        _finalReferenceValue
                    );
                } else {
                    // If challenge is enabled, update status to "Submitted" which marks
                    // the start of the challenge period. `statusTimestamp` is set further
                    // down in the code

                    _updateFinalReferenceValueState(
                        _poolId,
                        LibDIVAStorage.Status.Submitted,
                        _finalReferenceValue
                    );
                }
            }
            // If within the fallback period (the case when the data provider
            // failed to submit a value)
            else if (
                block.timestamp > submissionEndTime &&
                block.timestamp <=
                submissionEndTime + _settlementPeriods.fallbackSubmissionPeriod
            ) {
                // Check that the `msg.sender` is the fallback data provider
                if (msg.sender != _gs.fallbackDataProvider)
                    revert NotFallbackDataProvider();

                _confirmFinalReferenceValue(
                    _poolId,
                    _gs.treasury,
                    _gs.fallbackDataProvider,
                    _finalReferenceValue
                );
            }
            // If both the data provider and fallback do not provide a value,
            // anyone can trigger this function to set and confirm the final
            // reference value equal to inflection
            else {
                // Confirm final value
                _confirmFinalReferenceValue(
                    _poolId,
                    _gs.treasury,
                    _gs.treasury,
                    _pool.inflection
                );
            }
        } else if (
            _pool.statusFinalReferenceValue == LibDIVAStorage.Status.Challenged
        ) {
            // Calculate end of review period
            uint256 reviewEndTime = _pool.statusTimestamp +
                _settlementPeriods.reviewPeriod;

            // Check that called inside the review period. No pool expiry end check
            // needed here as "Challenged" status cannot be before expiry end.
            if (block.timestamp > reviewEndTime) revert ReviewPeriodExpired();

            // Check that the `msg.sender` is the data provider for the given pool
            if (msg.sender != _pool.dataProvider) revert NotDataProvider();

            // If challenge is disabled or the data provider submits the same
            // value as before following a challenge, the submitted final value
            // is directly confirmed
            if (
                (_allowChallenge == false) ||
                (_finalReferenceValue == _pool.finalReferenceValue)
            ) {
                _confirmFinalReferenceValue(
                    _poolId,
                    _gs.treasury,
                    _pool.dataProvider,
                    _finalReferenceValue
                );
            } else {
                // If challenge is enabled, status is set to "Submitted" and
                // position token holders get the opportunity to challenge again.

                _updateFinalReferenceValueState(
                    _poolId,
                    LibDIVAStorage.Status.Submitted,
                    _finalReferenceValue
                );
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Position token contract
 * @dev The `PositionToken` contract inherits from ERC20 contract and stores 
 * the Id of the pool that the position token is linked to. It implements a 
 * `mint` and a `burn` function which can only be called by the `PositionToken`
 * contract owner.
 *
 * Two `PositionToken` contracts are deployed during pool creation process 
 * (`createContingentPool`) with Diamond contract being set as the owner. 
 * The `mint` function is used during pool creation (`createContingentPool`) 
 * and addition of liquidity (`addLiquidity`). Position tokens are burnt 
 * during token redemption (`redeemPositionToken`) and removal of liquidity
 * (`removeLiquidity`). The address of the position tokens is stored in the 
 * pool parameters within Diamond contract and used to verify the tokens that 
 * a user sends back to withdraw collateral.
 *
 * Position tokens have the same number of decimals as the underlying 
 * collateral token.
 */
interface IPositionToken is IERC20Upgradeable {
    /**
     * @dev Function to initialize the position token instance
     */
    function initialize(
        string memory symbol_, // name is set equal to symbol
        uint256 poolId_,
        uint8 decimals_,
        address owner_
    ) external;

    /**
     * @dev Function to mint ERC20 position tokens. Called during 
     * `createContingentPool` and `addLiquidity`. Can only be called by the
     * owner of the position token which is the Diamond contract in the 
     * context of DIVA.
     * @param _recipient The account receiving the position tokens.
     * @param _amount The number of position tokens to mint.
     */
    function mint(
        address _recipient, 
        uint256 _amount
    )
        external;

    /**
     * @dev Function to burn position tokens. Called within `redeemPositionToken`
     * and `removeLiquidity`. Can only be called by the owner of the position
     * token which is the Diamond contract in the context of DIVA.
     * @param _redeemer Address redeeming positions tokens in return for
     * collateral.
     * @param _amount The number of position tokens to burn.
     */
    function burn(
        address _redeemer, 
        uint256 _amount
    )
        external;

    /**
     * @dev Returns the Id of the contingent pool that the position token is 
     * linked to in the context of DIVA.
     */
    function poolId() external view returns (uint256);

    /**
     * @dev Returns the owner of the position token (Diamond contract in the
     * context of DIVA).
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {LibDIVAStorage} from "../libraries/LibDIVAStorage.sol";

interface ISettlement {
    // Thrown if data provider attempts to submit a value when status
    // is submitted or confirmed
    error AlreadySubmittedOrConfirmed();

    // Thrown if data provider attempts to submit a value for a pool
    // that didn't expire yet
    error PoolNotExpired();

    // Thrown if caller of `setFinalReferenceValue` is not the data provider
    // for the given pool
    error NotDataProvider();

    // Thrown if caller of `setFinalReferenceValue` is not the fallback provider
    // if called during the fallback period
    error NotFallbackDataProvider();

    // Thrown if, after the end of the review period, i) a data provider attempts
    // to submit a value or ii) a user attempts to submit a challenge
    error ReviewPeriodExpired();

    // Thrown if a user that doesn't own any position tokens attempts to submit
    // a challenge
    error NoPositionTokens();

    // Thrown if a user attempts to challenge a value submission after the
    // challenge period has expired
    error ChallengePeriodExpired();

    // Thrown if user attempts to challenge whe status is "Open" or "Confirmed"
    error NothingToChallenge();

    // Thrown if user attempts to call `redeemPositionToken` when return collateral
    // was paused
    error ReturnCollateralPaused();

    // Thrown if token to redeem is an invalid position token address
    error InvalidPositionToken();

    // Thrown if a user attempts to redeem a position token where the final
    // reference value was not yet set
    error FinalReferenceValueNotSet();

    // Thrown if a user attempts to redeem a position token where
    // status is "Submitted" and challenge period did not expire yet
    error ChallengePeriodNotExpired();

    // Thrown if a user attempts to redeem a position token where
    // status is "Challenged" and the review period did not expire yet
    error ReviewPeriodNotExpired();

    // Struct for `batchSetFinalReferenceValue` function input
    struct ArgsBatchSetFinalReferenceValue {
        uint256 poolId;
        uint256 finalReferenceValue;
        bool allowChallenge;
    }

    // Struct for `batchChallengeFinalReferenceValue` function input
    struct ArgsBatchChallengeFinalReferenceValue {
        uint256 poolId;
        uint256 proposedFinalReferenceValue;
    }

    // Struct for `batchRedeemPositionToken` function input
    struct ArgsBatchRedeemPositionToken {
        address positionToken;
        uint256 amount;
    }

    /**
     * @notice Emitted when the status of the final reference value changes.
     * @param statusFinalReferenceValue The status of the final value:
     * 0=Open, 1=Submitted, 2=Challenged, or 3=Confirmed
     * @param by Address that triggered the underlying function.
     * @param poolId The Id of the pool in settlement.
     * @param proposedFinalReferenceValue Final reference value proposed by
     * the `msg.sender`.
     */
    event StatusChanged(
        LibDIVAStorage.Status indexed statusFinalReferenceValue,
        address indexed by,
        uint256 indexed poolId,
        uint256 proposedFinalReferenceValue
    );

    /**
     * @notice Emitted when position tokens are redeemed.
     * @param poolId The Id of the pool that the position token belongs to.
     * @param positionToken Address of the position token to redeem.
     * @param amountPositionToken Position token amount returned by user.
     * @param collateralAmountReturned Collateral amount returned to user.
     * @param returnedTo Address that is returned collateral.
     */
    event PositionTokenRedeemed(
        uint256 indexed poolId,
        address indexed positionToken,
        uint256 amountPositionToken,
        uint256 collateralAmountReturned,
        address indexed returnedTo
    );

    // Duplication of event defined in `LibDIVA.sol` as events emitted out of
    // library functions are not reflected in the contract ABI. Read more about it here:
    // https://web.archive.org/web/20180922101404/https://blog.aragon.org/library-driven-development-in-solidity-2bebcaf88736/
    event FeeClaimAllocated(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

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
        uint256 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) external;

    /**
     * @notice Batch version of `setFinalReferenceValue`
     * @param _argsBatchSetFinalReferenceValue Struct array containing pool id,
     * final reference value and allowChallenge
     */
    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[]
            calldata _argsBatchSetFinalReferenceValue
    ) external;

    /**
     * @notice Function to challenge the final value submitted by the data
     * provider.
     * @dev Only position token holders associated with the corresponding pool
     * are allowed to challenge. Function can be triggered multiple times.
     * `_proposedFinalReferenceValue` passed in as argument is not stored
     * in pool parameters but emitted as part of the `StatusChanged` event.
     * @param _poolId Pool Id for which the submitted final value is challenged.
     * @param _proposedFinalReferenceValue The proposed final value by the
     * challenger expressed as an integer with 18 decimals.
     */
    function challengeFinalReferenceValue(
        uint256 _poolId,
        uint256 _proposedFinalReferenceValue
    ) external;

    /**
     * @notice Batch version of `challengeFinalReferenceValue`
     * @param _argsBatchChallengeFinalReferenceValue Struct array containing pool id
     * and proposedFinalReferenceValue
     */
    function batchChallengeFinalReferenceValue(
        ArgsBatchChallengeFinalReferenceValue[]
            calldata _argsBatchChallengeFinalReferenceValue
    ) external;

    /**
     * @notice Function to redeem position tokens. Position tokens are burnt
     * during that process.
     * @dev If the submission period expired without a challenge or a review
     * period expired without another input from the data provider, the
     * previously submitted final value is confirmed inside the function at
     * first user redemption.
     * @param _positionToken address of the position token to be redeemed.
     * @param _amount number of position tokens to be redeemed..
     */
    function redeemPositionToken(address _positionToken, uint256 _amount)
        external;

    /**
     * @notice Batch version of `redeemPositionToken`
     * @param _argsBatchRedeemPositionToken Struct array containing position token
     * and amount
     */
    function batchRedeemPositionToken(
        ArgsBatchRedeemPositionToken[] calldata _argsBatchRedeemPositionToken
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {IPositionTokenFactory} from "../interfaces/IPositionTokenFactory.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown, if collateral amount to be returned to user during `removeLiquidity`
// or `redeemPositionToken` exceeds the pool's collateral balance
error AmountExceedsPoolCollateralBalance();

// Thrown if fee amount to be allocated exceeds the pool's
// current `collateralBalance`
error FeeAmountExceedsPoolCollateralBalance();

// Thrown if both `longRecipient` and `shortRecipient` passed into `addLiquidity` are
// equal to the zero address.
error ZeroLongAndShortRecipients();

// Thrown if a pool is already expired when a user attempts to add liquidity
error PoolExpired();

// Thrown if input params for `createContingentPool` are invalid
error InvalidInputParamsCreateContingentPool();

// Thrown if adding additional collateral during `addLiquidity` would
// result in the pool capacity being exceeded
error PoolCapacityExceeded();

library LibDIVA {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;

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
     * @notice Emitted when fees are allocated.
     * @dev Collateral token can be looked up via the `getPoolParameters`
     * function using the emitted `poolId`.
     * @param poolId The Id of the pool that the fee applies to.
     * @param recipient Address that is allocated the fees.
     * @param amount Fee amount allocated.
     */
    event FeeClaimAllocated(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when a new pool is created.
     * @param poolId The Id of the newly created contingent pool.
     * @param longRecipient The address that received the long position tokens.
     * @param shortRecipient The address that received the short position tokens.
     * @param collateralAmount The collateral amount deposited into the pool.
     * @param permissionedERC721Token Address of ERC721 token that the transfer
     * restrictions apply to.
     */
    event PoolIssued(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount,
        address permissionedERC721Token
    );

    /**
     * @notice Emitted when new collateral is added to an existing pool.
     * @param poolId The Id of the pool that collateral was added to.
     * @param longRecipient The address that received the long position token.
     * @param shortRecipient The address that received the short position token.
     * @param collateralAmount The collateral amount added.
     */
    event LiquidityAdded(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount
    );

    function _poolParameters(uint256 _poolId)
        internal
        view
        returns (LibDIVAStorage.Pool memory)
    {
        return LibDIVAStorage._poolStorage().pools[_poolId];
    }

    function _getLatestPoolId() internal view returns (uint256) {
        return LibDIVAStorage._poolStorage().poolId;
    }

    function _claim(address _collateralToken, address _recipient)
        internal
        view
        returns (uint256)
    {
        return
            LibDIVAStorage._feeClaimStorage().claimableFeeAmount[
                _collateralToken
            ][_recipient];
    }

    /**
     * @dev Internal function to transfer the collateral to the user.
     * Openzeppelin's `safeTransfer` method is used to handle different
     * implementations of the ERC20 standard.
     */
    function _returnCollateral(
        uint256 _poolId,
        address _collateralToken,
        address _receiver,
        uint256 _amount
    ) internal {
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        IERC20Metadata collateralToken = IERC20Metadata(_collateralToken);

        if (_amount > _pool.collateralBalance)
            revert AmountExceedsPoolCollateralBalance();

        _pool.collateralBalance -= _amount;

        collateralToken.safeTransfer(_receiver, _amount);
    }

    /**
     * @notice Internal function to calculate the payoff per long and short token
     * (net of fees) and store it in `payoutLong` and
     * `payoutShort` inside pool parameters.
     * @dev Called inside {redeemPositionToken} and {setFinalReferenceValue}
     * functions after status of final reference value has been confirmed.
     * @param _poolId The pool Id for which payout amounts are set.
     * @param _collateralTokenDecimals Collateral token decimals. Passed as
     * argument to avoid reading from storage again.
     */
    function _setPayoutAmount(uint256 _poolId, uint8 _collateralTokenDecimals)
        internal
    {
        // Get reference to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        LibDIVAStorage.Fees memory _fees = _getFees(_poolId);

        // Calculate payoff per short and long token. Output is in collateral
        // token decimals.
        (_pool.payoutShort, _pool.payoutLong) = _calcPayoffs(
            _pool.floor,
            _pool.inflection,
            _pool.cap,
            _pool.gradient,
            _pool.finalReferenceValue,
            _collateralTokenDecimals,
            _fees.protocolFee + _fees.settlementFee
        );
    }

    /**
     * @notice Internal function used within `setFinalReferenceValue` and
     * `redeemPositionToken` to calculate and allocate fee claims to recipient
     * (DIVA Treasury or data provider). Fee is applied to the overall
     * collateral remaining in the pool and allocated in full the first time
     * the respective function is triggered.
     * @dev Fees can be claimed via the `claimFee` function.
     * @param _poolId Pool Id.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * @param _recipient Fee recipient address.
     * @param _collateralBalance Current pool collateral balance expressed as
     * an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     */
    function _calcAndAllocateFeeClaim(
        uint256 _poolId,
        uint96 _fee,
        address _recipient,
        uint256 _collateralBalance,
        uint8 _collateralTokenDecimals
    ) internal {
        uint256 _feeAmount = _calcFee(
            _fee,
            _collateralBalance,
            _collateralTokenDecimals
        );

        _allocateFeeClaim(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to allocate fees to `recipient`.
     * @dev The balance of the recipient is tracked inside the contract and
     * can be claimed via `claimFee` function.
     * @param _poolId Pool Id that the fee applies to.
     * @param _recipient Address of the fee recipient.
     * @param _feeAmount Total fee amount expressed as an integer with
     * collateral token decimals.
     */
    function _allocateFeeClaim(
        uint256 _poolId,
        address _recipient,
        uint256 _feeAmount
    ) internal {
        // Get references to relevant storage slots
        LibDIVAStorage.FeeClaimStorage storage fs = LibDIVAStorage
            ._feeClaimStorage();
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // Check that fee amount to be allocated doesn't exceed the pool's
        // current `collateralBalance`
        if (_feeAmount > _pool.collateralBalance)
            revert FeeAmountExceedsPoolCollateralBalance();

        // Reduce `collateralBalance` in pool parameters and increase fee claim
        _pool.collateralBalance -= _feeAmount;
        fs.claimableFeeAmount[_pool.collateralToken][_recipient] += _feeAmount;

        // Log recipient and fee amount
        emit FeeClaimAllocated(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Function to calculate the fee amount for a given collateral amount.
     * @dev Output is an integer expressed with collateral token decimals.
     * As fee parameter has 18 decimals but collateral tokens may have
     * less, scaling needs to be applied when using `SafeDecimalMath` library.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * (e.g., 0.25% is 2500000000000000).
     * @param _collateralAmount Collateral amount that is used as the basis for
     * the fee calculation expressed as an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @return The fee amount expressed as an integer with collateral token decimals.
     */
    function _calcFee(
        uint96 _fee,
        uint256 _collateralAmount,
        uint8 _collateralTokenDecimals
    ) internal pure returns (uint256) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));

        uint256 _feeAmount = uint256(_fee).multiplyDecimal(
            _collateralAmount * _SCALINGFACTOR
        ) / _SCALINGFACTOR;

        return _feeAmount;
    }

    /**
     * @notice Function to calculate the payoffs per long and short token
     * (net of fees).
     * @dev Scaling applied during calculations to handle different decimals.
     * @param _floor Value of underlying at or below which the short token
     * will pay out the max amount and the long token zero. Expressed as an
     * integer with 18 decimals.
     * @param _inflection Value of underlying at which the long token will
     * payout out `_gradient` and the short token `1-_gradient`. Expressed
     * as an integer with 18 decimals.
     * @param _cap Value of underlying at or above which the long token will
     * pay out the max amount and short token zero. Expressed as an integer
     * with 18 decimals.
     * @param _gradient Long token payout at inflection (0 <= _gradient <= 1).
     * Expressed as an integer with collateral token decimals.
     * @param _finalReferenceValue Final value submitted by data provider
     * expressed as an integer with 18 decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @param _fee Fee in percent expressed as an integer with 18 decimals.
     * @return payoffShortNet Payoff per short token (net of fees) expressed
     * as an integer with collateral token decimals.
     * @return payoffLongNet Payoff per long token (net of fees) expressed
     * as an integer with collateral token decimals.
     */
    function _calcPayoffs(
        uint256 _floor,
        uint256 _inflection,
        uint256 _cap,
        uint256 _gradient,
        uint256 _finalReferenceValue,
        uint256 _collateralTokenDecimals,
        uint96 _fee // max value: 5% <= 2^96
    ) internal pure returns (uint96 payoffShortNet, uint96 payoffLongNet) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        uint256 _UNIT = SafeDecimalMath.UNIT;
        uint256 _payoffLong;
        uint256 _payoffShort;
        // Note: _gradient * _SCALINGFACTOR not stored in memory for calculations
        // as it would result in a stack-too-deep error

        if (_finalReferenceValue == _inflection) {
            _payoffLong = _gradient * _SCALINGFACTOR;
        } else if (_finalReferenceValue <= _floor) {
            _payoffLong = 0;
        } else if (_finalReferenceValue >= _cap) {
            _payoffLong = _UNIT;
        } else if (_finalReferenceValue < _inflection) {
            _payoffLong = (
                (_gradient * _SCALINGFACTOR).multiplyDecimal(
                    _finalReferenceValue - _floor
                )
            ).divideDecimal(_inflection - _floor);
        } else if (_finalReferenceValue > _inflection) {
            _payoffLong =
                _gradient *
                _SCALINGFACTOR +
                (
                    (_UNIT - _gradient * _SCALINGFACTOR).multiplyDecimal(
                        _finalReferenceValue - _inflection
                    )
                ).divideDecimal(_cap - _inflection);
        }

        _payoffShort = _UNIT - _payoffLong;

        payoffShortNet = uint96(
            _payoffShort.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );
        payoffLongNet = uint96(
            _payoffLong.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );

        return (payoffShortNet, payoffLongNet); // collateral token decimals
    }

    function _createContingentPool(
        PoolParams memory _poolParams,
        bool _transferCollateral
    ) internal returns (uint256) {
        // Get reference to relevant storage slot
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Create reference to collateral token corresponding to the provided pool Id
        IERC20Metadata collateralToken = IERC20Metadata(
            _poolParams.collateralToken
        );

        uint8 _collateralTokenDecimals = collateralToken.decimals();

        // Check validity of input parameters
        if (
            !_validateInputParamsCreateContingentPool(
                _poolParams,
                _collateralTokenDecimals
            )
        ) revert InvalidInputParamsCreateContingentPool();

        // Increment `poolId` every time a new pool is created. Index
        // starts at 1. No overflow risk when using compiler version >= 0.8.0.
        ++ps.poolId;

        // Cache new poolId to avoid reading from storage
        uint256 _poolId = ps.poolId;

        // Transfer approved collateral tokens from msg.sender to Diamond contract.
        if (_transferCollateral) {
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _poolParams.collateralAmount
            );
        }

        // Deploy two `PositionToken` contract clones, one that represents shares in the short
        // and one that represents shares in the long position.
        // Naming convention for short/long token: S13/L13 where 13 is the poolId
        // Diamond contract (address(this) due to delegatecall) is set as the
        // owner of the position tokens and is the only account that is
        // authorized to call the `mint` and `burn` function therein.
        // Note that position tokens have same number of decimals as collateral token.
        address _shortToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("S", Strings.toString(_poolId))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _poolParams.permissionedERC721Token
            );

        address _longToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("L", Strings.toString(_poolId))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _poolParams.permissionedERC721Token
            );

        // Store `Pool` struct in `pools` mapping for the newly generated `poolId`
        ps.pools[_poolId] = LibDIVAStorage.Pool(
            _poolParams.floor,
            _poolParams.inflection,
            _poolParams.cap,
            _poolParams.gradient,
            _poolParams.collateralAmount,
            0, // finalReferenceValue
            _poolParams.capacity,
            block.timestamp,
            _shortToken,
            0, // payoutShort
            _longToken,
            0, // payoutLong
            _poolParams.collateralToken,
            _poolParams.expiryTime,
            address(_poolParams.dataProvider),
            LibDIVAStorage.Status.Open,
            _poolParams.referenceAsset
        );

        // Number of position tokens is set equal to the total collateral to
        // standardize the max payout at 1.0. Position tokens are sent to the recipients
        // provided as part of the input parameters.
        IPositionToken(_shortToken).mint(
            _poolParams.shortRecipient,
            _poolParams.collateralAmount
        );
        IPositionToken(_longToken).mint(
            _poolParams.longRecipient,
            _poolParams.collateralAmount
        );

        // Log pool creation
        emit PoolIssued(
            _poolId,
            _poolParams.longRecipient,
            _poolParams.shortRecipient,
            _poolParams.collateralAmount,
            _poolParams.permissionedERC721Token
        );

        return _poolId;
    }

    function _validateInputParamsCreateContingentPool(
        PoolParams memory _poolParams,
        uint8 _collateralTokenDecimals
    ) internal view returns (bool) {
        // Expiry time should not be equal to or smaller than `block.timestamp`
        if (_poolParams.expiryTime <= block.timestamp) {
            return false;
        }

        // Reference asset should not be empty string
        if (bytes(_poolParams.referenceAsset).length == 0) {
            return false;
        }

        // Floor should not be greater than inflection
        if (_poolParams.floor > _poolParams.inflection) {
            return false;
        }

        // Cap should not be smaller than inflection
        if (_poolParams.cap < _poolParams.inflection) {
            return false;
        }

        // Data provider should not be zero address
        if (_poolParams.dataProvider == address(0)) {
            return false;
        }

        // Gradient should not be greater than 1 (integer in collateral token decimals)
        if (_poolParams.gradient > uint256(10**_collateralTokenDecimals)) {
            return false;
        }

        // Collateral amount should not be smaller than 1e6
        if (_poolParams.collateralAmount < 10**6) {
            return false;
        }

        // Collateral amount should not be greater than pool capacity
        if (_poolParams.collateralAmount > _poolParams.capacity) {
            return false;
        }

        // Collateral token should not have decimals larger than 18 or smaller than 6
        if ((_collateralTokenDecimals > 18) || (_collateralTokenDecimals < 6)) {
            return false;
        }

        // `longRecipient` and `shortRecipient` should not be both zero address
        if (
            _poolParams.longRecipient == address(0) &&
            _poolParams.shortRecipient == address(0)
        ) {
            return false;
        }

        return true;

        // Note: Conscious decision to allow either `longRecipient` or `shortRecipient` to
        // to be equal to the zero address to enable conditional burn use cases.
    }

    function _addLiquidity(
        uint256 _poolId,
        uint256 _collateralAmountIncr,
        address _longRecipient,
        address _shortRecipient,
        bool _transferCollateral
    ) internal {
        // Get reference to relevant storage slot
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // `longRecipient` and `shortRecipient` should not be both zero address
        if (_longRecipient == address(0) && _shortRecipient == address(0))
            revert ZeroLongAndShortRecipients();

        // Note: Similar to `createContingentPool`, conscious decision to allow either `longRecipient`
        // or `shortRecipient` to to be equal to the zero address to enable conditional burn use cases.

        // Check that pool has not expired yet
        if (block.timestamp >= _pool.expiryTime) revert PoolExpired();

        // Check that new total pool collateral does not exceed the maximum
        // capacity of the pool
        if ((_pool.collateralBalance + _collateralAmountIncr) > _pool.capacity)
            revert PoolCapacityExceeded();

        // Connect to collateral token contract of the given pool Id
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // Transfer approved collateral tokens from user to Diamond contract.
        if (_transferCollateral) {
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _collateralAmountIncr
            );
        }

        // Increase `collateralBalance`
        _pool.collateralBalance += _collateralAmountIncr;

        // Mint long and short position tokens and send to `shortRecipient` and
        // `_longRecipient`, respectively (additional supply equals `_collateralAmountIncr`)
        IPositionToken(_pool.shortToken).mint(
            _shortRecipient,
            _collateralAmountIncr
        );
        IPositionToken(_pool.longToken).mint(
            _longRecipient,
            _collateralAmountIncr
        );

        // Log addition of collateral
        emit LiquidityAdded(
            _poolId,
            _longRecipient,
            _shortRecipient,
            _collateralAmountIncr
        );
    }

    function _getFees(uint256 _poolId)
        internal
        view
        returns (LibDIVAStorage.Fees memory fees)
    {
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Load max index into memory to avoid reading from storage on every loop
        uint8 _idx = gs.maxUpdateIdToFees;

        // Iterate through the fee sets starting from the latest.
        for (uint8 i = _idx; i >= 0; ) {
            if (_poolId >= gs.updateIdToFees[i].startPoolId) {
                fees = gs.updateIdToFees[i];
                break;
            }

            // Cannot underflow as updateIdToFees[0] exists
            unchecked {
                --i;
            }
        }
    }

    function _getSettlementPeriods(uint256 _poolId)
        internal
        view
        returns (LibDIVAStorage.SettlementPeriods memory settlementPeriods)
    {
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Load max index into memory to avoid reading from storage on every loop
        uint8 _idx = gs.maxUpdateIdToSettlementPeriods;

        // Iterate through the settlement period sets starting from the latest.
        for (uint8 i = _idx; i >= 0; ) {
            if (_poolId >= gs.updateIdToSettlementPeriods[i].startPoolId) {
                settlementPeriods = gs.updateIdToSettlementPeriods[i];
                break;
            }

            // Cannot underflow as updateIdToSettlementPeriods[0] exists
            unchecked {
                --i;
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibDIVAStorage {
    // The hash for pool storage position, which is:
    // keccak256("diamond.standard.pool.storage")
    bytes32 constant POOL_STORAGE_POSITION =
        0x57b54c9a1067e6ab879c66c176c4e86e41fe1dcf5187b31dc2b93365087c7afb;

    // The hash for governance storage position, which is:
    // keccak256("diamond.standard.governance.storage")
    bytes32 constant GOVERNANCE_STORAGE_POSITION =
        0x898b136e888260ec0628fb6c3ad8f54cb15908878595b2abfc8c9ecda73a4daf;

    // The hash for fee claim storage position, which is:
    // keccak256("diamond.standard.fee.claim.storage")
    bytes32 constant FEE_CLAIM_STORAGE_POSITION =
        0x16b3e63c02e4dfaf74f59b1b7e9e81770bf30c0ed3fd4434b199357859900313;

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralBalance;
        uint256 finalReferenceValue;
        uint256 capacity;
        uint256 statusTimestamp;
        address shortToken;
        uint96 payoutShort; // max value: 1e18 <= 2^64
        address longToken;
        uint96 payoutLong; // max value: 1e18 <= 2^64
        address collateralToken;
        uint96 expiryTime;
        address dataProvider;
        Status statusFinalReferenceValue;
        string referenceAsset;
    }

    // Collection of settlement related periods as well as the id of the pool
    // at which they become applicable
    struct SettlementPeriods {
        uint256 startPoolId;                // poolId at which the periods become applicable
        uint24 submissionPeriod;           // days since expiry; max value: 15 days <= 2^24
        uint24 challengePeriod;            // days since time of submission; max value: 15 days <= 2^24
        uint24 reviewPeriod;               // days since time of challenge; max value: 15 days <= 2^24
        uint24 fallbackSubmissionPeriod;   // days since the end of the submission period; max value: 15 days <= 2^24
    }

    // Collection of fee related parameters as well as the id of the pool at
    // which they become applicable
    struct Fees {
        uint256 startPoolId;    // poolId at which the fees become applicable
        uint96 protocolFee;     // max value: 25000000000000000 = 2.5% <= 2^56
        uint96 settlementFee;   // max value: 25000000000000000 = 2.5% <= 2^56
    }

    // Collection of governance related parameters
    struct GovernanceStorage {        
        address treasury;                        // Treasury address controlled by DIVA governance
        address fallbackDataProvider;            // Address of fallback data provider
        uint256 pauseReturnCollateralUntil;      // Timestamp in seconds until when the 
        uint8 maxUpdateIdToFees;                 // Update Id that corresponds to the latest set of fees
        uint8 maxUpdateIdToSettlementPeriods;    // Update Id that corresponds to the latest set of settlement periods
        mapping(uint256 => Fees) updateIdToFees; // Mapping including the Fee regimes set over time
        mapping(uint256 => SettlementPeriods) updateIdToSettlementPeriods; // Mapping including the settlement period regimes set over time
    }

    struct FeeClaimStorage {
        mapping(address => mapping(address => uint256)) claimableFeeAmount; // collateralTokenAddress -> RecipientAddress -> amount
    }

    struct PoolStorage {
        uint256 poolId;
        mapping(uint256 => Pool) pools;
        address positionTokenFactory;
    }

    function _poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function _governanceStorage()
        internal
        pure
        returns (GovernanceStorage storage gs)
    {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function _feeClaimStorage()
        internal
        pure
        returns (FeeClaimStorage storage fs)
    {
        bytes32 position = FEE_CLAIM_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IPositionToken} from "./interfaces/IPositionToken.sol";

/**
 * @dev Implementation contract for position token clones
 */
contract PositionToken is IPositionToken, ERC20Upgradeable {

    uint256 private _poolId;
    address private _owner;
    uint8 private _decimals;

    constructor() {
        /* @dev To prevent the implementation contract from being used, invoke the {_disableInitializers}
         * function in the constructor to automatically lock it when it is deployed.
         * For more information, refer to @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol
         */
        _disableInitializers();
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "PositionToken: caller is not owner"
            );
        _;
    }

    function mint(
        address _recipient,
        uint256 _amount
        ) external override onlyOwner {
        _mint(_recipient, _amount);
    }

    function burn(
        address _redeemer,
        uint256 _amount
        ) external override onlyOwner {
        _burn(_redeemer, _amount);
    }

    function poolId() external view override returns (uint256) {
        return _poolId;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initialize(
        string memory symbol_,
        uint256 poolId_,
        uint8 decimals_,
        address owner_
    ) external override initializer {

        __ERC20_init(symbol_, symbol_);

        _owner = owner_;
        _poolId = poolId_;
        _decimals = decimals_;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

interface IPositionTokenFactory {
    /**
     * @notice Creates a clone of the permissionless position token contract.
     * @param _symbol Symbol string of the position token. Name is set equal to symbol.
     * @param _poolId The Id of the contingent pool that the position token belongs to.
     * @param _decimals Decimals of position token (same as collateral token).
     * @param _owner Owner of the position token. Should always be DIVA Protocol address.
     * @param _permissionedERC721Token Address of permissioned ERC721 token.
     * @return clone Returns the address of the clone contract.
     */
    function createPositionToken(
        string memory _symbol,
        uint256 _poolId,
        uint8 _decimals,
        address _owner,
        address _permissionedERC721Token
    ) external returns (address clone);

    /**
     * @notice Address where the position token implementation contract is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
    */
    function positionTokenImplementation() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.6 where SafeMath is no
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}