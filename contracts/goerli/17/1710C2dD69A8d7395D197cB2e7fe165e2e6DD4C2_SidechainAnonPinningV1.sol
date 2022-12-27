/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;


/**
 * Contract to manage multiple sidechains.
 *
 * _Masked and Unmasked Participants_
 * For each sidechain, there are masked and unmasked participants. Unmasked Participants have their
 * addresses listed as being members of the sidechain. Being unmasked allows the participant
 * to vote to add and remove other participants and contest pins.
 *
 * Masked Participants are participants which are listed against a sidechain. They are represented
 * as a salted hash of their address. The participant keeps the salt secret and keeps it off-chain.
 * If they need to unmask themselves, they present their secret salt. This is combined with their
 * sending address to create the salted hash. If this matches their masked participant value then
 * they become an unmasked participant.
 *
 * _Voting_
 * Voting works in the following way:
 * - An Unmasked Participant of a sidechain can submit a proposal for a vote for a certain action
 *  (VOTE_REMOVE_MASKED_PARTICIPANT,VOTE_ADD_UNMASKED_PARTICIPANT, VOTE_REMOVE_UNMASKED_PARTICIPANT,
 *  VOTE_CONTEST_PIN).
 * - Any other Unmasked Participant can then vote on the proposal.
 * - Once the voting period has expired, any Unmasked Participant can request the vote be actioned.
 *
 * The voting algorithm and voting period are configurable and set on a per-sidechain basis at time of
 * construction.
 *
 * _Management Pseudo Chain_
 * In addition to the normal sidechains, there is a Management Pseudo Chain (sidechain ID 0x00). This
 * sidechain is automatically created at contract deployment time. Any unmasked participant of this
 * sidechain can add a new sidechain.
 *
 * _Pinning_
 * Pinning values are put into a map. All participants of a sidechain agree on a sidechain secret
 * and a Pseudo Random Function (PRF) algorithm. The sidechain secret seeds the PRF. A new 256 bit value is
 * generated each time an uncontested pin is posted. The key in the map is calculated using the
 * equation:
 *
 * PRF_Value = PRF.nextValue
 * Key = keccak256(Sidechain Identifier, Previous Pin, PRF_Value).
 *
 * For the initial key for a sidechain, the Previous Pin is 0x00.
 *
 * Masked and unmasked participants of a sidechain observe the pinning map at the Key value waiting
 * for the next pin to be posted to that entry in the map. When the pin value is posted, they can then
 * determine if they wish to contest the pin. To contest the pin, they submit:
 *
 * Previous Key (and hence the previous pin)
 * PRF_Value
 * Sidechain Id
 *
 * Given they know the valid PRF Value, they are able to contest the pin, because they must be a member of the
 * sidechain. Given a good PRF algorithm, this will not expose future or previous PRF values, and hence will
 * not reveal earlier or future pinning values, and hence won't reveal the transaction rate of the sidechain.
 *
 * Once a key is revealed as belonging to a specific sidechain, then Unmasked Participants can vote on
 * whether to reject or keep the pin.
 *
 *
 */
interface SidechainAnonPinningInterface {

    /**
     * Add a sidechain to be managed.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _votingPeriod The number of blocks by which time a vote must be finalized.
     * @param _votingAlgorithmContract The address of the initial contract to be used for all votes.
     */
    function addSidechain(uint256 _sidechainId, address _votingAlgorithmContract, uint64 _votingPeriod) external;


    /**
     * Convert from being a masked to an unmasked participant. The participant themselves is the only
     * entity which can do this change.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain masked participants.
     */
    function unmask(uint256 _sidechainId, uint256 _index, uint256 _salt) external;

    /**
     * Propose that a certain action be voted on.
     * The message sender must be an unmasked member of the sidechain.
     *
     * Types of votes:
     *
     * Value  Action                                 _target                                 _additionalInfo1                 _additionalInfo2
     * 1      Vote to add a masked participant.      Salted Hash of participant's address    Not used                         Not used
     * 2      Vote to remove a masked participant    Salted Hash of participant's address    Index into array of participant  Not used
     * 3      Vote to add an unmasked participant    Address of proposed participant         Not used                         Not used
     * 4      Vote to remove an unmasked participant Address of participant                  Index into array of participant  Not used.
     * 5      Contest pin.                           Pin key                                 Previous pin key                 PRF value.
     *
     * Note for contest a pin: The message sender must be be able to produce information to demonstrate that the
     * contested pin is part of the sidechain by submitting the previous pin key, the current pin key,
     * and a PRF value. Given how the keys are created, this proves that the previous and the current key are linked,
     * which proves that the current pin key is part of the sidechain.
     *
     * The keys must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, PRF Value)
     *
     * Where the PRF Value is the next value to be calculated, based on a shared secret seed off-chain, and the number
     * of values which have been generated.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _action The type of vote: add or remove a masked or unmasked participant, challenge a pin.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     * @param _additionalInfo1 See above.
     * @param _additionalInfo2 See above.
     */
    function proposeVote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, uint256 _additionalInfo1, uint256 _additionalInfo2) external;

    /**
     * Vote for a proposal.
     *
     * If an account has already voted, they can not vote again or change their vote.
     * Only members of the sidechain can vote.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _action The type of vote: add or remove a masked or unmasked participant, challenge a pin.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     * @param _voteFor True if the transaction sender wishes to vote for the action.
     */
    function vote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _voteFor) external;

    /**
     * Vote for a proposal.
     *
     * If an account has already voted, they can vote again to change their vote.
     * Only members of the sidechain can action votes.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     */
    function actionVotes(uint256 _sidechainId, uint256 _voteTarget) external;



    /**
     * Add a pin to the pinning map. The key must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, DRBG Value)
     *
     * Where the DRBG Value is the next value to be calculated, based on a shared secret seed
     * off-chain, and the number of values which have been generated.
     *
     *
     * @param _pinKey The pin key calculated as per the equation above.
     * @param _pin Value to be associated with the key.
     */
    function addPin(uint256 _pinKey, bytes32 _pin) external;


    /**
     * Get the pin value for a certain key. The key must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, DRBG Value)
     *
     * Where the DRBG Value is the next value to be calculated, based on a shared secret seed
     * off-chain, and the number of values which have been generated.
     *
     *
     * @param _pinKey The pin key calculated as per the equation above.
     * @return The pin at the key.
     */
    function getPin(uint256 _pinKey) external view returns (bytes32);




    /**
     * Indicate if this contract manages a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return true if the sidechain is managed by this contract.
    */
    function getSidechainExists(uint256 _sidechainId) external view returns (bool);

    /**
     * Get the voting period being used in a sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return Length of voting period in blocks.
     */
    function getVotingPeriod(uint256 _sidechainId) external view returns (uint64);

    /**
     * Indicate if a certain account is an unmasked participant of a sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _participant Account to check to see if it is a participant.
     * @return true if _participant is an unmasked member of the sidechain.
     */
    function isSidechainParticipant(uint256 _sidechainId, address _participant) external view returns(bool);

    /**
     * Get the length of the masked sidechain participants array for a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return number of unmasked sidechain participants.
     */
    function getUnmaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256);

    /**
     * Get address of a certain unmasked sidechain participant. If the participant has been removed
     * at the given index, this function will return the address 0x00.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain participants.
     * @return Address of the participant, or 0x00.
     */
    function getUnmaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(address);

    /**
     * Get the length of the masked sidechain participants array for a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return length of the masked sidechain participants array.
     */
    function getMaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256);

    /*
     * Get the salted hash of a masked sidechain participant. If the participant has been removed
     * or has been unmasked, at the given index, this function will return 0x00.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain masked participants.
     * @return Salted hash or the participant's address, or 0x00.
     */
    function getMaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(uint256);

    /*
     * Return the number of blocks between when a pin is posted and when it can be contested.
     */
    function getPinDisputePeriod() external view returns (uint32);



    event AddedSidechain(uint256 _sidechainId);
    event AddingSidechainMaskedParticipant(uint256 _sidechainId, bytes32 _participant);
    event AddingSidechainUnmaskedParticipant(uint256 _sidechainId, address _participant);

    event ParticipantVoted(uint256 _sidechainId, address _participant, uint16 _action, uint256 _voteTarget, bool _votedFor);
    event VoteResult(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _result);

    event Dump1(uint256 a, uint256 b, address c);
    event Dump2(uint256 a, uint256 b, uint256 c);

}

/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;

import "./SidechainAnonPinningInterface.sol";
import "./VotingAlgInterface.sol";


/**
 * Contract to manage multiple sidechains.
 *
 * Please see the interface for documentation on all topics except for the constructor.
 *
 */
contract SidechainAnonPinningV1 is SidechainAnonPinningInterface {
    // The management sidechain is the sidechain with ID 0x00. It is used solely to restrict which
    // users can create a new sidechain. Only members of this sidechain can call addSidechain().
    uint256 public constant MANAGEMENT_PSEUDO_SIDECHAIN_ID = 0;

    // This PIN value is used to indicate that a PIN was contested and rejected.
    bytes32 private constant REMOVED_PIN = "\x01";
    // This PIN value is used to indicate that no PIN exists at the given MapKey.
    bytes32 private constant EMPTY_PIN = 0x00;

    // Indications that a vote is underway.
    // VOTE_NONE indicates no vote is underway. Also matches the deleted value for integers.
    enum VoteType {
        VOTE_NONE,                          // 0: MUST be the first value so it is the zero / deleted value.
        VOTE_ADD_MASKED_PARTICIPANT,        // 1
        VOTE_REMOVE_MASKED_PARTICIPANT,     // 2
        VOTE_ADD_UNMASKED_PARTICIPANT,      // 3
        VOTE_REMOVE_UNMASKED_PARTICIPANT,   // 4
        VOTE_CONTEST_PIN                    // 5
    }

    struct Votes {
        // The type of vote being voted on.
        VoteType voteType;
        // The block number when voting will cease.
        uint endOfVotingBlockNumber;
        // Additional info contain additional values which are type
        // of vote specific.
        uint256 additionalInfo1;
        uint256 additionalInfo2;

        // Have map as well as array to ensure constant time / constant cost look-up,
        // independent of number of participants.
        mapping(address=>bool) hasVoted;
        // The number of participants who voted for the proposal.
        uint64 numVotedFor;
        // The number of participants who voted against the proposal.
        uint64 numVotedAgainst;
    }

    struct SidechainRecord {
        // The algorithm for assessing the votes.
        address votingAlgorithmContract;
        // Voting period in blocks. This is the period in which participants can vote. Must be greater than 0.
        uint64 votingPeriod;

        // The number of unmasked participants.
        // Note that this value could be less than the size of the unmasked array as some of the participants
        // may have been removed.
        uint64 numUnmaskedParticipants;
        // Array of participants who can vote.
        // Note that this array could contain empty values, indicating that the participant has been removed.
        address[] unmasked;
        // Have map as well as array to ensure constant time / constant cost look-up, independent of number of participants.
        mapping(address=>bool) inUnmasked;

        // Array of masked participant. These participants can not vote.
        // Note that this array could contain empty values, indicating that the masked participant has been removed
        // or has been unmasked.
        uint256[] masked;
        // Have map as well as array to ensure constant time / constant cost look-up, independent of number of participants.
        mapping(uint256=>bool) inMasked;

        // Votes for adding and removing participants, for changing voting algorithm and voting period.
        mapping(uint256=>Votes) votes;
    }

    mapping(uint256=>SidechainRecord) private sidechains;


    struct Pins {
        // The block hash which is being pinned.
        bytes32 pin;
        // The block number after which the pin can not be challenged.
        uint256 contestBlockNumber;
    }
    mapping(uint256=>Pins) private pinningMap;

    // Number of blocks after a pin is posted that it can be disputed in. Must be greater than
    // the voting period because voting on contested pins must be actioned prior to the end
    // of the pin dispute period.
    // This value is used for all pins in the contract.
    uint32 private pinDisputePeriod;




    /**
     * Function modifier to ensure only unmasked sidechain participants can call the function.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @dev Throws if the message sender isn't a participant in the sidechain, or if the sidechain doesn't exist.
     */
    modifier onlySidechainParticipant(uint256 _sidechainId) {
        require(sidechains[_sidechainId].inUnmasked[msg.sender], "Sender is not a participant");
        _;
    }

    /**
     * Set the management pseudo chain configuration and global configuration.
     *
     * @param _votingAlg Management pseudo chain voting algorithm.
     * @param _votingPeriod Management pseudo chain voting period in blocks.
     * @param _pinDisputePeriod Number of block between when a pin is posted and when it can be challenged.
     *  Note that this must be greater than the voting period on the sidechain, otherwise participants will
     *  not be able to vote and action votes to reject the pin within the voting period.
     */
    constructor (address _votingAlg, uint32 _votingPeriod, uint32 _pinDisputePeriod) {
        addSidechainInternal(MANAGEMENT_PSEUDO_SIDECHAIN_ID, _votingAlg, _votingPeriod);
        pinDisputePeriod = _pinDisputePeriod;
    }


    function addSidechain(uint256 _sidechainId, address _votingAlgorithmContract, uint64 _votingPeriod) external onlySidechainParticipant(MANAGEMENT_PSEUDO_SIDECHAIN_ID) {
        addSidechainInternal(_sidechainId, _votingAlgorithmContract, _votingPeriod);
    }

    function addSidechainInternal(uint256 _sidechainId, address _votingAlgorithmContract, uint64 _votingPeriod) private {
        // The sidechain can not exist prior to creation.
        require(sidechains[_sidechainId].votingPeriod == 0);
        // The voting period must be greater than 0.
        require(_votingPeriod != 0);
        emit AddedSidechain(_sidechainId);

        // Create the entry in the map by assigning values to the structure.
        sidechains[_sidechainId].votingPeriod = _votingPeriod;
        sidechains[_sidechainId].votingAlgorithmContract = _votingAlgorithmContract;

        // The creator of the sidechain is always an unmasked participant. Anyone who analysed the
        // transaction history would be able determine this account as the one which instigated the
        // transaction.
        sidechains[_sidechainId].unmasked.push(msg.sender);
        sidechains[_sidechainId].inUnmasked[msg.sender] = true;
        sidechains[_sidechainId].numUnmaskedParticipants++;
    }


    function unmask(uint256 _sidechainId, uint256 _index, uint256 _salt) external {
        uint256 maskedParticipantActual = sidechains[_sidechainId].masked[_index];
        uint256 maskedParticipantCalculated = uint256(keccak256(abi.encodePacked(msg.sender, _salt)));
        // An account can only unmask itself.
        require(maskedParticipantActual == maskedParticipantCalculated);
        // If the unmasked participant already exists, then remove the participant
        // from the masked list and don't add it to the unmasked list.
        if (sidechains[_sidechainId].inUnmasked[msg.sender] == false) {
            emit AddingSidechainUnmaskedParticipant(_sidechainId, msg.sender);
            sidechains[_sidechainId].unmasked.push(msg.sender);
            sidechains[_sidechainId].inUnmasked[msg.sender] = true;
            sidechains[_sidechainId].numUnmaskedParticipants++;
        }
        delete sidechains[_sidechainId].masked[_index];
        delete sidechains[_sidechainId].inMasked[maskedParticipantActual];
    }


    function proposeVote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, uint256 _additionalInfo1, uint256 _additionalInfo2) external onlySidechainParticipant(_sidechainId) {
        // This will throw an error if the action is not a valid VoteType.
        VoteType action = VoteType(_action);

        // Can't start a vote if a vote is already underway.
        require(sidechains[_sidechainId].votes[_voteTarget].voteType == VoteType.VOTE_NONE, "Vote is already underway");

        // If the action is to add a masked participant, then they shouldn't be a participant already.
        if (action == VoteType.VOTE_ADD_MASKED_PARTICIPANT) {
            require(sidechains[_sidechainId].inMasked[_voteTarget] == false, "Masked participant is already a participant");
        }
        // If the action is to remove a masked participant, then they should be a participant already.
        // Additionally, they must supply the offset into the masked array of the participant to be removed.
        if (action == VoteType.VOTE_REMOVE_MASKED_PARTICIPANT) {
            require(sidechains[_sidechainId].inMasked[_voteTarget] == true, "Not a participant");
            require(sidechains[_sidechainId].masked[_additionalInfo1] == _voteTarget);
        }
        // If the action is to add an unmasked participant, then they shouldn't be a participant already.
        if (action == VoteType.VOTE_ADD_UNMASKED_PARTICIPANT) {
            require(sidechains[_sidechainId].inUnmasked[address(uint160(_voteTarget))] == false, "Unmasked participant is already a participant");
        }
        // If the action is to remove an unmasked participant, then they should be a participant
        // already and they can not be the sender. That is, the sender can not vote to remove
        // themselves.
        // Additionally, they must supply the offset into the unmasked array of the participant to be removed.
        if (action == VoteType.VOTE_REMOVE_UNMASKED_PARTICIPANT) {
            address voteTargetAddr = address(uint160(_voteTarget));
            require(sidechains[_sidechainId].inUnmasked[voteTargetAddr] == true);
            require(voteTargetAddr != msg.sender);
            require(sidechains[_sidechainId].unmasked[_additionalInfo1] == voteTargetAddr);
        }

        if (action == VoteType.VOTE_CONTEST_PIN) {
            uint256 pinKey = _voteTarget;
            uint256 previousPinKey = _additionalInfo1;
            uint256 prfValue = _additionalInfo2;

            // The current pin key must have a pin entry.
            require(pinningMap[pinKey].pin != EMPTY_PIN, "Current pin key has no pin entry");
            // The current pin key must still be able to be contested.
            require(pinningMap[pinKey].contestBlockNumber > block.number, "Current pin key cannot be contested anymore");


            bytes32 prevPin = pinningMap[previousPinKey].pin;
            // The previous pin key must have a pin entry.
            require(prevPin != EMPTY_PIN, "Previous pin key must have a pin entry");

            // Check that the calculation is correct, proving the transaction sender knows the
            // PRF value, and hence should be a member of the sidechain.
            uint256 calculatedPinKey = uint256(keccak256(abi.encodePacked(_sidechainId, prevPin, prfValue)));
            require(calculatedPinKey == pinKey , "calculated pin key doesnt match pin key");
        }


        // Set-up the vote.
        sidechains[_sidechainId].votes[_voteTarget].voteType = action;
        sidechains[_sidechainId].votes[_voteTarget].endOfVotingBlockNumber = block.number + sidechains[_sidechainId].votingPeriod;
        sidechains[_sidechainId].votes[_voteTarget].additionalInfo1 = _additionalInfo1;
        sidechains[_sidechainId].votes[_voteTarget].additionalInfo2 = _additionalInfo2;

        // The proposer is deemed to be voting for the proposal.
        voteNoChecks(_sidechainId, _action, _voteTarget, true);
    }


    function vote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _voteFor) external onlySidechainParticipant(_sidechainId) {
        // This will throw an error if the action is not a valid VoteType.
        VoteType action = VoteType(_action);

        // The type of vote must match what is currently being voted on.
        // Note that this will catch the case when someone is voting when there is no active vote.
        require(sidechains[_sidechainId].votes[_voteTarget].voteType == action);
        // Ensure the account has not voted yet.
        require(sidechains[_sidechainId].votes[_voteTarget].hasVoted[msg.sender] == false);

        // Check voting period has not expired.
        require(sidechains[_sidechainId].votes[_voteTarget].endOfVotingBlockNumber >= block.number);

        voteNoChecks(_sidechainId, _action, _voteTarget, _voteFor);
    }


    function actionVotes(uint256 _sidechainId, uint256 _voteTarget) external onlySidechainParticipant(_sidechainId) {
        // If no vote is underway, then there is nothing to action.
        VoteType action = sidechains[_sidechainId].votes[_voteTarget].voteType;
        require(action != VoteType.VOTE_NONE, "no vote is underway");
        // Can only action vote after voting period has ended.
        require(sidechains[_sidechainId].votes[_voteTarget].endOfVotingBlockNumber < block.number, "voting period has not ended yet");

        VotingAlgInterface voteAlg = VotingAlgInterface(sidechains[_sidechainId].votingAlgorithmContract);
        bool result = voteAlg.assess(
                sidechains[_sidechainId].numUnmaskedParticipants,
                sidechains[_sidechainId].votes[_voteTarget].numVotedFor,
                sidechains[_sidechainId].votes[_voteTarget].numVotedAgainst);
        emit VoteResult(_sidechainId, uint16(action), _voteTarget, result);

        if (result) {
            // The vote has been decided in the affimative.
            uint256 additionalInfo1 = sidechains[_sidechainId].votes[_voteTarget].additionalInfo1;
            address participantAddr = address(uint160(_voteTarget));
            if (action == VoteType.VOTE_ADD_UNMASKED_PARTICIPANT) {
                sidechains[_sidechainId].unmasked.push(participantAddr);
                sidechains[_sidechainId].inUnmasked[participantAddr] = true;
                sidechains[_sidechainId].numUnmaskedParticipants++;
            }
            else if (action == VoteType.VOTE_ADD_MASKED_PARTICIPANT) {
                sidechains[_sidechainId].masked.push(_voteTarget);
                sidechains[_sidechainId].inMasked[_voteTarget] = true;
            }
            else if (action == VoteType.VOTE_REMOVE_UNMASKED_PARTICIPANT) {
                delete sidechains[_sidechainId].unmasked[additionalInfo1];
                delete sidechains[_sidechainId].inUnmasked[participantAddr];
                sidechains[_sidechainId].numUnmaskedParticipants--;
            }
            else if (action == VoteType.VOTE_REMOVE_MASKED_PARTICIPANT) {
                delete sidechains[_sidechainId].masked[additionalInfo1];
                delete sidechains[_sidechainId].inMasked[_voteTarget];
            }
            else if (action == VoteType.VOTE_CONTEST_PIN) {
                // The current pin key must still be able to be contested.
                // If it is beyond the contest period, ignore the affirmative result
                // of the vote: it is too late.
                uint256 pinKey = _voteTarget;
                if (pinningMap[pinKey].contestBlockNumber > block.number) {
                    pinningMap[pinKey].pin = REMOVED_PIN;
                    delete pinningMap[pinKey].contestBlockNumber;
                }

            }
        }


        // The vote is over. Now delete the voting arrays and indicate there is no vote underway.
        // Remove all values from the map: Maps can't be deleted in Solidity.
        // NOTE: The code below has used values directly, rather than a local variable due to running
        // out of local variables.
        for (uint i = 0; i < sidechains[_sidechainId].unmasked.length; i++) {
            if( sidechains[_sidechainId].unmasked[i] != address(0)) {
                delete sidechains[_sidechainId].votes[_voteTarget].hasVoted[sidechains[_sidechainId].unmasked[i]];
            }
        }
        // This will recursively delete everything in the structure, except for the map, which was
        // deleted in the for loop above.
        delete sidechains[_sidechainId].votes[_voteTarget];
    }


    // Documented in interface.
    function addPin(uint256 _pinKey, bytes32 _pin) external {
        // Can not add a pin if there is one already.
        require(pinningMap[_pinKey].pin == EMPTY_PIN);

        pinningMap[_pinKey] = Pins(
            _pin, block.number  + pinDisputePeriod
        );
        emit Dump2(block.number, pinningMap[_pinKey].contestBlockNumber, pinDisputePeriod);

    }


    // Documented in interface.
    function getPin(uint256 _pinKey) external view returns (bytes32) {
        return pinningMap[_pinKey].pin;
    }







    /**
    * This function is used to indicate that an entity has voted. It has been created so that
    * calls to proposeVote do not have to incur all of the value checking in the vote call.
    *
    * TODO: Compare gas usage of keeping this integrated with the value checking.
    */
    function voteNoChecks(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _voteFor) private {
        // Indicate msg.sender has voted.
        emit ParticipantVoted(_sidechainId, msg.sender, _action, _voteTarget, _voteFor);
        sidechains[_sidechainId].votes[_voteTarget].hasVoted[msg.sender] = true;

        if (_voteFor) {
            sidechains[_sidechainId].votes[_voteTarget].numVotedFor++;
        } else {
            sidechains[_sidechainId].votes[_voteTarget].numVotedAgainst++;
        }
    }



    function getSidechainExists(uint256 _sidechainId) external view returns (bool) {
        return sidechains[_sidechainId].votingPeriod != 0;
    }


    function getVotingPeriod(uint256 _sidechainId) external view returns (uint64) {
        return sidechains[_sidechainId].votingPeriod;
    }


    function isSidechainParticipant(uint256 _sidechainId, address _participant) external view returns(bool) {
        return sidechains[_sidechainId].inUnmasked[_participant];
    }


    function getUnmaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256) {
        return sidechains[_sidechainId].unmasked.length;
    }


    function getUnmaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(address) {
        return sidechains[_sidechainId].unmasked[_index];
    }


    function getMaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256) {
        return sidechains[_sidechainId].masked.length;
    }


    function getMaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(uint256) {
        return sidechains[_sidechainId].masked[_index];
    }

    function getPinDisputePeriod() external view returns (uint32) {
        return pinDisputePeriod;
    }

}

/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;


/*
* Interface which all voting algorithms must implement.
*/
interface VotingAlgInterface {
    /**
     * Asses a vote.
     *
     * @param numParticipants Total number of participants.
     * @param numVotedFor     Number of participants who voted for the proposal.
     * @param numVotedAgainst Number of participants who voted against the proposal.
     * @return true if the result of the vote true. That is, given the voting algorithm
     *  the result of the vote is for what was being voted on.
     */
    function assess(uint64 numParticipants, uint64 numVotedFor, uint64 numVotedAgainst) external pure returns (bool);
}