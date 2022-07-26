// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./manager/TransactionManager.sol";
import "./manager/FallbackManager.sol";

/// @title A cool multisig wallet
/// @author Hyodar
/// @notice A contract that basically works as a shared wallet, allowing a
///     group of members to participate in a form of on-chain quorum to vote
///     on transactions to be executed by the wallet
contract MultisigWallet is TransactionManager, FallbackManager {
    constructor(address[] memory members, uint256 requiredApprovals_) {
        _setupMembership(members, requiredApprovals_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../utils/MemberList.sol";
import "../utils/Operation.sol";
import "./MembershipManager.sol";

/// @title Multisig transaction proposal and execution logic
/// @author Hyodar
/// @notice Manages transactions and provides related utility functions
abstract contract TransactionManager is MembershipManager {
    using MemberList for MemberList.List;

    /// @notice All transaction proposals ever made in the wallet
    /// @custom:security write-protection="onlyMember()"
    TransactionProposal[] internal _transactionProposals;

    /// @notice Map that records, per transaction, the approvals of any addresses
    /// @custom:security write-protection="onlyMember()"
    mapping(uint256 => mapping(address => bool)) public transactionApprovedBy;

    /// @notice Container for transaction proposal information
    /// @member to Destination of the transaction that would be executed
    /// @member executed Flag that indicates whether a transaction has already
    ///     been executed or not
    /// @member value The ether value to be sent in the transaction
    /// @member data The encoded transaction data
    struct TransactionProposal {
        address to;
        bool executed;
        Operation operation;
        uint256 value;
        uint256 refundAmount;
        bytes data;
    }

    /// @notice Emitted when a transaction proposal is created by a member
    /// @param member The address of the member that created the proposal
    /// @param transactionId The ID of the transaction proposal
    event TransactionProposalCreated(
        address indexed member,
        uint256 indexed transactionId
    );

    /// @notice Emitted when a transaction proposal is approved by a member
    /// @param member The address of the member that approved the proposal
    /// @param transactionId The ID of the transaction proposal being approved
    event TransactionProposalApproved(
        address indexed member,
        uint256 indexed transactionId
    );

    /// @notice Emitted when a transaction proposal approval is revoked by a
    ///     member
    /// @param member The address of the member that revoked its approval
    /// @param transactionId The ID of the previously approved transaction proposal
    event TransactionProposalApprovalRevoked(
        address indexed member,
        uint256 indexed transactionId
    );

    /// @notice Emitted when a transaction proposal is executed by a member
    /// @param member The address of the member that executed the proposal
    /// @param transactionId The ID of the executed transaction proposal
    event TransactionProposalExecuted(
        address indexed member,
        uint256 indexed transactionId
    );

    /// @notice Checks whether a transaction proposal has passed (i.e. its
    ///     member approvals are greater than or equal to the required
    ///     approvals)
    /// @dev Expensive operation, O(n)
    modifier proposalPassed(uint256 transactionId) {
        uint256 _memberCount = memberCount();
        uint256 approvals = 0;

        unchecked {
            // nothing can realistically overflow here
            for (
                uint256 i = 0;
                i < _memberCount && approvals < requiredApprovals;
                i++
            ) {
                if (transactionApprovedBy[transactionId][_members.at(i)]) {
                    approvals++;
                }
            }
        }

        require(approvals >= requiredApprovals, "Not enough approvals");

        _;
    }

    /// @notice Checks whether a transaction proposal exists in the list
    modifier proposalExists(uint256 transactionId) {
        require(
            transactionId < _transactionProposals.length, "Unknown proposal"
        );
        _;
    }

    /// @notice Checks whether a transaction proposal is still open to voting
    ///     (i.e. it hasn't yet been executed)
    modifier proposalOpen(uint256 transactionId) {
        require(
            !_transactionProposals[transactionId].executed,
            "This transaction has already been executed"
        );
        _;
    }

    /// @notice Opens a transaction for voting
    /// @dev Can only be called by a member
    /// @param to Call destination
    /// @param operation Operation type (call or delegatecall)
    /// @param value Ether value to be sent in the call
    /// @param data Encoded call data
    function proposeTransaction(
        address to,
        Operation operation,
        uint256 value,
        bytes calldata data,
        uint256 refundAmount
    )
        public
        onlyMember
    {
        if (operation == Operation.DELEGATE_CALL) {
            require(value == 0, "Cannot send value in delegatecall");
        }

        _transactionProposals.push(
            TransactionProposal({
                to: to,
                operation: operation,
                executed: false,
                value: value,
                data: data,
                refundAmount: refundAmount
            })
        );

        unchecked {
            // _transactionProposals.length > 0
            emit TransactionProposalCreated(
                msg.sender, _transactionProposals.length - 1
                );
        }
    }

    /// @notice Opens a transaction for voting and approves it
    /// @dev Can only be called by a member
    /// @param to Call destination
    /// @param operation Operation type (call or delegatecall)
    /// @param value Ether value to be sent in the call
    /// @param data Encoded call data
    function proposeAndApprove(
        address to,
        Operation operation,
        uint256 value,
        bytes calldata data,
        uint256 refundAmount
    )
        external
        onlyMember
    {
        proposeTransaction(to, operation, value, data, refundAmount);

        unchecked {
            // _transactionProposals.length > 0
            approve(_transactionProposals.length - 1);
        }
    }

    /// @notice Approves a transaction proposal
    /// @dev Can only be called by a member, requires that the proposal is
    ///     still open to voting and that the proposal wasn't yet approved by
    ///     this member
    /// @param transactionId ID of the transaction proposal to be approved
    function approve(uint256 transactionId)
        public
        onlyMember
        proposalExists(transactionId)
        proposalOpen(transactionId)
    {
        require(
            !transactionApprovedBy[transactionId][msg.sender],
            "Sender already approved this proposal"
        );

        transactionApprovedBy[transactionId][msg.sender] = true;
        emit TransactionProposalApproved(msg.sender, transactionId);
    }

    /// @notice Revokes a previous transaction proposal approval
    /// @dev Can only be called by a member, requires that the proposal is
    ///     still open to voting and that the proposal was already approved by
    ///     this member
    /// @param transactionId ID of the transaction proposal to have the
    ///      sender's approval revoked
    function revokeApproval(uint256 transactionId)
        external
        onlyMember
        proposalExists(transactionId)
        proposalOpen(transactionId)
    {
        require(
            transactionApprovedBy[transactionId][msg.sender],
            "Sender didn't approve this proposal"
        );

        transactionApprovedBy[transactionId][msg.sender] = false;
        emit TransactionProposalApprovalRevoked(msg.sender, transactionId);
    }

    /// @notice Executes a transaction whose proposal has passed voting
    /// @dev Can only be called by a member, requires that the proposal
    ///     is still open and already has at least the required approvals.
    ///     None of the calls should allow reentering execute() with the
    ///     same transaction since when those happen the transaction is
    ///     already marked as executed, so proposalOpen() would revert.
    ///     Refer to {MultisigWalletTest-testCannotReenterExecuteWithTheSameTransaction}
    /// @param transactionId ID of the transaction proposal to be executed
    function execute(uint256 transactionId)
        external
        onlyMember
        proposalExists(transactionId)
        proposalOpen(transactionId)
        proposalPassed(transactionId)
    {
        TransactionProposal storage transaction =
            _transactionProposals[transactionId];
        transaction.executed = true;

        bool success;

        // emit first so the event order stays the same even if the first call
        // leads to another execute() somehow
        emit TransactionProposalExecuted(msg.sender, transactionId);

        if (transaction.operation == Operation.CALL) {
            // slither-disable-next-line low-level-calls
            (success,) = address(transaction.to).call{
                value: transaction.value,
                gas: gasleft()
            }(transaction.data);
        } else {
            // slither-disable-next-line low-level-calls
            (success,) = address(transaction.to).delegatecall{gas: gasleft()}(
                transaction.data
            );
        }

        require(success, "Transaction was not successful");

        uint256 refundAmount = transaction.refundAmount;

        if (refundAmount != 0) {
            (success,) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund was not successful");
        }
    }

    /// @notice Gets a transaction proposal through its ID
    function getTransactionProposal(uint256 transactionId)
        external
        view
        returns (TransactionProposal memory)
    {
        return _transactionProposals[transactionId];
    }

    /// @notice Gets the amount of transaction proposals made in this wallet
    function getTransactionProposalCount() external view returns (uint256) {
        return _transactionProposals.length;
    }

    /// @notice Gets the members that approved a transaction proposal
    /// @param transactionId The ID of the transaction proposal
    function getApprovingMembers(uint256 transactionId)
        external
        view
        returns (address[] memory)
    {
        uint256 _memberCount = memberCount();
        address[] memory _approvingMembers = new address[](_memberCount);
        uint256 approvals = 0;

        unchecked {
            // nothing could realistically overflow in here
            for (uint256 i = 0; i < _memberCount; i++) {
                address member = _getMember(i);

                if (transactionApprovedBy[transactionId][member]) {
                    _approvingMembers[approvals++] = member;
                }
            }
        }

        address[] memory approvingMembers = new address[](approvals);

        unchecked {
            // nothing could realistically overflow in here
            for (uint256 i = 0; i < approvals; i++) {
                approvingMembers[i] = _approvingMembers[i];
            }
        }

        return approvingMembers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MembershipManager.sol";

/// @title Multisig fallback contract management logic
/// @author Hyodar
/// @notice Adds the possibility of setting a fallback contract to a multisig
///     wallet through a vote.
/// @dev This fallback contract could be used to cover
///     cases in which there's the necessity of the multisig to be responding
///     to functions it wasn't designed for, increasing reusability. Inspired
///     by Gnosis Safe. Gnosis article on this: <https://help.gnosis-safe.io/en/articles/4738352-what-is-a-fallback-handler-and-how-does-it-relate-to-the-gnosis-safe>
abstract contract FallbackManager is MembershipManager {
    /// @notice Fallback contract that will be called when fallback() is triggered
    /// @custom:security write-protection="onlyWallet()"
    address public fallbackContract;

    /// @notice Emitted when the wallet's fallback contract is changed
    /// @param previous Previous fallback contract address
    /// @param current Current fallback contract address
    event FallbackContractChanged(
        address indexed previous,
        address indexed current
    );

    /// @notice Emitted when the contract receives ether through receive()
    /// @param from Address that deposited ether into the wallet
    /// @param value Amount of wei deposited into the wallet
    event Deposit(address indexed from, uint256 value);

    /// @notice Sets the fallback contract address
    /// @dev Can only be called from the wallet itself
    function setFallbackContract(address fallbackContract_)
        external
        onlyWallet
    {
        emit FallbackContractChanged(fallbackContract, fallbackContract_);
        // slither-disable-next-line missing-zero-check
        fallbackContract = fallbackContract_;
    }

    /// @notice Makes a call to the fallback contract if it exists and
    ///     returns the result
    /// @dev The fallback contract must be set and it's required that the call
    ///     is successful
    fallback(bytes calldata callData) external payable returns (bytes memory) {
        if (fallbackContract == address(0)) {
            if (msg.value != 0) {
                emit Deposit(msg.sender, msg.value);
            }

            return "";
        }

        // slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) =
            fallbackContract.call{gas: gasleft(), value: msg.value}(callData);

        require(success);

        return returnData;
    }

    /// @notice Receives ether with no additional message data
    receive() external payable {
        if (msg.value != 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title An enumerable map-like member container
/// @author Hyodar
/// @notice This library can be used for storing members and cheaply checking
///     if an address is a member or not
library MemberList {
    struct List {
        address[] _members;
        // order as 1-indexed positions, since entries that are not set are 0
        mapping(address => uint256) _memberOrder;
    }

    /// @notice Checks whether an account is a member or not
    /// @dev Uses an underlying map in order to do this, so no O(n) required
    /// @param self The List instance
    /// @param account The account address to be checked
    function contains(List storage self, address account)
        internal
        view
        returns (bool)
    {
        return self._memberOrder[account] != 0;
    }

    /// @notice Adds an account address to the member list
    /// @dev The account must not be a member and must not be the zero address
    /// @param self The List instance
    /// @param account The account address to be added
    function add(List storage self, address account) internal {
        require(!contains(self, account), "Account is already a member");
        require(account != address(0), "Zero address cannot be added as member");

        self._members.push(account);
        self._memberOrder[account] = self._members.length;
    }

    /// @notice Removes an account address from the member list
    /// @dev The account must be a member
    /// @param self The List instance
    /// @param account The account address to be removed
    function remove(List storage self, address account) internal {
        uint256 removedMemberOrder = self._memberOrder[account];

        require(removedMemberOrder != 0, "Account is not a member");

        uint256 memberCount = self._members.length;

        if (removedMemberOrder != memberCount) {
            address lastMember;

            unchecked {
                // there is at least one member, memberCount > 0
                lastMember = self._members[memberCount - 1];

                // removedMemberOrder > 0
                self._members[removedMemberOrder - 1] = lastMember;
            }

            self._memberOrder[lastMember] = removedMemberOrder;
        }

        self._members.pop();
        delete self._memberOrder[account];
    }

    /// @notice Replaces an account address in the member list with another
    ///     address
    /// @dev The `from` account must be a member and the `to` account must not
    ///     be a member and must not be the zero address
    /// @param self The List instance
    /// @param from The current member to be replaced
    /// @param to The non-member that will replace `from`
    function replace(List storage self, address from, address to) internal {
        require(!contains(self, to), "Account is already a member");
        require(to != address(0), "Zero address cannot be added as member");

        uint256 replacedMemberOrder = self._memberOrder[from];
        require(replacedMemberOrder != 0, "Replaced account is not a member");

        unchecked {
            // replacedMemberOrder > 0
            self._members[replacedMemberOrder - 1] = to;
        }

        self._memberOrder[to] = replacedMemberOrder;
        delete self._memberOrder[from];
    }

    /// @notice Gets the member at a specified position in the array
    /// @dev `index` must be less than the members list length
    /// @param self The List instance
    /// @param index The index in the members array
    function at(List storage self, uint256 index)
        internal
        view
        returns (address)
    {
        return self._members[index];
    }

    /// @notice Gets the underlying members array
    /// @dev Results in a (possibly large) array copy. Prefer {MemberList-at}
    ///     when possible.
    /// @param self The List instance
    function values(List storage self)
        internal
        view
        returns (address[] memory)
    {
        return self._members;
    }

    /// @notice Gets the amount of members
    /// @param self The List instance
    function length(List storage self) internal view returns (uint256) {
        return self._members.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @notice Transaction operation types
enum Operation {
    CALL,
    DELEGATE_CALL
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../utils/MemberList.sol";

/// @title Multisig membership management logic
/// @author Hyodar
/// @notice Manages members and provides related utility functions
abstract contract MembershipManager {
    using MemberList for MemberList.List;

    /// @notice Member list
    MemberList.List internal _members;

    /// @notice Required approvals in order to execute a transaction
    /// @custom:security write-protection="onlyWallet()"
    uint256 public requiredApprovals;

    /// @notice Emitted when a member is added
    /// @param account Newly added member
    event MemberAdded(address indexed account);

    /// @notice Emitted when a member is removed
    /// @param account Newly removed member
    event MemberRemoved(address indexed account);

    /// @notice Emitted when the wallet's required approvals value is changed
    event RequiredApprovalsChanged(uint256 previous, uint256 current);

    /// @notice Checks whether the msg.sender is the wallet address
    modifier onlyWallet() {
        require(msg.sender == address(this), "Wallet-specific operation");
        _;
    }

    /// @notice Checks whether the msg.sender is a member
    modifier onlyMember() {
        require(isMember(msg.sender), "Member-specific operation");
        _;
    }

    /// @notice Checks whether a member count and required approvals setup is
    ///     valid - that is, if both are different from 0 and the required
    ///     approvals value is not greater than the member count.
    modifier validSetup(uint256 memberCount_, uint256 requiredApprovals_) {
        require(
            memberCount_ != 0 && requiredApprovals_ != 0,
            "There should be at least one member and at least one approval should be required"
        );
        require(
            requiredApprovals_ <= memberCount_,
            "Required approvals should not be greater than the amount of members"
        );
        _;
    }

    /// @notice Adds a wallet member
    /// @dev Can only be called by the wallet itself, the account must not be
    ///     a member and must not be the zero address
    /// @param account The account address to be added as member
    function addMember(address account) external onlyWallet {
        _addMember(account);
    }

    /// @notice Removes a wallet member
    /// @dev Can only be called by the wallet itself, the account must be a
    ///     member
    /// @param account The account address to be removed from the member list
    function removeMember(address account) external onlyWallet {
        _removeMember(account);
    }

    /// @notice Replaces a wallet member with another address
    /// @dev Can only be called by the wallet itself, the `from` account must
    ///     be a member and the `to` account must not be a member and must not
    ///     be the zero address
    /// @param from The current member to be replaced
    /// @param to The non-member that will replace `from`
    function replaceMember(address from, address to) external onlyWallet {
        _replaceMember(from, to);
    }

    /// @notice Sets the required approvals in order for a transaction to be
    ///     executed
    /// @dev Can only be called by the wallet itself and the final setup of
    ///     member count and required approvals must be valid. Refer to
    ///     {MembershipManager-validSetup}
    function setRequiredApprovals(uint256 requiredApprovals_)
        external
        onlyWallet
    {
        _setRequiredApprovals(requiredApprovals_);
    }

    /// @notice Gets the members list as an array
    /// @dev Results in a (possibly large) array copy.
    function getMembers() external view returns (address[] memory) {
        return _members.values();
    }

    /// @notice Checks whether an account is a member or not
    /// @dev Uses an underlying map in order to do this, so no O(n) required
    function isMember(address account) public view returns (bool) {
        return _members.contains(account);
    }

    /// @notice Gets the amount of members
    function memberCount() public view returns (uint256) {
        return _members.length();
    }

    /// @notice Gets a member from its index
    function _getMember(uint256 index) internal view returns (address) {
        return _members.at(index);
    }

    /// @notice Adds an account address to the member list
    /// @dev The account must not be a member and must not be the zero address
    /// @param account The account address to be added
    function _addMember(address account) internal {
        require(account != address(this), "Wallet cannot be added as member");

        _members.add(account);

        emit MemberAdded(account);
    }

    /// @notice Removes an account address from the member list
    /// @dev The account must be a member
    /// @param account The account address to be removed
    function _removeMember(address account)
        internal
        validSetup(_members.length() - 1, requiredApprovals)
    {
        _members.remove(account);

        emit MemberRemoved(account);
    }

    /// @notice Replaces an account address in the member list with another
    ///     address
    /// @dev The `from` account must be a member and the `to` account must not
    ///     be a member and must not be the zero address
    /// @param from The current member to be replaced
    /// @param to The non-member that will replace `from`
    function _replaceMember(address from, address to) internal {
        _members.replace(from, to);

        emit MemberRemoved(from);
        emit MemberAdded(to);
    }

    /// @notice Sets the required approvals in order for a transaction to be
    ///     executed
    /// @dev The final setup of member count and required approvals must be
    ///     valid. Refer to {MembershipManager-validSetup}
    function _setRequiredApprovals(uint256 requiredApprovals_)
        internal
        validSetup(_members.length(), requiredApprovals_)
    {
        emit RequiredApprovalsChanged(requiredApprovals, requiredApprovals_);
        requiredApprovals = requiredApprovals_;
    }

    /// @notice Sets up the initial membership data
    /// @dev The members array must be a non-empty array with no repeated
    ///     entries and must not have any zero addresses. The required
    ///     approvals must not be zero and must be at most the length of
    ///     `members`.
    function _setupMembership(
        address[] memory members,
        uint256 requiredApprovals_
    )
        internal
    {
        for (uint256 i = 0; i < members.length; i++) {
            _addMember(members[i]);
        }

        _setRequiredApprovals(requiredApprovals_);
    }
}