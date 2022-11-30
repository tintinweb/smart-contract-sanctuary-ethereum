// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../contracts/access/Upgradeable.sol";

/// @title Governance interface
/// @notice Requirements for Governance implementation
/// @custom:type interface
interface Governance is Upgradeable, IERC165 {
    error NotEnoughChoices();
    error NotPermitted(address sender);
    error CancelNotPossible(uint256 proposalId, address sender);
    error NotVoter(uint256 proposalId, address sender);
    error SupervisorListEmpty();
    error NotSupervisor(uint256 proposalId, address sender);
    error VoteIsOpen(uint256 proposalId);
    error VoteIsClosed(uint256 proposalId);
    error VoteCancelled(uint256 proposalId);
    error VoteVetoed(uint256 proposalId);
    error VoteFinal(uint256 proposalId);
    error VoteNotFinal(uint256 proposalId);
    error GasUsedRebateMustBeLarger(uint256 gasUsedRebate, uint256 minimumRebate);
    error BaseFeeRebateMustBeLarger(uint256 baseFee, uint256 minimumBaseFee);
    error ProposalNotSender(uint256 proposalId, address sender);
    error QuorumNotConfigured(uint256 proposalId);
    error VoteInProgress(uint256 proposalId);
    error TransactionExecuted(uint256 proposalId);
    error NotExecuted(uint256 proposalId);
    error InvalidChoice(uint256 proposalId, uint256 choiceId);
    error TransactionSignatureNotMatching(uint256 proposalId, uint256 transactionId);

    /// @notice A new proposal was created
    event ProposalCreated(address sender, uint256 proposalId);
    /// @notice transaction attached to proposal
    event ProposalTransactionAttached(
        address creator,
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    /// @notice transaction canceled on proposal
    event ProposalTransactionCancelled(
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    /// @notice transaction executed on proposal
    event ProposalTransactionExecuted(
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );

    /// @notice ProposalMeta attached
    event ProposalMeta(uint256 proposalId, uint256 metaId, bytes32 name, string value, address sender);
    /// @notice ProposalChoice Set
    event ProposalChoice(uint256 proposalId, uint256 choiceId, bytes32 name, string description, uint256 transactionId);
    /// @notice The proposal description
    event ProposalDescription(uint256 proposalId, string description, string url);
    /// @notice The proposal is final - vote is ready
    event ProposalFinal(uint256 proposalId, uint256 quorum);
    /// @notice Timing information
    event ProposalDelay(uint256 voteDelay, uint256 voteDuration);

    /// @notice The attached transactions are executed
    event ProposalExecuted(uint256 proposalId, uint256 executedTransactionCount);
    /// @notice The proposal has been vetoed
    event ProposalVeto(uint256 proposalId, address sender);
    /// @notice The contract has been funded to provide gas rebates
    event RebateFund(address sender, uint256 transfer, uint256 totalFund);
    /// @notice Gas rebate payment
    event RebatePaid(address recipient, uint256 rebate, uint256 gasPaid);

    /// @notice Winning choice in choice vote
    event WinningChoice(uint256 proposalId, bytes32 name, string description, uint256 transactionId, uint256 voteCount);

    /// @notice propose a vote for the community
    /// @return uint256 The id of the new proposal
    function propose() external returns (uint256);

    /// @notice propose a choice vote for the community
    /// @dev Only one new proposal is allowed per msg.sender
    /// @param _choiceCount the number of choices for this vote
    /// @return uint256 The id of the new proposal
    function propose(uint256 _choiceCount) external returns (uint256);

    /// @notice Attach a transaction to the specified proposal.
    ///         If successfull, it will be executed when voting is ended.
    /// @dev required prior to calling configure
    /// @param _proposalId the id of the proposal
    /// @param _target the target address for this transaction
    /// @param _value the value to pass to the call
    /// @param _signature the tranaction signature
    /// @param _calldata the call data to pass to the call
    /// @param _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    /// @return uint256 the transactionId
    function attachTransaction(
        uint256 _proposalId,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata,
        uint256 _scheduleTime
    ) external returns (uint256);

    /// @notice describe a proposal
    /// @param _proposalId the numeric id of the proposed vote
    /// @param _description the description
    /// @param _url for proposed vote
    /// @dev required prior to calling configure
    function describe(
        uint256 _proposalId,
        string memory _description,
        string memory _url
    ) external;

    /// @notice set a choice by choice id
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _name the name of the metadata field
    /// @param _description the detailed description of the choice
    /// @param _transactionId The id of the transaction to execute
    function setChoice(
        uint256 _proposalId,
        uint256 _choiceId,
        bytes32 _name,
        string memory _description,
        uint256 _transactionId
    ) external;

    /// @notice attach arbitrary metadata to proposal
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _name the name of the metadata field
    /// @param _value the value of the metadata
    /// @return uint256 the metadata id
    function addMeta(
        uint256 _proposalId,
        bytes32 _name,
        string memory _value
    ) external returns (uint256);

    /// @notice cancel a proposal if it is not yet open
    /// @param _proposalId The numeric id of the proposed vote
    function cancel(uint256 _proposalId) external;

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    function configure(uint256 _proposalId, uint256 _quorumRequired) external;

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumThreshold The threshold of participation that is required for a successful conclusion of voting
    /// @param _requiredDelay The minimum time required before the start of voting
    /// @param _requiredDuration The minimum time for voting to proceed before ending the vote is allowed
    function configure(
        uint256 _proposalId,
        uint256 _quorumThreshold,
        uint256 _requiredDelay,
        uint256 _requiredDuration
    ) external;

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice return the name of the community
    /// @return bytes32 the community name
    function community() external view returns (bytes32);

    /// @notice return the community url
    /// @return string memory representation of url
    function url() external view returns (string memory);

    /// @notice return community description
    /// @return string memory representation of community description
    function description() external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../contracts/VoterClass.sol";
import "../contracts/access/Upgradeable.sol";

/// @title Governance GovernanceCreator interface
/// @notice Requirements for Governance GovernanceCreator implementation
/// @custom:type interface
interface GovernanceCreator is Upgradeable, IERC165 {
    error StorageFactoryRequired(address _storage);
    error MetaStorageFactoryRequired(address meta);
    error GovernanceFactoryRequired(address governance);
    error StorageVersionMismatch(address _storage, uint32 expected, uint32 provided);
    error MetaVersionMismatch(address meta, uint32 expected, uint32 provided);
    error VoterClassRequired(address voterClass);

    /// @notice new contract created
    event GovernanceContractCreated(
        address creator,
        bytes32 name,
        address _storage,
        address metaStorage,
        address timeLock,
        address governance
    );
    /// @notice initialized local state for sender
    event GovernanceContractInitialized(address creator);
    /// @notice add supervisor
    event GovernanceContractWithSupervisor(address creator, address supervisor);
    /// @notice set voterclass
    event GovernanceContractWithVoterClass(address creator, address class, string name, uint32 version);
    /// @notice set minimum delay
    event GovernanceContractWithMinimumVoteDelay(address creator, uint256 delay);
    /// @notice set minimum duration
    event GovernanceContractWithMinimumDuration(address creator, uint256 duration);
    /// @notice set minimum quorum
    event GovernanceContractWithMinimumQuorum(address creator, uint256 quorum);
    /// @notice add name
    event GovernanceContractWithName(address creator, bytes32 name);
    /// @notice add url
    event GovernanceContractWithUrl(address creator, string url);
    /// @notice add description
    event GovernanceContractWithDescription(address creator, string description);

    /// @notice The timelock created
    event TimeLockCreated(address timeLock, uint256 lockTime);

    /// @notice settings state used by builder for creating Governance contract
    struct GovernanceProperties {
        /// @notice community name
        bytes32 name;
        /// @notice community url
        string url;
        /// @notice community description
        string description;
        /// @notice minimum allowed vote delay
        uint256 minimumVoteDelay;
        /// @notice minimum allowed vote duration
        uint256 minimumVoteDuration;
        /// @notice minimum allowed quorum
        uint256 minimumProjectQuorum;
        /// @notice max gas used for rebate
        uint256 maxGasUsed;
        /// @notice max base fee for rebate
        uint256 maxBaseFee;
        /// @notice array of supervisors
        address[] supervisorList;
        /// @notice voting class
        VoterClass class;
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice initialize and create a new builder context for this sender
    /// @return GovernanceCreator this contract
    function aGovernance() external returns (GovernanceCreator);

    /// @notice add a supervisor to the supervisor list for the next constructed contract contract
    /// @dev maintains an internal list which increases with every call
    /// @param _supervisor the address of the wallet representing a supervisor for the project
    /// @return GovernanceCreator this contract
    function withSupervisor(address _supervisor) external returns (GovernanceCreator);

    /// @notice set the VoterClass to be used for the next constructed contract
    /// @param _classAddress the address of the VoterClass contract
    /// @return GovernanceCreator this contract
    function withVoterClassAddress(address _classAddress) external returns (GovernanceCreator);

    /// @notice set the VoterClass to be used for the next constructed contract
    /// @dev the type safe VoterClass for use within Solidity code
    /// @param _class the address of the VoterClass contract
    /// @return GovernanceCreator this contract
    function withVoterClass(VoterClass _class) external returns (GovernanceCreator);

    /// @notice set the minimum vote delay to the specified value
    /// @param _minimumDelay the duration in seconds
    /// @return GovernanceCreator this contract
    function withMinimumDelay(uint256 _minimumDelay) external returns (GovernanceCreator);

    /// @notice set the minimum duration to the specified value
    /// @dev at least one day is required
    /// @param _minimumDuration the duration in seconds
    /// @return GovernanceCreator this contract
    function withMinimumDuration(uint256 _minimumDuration) external returns (GovernanceCreator);

    /// @notice set the minimum quorum for the project
    /// @dev must be non zero
    /// @param _minimumQuorum the quorum for the project
    /// @return GovernanceCreator this contract
    function withProjectQuorum(uint256 _minimumQuorum) external returns (GovernanceCreator);

    /// @notice set the community information
    /// @dev this helper calls withName, withUrl and WithDescription
    /// @param _name the name
    /// @param _url the url
    /// @param _description the description
    /// @return GovernanceCreator this contract
    function withDescription(
        bytes32 _name,
        string memory _url,
        string memory _description
    ) external returns (GovernanceCreator);

    /// @notice set the community name
    /// @param _name the name
    /// @return GovernanceCreator this contract
    function withName(bytes32 _name) external returns (GovernanceCreator);

    /// @notice set the community url
    /// @param _url the url
    /// @return GovernanceCreator this contract
    function withUrl(string memory _url) external returns (GovernanceCreator);

    /// @notice set the community description
    /// @dev limit 1k
    /// @param _description the description
    /// @return GovernanceCreator this contract
    function withDescription(string memory _description) external returns (GovernanceCreator);

    /// @notice setup gas rebate parameters
    /// @param _gasUsed the maximum gas used for rebate
    /// @param _baseFee the maximum base fee for rebate
    /// @return GovernanceCreator this contract
    function withGasRebate(uint256 _gasUsed, uint256 _baseFee) external returns (GovernanceCreator);

    /// @notice build the specified contract
    /// @dev Contructs a new contract and may require a large gas fee.  Build does not reinitialize context.
    /// If you wish to reset the settings call reset or aGovernance directly.
    /// @return governanceAddress address of the new Governance contract
    /// @return storageAddress address of the storage contract
    /// @return metaAddress address of the meta contract
    function build()
        external
        returns (
            address payable governanceAddress,
            address storageAddress,
            address metaAddress
        );

    /// @notice clear and reset resources associated with sender build requests
    function reset() external;

    /// @notice identify a contract that was created by this builder
    /// @return bool True if contract was created by this builder
    function contractRegistered(address _contract) external view returns (bool);

    /// @notice upgrade factories
    /// @dev owner required
    function upgrade(
        address _governance,
        address _storage,
        address _meta
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../contracts/GovernanceCreator.sol";
import "../contracts/Governance.sol";
import "../contracts/VoterClassCreator.sol";

contract System is Ownable {
    error NotGovernanceCreator(address creator);
    error NotVoterClassCreator(address creator);

    uint256 public constant MINIMUM_DELAY = 1 hours;
    uint256 public constant MINIMUM_DURATION = 1 days;

    GovernanceCreator private _creator;

    VoterClassCreator private _classCreator;

    /// @notice ctor for System factory
    /// @param _creatorAddress address of GovernanceCreator
    /// @param _voterCreator address of VoterClassCreator
    constructor(address _creatorAddress, address _voterCreator) {
        GovernanceCreator _govCreator = GovernanceCreator(_creatorAddress);
        VoterClassCreator _voterFactory = VoterClassCreator(_voterCreator);
        if (!_govCreator.supportsInterface(type(GovernanceCreator).interfaceId)) revert NotGovernanceCreator(_creatorAddress);
        if (!_voterFactory.supportsInterface(type(VoterClassCreator).interfaceId)) revert NotVoterClassCreator(_voterCreator);
        _creator = _govCreator;
        _classCreator = _voterFactory;
    }

    /// @notice one-shot factory creation method for Collective Governance System
    /// @dev this is useful for front end code or minimizing transactions
    /// @param _name the project name
    /// @param _url the project url
    /// @param _description the project description
    /// @param _erc721 address of ERC-721 contract
    /// @param _quorum the project quorum requirement
    /// @return governanceAddress address of the new Governance contract
    /// @return storageAddress address of the storage contract
    /// @return metaAddress address of the meta contract

    function create(
        bytes32 _name,
        string memory _url,
        string memory _description,
        address _erc721,
        uint256 _quorum
    )
        external
        returns (
            address payable governanceAddress,
            address storageAddress,
            address metaAddress
        )
    {
        address erc721Class = _classCreator.createERC721(_erc721, 1);
        address supervisor = msg.sender;
        return
            _creator
                .aGovernance()
                .withSupervisor(supervisor)
                .withVoterClassAddress(erc721Class)
                .withDescription(_name, _url, _description)
                .withMinimumDelay(MINIMUM_DELAY)
                .withMinimumDuration(MINIMUM_DURATION)
                .withProjectQuorum(_quorum)
                .build();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../contracts/access/Mutable.sol";
import "../contracts/access/Upgradeable.sol";

/// @title VoterClass interface
/// @notice The VoterClass interface defines the requirements for specifying a
/// population or grouping of acceptable voting wallets
/// @dev The VoterClass is stateless and therefore does not require any special
/// privledges.   It can be called by anyone.
/// @custom:type interface
interface VoterClass is Mutable, Upgradeable, IERC165 {
    error NotVoter(address wallet);
    error NotOwner(address tokenContract, address wallet);
    error EmptyClass();
    error UnknownToken(uint256 tokenId);

    /// @notice test if wallet represents an allowed voter for this class
    /// @return bool true if wallet is a voter
    function isVoter(address _wallet) external view returns (bool);

    /// @notice discover an array of shareIds associated with the specified wallet
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external view returns (uint256[] memory);

    /// @notice confirm shareid is associated with wallet for voting
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 shareId) external returns (uint256);

    /// @notice return voting weight of each confirmed share
    /// @return uint256 weight applied to one share
    function weight() external view returns (uint256);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../contracts/VoterClass.sol";
import "../contracts/access/Upgradeable.sol";

/// @title Interface for VoterClass creation
/// @custom:type interface
interface VoterClassCreator is Upgradeable, IERC165 {
    event VoterClassCreated(address voterClass);
    event VoterClassCreated(address voterClass, address project);

    /// @notice create a VoterClass for open voting
    /// @param _weight The weight associated with each vote
    /// @return address The address of the resulting voter class
    function createOpenVote(uint256 _weight) external returns (address);

    /// @notice create a VoterClass for pooled voting
    /// @param _weight The weight associated with each vote
    /// @return address The address of the resulting voter class
    function createVoterPool(uint256 _weight) external returns (address);

    /// @notice create a VoterClass for token holding members
    /// @param _erc721 The address of the ERC-721 contract for voting
    /// @param _weight The weight associated with each vote
    /// @return address The address of the resulting voter class
    function createERC721(address _erc721, uint256 _weight) external returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @title Interface for mutable objects
/// @notice used to determine if a class is modifiable
/// @custom:type interface
interface Mutable {
    error NotFinal();
    error ContractFinal();

    /// @return bool True if this object is final
    function isFinal() external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @title requirement for Upgradeable contract
/// @custom:type interface
interface Upgradeable {
    function version() external pure returns (uint32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
interface IERC165 {
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