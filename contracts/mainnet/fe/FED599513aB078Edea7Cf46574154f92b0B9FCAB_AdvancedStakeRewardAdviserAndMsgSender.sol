// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "./actions/AdvancedStakingBridgedDataCoder.sol";
import "./actions/Constants.sol";
import "./interfaces/IActionMsgReceiver.sol";
import "./interfaces/IFxStateSender.sol";
import "./StakeZeroRewardAdviser.sol";

/***
 * @title AdvancedStakeRewardAdviserAndMsgSender
 * @notice The "zero reward adviser" for the `RewardMaster` that sends `STAKE` action messages over
 * the PoS bridge to the STAKE_MSG_RECEIVER.
 * @dev It is assumed to run on the mainnet/Goerli and be authorized with the `RewardMaster` on the
 * same network as the "Reward Adviser" for "advanced" stakes.
 * As the "Reward Adviser" it gets called `getRewardAdvice` by the `RewardMaster` every time a user
 * creates or withdraws an "advanced" stake. It returns the "zero" advices, i.e. the `Advice` data
 * structure with zero `sharesToCreate` and `sharesToRedeem`.
 * On "zero" advices, the RewardMaster skips creating/redeeming "treasure shares" for/to stakers.
 * If the `getRewardAdvice` is called w/ the action STAKE (i.e. a new stake is being created), this
 * contract sends the STAKE message over the "Fx-Portal" (the PoS bridge run by the Polygon team)
 * to the STAKE_MSG_RECEIVER on the Polygon/Mumbai. The STAKE_MSG_RECEIVER is supposed to be the
 * `AdvancedStakeActionMsgRelayer` contract that processes the bridged messages, rewarding stakers
 * on the Polygon/Mumbai.
 */
contract AdvancedStakeRewardAdviserAndMsgSender is
    StakeZeroRewardAdviser,
    AdvancedStakingBridgedDataCoder
{
    event StakeMsgBridged(uint256 _nonce, bytes data);

    // solhint-disable var-name-mixedcase

    /// @notice Address of the `FxRoot` contract on the mainnet/Goerli network
    /// @dev `FxRoot` is the contract of the "Fx-Portal" on the mainnet/Goerli.
    address public immutable FX_ROOT;

    /// @notice Address of the RewardMaster contract on the mainnet/Goerli
    address public immutable REWARD_MASTER;

    /// @notice Address on the AdvancedStakeActionMsgRelayer on the Polygon/Mumbai
    address public immutable ACTION_MSG_RECEIVER;

    // solhint-enable var-name-mixedcase

    /// @notice Message nonce (i.e. sequential number of the latest message)
    uint256 public nonce;

    /// @param _rewardMaster Address of the RewardMaster contract on the mainnet/Goerli
    /// @param _actionMsgReceiver Address of the AdvancedStakeActionMsgRelayer on Polygon/Mumbai
    /// @param _fxRoot Address of the `FxRoot` (PoS Bridge) contract on mainnet/Goerli
    constructor(
        // slither-disable-next-line similar-names
        address _rewardMaster,
        address _actionMsgReceiver,
        address _fxRoot
    ) StakeZeroRewardAdviser(ADVANCED_STAKE, ADVANCED_UNSTAKE) {
        require(
            _fxRoot != address(0) &&
                _actionMsgReceiver != address(0) &&
                _rewardMaster != address(0),
            "AMS:E01"
        );

        FX_ROOT = _fxRoot;
        REWARD_MASTER = _rewardMaster;
        ACTION_MSG_RECEIVER = _actionMsgReceiver;
    }

    // It is called withing the `function getRewardAdvice`
    function _onRequest(bytes4 action, bytes memory message) internal override {
        // Ignore other messages except the STAKE
        if (action != STAKE) return;

        // Overflow ignored as the nonce is unexpected ever be that big
        uint24 _nonce = uint24(nonce + 1);
        nonce = uint256(_nonce);

        bytes memory content = _encodeBridgedData(_nonce, action, message);
        // known contract call - no need in reentrancy guard
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        IFxStateSender(FX_ROOT).sendMessageToChild(
            ACTION_MSG_RECEIVER,
            content
        );

        emit StakeMsgBridged(_nonce, content);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IRewardAdviser.sol";

/**
 * @title StakeZeroRewardAdviser
 * @notice The "reward adviser" for the `RewardMaster` that returns the "zero reward advice" only.
 * @dev The "zero" reward advice is the `Advice` with zero `sharesToCreate` and `sharesToRedeem`.
 * On "zero" advices, the RewardMaster skips creating/redeeming "treasure shares" for/to stakers.
 */
abstract contract StakeZeroRewardAdviser is
    StakingMsgProcessor,
    IRewardAdviser
{
    // solhint-disable var-name-mixedcase

    // `stakeAction` for the STAKE
    bytes4 internal immutable STAKE;

    // `stakeAction` for the UNSTAKE
    bytes4 internal immutable UNSTAKE;

    // solhint-enable var-name-mixedcase

    /// @param stakeAction The STAKE action type (see StakingMsgProcessor::_encodeStakeActionType)
    /// @param unstakeAction The UNSTAKE action type (see StakingMsgProcessor::_encodeUNstakeActionType)
    constructor(bytes4 stakeAction, bytes4 unstakeAction) {
        require(
            stakeAction != bytes4(0) && unstakeAction != bytes4(0),
            "ZRA:E1"
        );
        STAKE = stakeAction;
        UNSTAKE = unstakeAction;
    }

    /// @dev It is assumed to be called by the RewardMaster contract.
    /// It returns the "zero" reward advises, no matter who calls it.
    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        override
        returns (Advice memory)
    {
        require(
            action == STAKE || action == UNSTAKE,
            "ZRA: unsupported action"
        );

        _onRequest(action, message);

        // Return the "zero" advice
        return
            Advice(
                address(0), // createSharesFor
                0, // sharesToCreate
                address(0), // redeemSharesFrom
                0, // sharesToRedeem
                address(0) // sendRewardTo
            );
    }

    // solhint-disable no-empty-blocks
    // slither-disable-next-line dead-code
    function _onRequest(bytes4 action, bytes memory message) internal virtual {
        // Child contracts may re-define it
    }
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

/***
 * @title AdvancedStakingBridgedDataDecoder
 * @dev It encode (pack) and decodes (unpack) messages for bridging them between networks
 */
abstract contract AdvancedStakingBridgedDataCoder {
    function _encodeBridgedData(
        uint24 _nonce,
        bytes4 action,
        bytes memory message
    ) internal pure returns (bytes memory content) {
        content = abi.encodePacked(_nonce, action, message);
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _decodeBridgedData(bytes memory content)
        internal
        pure
        returns (
            uint256 _nonce,
            bytes4 action,
            bytes memory message
        )
    {
        require(content.length >= 7, "ABD:WRONG_LENGTH");

        _nonce =
            (uint256(uint8(content[0])) << 16) |
            (uint256(uint8(content[1])) << 8) |
            uint256(uint8(content[2]));

        action = bytes4(
            uint32(
                (uint256(uint8(content[3])) << 24) |
                    (uint256(uint8(content[4])) << 16) |
                    (uint256(uint8(content[5])) << 8) |
                    uint256(uint8(content[6]))
            )
        );

        uint256 curPos = 7;
        uint256 msgLength = content.length - curPos;
        message = new bytes(msgLength);
        if (msgLength > 0) {
            uint256 i = 0;
            while (i < msgLength) {
                message[i++] = content[curPos++];
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

// solhint-disable var-name-mixedcase

// The "stake type" for the "classic staking"
// bytes4(keccak256("classic"))
bytes4 constant CLASSIC_STAKE_TYPE = 0x4ab0941a;

// STAKE "action type" for the "classic staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), CLASSIC_STAKE_TYPE)))
bytes4 constant CLASSIC_STAKE = 0x1e4d02b5;

// UNSTAKE "action type" for the "classic staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), CLASSIC_STAKE_TYPE)))
bytes4 constant CLASSIC_UNSTAKE = 0x493bdf45;

// The "stake type" for the "advance staking"
// bytes4(keccak256("advanced"))
bytes4 constant ADVANCED_STAKE_TYPE = 0x7ec13a06;

// STAKE "action type" for the "advanced staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), ADVANCED_STAKE_TYPE)))
bytes4 constant ADVANCED_STAKE = 0xcc995ce8;

// UNSTAKE "action type" for the "advanced staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), ADVANCED_STAKE_TYPE)))
bytes4 constant ADVANCED_UNSTAKE = 0xb8372e55;

// PRP grant type for the "advanced" stake
// bytes4(keccak256("forAdvancedStakeGrant"))
bytes4 constant FOR_ADVANCED_STAKE_GRANT = 0x31a180d4;

// solhint-enable var-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

import "../interfaces/IStakingTypes.sol";

abstract contract StakingMsgProcessor {
    bytes4 internal constant STAKE_ACTION = bytes4(keccak256("stake"));
    bytes4 internal constant UNSTAKE_ACTION = bytes4(keccak256("unstake"));

    function _encodeStakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(STAKE_ACTION, stakeType)));
    }

    function _encodeUnstakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(UNSTAKE_ACTION, stakeType)));
    }

    function _packStakingActionMsg(
        address staker,
        IStakingTypes.Stake memory stake,
        bytes calldata data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                staker, // address
                stake.amount, // uint96
                stake.id, // uint32
                stake.stakedAt, // uint32
                stake.lockedTill, // uint32
                stake.claimedAt, // uint32
                data // bytes
            );
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _unpackStakingActionMsg(bytes memory message)
        internal
        pure
        returns (
            address staker,
            uint96 amount,
            uint32 id,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            bytes memory data
        )
    {
        // staker, amount, id and 3 timestamps occupy exactly 48 bytes
        // (`data` may be of zero length)
        require(message.length >= 48, "SMP: unexpected msg length");

        uint256 stakerAndAmount;
        uint256 idAndStamps;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }
        // solhint-enable no-inline-assembly

        staker = address(uint160(stakerAndAmount >> 96));
        amount = uint96(stakerAndAmount & 0xFFFFFFFFFFFFFFFFFFFFFFFF);

        id = uint32((idAndStamps >> 224) & 0xFFFFFFFF);
        stakedAt = uint32((idAndStamps >> 192) & 0xFFFFFFFF);
        lockedTill = uint32((idAndStamps >> 160) & 0xFFFFFFFF);
        claimedAt = uint32((idAndStamps >> 128) & 0xFFFFFFFF);

        uint256 dataLength = message.length - 48;
        data = new bytes(dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            data[i] = message[i + 48];
        }
    }
}

// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/***
 * @dev An interface of the `FxRoot` contract
 * `FxRoot` is the contract of the "Fx-Portal" (a PoS bridge run by the Polygon team) on the
 * mainnet/Goerli network. It passes data to s user-defined contract on the Polygon/Mumbai.
 * See https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
 */
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data)
        external;
}

// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}

// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IStakingTypes {
    // Stake type terms
    struct Terms {
        // if stakes of this kind allowed
        bool isEnabled;
        // if messages on stakes to be sent to the {RewardMaster}
        bool isRewarded;
        // limit on the minimum amount staked, no limit if zero
        uint32 minAmountScaled;
        // limit on the maximum amount staked, no limit if zero
        uint32 maxAmountScaled;
        // Stakes not accepted before this time, has no effect if zero
        uint32 allowedSince;
        // Stakes not accepted after this time, has no effect if zero
        uint32 allowedTill;
        // One (at least) of the following three params must be non-zero
        // if non-zero, overrides both `exactLockPeriod` and `minLockPeriod`
        uint32 lockedTill;
        // ignored if non-zero `lockedTill` defined, overrides `minLockPeriod`
        uint32 exactLockPeriod;
        // has effect only if both `lockedTill` and `exactLockPeriod` are zero
        uint32 minLockPeriod;
    }

    struct Stake {
        // index in the `Stake[]` array of `stakes`
        uint32 id;
        // defines Terms
        bytes4 stakeType;
        // time this stake was created at
        uint32 stakedAt;
        // time this stake can be claimed at
        uint32 lockedTill;
        // time this stake was claimed at (unclaimed if 0)
        uint32 claimedAt;
        // amount of tokens on this stake (assumed to be less 1e27)
        uint96 amount;
        // address stake voting power is delegated to
        address delegatee;
    }
}