// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IS2_1Admin } from "./impl/IS2_1Admin.sol";
import { IS2Core } from "../v2/impl/IS2Core.sol";
import { IS2_1Erc20 } from "./impl/IS2_1Erc20.sol";
import { IS2Getters } from "../v2/impl/IS2Getters.sol";
import { IS2Storage } from "../v2/impl/IS2Storage.sol";
import { MinHeap } from "../v2/lib/MinHeap.sol";

/**
 * @title IkaniV2_1Staking
 * @author Cyborg Labs, LLC
 *
 * @dev Implements ERC-721 in-place staking with rewards.
 *
 *  Rewards are earned at a configurable base rate per staked NFT, with four bonus multipliers:
 *
 *    - Account-level (i.e. owner-level) bonuses:
 *      - Number of unique staked fabric traits
 *      - Number of unique staked season traits
 *
 *    - Token-level bonuses:
 *      - Foil trait
 *      - Staked duration checkpoints
 */
contract IkaniV2_1Staking is
    IS2_1Admin,
    IS2Getters
{
    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ikani,
        address rewardsErc20
    )
        IS2_1Erc20(rewardsErc20)
        IS2Storage(ikani)
    {
        _disableInitializers();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "../../../deps/oz_cu_4_7_2/IERC721Upgradeable.sol";
import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniERC20 } from "../../../erc20/interfaces/IIkaniERC20.sol";
import { IS2_1Core } from "./IS2_1Core.sol";
import { IS2Roles } from "../../v2/impl/IS2Roles.sol";

/**
 * @title IS2_1Admin
 * @author Cyborg Labs, LLC
 *
 *  Role-restricted functions.
 */
abstract contract IS2_1Admin is
    IS2_1Core,
    IS2Roles
{
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    function pause()
        external
        onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole(UNPAUSER_ROLE)
    {
        _unpause();
    }

    function setBaseRate(
        uint32 baseRate
    )
        external
        onlyRole(BASE_RATE_CONTROLLER_ROLE)
    {
        _setBaseRate(baseRate);
    }

    function adminUnstake(
        address owner,
        uint256[] calldata tokenIds,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external
        onlyRole(UNSTAKE_CONTROLLER_ROLE)
        whenNotPaused
    {
        // Verify owner.
        _requireSameOwnerAndAuthorized(owner, tokenIds, true);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Unstake the tokens.
        context = _unstake(context, owner, tokenIds);

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] += rewardsDiff;

        emit AdminUnstaked(owner, tokenIds, receipt, receiptData);
    }

    function adminUnstake2(
        uint256[] calldata tokenIds,
        bytes32 receipt,
        bytes[] calldata receiptData
    )
        external
        onlyRole(UNSTAKE_CONTROLLER_ROLE)
        whenNotPaused
    {
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];
            bytes calldata innerReceiptData = receiptData[i];

            // Get owner.
            address owner = IERC721Upgradeable(IKANI).ownerOf(tokenId);

            // Get the updated rewards context and new rewards.
            (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

            // Unstake the token.
            uint256[] memory innerTokenIds = new uint256[](1);
            innerTokenIds[0] = tokenId;
            context = _unstake(context, owner, innerTokenIds);

            // Update storage for the account.
            _SETTLEMENT_CONTEXT_[owner] = context;
            _REWARDS_[owner] += rewardsDiff;

            emit AdminUnstaked(owner, innerTokenIds, receipt, innerReceiptData);

            unchecked { ++i; }
        }
    }

    function adminClaimRewards(
        address owner
    )
        external
        onlyRole(CLAIM_CONTROLLER_ROLE)
        whenNotPaused
    {
        _claimRewards(owner, owner);
    }

    function adminClaimRewardsAndBurnWithPermit(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s

    )
        external
        onlyRole(CLAIM_CONTROLLER_ROLE)
        onlyRole(BURN_CONTROLLER_ROLE)
        whenNotPaused
    {
        _claimRewards(owner, owner);
        _burnErc20(owner, burnAmount, burnReceipt, burnReceiptData, deadline, v, r, s);
    }

    //---------------- Internal Functions ----------------//

    function _setBaseRate(
        uint32 baseRate
    )
        internal
    {
        // The base rate at index zero is always zero.
        // The first configured base rate is at index one.
        unchecked {
            _RATE_CHANGES_[++_NUM_RATE_CHANGES_] = RateChange({
                baseRate: baseRate,
                timestamp: block.timestamp.toUint32()
            });
        }

        emit SetBaseRate(baseRate);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "../../../deps/oz_cu_4_7_2/AddressUpgradeable.sol";
import { IERC721Upgradeable } from "../../../deps/oz_cu_4_7_2/IERC721Upgradeable.sol";
import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";

import { IS2Lib } from "../lib/IS2Lib.sol";
import { MinHeap } from "../lib/MinHeap.sol";
import { IS2Erc20 } from "./IS2Erc20.sol";

/**
 * @title IS2Core
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Core is
    IS2Erc20
{
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    /**
     * @notice Stake one or more tokens owned by a single owner.
     *
     *  Will revert if any of the tokens are already staked.
     *  Will revert if the same token is included more than once.
     */
    function stake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Stake the tokens.
        context = _stake(context, owner, tokenIds, new uint256[](0));

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        if (rewardsDiff != 0) {
            _REWARDS_[owner] += rewardsDiff;
        }
    }

    function unstake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Unstake the tokens.
        context = _unstake(context, owner, tokenIds);

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] += rewardsDiff;
    }

    function batchSafeTransferFromStaked(
        address owner,
        address recipient,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Only owner can transfer staked"
        );

        // Verify owner.
        _requireSameOwnerAndAuthorized(owner, tokenIds, true);

        // Get the updated rewards context and new rewards.
        (
            SettlementContext memory ownerContext,
            uint256 ownerRewardsDiff
        ) = _settleAccount(owner);
        (
            SettlementContext memory recipientContext,
            uint256 recipientRewardsDiff
        ) = _settleAccount(recipient);

        // Get the staked timestamps.
        uint256 n = tokenIds.length;
        uint256[] memory stakedTimestamps = new uint256[](n);
        for (uint256 i = 0; i < n;) {
            stakedTimestamps[i] = _TOKEN_STAKING_STATE_[tokenIds[i]].timestamp;
            unchecked { ++i; }
        }

        // Unstake and restake the tokens.
        ownerContext = _unstake(ownerContext, owner, tokenIds);
        recipientContext = _stake(recipientContext, recipient, tokenIds, stakedTimestamps);

        // Update storage for the accounts.
        _SETTLEMENT_CONTEXT_[owner] = ownerContext;
        _REWARDS_[owner] += ownerRewardsDiff;
        _SETTLEMENT_CONTEXT_[recipient] = recipientContext;
        _REWARDS_[recipient] += recipientRewardsDiff;

        // Do transfers last, since a “safe” transfer can execute arbitrary smart contract code.
        // This is important to prevent reentrancy attacks.
        for (uint256 i = 0; i < n;) {
            IERC721Upgradeable(IKANI).safeTransferFrom(owner, recipient, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Claim all rewards for the account.
     *
     *  This function can be called with eth_call (e.g. callStatic in ethers.js) to get the
     *  current unclaimed rewards balance for an account.
     */
    function claimRewards(
        address owner,
        address recipient
    )
        external
        whenNotPaused
        returns (uint256)
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        return _claimRewards(owner, recipient);
    }

    function claimAndBurnRewards(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        _claimRewards(owner, owner);
        _burnErc20(owner, burnAmount, burnReceipt, burnReceiptData, deadline, v, r, s);
    }

    /**
     * @notice Settle rewards for an account.
     *
     *  Note: There is no access control on this function.
     */
    function settleRewards(
        address owner
    )
        external
        whenNotPaused
        returns (uint256)
    {
        return _settleRewards(owner);
    }

    //---------------- Internal Functions ----------------//

    function _settleRewards(
        address owner
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        uint256 rewardsNew = rewardsOld + rewardsDiff;

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = rewardsNew;

        return _getErc20Amount(rewardsNew);
    }

    function _claimRewards(
        address owner,
        address recipient
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = 0;

        // Mint the rewards amount.
        uint256 rewardsNew = rewardsOld + rewardsDiff;
        uint256 erc20Amount = _issueRewards(recipient, rewardsNew);

        emit ClaimedRewards(owner, erc20Amount);

        return erc20Amount;
    }

    function _stake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] calldata tokenIds,
        uint256[] memory maybeStakingStartTimestamps
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is not currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp == 0,
                "Already staked"
            );

            // The timestamp to use as the staking start timestamp for the token.
            uint256 stakingStartTimestamp = maybeStakingStartTimestamps.length > 0
                ? maybeStakingStartTimestamps[i]
                : block.timestamp;

            Checkpoint memory checkpoint;
            (context, checkpoint) = IS2Lib.stakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingStartTimestamp,
                stakingState.nonce,
                tokenId
            );

            // Update storage for the token.
            if (checkpoint.timestamp != 0) {
                IS2Lib._insertCheckpoint(_CHECKPOINTS_[owner], checkpoint);
            }
            _TOKEN_STAKING_STATE_[tokenId].timestamp = stakingStartTimestamp.toUint32();

            emit Staked(owner, tokenId, stakingStartTimestamp);

            unchecked { ++i; }
        }
    }

    function _unstake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] calldata tokenIds
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp != 0,
                "Not staked"
            );

            context = IS2Lib.unstakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingState.timestamp
            );

            // Update storage for the token.
            unchecked {
                _TOKEN_STAKING_STATE_[tokenId] = TokenStakingState({
                    timestamp: 0,
                    nonce: stakingState.nonce + 1
                });
            }

            emit Unstaked(owner, tokenId);

            unchecked { ++i; }
        }
    }

    function _requireSameOwnerAndAuthorized(
        address owner,
        uint256[] calldata tokenIds,
        bool alreadyAuthorized
    )
        internal
        view
    {
        address sender = msg.sender;
        bool senderIsOwner = sender == owner;
        uint256 n = tokenIds.length;

        // Verify owner and authorization.
        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            require(
                IERC721Upgradeable(IKANI).ownerOf(tokenId) == owner,
                "Wrong owner"
            );
            require(
                alreadyAuthorized || senderIsOwner || _isApproved(sender, owner, tokenId),
                "Not authorized to stake/unstake"
            );

            unchecked { ++i; }
        }
    }

    function _settleAccount(
        address owner
    )
        internal
        returns (
            SettlementContext memory context,
            uint256 rewardsDiff
        )
    {
        (context, rewardsDiff) = IS2Lib.settleAccountAndGetOwedRewards(
            _SETTLEMENT_CONTEXT_[owner],
            _RATE_CHANGES_,
            _CHECKPOINTS_[owner],
            _TOKEN_STAKING_STATE_,
            _NUM_RATE_CHANGES_
        );
    }

    function _isApproved(
        address spender,
        address owner,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        return (
            IERC721Upgradeable(IKANI).isApprovedForAll(owner, spender) ||
            IERC721Upgradeable(IKANI).getApproved(tokenId) == spender
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC20 } from "../../../deps/oz_c_4_7_2/IERC20.sol";

import { IIkaniERC20 } from "../../../erc20/interfaces/IIkaniERC20.sol";

import { IS2Storage } from "../../v2/impl/IS2Storage.sol";

/**
 * @title IS2_1Erc20
 * @author Cyborg Labs, LLC
 *
 * @notice Handles interactions with the ERC20 token.
 */
abstract contract IS2_1Erc20 is
    IS2Storage
{
    //---------------- Constants ----------------//

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable REWARDS_ERC20;

    uint256 private constant REWARDS_CONVERSION_FACTOR = 1e6;

    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address rewardsErc20
    ) {
        REWARDS_ERC20 = rewardsErc20;
    }

    //---------------- Internal Functions ----------------//

    function _issueRewards(
        address recipient,
        uint256 rewardsAmount
    )
        internal
        returns (uint256)
    {
        uint256 erc20Amount = _getErc20Amount(rewardsAmount);
        // Note: Not using SafeERC20, to save a bit of gas, since this is our own token.
        IERC20(REWARDS_ERC20).transfer(
            recipient,
            erc20Amount
        );
        return erc20Amount;
    }

    function _burnErc20(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        IIkaniERC20(REWARDS_ERC20).burnWithPermit(
            owner,
            burnAmount,
            burnReceipt,
            burnReceiptData,
            deadline,
            v,
            r,
            s
        );
    }

    function _getErc20Amount(
        uint256 rewardsAmount
    )
        internal
        pure
        returns (uint256)
    {
        return rewardsAmount * REWARDS_CONVERSION_FACTOR;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";
import { IS2Lib } from "../lib/IS2Lib.sol";
import { IS2Storage } from "./IS2Storage.sol";

/**
 * @title IS2Getters
 * @author Cyborg Labs, LLC
 *
 * @dev Simple getter functions that are only needed externally.
 */
abstract contract IS2Getters is
    IS2Storage
{
    //---------------- Constants ----------------//

    /// @dev Must match the value in IS2Lib.sol.
    uint256 public constant MULTIPLIER_BASE = 1e6;

    //---------------- External Functions ----------------//

    function isStaked(
        uint256 tokenId
    )
        external
        view
        override
        returns (bool)
    {
        return _TOKEN_STAKING_STATE_[tokenId].timestamp != 0;
    }

    function getStakedTimestamp(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        return _TOKEN_STAKING_STATE_[tokenId].timestamp;
    }

    function getHistoricalBaseRate(
        uint256 i
    )
        external
        view
        returns (RateChange memory)
    {
        require(
            i <= _NUM_RATE_CHANGES_,
            "Invalid base rate index"
        );
        return _RATE_CHANGES_[i];
    }

    function getNumBaseRateChanges()
        external
        view
        returns (uint256)
    {
        return _NUM_RATE_CHANGES_;
    }

    function getAccountRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getAccountRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getFabricsRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getFabricsRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getSeasonsRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getSeasonsRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getNumFabricsStaked(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getNumFabricsStaked(_SETTLEMENT_CONTEXT_[account]);
    }

    function getNumSeasonsStaked(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getNumSeasonsStaked(_SETTLEMENT_CONTEXT_[account]);
    }

    /**
     * @notice Get the token rewards rate for a token.
     */
    function getTokenRewardsRate(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        return (
            getBaseRate() *
            getDurationRewardsMultiplier(tokenId) *
            getFoilRewardsMultiplier(tokenId) /
            (MULTIPLIER_BASE * MULTIPLIER_BASE)
        );
    }

    /**
     * @notice Get the staked duration level for a token.
     */
    function getDurationLevel(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        uint256 stakedTimestamp = _TOKEN_STAKING_STATE_[tokenId].timestamp;
        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        return IS2Lib.getLevelForStakedDuration(stakedDuration);
    }

    //---------------- Public Functions ----------------//

    function getBaseRate()
        public
        view
        returns (uint256)
    {
        return _RATE_CHANGES_[_NUM_RATE_CHANGES_].baseRate;
    }

    function getDurationRewardsMultiplier(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        uint256 stakedTimestamp = _TOKEN_STAKING_STATE_[tokenId].timestamp;

        // If the token is not staked, return multipler of 1.
        if (stakedTimestamp == 0) {
            return MULTIPLIER_BASE;
        }

        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        return IS2Lib.getStakedDurationRewardsMultiplier(stakedDuration);
    }

    function getFoilRewardsMultiplier(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        IIkaniV2.PoemTraits memory traits = IIkaniV2(IKANI).getPoemTraits(tokenId);
        return IS2Lib.getFoilRewardsMultiplier(traits);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AccessControlUpgradeable } from "../../../deps/oz_cu_4_7_2/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "../../../deps/oz_cu_4_7_2/PausableUpgradeable.sol";

import { IIkaniV2Staking } from "../interfaces/IIkaniV2Staking.sol";
import { MinHeap } from "../lib/MinHeap.sol";

/**
 * @title IS2Storage
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Storage is
    AccessControlUpgradeable,
    PausableUpgradeable,
    IIkaniV2Staking
{
    //---------------- Constants ----------------//

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable IKANI;

    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ikani
    ) {
        IKANI = ikani;
    }

    //---------------- Storage ----------------//

    /// @dev Storage gap to allow for flexibility in contract upgrades.
    uint256[1_000_000] private __gap;

    /// @dev Historical record of all changes to the global base rewards rate.
    ///
    ///  The base rate at index zero is always zero.
    ///  The first configured base rate is at index one.
    mapping(uint256 => RateChange) internal _RATE_CHANGES_;

    /// @dev The number of changes to the global base rewards rate.
    uint256 internal _NUM_RATE_CHANGES_;

    /// @dev The rewards state and settlement info for an account.
    mapping(address => SettlementContext) internal _SETTLEMENT_CONTEXT_;

    /// @dev The priority queue of unlockable duration-based bonus points for an account.
    ///
    ///  These are encoded as IIkaniV2Staking.Checkpoint structs and ordered by timestamp.
    mapping(address => MinHeap.Heap) internal _CHECKPOINTS_;

    /// @dev The settled rewards held by an account.
    ///
    ///  Converts to an ERC-20 amount as specified in IS2Erc20.sol.
    mapping(address => uint256) internal _REWARDS_;

    /// @dev The staking state of a token, including the timestamp and nonce.
    ///
    ///  timestamp  The timestamp when the token was staked, if currently staked, otherwise zero.
    ///  nonce      The number of times the token has been unstaked.
    mapping(uint256 => TokenStakingState) internal _TOKEN_STAKING_STATE_;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IkaniV2Staking
 * @author Cyborg Labs, LLC
 *
 * @dev Priority queue implemented as a heap.
 */
library MinHeap {

    struct Heap {
        mapping(uint256 => uint256) data;
        uint256 length;
    }

    function insert(
        Heap storage _heap_,
        uint256 value
    )
        internal
    {
        unchecked {
            uint256 index = _heap_.length + 1;
            _heap_.length = index;

            while (index != 1) {
                uint256 parentIndex = index >> 1;
                uint256 parentValue = _heap_.data[parentIndex];
                if (parentValue <= value) {
                    break;
                }
                _heap_.data[index] = parentValue;
                index = parentIndex;
            }

            _heap_.data[index] = value;
        }
    }

    function unsafePeek(
        Heap storage _heap_
    )
        internal
        view
        returns (uint256)
    {
        return _heap_.data[1];
    }

    function safePeek(
        Heap storage _heap_
    )
        internal
        view
        returns (uint256)
    {
        require(
            _heap_.length != 0,
            "Heap is empty"
        );
        return _heap_.data[1];
    }

    function popMin(
        Heap storage _heap_
    )
        internal
    {
        unchecked {
            // We implicitly move the last value to the top of the heap, and heapify it down.
            uint256 oldLength = _heap_.length--;
            uint256 lastValue = _heap_.data[oldLength];

            if (oldLength == 1) {
                return;
            }

            uint256 index = 1;
            uint256 leftChildIndex = 2;
            uint256 rightChildIndex = 3;

            // While there is a left child...
            while (leftChildIndex < oldLength) {

                // Get the smaller of the left child and (if it exists) the right child.
                uint256 childIndex = leftChildIndex;
                uint256 childValue = _heap_.data[leftChildIndex];
                if (rightChildIndex < oldLength) {
                    uint256 rightChildValue = _heap_.data[rightChildIndex];
                    if (rightChildValue < childValue) {
                        childIndex = rightChildIndex;
                        childValue = rightChildValue;
                    }
                }

                // If the child value is smaller than our value, bring the child up.
                if (childValue < lastValue) {
                    _heap_.data[index] = childValue;
                    index = childIndex;
                } else {
                    break;
                }

                leftChildIndex = index << 1;
                rightChildIndex = leftChildIndex + 1;
            }

            _heap_.data[index] = lastValue;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IIkaniERC20 {

    //---------------- Events ----------------//

    event Minted(
        address indexed to,
        uint256 amount,
        bytes32 indexed receipt,
        bytes receiptData
    );

    event Burned(
        address indexed from,
        uint256 amount,
        bytes32 indexed receipt,
        bytes receiptData
    );

    //---------------- Functions ----------------//

    function mint(
        address to,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;

    function burn(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;

    function burnWithPermit(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function burnFrom(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "../../../deps/oz_cu_4_7_2/AddressUpgradeable.sol";
import { IERC721Upgradeable } from "../../../deps/oz_cu_4_7_2/IERC721Upgradeable.sol";
import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";

import { IS2Lib } from "../../v2/lib/IS2Lib.sol";
import { MinHeap } from "../../v2/lib/MinHeap.sol";
import { IS2_1Erc20 } from "./IS2_1Erc20.sol";

/**
 * @title IS2_1Core
 * @author Cyborg Labs, LLC
 */
abstract contract IS2_1Core is
    IS2_1Erc20
{
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    /**
     * @notice Stake one or more tokens owned by a single owner.
     *
     *  Will revert if any of the tokens are already staked.
     *  Will revert if the same token is included more than once.
     */
    function stake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Stake the tokens.
        context = _stake(context, owner, tokenIds, new uint256[](0));

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        if (rewardsDiff != 0) {
            _REWARDS_[owner] += rewardsDiff;
        }
    }

    function unstake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Unstake the tokens.
        context = _unstake(context, owner, tokenIds);

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] += rewardsDiff;
    }

    function batchSafeTransferFromStaked(
        address owner,
        address recipient,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Only owner can transfer staked"
        );

        // Verify owner.
        _requireSameOwnerAndAuthorized(owner, tokenIds, true);

        // Get the updated rewards context and new rewards.
        (
            SettlementContext memory ownerContext,
            uint256 ownerRewardsDiff
        ) = _settleAccount(owner);
        (
            SettlementContext memory recipientContext,
            uint256 recipientRewardsDiff
        ) = _settleAccount(recipient);

        // Get the staked timestamps.
        uint256 n = tokenIds.length;
        uint256[] memory stakedTimestamps = new uint256[](n);
        for (uint256 i = 0; i < n;) {
            stakedTimestamps[i] = _TOKEN_STAKING_STATE_[tokenIds[i]].timestamp;
            unchecked { ++i; }
        }

        // Unstake and restake the tokens.
        ownerContext = _unstake(ownerContext, owner, tokenIds);
        recipientContext = _stake(recipientContext, recipient, tokenIds, stakedTimestamps);

        // Update storage for the accounts.
        _SETTLEMENT_CONTEXT_[owner] = ownerContext;
        _REWARDS_[owner] += ownerRewardsDiff;
        _SETTLEMENT_CONTEXT_[recipient] = recipientContext;
        _REWARDS_[recipient] += recipientRewardsDiff;

        // Do transfers last, since a “safe” transfer can execute arbitrary smart contract code.
        // This is important to prevent reentrancy attacks.
        for (uint256 i = 0; i < n;) {
            IERC721Upgradeable(IKANI).safeTransferFrom(owner, recipient, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Claim all rewards for the account.
     *
     *  This function can be called with eth_call (e.g. callStatic in ethers.js) to get the
     *  current unclaimed rewards balance for an account.
     */
    function claimRewards(
        address owner,
        address recipient
    )
        external
        whenNotPaused
        returns (uint256)
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        return _claimRewards(owner, recipient);
    }

    function claimAndBurnRewards(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        _claimRewards(owner, owner);
        _burnErc20(owner, burnAmount, burnReceipt, burnReceiptData, deadline, v, r, s);
    }

    /**
     * @notice Settle rewards for an account.
     *
     *  Note: There is no access control on this function.
     */
    function settleRewards(
        address owner
    )
        external
        whenNotPaused
        returns (uint256)
    {
        return _settleRewards(owner);
    }

    //---------------- Internal Functions ----------------//

    function _settleRewards(
        address owner
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        uint256 rewardsNew = rewardsOld + rewardsDiff;

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = rewardsNew;

        return _getErc20Amount(rewardsNew);
    }

    function _claimRewards(
        address owner,
        address recipient
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = 0;

        // Mint the rewards amount.
        uint256 rewardsNew = rewardsOld + rewardsDiff;
        uint256 erc20Amount = _issueRewards(recipient, rewardsNew);

        emit ClaimedRewards(owner, erc20Amount);

        return erc20Amount;
    }

    function _stake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] calldata tokenIds,
        uint256[] memory maybeStakingStartTimestamps
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is not currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp == 0,
                "Already staked"
            );

            // The timestamp to use as the staking start timestamp for the token.
            uint256 stakingStartTimestamp = maybeStakingStartTimestamps.length > 0
                ? maybeStakingStartTimestamps[i]
                : block.timestamp;

            Checkpoint memory checkpoint;
            (context, checkpoint) = IS2Lib.stakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingStartTimestamp,
                stakingState.nonce,
                tokenId
            );

            // Update storage for the token.
            if (checkpoint.timestamp != 0) {
                IS2Lib._insertCheckpoint(_CHECKPOINTS_[owner], checkpoint);
            }
            _TOKEN_STAKING_STATE_[tokenId].timestamp = stakingStartTimestamp.toUint32();

            emit Staked(owner, tokenId, stakingStartTimestamp);

            unchecked { ++i; }
        }
    }

    function _unstake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] memory tokenIds
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp != 0,
                "Not staked"
            );

            context = IS2Lib.unstakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingState.timestamp
            );

            // Update storage for the token.
            unchecked {
                _TOKEN_STAKING_STATE_[tokenId] = TokenStakingState({
                    timestamp: 0,
                    nonce: stakingState.nonce + 1
                });
            }

            emit Unstaked(owner, tokenId);

            unchecked { ++i; }
        }
    }

    function _requireSameOwnerAndAuthorized(
        address owner,
        uint256[] calldata tokenIds,
        bool alreadyAuthorized
    )
        internal
        view
    {
        address sender = msg.sender;
        bool senderIsOwner = sender == owner;
        uint256 n = tokenIds.length;

        // Verify owner and authorization.
        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            require(
                IERC721Upgradeable(IKANI).ownerOf(tokenId) == owner,
                "Wrong owner"
            );
            require(
                alreadyAuthorized || senderIsOwner || _isApproved(sender, owner, tokenId),
                "Not authorized to stake/unstake"
            );

            unchecked { ++i; }
        }
    }

    function _settleAccount(
        address owner
    )
        internal
        returns (
            SettlementContext memory context,
            uint256 rewardsDiff
        )
    {
        (context, rewardsDiff) = IS2Lib.settleAccountAndGetOwedRewards(
            _SETTLEMENT_CONTEXT_[owner],
            _RATE_CHANGES_,
            _CHECKPOINTS_[owner],
            _TOKEN_STAKING_STATE_,
            _NUM_RATE_CHANGES_
        );
    }

    function _isApproved(
        address spender,
        address owner,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        return (
            IERC721Upgradeable(IKANI).isApprovedForAll(owner, spender) ||
            IERC721Upgradeable(IKANI).getApproved(tokenId) == spender
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IS2Storage } from "./IS2Storage.sol";

/**
 * @title IS2Storage
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Roles is
    IS2Storage
{
    //---------------- Constants ----------------//

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant UNPAUSER_ROLE = keccak256('UNPAUSER_ROLE');
    bytes32 public constant BASE_RATE_CONTROLLER_ROLE = keccak256('BASE_RATE_CONTROLLER_ROLE');
    bytes32 public constant BURN_CONTROLLER_ROLE = keccak256('BURN_CONTROLLER_ROLE');
    bytes32 public constant CLAIM_CONTROLLER_ROLE = keccak256('CLAIM_CONTROLLER_ROLE');
    bytes32 public constant UNSTAKE_CONTROLLER_ROLE = keccak256('UNSTAKE_CONTROLLER_ROLE');
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2 {

    //---------------- Enums ----------------//

    enum Theme {
        NULL,
        SKY,
        OCEAN,
        MOUNTAIN,
        FLOWERS,
        TBA_THEME_5,
        TBA_THEME_6,
        TBA_THEME_7,
        TBA_THEME_8
    }

    enum Season {
        NONE,
        SPRING,
        SUMMER,
        AUTUMN,
        WINTER
    }

    enum Fabric {
        NULL,
        KOYAMAKI,
        SEIGAIHA,
        NAMI,
        KUMO,
        TBA_FABRIC_5,
        TBA_FABRIC_6,
        TBA_FABRIC_7,
        TBA_FABRIC_8
    }

    enum Foil {
        NONE,
        GOLD,
        PLATINUM,
        SUI_GENERIS
    }

    //---------------- Structs ----------------//

    /**
     * @notice The poem metadata traits.
     */
    struct PoemTraits {
        Theme theme;
        Season season;
        Fabric fabric;
        Foil foil;
    }

    /**
     * @notice Information about a series within the collection.
     */
    struct Series {
        string name;
        bytes32 provenanceHash;
        uint256 poemCreationDeadline;
        uint256 maxTokenIdExclusive;
        uint256 startingIndexBlockNumber;
        uint256 startingIndex;
        bool startingIndexWasSet;
    }

    /**
     * @notice Arguments to be signed by the mint authority to authorize a mint.
     */
    struct MintArgs {
        uint256 seriesIndex;
        uint256 mintPrice;
        uint256 maxTokenIdExclusive;
        uint256 nonce;
    }

    //---------------- Events ----------------//

    event SetRoyaltyReceiver(
        address royaltyReceiver
    );

    event SetRoyaltyBips(
        uint256 royaltyBips
    );

    event SetSeriesInfo(
        uint256 indexed seriesIndex,
        string name,
        bytes32 provenanceHash
    );

    event AdvancedPoemCreationDeadline(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline
    );

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    event FinishedPoem(
        uint256 indexed tokenId
    );

    //---------------- Functions ----------------//

    function getPoemTraits(
        uint256 tokenId
    )
        external
        view
        returns (IIkaniV2.PoemTraits memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";
import { IIkaniV2Staking } from "../interfaces/IIkaniV2Staking.sol";
import { MinHeap } from "../lib/MinHeap.sol";

library IS2Lib {
    using MinHeap for MinHeap.Heap;
    using SafeCastUpgradeable for uint256;

    //---------------- Constants ----------------//

    uint256 internal constant MULTIPLIER_BASE = 1e6;
    uint256 internal constant MULTIPLIER_BASE_2 = MULTIPLIER_BASE ** 2;

    uint256 internal constant BASE_POINTS_NO_FOIL = 1e6;
    uint256 internal constant BASE_POINTS_GOLD = 1.5e6;
    uint256 internal constant BASE_POINTS_PLATINUM = 2.25e6;
    uint256 internal constant BASE_POINTS_SUI_GENERIS = 3.375e6;

    uint256 internal constant SEASONS_MULTIPLIER_2 = 1.05e6;
    uint256 internal constant SEASONS_MULTIPLIER_3 = 1.12e6;
    uint256 internal constant SEASONS_MULTIPLIER_4 = 1.25e6;

    uint256 internal constant FABRICS_MULTIPLIER_2 = 1.05e6;
    uint256 internal constant FABRICS_MULTIPLIER_3 = 1.12e6;
    uint256 internal constant FABRICS_MULTIPLIER_4 = 1.25e6;

    uint256 internal constant LEVEL_MULTIPLIER_1 = 1.05e6;
    uint256 internal constant LEVEL_MULTIPLIER_2 = 1.1e6;
    uint256 internal constant LEVEL_MULTIPLIER_3 = 1.2e6;
    uint256 internal constant LEVEL_MULTIPLIER_4 = 1.3e6;

    uint256 internal constant LEVEL_DURATION_1 = 1 weeks;
    uint256 internal constant LEVEL_DURATION_2 = 2 weeks;
    uint256 internal constant LEVEL_DURATION_3 = 4 weeks;
    uint256 internal constant LEVEL_DURATION_4 = 12 weeks;

    uint256 internal constant LAST_LEVEL = 4;

    //---------------- External Functions ----------------//

    /**
     * @dev Settle rewards to current timestamp, returning updated context and new rewards.
     *
     *  After calling this function, the returned updated context should be saved to storage.
     *  The new rewards should also be saved to storage (or spent).
     */
    function settleAccountAndGetOwedRewards(
        IIkaniV2Staking.SettlementContext memory intialContext,
        mapping(uint256 => IIkaniV2Staking.RateChange) storage _rate_changes_,
        MinHeap.Heap storage _checkpoints_,
        mapping(uint256 => IIkaniV2Staking.TokenStakingState) storage _token_staking_state_,
        uint256 globalNumRateChanges
    )
        external
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            uint256 newRewards
        )
    {
        context = intialContext;
        newRewards = 0;

        if (context.timestamp == block.timestamp) {
            // Short-circuit.
            return (context, newRewards);
        }

        if (context.points == 0) {
            // Short-circuit.
            //
            // TODO: Clarify the note below.
            //
            // Note: We don't remove old checkpoints from the heap at this time. It's important
            // that any old checkpoints are invalidated by the change in staking nonce, otherwise
            // this function would revert when trying to settle a checkpoint whose timestamp is
            // less than the context timestamp.
            context.timestamp = block.timestamp.toUint32();
            context.numRateChanges = globalNumRateChanges.toUint32();

            // Get the current base rate.
            context.baseRate = _rate_changes_[globalNumRateChanges].baseRate;

            return (context, newRewards);
        }

        // Load into memory any rate changes that need to be applied.
        uint256 numRateChangesToApply = globalNumRateChanges - context.numRateChanges;
        IIkaniV2Staking.RateChange[] memory rateChanges = (
            new IIkaniV2Staking.RateChange[](numRateChangesToApply)
        );
        for (uint256 i = 0; i < numRateChangesToApply;) {
            unchecked {
                rateChanges[i] = _rate_changes_[context.numRateChanges + i + 1];
                ++i;
            }
        }

        // Iterate over the checkpoints in chronological order.
        while (_checkpoints_.length > 0) {
            IIkaniV2Staking.Checkpoint memory checkpoint;

            {
                uint256 checkpointUint = _checkpoints_.unsafePeek();

                // Get the threshold for checkpoints that have been reached.
                uint256 checkpointThreshold;
                unchecked {
                    checkpointThreshold = (block.timestamp + 1) << 224;
                }

                // Stop iterating if the next checkpoint has not been reached.
                if (checkpointUint >= checkpointThreshold) {
                    break;
                }

                // If the checkpoint was reached, remove it from the heap and process it.
                _checkpoints_.popMin();

                // Parse the checkpoint.
                checkpoint = _decodeCheckpoint(checkpointUint);
            }

            // Ignore and discard the checkpoint if it is no longer valid.
            // A checkpoint is no longer valid if the associated token was unstaked since the
            // checkpoint was created.
            {
                // TODO: Optimize by caching these?
                IIkaniV2Staking.TokenStakingState memory stakingState = (
                    _token_staking_state_[checkpoint.tokenId]
                );
                if (checkpoint.stakedNonce != stakingState.nonce) {
                    continue;
                }
                if (stakingState.timestamp == 0) {
                    // TODO: Remove.
                    //
                    // This check is redundant, and this continue should never be reached.
                    // Keeping it just for now.
                    // revert('Sanity check failed');
                    continue;
                }
            }

            // Process any rate changes that occurred before the checkpoint.
            while (context.numRateChanges < globalNumRateChanges) {
                uint256 rateIndex = (
                    numRateChangesToApply + context.numRateChanges - globalNumRateChanges
                );

                if (rateChanges[rateIndex].timestamp >= checkpoint.timestamp) {
                    break;
                }

                newRewards += _settleAccountToTimestamp(context, rateChanges[rateIndex].timestamp);
                context.timestamp = rateChanges[rateIndex].timestamp;

                context.baseRate = rateChanges[rateIndex].baseRate;
                ++context.numRateChanges;
            }

            // Settle up to the checkpoint timestamp.
            newRewards += _settleAccountToTimestamp(context, checkpoint.timestamp);
            context.timestamp = checkpoint.timestamp;

            // Add points from the checkpoint.
            uint256 level = uint256(checkpoint.level);
            uint256 bonusPoints;
            {
                bonusPoints = _getBonusPointsFromLevel(
                    uint256(checkpoint.basePoints),
                    level
                ).toUint32();
            }
            {
                context.points += bonusPoints.toUint32();
            }

            // Add next checkpoint if there is a next checkpoint.
            if (level < LAST_LEVEL) {
                checkpoint = _getNextCheckpoint(checkpoint);
                _insertCheckpoint(_checkpoints_, checkpoint);
            }
        }

        // Process any remaining rate changes and settle up to each one.
        while (context.numRateChanges < globalNumRateChanges) {
            IIkaniV2Staking.RateChange memory rateChange = rateChanges[
                numRateChangesToApply + context.numRateChanges - globalNumRateChanges
            ];

            newRewards += _settleAccountToTimestamp(context, rateChange.timestamp);
            context.timestamp = rateChange.timestamp;

            context.baseRate = rateChange.baseRate;
            ++context.numRateChanges;
        }

        // Settle up to the current timestamp.
        newRewards += _settleAccountToTimestamp(context, block.timestamp);
        context.timestamp = block.timestamp.toUint32();
    }

    function stakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakingStartTimestamp,
        uint256 stakedNonce,
        uint256 tokenId
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            IIkaniV2Staking.Checkpoint memory checkpoint
        )
    {
        context = intialContext;

        // Get base points (affected by foil).
        uint256 basePoints = getFoilRewardsMultiplier(traits);

        // Determine level and points (affected by staked duration).
        uint256 stakedDuration = block.timestamp - stakingStartTimestamp;
        uint256 level = getLevelForStakedDuration(stakedDuration);
        uint256 points = (
            basePoints *
            _getLevelRewardsMultiplier(level) /
            MULTIPLIER_BASE
        );

        // If applicable, add a checkpoint for the next increase in points.
        if (level < LAST_LEVEL) {
            uint256 nextLevel;
            unchecked {
                nextLevel = level + 1;
            }
            uint256 checkpointTimestamp = stakingStartTimestamp + _getDurationForLevel(nextLevel);
            checkpoint = IIkaniV2Staking.Checkpoint({
                timestamp: checkpointTimestamp.toUint32(),
                level: nextLevel.toUint32(),
                basePoints: basePoints.toUint32(),
                stakedNonce: stakedNonce.toUint32(),
                tokenId: tokenId.toUint128()
            });
        }

        // Update the trait counts, acount-level multiplier, and points for the account.
        context = _addTraitsToToken(context, traits);
        context.multiplier = getAccountRewardsMultiplier(context).toUint32();
        context.points += points.toUint32();
    }

    function unstakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakedTimestamp
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context
        )
    {
        context = intialContext;

        // Get base points (affected by foil).
        uint256 basePoints = getFoilRewardsMultiplier(traits);

        // Determine points (affected by staked duration).
        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        uint256 points = (
            basePoints *
            getStakedDurationRewardsMultiplier(stakedDuration) /
            MULTIPLIER_BASE
        );

        // Update the trait counts, acount-level multiplier, and points for the account.
        context = _subtractTraitsFromToken(context, traits);
        context.multiplier = getAccountRewardsMultiplier(context).toUint32();
        context.points -= points.toUint32();

    }

    //---------------- Public State-Changing Functions ----------------//

    function _insertCheckpoint(
        MinHeap.Heap storage _checkpoints_,
        IIkaniV2Staking.Checkpoint memory checkpoint
    )
        public
    {
        uint256 checkpointUint = (
            (uint256(checkpoint.timestamp) << 224) +
            (uint256(checkpoint.level) << 192) +
            (uint256(checkpoint.basePoints) << 160) +
            (uint256(checkpoint.stakedNonce) << 128) +
            checkpoint.tokenId
        );
        _checkpoints_.insert(checkpointUint);
    }

    //---------------- Public Pure Functions ----------------//

    function getFoilRewardsMultiplier(
        IIkaniV2.PoemTraits memory traits
    )
        public
        pure
        returns (uint256)
    {
        if (traits.foil == IIkaniV2.Foil.NONE) {
            return BASE_POINTS_NO_FOIL;
        } else if (traits.foil == IIkaniV2.Foil.GOLD) {
            return BASE_POINTS_GOLD;
        } else if (traits.foil == IIkaniV2.Foil.PLATINUM) {
            return BASE_POINTS_PLATINUM;
        } else if (traits.foil == IIkaniV2.Foil.SUI_GENERIS) {
            return BASE_POINTS_SUI_GENERIS;
        }

        // Sanity check.
        revert("Unknown foil");
    }

    function getStakedDurationRewardsMultiplier(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        if (stakedDuration < LEVEL_DURATION_1) {
            return MULTIPLIER_BASE;
        } else if (stakedDuration < LEVEL_DURATION_2) {
            return LEVEL_MULTIPLIER_1;
        } else if (stakedDuration < LEVEL_DURATION_3) {
            return LEVEL_MULTIPLIER_2;
        } else if (stakedDuration < LEVEL_DURATION_4) {
            return LEVEL_MULTIPLIER_3;
        }
        return LEVEL_MULTIPLIER_4;
    }

    function getAccountRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 fabricsMultiplier = getFabricsRewardsMultiplier(context);
        uint256 seasonsMultiplier = getSeasonsRewardsMultiplier(context);
        return fabricsMultiplier * seasonsMultiplier / MULTIPLIER_BASE;
    }

    function getFabricsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 uniqueFabricsCount = getNumFabricsStaked(context);
        if (uniqueFabricsCount == 4)  {
            return FABRICS_MULTIPLIER_4;
        } else if (uniqueFabricsCount == 3)  {
            return FABRICS_MULTIPLIER_3;
        } else if (uniqueFabricsCount == 2)  {
            return FABRICS_MULTIPLIER_2;
        }
        return MULTIPLIER_BASE;
    }

    function getSeasonsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 uniqueSeasonsCount = getNumSeasonsStaked(context);
        if (uniqueSeasonsCount == 4)  {
            return SEASONS_MULTIPLIER_4;
        } else if (uniqueSeasonsCount == 3)  {
            return SEASONS_MULTIPLIER_3;
        } else if (uniqueSeasonsCount == 2)  {
            return SEASONS_MULTIPLIER_2;
        }
        return MULTIPLIER_BASE;
    }

    function getNumFabricsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        unchecked {
            return (
                _toUint256(context.fabricKoyamaki > 0) +
                _toUint256(context.fabricSeigaiha > 0) +
                _toUint256(context.fabricNami > 0) +
                _toUint256(context.fabricKumo > 0)
            );
        }
    }

    function getNumSeasonsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        unchecked {
            return (
                _toUint256(context.seasonSpring > 0) +
                _toUint256(context.seasonSummer > 0) +
                _toUint256(context.seasonAutumn > 0) +
                _toUint256(context.seasonWinter > 0)
            );
        }
    }

    function getLevelForStakedDuration(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        if (stakedDuration < LEVEL_DURATION_1) {
            return 0;
        } else if (stakedDuration < LEVEL_DURATION_2) {
            return 1;
        } else if (stakedDuration < LEVEL_DURATION_3) {
            return 2;
        } else if (stakedDuration < LEVEL_DURATION_4) {
            return 3;
        }
        return LAST_LEVEL; // 4
    }

    //---------------- Private Pure Functions ----------------//

    function _getLevelRewardsMultiplier(
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        if (level == 0) {
            return MULTIPLIER_BASE;
        } else if (level == 1) {
            return LEVEL_MULTIPLIER_1;
        } else if (level == 2) {
            return LEVEL_MULTIPLIER_2;
        } else if (level == 3) {
            return LEVEL_MULTIPLIER_3;
        } else if (level == 4) {
            return LEVEL_MULTIPLIER_4;
        }

        // Sanity check.
        revert("Unknown level");
    }

    function _getDurationForLevel(
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        // Note: This function cannot be called with level = 0.
        if (level == 1) {
            return LEVEL_DURATION_1;
        } else if (level == 2) {
            return LEVEL_DURATION_2;
        } else if (level == 3) {
            return LEVEL_DURATION_3;
        } else if (level == 4) {
            return LEVEL_DURATION_4;
        }

        // Sanity check.
        revert("Unknown level");
    }

    function _addTraitsToToken(
        IIkaniV2Staking.SettlementContext memory context,
        IIkaniV2.PoemTraits memory traits
    )
        private
        pure
        returns (IIkaniV2Staking.SettlementContext memory)
    {
        // TODO: Optimize.
        context.seasonSpring += _toUint8(traits.season == IIkaniV2.Season.SPRING);
        context.seasonSummer += _toUint8(traits.season == IIkaniV2.Season.SUMMER);
        context.seasonAutumn += _toUint8(traits.season == IIkaniV2.Season.AUTUMN);
        context.seasonWinter += _toUint8(traits.season == IIkaniV2.Season.WINTER);
        context.fabricKoyamaki += _toUint8(traits.fabric == IIkaniV2.Fabric.KOYAMAKI);
        context.fabricSeigaiha += _toUint8(traits.fabric == IIkaniV2.Fabric.SEIGAIHA);
        context.fabricNami += _toUint8(traits.fabric == IIkaniV2.Fabric.NAMI);
        context.fabricKumo += _toUint8(traits.fabric == IIkaniV2.Fabric.KUMO);

        return context;
    }

    function _subtractTraitsFromToken(
        IIkaniV2Staking.SettlementContext memory context,
        IIkaniV2.PoemTraits memory traits
    )
        private
        pure
        returns (IIkaniV2Staking.SettlementContext memory)
    {
        // TODO: Optimize.
        context.seasonSpring -= _toUint8(traits.season == IIkaniV2.Season.SPRING);
        context.seasonSummer -= _toUint8(traits.season == IIkaniV2.Season.SUMMER);
        context.seasonAutumn -= _toUint8(traits.season == IIkaniV2.Season.AUTUMN);
        context.seasonWinter -= _toUint8(traits.season == IIkaniV2.Season.WINTER);
        context.fabricKoyamaki -= _toUint8(traits.fabric == IIkaniV2.Fabric.KOYAMAKI);
        context.fabricSeigaiha -= _toUint8(traits.fabric == IIkaniV2.Fabric.SEIGAIHA);
        context.fabricNami -= _toUint8(traits.fabric == IIkaniV2.Fabric.NAMI);
        context.fabricKumo -= _toUint8(traits.fabric == IIkaniV2.Fabric.KUMO);

        return context;
    }

    function _settleAccountToTimestamp(
        IIkaniV2Staking.SettlementContext memory context,
        uint256 timestamp
    )
        private
        pure
        returns (uint256)
    {
        uint256 timeDelta = timestamp - context.timestamp;
        uint256 rewards = (
            timeDelta *
            context.baseRate *
            context.points *
            context.multiplier /
            MULTIPLIER_BASE_2
        );

        return rewards;
    }

    function _getNextCheckpoint(
        IIkaniV2Staking.Checkpoint memory checkpoint
    )
        private
        pure
        returns (IIkaniV2Staking.Checkpoint memory)
    {
        // Assumption: checkpoint.level < LAST_LEVEL
        uint256 timestampDiff;
        unchecked {
            uint32 newLevel = ++checkpoint.level;
            if (newLevel == 2) {
                timestampDiff = LEVEL_DURATION_2 - LEVEL_DURATION_1;
            } else if (newLevel == 3) {
                timestampDiff = LEVEL_DURATION_3 - LEVEL_DURATION_2;
            } else if (newLevel == 4) {
                timestampDiff = LEVEL_DURATION_4 - LEVEL_DURATION_3;
            }
        }
        checkpoint.timestamp += timestampDiff.toUint32();
        return checkpoint;
    }

    function _getBonusPointsFromLevel(
        uint256 basePoints,
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        // example params:
        //              no foil: base points 1e6
        //                 gold: base points 1.2e6
        //   level 1 multiplier: 1.1e6
        //   level 2 multiplier: 1.2e6
        //                 base: 1e6
        //
        // then the bonus points that are unlocked are
        //
        // no foil, level 1: (1.1e6 - 1.0e6) * 1e6 / base = 0.1e6
        // no foil, level 2: (1.2e6 - 1.1e6) * 1e6 / base = 0.1e6
        //    gold, level 1: (1.1e6 - 1.0e6) * 1.2e6 / base = 0.12e6
        //    gold, level 2: (1.2e6 - 1.1e6) * 1.2e6 / base = 0.12e6
        //
        // result:
        //   no foil: 1e6 -> 1.1e6 -> 1.2e6
        //      gold: 1.2e6 -> 1.32e6 -> 1.44e6
        //
        // Assume this function will not be called with level = 0.
        uint256 diff = (
            _getLevelRewardsMultiplier(level) -
            _getLevelRewardsMultiplier(level - 1)
        );
        return basePoints * diff / MULTIPLIER_BASE;
    }

    function _decodeCheckpoint(
        uint256 checkpointUint
    )
        private
        pure
        returns (
            IIkaniV2Staking.Checkpoint memory checkpoint
        )
    {
        // Truncate (unsafe cast).
        checkpoint.timestamp = uint32(checkpointUint >> 224);
        checkpoint.level = uint32(checkpointUint >> 192);
        checkpoint.basePoints = uint32(checkpointUint >> 160);
        checkpoint.stakedNonce = uint32(checkpointUint >> 128);
        checkpoint.tokenId = uint128(checkpointUint);
    }

    function _toUint8(bool x)
        private
        pure
        returns (uint8 r)
    {
        assembly { r := x }
    }

    function _toUint256(bool x)
        private
        pure
        returns (uint256 r)
    {
        assembly { r := x }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2Staking
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IIkaniV2Staking features of the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2Staking {

    //---------------- Structs ----------------//

    struct RateChange {
        uint32 baseRate;
        uint32 timestamp;
    }

    struct SettlementContext {
        // The timestamp of the last settlement of this account.
        uint32 timestamp;
        // The number of global rate changes taken into account as of the last settlement
        // of this account.
        uint32 numRateChanges;
        // The global base earning rate.
        uint32 baseRate;
        // The current number of points for the account's staked tokens.
        uint32 points;
        // Current multiplier derived from the account's staked traits.
        uint32 multiplier;
        // The trait counts for the account's staked tokens.
        uint8 fabricKoyamaki;
        uint8 fabricSeigaiha;
        uint8 fabricNami;
        uint8 fabricKumo;
        uint8 fabricTba5;
        uint8 fabricTba6;
        uint8 fabricTba7;
        uint8 fabricTba8;
        uint8 seasonSpring;
        uint8 seasonSummer;
        uint8 seasonAutumn;
        uint8 seasonWinter;
    }

    struct Checkpoint {
        uint128 tokenId;
        uint32 stakedNonce;
        uint32 basePoints;
        uint32 level;
        uint32 timestamp;
    }

    struct TokenStakingState {
        uint32 timestamp;
        uint32 nonce;
    }

    //---------------- Events ----------------//

    event SetBaseRate(
        uint256 baseRate
    );

    event AdminUnstaked(
        address indexed owner,
        uint256[] indexed tokenIds,
        bytes32 indexed receipt,
        bytes receiptData
    );

    event Staked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 stakingStartTimestamp
    );

    event Unstaked(
        address indexed owner,
        uint256 indexed tokenId
    );

    event ClaimedRewards(
        address indexed owner,
        uint256 amount
    );

    //---------------- Functions ----------------//

    function isStaked(
        uint256 tokenId
    )
        external
        view
        returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "./Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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

import "./AddressUpgradeable.sol";

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC20 } from "../../../deps/oz_c_4_7_2/IERC20.sol";

import { IIkaniERC20 } from "../../../erc20/interfaces/IIkaniERC20.sol";

import { IS2Storage } from "./IS2Storage.sol";

/**
 * @title IS2Erc20
 * @author Cyborg Labs, LLC
 *
 * @notice Handles interactions with the ERC20 token.
 */
abstract contract IS2Erc20 is
    IS2Storage
{
    //---------------- Constants ----------------//

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable REWARDS_ERC20;

    uint256 private constant REWARDS_CONVERSION_FACTOR = 1e6;

    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address rewardsErc20
    ) {
        REWARDS_ERC20 = rewardsErc20;
    }

    //---------------- Internal Functions ----------------//

    function _issueRewards(
        address recipient,
        uint256 rewardsAmount
    )
        internal
        returns (uint256)
    {
        uint256 erc20Amount = _getErc20Amount(rewardsAmount);
        // Note: Not using SafeERC20, to save a bit of gas, since this is our own token.
        IERC20(REWARDS_ERC20).transfer(
            recipient,
            erc20Amount
        );
        return erc20Amount;
    }

    function _burnErc20(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        IIkaniERC20(REWARDS_ERC20).burnWithPermit(
            owner,
            burnAmount,
            burnReceipt,
            burnReceiptData,
            deadline,
            v,
            r,
            s
        );
    }

    function _getErc20Amount(
        uint256 rewardsAmount
    )
        internal
        pure
        returns (uint256)
    {
        return rewardsAmount * REWARDS_CONVERSION_FACTOR;
    }
}