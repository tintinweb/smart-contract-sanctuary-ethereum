// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

import { LibStaking } from "../libs/LibStaking.sol";

contract StakingFacet {
    // PUBLIC FUNCTIONS
    function checkpoint() public {
        LibStaking.checkpoint();
    }

    function withdraw() public {
        LibStaking.withdraw();
    }

    function increaseAmount(uint256 _value) public {
        LibStaking.increaseAmount(_value);
    }

    function increaseUnlockTime(uint256 _secondsIncrease) public {
        LibStaking.increaseUnlockTime(_secondsIncrease);
    }

    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) public {
        LibStaking.createLock(_for, _value, _lockDuration);
    }

    function depositFor(address _user, uint256 _value) public {
        LibStaking.depositFor(_user, _value);
    }

    // VIEW FUNCTIONS

    function getLastUserSlope(address _user) public view returns (int128) {
        return LibStaking.getLastUserSlope(_user);
    }

    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) public view returns (uint256) {
        return LibStaking.getUserPointHistoryTimestamp(_user, _userEpoch);
    }

    // function getUserLockedBalance(address _user) public view returns (LockedBalance memory) {
    //     bytes32 _userID = LibHelpers._getIdForAddress(_user);
    //     return s.userLockedBalances[_userID];
    // }

    function getUserLockedBalanceEndTime(address _user) public view returns (uint256) {
        return LibStaking.getUserLockedBalanceEndTime(_user);
    }

    function exchangeRate() public view returns (uint256) {
        return LibStaking.exchangeRate();
    }

    function getVENAYMForNAYM(uint256 _value) external view returns (uint256) {
        return LibStaking._getVENAYMForNAYM(_value);
    }

    function getNAYMForVENAYM(uint256 _value) external view returns (uint256) {
        return LibStaking._getNAYMForVENAYM(_value);
    }

    // standard ERC20 balanceOf function which reports a user's veNAYMS amount
    function balanceOf(address _user) public view returns (uint256) {
        return LibStaking.balanceOf(_user);
    }

    function name() public pure returns (string memory) {
        return LibStaking.name();
    }

    function symbol() public pure returns (string memory) {
        return LibStaking.symbol();
    }

    function decimals() public pure returns (uint8) {
        return LibStaking.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

import { AppStorage, LibAppStorage, LibAdmin, LibConstants, LibHelpers, LockedBalance, StakingCheckpoint } from "../AppStorage.sol";
import { LibMeta } from "src/diamonds/shared/libs/LibMeta.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "./LibTokenizedVaultIO.sol";

import { console2 } from "forge-std/console2.sol";

// Relies on this port of veCRV from Vyper to Solidity as reference:
// https://github.com/MochiFi/veCRV-vMOCHI/blob/main/contracts/vMochi.sol
// Original veCRV Vyper code:
// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
library LibStaking {
    // NOTE: If rewards are withdrawable, staking cannot be compound, must be linear

    // EVENTS
    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 depositType, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    // todo this does.. what? nothing it seems?
    function checkpoint() internal {
        _checkpoint(address(0), LockedBalance({ amount: 0, endTime: 0 }), LockedBalance({ amount: 0, endTime: 0 }));
    }

    function withdraw() internal {
        _withdraw(msg.sender);
    }

    function increaseAmount(uint256 _value) internal {
        depositFor(msg.sender, _value);
    }

    function increaseUnlockTime(uint256 _secondsIncrease) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(msg.sender);
        // kp TODO TODO - don't use s.userLockedBalances
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        uint256 unlockTime = ((_lockedData.endTime + _secondsIncrease) / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;
        // uint256 unlockTime = (_unlockTime / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK; // old version
        require(_lockedData.amount > 0, "STAKING: NO EXISTING LOCK");
        require(_lockedData.endTime > block.timestamp, "STAKING: LOCK EXPIRED");
        require(unlockTime > _lockedData.endTime, "STAKING: ONLY INCREASE DURATION");
        require(unlockTime <= block.timestamp + LibConstants.STAKING_MAXTIME, "STAKING: OVER MAX LOCK TIME");
        _depositFor(msg.sender, 1, unlockTime, _lockedData, LibConstants.STAKING_INCREASE_UNLOCK_TIME);
    }

    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // TODO enable rounding down to nearest week? messes with set lengths e.g. 60 days
        uint256 unlockTime = ((_lockDuration + block.timestamp) / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;
        // uint256 unlockTime = (_unlockAt / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK; // old version
        bytes32 _userID = LibHelpers._getIdForAddress(msg.sender);

        require(_value > 0, "STAKING: ZERO VALUE");
        // TODO: Fix. 60 day min will cause issues with week rounding down
        // require(unlockTime >= block.timestamp + MINTIME, "STAKING: LESS THAN MIN TIME");
        require(unlockTime <= block.timestamp + LibConstants.STAKING_MAXTIME, "STAKING: MORE THAN MAX TIME");
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        require(_lockedData.amount == 0, "STAKING: WITHDRAW EXISTING FIRST");

        _depositFor(_for, _value, unlockTime, _lockedData, LibConstants.STAKING_CREATE_LOCK_TYPE);
    }

    // todo make sure we are getting correct user IDs here.
    function depositFor(address _user, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        // LockedBalance memory _lockedData = s.userLockedBalances[_userID];
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        require(_value > 0, "STAKING: ZERO VALUE");
        require(_lockedData.amount > 0, "STAKING: LOCK DOES NOT EXIST");
        require(_lockedData.endTime > block.timestamp, "STAKING: LOCKED EXPIRED");
        _depositFor(_user, _value, 0, _lockedData, LibConstants.STAKING_DEPOSIT_FOR_TYPE);
    }

    // _user is recipient of veNAYMS position
    function _depositFor(
        address _user,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _lockedData,
        int128 _type
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // save supply before increases
        // uint256 supplyBefore = s.stakedSupply;
        uint256 supplyBefore = LibTokenizedVault._internalTokenSupply(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        bytes32 receiverId = LibHelpers._getIdForAddress(_user); // separate ID for recipient of veNAYMS
        bytes32 depositorId = LibHelpers._getIdForAddress(msg.sender); // separate ID for depositor, these might not be the same address

        console2.log("msg.sender in staking", msg.sender);
        // calculate amount to be minted PRIOR to updating staking supply (aka supply of veNAYM)
        uint256 mintAmount = ((_value * LibConstants.SCALE) / exchangeRate());
        // s.stakedSupply += ((_value * LibConstants.SCALE) / exchangeRate());

        if (_value != 0) {
            LibTokenizedVaultIO._externalDeposit(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), address(this), _value);

            // Internal transfer of NAYMS from depositor to staking contract for _value
            // TODO check STAKING_ID is in line with account transferred from in _withdraw
            // LibTokenizedVault._internalTransfer(
            //     depositorId,
            //     LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
            //     s.naymsTokenId,
            //     // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER),
            //     _value
            // );
        }

        LibTokenizedVault._internalMint(receiverId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), mintAmount);

        // Load prev version of LockedBalance for checkpoint function
        // LockedBalance memory oldLocked = s.userLockedBalances[receiverId];
        LockedBalance memory oldLocked = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(receiverId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[receiverId]
        });

        // Increase amount locked by NAYMS value / veNAYMS exchange rate
        _lockedData.amount += ((_value * LibConstants.SCALE) / exchangeRate());

        if (_unlockTime != 0) {
            _lockedData.endTime = _unlockTime;
            s.userLockedEndTime[receiverId] = _unlockTime;
        }

        // Persist modified LockedBalance to storage
        // todo check if I modified this correctly
        // s.userLockedBalances[receiverId] = _lockedData;

        _checkpoint(_user, oldLocked, _lockedData);

        emit Deposit(_user, _value, _unlockTime, _type, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    function _withdraw(address _user) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        bytes32 _stmID = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
        // todo double check if this update is good
        // LockedBalance memory _lockedData = s.userLockedBalances[_userID];
        LockedBalance memory oldLocked = LockedBalance({ amount: LibTokenizedVault._internalBalanceOf(_userID, _stmID), endTime: s.userLockedEndTime[_userID] });

        require(block.timestamp >= oldLocked.endTime, "STAKING: UNLOCK TIME NOT REACHED");
        // todo simplify types
        uint256 value = uint256(int256(oldLocked.amount));

        // Setting user's LockedBalance endTime and amount to 0
        // LockedBalance memory oldLocked = s.userLockedBalances[_userID];
        // _lockedData.endTime = 0;
        // _lockedData.amount = 0;
        // s.userLockedBalances[_userID] = _lockedData;

        // value in terms of veNAYMS, withdrawAmount in terms of NAYMS
        uint256 withdrawAmount = (value * exchangeRate()) / LibConstants.SCALE;

        uint256 supplyBefore = LibTokenizedVault._internalTokenSupply(_stmID);

        LibTokenizedVault._internalBurn(_userID, _stmID, withdrawAmount);

        // Internal transfer of NAYMS to _user for withdrawAmount
        // TODO check this account is in line with account transferred to (STAKING_ID) in _depositFor
        // TODO Ted added staking id - please double check
        // NOTE: everything regarding transfers is handled (or should be) in the internal burn method above
        // LibTokenizedVault._internalTransfer(
        //     _userID,
        //     LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
        //     s.naymsTokenId,
        //     // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER),
        //     withdrawAmount
        // );

        // uint256 supplyBefore = s.stakedSupply;
        // s.stakedSupply -= value;

        // todo fetch actual values? or is this mock okay
        LockedBalance memory _lockedData = LockedBalance({ endTime: 0, amount: 0 });
        _checkpoint(_user, oldLocked, _lockedData);
        emit Withdraw(_user, withdrawAmount, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    function _checkpoint(
        address _user,
        LockedBalance memory _oldLocked,
        LockedBalance memory _newLocked
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        StakingCheckpoint memory uOldCheckpoint;
        StakingCheckpoint memory uNewCheckpoint;
        int128 oldSlope = 0;
        int128 newSlope = 0;
        uint256 epoch = s.stakingEpoch;
        bytes32 userID = LibHelpers._getIdForAddress(_user);

        if (_user != address(0)) {
            // Setting old checkpoint values
            if (_oldLocked.endTime > block.timestamp && _oldLocked.amount > 0) {
                uOldCheckpoint.slope = int128(int256(_oldLocked.amount)) / int128(int256(LibConstants.STAKING_MAXTIME));
                uOldCheckpoint.bias = uOldCheckpoint.slope * int128(int256(_oldLocked.endTime - block.timestamp));
            }
            // Setting new checkpoint values
            if (_newLocked.endTime > block.timestamp && _newLocked.amount > 0) {
                uNewCheckpoint.slope = int128(int256(_newLocked.amount)) / int128(int256(LibConstants.STAKING_MAXTIME));
                uNewCheckpoint.bias = uNewCheckpoint.slope * int128(int256(_newLocked.endTime - block.timestamp));
            }

            oldSlope = s.stakingSlopeChanges[_oldLocked.endTime];
            if (_newLocked.endTime != 0) {
                if (_newLocked.endTime == _oldLocked.endTime) {
                    newSlope = oldSlope;
                } else {
                    newSlope = s.stakingSlopeChanges[_newLocked.endTime];
                }
            }
        }

        // Fresh checkpoint object for global last checkpoint
        StakingCheckpoint memory lastCheckpoint = StakingCheckpoint({ bias: 0, slope: 0, ts: block.timestamp, blk: block.number });

        // save last global checkpoint if in a non-zero epoch
        if (epoch > 0) {
            lastCheckpoint = s.globalStakingCheckpointHistory[epoch];
        }

        uint256 lastCheckpointTimestamp = lastCheckpoint.ts;

        {
            // Storing another copy of lastCheckpoint in memory
            StakingCheckpoint memory initialLastCheckpoint = StakingCheckpoint({
                bias: lastCheckpoint.bias,
                slope: lastCheckpoint.slope,
                ts: lastCheckpoint.ts,
                blk: lastCheckpoint.blk
            });

            uint256 blockSlope = 0;

            // Calculating slope as change in block num over change in time
            // if epoch > 0, this will be true (see above in function)
            if (block.timestamp > lastCheckpoint.ts) {
                blockSlope = (LibConstants.SCALE * (block.number - lastCheckpoint.blk)) / (block.timestamp - lastCheckpoint.ts);
            }

            // Rounding last checkpoint timestamp down to nearest week
            uint256 t_i = (lastCheckpointTimestamp / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;

            for (uint256 i = 0; i < 255; i++) {
                // increment by week in timestamp
                t_i += LibConstants.STAKING_WEEK;
                int128 dSlope = 0;

                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    dSlope = s.stakingSlopeChanges[t_i];
                }

                lastCheckpoint.bias -= lastCheckpoint.slope * int128(int256(t_i - lastCheckpointTimestamp));
                lastCheckpoint.slope += dSlope;

                if (lastCheckpoint.bias < 0) {
                    lastCheckpoint.bias = 0;
                }
                if (lastCheckpoint.slope < 0) {
                    lastCheckpoint.slope = 0;
                }

                lastCheckpointTimestamp = t_i;
                lastCheckpoint.ts = t_i;
                lastCheckpoint.blk == initialLastCheckpoint.blk + (blockSlope * (t_i - initialLastCheckpoint.ts)) / LibConstants.SCALE;
                epoch += 1;

                // if caught up to current time, save block num and break out loop
                if (t_i == block.timestamp) {
                    lastCheckpoint.blk = block.number;
                    break;
                } else {
                    // else store latest checkpoint in historic checkpoint mapping and loop again
                    s.globalStakingCheckpointHistory[epoch] = lastCheckpoint;
                }
            }

            // epoch up to date, persist to storage
            s.stakingEpoch = epoch;

            // update last checkpoint slope and bias,
            // calced from diff in user checkpoint slope and bias
            if (_user != address(0)) {
                lastCheckpoint.slope += uNewCheckpoint.slope - uOldCheckpoint.slope;
                lastCheckpoint.bias += uNewCheckpoint.bias - uOldCheckpoint.bias;
                if (lastCheckpoint.slope < 0) {
                    lastCheckpoint.slope = 0;
                }
                if (lastCheckpoint.bias < 0) {
                    lastCheckpoint.bias = 0;
                }
            }
        }

        // finally, store updated global checkpoint for latest epoch
        s.globalStakingCheckpointHistory[epoch] = lastCheckpoint;

        // Update old and new slopes, save in stakingSlopeChanges storage mapping
        if (_user != address(0)) {
            if (_oldLocked.endTime > block.timestamp) {
                oldSlope += uOldCheckpoint.slope;
                if (_newLocked.endTime == _oldLocked.endTime) {
                    oldSlope -= uNewCheckpoint.slope;
                }
                s.stakingSlopeChanges[_oldLocked.endTime] = oldSlope;
            }
            if (_newLocked.endTime > block.timestamp) {
                if (_newLocked.endTime > _oldLocked.endTime) {
                    newSlope -= uNewCheckpoint.slope;
                    s.stakingSlopeChanges[_newLocked.endTime] = newSlope;
                }
            }

            // Update user epoch checkpoint and save to storage
            uint256 userEpoch = ++s.userStakingCheckpointEpoch[userID];
            uNewCheckpoint.ts = block.timestamp;
            uNewCheckpoint.blk = block.number;
            s.userStakingCheckpointHistory[userID][userEpoch] = uNewCheckpoint;
        }
    }

    // VIEW FUNCTIONS

    function getLastUserSlope(address _user) internal view returns (int128) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        uint256 userEpoch = s.userStakingCheckpointEpoch[_userID];
        return s.userStakingCheckpointHistory[_userID][userEpoch].slope;
    }

    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        return s.userStakingCheckpointHistory[_userID][_userEpoch].ts;
    }

    // function getUserLockedBalance(address _user) public view returns (LockedBalance memory) {
    //     bytes32 _userID = LibHelpers._getIdForAddress(_user);
    //     return s.userLockedBalances[_userID];
    // }

    function getUserLockedBalanceEndTime(address _user) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        // return s.userLockedBalances[_userID].endTime;
        return s.userLockedEndTime[_userID];
    }

    function exchangeRate() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 stakedSupply = LibTokenizedVault._internalTokenSupply(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        // if (s.stakedSupply == 0) {
        if (stakedSupply == 0) {
            // if supply = 0, return 1 with 18 decimals
            return 1e18;
        }

        // TODO check this is pulling balance for correct account
        uint256 naymBalanceInStaking = LibTokenizedVault._internalBalanceOf(
            LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
            // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER)
            s.naymsTokenId
        );

        // return (LibConstants.SCALE * naymBalanceInStaking) / s.stakedSupply;
        return (LibConstants.SCALE * naymBalanceInStaking) / stakedSupply;
    }

    function _getVENAYMForNAYM(uint256 _value) internal view returns (uint256) {
        return ((_value * LibConstants.SCALE) / exchangeRate());
    }

    function _getNAYMForVENAYM(uint256 _value) internal view returns (uint256) {
        return (_value * exchangeRate()) / LibConstants.SCALE;
    }

    // standard ERC20 balanceOf function which reports a user's veNAYMS amount
    function balanceOf(address _user) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        return s.userLockedBalances[_userID].amount;
    }

    function name() internal pure returns (string memory) {
        return LibConstants.VE_NAYM_NAME;
    }

    function symbol() internal pure returns (string memory) {
        return LibConstants.VE_NAYM_SYMBOL;
    }

    function decimals() internal pure returns (uint8) {
        return LibConstants.VE_NAYM_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice storage for nayms v3 decentralized insurance platform

import "./FreeStructs.sol";

import { LibMeta } from "../shared/libs/LibMeta.sol";

import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";

import { LibACL } from "./libs/LibACL.sol";

struct AppStorage {
    //// NAYMS ERC20 TOKEN ////
    mapping(address => uint256) nonces; //is this used?
    mapping(address => mapping(address => uint256)) allowance;
    address[] approvedContracts; // Is this used?
    mapping(address => uint256) approvedContractIndexes; // Is this used?
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => bytes32) objectTokenSymbol;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    // External Tokens
    // mapping(bytes32 => bool) externalTokens; // bytes32 ID of external token => is external token?
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //    mapping(address => uint256) permitExternalDepositNonce; // Is this used?
    // limit to three when updating???

    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    // // Keep track of the different dividends issued on chain
    // mapping(bytes32 => mapping(bytes32 => uint8)) issuedDividendsTokensIndex; // ownerId => dividendTokenId => index
    // mapping(bytes32 => mapping(uint8 => bytes32)) issuedDividendTokens; // ownerId => index => dividendTokenId
    // mapping(bytes32 => uint8) numIssuedDividends; //starts at 1. 0 means no dividends issued
    // //// DIVIDEND PAYOUT LOGIC ////
    // mapping(bytes32 => mapping(bytes32 => uint256)) divPerTokens; // entity ID => token ID => dividend per token ratio
    // mapping(bytes32 => mapping(bytes32 => EntityDividendInfo)) dividendInfos; // entity ID => token ID => dividend info

    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract LibHelpers._getIdForAddress(address(this))
    // When dividends are paid, they are transfered OUT of the diamond contract.
    //
    //
    // To calculate withdrawableDividiend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you trasnsfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransfered * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransfered * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division theser will be dust. Leave the dust in the diamond!!!

    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    uint256 groupsConfigUpdateIndex;
    uint256 canAssignConfigUpdateIndex;
    string[][] groupsConfig;
    string[][] canAssignConfig;
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// ACL Non Essential ////
    //these are only for user viewing. They can be removed.

    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    ////  STAKING  ////
    mapping(bytes32 => LockedBalance) userLockedBalances; // userID => LockedBalance struct todo NOT YET READY TO BE REMOVED
    mapping(bytes32 => uint256) userLockedEndTime; // userID => locked end time
    mapping(uint256 => StakingCheckpoint) globalStakingCheckpointHistory; // epoch => StakingCheckpoint struct
    mapping(bytes32 => mapping(uint256 => StakingCheckpoint)) userStakingCheckpointHistory; // userID => epoch => StakingCheckpoint
    mapping(bytes32 => uint256) userStakingCheckpointEpoch; // userID => user_epoch
    mapping(uint256 => int128) stakingSlopeChanges; // timestamp => signed slope change
    uint256 stakingEpoch;
    // uint256 stakedSupply; // todo READY TO BE REMOVED. use the internal total supply variable instead
    // Keep track of the different tokens owned on chain
    mapping(bytes32 => mapping(bytes32 => uint8)) ownedTokenIndex; // ownerId => tokenId => index
    mapping(bytes32 => mapping(uint8 => bytes32)) ownedTokenAtIndex; // ownerId => index => tokenId
    mapping(bytes32 => uint8) numOwnedTokens; //starts at 1. 0 means no tokens owned
    // ownedTokenIndex
    // ownedTokenAtIndex
    // numOwnedTokens

    // issuedDividendsIndex
    // issuedDividendsAtIndex
    // numIssuedDividends

    // mapping(ownerid => tokenid => index =) issuedDividends
    // mapping() numIssuedDividends //starts at 0

    ////
    //// FROM HERE ON, EVERYTHING IS DEPRECATED. MOVE TO USING THE SAME VARIABLE IN THE "Settings" STRUCTURE
    //// Use LibAdminFunctions._getSettings() to get the instance of settings you need
    ////

    // //// FEE BANK ////
    // bytes32 feeBankId;
    // bytes32 naymsLtdId;
    // bytes32 brokerFeeBankId; // the internal address that the fees all brokers have earned get distribuited to
    // bytes32 marketplaceBankId;
    // bytes32 dividendBankId;
    // bytes32 ndfBankId;
    ////  NDF  ////
    uint256 equilibriumLevel;
    uint256 actualDiscount;
    uint256 maxDiscount;
    uint256 actualNaymsAllocation;
    uint256 targetNaymsAllocation;
    address discountToken;
    uint24 poolFee;
    //// SSF ////
    uint256 rewardsCoefficient;
    mapping(bytes32 => uint256) userRewards;
    //// LP ////
    address lpAddress;
    ////  NAYMS  ////
    string wrappedTokenName;
    string wrappedTokenSymbol;
    uint8 wrappedTokenDecimals;
    address naymsToken; // represents the address key for this NAYMS token in AppStorage 1155 system
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage 1155 system
    //Token addresses for quotes and swaps
    address token0;
    address token1;
    //address token2;
    address pool;
    address uniswapFactory;
    /// Trading Commissions (all in basis points) ///
    uint16 tradingComissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total comission above is further divided as follows:
    uint16 tradingComissionNaymsLtdBP;
    uint16 tradingComissionNDFBP;
    uint16 tradingComissionSTMBP;
    uint16 tradingComissionMakerBP;
    // Premium Commissions
    uint16 premiumComissionNaymsLtdBP;
    uint16 premiumComissionNDFBP;
    uint16 premiumComissionSTMBP;
    // A policy can pay out additional comissions on premiums to entities having a variety of roles on the policy

    mapping(bytes32 => mapping(bytes32 => uint256)) marketLockedBalances; // to keep track of an owner's tokens that are on sale in the marketplace, ownerId => lockedTokenId => amount
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier assertSysAdmin() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)),
            "not a system admin"
        );
        _;
    }

    modifier assertSysMgr() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)),
            "not a system manager"
        );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "not the entity's admin"
        );
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check if the id has been used (has a parent account associated with it) and revert if it has
        require(!s.existingObjects[_objectId], "object already exists");
        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");
        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");
        s.existingObjects[_objectId] = true;
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.objectParent[_objectId] = _parentId;
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenSymbol[_objectId] != LibAdmin._getEmptyId());
    }

    function _enableObjectTokenization(bytes32 _objectId, string memory _symbol) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bytes(_symbol).length < 16, "symbol more than 16 characters");
        require(s.objectTokenSymbol[_objectId] == LibAdmin._getEmptyId(), "object already tokenized");

        s.objectTokenSymbol[_objectId] = LibHelpers._stringToBytes32(_symbol);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, LibAdmin, LibConstants, LibHelpers } from "../AppStorage.sol";

library LibTokenizedVault {
    /**
     * @dev Emitted when a token balance gets updated.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param newAmountOwned new amount owned
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenBalanceUpdate(bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address msgSender);

    /**
     * @dev Emitted when a token supply gets updated.
     * @param tokenId ID of token
     * @param newTokenSupply New token supply
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenSupplyUpdate(bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address msgSender);

    function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenBalances[_tokenId][_ownerId];
    }

    function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenSupply[_objectId];
    }

    function _internalTransfer(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalTransferFrom: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalTransferFrom: must own the funds");
        }
        _withdrawAllDividends(_from, _tokenId);
        s.tokenBalances[_tokenId][_from] -= _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalTransferFrom", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalTransferFrom", msg.sender);

        success = true;
    }

    function _internalMint(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        require(_to != "", "MultiToken: mint to zero address");
        require(_amount > 0, "MultiToken: mint zero tokens");

        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 supply = _internalTokenSupply(_tokenId);

        // This must be done BEFORE the supply increases!!!
        // This will calcualte the hypothetical dividends that would correspond to this number of shares.
        // It must be added to the withdrawn dividend for every denomination for the user who receives the minted tokens
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];
        bytes32 dividendDenominationId;

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];

            (, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend);
            s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to] += dividendDeduction;
        }

        // Now you can bump the token supply and the balance for the user
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        s.tokenSupply[_tokenId] += _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalMint", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalMint", msg.sender);
    }

    function _internalBurn(
        bytes32 _from,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalBurn: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalBurn: must own the funds");
        }

        _withdrawAllDividends(_from, _tokenId);
        s.tokenSupply[_tokenId] -= _amount;
        s.tokenBalances[_tokenId][_from] -= _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalBurn", msg.sender);
        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalBurn", msg.sender);
    }

    function _withdrawDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];

        uint256 withdrawableDividend;
        uint256 dividendDeduction;
        (withdrawableDividend, dividendDeduction) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend);
        require(withdrawableDividend > 0, "_withdrawDividend: no dividend");

        // Bump the withdrawn dividends for the owner
        s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += dividendDeduction;

        // Move the dividend
        s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
        s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

        emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
        emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
    }

    function _getWithdrawableDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal view returns (uint256 withdrawableDividend_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];

        (withdrawableDividend_, ) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend);
    }

    function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];
        bytes32 dividendDenominationId;

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            dividendDenominationId = dividendDenominations[i];
            _withdrawDividend(_ownerId, _tokenId, dividendDenominationId);
        }
    }

    function _payDividend(
        bytes32 _from,
        bytes32 _to,
        bytes32 _dividendTokenId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "dividend amount must be > 0");
        require(LibAdmin._isSupportedExternalToken(_dividendTokenId), "must be supported dividend token");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // If no tokens are issued, then deposit directly.
        if (_internalTokenSupply(_to) == 0) {
            _internalTransfer(_from, _to, _dividendTokenId, _amount);
        }
        // Otherwise pay as dividend
        else {
            // issue dividend. if you are owed dividends on the _dividendTokenId, they will be collected
            // Check for possible infinite loop, but probably not
            _internalTransfer(_from, dividendBankId, _dividendTokenId, _amount);
            s.totalDividends[_to][_dividendTokenId] += _amount;

            // keep track of the dividend denominations
            // if dividend has not yet been issued in this token, add it to the list and update mappings
            if (s.dividendDenominationIndex[_to][_dividendTokenId] == 0) {
                // We must limit the number of different tokens dividends are paid in
                if (s.dividendDenominations[_to].length > LibAdmin._getMaxDividendDenominations()) {
                    revert("exceeds max div denominations");
                }

                s.dividendDenominationIndex[_to][_dividendTokenId] = uint8(s.dividendDenominations[_to].length);
                s.dividendDenominationAtIndex[_to][uint8(s.dividendDenominations[_to].length)] = _dividendTokenId;
                s.dividendDenominations[_to].push(_dividendTokenId);
            }
        }
        // Events are emitted from the _internalTransfer()
    }

    function _getTokenSymbol(bytes32 _objectId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibHelpers._bytes32ToString(s.objectTokenSymbol[_objectId]);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend
    ) internal pure returns (uint256 _withdrawableDividend, uint256 _dividendDeduction) {
        // The dividend that can be withdrawn is: withdrawableDividend = (totalDividend/tokenSupply) * _amount. The remainer (dust) is lost.
        // To get a smaller remainder we re-arrange to: withdrawableDividend = (totalDividend * _amount) / _supply

        uint256 totalDividendTimesAmount = _totalDividend * _amount;

        _withdrawableDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);
        _dividendDeduction = _withdrawableDividend;

        // If there is a remainder, add 1 to the _dividendDeduction
        if (totalDividendTimesAmount > _withdrawableDividend * _supply) {
            _dividendDeduction += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import { AppStorage, LibAppStorage, LibHelpers } from "../AppStorage.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";

import { LibERC20 } from "../../../ERC20/LibERC20.sol";

/**
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
library LibTokenizedVaultIO {
    event NaymsVaultTokenTransfer(address operator, bytes32 indexed from, bytes32 indexed to, uint256 amount);

    event ExternalDeposit();

    function _externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        LibERC20.transferFrom(_externalTokenAddress, msg.sender, address(this), _amount);

        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        // Funds are transferred to entity
        LibTokenizedVault._internalMint(_receiverId, internalTokenId, _amount);
    }

    function _externalWithdraw(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        // withdraw from the user's entity
        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        // burn internal token
        LibTokenizedVault._internalBurn(_entityId, internalTokenId, _amount);

        // transfer AFTER burn
        LibERC20.transfer(address(_externalTokenAddress), _receiver, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

// should add to 100% (1000)
struct FeeTotal {
    uint8 tradingComissionNaymsLtdBP;
    uint8 tradingComissionNDFBP;
    uint8 tradingComissionSTMBP;
    uint8 tradingComissionMakerBP;
}

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    // uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

struct MultiToken {
    string tokenUri;
    // kp NOTE todo: what is this struct for?
    mapping(uint256 => mapping(bytes32 => uint256)) tokenBalances; // token ID to account balance
    mapping(bytes32 => mapping(bytes32 => bool)) tokenOpApprovals; // account to operator approvals
}

struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapital;
    uint256 totalLimit;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    uint256 state;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    uint256[] premiums;
    uint256[] premiumDueDates;
    bytes32[] commissionReceivers;
    uint256[] comissionBasisPoints;
    uint256 sponsorComissionBasisPoints; //underwriter is  parent
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

struct OfferState {
    address creator;
    address sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    address buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

// todo where's the most optimal place to put this struct that passes into initialization()?
struct Args {
    bytes32 systemContext;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";

library LibAdmin {
    event BalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event EquilibriumLevelUpdated(uint256 oldLevel, uint256 newLevel);
    event MaxDiscountUpdated(uint256 oldDiscount, uint256 newDiscount);
    event TargetNaymsAllocationUpdated(uint256 oldTarget, uint256 newTarget);
    event DiscountTokenUpdated(address oldToken, address newToken);
    event PoolFeeUpdated(uint256 oldFee, uint256 newFee);
    event CoefficientUpdated(uint256 oldCoefficient, uint256 newCoefficient);
    event RoleGroupUpdated(string role, string group, bool roleInGroup, uint256 index);
    event RoleCanAssignUpdated(string role, string group, uint256 index);

    function initSystem() internal {
        _initReserveObjectIds();
        // TODO Ted have a look
        //Init all reserved IDs from constants
        //Init supported tokens by calling _addSupportedTokens() with supported tokens array from deployment
    }

    function _reserveObject(bytes32 objectId) internal {}

    function _initReserveObjectIds() internal {
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER));
    }

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        s.maxDividendDenominations = _newMaxDividendDenominations;
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _setEquilibriumLevel(uint256 _newLevel) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldLevel = s.equilibriumLevel;
        s.equilibriumLevel = _newLevel;

        emit EquilibriumLevelUpdated(oldLevel, _newLevel);
    }

    function _setMaxDiscount(uint256 _newDiscount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldDiscount = s.maxDiscount;
        s.maxDiscount = _newDiscount;

        emit MaxDiscountUpdated(oldDiscount, _newDiscount);
    }

    function _setTargetNaymsAllocation(uint256 _newTarget) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldTarget = s.targetNaymsAllocation;
        s.targetNaymsAllocation = _newTarget;

        emit TargetNaymsAllocationUpdated(oldTarget, _newTarget);
    }

    function _setDiscountToken(address _newToken) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldToken = s.discountToken;
        s.discountToken = _newToken;

        emit DiscountTokenUpdated(oldToken, _newToken);
    }

    function _setPoolFee(uint24 _newFee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldFee = s.poolFee;
        s.poolFee = _newFee;

        emit PoolFeeUpdated(oldFee, _newFee);
    }

    function _setCoefficient(uint256 _newCoefficient) internal {
        require(_newCoefficient <= 1000, "Coefficient too high");
        require(_newCoefficient >= 0, "Coefficient too low");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 oldCoefficient = s.rewardsCoefficient;

        s.rewardsCoefficient = _newCoefficient;

        emit CoefficientUpdated(oldCoefficient, s.rewardsCoefficient);
    }
    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        s.canAssignConfigUpdateIndex++;
        emit RoleCanAssignUpdated(_role, _assignerGroup, s.canAssignConfigUpdateIndex);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        s.groupsConfigUpdateIndex++;
        emit RoleGroupUpdated(_role, _group, _roleInGroup, s.groupsConfigUpdateIndex);
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bool alreadyAdded;
        s.externalTokenSupported[_tokenAddress] = true;
        // Supported tokens cannot be removed because they may exist in the system!
        for (uint256 i = 0; i < s.supportedExternalTokens.length; i++) {
            if (s.supportedExternalTokens[i] == _tokenAddress) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            LibObject._createObject(LibHelpers._getIdForAddress(_tokenAddress));
            s.supportedExternalTokens.push(_tokenAddress);
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import { LibHelpers } from "./LibHelpers.sol";

/**
 * @dev Settings keys.
 */
library LibConstants {
    //Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant MARKET_IDENTIFIER = "Market";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";
    // These should go directly to the receivers
    string internal constant FEE_BANK_IDENTIFIER = "Deprecated!!!";
    string internal constant BROKER_FEE_BANK_IDENTIFIER = "Also Deprecated!!!";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_APPROVED_USER = "Approved User";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";

    //Groups
    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 internal constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 internal constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

/// @notice Pure functions
library LibHelpers {
    function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index));
    }

    function _getIdForAddress(address _addr) internal pure returns (bytes32) {
        return bytes32(bytes20(_addr));
    }

    function _getSenderId() internal view returns (bytes32) {
        return _getIdForAddress(msg.sender);
    }

    function _getNaymsVaultTokenIdForAddress(address _addr) internal pure returns (bytes32) {
        uint256 naymsVaultTokenId = uint256(uint160(_addr)) << 1;
        return bytes32(naymsVaultTokenId);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32 result) {
        return _bytesToBytes32(bytes(strIn));
    }

    function _bytes32ToString(bytes32 bytesIn) internal pure returns (string memory) {
        return string(_bytes32ToBytes(bytesIn));
    }

    function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), input)
        }
        return b;
    }

    function _strEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return (keccak256(abi.encode(s1)) == keccak256(abi.encode(s2)));
    }

    function isZeroAddress(bytes32 accountId) internal pure returns (bool) {
        return _getAddressFromId(accountId) == address(0);
    }

    function _asSingletonArray(bytes32 element) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](1);
        array[0] = element;
        return array;
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

import { AppStorage, LibAppStorage, Modifiers } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param roleId The ID of the role which got unassigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     * @param txOrigin tx.origin
     * @param msgSender msg.sender
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 roleId, string functionName, address txOrigin, address msgSender);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.roles[_objectId][_contextId] = _roleId;
        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole", tx.origin, msg.sender);
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole", tx.origin, msg.sender);
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /// Can a user (or object) assign a role in a given context
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");
        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 assignerGroup = s.canAssign[_roleId];

        // Check for group membership in the given context
        if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
                ret = true;
            }
        }
        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import { IERC20 } from "./IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}