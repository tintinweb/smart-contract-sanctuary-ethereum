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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../contracts/Constant.sol";
import "../contracts/GovernanceStorage.sol";
import "../contracts/CollectiveGovernance.sol";
import "../contracts/VoterClass.sol";
import "../contracts/GovernanceCreator.sol";
import "../contracts/StorageFactory.sol";

/// @title Governance GovernanceCreator implementation
/// @notice This builder supports creating new instances of the Collective Governance Contract
contract GovernanceBuilder is GovernanceCreator, ERC165 {
    string public constant NAME = "collective governance builder";

    mapping(address => GovernanceProperties) private _buildMap;

    /// @dev implement the null object pattern requring voter class to be valid
    VoterClass private immutable _voterClassNull;

    StorageCreator private immutable _storageFactory;

    constructor() {
        _voterClassNull = new VoterClassNullObject();
        _storageFactory = new StorageFactory();
    }

    /// @notice initialize and create a new builder context for this sender
    /// @return GovernanceCreator this contract
    function aGovernance() external returns (GovernanceCreator) {
        clear(msg.sender);
        emit GovernanceContractInitialized(msg.sender);
        return this;
    }

    /// @notice add a supervisor to the supervisor list for the next constructed contract contract
    /// @dev maintains an internal list which increases with every call
    /// @param _supervisor the address of the wallet representing a supervisor for the project
    /// @return GovernanceCreator this contract
    function withSupervisor(address _supervisor) external returns (GovernanceCreator) {
        GovernanceProperties storage _properties = _buildMap[msg.sender];
        _properties.supervisorList.push(_supervisor);
        emit GovernanceContractWithSupervisor(msg.sender, _supervisor);
        return this;
    }

    /// @notice set the VoterClass to be used for the next constructed contract
    /// @param _classAddress the address of the VoterClass contract
    /// @return GovernanceCreator this contract
    function withVoterClassAddress(address _classAddress) external returns (GovernanceCreator) {
        IERC165 erc165 = IERC165(_classAddress);
        require(erc165.supportsInterface(type(VoterClass).interfaceId), "VoterClass required");
        return withVoterClass(VoterClass(_classAddress));
    }

    /// @notice set the VoterClass to be used for the next constructed contract
    /// @dev the type safe VoterClass for use within Solidity code
    /// @param _class the address of the VoterClass contract
    /// @return GovernanceCreator this contract
    function withVoterClass(VoterClass _class) public returns (GovernanceCreator) {
        GovernanceProperties storage _properties = _buildMap[msg.sender];
        _properties.class = _class;
        emit GovernanceContractWithVoterClass(msg.sender, address(_class), _class.name(), _class.version());
        return this;
    }

    /// @notice set the minimum duration to the specified value
    /// @dev at least one day is required
    /// @param _minimumDuration the duration in seconds
    /// @return GovernanceCreator this contract
    function withMinimumDuration(uint256 _minimumDuration) external returns (GovernanceCreator) {
        GovernanceProperties storage _properties = _buildMap[msg.sender];
        _properties.minimumVoteDuration = _minimumDuration;
        emit GovernanceContractWithMinimumDuration(msg.sender, _minimumDuration);
        return this;
    }

    /// @notice build the specified contract
    /// @dev contructs a new contract and may require a large gas fee, does not reinitialize context
    /// @return the address of the new Governance contract
    function build() external returns (address) {
        address _creator = msg.sender;
        GovernanceProperties storage _properties = _buildMap[_creator];
        require(_properties.supervisorList.length > 0, "Supervisor required");
        require(_properties.minimumVoteDuration >= Constant.MINIMUM_VOTE_DURATION, "Longer minimum duration required");
        require(address(_properties.class) != address(_voterClassNull), "Voter class required");
        Storage _storage = _storageFactory.create(_properties.class, _properties.minimumVoteDuration);
        Governance _governance = new CollectiveGovernance(_properties.supervisorList, _properties.class, _storage);
        address _governanceAddress = address(_governance);
        transferOwnership(_storage, _governanceAddress);
        emit GovernanceContractCreated(_creator, address(_storage), _governanceAddress);
        return _governanceAddress;
    }

    /// @notice clear and reset resources associated with sender build requests
    function reset() external {
        // overwrite to truncate data lifetime
        clear(msg.sender);
        delete _buildMap[msg.sender];
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(GovernanceCreator).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure virtual returns (uint32) {
        return Constant.VERSION_1;
    }

    function transferOwnership(Storage _storage, address _targetOwner) private {
        Ownable _ownableStorage = Ownable(address(_storage));
        _ownableStorage.transferOwnership(_targetOwner);
    }

    function clear(address sender) internal {
        GovernanceProperties storage _properties = _buildMap[sender];
        _properties.class = _voterClassNull;
        _properties.supervisorList = new address[](0);
        _properties.minimumVoteDuration = Constant.MINIMUM_VOTE_DURATION;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

/**
  @notice extract global manifest constants
 */
library Constant {
    uint256 public constant UINT_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @notice minimum vote duration
    /// @dev For security reasons this must be a relatively long time compared to seconds
    uint256 public constant MINIMUM_VOTE_DURATION = 5 minutes;

    // timelock setup
    uint256 public constant TIMELOCK_GRACE_PERIOD = 14 days;
    uint256 public constant TIMELOCK_MINIMUM_DELAY = MINIMUM_VOTE_DURATION;
    uint256 public constant TIMELOCK_MAXIMUM_DELAY = 30 days;

    uint32 public constant VERSION_1 = 1;
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../contracts/Constant.sol";
import "../contracts/Storage.sol";
import "../contracts/VoterClass.sol";

/// @title GovernanceStorage implementation
/// @notice GovernanceStorage implements the necesscary infrastructure for
/// governance and voting with safety controls
/// @dev The creator of the contract, typically the Governance contract itself,
/// privledged with respect to write opperations in this contract.   The creator
/// is required for nearly all change operations
contract GovernanceStorage is Storage, ERC165, Ownable {
    /// @notice contract name
    string public constant NAME = "collective governance storage";

    uint256 public constant MAXIMUM_QUORUM = Constant.UINT_MAX;
    uint256 public constant MAXIMUM_TIME = Constant.UINT_MAX;

    uint256 private immutable _minimumVoteDuration;

    /// @notice Voter class for storage
    VoterClass private immutable _voterClass;

    /// @notice The total number of proposals
    uint256 private _proposalCount;

    /// @notice global list of proposed issues by id
    mapping(uint256 => Proposal) public proposalMap;

    /// @notice The last contest for each sender
    mapping(address => uint256) private _latestProposalId;

    /// @notice create a new storage object with VoterClass as the voting population
    /// @param _class the contract that defines the popluation
    /// @param _minimumDuration the least possible voting duration
    constructor(VoterClass _class, uint256 _minimumDuration) {
        require(_minimumDuration >= Constant.MINIMUM_VOTE_DURATION, "Short vote");
        require(_class.isFinal(), "Voter Class modifiable");
        _minimumVoteDuration = _minimumDuration;
        _voterClass = _class;
        _proposalCount = 0;
    }

    modifier requireValid(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_proposalId > 0 && _proposalId <= _proposalCount && proposal.id == _proposalId, "Invalid proposal");
        _;
    }

    modifier requireVoteCast(uint256 _proposalId, uint256 _receiptId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_receiptId > 0, "Receipt id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareId == _receiptId, "No vote cast");
        require(receipt.votesCast > 0 && !receipt.abstention && !receipt.undoCast, "No affirmative vote");
        _;
    }

    modifier requireReceiptForWallet(
        uint256 _proposalId,
        uint256 _receiptId,
        address _wallet
    ) {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.wallet == _wallet, "Not voter");
        _;
    }

    modifier requireValidReceipt(uint256 _proposalId, uint256 _receiptId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_receiptId > 0, "Receipt id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareId > 0, "Receipt not initialized");
        _;
    }

    modifier requireShareAvailable(uint256 _proposalId, uint256 _shareId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_shareId > 0, "Share id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        require(receipt.shareId == 0 && receipt.votesCast == 0 && !receipt.abstention && !receipt.undoCast, "Already voted");
        _;
    }

    modifier requireProposalSender(uint256 _proposalId, address _sender) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.proposalSender == _sender, "Not creator");
        _;
    }

    modifier requireConfig(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.status == Status.CONFIG, "Vote not modifiable");
        _;
    }

    modifier requireFinal(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.status == Status.FINAL, "Not final");
        _;
    }

    modifier requireVotingActive(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.startTime <= getBlockTimestamp() && proposal.endTime > getBlockTimestamp(), "Vote not active");
        _;
    }

    modifier requireUndo(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.isUndoEnabled, "Undo not enabled");
        _;
    }

    /// @notice Register a new supervisor on the specified proposal.
    /// The supervisor has rights to add or remove voters prior to start of voting
    /// in a Voter Pool. The supervisor also has the right to veto the outcome of the vote.
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function registerSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external onlyOwner requireValid(_proposalId) requireProposalSender(_proposalId, _sender) requireConfig(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = true;
            emit AddSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice remove a supervisor from the proposal along with its ability to change or veto
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function burnSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external onlyOwner requireValid(_proposalId) requireProposalSender(_proposalId, _sender) requireConfig(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        if (proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = false;
            emit BurnSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice set the minimum number of participants for a successful outcome
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _quorum the number required for quorum
    /// @param _sender original wallet for this request
    function setQuorumRequired(
        uint256 _proposalId,
        uint256 _quorum,
        address _sender
    ) external onlyOwner requireValid(_proposalId) requireConfig(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.quorumRequired = _quorum;
        emit SetQuorumRequired(_proposalId, _quorum);
    }

    /// @notice enable the undo feature for this vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function enableUndoVote(uint256 _proposalId, address _sender)
        external
        onlyOwner
        requireValid(_proposalId)
        requireConfig(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.isUndoEnabled = true;
        emit UndoVoteEnabled(_proposalId);
    }

    /// @notice set the delay period required to preceed the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDelay the quorum number
    /// @param _sender original wallet for this request
    function setVoteDelay(
        uint256 _proposalId,
        uint256 _voteDelay,
        address _sender
    ) external onlyOwner requireValid(_proposalId) requireConfig(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.voteDelay = _voteDelay;
    }

    /// @notice set the required duration for the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDuration the quorum number
    /// @param _sender original wallet for this request
    function setVoteDuration(
        uint256 _proposalId,
        uint256 _voteDuration,
        address _sender
    ) external onlyOwner requireValid(_proposalId) requireConfig(_proposalId) {
        require(_voteDuration >= Constant.MINIMUM_VOTE_DURATION, "Short vote");
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.voteDuration = _voteDuration;
    }

    /// @notice get the address of the proposal sender
    /// @param _proposalId the id of the proposal
    /// @return address the address of the sender
    function getSender(uint256 _proposalId) external view requireValid(_proposalId) returns (address) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.proposalSender;
    }

    /// @notice get the quorum required
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number required for quorum
    function quorumRequired(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.quorumRequired;
    }

    /// @notice get the vote delay
    /// @param _proposalId the id of the proposal
    /// @return uint256 the delay
    function voteDelay(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voteDelay;
    }

    /// @notice get the vote duration
    /// @param _proposalId the id of the proposal
    /// @return uint256 the duration
    function voteDuration(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voteDuration;
    }

    /// @notice get the start time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the start time
    function startTime(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.startTime;
    }

    /// @notice get the end time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the end time
    function endTime(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.endTime;
    }

    /// @notice get the for vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of votes in favor
    function forVotes(uint256 _proposalId) public view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.forVotes;
    }

    /// @notice get the against vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of against votes
    function againstVotes(uint256 _proposalId) public view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.againstVotes;
    }

    /// @notice get the number of abstentions
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number abstentions
    function abstentionCount(uint256 _proposalId) public view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.abstentionCount;
    }

    /// @notice get the current number counting towards quorum
    /// @param _proposalId the id of the proposal
    /// @return uint256 the amount of participation
    function quorum(uint256 _proposalId) external view returns (uint256) {
        return forVotes(_proposalId) + againstVotes(_proposalId) + abstentionCount(_proposalId);
    }

    /// @notice test if the address is a supervisor on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the address to check
    /// @return bool true if the address is a supervisor
    function isSupervisor(uint256 _proposalId, address _supervisor) external view requireValid(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.supervisorPool[_supervisor];
    }

    /// @notice test if address is a voter on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _voter the address to check
    /// @return bool true if the address is a voter
    function isVoter(uint256 _proposalId, address _voter) external view requireValid(_proposalId) returns (bool) {
        return _voterClass.isVoter(_voter);
    }

    /// @notice test if proposal is ready or in the setup phase
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked ready
    function isFinal(uint256 _proposalId) public view requireValid(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.status == Status.FINAL || proposal.status == Status.CANCELLED;
    }

    /// @notice test if proposal is cancelled
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked cancelled
    function isCancel(uint256 _proposalId) public view requireValid(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.status == Status.CANCELLED;
    }

    /// @notice test if proposal is veto
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked veto
    function isVeto(uint256 _proposalId) external view requireValid(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_proposalId > 0 && _proposalId <= _proposalCount, "Unknown proposal");
        return proposal.isVeto;
    }

    /// @notice get the id of the last proposal for sender
    /// @return uint256 the id of the most recent proposal for sender
    function latestProposal(address _sender) external view returns (uint256) {
        uint256 latestProposalId = _latestProposalId[_sender];
        require(latestProposalId > 0, "No proposal");
        return latestProposalId;
    }

    /// @notice get the vote receipt
    /// @return _shareId the share id for the vote
    /// @return _shareFor the shares cast in favor
    /// @return _votesCast the number of votes cast
    /// @return _isAbstention true if vote was an abstention
    /// @return _isUndo true if the vote was reversed
    function voteReceipt(uint256 _proposalId, uint256 _shareId)
        external
        view
        requireValid(_proposalId)
        requireValidReceipt(_proposalId, _shareId)
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        return (receipt.shareId, receipt.shareFor, receipt.votesCast, receipt.abstention, receipt.undoCast);
    }

    /// @notice get the VoterClass used for this voting store
    /// @return VoterClass the voter class for this store
    function voterClass() external view returns (VoterClass) {
        return _voterClass;
    }

    /// @notice initialize a new proposal and return the id
    /// @return uint256 the id of the proposal
    function initializeProposal(address _sender) external onlyOwner returns (uint256) {
        uint256 latestProposalId = _latestProposalId[_sender];
        if (latestProposalId != 0) {
            Proposal storage lastProposal = proposalMap[latestProposalId];
            require(
                isCancel(latestProposalId) || (isFinal(latestProposalId) && getBlockTimestamp() >= lastProposal.endTime),
                "Too many proposals"
            );
        }
        _proposalCount++;
        uint256 proposalId = _proposalCount;
        _latestProposalId[_sender] = proposalId;

        // proposal
        Proposal storage proposal = proposalMap[proposalId];
        proposal.id = proposalId;
        proposal.proposalSender = _sender;
        proposal.quorumRequired = MAXIMUM_QUORUM;
        proposal.voteDelay = 0;
        proposal.voteDuration = Constant.MINIMUM_VOTE_DURATION;
        proposal.startTime = MAXIMUM_TIME;
        proposal.endTime = MAXIMUM_TIME;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.abstentionCount = 0;
        proposal.transactionCount = 0;
        proposal.isVeto = false;
        proposal.status = Status.CONFIG;
        proposal.isUndoEnabled = false;

        emit InitializeProposal(proposalId, _sender);
        return proposalId;
    }

    /// @notice indicate the proposal is ready for voting and should be frozen
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function makeFinal(uint256 _proposalId, address _sender)
        public
        onlyOwner
        requireValid(_proposalId)
        requireConfig(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.status = Status.FINAL;
        proposal.startTime = getBlockTimestamp() + proposal.voteDelay;
        proposal.endTime = proposal.startTime + proposal.voteDuration;
        emit VoteReady(_proposalId, proposal.startTime, proposal.endTime);
    }

    /// @notice cancel the proposal if it is not yet started
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function cancel(uint256 _proposalId, address _sender) external onlyOwner requireValid(_proposalId) {
        if (!isFinal(_proposalId)) {
            // calculate start and end time
            makeFinal(_proposalId, _sender);
        }
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        proposal.status = Status.CANCELLED;
        emit VoteCancel(_proposalId, _sender);
    }

    /// @notice veto the specified proposal
    /// @dev supervisor is required
    /// @param _proposalId the id of the proposal
    /// @param _sender the address of the veto sender
    function veto(uint256 _proposalId, address _sender) external onlyOwner requireValid(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Requires supervisor");
        if (!proposal.isVeto) {
            proposal.isVeto = true;
            emit VoteVeto(_proposalId, msg.sender);
        } else {
            revert("Already vetoed");
        }
    }

    /// @notice cast an affirmative vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteForByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    )
        external
        onlyOwner
        requireShareAvailable(_proposalId, _shareId)
        requireValid(_proposalId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = _voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.shareFor = _shareCount;
        proposal.forVotes += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    /// @notice cast an against vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteAgainstByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    )
        external
        onlyOwner
        requireValid(_proposalId)
        requireShareAvailable(_proposalId, _shareId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = _voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.abstention = false;
        proposal.againstVotes += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    /// @notice cast an abstention for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function abstainForShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) public onlyOwner requireValid(_proposalId) requireVotingActive(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = _voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        require(receipt.shareId == 0 && receipt.votesCast == 0, "Share already voted");
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.abstention = true;
        proposal.abstentionCount += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    /// @notice undo vote for the specified receipt
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _receiptId the id of the share to undo
    /// @return uint256 the number of votes cast
    function undoVoteById(
        uint256 _proposalId,
        address _wallet,
        uint256 _receiptId
    )
        public
        onlyOwner
        requireValid(_proposalId)
        requireVoteCast(_proposalId, _receiptId)
        requireReceiptForWallet(_proposalId, _receiptId, _wallet)
        requireUndo(_proposalId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareFor > 0, "Vote not affirmative");
        uint256 undoVotes = receipt.shareFor;
        receipt.undoCast = true;
        proposal.forVotes -= undoVotes;
        emit UndoVote(_proposalId, _wallet, _receiptId, undoVotes);
        return undoVotes;
    }

    /// @notice add a transaction to the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _target the target address for this transaction
    /// @param _value the value to pass to the call
    /// @param _signature the tranaction signature
    /// @param _calldata the call data to pass to the call
    /// @param _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    /// @param _sender for this proposal
    /// @return uint256 the id of the transaction that was added
    function addTransaction(
        uint256 _proposalId,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata,
        uint256 _scheduleTime,
        address _sender
    )
        external
        onlyOwner
        requireConfig(_proposalId)
        requireValid(_proposalId)
        requireProposalSender(_proposalId, _sender)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 transactionId = proposal.transactionCount++;
        proposal.transaction[transactionId] = Transaction(_target, _value, _signature, _calldata, _scheduleTime);
        return transactionId;
    }

    /// @notice return the stored transaction by id
    /// @param _proposalId the proposal where the transaction is stored
    /// @param _transactionId The id of the transaction on the proposal
    /// @return _target the target address for this transaction
    /// @return _value the value to pass to the call
    /// @return _signature the tranaction signature
    /// @return _calldata the call data to pass to the call
    /// @return _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    function getTransaction(uint256 _proposalId, uint256 _transactionId)
        external
        view
        requireValid(_proposalId)
        returns (
            address _target,
            uint256 _value,
            string memory _signature,
            bytes memory _calldata,
            uint256 _scheduleTime
        )
    {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_transactionId < proposal.transactionCount, "Invalid transaction");
        Transaction storage transaction = proposal.transaction[_transactionId];
        return (transaction.target, transaction.value, transaction.signature, transaction._calldata, transaction.scheduleTime);
    }

    /// @notice set proposal state executed
    /// @param _proposalId the id of the proposal
    /// @param _sender for this proposal
    function setExecuted(uint256 _proposalId, address _sender)
        external
        onlyOwner
        requireValid(_proposalId)
        requireFinal(_proposalId)
        requireProposalSender(_proposalId, _sender)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        require(!proposal.isExecuted, "Executed previously");
        proposal.isExecuted = true;
    }

    /// @notice get the current state if executed or not
    /// @param _proposalId the id of the proposal
    /// @return bool true if already executed
    function isExecuted(uint256 _proposalId) external view requireValid(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.isExecuted;
    }

    /// @notice get the number of attached transactions
    /// @param _proposalId the id of the proposal
    /// @return uint256 current number of transactions
    function transactionCount(uint256 _proposalId) external view requireValid(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.transactionCount;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(Storage).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice get the vote duration in seconds
    /// @return uint256 the least duration of a vote in seconds
    function minimumVoteDuration() external view returns (uint256) {
        return _minimumVoteDuration;
    }

    /// @notice get the maxiumum possible for the pass threshold
    /// @return uint256 the maximum value
    function maxPassThreshold() external pure returns (uint256) {
        return MAXIMUM_QUORUM;
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() public pure virtual returns (uint32) {
        return Constant.VERSION_1;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../contracts/Storage.sol";
import "../contracts/Governance.sol";
import "../contracts/VoteStrategy.sol";
import "../contracts/VoterClass.sol";
import "../contracts/VoterClassERC721.sol";
import "../contracts/VoterClassOpenVote.sol";
import "../contracts/TimeLock.sol";

/// @title Collective Governance implementation
/// @notice Governance contract implementation for Collective.   This contract implements voting by
/// groups of pooled voters, open voting or based on membership, such as class members who hold a specific
/// ERC-721 token in their wallet.
/// Creating a Vote is a three step process
///
/// First, propose the vote.  Next, Configure the vote.  Finally, start the vote.
///
/// Voting may proceed according to the conditions established during configuration.
///
/// @dev The VoterClass is common to all proposed votes as are the project supervisors.   Individual supervisors may
/// be configured as part of the proposal creation workflow but project supervisors are always included.
contract CollectiveGovernance is Governance, VoteStrategy, ERC165 {
    /// @notice contract name
    string public constant NAME = "collective governance";
    uint32 public constant VERSION_1 = 1;

    VoterClass private immutable _voterClass;

    Storage private immutable _storage;

    TimeLock private immutable _timeLock;

    address[] private _projectSupervisorList;

    /// @notice voting is open or not
    mapping(uint256 => bool) private isVoteOpenByProposalId;

    /// @notice create a new collective governance contract
    /// @dev this should be invoked through the GovernanceBuilder
    /// @param _supervisorList the list of supervisors for this project
    /// @param _class the VoterClass for this project
    /// @param _governanceStorage The storage contract for this governance
    constructor(
        address[] memory _supervisorList,
        VoterClass _class,
        Storage _governanceStorage
    ) {
        _voterClass = _class;
        _storage = _governanceStorage;
        uint256 _timeLockDelay = max(_storage.minimumVoteDuration(), Constant.TIMELOCK_MINIMUM_DELAY);
        _timeLock = new TimeLock(_timeLockDelay);
        _projectSupervisorList = _supervisorList;
    }

    modifier requireVoteReady(uint256 _proposalId) {
        require(_storage.isFinal(_proposalId), "Voting is not ready");
        _;
    }

    modifier requireVoteClosed(uint256 _proposalId) {
        require(_storage.isFinal(_proposalId) && !isVoteOpenByProposalId[_proposalId], "Vote is not closed");
        _;
    }

    modifier requireVoteOpen(uint256 _proposalId) {
        require(_storage.isFinal(_proposalId) && isVoteOpenByProposalId[_proposalId], "Voting is closed");
        _;
    }

    modifier requireVoteAllowed(uint256 _proposalId) {
        require(!_storage.isCancel(_proposalId) && !_storage.isVeto(_proposalId), "Vote cancelled");
        _;
    }

    modifier requireSupervisor(uint256 _proposalId) {
        require(_storage.isSupervisor(_proposalId, msg.sender), "Supervisor required");
        _;
    }

    /// @notice propose a vote for the community
    /// @dev Only one new proposal is allowed per msg.sender
    /// @return uint256 The id of the new proposal
    function propose() external returns (uint256) {
        address _sender = msg.sender;
        uint256 proposalId = _storage.initializeProposal(_sender);
        _storage.registerSupervisor(proposalId, _sender, _sender);
        for (uint256 i = 0; i < _projectSupervisorList.length; i++) {
            _storage.registerSupervisor(proposalId, _projectSupervisorList[i], _sender);
        }
        emit ProposalCreated(_sender, proposalId);
        return proposalId;
    }

    /// @notice Attach a transaction to the specified proposal.
    ///         If successfull, it will be executed when voting is ended.
    /// @dev must be called prior to configuration
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
    ) external returns (uint256) {
        require(_storage.getSender(_proposalId) == msg.sender, "Not sender");
        uint256 transactionId = _storage.addTransaction(
            _proposalId,
            _target,
            _value,
            _signature,
            _calldata,
            _scheduleTime,
            msg.sender
        );
        bytes32 txHash = _timeLock.queueTransaction(_target, _value, _signature, _calldata, _scheduleTime);
        emit ProposalTransactionAttached(msg.sender, _proposalId, _target, _value, _scheduleTime, txHash);
        return transactionId;
    }

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    function configure(uint256 _proposalId, uint256 _quorumRequired) public requireSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setQuorumRequired(_proposalId, _quorumRequired, _sender);
        _storage.makeFinal(_proposalId, _sender);
        emit ProposalOpen(_proposalId);
    }

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    /// @param _requiredDuration The minimum time for voting to proceed before ending the vote is allowed
    function configure(
        uint256 _proposalId,
        uint256 _quorumRequired,
        uint256 _requiredDuration
    ) external requireSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setVoteDuration(_proposalId, _requiredDuration, _sender);
        configure(_proposalId, _quorumRequired);
    }

    /// @notice start the voting process by proposal id
    /// @param _proposalId The numeric id of the proposed vote
    function startVote(uint256 _proposalId)
        external
        requireSupervisor(_proposalId)
        requireVoteReady(_proposalId)
        requireVoteAllowed(_proposalId)
    {
        require(_storage.quorumRequired(_proposalId) < _storage.maxPassThreshold(), "Set quorum required");
        if (!isVoteOpenByProposalId[_proposalId]) {
            isVoteOpenByProposalId[_proposalId] = true;
            emit VoteOpen(_proposalId);
        } else {
            revert("Already open");
        }
    }

    /// @notice test if an existing proposal is open
    /// @param _proposalId The numeric id of the proposed vote
    /// @return bool True if the proposal is open
    function isOpen(uint256 _proposalId) external view returns (bool) {
        uint256 endTime = _storage.endTime(_proposalId);
        bool voteProceeding = !_storage.isCancel(_proposalId) && !_storage.isVeto(_proposalId);
        return isVoteOpenByProposalId[_proposalId] && getBlockTimestamp() < endTime && voteProceeding;
    }

    /// @notice end voting on an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev it is not possible to end voting until the required duration has elapsed
    function endVote(uint256 _proposalId) public requireSupervisor(_proposalId) requireVoteOpen(_proposalId) {
        uint256 _endTime = _storage.endTime(_proposalId);
        require(
            _endTime <= getBlockTimestamp() || _storage.isVeto(_proposalId) || _storage.isCancel(_proposalId),
            "Vote in progress"
        );
        isVoteOpenByProposalId[_proposalId] = false;

        if (!_storage.isVeto(_proposalId) && getVoteSucceeded(_proposalId)) {
            executeTransaction(_proposalId);
        } else {
            cancelTransaction(_proposalId);
        }
        emit VoteClosed(_proposalId);
        emit ProposalClosed(_proposalId);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev Auto discovery is attempted and if possible the method will proceed using the discovered shares
    function voteFor(uint256 _proposalId) external {
        uint256[] memory _shareList = _voterClass.discover(msg.sender);
        voteFor(_proposalId, _shareList);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteFor(uint256 _proposalId, uint256[] memory _tokenIdList) public {
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            voteFor(_proposalId, _tokenIdList[i]);
        }
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteFor(uint256 _proposalId, uint256 _tokenId) public requireVoteOpen(_proposalId) requireVoteAllowed(_proposalId) {
        uint256 count = _storage.voteForByShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    /// @notice cast an against vote by id
    /// @dev auto discovery is attempted and if possible the method will proceed using the discovered shares
    /// @param _proposalId The numeric id of the proposed vote
    function voteAgainst(uint256 _proposalId) public {
        uint256[] memory _shareList = _voterClass.discover(msg.sender);
        voteAgainst(_proposalId, _shareList);
    }

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteAgainst(uint256 _proposalId, uint256[] memory _tokenIdList) public {
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            voteAgainst(_proposalId, _tokenIdList[i]);
        }
    }

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteAgainst(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireVoteAllowed(_proposalId)
    {
        uint256 count = _storage.voteAgainstByShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    /// @notice abstain from vote by id
    /// @dev auto discovery is attempted and if possible the method will proceed using the discovered shares
    /// @param _proposalId The numeric id of the proposed vote
    function abstainFrom(uint256 _proposalId) external {
        uint256[] memory _shareList = _voterClass.discover(msg.sender);
        abstainFrom(_proposalId, _shareList);
    }

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function abstainFrom(uint256 _proposalId, uint256[] memory _tokenIdList) public {
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            abstainFrom(_proposalId, _tokenIdList[i]);
        }
    }

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function abstainFrom(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireVoteAllowed(_proposalId)
    {
        uint256 count = _storage.abstainForShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit AbstentionTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    /// @notice undo any previous vote if any
    /// @dev Only applies to affirmative vote.
    /// auto discovery is attempted and if possible the method will proceed using the discovered shares
    /// @param _proposalId The numeric id of the proposed vote
    function undoVote(uint256 _proposalId) external {
        uint256[] memory _shareList = _voterClass.discover(msg.sender);
        undoVote(_proposalId, _shareList);
    }

    /// @notice undo any previous vote if any
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function undoVote(uint256 _proposalId, uint256[] memory _tokenIdList) public {
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            undoVote(_proposalId, _tokenIdList[i]);
        }
    }

    /// @notice undo any previous vote if any
    /// @dev only applies to affirmative vote
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function undoVote(uint256 _proposalId, uint256 _tokenId) public requireVoteOpen(_proposalId) requireVoteAllowed(_proposalId) {
        uint256 count = _storage.undoVoteById(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteUndo(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    /// @notice veto proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev transaction must be signed by a supervisor wallet
    function veto(uint256 _proposalId)
        external
        requireSupervisor(_proposalId)
        requireVoteOpen(_proposalId)
        requireVoteAllowed(_proposalId)
    {
        _storage.veto(_proposalId, msg.sender);
    }

    /// @notice get the result of the vote
    /// @return bool True if the vote is closed and passed
    /// @dev This method will fail if the vote was vetoed
    function getVoteSucceeded(uint256 _proposalId)
        public
        view
        requireVoteAllowed(_proposalId)
        requireVoteClosed(_proposalId)
        returns (bool)
    {
        uint256 totalVotesCast = _storage.quorum(_proposalId);
        bool quorumRequirementMet = totalVotesCast >= _storage.quorumRequired(_proposalId);
        return quorumRequirementMet && _storage.forVotes(_proposalId) > _storage.againstVotes(_proposalId);
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(Governance).interfaceId ||
            interfaceId == type(VoteStrategy).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice return the address of the internal vote data store
    /// @return address The address of the store
    function getStorageAddress() external view returns (address) {
        return address(_storage);
    }

    /// @notice cancel a proposal if it is not yet open
    /// @dev proposal must be finalized and ready but voting must not yet be open
    /// @param _proposalId The numeric id of the proposed vote
    function cancel(uint256 _proposalId) public requireSupervisor(_proposalId) {
        uint256 _startTime = _storage.startTime(_proposalId);
        require(!isVoteOpenByProposalId[_proposalId] && getBlockTimestamp() <= _startTime, "Not possible");
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        for (uint256 tid = 0; tid < transactionCount; tid++) {
            (address target, uint256 value, string memory signature, bytes memory _calldata, uint256 scheduleTime) = _storage
                .getTransaction(_proposalId, tid);
            _timeLock.cancelTransaction(target, value, signature, _calldata, scheduleTime);
        }
        _storage.cancel(_proposalId, msg.sender);
        emit ProposalClosed(_proposalId);
    }

    function executeTransaction(uint256 _proposalId) private {
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        if (transactionCount > 0) {
            _storage.setExecuted(_proposalId, msg.sender);
            for (uint256 tid = 0; tid < transactionCount; tid++) {
                (address target, uint256 value, string memory signature, bytes memory _calldata, uint256 scheduleTime) = _storage
                    .getTransaction(_proposalId, tid);
                _timeLock.executeTransaction(target, value, signature, _calldata, scheduleTime);
            }
            emit ProposalExecuted(_proposalId);
        }
    }

    function cancelTransaction(uint256 _proposalId) private {
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        if (transactionCount > 0) {
            for (uint256 tid = 0; tid < transactionCount; tid++) {
                (address target, uint256 value, string memory signature, bytes memory _calldata, uint256 scheduleTime) = _storage
                    .getTransaction(_proposalId, tid);
                _timeLock.cancelTransaction(target, value, signature, _calldata, scheduleTime);
            }
        }
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure virtual returns (uint32) {
        return VERSION_1;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
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

/// @title VoterClass interface
/// @notice The VoterClass interface defines the requirements for specifying a
/// population or grouping of acceptable voting wallets
/// @dev The VoterClass is stateless and therefore does not require any special
/// privledges.   It can be called by anyone.
/// @custom:type interface
interface VoterClass is IERC165 {
    /// @notice test if voterclass is modifiable such as to add or remove voters from a pool
    /// @dev class must be final to be used in a Governance contract
    /// @return bool true if class is final
    function isFinal() external view returns (bool);

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

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32);
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

/// @title Governance GovernanceCreator interface
/// @notice Requirements for Governance GovernanceCreator implementation
/// @custom:type interface
interface GovernanceCreator is IERC165 {
    event GovernanceContractCreated(address creator, address _storage, address governance);
    event GovernanceContractInitialized(address creator);
    event GovernanceContractWithSupervisor(address creator, address supervisor);
    event GovernanceContractWithVoterClass(address creator, address class, string name, uint32 version);
    event GovernanceContractWithMinimumDuration(address creator, uint256 duration);

    struct GovernanceProperties {
        uint256 minimumVoteDuration;
        address[] supervisorList;
        VoterClass class;
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32);

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

    /// @notice set the minimum duration to the specified value
    /// @dev at least one day is required
    /// @param _minimumDuration the duration in seconds
    /// @return GovernanceCreator this contract
    function withMinimumDuration(uint256 _minimumDuration) external returns (GovernanceCreator);

    /// @notice build the specified contract
    /// @dev Contructs a new contract and may require a large gas fee.  Build does not reinitialize context.
    /// If you wish to reset the settings call reset or aGovernance directly.
    /// @return the address of the new Governance contract
    function build() external returns (address);
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

import "../contracts/StorageCreator.sol";
import "../contracts/GovernanceStorage.sol";

/**
 * @notice CollectiveStorage creational contract
 */
contract StorageFactory is StorageCreator {
    /// @notice create a new storage object with VoterClass as the voting population
    /// @param _class the contract that defines the popluation
    /// @param _minimumDuration the least possible voting duration
    /// @return Storage the created instance
    function create(VoterClass _class, uint256 _minimumDuration) external returns (Storage) {
        GovernanceStorage _storage = new GovernanceStorage(_class, _minimumDuration);
        _storage.transferOwnership(msg.sender);
        emit StorageCreated(address(_storage), msg.sender);
        return _storage;
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
import "../contracts/VoteStrategy.sol";

/// @title Storage interface
/// @notice provides the requirements for Storage contract implementation
/// @custom:type interface
interface Storage is IERC165 {
    // event section
    event InitializeProposal(uint256 proposalId, address owner);
    event AddSupervisor(uint256 proposalId, address supervisor);
    event BurnSupervisor(uint256 proposalId, address supervisor);
    event SetQuorumRequired(uint256 proposalId, uint256 passThreshold);
    event UndoVoteEnabled(uint256 proposalId);

    event VoteCast(uint256 proposalId, address voter, uint256 shareId, uint256 totalVotesCast);
    event UndoVote(uint256 proposalId, address voter, uint256 shareId, uint256 votesUndone);
    event VoteVeto(uint256 proposalId, address supervisor);
    event VoteReady(uint256 proposalId, uint256 startTime, uint256 endTime);
    event VoteCancel(uint256 proposalId, address supervisor);

    /// @notice The current state of a proposal.
    /// CONFIG indicates the proposal is currently mutable with building
    /// and setup operations underway.
    /// Both FINAL and CANCELLED are immutable states indicating the proposal is final,
    /// however the CANCELLED state indicates the proposal never entered a voting phase.
    enum Status {
        CONFIG,
        FINAL,
        CANCELLED
    }

    /// @notice The executable transaction resulting from a proposed Governance operation
    struct Transaction {
        /// @notice target for call instruction
        address target;
        /// @notice value to pass
        uint256 value;
        /// @notice signature for call
        string signature;
        /// @notice call data of the call
        bytes _calldata;
        /// @notice future dated start time for call within the TimeLocked grace period
        uint256 scheduleTime;
    }

    /// @notice Struct describing the data required for a specific vote.
    /// @dev proposal is only valid if id != 0 and proposal.id == id;
    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposalSender;
        /// @notice The number of votes in support of a proposal required in
        /// order for a quorum to be reached and for a vote to succeed
        uint256 quorumRequired;
        /// @notice The number of blocks to delay the first vote from voting open
        uint256 voteDelay;
        /// @notice The number of blocks duration for the vote, last vote must be cast prior
        uint256 voteDuration;
        /// @notice The time when voting begins
        uint256 startTime;
        /// @notice The time when voting ends
        uint256 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstentionCount;
        /// @notice number of attached transactions
        uint256 transactionCount;
        /// @notice Flag marking whether the proposal has been vetoed
        bool isVeto;
        /// @notice Flag marking whether the proposal has been executed
        bool isExecuted;
        /// @notice current status for this proposal
        Status status;
        /// @notice this proposal allows undo votes
        bool isUndoEnabled;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(uint256 => Receipt) voteReceipt;
        /// @notice configured supervisors
        mapping(address => bool) supervisorPool;
        /// @notice table of mapped transactions
        mapping(uint256 => Transaction) transaction;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice address of voting wallet
        address wallet;
        /// @notice id of reserved shares
        uint256 shareId;
        /// @notice number of votes cast for
        uint256 shareFor;
        /// @notice The number of votes the voter had, which were cast
        uint256 votesCast;
        /// @notice did the voter abstain
        bool abstention;
        /// @notice has this share been reversed
        bool undoCast;
    }

    /// @notice Register a new supervisor on the specified proposal.
    /// The supervisor has rights to add or remove voters prior to start of voting
    /// in a Voter Pool. The supervisor also has the right to veto the outcome of the vote.
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function registerSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external;

    /// @notice remove a supervisor from the proposal along with its ability to change or veto
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function burnSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external;

    /// @notice set the minimum number of participants for a successful outcome
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _quorum the number required for quorum
    /// @param _sender original wallet for this request
    function setQuorumRequired(
        uint256 _proposalId,
        uint256 _quorum,
        address _sender
    ) external;

    /// @notice enable the undo feature for this vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function enableUndoVote(uint256 _proposalId, address _sender) external;

    /// @notice set the delay period required to preceed the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDelay the quorum number
    /// @param _sender original wallet for this request
    function setVoteDelay(
        uint256 _proposalId,
        uint256 _voteDelay,
        address _sender
    ) external;

    /// @notice set the required duration for the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDuration the quorum number
    /// @param _sender original wallet for this request
    function setVoteDuration(
        uint256 _proposalId,
        uint256 _voteDuration,
        address _sender
    ) external;

    /// @notice get the address of the proposal sender
    /// @param _proposalId the id of the proposal
    /// @return address the address of the sender
    function getSender(uint256 _proposalId) external view returns (address);

    /// @notice get the quorum required
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number required for quorum
    function quorumRequired(uint256 _proposalId) external view returns (uint256);

    /// @notice get the vote delay
    /// @param _proposalId the id of the proposal
    /// @return uint256 the delay
    function voteDelay(uint256 _proposalId) external view returns (uint256);

    /// @notice get the vote duration
    /// @param _proposalId the id of the proposal
    /// @return uint256 the duration
    function voteDuration(uint256 _proposalId) external view returns (uint256);

    /// @notice get the start time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the start time
    function startTime(uint256 _proposalId) external view returns (uint256);

    /// @notice get the end time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the end time
    function endTime(uint256 _proposalId) external view returns (uint256);

    /// @notice get the for vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of votes in favor
    function forVotes(uint256 _proposalId) external view returns (uint256);

    /// @notice get the against vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of against votes
    function againstVotes(uint256 _proposalId) external view returns (uint256);

    /// @notice get the number of abstentions
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number abstentions
    function abstentionCount(uint256 _proposalId) external view returns (uint256);

    /// @notice get the current number counting towards quorum
    /// @param _proposalId the id of the proposal
    /// @return uint256 the amount of participation
    function quorum(uint256 _proposalId) external view returns (uint256);

    /// @notice test if the address is a supervisor on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the address to check
    /// @return bool true if the address is a supervisor
    function isSupervisor(uint256 _proposalId, address _supervisor) external view returns (bool);

    /// @notice test if address is a voter on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _voter the address to check
    /// @return bool true if the address is a voter
    function isVoter(uint256 _proposalId, address _voter) external view returns (bool);

    /// @notice test if proposal is ready or in the setup phase
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked ready
    function isFinal(uint256 _proposalId) external view returns (bool);

    /// @notice test if proposal is cancelled
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked cancelled
    function isCancel(uint256 _proposalId) external view returns (bool);

    /// @notice test if proposal is veto
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked veto
    function isVeto(uint256 _proposalId) external view returns (bool);

    /// @notice get the id of the last proposal for sender
    /// @return uint256 the id of the most recent proposal for sender
    function latestProposal(address _sender) external view returns (uint256);

    /// @notice get the vote receipt
    /// @return _shareId the share id for the vote
    /// @return _shareFor the shares cast in favor
    /// @return _votesCast the number of votes cast
    /// @return _isAbstention true if vote was an abstention
    /// @return _isUndo true if the vote was reversed
    function voteReceipt(uint256 _proposalId, uint256 shareId)
        external
        view
        returns (
            uint256 _shareId,
            uint256 _shareFor,
            uint256 _votesCast,
            bool _isAbstention,
            bool _isUndo
        );

    /// @notice get the VoterClass used for this voting store
    /// @return VoterClass the voter class for this store
    function voterClass() external view returns (VoterClass);

    /// @notice initialize a new proposal and return the id
    /// @return uint256 the id of the proposal
    function initializeProposal(address _sender) external returns (uint256);

    /// @notice indicate the proposal is ready for voting and should be frozen
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function makeFinal(uint256 _proposalId, address _sender) external;

    /// @notice cancel the proposal if it is not yet started
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function cancel(uint256 _proposalId, address _sender) external;

    /// @notice veto the specified proposal
    /// @dev supervisor is required
    /// @param _proposalId the id of the proposal
    /// @param _sender the address of the veto sender
    function veto(uint256 _proposalId, address _sender) external;

    /// @notice cast an affirmative vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteForByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    /// @notice cast an against vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteAgainstByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    /// @notice cast an abstention for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function abstainForShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    /// @notice undo vote for the specified receipt
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _receiptId the id of the share to undo
    /// @return uint256 the number of votes cast
    function undoVoteById(
        uint256 _proposalId,
        address _wallet,
        uint256 _receiptId
    ) external returns (uint256);

    /// @notice add a transaction to the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _target the target address for this transaction
    /// @param _value the value to pass to the call
    /// @param _signature the tranaction signature
    /// @param _calldata the call data to pass to the call
    /// @param _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    /// @param _sender for this proposal
    /// @return uint256 the id of the transaction that was added
    function addTransaction(
        uint256 _proposalId,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata,
        uint256 _scheduleTime,
        address _sender
    ) external returns (uint256);

    /// @notice return the stored transaction by id
    /// @param _proposalId the proposal where the transaction is stored
    /// @param _transactionId The id of the transaction on the proposal
    /// @return _target the target address for this transaction
    /// @return _value the value to pass to the call
    /// @return _signature the tranaction signature
    /// @return _calldata the call data to pass to the call
    /// @return _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    function getTransaction(uint256 _proposalId, uint256 _transactionId)
        external
        view
        returns (
            address _target,
            uint256 _value,
            string memory _signature,
            bytes memory _calldata,
            uint256 _scheduleTime
        );

    /// @notice set proposal state executed
    /// @param _proposalId the id of the proposal
    /// @param _sender for this proposal
    function setExecuted(uint256 _proposalId, address _sender) external;

    /// @notice get the current state if executed or not
    /// @param _proposalId the id of the proposal
    /// @return bool true if already executed
    function isExecuted(uint256 _proposalId) external view returns (bool);

    /// @notice get the number of attached transactions
    /// @param _proposalId the id of the proposal
    /// @return uint256 current number of transactions
    function transactionCount(uint256 _proposalId) external view returns (uint256);

    /// @notice get the maxiumum possible for the pass threshold
    /// @return uint256 the maximum value
    function maxPassThreshold() external pure returns (uint256);

    /// @notice get the vote duration in seconds
    /// @return uint256 the least duration of a vote in seconds
    function minimumVoteDuration() external view returns (uint256);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32);
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

/// @title Governance interface
/// @notice Requirements for Governance implementation
/// @custom:type interface
interface Governance is IERC165 {
    /// @notice A new proposal was created
    event ProposalCreated(address sender, uint256 proposalId);
    /// @notice transaction attached to proposal
    event ProposalTransactionAttached(
        address creator,
        uint256 proposalId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    /// @notice The proposal is now open for voting
    event ProposalOpen(uint256 proposalId);
    /// @notice Voting is now closed for voting
    event ProposalClosed(uint256 proposalId);
    /// @notice The attached transactions are executed
    event ProposalExecuted(uint256 proposalId);

    /// @notice propose a vote for the community
    /// @return uint256 The id of the new proposal
    function propose() external returns (uint256);

    /// @notice Attach a transaction to the specified proposal.
    ///         If successfull, it will be executed when voting is ended.
    /// @dev must be called prior to configuration
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
    /// @param _requiredDuration The minimum time for voting to proceed before ending the vote is allowed
    function configure(
        uint256 _proposalId,
        uint256 _quorumThreshold,
        uint256 _requiredDuration
    ) external;

    /// @notice return the address of the internal vote data store
    /// @return address The address of the store
    function getStorageAddress() external view returns (address);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32);
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

import "./VoterClass.sol";
import "./VoterClassNullObject.sol";

/// @title VoteStrategy interface
/// Requirements for voting implementations in Collective Governance
/// @custom:type interface
interface VoteStrategy {
    // event section
    event VoteOpen(uint256 proposalId);
    event VoteClosed(uint256 proposalId);
    event VoteTally(uint256 proposalId, address wallet, uint256 count);
    event AbstentionTally(uint256 proposalId, address wallet, uint256 count);
    event VoteUndo(uint256 proposalId, address wallet, uint256 count);

    /// @notice start the voting process by proposal id
    /// @param _proposalId The numeric id of the proposed vote
    function startVote(uint256 _proposalId) external;

    /// @notice test if an existing proposal is open
    /// @param _proposalId The numeric id of the proposed vote
    /// @return bool True if the proposal is open
    function isOpen(uint256 _proposalId) external view returns (bool);

    /// @notice end voting on an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    function endVote(uint256 _proposalId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    function voteFor(uint256 _proposalId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteFor(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteFor(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    function voteAgainst(uint256 _proposalId) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteAgainst(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteAgainst(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    function abstainFrom(uint256 _proposalId) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function abstainFrom(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function abstainFrom(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice undo any previous vote if any
    /// @dev Only applies to affirmative vote.
    /// @param _proposalId The numeric id of the proposed vote
    function undoVote(uint256 _proposalId) external;

    /// @notice undo any previous vote if any
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function undoVote(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice undo any previous vote if any
    /// @dev only applies to affirmative vote
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function undoVote(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice veto proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev transaction must be signed by a supervisor wallet
    function veto(uint256 _proposalId) external;

    /// @notice get the result of the vote
    /// @return bool True if the vote is closed and passed
    /// @dev This method will fail if the vote was vetoed
    function getVoteSucceeded(uint256 _proposalId) external view returns (bool);
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "../contracts/Constant.sol";
import "../contracts/VoterClass.sol";

/// @title ERC721 Implementation of VoterClass
/// @notice This contract implements a voter pool based on ownership of an ERC-721 token.
/// A class member is considered a voter if they have signing access to a wallet that is marked
/// ownerOf a token of the specified address
/// @dev ERC721Enumerable is supported for discovery, however if the token contract does not support enumeration
/// then vote by specific tokenId is still supported
contract VoterClassERC721 is VoterClass, ERC165 {
    string public constant NAME = "collective VoterClassERC721";

    address private immutable _contractAddress;

    uint256 private immutable _weight;

    /// @param _contract Address of the token contract
    /// @param _voteWeight The integral weight to apply to each token held by the wallet
    constructor(address _contract, uint256 _voteWeight) {
        _contractAddress = _contract;
        _weight = _voteWeight;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidShare(uint256 _shareId) {
        require(_shareId != 0, "Share not valid");
        _;
    }

    /// @notice ERC-721 VoterClass is always final
    /// @dev always returns true
    /// @return bool true if final
    function isFinal() external pure returns (bool) {
        return true;
    }

    /// @notice determine if wallet holds at least one token from the ERC-721 contract
    /// @return bool true if wallet can sign for votes on this class
    function isVoter(address _wallet) external view requireValidAddress(_wallet) returns (bool) {
        return IERC721(_contractAddress).balanceOf(_wallet) > 0;
    }

    /// @notice tabulate the number of votes available for the specific wallet and tokenId
    /// @param _wallet The wallet to test for ownership
    /// @param _tokenId The id of the token associated with the ERC-721 contract
    function votesAvailable(address _wallet, uint256 _tokenId) external view requireValidAddress(_wallet) returns (uint256) {
        address tokenOwner = IERC721(_contractAddress).ownerOf(_tokenId);
        if (_wallet == tokenOwner) {
            return 1;
        }
        return 0;
    }

    /// @notice discover an array of tokenIds associated with the specified wallet
    /// @dev discovery requires support for ERC721Enumerable, otherwise execution will revert
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external view requireValidAddress(_wallet) returns (uint256[] memory) {
        bytes4 interfaceId721 = type(IERC721Enumerable).interfaceId;
        require(IERC721(_contractAddress).supportsInterface(interfaceId721), "ERC-721 Enumerable required");
        IERC721Enumerable enumContract = IERC721Enumerable(_contractAddress);
        IERC721 _nft = IERC721(_contractAddress);
        uint256 tokenBalance = _nft.balanceOf(_wallet);
        require(tokenBalance > 0, "Token owner required");
        uint256[] memory tokenIdList = new uint256[](tokenBalance);
        for (uint256 i = 0; i < tokenBalance; i++) {
            tokenIdList[i] = enumContract.tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIdList;
    }

    /// @notice confirm tokenId is associated with wallet for voting
    /// @dev does not require IERC721Enumerable, tokenId ownership is checked directly using ERC-721
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 _tokenId) external view requireValidShare(_tokenId) returns (uint256) {
        uint256 voteCount = this.votesAvailable(_wallet, _tokenId);
        require(voteCount > 0, "Not owner");
        return _weight * voteCount;
    }

    /// @notice return voting weight of each confirmed share
    /// @return uint256 weight applied to one share
    function weight() external view returns (uint256) {
        return _weight;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(VoterClass).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32) {
        return Constant.VERSION_1;
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../contracts/Constant.sol";
import "../contracts/VoterClass.sol";

/// @notice OpenVote VoterClass allows every wallet to participate in an open vote
contract VoterClassOpenVote is VoterClass, ERC165 {
    string public constant NAME = "collective VoterClassOpenVote";
    uint32 public constant VERSION_1 = 1;

    uint256 private immutable _weight;

    /// @param _voteWeight The integral weight to apply to each token held by the wallet
    constructor(uint256 _voteWeight) {
        _weight = _voteWeight;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidShare(address _wallet, uint256 _shareId) {
        require(_shareId > 0 && _shareId == uint160(_wallet), "Not a valid share");
        _;
    }

    /// @notice OpenVote VoterClass is always final
    /// @dev always returns true
    /// @return bool true if final
    function isFinal() external pure returns (bool) {
        return true;
    }

    /// @notice return true for all wallets
    /// @dev always returns true
    /// @return bool true if voter
    function isVoter(address _wallet) external pure requireValidAddress(_wallet) returns (bool) {
        return true;
    }

    /// @notice discover an array of shareIds associated with the specified wallet
    /// @dev the shareId of the open vote is the numeric value of the wallet address itself
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external pure requireValidAddress(_wallet) returns (uint256[] memory) {
        uint256[] memory shareList = new uint256[](1);
        shareList[0] = uint160(_wallet);
        return shareList;
    }

    /// @notice confirm shareid is associated with wallet for voting
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 _shareId) external view requireValidShare(_wallet, _shareId) returns (uint256) {
        return _weight;
    }

    /// @notice return voting weight of each confirmed share
    /// @return uint256 weight applied to one share
    function weight() external view returns (uint256) {
        return _weight;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(VoterClass).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32) {
        return Constant.VERSION_1;
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "../contracts/Constant.sol";
import "../contracts/TimeLocker.sol";

/**
 * @notice TimeLock transactions until a future time.   This is useful to guarantee that a Transaction
 * is specified in advance of a vote and to make it impossible to execute before the end of voting.
 *
 * @dev This is a modified version of Compound Finance TimeLock.
 *
 * https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/Timelock.sol
 *
 * Implements Ownable and requires owner for all operations.
 */
contract TimeLock is TimeLocker, Ownable {
    uint256 public immutable _lockTime;

    /// @notice table of transaction hashes, map to true if seen by the queueTransaction operation
    mapping(bytes32 => bool) public _queuedTransaction;

    /**
     * @param _lockDuration The time delay required for the time lock
     */
    constructor(uint256 _lockDuration) {
        if (_lockDuration < Constant.TIMELOCK_MINIMUM_DELAY || _lockDuration > Constant.TIMELOCK_MAXIMUM_DELAY) {
            revert RequiredDelayNotInRange(_lockDuration, Constant.TIMELOCK_MINIMUM_DELAY, Constant.TIMELOCK_MAXIMUM_DELAY);
        }
        _lockTime = _lockDuration;
    }

    receive() external payable {
        emit TimelockEth(msg.sender, msg.value);
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        revert NotPermitted(msg.sender);
    }

    /**
     * @notice Mark a transaction as queued for this time lock
     * @dev It is only possible to execute a queued transaction.   Queueing in the context of a TimeLock is
     * the process of identifying in advance or naming the transaction to be executed.  Nothing is actually queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 the hash value for the transaction used for the internal index
     */
    function queueTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external onlyOwner returns (bytes32) {
        bytes32 txHash = getTxHash(_target, _value, _signature, _calldata, _scheduleTime);
        uint256 blockTime = getBlockTimestamp();
        if (_scheduleTime < (blockTime + _lockTime) || _scheduleTime > (blockTime + _lockTime + Constant.TIMELOCK_GRACE_PERIOD)) {
            revert TimestampNotInLockRange(txHash, blockTime, _scheduleTime);
        }
        if (_queuedTransaction[txHash]) revert AlreadyInQueue(txHash);
        enqueue(txHash);
        emit QueueTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);
        return txHash;
    }

    /**
     * @notice cancel a queued transaction from the timelock
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     */
    function cancelTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external onlyOwner {
        bytes32 txHash = getTxHash(_target, _value, _signature, _calldata, _scheduleTime);
        if (!_queuedTransaction[txHash]) revert NotInQueue(txHash);
        unqueue(txHash);
        emit CancelTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);
    }

    /**
     * @notice If the time lock is concluded, execute the scheduled transaction.
     * @dev It is only possible to execute a queued transaction.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes The return data from the executed call
     */
    function executeTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(_target, _value, _signature, _calldata, _scheduleTime);
        if (!_queuedTransaction[txHash]) {
            revert NotInQueue(txHash);
        }
        uint256 blockTime = getBlockTimestamp();
        if (blockTime < _scheduleTime) {
            revert TransactionLocked(txHash, _scheduleTime);
        }
        if (blockTime > (_scheduleTime + Constant.TIMELOCK_GRACE_PERIOD)) {
            revert TransactionStale(txHash);
        }

        unqueue(txHash);

        bytes memory callData;
        if (bytes(_signature).length == 0) {
            callData = _calldata;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _calldata);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool ok, bytes memory returnData) = _target.call{value: _value}(callData);
        if (!ok) revert ExecutionFailed(txHash);

        emit ExecuteTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);

        return returnData;
    }

    /**
     * Calculate the hash code of the specified transaction.  This is used as the transaction id
     * for marking the transaction as queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 The 32 byte hash of the transaction
     */
    function getTxHash(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) public pure returns (bytes32) {
        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature, _calldata, _scheduleTime));
        return txHash;
    }

    function enqueue(bytes32 txHash) private {
        _queuedTransaction[txHash] = true;
    }

    function unqueue(bytes32 txHash) private {
        // overwrite memory to protect against value rebinding
        _queuedTransaction[txHash] = false;
        delete _queuedTransaction[txHash];
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
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

import "../contracts/VoterClass.sol";
import "../contracts/Storage.sol";

/**
 * @notice Factory interface for CollectiveStorage
 */
/// @custom:type interface
interface StorageCreator {
    event StorageCreated(address _storage, address _owner);

    /// @notice create a new storage object with VoterClass as the voting population
    /// @param _class the contract that defines the popluation
    /// @param _minimumDuration the least possible voting duration
    /// @return Storage the created instance
    function create(VoterClass _class, uint256 _minimumDuration) external returns (Storage);
}

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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./VoterClass.sol";

/// @notice Null Object Pattern for VoterClass
/// @dev No voter is allowed.
contract VoterClassNullObject is VoterClass, ERC165 {
    string public constant NAME = "collective VoterClassNullObject";

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    /// @notice always final
    /// @return bool always returns true
    function isFinal() external pure returns (bool) {
        return true;
    }

    /// @notice no voter is allowed
    /// @return bool always returns false
    function isVoter(address _wallet) external pure requireValidAddress(_wallet) returns (bool) {
        return false;
    }

    /// @notice always reverts
    function discover(address _wallet) external pure requireValidAddress(_wallet) returns (uint256[] memory) {
        revert("Not a voter");
    }

    /// @notice always returns 0
    function confirm(
        address, /* _wallet */
        uint256 /* shareId */
    ) external pure returns (uint256) {
        return 0;
    }

    /// @notice always returns 0
    function weight() external pure returns (uint256) {
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(VoterClass).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice return the version of this implementation
    /// @return uint32 version number
    function version() external pure returns (uint32) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

/**
 * @notice TimeLock transactions until a future time.   This is useful to guarantee that a Transaction
 * is specified in advance of a vote and to make it impossible to execute before the end of voting.
 */
/// @custom:type interface
interface TimeLocker {
    /// @notice operation is not used or forbidden
    error NotPermitted(address sender);
    /// @notice A transaction has been queued previously
    error AlreadyInQueue(bytes32 txHash);
    /// @notice The timestamp or nonce specified does not meet the requirements for the timelock
    error TimestampNotInLockRange(bytes32 txHash, uint256 timestamp, uint256 scheduleTime);
    /// @notice The provided delay does not meet the requirements for the TimeLock
    error RequiredDelayNotInRange(uint256 lockDelay, uint256 minDelay, uint256 maxDelay);
    /// @notice It is impossible to execute a call which is not in the queue already
    error NotInQueue(bytes32 txHash);
    /// @notice The specified transaction is currently locked.  Caller must wait to scheduleTime
    error TransactionLocked(bytes32 txHash, uint256 untilTime);
    /// @notice The grace period is past and the transaction is lost
    error TransactionStale(bytes32 txHash);
    /// @notice Call failed
    error ExecutionFailed(bytes32 txHash);

    event TimelockEth(address sender, uint256 amount);
    event TransferEth(address recipient, uint256 amount);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /**
     * @notice Mark a transaction as queued for this time lock
     * @dev It is only possible to execute a queued transaction.   Queueing in the context of a TimeLock is
     * the process of identifying in advance or naming the transaction to be executed.  Nothing is actually queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 the hash value for the transaction used for the internal index
     */
    function queueTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);

    /**
     * @notice cancel a queued transaction from the timelock
     *
     * @dev this method unmarks the named transaction so that it may not be executed
     *
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     */
    function cancelTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external;

    /**
     * @notice Execute the scheduled transaction at the end of the time lock or scheduled time.
     * @dev It is only possible to execute a queued transaction.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes The return data from the executed call
     */
    function executeTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external payable returns (bytes memory);

    /**
     * Calculate the hash code of the specified transaction.  This is used as the transaction id
     * for marking the transaction as queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 The 32 byte hash of the transaction
     */
    function getTxHash(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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