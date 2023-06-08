// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./challenge/Challenge.sol";
import "./challenge/ChallengeLib.sol";
import "./AssertionMap.sol";
import "./IRollup.sol";
import "./RollupLib.sol";
import "./WhiteList.sol";
import "./verifier/IVerifier.sol";
import {Lib_AddressResolver} from "../../libraries/resolver/Lib_AddressResolver.sol";
import {Lib_AddressManager} from "../../libraries/resolver/Lib_AddressManager.sol";
import {Lib_BVMCodec} from "../../libraries/codec/Lib_BVMCodec.sol";


abstract contract RollupBase is IRollup, Initializable {
    // Config parameters
    uint256 public minimumAssertionPeriod; // number of L1 blocks
    uint256 public baseStakeAmount; // number of stake tokens

    IERC20 public stakeToken;
    AssertionMap public override assertions;
    IVerifierEntry public verifier;

    // slot place hold
    uint256[50] rollupBaseGap;

    struct Staker {
        bool isStaked;
        uint256 amountStaked;
        uint256 assertionID; // latest staked assertion ID
        address operator; // operator
        address currentChallenge; // address(0) if none
    }

    struct Zombie {
        address stakerAddress;
        uint256 lastAssertionID;
    }

    struct ChallengeCtx {
        bool completed;
        address challengeAddress;
        address defenderAddress;
        address challengerAddress;
        uint256 defenderAssertionID;
        uint256 challengerAssertionID;
    }
}

contract Rollup is Lib_AddressResolver, RollupBase, Whitelist {
    modifier stakedOnly() {
        if (!isStaked(msg.sender)) {
            revert("NotStaked");
        }
        _;
    }

    modifier operatorOnly() {
        if (registers[msg.sender] == address(0)) {
            revert("NotOperator");
        }
        _;
    }

    // Assertion state
    uint256 public lastResolvedAssertionID;
    uint256 public lastConfirmedAssertionID;
    uint256 public lastCreatedAssertionID;

    // Staking state
    uint256 public numStakers; // current total number of stakers
    mapping(address => Staker) public stakers; // mapping from staker addresses to corresponding stakers
    mapping(address => address) public registers; // register info for operator => staker
    mapping(address => uint256) public withdrawableFunds; // mapping from addresses to withdrawable funds (won in challenge)
    Zombie[] public zombies; // stores stakers that lost a challenge
    ChallengeCtx public challengeCtx;  // stores challenge context

    constructor() Lib_AddressResolver(address(0)) {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _verifier,
        address _stakeToken,
        address _libAddressManager,
        address _assertionMap,
        uint256 _minimumAssertionPeriod,
        uint256 _baseStakeAmount,
        bytes32 _initialVMhash,
        address[] calldata stakerWhitelists,
        address[] calldata operatorWhitelists
    ) public initializer {
        if (_owner == address(0) || _verifier == address(0)) {
            revert("ZeroAddress");
        }
        owner = _owner;
        stakeToken = IERC20(_stakeToken);
        verifier = IVerifierEntry(_verifier);

        if (address(libAddressManager) != address(0)) {
            revert("RedundantInitialized");
        }
        libAddressManager = Lib_AddressManager(_libAddressManager);

        if (address(assertions) != address(0)) {
            revert("RedundantInitialized");
        }
        assertions = AssertionMap(_assertionMap);

        minimumAssertionPeriod = _minimumAssertionPeriod;
        baseStakeAmount = _baseStakeAmount;

        assertions.setRollupAddress(address(this));
        lastResolvedAssertionID = 0;
        lastConfirmedAssertionID = 0;
        lastCreatedAssertionID = 0;

        assertions.createAssertion(
            lastResolvedAssertionID, // assertionID
            _initialVMhash,
            0, // inboxSize (genesis)
            0, // parentID
            block.number // deadline (unchallengeable)
        );

        addToStakerWhitelist(stakerWhitelists);
        addToOperatorWhitelist(operatorWhitelists);
    }

    /// @inheritdoc IRollup
    function isStaked(address addr) public view override returns (bool) {
        return stakers[addr].isStaked;
    }

    /// @inheritdoc IRollup
    function currentRequiredStake() public view override returns (uint256) {
        return baseStakeAmount;
    }

    /// @inheritdoc IRollup
    function confirmedInboxSize() public view override returns (uint256) {
        return assertions.getInboxSize(lastConfirmedAssertionID);
    }

    /// @inheritdoc IRollup
    function stake(uint256 stakeAmount, address operator) external override
        stakerWhitelistOnly(msg.sender)
        operatorWhitelistOnly(operator)
    {
        // send erc20 token to staking contract, need user approve first
        require(
            IERC20(stakeToken).transferFrom(msg.sender, address(this), stakeAmount),
            "transfer erc20 token failed"
        );

        if (isStaked(msg.sender)) {
            require(
            stakers[msg.sender].operator == operator,
                "staker => operator mapping not unique"
            );
            stakers[msg.sender].amountStaked += stakeAmount;
        } else {
            require(registers[operator] == address(0), "operator is occupied");

            if (stakeAmount < baseStakeAmount) {
                revert("InsufficientStake");
            }

            stakers[msg.sender] = Staker(true, stakeAmount, 0, operator, address(0));
            registers[operator] = msg.sender;
            numStakers++;
            stakeOnAssertion(msg.sender, lastConfirmedAssertionID);
        }
    }

    /// @inheritdoc IRollup
    function unstake(uint256 stakeAmount) external override {
        requireStaked(msg.sender);
        // Require that staker is staked on a confirmed assertion.
        Staker storage staker = stakers[msg.sender];
        if (staker.assertionID > lastConfirmedAssertionID) {
            revert("StakedOnUnconfirmedAssertion");
        }
        if (stakeAmount > staker.amountStaked - currentRequiredStake()) {
            revert("InsufficientStake");
        }
        staker.amountStaked -= stakeAmount;
        // send erc20 token to user
        require(
            IERC20(stakeToken).transfer(msg.sender, stakeAmount),
            "transfer erc20 token failed"
        );
    }

    /// @inheritdoc IRollup
    function removeStake(address stakerAddress) onlyOwner external override {
        requireStaked(stakerAddress);
        // Require that staker is staked on a confirmed assertion.
        Staker storage staker = stakers[stakerAddress];
        if (staker.assertionID > lastConfirmedAssertionID) {
            revert("StakedOnUnconfirmedAssertion");
        }
        uint256 amountToSent = staker.amountStaked;
        deleteStaker(stakerAddress);
        // send erc20 token to user
        require(
            IERC20(stakeToken).transfer(stakerAddress, amountToSent),
            "transfer erc20 token failed"
        );
    }

    /// @inheritdoc IRollup
    function advanceStake(uint256 assertionID) external override operatorOnly {
        address stakerAddr = registers[msg.sender];
        Staker storage staker = stakers[stakerAddr];
        if (assertionID <= staker.assertionID || assertionID > lastCreatedAssertionID) {
            revert("AssertionOutOfRange");
        }
        // TODO: allow arbitrary descendant of current staked assertionID, not just child.
        if (staker.assertionID != assertions.getParentID(assertionID)) {
            revert("ParentAssertionUnstaked");
        }
        stakeOnAssertion(stakerAddr, assertionID);
    }

    /// @inheritdoc IRollup
    function withdraw() external override operatorOnly {
        uint256 withdrawableFund = withdrawableFunds[msg.sender];
        withdrawableFunds[msg.sender] = 0;
        require(
            IERC20(stakeToken).transfer(msg.sender, withdrawableFund),
            "transfer erc20 token failed"
        );
    }

    /// @inheritdoc IRollup
    function createAssertion(
        bytes32 vmHash,
        uint256 inboxSize
    ) public override operatorOnly {
        address stakerAddr = registers[msg.sender];
        require(stakers[stakerAddr].currentChallenge == address(0),"can not create assertion when staker in challenge");
        uint256 parentID = stakers[stakerAddr].assertionID;
        // Require that enough time has passed since the last assertion.
        if (block.number - assertions.getProposalTime(parentID) < minimumAssertionPeriod) {
            revert("MinimumAssertionPeriodNotPassed");
        }
        // Require that the assertion at least includes one transaction
        if (inboxSize <= assertions.getInboxSize(parentID)) {
            revert("EmptyAssertion");
        }

        // Initialize assertion.
        lastCreatedAssertionID++;
        emit AssertionCreated(lastCreatedAssertionID, msg.sender, vmHash, inboxSize);
        assertions.createAssertion(
            lastCreatedAssertionID, vmHash, inboxSize, parentID, newAssertionDeadline()
        );

        // Update stake.
        stakeOnAssertion(stakerAddr, lastCreatedAssertionID);
        // confirmed this assertion instantly
        lastResolvedAssertionID++;
        lastConfirmedAssertionID = lastResolvedAssertionID;
        emit AssertionConfirmed(lastResolvedAssertionID);
    }

    /// @inheritdoc IRollup
    function createAssertionWithStateBatch(
        bytes32 vmHash,
        uint256 inboxSize,
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement,
        bytes calldata _signature
        ) external override operatorOnly {
        // permissions only allow rollup proposer to submit assertion, only allow RollupContract to append new batch
        require(msg.sender == resolve("BVM_Rolluper"), "msg.sender is not rollup proposer, can't append batch");
        // create assertion
        createAssertion(vmHash, inboxSize);
        // append state batch
        address scc = resolve("StateCommitmentChain");
        (bool success, ) = scc.call(
            abi.encodeWithSignature("appendStateBatch(bytes32[],uint256,bytes)", _batch, _shouldStartAtElement, _signature)
        );
        require(success, "scc append state batch failed, revert all");
    }

    function challengeAssertion(address[2] calldata players, uint256[2] calldata assertionIDs)
        external
        override
        operatorOnly
        returns (address)
    {
        uint256 defenderAssertionID = assertionIDs[0];
        uint256 challengerAssertionID = assertionIDs[1];
        // Require IDs ordered and in-range.
        if (defenderAssertionID >= challengerAssertionID) {
            revert("WrongOrder");
        }
        if (challengerAssertionID > lastCreatedAssertionID) {
            revert("UnproposedAssertion");
        }
        if (lastConfirmedAssertionID >= defenderAssertionID) {
            revert("AssertionAlreadyResolved");
        }
        // Require that players have attested to sibling assertions.
        uint256 parentID = assertions.getParentID(defenderAssertionID);
        if (parentID != assertions.getParentID(challengerAssertionID)) {
            revert("DifferentParent");
        }
        // Require that neither player is currently engaged in a challenge.
        address defender = players[0];
        address challenger = players[1];
        require(defender != challenger, "defender and challenge must not equal");
        address defenderStaker = registers[defender];
        address challengerStaker = registers[challenger];
        requireUnchallengedStaker(defenderStaker);
        requireUnchallengedStaker(challengerStaker);

        // TODO: Calculate upper limit for allowed node proposal time.

        // Initialize challenge.
        Challenge challenge = new Challenge();
        address challengeAddr = address(challenge);
        stakers[challenger].currentChallenge = challengeAddr;
        stakers[defender].currentChallenge = challengeAddr;

        challengeCtx = ChallengeCtx(false,challengeAddr,defender,challenger,defenderAssertionID,challengerAssertionID);
        emit AssertionChallenged(defenderAssertionID, challengeAddr);
        uint256 inboxSize = assertions.getInboxSize(parentID);
        bytes32 parentStateHash = assertions.getStateHash(parentID);
        bytes32 defenderStateHash = assertions.getStateHash(defenderAssertionID);
        challenge.initialize(
            defender,
            challenger,
            verifier,
            address(this),
            inboxSize,
            parentStateHash,
            defenderStateHash
        );
        return challengeAddr;
    }

    /// @inheritdoc IRollup
    function confirmFirstUnresolvedAssertion() public override operatorOnly {
        if (lastResolvedAssertionID >= lastCreatedAssertionID) {
            revert("NoUnresolvedAssertion");
        }

        // (1) there is at least one staker, and
        if (numStakers <= 0) revert("NoStaker");

        uint256 lastUnresolvedID = lastResolvedAssertionID + 1;

        // (2) challenge period has passed
        if (block.timestamp < assertions.getDeadline(lastUnresolvedID)) {
            revert("ChallengePeriodPending");
        }

        // (3) predecessor has been confirmed
        if (assertions.getParentID(lastUnresolvedID) != lastConfirmedAssertionID) {
            revert("InvalidParent");
        }

        // Remove old zombies
        // removeOldZombies();

        // (4) all stakers are staked on the block.
        // if (assertions.getNumStakers(lastUnresolvedID) != numStakers) {
        //    revert("NotAllStaked");
        // }

        // there is no slashing mechanism currently,
        // we can not handle offline staker if we sum up zombies and numStakers,
        // in which case a offline validator can block confirmation progress.
        // if (assertions.getNumStakers(lastUnresolvedID) != countStakedZombies(lastUnresolvedID) + numStakers) {
        //    revert NotAllStaked();
        // }

        // Confirm assertion.
        // assertions.deleteAssertion(lastConfirmedAssertionID);
        lastResolvedAssertionID++;
        lastConfirmedAssertionID = lastResolvedAssertionID;
        emit AssertionConfirmed(lastResolvedAssertionID);
    }

    /// @inheritdoc IRollup
    function rejectFirstUnresolvedAssertion() external override operatorOnly {
        if (lastResolvedAssertionID >= lastCreatedAssertionID) {
            revert("NoUnresolvedAssertion");
        }

        uint256 firstUnresolvedAssertionID = lastResolvedAssertionID + 1;

        // First case - parent of first unresolved is last confirmed (`if` condition below). e.g.
        // [1] <- [3]           | valid chain ([1] is last confirmed, [3] is stakerAddress's unresolved assertion)
        //  ^---- [2]           | invalid chain ([2] is firstUnresolved)
        // Second case (trivial) - parent of first unresolved is not last confirmed. i.e.:
        //   parent is previous rejected, e.g.
        //   [1] <- [4]           | valid chain ([1] is last confirmed, [4] is stakerAddress's unresolved assertion)
        //   [2] <- [3]           | invalid chain ([3] is firstUnresolved)
        //   OR
        //   parent is previous confirmed, e.g.
        //   [1] <- [2] <- [4]    | valid chain ([2] is last confirmed, [4] is stakerAddress's unresolved assertion)
        //    ^---- [3]           | invalid chain ([3] is firstUnresolved)
        if (assertions.getParentID(firstUnresolvedAssertionID) == lastConfirmedAssertionID) {
            // 1a. challenge period has passed.
            if (block.timestamp < assertions.getDeadline(firstUnresolvedAssertionID)) {
                revert("ChallengePeriodPending");
            }
            // 1b. at least one staker exists (on a sibling)
            // - stakerAddress is indeed a staker
            // requireStaked(stakerAddress);
            // - staker's assertion can't be a ancestor of firstUnresolved (because staker's assertion is also unresolved)
            // if (stakers[stakerAddress].assertionID < firstUnresolvedAssertionID) {
            //    revert("AssertionAlreadyResolved");
            // }
            // - staker's assertion can't be a descendant of firstUnresolved (because staker has never staked on firstUnresolved)
            // if (assertions.isStaker(firstUnresolvedAssertionID, stakerAddress)) {
            //    revert("StakerStakedOnTarget");
            // }
            // If a staker is staked on an assertion that is neither an ancestor nor a descendant of firstUnresolved, it must be a sibling, QED

            // 1c. no staker is staked on this assertion
            // removeOldZombies();
            if (assertions.getNumStakers(firstUnresolvedAssertionID) != countStakedZombies(firstUnresolvedAssertionID))
            {
                revert("StakersPresent");
            }
        }

        // Reject assertion.
        lastResolvedAssertionID++;
        emit AssertionRejected(lastResolvedAssertionID);
        assertions.deleteAssertion(lastResolvedAssertionID);
    }

/// @inheritdoc IRollup
    function rejectLatestCreatedAssertionWithBatch(Lib_BVMCodec.ChainBatchHeader memory _batchHeader) external override onlyOwner {
        address scc = resolve("StateCommitmentChain");

        // batch shift
        (, bytes memory data) = scc.call(
            abi.encodeWithSignature("getTotalBatches()")
        );
        uint256 totalBatches = uint256(bytes32(data));
        require(totalBatches-_batchHeader.batchIndex == 1, "delete batch with gap is not allowed");

        // Delete state batch
        (bool success, ) = scc.call(
            abi.encodeWithSignature("deleteStateBatch((uint256,bytes32,uint256,uint256,bytes,bytes))", _batchHeader)
        );
        require(success, "scc delete state batch failed, revert all");

        // Reject assertion.
        require(lastCreatedAssertionID >= lastResolvedAssertionID, "delete assertion before last resolved in error");
        emit AssertionRejected(lastCreatedAssertionID);
        assertions.deleteAssertionForBatch(lastCreatedAssertionID);
        lastCreatedAssertionID--;
        lastResolvedAssertionID--;
        lastConfirmedAssertionID--;

        // Revert status
        for (uint i = 0; i < stakerslist.length; i++) {
            if (stakers[stakerslist[i]].assertionID > lastCreatedAssertionID) {
                stakers[stakerslist[i]].assertionID = lastCreatedAssertionID;
            }
        }
    }

    /// @inheritdoc IRollup
    function completeChallenge(address winner, address loser) external override operatorOnly {
        address winnerStaker = registers[winner];
        address loserStaker = registers[loser];
        requireStaked(loserStaker);

        address challenge = getChallenge(winnerStaker, loserStaker);
        if (msg.sender != challenge) {
            revert("NotChallenge");
        }
        uint256 amountWon;
        uint256 loserStake = stakers[loserStaker].amountStaked;
        // uint256 winnerStake = stakers[winnerStaker].amountStaked;
        if (loserStake > baseStakeAmount) {
            // If loser has a higher stake than the base stake amount, refund the difference.
            // Loser gets deleted anyways, so maybe unnecessary to set amountStaked.
            // stakers[loser].amountStaked = winnerStake;
            withdrawableFunds[loserStaker] += (loserStake - baseStakeAmount);
            amountWon = baseStakeAmount;
        } else {
            amountWon = loserStake;
        }
        // Reward the winner with winner amount
        stakers[winnerStaker].amountStaked += amountWon; // why +stake instead of +withdrawable?
        stakers[winnerStaker].currentChallenge = address(0);
        // Turning loser into zombie renders the loser's remaining stake inaccessible.
        uint256 assertionID = stakers[loserStaker].assertionID;
        deleteStaker(loserStaker);
        // Track as zombie so we can account for it during assertion resolution.
        zombies.push(Zombie(loserStaker, assertionID));
        challengeCtx.completed = true;
    }

    /**
     * @notice Updates staker and assertion metadata.
     * @param stakerAddress Address of existing staker.
     * @param assertionID ID of existing assertion to stake on.
     */
    function stakeOnAssertion(address stakerAddress, uint256 assertionID) private {
        stakers[stakerAddress].assertionID = assertionID;
        assertions.stakeOnAssertion(assertionID, stakerAddress);
        emit StakerStaked(stakerAddress, assertionID);
    }

    /**
     * @notice Deletes the staker from global state. Does not touch assertion staker state.
     * @param stakerAddress Address of the staker to delete
     */
    function deleteStaker(address stakerAddress) private {
        numStakers--;
        address operator = stakers[stakerAddress].operator;
        delete stakers[stakerAddress];
        delete registers[operator];
    }

    /**
     * @notice Checks to see whether the two stakers are in the same challenge
     * @param staker1Address Address of the first staker
     * @param staker2Address Address of the second staker
     * @return Address of the challenge that the two stakers are in
     */
    function getChallenge(address staker1Address, address staker2Address) private view returns (address) {
        Staker storage staker1 = stakers[staker1Address];
        Staker storage staker2 = stakers[staker2Address];
        address challenge = staker1.currentChallenge;
        if (challenge == address(0)) {
            revert("NotInChallenge");
        }
        if (challenge != staker2.currentChallenge) {
            revert("InDifferentChallenge");
        }
        return challenge;
    }

    function newAssertionDeadline() private returns (uint256) {
        // TODO: account for prev assertion, gas
        // return block.number + confirmationPeriod;
        address scc = resolve("StateCommitmentChain");
        (bool success, bytes memory data) = scc.call(
            abi.encodeWithSignature("FRAUD_PROOF_WINDOW()")
        );
        require(success,"call FRAUD_PROOF_WINDOW() failed");
        uint256 confirmationWindow = uint256(bytes32(data));
        return block.timestamp + confirmationWindow;
    }

    // *****************
    // zombie processing
    // *****************

    function removeOldZombies() external operatorOnly {
        delete zombies;
    }
    /**
     * @notice Removes any zombies whose latest stake is earlier than the first unresolved assertion.
     * @dev Uses pop() instead of delete to prevent gaps, although order is not preserved
     */
    // function removeOldZombies() private {
    // }

    /**
     * @notice Counts the number of zombies staked on an assertion.
     * @dev O(n), where n is # of zombies (but is expected to be small).
     * This function could be uncallable if there are too many zombies. However,
     * removeOldZombies() can be used to remove any zombies that exist so that this
     * will then be callable.
     * @param assertionID The assertion on which to count staked zombies
     * @return The number of zombies staked on the assertion
     */
    function countStakedZombies(uint256 assertionID) private view returns (uint256) {
        uint256 numStakedZombies = 0;
        for (uint256 i = 0; i < zombies.length; i++) {
            if (assertions.isStaker(assertionID, zombies[i].stakerAddress)) {
                numStakedZombies++;
            }
        }
        return numStakedZombies;
    }

    // ************
    // requirements
    // ************

    function requireStaked(address stakerAddress) private view {
        if (!isStaked(stakerAddress)) {
            revert("NotStaked");
        }
    }

    function requireUnchallengedStaker(address stakerAddress) private view {
        requireStaked(stakerAddress);
        if (stakers[stakerAddress].currentChallenge != address(0)) {
            revert("ChallengedStaker");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/Errors.sol";

// Exists only to reduce size of Rollup contract (maybe revert since Rollup fits under optimized compilation).
contract AssertionMap is Initializable {
    error ChildInboxSizeMismatch();

    error SiblingStateHashExists();

    struct Assertion {
        bytes32 stateHash; // Hash of execution state associated with assertion (see `RollupLib.stateHash`)
        uint256 inboxSize; // Inbox size this assertion advanced to
        uint256 parent; // Parent assertion ID
        uint256 deadline; // Confirmation deadline (L1 block timestamp)
        uint256 proposalTime; // L1 block number at which assertion was proposed
        // Staking state
        uint256 numStakers; // total number of stakers that have ever staked on this assertion. increasing only.
        // Child state
        uint256 childInboxSize; // child assertion inbox state
    }

    struct AssertionState {
        mapping(address => bool) stakers; // all stakers that have ever staked on this assertion.
        mapping(bytes32 => bool) childStateHashes; // child assertion vm hashes
    }

    mapping(uint256 => Assertion) public assertions;
    mapping(uint256 => AssertionState) private assertionStates; // mapping from assertionID to assertion state
    address public rollupAddress;

    modifier rollupOnly() {
        if (msg.sender != rollupAddress) {
            revert NotRollup(msg.sender, rollupAddress);
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    function setRollupAddress(address _rollupAddress) public {
        require(
            address(rollupAddress) == address(0),
            "rollupAddress already initialized."
        );
        require(_rollupAddress != address(0), "ZERO_ADDRESS");
        rollupAddress = _rollupAddress;
    }

    function getStateHash(uint256 assertionID) external view returns (bytes32) {
        return assertions[assertionID].stateHash;
    }

    function getInboxSize(uint256 assertionID) external view returns (uint256) {
        return assertions[assertionID].inboxSize;
    }

    function getParentID(uint256 assertionID) external view returns (uint256) {
        return assertions[assertionID].parent;
    }

    function getDeadline(uint256 assertionID) external view returns (uint256) {
        return assertions[assertionID].deadline;
    }

    function getProposalTime(uint256 assertionID) external view returns (uint256) {
        return assertions[assertionID].proposalTime;
    }

    function getNumStakers(uint256 assertionID) external view returns (uint256) {
        return assertions[assertionID].numStakers;
    }

    function isStaker(uint256 assertionID, address stakerAddress) external view returns (bool) {
        return assertionStates[assertionID].stakers[stakerAddress];
    }

    function createAssertion(
        uint256 assertionID,
        bytes32 stateHash,
        uint256 inboxSize,
        uint256 parentID,
        uint256 deadline
    ) external rollupOnly {
        Assertion storage parentAssertion = assertions[parentID];
        AssertionState storage parentAssertionState = assertionStates[parentID];
        // Child assertions must have same inbox size
        uint256 parentChildInboxSize = parentAssertion.childInboxSize;
        if (parentChildInboxSize == 0) {
            parentAssertion.childInboxSize = inboxSize;
        } else {
            if (inboxSize != parentChildInboxSize) {
                revert("ChildInboxSizeMismatch");
            }
        }
        if (parentAssertionState.childStateHashes[stateHash]) {
            revert("SiblingStateHashExists");
        }

        parentAssertionState.childStateHashes[stateHash] = true;

        assertions[assertionID] = Assertion(
            stateHash,
            inboxSize,
            parentID,
            deadline,
            block.number, // proposal time
            0, // numStakers
            0 // childInboxSize
        );
    }

    function stakeOnAssertion(uint256 assertionID, address stakerAddress) external rollupOnly {
        Assertion storage assertion = assertions[assertionID];
        assertionStates[assertionID].stakers[stakerAddress] = true;
        assertion.numStakers++;
    }

    function deleteAssertion(uint256 assertionID) external rollupOnly {
        delete assertions[assertionID];
    }

    function deleteAssertionForBatch(uint256 assertionID) external rollupOnly {
        bytes32 stateHash = assertions[assertionID].stateHash;
        uint256 parentID = assertions[assertionID].parent;
        delete assertions[assertionID];
        assertions[parentID].childInboxSize = 0;
        assertionStates[parentID].childStateHashes[stateHash] = false;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./AssertionMap.sol";
import {Lib_BVMCodec} from "../../libraries/codec/Lib_BVMCodec.sol";

interface IRollup {
    event AssertionCreated(
        uint256 assertionID, address asserterAddr, bytes32 vmHash, uint256 inboxSize
    );

    event AssertionChallenged(uint256 assertionID, address challengeAddr);

    event AssertionConfirmed(uint256 assertionID);

    event AssertionRejected(uint256 assertionID);

    event StakerStaked(address stakerAddr, uint256 assertionID);

    /// @dev Thrown when address that have not staked any token calls a only-staked function
    error NotStaked();

    /// @dev Thrown when the function is called with Insufficient Stake
    error InsufficientStake();

    /// @dev Thrown when the caller is staked on unconfirmed assertion.
    error StakedOnUnconfirmedAssertion();

    /// @dev Thrown when transfer fails
    error TransferFailed();

    /// @dev Thrown when a staker tries to advance stake to invalid assertionId.
    error AssertionOutOfRange();

    /// @dev Thrown when a staker tries to advance stake to non-child assertion
    error ParentAssertionUnstaked();

    /// @dev Thrown when a sender tries to create assertion before the minimum assertion time period
    error MinimumAssertionPeriodNotPassed();

    /// @dev Thrown when parent's statehash is not equal to the start state(or previous state)/
    error PreviousStateHash();

    /// @dev Thrown when a sender tries to create assertion without any tx.
    error EmptyAssertion();

    /// @dev Thrown when the requested assertion read past the end of current Inbox.
    error InboxReadLimitExceeded();

    /// @dev Thrown when the challenge assertion Id is not ordered or in range.
    error WrongOrder();

    /// @dev Thrown when the challenger tries to challenge an unproposed assertion
    error UnproposedAssertion();

    /// @dev Thrown when the assertion is already resolved
    error AssertionAlreadyResolved();

    /// @dev Thrown when there is no unresolved assertion
    error NoUnresolvedAssertion();

    /// @dev Thrown when the challenge period has not passed
    error ChallengePeriodPending();

    /// @dev Thrown when the challenger and defender didn't attest to sibling assertions
    error DifferentParent();

    /// @dev Thrown when the assertion's parent is not the last confirmed assertion
    error InvalidParent();

    /// @dev Thrown when the staker is not in a challenge
    error NotInChallenge();

    /// @dev Thrown when the two stakers are in different challenge
    /// @param staker1Challenge challenge address of staker 1
    /// @param staker2Challenge challenge address of staker 2
    error InDifferentChallenge(address staker1Challenge, address staker2Challenge);

    /// @dev Thrown when the staker is currently in Challenge
    error ChallengedStaker();

    /// @dev Thrown when all the stakers are not staked
    error NotAllStaked();

    /// @dev Thrown staker's assertion is descendant of firstUnresolved assertion
    error StakerStakedOnTarget();

    /// @dev Thrown when there are staker's present on the assertion
    error StakersPresent();

    /// @dev Thrown when there are zero stakers
    error NoStaker();

    /// @dev Thrown when slot is not blank in initialize step
    error RedundantInitialized();

    /// @dev Thrown when function is called with a zero address argument
    error ZeroAddress();

    function assertions() external view returns (AssertionMap);

    /**
     * @param addr User address.
     * @return True if address is staked, else False.
     */
    function isStaked(address addr) external view returns (bool);

    /**
     * @return The current required stake amount.
     */
    function currentRequiredStake() external view returns (uint256);

    /**
     * @return confirmedInboxSize size of inbox confirmed
     */
    function confirmedInboxSize() external view returns (uint256);

    /**
     * @notice Deposits stake on staker's current assertion (or the last confirmed assertion if not currently staked).
     * @notice currently use MNT to stake; stakeAmount Token amount to deposit. Must be > than defined threshold if this is a new stake.
     */
     function stake(uint256 stakeAmount, address operator) external;

    /**
     * @notice Withdraws stakeAmount from staker's stake by if assertion it is staked on is confirmed.
     * @param stakeAmount Token amount to withdraw. Must be <= sender's current stake minus the current required stake.
     */
    function unstake(uint256 stakeAmount) external;

    /**
     * @notice Removes stakerAddress from the set of stakers and withdraws the full stake amount to stakerAddress.
     * This can be called by anyone since it is currently necessary to keep the chain progressing.
     * @param stakerAddress Address of staker for which to unstake.
     */
    function removeStake(address stakerAddress) external;

    /**
     * @notice Advances msg.sender's existing sake to assertionID.
     * @param assertionID ID of assertion to advance stake to. Currently this must be a child of the current assertion.
     * TODO: generalize to arbitrary descendants.
     */
    function advanceStake(uint256 assertionID) external;

    /**
     * @notice Withdraws all of msg.sender's withdrawable funds.
     */
    function withdraw() external;

    /**
     * @notice Creates a new DA representing the rollup state after executing a block of transactions (sequenced in SequencerInbox).
     * Block is represented by all transactions in range [prevInboxSize, inboxSize]. The latest staked DA of the sender
     * is considered to be the predecessor. Moves sender stake onto the new DA.
     *
     * The new DA stores the hash of the parameters: vmHash
     *
     * @param vmHash New VM hash.
     * @param inboxSize Size of inbox corresponding to assertion (number of transactions).
     */
    function createAssertion(
        bytes32 vmHash,
        uint256 inboxSize
    ) external;

    /**
     *
     * @notice create assertion with scc state batch
     *
     * @param vmHash New VM hash.
     * @param inboxSize Size of inbox corresponding to assertion (number of transactions).
     * @param _batch Batch of state roots.
     * @param _shouldStartAtElement Index of the element at which this batch should start.
     * @param _signature tss group signature of state batches.
     */
    function createAssertionWithStateBatch(
        bytes32 vmHash,
        uint256 inboxSize,
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement,
        bytes calldata _signature
    ) external;


    /**
     * @notice Initiates a dispute between a defender and challenger on an unconfirmed DA.
     * @param players Defender (first) and challenger (second) addresses. Must be staked on DAs on different branches.
     * @param assertionIDs Assertion IDs of the players engaged in the challenge. The first ID should be the earlier-created and is the one being challenged.
     * @return Newly created challenge contract address.
     */
    function challengeAssertion(address[2] calldata players, uint256[2] calldata assertionIDs)
        external
        returns (address);

    /**
     * @notice Confirms first unresolved assertion. Assertion is confirmed if and only if:
     * (1) there is at least one staker, and
     * (2) challenge period has passed, and
     * (3) predecessor has been confirmed, and
     * (4) all stakers are staked on the assertion.
     */
    function confirmFirstUnresolvedAssertion() external;

    /**
     * @notice Rejects first unresolved assertion. Assertion is rejected if and only if:
     * (1) all of the following are true:
     * (a) challenge period has passed, and
     * (b) at least one staker exists, and
     * (c) no staker remains staked on the assertion (all have been destroyed).
     * OR
     * (2) predecessor has been rejected
     */
    function rejectFirstUnresolvedAssertion() external;

    //* @param stakerAddress Address of a staker staked on a different branch to the first unresolved assertion.
    //* If the first unresolved assertion's parent is confirmed, this parameter is used to establish that a staker exists
    //* on a different branch of the assertion chain. This parameter is ignored when the parent of the first unresolved
    //* assertion is not the last confirmed assertion.
    function rejectLatestCreatedAssertionWithBatch(Lib_BVMCodec.ChainBatchHeader memory _batchHeader) external;

    /**
     * @notice Completes ongoing challenge. Callback, called by a challenge contract.
     * @param winner Address of winning staker.
     * @param loser Address of losing staker.
     */
    function completeChallenge(address winner, address loser) external;
}

// SPDX-License-Identifier: Apache-2.0

abstract contract Whitelist {
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier stakerWhitelistOnly(address _checkAddress) {
        require(stakerslist[stakerWhitelist[_checkAddress]] == _checkAddress, "NOT_IN_STAKER_WHITELIST");
        _;
    }

    modifier operatorWhitelistOnly(address _checkAddress) {
        require(operatorslist[operatorWhitelist[_checkAddress]] == _checkAddress, "NOT_IN_OPERATOR_WHITELIST");
        _;
    }

    address public owner;
    mapping(address => uint256) public stakerWhitelist;
    address[] public stakerslist;
    mapping(address => uint256) public operatorWhitelist;
    address[] public operatorslist;

    // slot place hold
    uint256[50] whitelistGap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Add to staker whitelist
     */
    function addToStakerWhitelist(address[] calldata toAddAddresses) public onlyOwner {
        uint256 lens = stakerslist.length;
        for (uint i = 0; i < toAddAddresses.length; i++) {
            stakerWhitelist[toAddAddresses[i]] = lens+i;
            stakerslist.push(toAddAddresses[i]);
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromStakerWhitelist(address[] calldata toRemoveAddresses) public onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            uint256 index = stakerWhitelist[toRemoveAddresses[i]];
            stakerWhitelist[stakerslist[stakerslist.length-1]] = index;
            stakerslist[index] = stakerslist[stakerslist.length-1];
            stakerslist.pop();
            delete stakerWhitelist[toRemoveAddresses[i]];
        }
    }

    /**
 * @notice Add to whitelist
     */
    function addToOperatorWhitelist(address[] calldata toAddAddresses) public onlyOwner {
        uint256 lens = operatorslist.length;
        for (uint i = 0; i < toAddAddresses.length; i++) {
            operatorWhitelist[toAddAddresses[i]] = lens+i;
            operatorslist.push(toAddAddresses[i]);
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromOperatorWhitelist(address[] calldata toRemoveAddresses) public onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            uint256 index = operatorWhitelist[toRemoveAddresses[i]];
            operatorWhitelist[operatorslist[operatorslist.length-1]] = index;
            operatorslist[index] = operatorslist[operatorslist.length-1];
            operatorslist.pop();
            delete operatorWhitelist[toRemoveAddresses[i]];
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./challenge/ChallengeLib.sol";

// TODO: move into ChallengeLib.
library RollupLib {
    struct ExecutionState {
        bytes32 vmHash;
    }

    /**
     * @notice Computes the hash of `execState`.
     */
    function stateHash(ExecutionState memory execState) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(execState.vmHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {
    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(address _libAddressManager) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(string memory _name) public view returns (address) {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
    /**********
     * Events *
     **********/

    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    /*************
     * Variables *
     *************/

    mapping(bytes32 => address) private addresses;

    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(_name, _address, oldAddress);
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";

/**
 * @title Lib_BVMCodec
 */
library Lib_BVMCodec {
    /*********
     * Enums *
     *********/

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }

    /***********
     * Structs *
     ***********/

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes signature;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex; // QUEUED TX ONLY
        uint256 timestamp; // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData; // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 transactionHash;
        uint40 timestamp;
        uint40 blockNumber;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes a standard BVM transaction.
     * @param _transaction BVM transaction to encode.
     * @return Encoded transaction bytes.
     */
    function encodeTransaction(Transaction memory _transaction)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _transaction.timestamp,
                _transaction.blockNumber,
                _transaction.l1QueueOrigin,
                _transaction.l1TxOrigin,
                _transaction.entrypoint,
                _transaction.gasLimit,
                _transaction.data
            );
    }

    /**
     * Hashes a standard BVM transaction.
     * @param _transaction BVM transaction to encode.
     * @return Hashed transaction
     */
    function hashTransaction(Transaction memory _transaction) internal pure returns (bytes32) {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return Account state struct.
     */
    function decodeEVMAccount(bytes memory _encoded) internal pure returns (EVMAccount memory) {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return
            EVMAccount({
                nonce: Lib_RLPReader.readUint256(accountState[0]),
                balance: Lib_RLPReader.readUint256(accountState[1]),
                storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
                codeHash: Lib_RLPReader.readBytes32(accountState[3])
            });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return Hash of the header.
     */
    function hashBatchHeader(Lib_BVMCodec.ChainBatchHeader memory _batchHeader)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _batchHeader.batchRoot,
                    _batchHeader.batchSize,
                    _batchHeader.prevTotalElements,
                    _batchHeader.signature,
                    _batchHeader.extraData
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./IChallenge.sol";
import "./ChallengeLib.sol";
import "../IRollup.sol";

contract Challenge is IChallenge {
    struct BisectedStore {
        bytes32 startState;
        bytes32 midState;
        bytes32 endState;
        uint256 blockNum;
        uint256 blockTime;
        uint256 challengedSegmentStart;
        uint256 challengedSegmentLength;
    }

    enum Turn {
        NoChallenge,
        Challenger,
        Defender
    }

    // Error codes

    // Can only initialize once
    string private constant CHAL_INIT_STATE = "CHAL_INIT_STATE";
    // deadline expired
    string private constant BIS_DEADLINE = "BIS_DEADLINE";
    // Only original asserter can continue bisect
    string private constant BIS_SENDER = "BIS_SENDER";
    // Incorrect previous state
    string private constant BIS_PREV = "BIS_PREV";
    // Can't timeout before deadline
    string private constant TIMEOUT_DEADLINE = "TIMEOUT_DEADLINE";

    bytes32 private constant UNREACHABLE_ASSERTION = bytes32(uint256(0));

    uint256 private constant MAX_BISECTION_DEGREE = 2;

    // Other contracts
    address internal resultReceiver;
    IVerifierEntry internal verifier;

    // Challenge state
    address public defender;
    address public challenger;
    uint256 public lastMoveBlockTime;
    uint256 public defenderTimeLeft;
    uint256 public challengerTimeLeft;

    Turn public turn;
    // See `ChallengeLib.computeBisectionHash` for the format of this commitment.
    bytes32 public bisectionHash;
    bytes32[3] public prevBisection;

    // Initial state used to initialize bisectionHash (write-once).
    bytes32 private startStateHash;
    bytes32 private endStateHash;

    address public winner;

    bool public rollback;
    uint256 public startInboxSize;

    BisectedStore public currentBisected;

    /**
     * @notice Pre-condition: `msg.sender` is correct and still has time remaining.
     * Post-condition: `turn` changes and `lastMoveBlock` set to current `block.number`.
     */
    modifier onlyOnTurn() {
        require(msg.sender == currentResponder(), BIS_SENDER);
        require(block.timestamp - lastMoveBlockTime <= currentResponderTimeLeft(), BIS_DEADLINE);

        _;

        if (turn == Turn.Challenger) {
            challengerTimeLeft = challengerTimeLeft - (block.timestamp- lastMoveBlockTime);
            turn = Turn.Defender;
        } else if (turn == Turn.Defender) {
            defenderTimeLeft = defenderTimeLeft - (block.timestamp - lastMoveBlockTime);
            turn = Turn.Challenger;
        }
        lastMoveBlockTime = block.timestamp;
    }

    /**
     * @notice Ensures challenge has been initialized.
     */
    modifier postInitialization() {
        require(bisectionHash != 0, "NOT_INITIALIZED");
        _;
    }

    modifier onlyDefender(){
        require(defender != address(0),"Defender not set");
        require(msg.sender==defender,"Caller not defender");
        _;
    }

    function initialize(
        address _defender,
        address _challenger,
        IVerifierEntry _verifier,
        address _resultReceiver,
        uint256 _startInboxSize,
        bytes32 _startStateHash,
        bytes32 _endStateHash
    ) external override {
        require(turn == Turn.NoChallenge, CHAL_INIT_STATE);
        require(_defender != address(0) && _challenger != address(0) && _resultReceiver != address(0), "ZERO_ADDRESS");
        defender = _defender;
        challenger = _challenger;
        verifier = _verifier;
        resultReceiver = _resultReceiver;
        startStateHash = _startStateHash;
        endStateHash = _endStateHash;

        turn = Turn.Defender;
        lastMoveBlockTime = block.timestamp;
        // TODO(ujval): initialize timeout
        defenderTimeLeft = 150;
        challengerTimeLeft = 150;
        prevBisection[0] = _startStateHash;
        prevBisection[1] = bytes32(0);
        prevBisection[2] = _endStateHash;

        startInboxSize = _startInboxSize;
    }

    function initializeChallengeLength(bytes32 checkStateHash, uint256 _numSteps) external override onlyOnTurn {
        require(bisectionHash == 0, CHAL_INIT_STATE);
        require(_numSteps > 0, "INVALID_NUM_STEPS");
        bisectionHash = ChallengeLib.computeBisectionHash(0, _numSteps);
        // TODO: consider emitting a different event?
        currentBisected = BisectedStore(startStateHash, checkStateHash, endStateHash, block.number, block.timestamp, 0, _numSteps);
        emit Bisected(startStateHash, checkStateHash, endStateHash, block.number, block.timestamp, 0, _numSteps);
    }

    function bisectExecution(
        bytes32[3] calldata bisection,
        uint256 challengedSegmentIndex,
        uint256 challengedSegmentStart,
        uint256 challengedSegmentLength,
        uint256 prevChallengedSegmentStart,
        uint256 prevChallengedSegmentLength
    ) external override onlyOnTurn postInitialization {
        // Verify provided prev bisection.
        bytes32 prevHash = ChallengeLib.computeBisectionHash(prevChallengedSegmentStart, prevChallengedSegmentLength);
        require(prevHash == bisectionHash, BIS_PREV);

        // Require agreed upon start state hash and disagreed upon end state hash.
        if (prevBisection[1] != bytes32(0)) {
            require(bisection[0] == prevBisection[0] || bisection[0] == prevBisection[1], "AMBIGUOUS_START");
        }
        require(bisection[2] != prevBisection[2], "INVALID_END");

        // Compute segment start/length.
        require(challengedSegmentLength > 0, "TOO_SHORT");

        // Compute new challenge state.
        prevBisection[0] = bisection[0];
        prevBisection[1] = bisection[1];
        prevBisection[2] = bisection[2];
        bisectionHash = ChallengeLib.computeBisectionHash(challengedSegmentStart, challengedSegmentLength);
        currentBisected = BisectedStore(bisection[0], bisection[1], bisection[2], block.number, block.timestamp, challengedSegmentStart, challengedSegmentLength);
        emit Bisected(bisection[0], bisection[1], bisection[2], block.number, block.timestamp, challengedSegmentStart, challengedSegmentLength);
    }

    function verifyOneStepProof(
        VerificationContext.Context calldata ctx,
        uint8 verifyType,
        bytes calldata proof,
        uint256 challengedStepIndex,
        uint256 prevChallengedSegmentStart,
        uint256 prevChallengedSegmentLength
    ) external override onlyOnTurn {
         // Verify provided prev bisection.
         bytes32 prevHash =
            ChallengeLib.computeBisectionHash(prevChallengedSegmentStart, prevChallengedSegmentLength);
         require(prevHash == bisectionHash, BIS_PREV);
         // require(challengedStepIndex > 0 && challengedStepIndex < prevBisection.length, "INVALID_INDEX");
         // Require that this is the last round.
         require(prevChallengedSegmentLength / MAX_BISECTION_DEGREE <= 1, "BISECTION_INCOMPLETE");

         // verify OSP
         // IVerificationContext ctx = <get ctx from sequenced txs>;

         bytes32 nextStateHash = verifier.verifyOneStepProof(
             ctx,
             verifyType,
             prevBisection[challengedStepIndex-1],
             proof
         );
         if (nextStateHash == prevBisection[challengedStepIndex]) {
             // osp verified, current win
             _currentWin(CompletionReason.OSP_VERIFIED);
         } else {
             _currentLose(CompletionReason.OSP_VERIFIED);
         }
    }

    function setRollback() public {
        if (rollback) {
            revert("ALREADY_SET_ROLLBACK");
        }
        rollback = true;
    }

    function timeout() external override {
        require(block.timestamp - lastMoveBlockTime > currentResponderTimeLeft(), TIMEOUT_DEADLINE);
        if (turn == Turn.Defender) {
            _challengerWin(CompletionReason.TIMEOUT);
        } else {
            _asserterWin(CompletionReason.TIMEOUT);
        }
    }

    function currentResponder() public view override returns (address) {
        if (turn == Turn.Defender) {
            return defender;
        } else if (turn == Turn.Challenger) {
            return challenger;
        } else {
            revert("NO_TURN");
        }
    }

    function currentResponderTimeLeft() public view override returns (uint256) {
        if (turn == Turn.Defender) {
            return defenderTimeLeft;
        } else if (turn == Turn.Challenger) {
            return challengerTimeLeft;
        } else {
            revert("NO_TURN");
        }
    }

    function _currentWin(CompletionReason reason) private {
        if (turn == Turn.Defender) {
            _asserterWin(reason);
        } else {
            winner = challenger;
            _challengerWin(reason);
        }
    }

    function _currentLose(CompletionReason reason) private {
        if (turn == Turn.Defender) {
            _challengerWin(reason);
        } else {
            _asserterWin(reason);
        }
    }

    function _asserterWin(CompletionReason reason) private {
        winner = defender;
        emit ChallengeCompleted(defender, challenger, reason);
    }

    function _challengerWin(CompletionReason reason) private {
        winner = challenger;
        emit ChallengeCompleted(challenger, defender, reason);
    }

    function completeChallenge(bool result) external onlyDefender{
        require(winner != address(0),"Do not have winner");

        if (winner == challenger) {
            if (result) {
                IRollup(resultReceiver).completeChallenge(challenger, defender);
                return;
            }
            winner = defender;
        }
        IRollup(resultReceiver).completeChallenge(defender, challenger);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

library ChallengeLib {
    /**
     * @notice Computes the initial bisection hash.
     * @param numSteps Number of steps from the end of `startState` to the end of `endState`.
     */
    function initialBisectionHash(uint256 numSteps)
        internal
        pure
        returns (bytes32)
    {
        return ChallengeLib.computeBisectionHash(0, numSteps);
    }

    /**
     * @notice Computes H(bisection || segmentStart || segmentLength)
     * @param challengedSegmentStart The number of steps preceding `bisection[1]`, relative to the assertion being challenged.
     * @param challengedSegmentLength Length of bisected segment (in steps), from the start of bisection[1] to the end of bisection[-1].
     */
    function computeBisectionHash(
        uint256 challengedSegmentStart,
        uint256 challengedSegmentLength
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(challengedSegmentStart, challengedSegmentLength));
    }

    /**
     * @notice Returns length of first segment in a bisection.
     */
    function firstSegmentLength(uint256 length, uint256 bisectionDegree) internal pure returns (uint256) {
        return length / bisectionDegree + length % bisectionDegree;
    }

    /**
     * @notice Returns length of a segment (after first) in a bisection.
     */
    function otherSegmentLength(uint256 length, uint256 bisectionDegree) internal pure returns (uint256) {
        return length / bisectionDegree;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./libraries/VerificationContext.sol";

interface IVerifier {
    function verifyOneStepProof(VerificationContext.Context memory ctx, bytes32 currStateHash, bytes calldata encoded)
        external
        pure
        returns (bytes32);
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

/// @dev Thrown when unauthorized (!rollup) address calls an only-rollup function
/// @param sender Address of the caller
/// @param rollup The rollup address authorized to call this function
error NotRollup(address sender, address rollup);

/// @dev Thrown when unauthorized (!challenge) address calls an only-challenge function
/// @param sender Address of the caller
/// @param challenge The challenge address authorized to call this function
error NotChallenge(address sender, address challenge);

/// @dev Thrown when unauthorized (!sequencer) address calls an only-sequencer function
/// @param sender Address of the caller
/// @param sequencer The sequencer address authorized to call this function
error NotSequencer(address sender, address sequencer);

/// @dev Thrown when function is called with a zero address argument
error ZeroAddress();

/// @dev Thrown when function is called with a zero address argument
error RedundantInitialized();

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
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {
    /*************
     * Constants *
     *************/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({ length: _in.length - offset, ptr: _in.ptr + offset })
            );

            out[itemCount] = RLPItem({ length: itemLength + itemOffset, ptr: _in.ptr + offset });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in) internal pure returns (string memory) {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in) internal pure returns (string memory) {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(out == 0 || out == 1, "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1");

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
            }

            require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
            }

            require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask;
        unchecked {
            mask = 256**(32 - (_length % 32)) - 1;
        }

        assembly {
            mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
        }
        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {
    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        return uint256(toBytes32(_bytes));
    }

    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts a bytes32 value to a boolean. Anything non-zero will be converted to "true."
     * @param _in Input bytes32 value.
     * @return Bytes32 as a boolean.
     */
    function toBool(bytes32 _in) internal pure returns (bool) {
        return _in != 0;
    }

    /**
     * Converts a boolean to a bytes32 value.
     * @param _in Input boolean value.
     * @return Boolean as a bytes32.
     */
    function fromBool(bool _in) internal pure returns (bytes32) {
        return bytes32(uint256(_in ? 1 : 0));
    }

    /**
     * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
     * @param _in Input bytes32 value.
     * @return Bytes32 as an address.
     */
    function toAddress(bytes32 _in) internal pure returns (address) {
        return address(uint160(uint256(_in)));
    }

    /**
     * Converts an address to a bytes32.
     * @param _in Input address value.
     * @return Address as a bytes32.
     */
    function fromAddress(address _in) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_in)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * This file was changed in accordance to Apache License, Version 2.0.
 *
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../verifier/IVerifierEntry.sol";

/**
 * @notice Protocol execution:
 * `initialize` (challenger, via Rollup) ->
 * `initializeChallengeLength` (defender) ->
 * `bisectExecution` (challenger, defender -- alternating) ->
 * `verifyOneStepProof`
 */
interface IChallenge {
    enum CompletionReason {
        OSP_VERIFIED, // OSP verified by winner.
        TIMEOUT // Loser timed out before completing their round.
    }

    event ChallengeCompleted(address winner, address loser, CompletionReason reason);

    event Bisected(bytes32 startState, bytes32 midState, bytes32 endState, uint256 blockNum, uint256 blockTime, uint256 challengedSegmentStart, uint256 challengedSegmentLength);

    /**
     * @notice Initializes contract.
     * @param _defender Defending party.
     * @param _challenger Challenging party. Challenger starts.
     * @param _verifier Address of the verifier contract.
     * @param _resultReceiver Address of contract that will receive the outcome (via callback `completeChallenge`).
     * @param _startStateHash Bisection root being challenged.
     * @param _endStateHash Bisection root being challenged.
     */
    function initialize(
        address _defender,
        address _challenger,
        IVerifierEntry _verifier,
        address _resultReceiver,
        uint256 _startInboxSize,
        bytes32 _startStateHash,
        bytes32 _endStateHash
    ) external;

    /**
     * @notice Initializes the length of the challenge. Must be called by defender before bisection rounds begin.
     * @param _numSteps Number of steps executed from the start of the assertion to its end.
     * If this parameter is incorrect, the defender will be slashed (assuming successful execution of the protocol by the challenger).
     */
    function initializeChallengeLength(bytes32 checkStateHash, uint256 _numSteps) external;

    /**
     * @notice Bisects a segment. The challenged segment is defined by: {`challengedSegmentStart`, `challengedSegmentLength`, `bisection[0]`, `oldEndHash`}
     * @param bisection Bisection of challenged segment. Each element is a state hash (see `ChallengeLib.stateHash`).
     * The first element is the last agreed upon state hash. Must be of length MAX_BISECTION_LENGTH for all rounds except the last.
     * In the last round, the bisection segments must be single steps.
     * @param challengedSegmentIndex Index into `prevBisection`. Must be greater than 0 (since the first is agreed upon).
     * @param challengedSegmentStart Offset of the segment challenged in the preceding round (in steps).
     * @param challengedSegmentLength Length of the segment challenged in the preceding round (in steps).
     * @param prevChallengedSegmentStart Offset of the segment challenged in the preceding round (in steps).
     * Note: this is relative to the assertion being challenged (i.e. always between 0 and the initial `numSteps`).
     * @param prevChallengedSegmentLength Length of the segment challenged in the preceding round (in steps).
     */
    function bisectExecution(
        bytes32[3] calldata bisection,
        uint256 challengedSegmentIndex,
        uint256 challengedSegmentStart,
        uint256 challengedSegmentLength,
        uint256 prevChallengedSegmentStart,
        uint256 prevChallengedSegmentLength
    ) external;

    /**
     * @notice Verifies one step proof and completes challenge protocol.
     * @param ctx execution context.
     * @param verifyType Index into `prevBisection`. Must be greater than 0 (since the first is agreed upon).
     * @param proof one step proof.
     * @param prevChallengedSegmentStart Offset of the segment challenged in the preceding round (in steps).
     * Note: this is relative to the assertion being challenged (i.e. always between 0 and the initial `numSteps`).
     * @param prevChallengedSegmentLength Length of the segment challenged in the preceding round (in steps).
     */
    function verifyOneStepProof(
        VerificationContext.Context calldata ctx,
        uint8 verifyType,
        bytes calldata proof,
        uint256 challengedStepIndex,
        uint256 prevChallengedSegmentStart,
        uint256 prevChallengedSegmentLength
    ) external;

    function setRollback() external;

    /**
     * @notice Triggers completion of challenge protocol if a responder timed out.
     */
    function timeout() external;

    function currentResponder() external view returns (address);

    function currentResponderTimeLeft() external view returns (uint256);

    function completeChallenge(bool) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./libraries/VerificationContext.sol";

interface IVerifierEntry {
    function verifyOneStepProof(
        VerificationContext.Context memory ctx,
        uint8 verifier,
        bytes32 currStateHash,
        bytes calldata encoded
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/DeserializationLib.sol";
import "../../libraries/BytesLib.sol";
import "../../libraries/MerkleLib.sol";

import "./MemoryLib.sol";
import "./EVMTypesLib.sol";

library VerificationContext {
    using BytesLib for bytes;
    using EVMTypesLib for EVMTypesLib.Transaction;

    struct Context {
        address coinbase;
        uint256 timestamp;
        uint256 number;
        address origin;
        EVMTypesLib.Transaction transaction;
        bytes32 inputRoot;
        bytes32 txHash;
    }

    function newContext(bytes calldata proof) internal view returns (Context memory ctx) {
//        inbox.verifyTxInclusion(proof);
//        ctx.coinbase = inbox.sequencerAddress();
        ctx.coinbase = address(0); // TODO FIXME
        uint256 offset = 0;
        uint256 txDataLength;
        (offset, ctx.origin) = DeserializationLib.deserializeAddress(proof, offset);
        (offset, ctx.number) = DeserializationLib.deserializeUint256(proof, offset);
        (offset, ctx.timestamp) = DeserializationLib.deserializeUint256(proof, offset);
        (offset, txDataLength) = DeserializationLib.deserializeUint256(proof, offset);
        bytes memory txData = bytes(proof[offset:txDataLength]);
        ctx.transaction = EVMTypesLib.decodeTransaction(txData);
    }

    function getCoinbase(Context memory ctx) internal pure returns (address) {
        return ctx.coinbase;
    }

    function getTimestamp(Context memory ctx) internal pure returns (uint256) {
        return ctx.timestamp;
    }

    function getBlockNumber(Context memory ctx) internal pure returns (uint256) {
        return ctx.number;
    }

    function getDifficulty(Context memory) internal pure returns (uint256) {
        return 1;
    }

    function getGasLimit(Context memory) internal pure returns (uint64) {
        return 80000000;
    }

    function getChainID(Context memory) internal pure returns (uint256) {
        return 13527;
    }

    // Transaction
    function getOrigin(Context memory ctx) internal pure returns (address) {
        return ctx.origin;
    }

    function getRecipient(Context memory ctx) internal pure returns (address) {
        return ctx.transaction.to;
    }

    function getValue(Context memory ctx) internal pure returns (uint256) {
        return ctx.transaction.value;
    }

    function getGas(Context memory ctx) internal pure returns (uint64) {
        return ctx.transaction.gas;
    }

    function getGasPrice(Context memory ctx) internal pure returns (uint256) {
        return ctx.transaction.gasPrice;
    }

    function getInput(Context memory ctx) internal pure returns (bytes memory) {
        return ctx.transaction.data;
    }

    function getInputSize(Context memory ctx) internal pure returns (uint64) {
        return uint64(ctx.transaction.data.length);
    }

    function getInputRoot(Context memory ctx) internal pure returns (bytes32) {
        if (ctx.inputRoot == 0x0) {
            ctx.inputRoot = MemoryLib.getMemoryRoot(ctx.transaction.data);
        }
        return ctx.inputRoot;
    }

    function getTxHash(Context memory ctx) internal pure returns (bytes32) {
        if (ctx.txHash == 0x0) {
            ctx.txHash = ctx.transaction.hashTransaction();
        }
        return ctx.transaction.hashTransaction();
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./BytesLib.sol";

library DeserializationLib {
    function deserializeAddress(bytes memory data, uint256 startOffset) internal pure returns (uint256, address) {
        return (startOffset + 20, BytesLib.toAddress(data, startOffset));
    }

    function deserializeUint256(bytes memory data, uint256 startOffset) internal pure returns (uint256, uint256) {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, BytesLib.toUint256(data, startOffset));
    }

    function deserializeBytes32(bytes memory data, uint256 startOffset) internal pure returns (uint256, bytes32) {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, BytesLib.toBytes32(data, startOffset));
    }
}

// SPDX-License-Identifier: Unlicense

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 * @custom:attribution https://github.com/GNSPS/solidity-bytes-utils
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toBytes32Pad(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        bytes32 result;

        assembly {
            result := mload(add(add(_bytes, 0x20), _start))
        }

        if (_bytes.length < _start + 32) {
            uint256 pad = 32 + _start - _bytes.length;
            result = result >> pad << pad;
        }

        return result;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for { let cc := add(_postBytes, 0x20) }
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MerkleLib {
    // Hashes a and b in the order they are passed
    function hash_node(bytes32 a, bytes32 b) internal pure returns (bytes32 hash) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            hash := keccak256(0x00, 0x40)
        }
    }

    // Hashes a and b in order define by boolean
    function hash_pair(bytes32 a, bytes32 b, bool order) internal pure returns (bytes32 hash) {
        hash = order ? hash_node(a, b) : hash_node(b, a);
    }

    // Counts number of set bits (1's) in 32-bit unsigned integer
    function bit_count_32(uint32 n) internal pure returns (uint32) {
        n = n - ((n >> 1) & 0x55555555);
        n = (n & 0x33333333) + ((n >> 2) & 0x33333333);

        return (((n + (n >> 4)) & 0xF0F0F0F) * 0x1010101) >> 24;
    }

    // Round 32-bit unsigned integer up to the nearest power of 2
    function round_up_to_power_of_2(uint32 n) internal pure returns (uint32) {
        if (bit_count_32(n) == 1) return n;

        n |= n >> 1;
        n |= n >> 2;
        n |= n >> 4;
        n |= n >> 8;
        n |= n >> 16;

        return n + 1;
    }

    // Get the Element Merkle Root for a tree with just a single bytes32 element in memory
    function get_root_from_one(bytes32 element) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes1(0), element));
    }

    // Get nodes (parent of leafs) from bytes32 elements in memory
    function get_nodes_from_elements(bytes32[] memory elements) internal pure returns (bytes32[] memory nodes) {
        uint256 element_count = elements.length;
        uint256 node_count = (element_count >> 1) + (element_count & 1);
        nodes = new bytes32[](node_count);
        uint256 write_index;
        uint256 left_index;

        while (write_index < node_count) {
            left_index = write_index << 1;

            if (left_index == element_count - 1) {
                nodes[write_index] = keccak256(abi.encodePacked(bytes1(0), elements[left_index]));
                break;
            }

            nodes[write_index++] = hash_node(
                keccak256(abi.encodePacked(bytes1(0), elements[left_index])),
                keccak256(abi.encodePacked(bytes1(0), elements[left_index + 1]))
            );
        }
    }

    // Get the Element Merkle Root given nodes (parent of leafs)
    function get_root_from_nodes(bytes32[] memory nodes) internal pure returns (bytes32) {
        uint256 node_count = nodes.length;
        uint256 write_index;
        uint256 left_index;

        while (node_count > 1) {
            left_index = write_index << 1;

            if (left_index == node_count - 1) {
                nodes[write_index] = nodes[left_index];
                write_index = 0;
                node_count = (node_count >> 1) + (node_count & 1);
                continue;
            }

            if (left_index >= node_count) {
                write_index = 0;
                node_count = (node_count >> 1) + (node_count & 1);
                continue;
            }

            nodes[write_index++] = hash_node(nodes[left_index], nodes[left_index + 1]);
        }

        return nodes[0];
    }

    // Get the Element Merkle Root for a tree with several bytes32 elements in memory
    function get_root_from_many(bytes32[] memory elements) internal pure returns (bytes32) {
        return get_root_from_nodes(get_nodes_from_elements(elements));
    }

    // Get the original Element Merkle Root, given a Size Proof
    function get_root_from_size_proof(uint256 element_count, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 proof_index = bit_count_32(uint32(element_count)) - 1;
        hash = proof[proof_index];

        while (proof_index > 0) {
            hash = hash_node(proof[--proof_index], hash);
        }
    }

    // Get the original Element Merkle Root, given an index, a leaf, and a Single Proof
    function get_root_from_leaf_and_single_proof(uint256 index, bytes32 leaf, bytes32[] memory proof)
        internal
        pure
        returns (bytes32)
    {
        uint256 proof_index = proof.length - 1;
        uint256 upper_bound = uint256(proof[0]) - 1;

        while (proof_index > 0) {
            if (index != upper_bound || (index & 1 == 1)) {
                leaf = (index & 1 == 1) ? hash_node(proof[proof_index], leaf) : hash_node(leaf, proof[proof_index]);
                proof_index -= 1;
            }

            index >>= 1;
            upper_bound >>= 1;
        }

        return leaf;
    }

    // Get the original Element Merkle Root, given an index, a bytes32 element, and a Single Proof
    function get_root_from_single_proof(uint256 index, bytes32 element, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(bytes1(0), element));
        hash = get_root_from_leaf_and_single_proof(index, hash, proof);
    }

    // Get the original and updated Element Merkle Root, given an index, a leaf, an update leaf, and a Single Proof
    function get_roots_from_leaf_and_single_proof_update(
        uint256 index,
        bytes32 leaf,
        bytes32 update_leaf,
        bytes32[] memory proof
    ) internal pure returns (bytes32 scratch, bytes32) {
        uint256 proof_index = proof.length - 1;
        uint256 upper_bound = uint256(proof[0]) - 1;

        while (proof_index > 0) {
            if ((index != upper_bound) || (index & 1 == 1)) {
                scratch = proof[proof_index];
                proof_index -= 1;
                leaf = (index & 1 == 1) ? hash_node(scratch, leaf) : hash_node(leaf, scratch);
                update_leaf = (index & 1 == 1) ? hash_node(scratch, update_leaf) : hash_node(update_leaf, scratch);
            }

            index >>= 1;
            upper_bound >>= 1;
        }

        return (leaf, update_leaf);
    }

    // Get the original and updated Element Merkle Root, given an index, a bytes32 element, a bytes32 update element, and a Single Proof
    function get_roots_from_single_proof_update(
        uint256 index,
        bytes32 element,
        bytes32 update_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 hash, bytes32 update_hash) {
        hash = keccak256(abi.encodePacked(bytes1(0), element));
        update_hash = keccak256(abi.encodePacked(bytes1(0), update_element));
        return get_roots_from_leaf_and_single_proof_update(index, hash, update_hash, proof);
    }

    // Get the indices of the elements being proven, given an Existence Multi Proof
    function get_indices_from_multi_proof(uint256 element_count, bytes32 flags, bytes32 skips, bytes32 orders)
        internal
        pure
        returns (uint256[] memory indices)
    {
        indices = new uint256[](element_count);
        uint256[] memory bits_pushed = new uint256[](element_count);
        bool[] memory grouped_with_next = new bool[](element_count);
        element_count -= 1;
        uint256 index = element_count;
        bytes32 bit_check = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 flag;
        bytes32 skip;
        bytes32 order;
        uint256 bits_to_push;

        while (true) {
            flag = flags & bit_check;
            skip = skips & bit_check;
            order = orders & bit_check;
            bits_to_push = 1 << bits_pushed[index];

            if (skip == bit_check) {
                if (flag == bit_check) return indices;

                while (true) {
                    bits_pushed[index]++;

                    if (index == 0) {
                        index = element_count;
                        break;
                    }

                    if (!grouped_with_next[index--]) break;
                }

                bit_check <<= 1;
                continue;
            }

            if (flag == bit_check) {
                while (true) {
                    if (order == bit_check) {
                        indices[index] |= bits_to_push;
                    }

                    bits_pushed[index]++;

                    if (index == 0) {
                        index = element_count;
                        break;
                    }

                    if (!grouped_with_next[index]) {
                        grouped_with_next[index--] = true;
                        break;
                    }

                    grouped_with_next[index--] = true;
                }
            }

            while (true) {
                if (order != bit_check) {
                    indices[index] |= bits_to_push;
                }

                bits_pushed[index]++;

                if (index == 0) {
                    index = element_count;
                    break;
                }

                if (!grouped_with_next[index--]) break;
            }

            bit_check <<= 1;
        }
    }

    // Get leafs from bytes32 elements in memory, in reverse order
    function get_reversed_leafs_from_elements(bytes32[] memory elements)
        internal
        pure
        returns (bytes32[] memory leafs)
    {
        uint256 element_count = elements.length;
        leafs = new bytes32[](element_count);
        // uint256 read_index = element_count - 1;
        // uint256 write_index;

        for (uint64 i = 0; i < element_count; i++) {
            leafs[i] = keccak256(abi.encodePacked(bytes1(0), elements[element_count - 1 - i]));
        }

        // while (write_index < element_count) {
        //     leafs[write_index] = keccak256(abi.encodePacked(bytes1(0), elements[read_index]));
        //     write_index += 1;
        //     read_index -= 1;
        // }
    }

    // Get the original Element Merkle Root, given leafs and an Existence Multi Proof
    function get_root_from_leafs_and_multi_proof(bytes32[] memory leafs, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 right)
    {
        uint256 leaf_count = leafs.length;
        uint256 read_index;
        uint256 write_index;
        uint256 proof_index = 4;
        bytes32 bit_check = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 flags = proof[1];
        bytes32 skips = proof[2];
        bytes32 orders = proof[3];

        while (true) {
            if (skips & bit_check == bit_check) {
                if (flags & bit_check == bit_check) return leafs[(write_index == 0 ? leaf_count : write_index) - 1];

                leafs[write_index] = leafs[read_index];

                read_index = (read_index + 1) % leaf_count;
                write_index = (write_index + 1) % leaf_count;
                bit_check <<= 1;
                continue;
            }

            right = (flags & bit_check == bit_check) ? leafs[read_index++] : proof[proof_index++];

            read_index %= leaf_count;

            leafs[write_index] = hash_pair(leafs[read_index], right, orders & bit_check == bit_check);

            read_index = (read_index + 1) % leaf_count;
            write_index = (write_index + 1) % leaf_count;
            bit_check <<= 1;
        }
    }

    // Get the original Element Merkle Root, given bytes32 memory in memory and an Existence Multi Proof
    function get_root_from_multi_proof(bytes32[] memory elements, bytes32[] memory proof)
        internal
        pure
        returns (bytes32)
    {
        return get_root_from_leafs_and_multi_proof(get_reversed_leafs_from_elements(elements), proof);
    }

    // Get current and update leafs from current bytes32 elements in memory and update bytes32 elements in memory, in reverse order
    function get_reversed_leafs_from_current_and_update_elements(
        bytes32[] memory elements,
        bytes32[] memory update_elements
    ) internal pure returns (bytes32[] memory leafs, bytes32[] memory update_leafs) {
        uint256 element_count = elements.length;
        require(update_elements.length == element_count, "LENGTH_MISMATCH");

        leafs = new bytes32[](element_count);
        update_leafs = new bytes32[](element_count);
        // uint256 read_index = element_count - 1;
        // uint256 write_index;

        // while (write_index < element_count) {
        //     leafs[write_index] = keccak256(abi.encodePacked(bytes1(0), elements[read_index]));
        //     update_leafs[write_index] = keccak256(abi.encodePacked(bytes1(0), update_elements[read_index]));
        //     write_index += 1;
        //     read_index -= 1;
        // }

        for (uint64 i = 0; i < element_count; i++) {
            leafs[i] = keccak256(abi.encodePacked(bytes1(0), elements[element_count - 1 - i]));
            update_leafs[i] = keccak256(abi.encodePacked(bytes1(0), update_elements[element_count - 1 - i]));
        }
    }

    // Get the original and updated Element Merkle Root, given leafs, update leafs, and an Existence Multi Proof
    function get_roots_from_leafs_and_multi_proof_update(
        bytes32[] memory leafs,
        bytes32[] memory update_leafs,
        bytes32[] memory proof
    ) internal pure returns (bytes32 flags, bytes32 skips) {
        uint256 leaf_count = update_leafs.length;
        uint256 read_index;
        uint256 write_index;
        uint256 proof_index = 4;
        bytes32 bit_check = 0x0000000000000000000000000000000000000000000000000000000000000001;
        flags = proof[1];
        skips = proof[2];
        bytes32 orders = proof[3];
        bytes32 scratch;
        uint256 scratch_2;

        while (true) {
            if (skips & bit_check == bit_check) {
                if (flags & bit_check == bit_check) {
                    read_index = (write_index == 0 ? leaf_count : write_index) - 1;

                    return (leafs[read_index], update_leafs[read_index]);
                }

                leafs[write_index] = leafs[read_index];
                update_leafs[write_index] = update_leafs[read_index];

                read_index = (read_index + 1) % leaf_count;
                write_index = (write_index + 1) % leaf_count;
                bit_check <<= 1;
                continue;
            }

            if (flags & bit_check == bit_check) {
                scratch_2 = (read_index + 1) % leaf_count;

                leafs[write_index] = hash_pair(leafs[scratch_2], leafs[read_index], orders & bit_check == bit_check);
                update_leafs[write_index] =
                    hash_pair(update_leafs[scratch_2], update_leafs[read_index], orders & bit_check == bit_check);

                read_index += 2;
            } else {
                scratch = proof[proof_index++];

                leafs[write_index] = hash_pair(leafs[read_index], scratch, orders & bit_check == bit_check);
                update_leafs[write_index] =
                    hash_pair(update_leafs[read_index], scratch, orders & bit_check == bit_check);

                read_index += 1;
            }

            read_index %= leaf_count;
            write_index = (write_index + 1) % leaf_count;
            bit_check <<= 1;
        }
    }

    // Get the original and updated Element Merkle Root,
    // given bytes32 elements in memory, bytes32 update elements in memory, and an Existence Multi Proof
    function get_roots_from_multi_proof_update(
        bytes32[] memory elements,
        bytes32[] memory update_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32, bytes32) {
        (bytes32[] memory leafs, bytes32[] memory update_leafs) =
            get_reversed_leafs_from_current_and_update_elements(elements, update_elements);
        return get_roots_from_leafs_and_multi_proof_update(leafs, update_leafs, proof);
    }

    // Get the original Element Merkle Root, given an Append Proof
    function get_root_from_append_proof(bytes32[] memory proof) internal pure returns (bytes32 hash) {
        uint256 proof_index = bit_count_32(uint32(uint256(proof[0])));
        hash = proof[proof_index];

        while (proof_index > 1) {
            proof_index -= 1;
            hash = hash_node(proof[proof_index], hash);
        }
    }

    // Get the original and updated Element Merkle Root, given append leaf and an Append Proof
    function get_roots_from_leaf_and_append_proof_single_append(bytes32 append_leaf, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 hash, bytes32 scratch)
    {
        uint256 proof_index = bit_count_32(uint32(uint256(proof[0])));
        hash = proof[proof_index];
        append_leaf = hash_node(hash, append_leaf);

        while (proof_index > 1) {
            proof_index -= 1;
            scratch = proof[proof_index];
            append_leaf = hash_node(scratch, append_leaf);
            hash = hash_node(scratch, hash);
        }

        return (hash, append_leaf);
    }

    // Get the original and updated Element Merkle Root, given a bytes32 append element in memory and an Append Proof
    function get_roots_from_append_proof_single_append(bytes32 append_element, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_leaf, bytes32)
    {
        append_leaf = keccak256(abi.encodePacked(bytes1(0), append_element));
        return get_roots_from_leaf_and_append_proof_single_append(append_leaf, proof);
    }

    // Get leafs from bytes32 elements in memory
    function get_leafs_from_elements(bytes32[] memory elements) internal pure returns (bytes32[] memory leafs) {
        uint256 element_count = elements.length;
        leafs = new bytes32[](element_count);

        while (element_count > 0) {
            element_count -= 1;
            leafs[element_count] = keccak256(abi.encodePacked(bytes1(0), elements[element_count]));
        }
    }

    // Get the original and updated Element Merkle Root, given append leafs and an Append Proof
    function get_roots_from_leafs_and_append_proof_multi_append(bytes32[] memory append_leafs, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 hash, bytes32)
    {
        uint256 leaf_count = append_leafs.length;
        uint256 write_index;
        uint256 read_index;
        uint256 offset = uint256(proof[0]);
        uint256 index = offset;

        // reuse leaf_count variable as upper_bound, since leaf_count no longer needed
        leaf_count += offset;
        leaf_count -= 1;
        uint256 proof_index = bit_count_32(uint32(offset));
        hash = proof[proof_index];

        while (leaf_count > 0) {
            if ((write_index == 0) && (index & 1 == 1)) {
                append_leafs[0] = hash_node(proof[proof_index], append_leafs[read_index]);
                proof_index -= 1;
                read_index += 1;

                if (proof_index > 0) {
                    hash = hash_node(proof[proof_index], hash);
                }

                write_index = 1;
                index += 1;
            } else if (index < leaf_count) {
                append_leafs[write_index++] = hash_node(append_leafs[read_index++], append_leafs[read_index]);
                read_index += 1;
                index += 2;
            }

            if (index >= leaf_count) {
                if (index == leaf_count) {
                    append_leafs[write_index] = append_leafs[read_index];
                }

                read_index = 0;
                write_index = 0;
                leaf_count >>= 1;
                offset >>= 1;
                index = offset;
            }
        }

        return (hash, append_leafs[0]);
    }

    // Get the original and updated Element Merkle Root, given bytes32 append elements in memory and an Append Proof
    function get_roots_from_append_proof_multi_append(bytes32[] memory append_elements, bytes32[] memory proof)
        internal
        pure
        returns (bytes32, bytes32)
    {
        return get_roots_from_leafs_and_append_proof_multi_append(get_leafs_from_elements(append_elements), proof);
    }

    // Get the updated Element Merkle Root, given an append leaf and an Append Proof
    function get_new_root_from_leafs_and_append_proof_single_append(bytes32 append_leaf, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_hash)
    {
        uint256 proof_index = bit_count_32(uint32(uint256(proof[0])));
        append_hash = hash_node(proof[proof_index], append_leaf);

        while (proof_index > 1) {
            proof_index -= 1;
            append_hash = hash_node(proof[proof_index], append_hash);
        }
    }

    // Get the updated Element Merkle Root, given a bytes32 append elements in memory and an Append Proof
    function get_new_root_from_append_proof_single_append(bytes32 append_element, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_leaf)
    {
        append_leaf = keccak256(abi.encodePacked(bytes1(0), append_element));
        return get_new_root_from_leafs_and_append_proof_single_append(append_leaf, proof);
    }

    // Get the updated Element Merkle Root, given append leafs and an Append Proof
    function get_new_root_from_leafs_and_append_proof_multi_append(
        bytes32[] memory append_leafs,
        bytes32[] memory proof
    ) internal pure returns (bytes32) {
        uint256 leaf_count = append_leafs.length;
        uint256 write_index;
        uint256 read_index;
        uint256 offset = uint256(proof[0]);
        uint256 index = offset;

        // reuse leaf_count variable as upper_bound, since leaf_count no longer needed
        leaf_count += offset;
        leaf_count -= 1;
        uint256 proof_index = proof.length - 1;

        while (leaf_count > 0) {
            if ((write_index == 0) && (index & 1 == 1)) {
                append_leafs[0] = hash_node(proof[proof_index], append_leafs[read_index]);

                read_index += 1;
                proof_index -= 1;
                write_index = 1;
                index += 1;
            } else if (index < leaf_count) {
                append_leafs[write_index++] = hash_node(append_leafs[read_index++], append_leafs[read_index++]);

                index += 2;
            }

            if (index >= leaf_count) {
                if (index == leaf_count) {
                    append_leafs[write_index] = append_leafs[read_index];
                }

                read_index = 0;
                write_index = 0;
                leaf_count >>= 1;
                offset >>= 1;
                index = offset;
            }
        }

        return append_leafs[0];
    }

    // Get the updated Element Merkle Root, given bytes32 append elements in memory and an Append Proof
    function get_new_root_from_append_proof_multi_append(bytes32[] memory append_elements, bytes32[] memory proof)
        internal
        pure
        returns (bytes32)
    {
        return get_new_root_from_leafs_and_append_proof_multi_append(get_leafs_from_elements(append_elements), proof);
    }

    // Get the original Element Merkle Root and derive Append Proof, given an index, an append leaf, and a Single Proof
    function get_append_proof_from_leaf_and_single_proof(uint256 index, bytes32 leaf, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_hash, bytes32[] memory append_proof)
    {
        uint256 proof_index = proof.length - 1;
        uint256 append_node_index = uint256(proof[0]);
        uint256 upper_bound = append_node_index - 1;
        uint256 append_proof_index = bit_count_32(uint32(append_node_index)) + 1;
        append_proof = new bytes32[](append_proof_index);
        append_proof[0] = bytes32(append_node_index);
        bytes32 scratch;

        while (proof_index > 0) {
            if (index != upper_bound || (index & 1 == 1)) {
                scratch = proof[proof_index];

                leaf = (index & 1 == 1) ? hash_node(scratch, leaf) : hash_node(leaf, scratch);

                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;
                    append_proof[append_proof_index] = scratch;
                    append_hash = hash_node(scratch, append_hash);
                }

                proof_index -= 1;
            } else if (append_node_index & 1 == 1) {
                append_proof_index -= 1;
                append_proof[append_proof_index] = leaf;
                append_hash = leaf;
            }

            index >>= 1;
            upper_bound >>= 1;
            append_node_index >>= 1;
        }

        require(append_proof_index == 2 || append_hash == leaf, "INVALID_PROOF");

        if (append_proof_index == 2) {
            append_proof[1] = leaf;
        }
    }

    // Get the original Element Merkle Root and derive Append Proof, given an index, a bytes32 element, and a Single Proof
    function get_append_proof_from_single_proof(uint256 index, bytes32 element, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 leaf, bytes32[] memory)
    {
        leaf = keccak256(abi.encodePacked(bytes1(0), element));
        return get_append_proof_from_leaf_and_single_proof(index, leaf, proof);
    }

    // Get the original Element Merkle Root and derive Append Proof, given an index, a leaf, an update leaf, and a Single Proof
    function get_append_proof_from_leaf_and_single_proof_update(
        uint256 index,
        bytes32 leaf,
        bytes32 update_leaf,
        bytes32[] memory proof
    ) internal pure returns (bytes32 append_hash, bytes32[] memory append_proof) {
        uint256 proof_index = proof.length - 1;
        uint256 append_node_index = uint256(proof[0]);
        uint256 upper_bound = append_node_index - 1;
        uint256 append_proof_index = bit_count_32(uint32(append_node_index)) + 1;
        append_proof = new bytes32[](append_proof_index);
        append_proof[0] = bytes32(append_node_index);
        bytes32 scratch;

        while (proof_index > 0) {
            if (index != upper_bound || (index & 1 == 1)) {
                scratch = proof[proof_index];

                leaf = (index & 1 == 1) ? hash_node(scratch, leaf) : hash_node(leaf, scratch);

                update_leaf = (index & 1 == 1) ? hash_node(scratch, update_leaf) : hash_node(update_leaf, scratch);

                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;
                    append_proof[append_proof_index] = scratch;
                    append_hash = hash_node(scratch, append_hash);
                }

                proof_index -= 1;
            } else if (append_node_index & 1 == 1) {
                append_proof_index -= 1;
                append_proof[append_proof_index] = update_leaf;
                append_hash = leaf;
            }

            index >>= 1;
            upper_bound >>= 1;
            append_node_index >>= 1;
        }

        require(append_proof_index == 2 || append_hash == leaf, "INVALID_PROOF");

        if (append_proof_index == 2) {
            append_proof[1] = update_leaf;
        }
    }

    // Get the original Element Merkle Root and derive Append Proof,
    // given an index, a bytes32 element, a bytes32 update element, and a Single Proof
    function get_append_proof_from_single_proof_update(
        uint256 index,
        bytes32 element,
        bytes32 update_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 leaf, bytes32[] memory) {
        leaf = keccak256(abi.encodePacked(bytes1(0), element));
        bytes32 update_leaf = keccak256(abi.encodePacked(bytes1(0), update_element));
        return get_append_proof_from_leaf_and_single_proof_update(index, leaf, update_leaf, proof);
    }

    // Hashes leaf at read index and next index (circular) to write index
    function hash_within_leafs(
        bytes32[] memory leafs,
        uint256 write_index,
        uint256 read_index,
        uint256 leaf_count,
        bool order
    ) internal pure {
        leafs[write_index] = order
            ? hash_node(leafs[(read_index + 1) % leaf_count], leafs[read_index])
            : hash_node(leafs[read_index], leafs[(read_index + 1) % leaf_count]);
    }

    // Hashes value with leaf at read index to write index
    function hash_with_leafs(bytes32[] memory leafs, bytes32 value, uint256 write_index, uint256 read_index, bool order)
        internal
        pure
    {
        leafs[write_index] = order ? hash_node(leafs[read_index], value) : hash_node(value, leafs[read_index]);
    }

    // Get the original Element Merkle Root and derive Append Proof, given leafs and an Existence Multi Proof
    function get_append_proof_from_leafs_and_multi_proof(bytes32[] memory leafs, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_hash, bytes32[] memory append_proof)
    {
        uint256 leaf_count = leafs.length;
        uint256 read_index;
        uint256 write_index;
        uint256 proof_index = 4;
        uint256 append_node_index = uint256(proof[0]);
        uint256 append_proof_index = uint256(bit_count_32(uint32(append_node_index))) + 1;
        append_proof = new bytes32[](append_proof_index);
        append_proof[0] = bytes32(append_node_index);
        bytes32 bit_check = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 skips = proof[2];
        uint256 read_index_of_append_node;
        bool scratch;

        while (true) {
            if (skips & bit_check == bit_check) {
                if (proof[1] & bit_check == bit_check) {
                    read_index = (write_index == 0 ? leaf_count : write_index) - 1;

                    // reuse bit_check as scratch variable
                    bit_check = leafs[read_index];

                    require(append_proof_index == 2 || append_hash == bit_check, "INVALID_PROOF");

                    if (append_proof_index == 2) {
                        append_proof[1] = bit_check;
                    }

                    return (append_hash, append_proof);
                }

                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;
                    append_hash = leafs[read_index]; // TODO scratch this leafs[read_index] above
                    append_proof[append_proof_index] = leafs[read_index];
                }

                read_index_of_append_node = write_index;
                append_node_index >>= 1;

                leafs[write_index] = leafs[read_index];

                read_index = (read_index + 1) % leaf_count;
                write_index = (write_index + 1) % leaf_count;
                bit_check <<= 1;
                continue;
            }

            scratch = proof[1] & bit_check == bit_check;

            if (read_index_of_append_node == read_index) {
                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;

                    if (scratch) {
                        // reuse read_index_of_append_node as temporary scratch variable
                        read_index_of_append_node = (read_index + 1) % leaf_count;

                        append_hash = hash_node(leafs[read_index_of_append_node], append_hash);
                        append_proof[append_proof_index] = leafs[read_index_of_append_node];
                    } else {
                        append_hash = hash_node(proof[proof_index], append_hash);
                        append_proof[append_proof_index] = proof[proof_index];
                    }
                }

                read_index_of_append_node = write_index;
                append_node_index >>= 1;
            }

            if (scratch) {
                scratch = proof[3] & bit_check == bit_check;
                hash_within_leafs(leafs, write_index, read_index, leaf_count, scratch);
                read_index += 2;
            } else {
                scratch = proof[3] & bit_check == bit_check;
                hash_with_leafs(leafs, proof[proof_index], write_index, read_index, scratch);
                proof_index += 1;
                read_index += 1;
            }

            read_index %= leaf_count;
            write_index = (write_index + 1) % leaf_count;
            bit_check <<= 1;
        }
    }

    // Get the original Element Merkle Root and derive Append Proof, given bytes32 elements in memory and an Existence Multi Proof
    function get_append_proof_from_multi_proof(bytes32[] memory elements, bytes32[] memory proof)
        internal
        pure
        returns (bytes32, bytes32[] memory)
    {
        return get_append_proof_from_leafs_and_multi_proof(get_reversed_leafs_from_elements(elements), proof);
    }

    // Get combined current and update leafs from current bytes32 elements in memory and update bytes32 elements in memory, in reverse order
    function get_reversed_combined_leafs_from_current_and_update_elements(
        bytes32[] memory elements,
        bytes32[] memory update_elements
    ) internal pure returns (bytes32[] memory combined_leafs) {
        uint256 element_count = elements.length;
        require(update_elements.length == element_count, "LENGTH_MISMATCH");

        combined_leafs = new bytes32[](element_count << 1);
        // uint256 read_index = element_count - 1;
        // uint256 write_index;

        // while (write_index < element_count) {
        //     combined_leafs[write_index] = keccak256(abi.encodePacked(bytes1(0), elements[read_index]));
        //     combined_leafs[element_count + write_index] =
        //         keccak256(abi.encodePacked(bytes1(0), update_elements[read_index]));
        //     write_index += 1;
        //     read_index -= 1;
        // }

        for (uint64 i = 0; i < element_count; i++) {
            combined_leafs[i] = keccak256(abi.encodePacked(bytes1(0), elements[element_count - 1 - i]));
            combined_leafs[element_count + i] =
                keccak256(abi.encodePacked(bytes1(0), update_elements[element_count - 1 - i]));
        }
    }

    // Copy leaf and update leaf at read indices and to write indices
    function copy_within_combined_leafs(
        bytes32[] memory combined_leafs,
        uint256 write_index,
        uint256 read_index,
        uint256 leaf_count
    ) internal pure {
        combined_leafs[write_index] = combined_leafs[read_index];
        combined_leafs[leaf_count + write_index] = combined_leafs[leaf_count + read_index];
    }

    // Hashes leaf and update leaf at read indices and next indices (circular) to write indices
    function hash_within_combined_leafs(
        bytes32[] memory combined_leafs,
        uint256 write_index,
        uint256 read_index,
        uint256 leaf_count,
        bool order
    ) internal pure {
        uint256 scratch = (read_index + 1) % leaf_count;

        combined_leafs[write_index] = order
            ? hash_node(combined_leafs[scratch], combined_leafs[read_index])
            : hash_node(combined_leafs[read_index], combined_leafs[scratch]);

        combined_leafs[leaf_count + write_index] = order
            ? hash_node(combined_leafs[leaf_count + scratch], combined_leafs[leaf_count + read_index])
            : hash_node(combined_leafs[leaf_count + read_index], combined_leafs[leaf_count + scratch]);
    }

    // Hashes value with leaf and update leaf at read indices to write indices
    function hash_with_combined_leafs(
        bytes32[] memory combined_leafs,
        bytes32 value,
        uint256 write_index,
        uint256 read_index,
        uint256 leaf_count,
        bool order
    ) internal pure {
        combined_leafs[write_index] =
            order ? hash_node(combined_leafs[read_index], value) : hash_node(value, combined_leafs[read_index]);

        combined_leafs[leaf_count + write_index] = order
            ? hash_node(combined_leafs[leaf_count + read_index], value)
            : hash_node(value, combined_leafs[leaf_count + read_index]);
    }

    // Get the original Element Merkle Root and derive Append Proof, given combined leafs and update leafs and an Existence Multi Proof
    function get_append_proof_from_leafs_and_multi_proof_update(bytes32[] memory combined_leafs, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 append_hash, bytes32[] memory append_proof)
    {
        uint256 leaf_count = combined_leafs.length >> 1;
        uint256 read_index;
        uint256 write_index;
        uint256 read_index_of_append_node;
        uint256 proof_index = 4;
        uint256 append_node_index = uint256(proof[0]);
        uint256 append_proof_index = bit_count_32(uint32(append_node_index)) + 1;
        append_proof = new bytes32[](append_proof_index);
        append_proof[0] = bytes32(append_node_index);
        bytes32 bit_check = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bool scratch;

        while (true) {
            if (proof[2] & bit_check == bit_check) {
                if (proof[1] & bit_check == bit_check) {
                    read_index = (write_index == 0 ? leaf_count : write_index) - 1;

                    // reuse bit_check as scratch variable
                    bit_check = combined_leafs[read_index];

                    require(append_proof_index == 2 || append_hash == bit_check, "INVALID_PROOF");

                    if (append_proof_index == 2) {
                        append_proof[1] = combined_leafs[leaf_count + read_index];
                    }

                    return (bit_check, append_proof);
                }

                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;
                    append_hash = combined_leafs[read_index];
                    append_proof[append_proof_index] = combined_leafs[leaf_count + read_index];
                }

                read_index_of_append_node = write_index;
                append_node_index >>= 1;

                copy_within_combined_leafs(combined_leafs, write_index, read_index, leaf_count);

                read_index = (read_index + 1) % leaf_count;
                write_index = (write_index + 1) % leaf_count;
                bit_check <<= 1;
                continue;
            }

            scratch = proof[1] & bit_check == bit_check;

            if (read_index_of_append_node == read_index) {
                if (append_node_index & 1 == 1) {
                    append_proof_index -= 1;

                    if (scratch) {
                        // use read_index_of_append_node as temporary scratch
                        read_index_of_append_node = (read_index + 1) % leaf_count;

                        append_hash = hash_node(combined_leafs[read_index_of_append_node], append_hash);
                        append_proof[append_proof_index] = combined_leafs[leaf_count + read_index_of_append_node];
                    } else {
                        append_hash = hash_node(proof[proof_index], append_hash);
                        append_proof[append_proof_index] = proof[proof_index];
                    }
                }

                read_index_of_append_node = write_index;
                append_node_index >>= 1;
            }

            if (scratch) {
                scratch = proof[3] & bit_check == bit_check;

                hash_within_combined_leafs(combined_leafs, write_index, read_index, leaf_count, scratch);

                read_index += 2;
            } else {
                scratch = proof[3] & bit_check == bit_check;

                hash_with_combined_leafs(
                    combined_leafs, proof[proof_index], write_index, read_index, leaf_count, scratch
                );

                proof_index += 1;
                read_index += 1;
            }

            read_index %= leaf_count;
            write_index = (write_index + 1) % leaf_count;
            bit_check <<= 1;
        }
    }

    // Get the original Element Merkle Root and derive Append Proof,
    // given bytes32 elements in memory, bytes32 update elements in memory, and an Existence Multi Proof
    function get_append_proof_from_multi_proof_update(
        bytes32[] memory elements,
        bytes32[] memory update_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32, bytes32[] memory) {
        return get_append_proof_from_leafs_and_multi_proof_update(
            get_reversed_combined_leafs_from_current_and_update_elements(elements, update_elements), proof
        );
    }

    // INTERFACE: Check if bytes32 element exists at index, given a root and a Single Proof
    function element_exists(bytes32 root, uint256 index, bytes32 element, bytes32[] memory proof)
        internal
        pure
        returns (bool)
    {
        return hash_node(proof[0], get_root_from_single_proof(index, element, proof)) == root;
    }

    // INTERFACE: Check if bytes32 elements in memory exist, given a root and a Single Proof
    function elements_exist(bytes32 root, bytes32[] memory elements, bytes32[] memory proof)
        internal
        pure
        returns (bool)
    {
        return hash_node(proof[0], get_root_from_multi_proof(elements, proof)) == root;
    }

    // INTERFACE: Get the indices of the bytes32 elements in memory, given an Existence Multi Proof
    function get_indices(bytes32[] memory elements, bytes32[] memory proof) internal pure returns (uint256[] memory) {
        return get_indices_from_multi_proof(elements.length, proof[1], proof[2], proof[3]);
    }

    // INTERFACE: Check tree size, given a Size Proof
    function verify_size_with_proof(bytes32 root, uint256 size, bytes32[] memory proof) internal pure returns (bool) {
        if (root == bytes32(0) && size == 0) return true;

        return hash_node(bytes32(size), get_root_from_size_proof(size, proof)) == root;
    }

    // INTERFACE: Check tree size, given a the Element Merkle Root
    function verify_size(bytes32 root, uint256 size, bytes32 element_root) internal pure returns (bool) {
        if (root == bytes32(0) && size == 0) return true;

        return hash_node(bytes32(size), element_root) == root;
    }

    // INTERFACE: Try to update a bytes32 element, given a root, and index, an bytes32 element, and a Single Proof
    function try_update_one(
        bytes32 root,
        uint256 index,
        bytes32 element,
        bytes32 update_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 new_element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32 old_element_root;
        (old_element_root, new_element_root) = get_roots_from_single_proof_update(index, element, update_element, proof);

        require(hash_node(total_element_count, old_element_root) == root, "INVALID_PROOF");

        return hash_node(total_element_count, new_element_root);
    }

    // INTERFACE: Try to update bytes32 elements in memory, given a root, bytes32 elements in memory, and an Existence Multi Proof
    function try_update_many(
        bytes32 root,
        bytes32[] memory elements,
        bytes32[] memory update_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32 new_element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32 old_element_root;
        (old_element_root, new_element_root) = get_roots_from_multi_proof_update(elements, update_elements, proof);

        require(hash_node(total_element_count, old_element_root) == root, "INVALID_PROOF");

        return hash_node(total_element_count, new_element_root);
    }

    // INTERFACE: Try to append a bytes32 element, given a root and an Append Proof
    function try_append_one(bytes32 root, bytes32 append_element, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 new_element_root)
    {
        bytes32 total_element_count = proof[0];

        require((root == bytes32(0)) == (total_element_count == bytes32(0)), "INVALID_TREE");

        if (root == bytes32(0)) return hash_node(bytes32(uint256(1)), get_root_from_one(append_element));

        bytes32 old_element_root;
        (old_element_root, new_element_root) = get_roots_from_append_proof_single_append(append_element, proof);

        require(hash_node(total_element_count, old_element_root) == root, "INVALID_PROOF");

        return hash_node(bytes32(uint256(total_element_count) + 1), new_element_root);
    }

    // INTERFACE: Try to append bytes32 elements in memory, given a root and an Append Proof
    function try_append_many(bytes32 root, bytes32[] memory append_elements, bytes32[] memory proof)
        internal
        pure
        returns (bytes32 new_element_root)
    {
        bytes32 total_element_count = proof[0];

        require((root == bytes32(0)) == (total_element_count == bytes32(0)), "INVALID_TREE");

        if (root == bytes32(0)) {
            return hash_node(bytes32(append_elements.length), get_root_from_many(append_elements));
        }

        bytes32 old_element_root;
        (old_element_root, new_element_root) = get_roots_from_append_proof_multi_append(append_elements, proof);

        require(hash_node(total_element_count, old_element_root) == root, "INVALID_PROOF");

        return hash_node(bytes32(uint256(total_element_count) + append_elements.length), new_element_root);
    }

    // INTERFACE: Try to append a bytes32 element, given a root, an index, a bytes32 element, and a Single Proof
    function try_append_one_using_one(
        bytes32 root,
        uint256 index,
        bytes32 element,
        bytes32 append_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_single_proof(index, element, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_single_append(append_element, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + 1), element_root);
    }

    // INTERFACE: Try to append bytes32 elements in memory, given a root, an index, a bytes32 element, and a Single Proof
    function try_append_many_using_one(
        bytes32 root,
        uint256 index,
        bytes32 element,
        bytes32[] memory append_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_single_proof(index, element, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_multi_append(append_elements, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + append_elements.length), element_root);
    }

    // INTERFACE: Try to append a bytes32 element, given a root, bytes32 elements in memory, and an Existence Multi Proof
    function try_append_one_using_many(
        bytes32 root,
        bytes32[] memory elements,
        bytes32 append_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_multi_proof(elements, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_single_append(append_element, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + 1), element_root);
    }

    // INTERFACE: Try to append bytes32 elements in memory, given a root, bytes32 elements in memory, and an Existence Multi Proof
    function try_append_many_using_many(
        bytes32 root,
        bytes32[] memory elements,
        bytes32[] memory append_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_multi_proof(elements, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_multi_append(append_elements, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + append_elements.length), element_root);
    }

    // INTERFACE: Try to update a bytes32 element and append a bytes32 element,
    // given a root, an index, a bytes32 element, and a Single Proof
    function try_update_one_and_append_one(
        bytes32 root,
        uint256 index,
        bytes32 element,
        bytes32 update_element,
        bytes32 append_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_single_proof_update(index, element, update_element, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_single_append(append_element, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + 1), element_root);
    }

    // INTERFACE: Try to update a bytes32 element and append bytes32 elements in memory,
    // given a root, an index, a bytes32 element, and a Single Proof
    function try_update_one_and_append_many(
        bytes32 root,
        uint256 index,
        bytes32 element,
        bytes32 update_element,
        bytes32[] memory append_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_single_proof_update(index, element, update_element, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_multi_append(append_elements, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + append_elements.length), element_root);
    }

    // INTERFACE: Try to update bytes32 elements in memory and append a bytes32 element,
    // given a root, bytes32 elements in memory, and a Single Proof
    function try_update_many_and_append_one(
        bytes32 root,
        bytes32[] memory elements,
        bytes32[] memory update_elements,
        bytes32 append_element,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_multi_proof_update(elements, update_elements, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_single_append(append_element, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + 1), element_root);
    }

    // INTERFACE: Try to update bytes32 elements in memory and append bytes32 elements in memory,
    // given a root, bytes32 elements in memory, and an Existence Multi Proof
    function try_update_many_and_append_many(
        bytes32 root,
        bytes32[] memory elements,
        bytes32[] memory update_elements,
        bytes32[] memory append_elements,
        bytes32[] memory proof
    ) internal pure returns (bytes32 element_root) {
        bytes32 total_element_count = proof[0];

        require(root != bytes32(0) || total_element_count == bytes32(0), "EMPTY_TREE");

        bytes32[] memory append_proof;
        (element_root, append_proof) = get_append_proof_from_multi_proof_update(elements, update_elements, proof);

        require(hash_node(total_element_count, element_root) == root, "INVALID_PROOF");

        element_root = get_new_root_from_append_proof_multi_append(append_elements, append_proof);

        return hash_node(bytes32(uint256(total_element_count) + append_elements.length), element_root);
    }

    // INTERFACE: Create a tree and return the root, given a bytes32 element
    function create_from_one(bytes32 element) internal pure returns (bytes32 new_element_root) {
        return hash_node(bytes32(uint256(1)), get_root_from_one(element));
    }

    // INTERFACE: Create a tree and return the root, given bytes32 elements in memory
    function create_from_many(bytes32[] memory elements) internal pure returns (bytes32 new_element_root) {
        return hash_node(bytes32(elements.length), get_root_from_many(elements));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/DeserializationLib.sol";
import "../../libraries/MerkleLib.sol";
import "../../libraries/BytesLib.sol";
import "./OneStepProof.sol";

library MemoryLib {
    using BytesLib for bytes;

    function calcCellNum(uint64 offset, uint64 length) internal pure returns (uint64) {
        return (offset + length + 31) / 32 - offset / 32;
    }

    function getMemoryRoot(bytes memory content) internal pure returns (bytes32) {
        uint64 cellNum = MemoryLib.calcCellNum(0, uint64(content.length));
        bytes32[] memory elements = new bytes32[](cellNum);
        for (uint256 i = 0; i < cellNum - 1; i++) {
            elements[i] = content.toBytes32(i * 32);
        }
        elements[cellNum - 1] = content.toBytes32Pad((cellNum - 1) * 32);
        return MerkleLib.create_from_many(elements);
    }

    function decodeAndVerifyMemoryReadProof(
        OneStepProof.StateProof memory stateProof,
        bytes calldata encoded,
        uint64 offset,
        uint64 memoryOffset,
        uint64 memoryReadLength
    ) internal pure returns (uint64, bytes memory) {
        if (stateProof.memSize == 0 || memoryReadLength == 0) {
            return (offset, new bytes(memoryReadLength));
        }
        uint64 startCell = memoryOffset / 32;
        uint64 cellNum = calcCellNum(memoryOffset, memoryReadLength);
        uint64 memoryCell = calcCellNum(0, stateProof.memSize);
        OneStepProof.MemoryMerkleProof memory merkleProof;
        {
            if (memoryCell <= startCell) {
                cellNum += startCell - memoryCell;
                OneStepProof.MemoryAppendProof memory appendProof;
                (offset, appendProof) = OneStepProof.decodeMemoryAppendProof(encoded, offset, cellNum);
                (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
                stateProof.memRoot =
                    MerkleLib.try_append_many(stateProof.memRoot, appendProof.appendCells, merkleProof.proof);
                if (memoryOffset + memoryReadLength > stateProof.memSize) {
                    stateProof.memSize = (memoryOffset + memoryReadLength + 31) / 32 * 32; // Expand by words
                }
                bytes memory readContent = new bytes(memoryReadLength);
                return (offset, readContent);
            }
        }
        {
            if (memoryCell >= startCell + cellNum) {
                OneStepProof.MemoryReadProof memory readProof;
                (offset, readProof) = OneStepProof.decodeMemoryReadProof(encoded, offset, cellNum);
                (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
                if (cellNum == 1) {
                    MerkleLib.element_exists(stateProof.memRoot, startCell, readProof.cells[0], merkleProof.proof);
                    require(
                        MerkleLib.element_exists(stateProof.memRoot, startCell, readProof.cells[0], merkleProof.proof),
                        "IMP"
                    );
                } else {
                    {
                        // avoid stack too deep
                        uint256[] memory indices = MerkleLib.get_indices(readProof.cells, merkleProof.proof);
                        for (uint64 i = 0; i < cellNum; i++) {
                            require(indices[i] == startCell + i, "IMP");
                        }
                    }
                    MerkleLib.elements_exist(stateProof.memRoot, readProof.cells, merkleProof.proof);
                    require(MerkleLib.elements_exist(stateProof.memRoot, readProof.cells, merkleProof.proof), "IMP");
                }
                bytes memory readContent = abi.encodePacked(readProof.cells).slice(memoryOffset % 32, memoryReadLength);
                return (offset, readContent);
            }
        }
        uint64 existCellNum = memoryCell - startCell;
        OneStepProof.MemoryCombinedReadProof memory combinedReadProof;
        (offset, combinedReadProof) =
            OneStepProof.decodeMemoryCombinedReadProof(encoded, offset, existCellNum, cellNum - existCellNum);
        (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
        if (existCellNum == 1) {
            stateProof.memRoot = MerkleLib.try_append_many_using_one(
                stateProof.memRoot,
                startCell,
                combinedReadProof.cells[0],
                combinedReadProof.appendCells,
                merkleProof.proof
            );
        } else {
            {
                // avoid stack too deep
                uint256[] memory indices = MerkleLib.get_indices(combinedReadProof.cells, merkleProof.proof);
                for (uint64 i = 0; i < existCellNum; i++) {
                    require(indices[i] == startCell + i, "IMP");
                }
            }
            stateProof.memRoot = MerkleLib.try_append_many_using_many(
                stateProof.memRoot, combinedReadProof.cells, combinedReadProof.appendCells, merkleProof.proof
            );
        }
        if (memoryOffset + memoryReadLength > stateProof.memSize) {
            stateProof.memSize = (memoryOffset + memoryReadLength + 31) / 32 * 32; // Expand by words
        }
        bytes memory readContent = abi.encodePacked(combinedReadProof.cells, combinedReadProof.appendCells).slice(
            memoryOffset % 32, memoryReadLength
        );
        return (offset, readContent);
    }

    function decodeAndVerifyMemoryLikeReadProofNoAppend(
        bytes32 memoryLikeRoot,
        uint64 memoryLikeSize,
        bytes calldata encoded,
        uint64 offset,
        uint64 memoryLikeOffset,
        uint64 memoryLikeReadLength
    ) internal pure returns (uint64, bytes memory) {
        if (memoryLikeSize == 0 || memoryLikeReadLength == 0) {
            return (offset, new bytes(memoryLikeReadLength));
        }
        uint64 startCell = memoryLikeOffset / 32;
        uint64 cellNum = calcCellNum(memoryLikeOffset, memoryLikeReadLength);
        uint64 memoryCell = calcCellNum(0, memoryLikeSize);
        {
            if (memoryCell <= startCell) {
                bytes memory readContent;
                readContent = new bytes(memoryLikeReadLength);
                return (offset, readContent);
            }
        }
        {
            if (memoryCell >= startCell + cellNum) {
                bytes memory readContent;
                OneStepProof.MemoryReadProof memory readProof;
                OneStepProof.MemoryMerkleProof memory merkleProof;
                (offset, readProof) = OneStepProof.decodeMemoryReadProof(encoded, offset, cellNum);
                (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
                if (cellNum == 1) {
                    MerkleLib.element_exists(memoryLikeRoot, startCell, readProof.cells[0], merkleProof.proof);
                    require(
                        MerkleLib.element_exists(memoryLikeRoot, startCell, readProof.cells[0], merkleProof.proof),
                        "IMP"
                    );
                } else {
                    {
                        uint256[] memory indices = MerkleLib.get_indices(readProof.cells, merkleProof.proof);
                        for (uint64 i = 0; i < cellNum; i++) {
                            require(indices[i] == startCell + i, "IMP2");
                        }
                    }
                    MerkleLib.elements_exist(memoryLikeRoot, readProof.cells, merkleProof.proof);
                    require(MerkleLib.elements_exist(memoryLikeRoot, readProof.cells, merkleProof.proof), "IMP");
                }
                readContent = abi.encodePacked(readProof.cells).slice(memoryLikeOffset % 32, memoryLikeReadLength);
                return (offset, readContent);
            }
        }
        uint64 existCellNum = memoryCell - startCell;
        OneStepProof.MemoryReadProof memory readProof;
        OneStepProof.MemoryMerkleProof memory merkleProof;
        (offset, readProof) = OneStepProof.decodeMemoryReadProof(encoded, offset, existCellNum);
        (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
        if (existCellNum == 1) {
            MerkleLib.element_exists(memoryLikeRoot, startCell, readProof.cells[0], merkleProof.proof);
            require(MerkleLib.element_exists(memoryLikeRoot, startCell, readProof.cells[0], merkleProof.proof), "IMP");
        } else {
            {
                uint256[] memory indices = MerkleLib.get_indices(readProof.cells, merkleProof.proof);
                for (uint64 i = 0; i < cellNum; i++) {
                    require(indices[i] == startCell + i, "IMP");
                }
            }
            MerkleLib.elements_exist(memoryLikeRoot, readProof.cells, merkleProof.proof);
            require(MerkleLib.elements_exist(memoryLikeRoot, readProof.cells, merkleProof.proof), "IMP");
        }
        bytes memory padding = new bytes(32 * (cellNum - existCellNum));
        bytes memory readContent;
        readContent = abi.encodePacked(readProof.cells, padding).slice(memoryLikeOffset % 32, memoryLikeReadLength);
        return (offset, readContent);
    }

    function decodeAndVerifyMemoryWriteProof(
        OneStepProof.StateProof memory stateProof,
        bytes calldata encoded,
        uint64 offset,
        uint64 memoryOffset,
        uint64 memoryWriteLength
    ) internal pure returns (uint64, bytes memory) {
        if (memoryWriteLength == 0) {
            return (offset, new bytes(0));
        }
        if (stateProof.memSize == 0) {
            // Don't call decodeMemoryWriteProof if memory is empty
            // Instead, update memory root and size directly
            revert();
        }
        uint64 startCell = memoryOffset / 32;
        uint64 cellNum = calcCellNum(memoryOffset, memoryWriteLength);
        uint64 memoryCell = calcCellNum(0, stateProof.memSize);
        OneStepProof.MemoryMerkleProof memory merkleProof;

        {
            if (memoryCell <= startCell) {
                cellNum += startCell - memoryCell;
                OneStepProof.MemoryAppendProof memory appendProof;
                (offset, appendProof) = OneStepProof.decodeMemoryAppendProof(encoded, offset, cellNum);
                (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
                if (cellNum == 1) {
                    stateProof.memRoot =
                        MerkleLib.try_append_one(stateProof.memRoot, appendProof.appendCells[0], merkleProof.proof);
                } else {
                    stateProof.memRoot =
                        MerkleLib.try_append_many(stateProof.memRoot, appendProof.appendCells, merkleProof.proof);
                }
                if (memoryOffset + memoryWriteLength > stateProof.memSize) {
                    stateProof.memSize = (memoryOffset + memoryWriteLength + 31) / 32 * 32; // Expand by words
                }
                bytes memory writeContent =
                    abi.encodePacked(appendProof.appendCells).slice(memoryOffset % 32, memoryWriteLength);
                return (offset, writeContent);
            }
        }
        {
            if (memoryCell >= startCell + cellNum) {
                OneStepProof.MemoryWriteProof memory writeProof;
                (offset, writeProof) = OneStepProof.decodeMemoryWriteProof(encoded, offset, cellNum);
                (offset, merkleProof) = OneStepProof.decodeMemoryMerkleProof(encoded, offset);
                if (cellNum == 1) {
                    stateProof.memRoot = MerkleLib.try_update_one(
                        stateProof.memRoot,
                        startCell,
                        writeProof.cells[0],
                        writeProof.updatedCells[0],
                        merkleProof.proof
                    );
                } else {
                    {
                        // Avoid stack too deep
                        uint256[] memory indices = MerkleLib.get_indices(writeProof.cells, merkleProof.proof);
                        for (uint64 i = 0; i < cellNum; i++) {
                            require(indices[i] == startCell + i, "IMP");
                        }
                    }
                    stateProof.memRoot = MerkleLib.try_update_many(
                        stateProof.memRoot, writeProof.cells, writeProof.updatedCells, merkleProof.proof
                    );
                }
                bytes memory writeContent =
                    abi.encodePacked(writeProof.updatedCells).slice(memoryOffset % 32, memoryWriteLength);
                return (offset, writeContent);
            }
        }
        uint64 existCellNum = memoryCell - startCell;
        OneStepProof.MemoryCombinedWriteProof memory combinedWriteProof;
        (offset, combinedWriteProof) =
            OneStepProof.decodeMemoryCombinedWriteProof(encoded, offset, existCellNum, cellNum - existCellNum);
        if (cellNum == 1) {
            stateProof.memRoot = MerkleLib.try_update_one_and_append_many(
                stateProof.memRoot,
                startCell,
                combinedWriteProof.cells[0],
                combinedWriteProof.updatedCells[0],
                combinedWriteProof.appendCells,
                merkleProof.proof
            );
        } else {
            {
                // avoid stack too deep
                uint256[] memory indices = MerkleLib.get_indices(combinedWriteProof.cells, merkleProof.proof);
                for (uint64 i = 0; i < cellNum; i++) {
                    require(indices[i] == startCell + i, "IMP");
                }
            }
            stateProof.memRoot = MerkleLib.try_update_many_and_append_many(
                stateProof.memRoot,
                combinedWriteProof.cells,
                combinedWriteProof.updatedCells,
                combinedWriteProof.appendCells,
                merkleProof.proof
            );
        }
        if (memoryOffset + memoryWriteLength > stateProof.memSize) {
            stateProof.memSize = (memoryOffset + memoryWriteLength + 31) / 32 * 32; // Expand by words
        }
        bytes memory writeContent = abi.encodePacked(combinedWriteProof.updatedCells, combinedWriteProof.appendCells)
            .slice(memoryOffset % 32, memoryWriteLength);
        return (offset, writeContent);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/BytesLib.sol";
import "../../libraries/RLPReader.sol";
import "../../libraries/RLPWriter.sol";
import "./BloomLib.sol";

library EVMTypesLib {
    using BytesLib for bytes;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    struct BlockHeader {
        bytes32 parentHash;
        bytes32 ommerHash;
        address beneficiary;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptsRoot;
        uint256 difficulty;
        uint256 number;
        uint64 gasLimit;
        uint64 gasUsed;
        uint64 timestamp;
        BloomLib.Bloom logsBloom;
    }

    function hashBlockHeader(BlockHeader memory header) internal pure returns (bytes32) {
        bytes[] memory raw = new bytes[](15);
        raw[0] = RLPWriter.writeBytes(abi.encodePacked(header.parentHash));
        raw[1] = RLPWriter.writeBytes(abi.encodePacked(header.ommerHash));
        raw[2] = RLPWriter.writeAddress(header.beneficiary);
        raw[3] = RLPWriter.writeBytes(abi.encodePacked(header.stateRoot));
        raw[4] = RLPWriter.writeBytes(abi.encodePacked(header.transactionRoot));
        raw[5] = RLPWriter.writeBytes(abi.encodePacked(header.receiptsRoot));
        raw[6] = RLPWriter.writeBytes(abi.encodePacked(header.logsBloom.data));
        raw[7] = RLPWriter.writeUint(header.difficulty);
        raw[8] = RLPWriter.writeUint(header.number);
        raw[9] = RLPWriter.writeUint(uint256(header.gasLimit));
        raw[10] = RLPWriter.writeUint(uint256(header.gasUsed));
        raw[11] = RLPWriter.writeUint(uint256(header.timestamp));
        raw[12] = RLPWriter.writeBytes(""); // Extra
        raw[13] = RLPWriter.writeBytes(abi.encodePacked(bytes32(0))); // MixDigest
        raw[14] = RLPWriter.writeBytes(abi.encodePacked(bytes8(0))); // Nonce
        return keccak256(RLPWriter.writeList(raw));
    }

    struct Transaction {
        uint64 nonce;
        uint256 gasPrice;
        uint64 gas;
        address to;
        uint256 value;
        bytes data;
        uint256 v;
        uint256 r;
        uint256 s;
    }

    function decodeTransaction(bytes memory data) internal pure returns (Transaction memory transaction) {
        RLPReader.RLPItem[] memory decoded = data.toRlpItem().toList();
        transaction.nonce = uint64(decoded[0].toUint());
        transaction.gasPrice = decoded[1].toUint();
        transaction.gas = uint64(decoded[2].toUint());
        transaction.to = address(uint160(decoded[3].toUint()));
        transaction.value = decoded[4].toUint();
        transaction.data = decoded[5].toBytes();
        transaction.v = decoded[6].toUint();
        transaction.r = decoded[7].toUint();
        transaction.s = decoded[8].toUint();
    }

    function hashTransaction(Transaction memory txn) internal pure returns (bytes32) {
        bytes[] memory raw = new bytes[](9);
        raw[0] = RLPWriter.writeUint(uint256(txn.nonce));
        raw[1] = RLPWriter.writeUint(txn.gasPrice);
        raw[2] = RLPWriter.writeUint(uint256(txn.gas));
        raw[3] = RLPWriter.writeAddress(txn.to);
        raw[4] = RLPWriter.writeUint(txn.value);
        raw[5] = RLPWriter.writeBytes(txn.data);
        raw[6] = RLPWriter.writeUint(txn.v);
        raw[7] = RLPWriter.writeUint(txn.r);
        raw[8] = RLPWriter.writeUint(txn.s);
        return keccak256(RLPWriter.writeList(raw));
    }

    struct Account {
        uint64 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    function decodeAccount(RLPReader.RLPItem memory encoded) internal pure returns (Account memory proof) {
        RLPReader.RLPItem[] memory items = encoded.toList();
        require(items.length == 4, "Invalid Account");
        proof.nonce = uint64(items[0].toUint());
        proof.balance = items[1].toUint();
        proof.storageRoot = bytes32(items[2].toUint());
        proof.codeHash = bytes32(items[3].toUint());
    }

    function encodeRLP(Account memory account) internal pure returns (bytes memory) {
        bytes[] memory raw = new bytes[](4);
        raw[0] = RLPWriter.writeUint(uint256(account.nonce));
        raw[1] = RLPWriter.writeUint(account.balance);
        raw[2] = RLPWriter.writeBytes(abi.encodePacked(account.storageRoot));
        raw[3] = RLPWriter.writeBytes(abi.encodePacked(account.codeHash));
        return RLPWriter.writeList(raw);
    }

    function hashLogEntry(address addr, uint256[] memory topics, bytes memory data) internal pure returns (bytes32) {
        bytes[] memory topicRaw = new bytes[](topics.length);
        for (uint256 i = 0; i < topics.length; i++) {
            topicRaw[i] = RLPWriter.writeBytes(abi.encodePacked(bytes32(topics[i])));
        }
        bytes[] memory raw = new bytes[](3);
        raw[0] = RLPWriter.writeAddress(addr);
        raw[1] = RLPWriter.writeBytes(RLPWriter.writeList(topicRaw));
        raw[2] = RLPWriter.writeBytes(data);
        return keccak256(RLPWriter.writeList(raw));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/RLPReader.sol";
import "../../libraries/BytesLib.sol";
import "./BloomLib.sol";
import "./VerificationContext.sol";

library OneStepProof {
    using BytesLib for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;
    using VerificationContext for VerificationContext.Context;

    // [encode rule]
    struct StateProof {
        uint64 blockNumber; // Block number of current transaction [always]
        uint64 transactionIdx; // Transaction index in block [always]
        uint16 depth; // Current call depth [always]
        uint64 gas; // Gas left in the current call [always]
        uint64 refund; // Gas refund accumulated in the current transaction [always]
        bytes32 lastDepthHash; // The state hash of the last depth call frame [always]
        address contractAddress; // Current executing contract address [depth > 1]
        address caller; // Current caller [depth > 1]
        uint256 value; // Current call value [depth > 1]
        uint8 callFlag; // Current call type [depth > 1]
        uint64 out; // Offset of the return data of current call to be copied to the last depth call frame [depth > 1]
        uint64 outSize; // Size of the return data of current call to be copied to the last depth call frame [depth > 1]
        uint64 pc; // Current program counter [always]
        uint8 opCode; // Current opcode to be executed [always]
        bytes32 codeHash; // Current executing contract code hash [always]
        uint64 stackSize; // Size of the stack [always]
        bytes32 stackHash; // Commitment of the stack [always]
        uint64 memSize; // Size of the memory [always]
        bytes32 memRoot; // Commitment of the memory [memSize > 0]
        uint64 inputDataSize; // Size of the call data [depth > 1]
        bytes32 inputDataRoot; // Commitment of the return data [depth > 1 && inputDataSize > 0]
        uint64 returnDataSize; // Size of the return data [always]
        bytes32 returnDataRoot; // Commitment of the return data [returnDataSize > 0]
        bytes32 committedGlobalStateRoot; // Commitment of the global MPT state at the start of transaction [always]
        bytes32 globalStateRoot; // Commitment of the global MPT state [always]
        bytes32 selfDestructAcc; // Commitment of the self destructed contracts in the current transaction [always]
        bytes32 logAcc; // Commitment of the logs emitted in the current transaction [always]
        bytes32 blockHashRoot; // Commitment of the 256 previous blockhash in the current block [always]
        bytes32 accessListRoot; // Commitment of the access list in the current transaction [always]
    }

    function decodeStateProof(VerificationContext.Context memory ctx, bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, StateProof memory proof)
    {
        uint64 remainLength = uint64(encoded.length) - offset;
        uint64 stateProofLen = 323;
        require(remainLength >= stateProofLen, "Proof Underflow (State)");
        proof.blockNumber = encoded.toUint64(offset);
        proof.transactionIdx = encoded.toUint64(offset + 8);
        proof.depth = encoded.toUint16(offset + 16);
        proof.gas = encoded.toUint64(offset + 18);
        proof.refund = encoded.toUint64(offset + 26);
        proof.lastDepthHash = encoded.toBytes32(offset + 34);
        offset = offset + 66;
        if (proof.depth > 1) {
            stateProofLen += 97;
            require(remainLength >= stateProofLen, "Proof Underflow (State)");
            proof.contractAddress = encoded.toAddress(offset);
            proof.caller = encoded.toAddress(offset + 20);
            proof.value = encoded.toUint256(offset + 40);
            proof.callFlag = encoded.toUint8(offset + 72);
            proof.out = encoded.toUint64(offset + 73);
            proof.outSize = encoded.toUint64(offset + 81);
            offset += 89;
        } else {
            proof.contractAddress = ctx.getRecipient();
            proof.caller = ctx.getOrigin();
            proof.value = ctx.getValue();
            if (ctx.getRecipient() == address(0)) {
                proof.callFlag = 4;
            } else {
                proof.callFlag = 0;
            }
        }
        proof.pc = encoded.toUint64(offset);
        proof.opCode = encoded.toUint8(offset + 8);
        proof.codeHash = encoded.toBytes32(offset + 9);
        proof.stackSize = encoded.toUint64(offset + 41);
        offset += 49;
        if (proof.stackSize != 0) {
            stateProofLen += 32;
            require(remainLength >= stateProofLen, "Proof Underflow (State)");
            proof.stackHash = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.memSize = encoded.toUint64(offset);
        offset += 8;
        if (proof.memSize != 0) {
            stateProofLen += 32;
            require(remainLength >= stateProofLen, "Proof Underflow (State)");
            proof.memRoot = encoded.toBytes32(offset);
            offset += 32;
        }
        if (proof.depth > 1) {
            proof.inputDataSize = encoded.toUint64(offset);
            offset += 8;
            if (proof.inputDataSize != 0) {
                stateProofLen += 32;
                require(remainLength >= stateProofLen, "Proof Underflow (State)");
                proof.inputDataRoot = encoded.toBytes32(offset);
                offset += 32;
            }
        } else {
            proof.inputDataSize = ctx.getInputSize();
            proof.inputDataRoot = ctx.getInputRoot();
        }
        proof.returnDataSize = encoded.toUint64(offset);
        offset += 8;
        if (proof.returnDataSize != 0) {
            stateProofLen += 32;
            require(remainLength >= stateProofLen, "Proof Underflow (State)");
            proof.returnDataRoot = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.committedGlobalStateRoot = encoded.toBytes32(offset);
        proof.globalStateRoot = encoded.toBytes32(offset + 32);
        proof.selfDestructAcc = encoded.toBytes32(offset + 64);
        proof.logAcc = encoded.toBytes32(offset + 96);
        proof.blockHashRoot = encoded.toBytes32(offset + 128);
        proof.accessListRoot = encoded.toBytes32(offset + 160);
        return (offset + 192, proof);
    }

    function encodeStateProof(StateProof memory proof) internal pure returns (bytes memory encoded) {
        encoded = encoded.concat(abi.encodePacked(proof.blockNumber));
        encoded = encoded.concat(abi.encodePacked(proof.transactionIdx));
        encoded = encoded.concat(abi.encodePacked(proof.depth));
        encoded = encoded.concat(abi.encodePacked(proof.gas));
        encoded = encoded.concat(abi.encodePacked(proof.refund));
        encoded = encoded.concat(abi.encodePacked(proof.lastDepthHash));
        if (proof.depth > 1) {
            encoded = encoded.concat(abi.encodePacked(proof.contractAddress));
            encoded = encoded.concat(abi.encodePacked(proof.caller));
            encoded = encoded.concat(abi.encodePacked(proof.value));
            encoded = encoded.concat(abi.encodePacked(proof.callFlag));
            encoded = encoded.concat(abi.encodePacked(proof.out));
            encoded = encoded.concat(abi.encodePacked(proof.outSize));
        }
        encoded = encoded.concat(abi.encodePacked(proof.pc));
        encoded = encoded.concat(abi.encodePacked(proof.opCode));
        encoded = encoded.concat(abi.encodePacked(proof.codeHash));
        encoded = encoded.concat(abi.encodePacked(proof.stackSize));
        if (proof.stackSize != 0) {
            encoded = encoded.concat(abi.encodePacked(proof.stackHash));
        }
        encoded = encoded.concat(abi.encodePacked(proof.memSize));
        if (proof.memSize != 0) {
            encoded = encoded.concat(abi.encodePacked(proof.memRoot));
        }
        if (proof.depth > 1) {
            encoded = encoded.concat(abi.encodePacked(proof.inputDataSize));
            if (proof.inputDataSize != 0) {
                encoded = encoded.concat(abi.encodePacked(proof.inputDataRoot));
            }
        }
        encoded = encoded.concat(abi.encodePacked(proof.returnDataSize));
        if (proof.returnDataSize != 0) {
            encoded = encoded.concat(abi.encodePacked(proof.returnDataRoot));
        }
        encoded = encoded.concat(abi.encodePacked(proof.committedGlobalStateRoot));
        encoded = encoded.concat(abi.encodePacked(proof.globalStateRoot));
        encoded = encoded.concat(abi.encodePacked(proof.selfDestructAcc));
        encoded = encoded.concat(abi.encodePacked(proof.logAcc));
        encoded = encoded.concat(abi.encodePacked(proof.blockHashRoot));
        encoded = encoded.concat(abi.encodePacked(proof.accessListRoot));
    }

    function hashStateProof(StateProof memory proof) internal pure returns (bytes32) {
        if (proof.depth == 0) {
            // When returning/reverting from depth 1, we can't directly return an InterStateProof
            // Therefore we reuse some of the fields in the IntraStateProof to store an InterStateProof
            // The field mappings are as follows:
            InterStateProof memory interProof;
            interProof.blockNumber = proof.blockNumber;
            interProof.transactionIdx = proof.transactionIdx;
            interProof.globalStateRoot = proof.globalStateRoot;
            interProof.cumulativeGasUsed = proof.value;
            interProof.blockGasUsed = uint256(proof.lastDepthHash);
            interProof.blockHashRoot = proof.blockHashRoot;
            interProof.transactionTrieRoot = proof.selfDestructAcc;
            interProof.receiptTrieRoot = proof.logAcc;
            return hashInterStateProof(interProof);
        }
        return keccak256(encodeStateProof(proof));
    }

    struct InterStateProof {
        uint64 blockNumber;
        uint64 transactionIdx;
        bytes32 globalStateRoot;
        uint256 cumulativeGasUsed;
        uint256 blockGasUsed;
        bytes32 blockHashRoot;
        bytes32 transactionTrieRoot;
        bytes32 receiptTrieRoot;
        BloomLib.Bloom logsBloom;
    }

    function decodeInterStateProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, InterStateProof memory proof)
    {
        require(encoded.length - offset >= 464, "Proof Underflow (Inter)");
        proof.blockNumber = encoded.toUint64(offset);
        proof.transactionIdx = encoded.toUint64(offset + 8);
        proof.globalStateRoot = encoded.toBytes32(offset + 16);
        proof.cumulativeGasUsed = encoded.toUint64(offset + 48);
        proof.blockGasUsed = encoded.toUint64(offset + 80);
        proof.blockHashRoot = encoded.toBytes32(offset + 112);
        proof.transactionTrieRoot = encoded.toBytes32(offset + 144);
        proof.receiptTrieRoot = encoded.toBytes32(offset + 176);
        proof.logsBloom = BloomLib.decodeBloom(encoded, offset + 208);
        return (offset + 464, proof);
    }

    function encodeInterStateProof(InterStateProof memory proof) internal pure returns (bytes memory encoded) {
        encoded = encoded.concat(abi.encodePacked(proof.blockNumber));
        encoded = encoded.concat(abi.encodePacked(proof.transactionIdx));
        encoded = encoded.concat(abi.encodePacked(proof.globalStateRoot));
        encoded = encoded.concat(abi.encodePacked(proof.cumulativeGasUsed));
        encoded = encoded.concat(abi.encodePacked(proof.blockGasUsed));
        encoded = encoded.concat(abi.encodePacked(proof.blockHashRoot));
        encoded = encoded.concat(abi.encodePacked(proof.transactionTrieRoot));
        encoded = encoded.concat(abi.encodePacked(proof.receiptTrieRoot));
        encoded = encoded.concat(abi.encodePacked(proof.logsBloom.data));
    }

    function hashInterStateProof(InterStateProof memory proof) internal pure returns (bytes32) {
        return keccak256(encodeInterStateProof(proof));
    }

    struct BlockStateProof {
        uint64 blockNumber;
        bytes32 globalStateRoot;
        uint256 cumulativeGasUsed;
        bytes32 blockHashRoot;
    }

    function decodeBlockStateProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, BlockStateProof memory proof)
    {
        require(encoded.length - offset >= 104, "Proof Underflow (Block)");
        proof.blockNumber = encoded.toUint64(offset);
        proof.globalStateRoot = encoded.toBytes32(offset + 8);
        proof.cumulativeGasUsed = encoded.toUint64(offset + 40);
        proof.blockHashRoot = encoded.toBytes32(offset + 72);
        return (offset + 104, proof);
    }

    function encodeBlockStateProof(BlockStateProof memory proof) internal pure returns (bytes memory encoded) {
        encoded = encoded.concat(abi.encodePacked(proof.blockNumber));
        encoded = encoded.concat(abi.encodePacked(proof.globalStateRoot));
        encoded = encoded.concat(abi.encodePacked(proof.cumulativeGasUsed));
        encoded = encoded.concat(abi.encodePacked(proof.blockHashRoot));
    }

    function hashBlockStateProof(BlockStateProof memory proof) internal pure returns (bytes32) {
        return keccak256(encodeBlockStateProof(proof));
    }

    struct CodeProof {
        uint64 ptr;
        uint64 size;
    }

    function decodeCodeProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, CodeProof memory proof)
    {
        require(encoded.length - offset >= 8, "Proof Underflow (Code)");
        // Decode bytecode size in bytes
        uint64 contentSize = encoded.toUint64(offset);
        require(encoded.length - offset >= 8 + contentSize, "Proof Underflow (Code)");
        offset += 8;
        proof.ptr = offset;
        proof.size = contentSize;
        return (offset + contentSize, proof);
    }

    function getOpCodeAt(CodeProof memory proof, bytes calldata encoded, uint64 idx) internal pure returns (uint8) {
        if (idx >= proof.size) {
            return 0;
        }
        return uint8(encoded[proof.ptr + idx]);
    }

    function getCodeSlice(CodeProof memory proof, bytes calldata encoded, uint64 offset, uint64 size)
        internal
        pure
        returns (bytes memory)
    {
        if (offset + size > proof.size) {
            return encoded.slice(proof.ptr + offset, size).concat(new bytes(size - (proof.size - offset)));
        }
        return encoded.slice(proof.ptr + offset, size);
    }

    function hashCodeProof(CodeProof memory proof, bytes calldata encoded) internal pure returns (bytes32) {
        return keccak256(encoded[proof.ptr:proof.ptr + proof.size]);
    }

    struct StackProof {
        // The elements popped in the step
        uint256[] pops;
        // The stack hash after popping above elements
        bytes32 stackHashAfterPops;
    }

    function decodeStackProof(bytes calldata encoded, uint64 offset, uint64 popNum)
        internal
        pure
        returns (uint64, StackProof memory proof)
    {
        if (popNum == 0) {
            // No StackProof needed for popNum == 0
            return (offset, proof);
        }
        require(encoded.length - offset >= 32 * (popNum + 1), "Proof Underflow (Stack)");
        proof.pops = new uint256[](popNum);
        // Decode popped elements
        for (uint64 i = 0; i < popNum; i++) {
            proof.pops[i] = encoded.toUint256(offset);
            offset += 32;
        }
        // Decode stackHashAfterPops
        proof.stackHashAfterPops = encoded.toBytes32(offset);
        offset += 32;
        return (offset, proof);
    }

    function encodeStackProof(StackProof memory proof) internal pure returns (bytes memory encoded) {
        for (uint64 i = 0; i < proof.pops.length; i++) {
            encoded = encoded.concat(abi.encodePacked(proof.pops[i]));
        }
        encoded = encoded.concat(abi.encodePacked(proof.stackHashAfterPops));
    }

    struct MemoryMerkleProof {
        bytes32[] proof;
    }

    function decodeMemoryMerkleProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, MemoryMerkleProof memory proof)
    {
        require(encoded.length - offset >= 8, "Proof Underflow");
        uint64 len = encoded.toUint64(offset);
        offset += 8;
        require(encoded.length - offset >= 32 * len, "Proof Underflow");
        proof.proof = new bytes32[](len);
        for (uint64 i = 0; i < len; i++) {
            proof.proof[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct MemoryReadProof {
        bytes32[] cells;
    }

    function decodeMemoryReadProof(bytes calldata encoded, uint64 offset, uint64 cellNum)
        internal
        pure
        returns (uint64, MemoryReadProof memory proof)
    {
        require(encoded.length - offset >= 32 * cellNum, "Proof Underflow");
        proof.cells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.cells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct MemoryWriteProof {
        bytes32[] cells;
        bytes32[] updatedCells;
    }

    function decodeMemoryWriteProof(bytes calldata encoded, uint64 offset, uint64 cellNum)
        internal
        pure
        returns (uint64, MemoryWriteProof memory proof)
    {
        require(encoded.length - offset >= 64 * cellNum, "Proof Underflow");
        proof.cells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.cells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.updatedCells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.updatedCells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct MemoryAppendProof {
        bytes32[] appendCells;
    }

    function decodeMemoryAppendProof(bytes calldata encoded, uint64 offset, uint64 cellNum)
        internal
        pure
        returns (uint64, MemoryAppendProof memory proof)
    {
        require(encoded.length - offset >= 32 * cellNum, "Proof Underflow");
        proof.appendCells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.appendCells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct MemoryCombinedReadProof {
        bytes32[] cells;
        bytes32[] appendCells;
    }

    function decodeMemoryCombinedReadProof(bytes calldata encoded, uint64 offset, uint64 cellNum, uint64 appendCellNum)
        internal
        pure
        returns (uint64, MemoryCombinedReadProof memory proof)
    {
        require(encoded.length - offset >= 32 * (cellNum + appendCellNum), "Proof Underflow");
        proof.cells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.cells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.appendCells = new bytes32[](appendCellNum);
        for (uint64 i = 0; i < appendCellNum; i++) {
            proof.appendCells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct MemoryCombinedWriteProof {
        bytes32[] cells;
        bytes32[] updatedCells;
        bytes32[] appendCells;
    }

    function decodeMemoryCombinedWriteProof(bytes calldata encoded, uint64 offset, uint64 cellNum, uint64 appendCellNum)
        internal
        pure
        returns (uint64, MemoryCombinedWriteProof memory proof)
    {
        require(encoded.length - offset >= 32 * (2 * cellNum + appendCellNum), "Proof Underflow");
        proof.cells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.cells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.updatedCells = new bytes32[](cellNum);
        for (uint64 i = 0; i < cellNum; i++) {
            proof.updatedCells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        proof.appendCells = new bytes32[](appendCellNum);
        for (uint64 i = 0; i < appendCellNum; i++) {
            proof.appendCells[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    // For MPT proof, receipt proof
    struct RLPProof {
        RLPReader.RLPItem proof;
    }

    function decodeRLPProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, RLPProof memory proof)
    {
        require(encoded.length - offset >= 8, "Proof Underflow");
        uint64 len = encoded.toUint64(offset);
        offset += 8;
        require(encoded.length - offset >= len, "Proof Underflow");
        proof.proof = encoded.slice(offset, len).toRlpItem();
        return (offset + len, proof);
    }

    struct BlockHashProof {
        bytes32 blockHash;
    }

    function decodeBlockHashProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, BlockHashProof memory proof)
    {
        require(encoded.length - offset >= 32, "Proof Underflow");
        proof.blockHash = encoded.toBytes32(offset);
        return (offset + 32, proof);
    }

    struct BlockHashMerkleProof {
        uint64 path;
        bytes32[] proof;
    }

    function decodeBlockHashMerkleProof(bytes memory encoded, uint64 offset)
        internal
        pure
        returns (uint64, BlockHashMerkleProof memory proof)
    {
        require(encoded.length - offset >= 9, "Proof Underflow");
        proof.path = encoded.toUint64(offset);
        uint8 len = encoded.toUint8(offset + 8);
        offset += 9;
        require(encoded.length - offset >= 32 * len, "Proof Underflow");
        proof.proof = new bytes32[](len);
        for (uint64 i = 0; i < len; i++) {
            proof.proof[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return (offset, proof);
    }

    struct LogProof {
        bytes32 accumulateHash;
        BloomLib.Bloom bloom;
    }

    function decodeLogProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, LogProof memory proof)
    {
        require(encoded.length - offset >= 288, "Proof Underflow");
        proof.accumulateHash = encoded.toBytes32(offset);
        proof.bloom = BloomLib.decodeBloom(encoded, offset + 32);
        return (offset + 288, proof);
    }

    function hashLogProof(LogProof memory proof) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(proof.accumulateHash, proof.bloom.data));
    }

    struct SelfDestructSetProof {
        address[] contracts;
    }

    function decodeSelfDestructSetProof(bytes calldata encoded, uint64 offset)
        internal
        pure
        returns (uint64, SelfDestructSetProof memory proof)
    {
        require(encoded.length - offset >= 8, "Proof Underflow");
        uint64 len = encoded.toUint64(offset);
        offset += 8;
        require(encoded.length - offset >= 20 * len, "Proof Underflow");
        proof.contracts = new address[](len);
        for (uint64 i = 0; i < len; i++) {
            proof.contracts[i] = encoded.toAddress(offset);
            offset += 20;
        }
        return (offset, proof);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */

pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     * @return RLPItem of (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadToRlpItem(RLPItem memory item) internal pure returns (RLPItem memory) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return RLPItem(memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) {
            return false;
        }
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /**
     * RLPItem conversions into data types *
     */

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) { result := div(result, exp(256, sub(32, len))) }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (
            byte0 < LIST_SHORT_START // being explicit
        ) {
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/BytesLib.sol";

library BloomLib {
    using BytesLib for bytes;

    struct Bloom {
        bytes32[8] data;
    }

    function emptyBloom() internal pure returns (Bloom memory b) {
        return b;
    }

    function decodeBloom(bytes calldata encoded, uint64 offset) internal pure returns (Bloom memory) {
        Bloom memory bloom;
        for (uint256 i = 0; i < 8; i++) {
            bloom.data[i] = encoded.toBytes32(offset);
            offset += 32;
        }
        return bloom;
    }

    function addHash(Bloom memory bloom, bytes32 h) internal pure {
        uint16 i1 = 255 - (uint16(uint256(h) >> 240) & 0x7ff) >> 3;
        uint8 v1 = uint8(1 << (uint8(h[1]) & 0x7));
        bloom.data[i1 >> 5] = bytes32(uint256(bloom.data[i1 >> 5]) | (uint256(v1) << 8 * (31 - (i1 & 0x1f))));
        uint16 i2 = 255 - (uint16(uint256(h) >> 224) & 0x7ff) >> 3;
        uint8 v2 = uint8(1 << (uint8(h[3]) & 0x7));
        bloom.data[i2 >> 5] = bytes32(uint256(bloom.data[i2 >> 5]) | (uint256(v2) << 8 * (31 - (i2 & 0x1f))));
        uint16 i3 = 255 - (uint16(uint256(h) >> 208) & 0x7ff) >> 3;
        uint8 v3 = uint8(1 << (uint8(h[5]) & 0x7));
        bloom.data[i3 >> 5] = bytes32(uint256(bloom.data[i3 >> 5]) | (uint256(v3) << 8 * (31 - (i3 & 0x1f))));
    }

    function add(Bloom memory bloom, bytes memory data) internal pure {
        bytes32 h;
        assembly {
            h := keccak256(add(data, 0x20), mload(data))
        }
        addHash(bloom, h);
    }

    function add(Bloom memory bloom, address data) internal pure {
        bytes32 h = keccak256(abi.encodePacked(data));
        addHash(bloom, h);
    }

    function add(Bloom memory bloom, bytes32 data) internal pure {
        bytes32 h = keccak256(abi.encodePacked(data));
        addHash(bloom, h);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:attribution https://github.com/bakaoh/solidity-rlp-encode
 * @title RLPWriter
 * @author RLPWriter is a library for encoding Solidity types to RLP bytes. Adapted from Bakaoh's
 *         RLPEncode library (https://github.com/bakaoh/solidity-rlp-encode) with minor
 *         modifications to improve legibility.
 */
library RLPWriter {
    /**
     * @notice RLP encodes a byte string.
     *
     * @param _in The byte string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * @notice RLP encodes a list of RLP encoded byte byte strings.
     *
     * @param _in The list of RLP encoded byte strings.
     *
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * @notice RLP encodes a string.
     *
     * @param _in The string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * @notice RLP encodes an address.
     *
     * @param _in The address to encode.
     *
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * @notice RLP encodes a uint.
     *
     * @param _in The uint256 to encode.
     *
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * @notice RLP encodes a bool.
     *
     * @param _in The bool to encode.
     *
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /**
     * @notice Encode the first byte and then the `len` in binary form if `length` is more than 55.
     *
     * @param _len    The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     *
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256 ** (lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes.
     *
     * @param _x The integer to encode.
     *
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * @custom:attribution https://github.com/Arachnid/solidity-stringutils
     * @notice Copies a piece of memory to another location.
     *
     * @param _dest Destination location.
     * @param _src  Source location.
     * @param _len  Length of memory to copy.
     */
    function _memcpy(uint256 _dest, uint256 _src, uint256 _len) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @custom:attribution https://github.com/sammayo/solidity-rlp-encoder
     * @notice Flattens a list of byte strings into one byte string.
     *
     * @param _list List of byte strings to flatten.
     *
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}