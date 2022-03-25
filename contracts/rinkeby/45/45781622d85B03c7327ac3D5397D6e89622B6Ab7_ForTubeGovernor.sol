// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./IForTubeGovernor.sol";

contract ForTubeGovernor is Initializable, ForTubeGovernorStorage, ForTubeGovernorEvents {
    /// @notice The name of this contract
    string public constant name = "ForTube Governor";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 76000e18; // 76,000 FDAO

    // /// @notice The minimum setable voting period
    // uint public constant MIN_VOTING_PERIOD = 5760; // About 24 hours，1 block == 15s

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

    /// @notice The min setable voting delay
    // uint public constant MIN_VOTING_DELAY = 5760; // About 24 Hours, 1 block = 15s

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public constant quorumVotes = 400000e18; // 400,000 FDAO

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 100; // 100 actions, for update so many ftokens

    /**
      * @notice Used to initialize the contract during delegator contructor
      * @param admin_ The address of the MultiSig
      * @param fdao_ The address of the FDAO token
      * @param minVotingPeriod_ The initial voting period
      * @param proposalThreshold_ The initial proposal threshold
      */
    function initialize(address admin_, address fdao_, uint minVotingPeriod_, uint minVotingDelay_, uint proposalThreshold_) external initializer {
        require(admin_ != address(0), "ForTubeGovernor::initialize: invalid admin address");
        require(fdao_ != address(0), "ForTubeGovernor::initialize: invalid FDAO address");
        minVotingPeriod = minVotingPeriod_; // init to 5760 (24H) in prod
        minVotingDelay = minVotingDelay_; // init to 5760 (24H) in prod
        require(minVotingDelay_ <= MAX_VOTING_DELAY, "ForTubeGovernor::propose: invalid voting delay");
        require(proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD, "ForTubeGovernor::initialize: invalid proposal threshold");

        fdao = IFdao(fdao_);
        proposalThreshold = proposalThreshold_;

        admin = admin_;
    }

    /**
      * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
      * @param executables all the exectables in the proposal
      * @param description description of the proposal
      * @param options voted options count
      * @param startBlock voting start block number
      * @param votingPeriod voting Peroid in block unit
      * @return Proposal id of new proposal
      */
    function propose(bytes[] memory executables, string memory description, uint options, uint256 startBlock, uint256 votingPeriod) public returns (uint) {
        require(options >= 2, "invalid options");
        require(startBlock > block.number + minVotingDelay && startBlock <= block.number + MAX_VOTING_DELAY, "invalid block number");
        require(executables.length == options, "ForTubeGovernor::propose: executables != options");
        require(votingPeriod >= minVotingPeriod && votingPeriod <= MAX_VOTING_PERIOD, "ForTubeGovernor::propose: invalid voting period");

        require(fdao.getPriorVotes(msg.sender, sub256(block.number, 1)) >= proposalThreshold, "ForTubeGovernor::propose: proposer votes below proposal threshold");
        for (uint i = 0; i < options; i++) {
            (, address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, ) = abi.decode(executables[i], (uint[], address[], uint[], string[], bytes[], string));

            require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "ForTubeGovernor::propose: proposal function information arity mismatch");
            require(targets.length <= proposalMaxOperations, "ForTubeGovernor::propose: too many actions");
        }

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "ForTubeGovernor::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "ForTubeGovernor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint endBlock = add256(startBlock, votingPeriod);

        uint[] memory _votes = new uint[](options);
        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            executables: executables,
            startBlock: startBlock,
            endBlock: endBlock,
            votes: _votes,
            canceled: false,
            executed: false,
            winning: uint(-1), // invalid option, 0 is valid, so use -1 as invalid.
            options: options
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, executables, startBlock, endBlock, description);
        return newProposal.id;
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint proposalId) external payable {
        require(msg.sender == admin, "ForTubeGovernor::execute: Call must come from admin.");
        require(state(proposalId) == ProposalState.Succeeded, "ForTubeGovernor::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        require(proposal.winning != uint(-1), "!winning");

        emit ProposalExecuted(proposalId);
    }

    /**
      * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
      * @param proposalId The id of the proposal to cancel
      */
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed && state(proposalId) != ProposalState.Canceled, "ForTubeGovernor::cancel: cannot cancel executed or canceled proposal");

        Proposal storage proposal = proposals[proposalId];

        // Proposer can cancel
        if(msg.sender != proposal.proposer) {
            require(fdao.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold, "ForTubeGovernor::cancel: proposer above threshold");
        }

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
      * @notice Gets actions of a proposal
      * @param proposalId the id of the proposal
      * @param option the option of the proposal
      * @return chain_ids chain_ids of the proposal actions
      * @return targets targets of the proposal actions
      * @return values values of the proposal actions
      * @return signatures signatures of the proposal actions
      * @return calldatas calldatas of the proposal actions
      */
    function getActions(uint proposalId, uint option) external view returns (uint[] memory chain_ids, address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory descriptions) {
        Proposal storage p = proposals[proposalId];
        require(option < p.executables.length, "option out of range");
        (chain_ids, targets, values, signatures, calldatas, descriptions) = abi.decode(p.executables[option], (uint[], address[], uint[], string[], bytes[], string));
    }

    function getExecutables(uint proposalId) external view returns (bytes[] memory executeables) {
        Proposal storage p = proposals[proposalId];
        return p.executables;
    }

    function getExecutablesAt(uint proposalId, uint index) external view returns (bytes memory executeables) {
        Proposal storage p = proposals[proposalId];
        require(index < p.executables.length, "index out of range");
        return p.executables[index];
    }

    /**
      * @notice Gets the receipt for a voter on a given proposal
      * @param proposalId the id of proposal
      * @param voter The address of the voter
      * @return The voting receipt
      */
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
      * @notice Gets the state of a proposal
      * @param proposalId The id of the proposal
      * @return Proposal state
      */
    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "ForTubeGovernor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.winning == uint(-1) || proposal.votes[proposal.winning] < quorumVotes) {
            return ProposalState.Failed;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Succeeded;
        }
    }

    /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support zero-based index for the vote.
      */
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support));
    }

    /**
      * @notice Internal function that caries out voting logic
      * @param voter The voter that is casting their vote
      * @param proposalId The id of the proposal to vote on
      * @param support The support zero-based index for the vote.
      * @return The number of votes cast
      */
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint96) {
        require(state(proposalId) == ProposalState.Active, "ForTubeGovernor::castVoteInternal: voting is closed");
        require(support < proposals[proposalId].options, "ForTubeGovernor::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "ForTubeGovernor::castVoteInternal: voter already voted");
        uint96 votes = fdao.getPriorVotes(voter, proposal.startBlock);

        proposal.votes[support] = add256(proposal.votes[support], votes);

        uint _max = proposal.winning == uint(-1) ? 0 : proposal.votes[proposal.winning];
        if (proposal.votes[support] > _max) {
            proposal.winning = support;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
      * @notice Admin function for setting the proposal threshold
      * @dev newProposalThreshold must be greater than the hardcoded min
      * @param newProposalThreshold new proposal threshold
      */
    function _setProposalThreshold(uint newProposalThreshold) external {
        require(msg.sender == admin, "ForTubeGovernor::_setProposalThreshold: admin only");
        require(newProposalThreshold >= MIN_PROPOSAL_THRESHOLD, "ForTubeGovernor::_setProposalThreshold: invalid proposal threshold");
        uint oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "ForTubeGovernor:_setPendingAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "ForTubeGovernor:_acceptAdmin: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract ForTubeGovernorEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, bytes[] executables, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support index for the vote.
    /// @param votes Number of votes which were cast by the voter
    event VoteCast(address indexed voter, uint proposalId, uint8 support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    /// @notice Emitted when proposal threshold is set
    event ProposalThresholdSet(uint oldProposalThreshold, uint newProposalThreshold);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);
}

/**
 * @title Storage for ForTube Governor
 * @notice For future upgrades, do not change ForTubeGovernorDelegateStorageV1. Create a new
 * contract which implements ForTubeGovernorDelegateStorageV1 and following the naming convention
 * ForTubeGovernorDelegateStorageVX.
 */
contract ForTubeGovernorStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice The min setable voting delay
    uint public minVotingDelay; // 5760, About 24 Hours, 1 block = 15s for production

    /// @notice The minimum setable voting period
    uint public minVotingPeriod;// 5760, About 24 hours，1 block == 15s

    /// @notice The number of votes required in order for a voter to become a proposer
    uint public proposalThreshold;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The address of the ForTube governance token
    IFdao public fdao;

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    struct Proposal {
        // @notice Unique id for looking up a proposal
        uint id;

        // @notice Creator of the proposal
        address proposer;

        // every executable is decoded to address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description
        bytes[] executables;

        // @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        // @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        uint[] votes; // votes[x] is current number of votes to x in this proposal

        // @notice Flag marking whether the proposal has been canceled
        bool canceled;

        // @notice Flag marking whether the proposal has been executed
        bool executed;

        // @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;

        uint winning;
        uint options;// option count
    }

    /// Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal or abstains, expand for multi options
        uint8 support;

        // The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Failed,
        Succeeded,
        Executed
    }
}

interface IFdao {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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