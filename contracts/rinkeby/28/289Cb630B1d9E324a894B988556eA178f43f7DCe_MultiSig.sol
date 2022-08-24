// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error MultiSig__OnlyOwner();
error MultiSig__CtorNotEnoughOwners();
error MultiSig__CtorTooManyOwners();
error MultiSig__OwnerInvalidAddress();
error MultiSig__CtorListOfOwnersHasDuplicatedAddresses();
error MultiSig__TxAlreadyExecuted();
error MultiSig__TxDoesNotExist();
error MultiSig__TxAlreadyConfirmed();
error MultiSig__TxCannotExecute();
error MultiSig__TxExecuteFailed();
error MultiSig__TxAlreadySubmitted();
error MultiSig__AddOwnerFailed();
error MultiSig__RemoveOwnerFailed();

/** @title A multisignature wallet contract
 *  @author Brice Grenard
 *  @notice This contract is a mutlisig wallet that is being used for the marketplace contract I have been working on.
 *  It allows any contract's owner to make a proposal. Anyone including the proposal's author is welcomed to confirm it.
 *  If a proposal has gained enough confirmation, the transaction can be executed.
 */
contract MultiSig {
    using SafeMath for uint256;

    /* events */
    event TxSubmitted(
        address indexed owner,
        uint256 indexed nonce,
        address indexed to,
        uint256 value,
        bytes data
    );
    event TxConfirmed(address indexed owner, uint256 indexed nonce);
    event TxExecuted(address indexed owner, uint indexed nonce);
    event MultiSigOwnerAdded(address indexed owner, uint256 indexed timestamp);
    event MultiSigOwnerRemoved(
        address indexed owner,
        uint256 indexed timestamp
    );

    uint8 immutable i_minimumOwnersCount = 3;
    uint8 immutable i_maximumOwnersCount = 20;
    //80% of owners required to approve a transaction, in this contract approve fct is executeTx()
    uint8 immutable i_percentageOwnersRequiredForApproval = 80;

    //array of owner addresses stored in contract
    address[] private s_owners;
    //mapping that allows to track if an address is a owner
    mapping(address => bool) private s_isOwner;
    //for a given transaction nonce, returns the transaction object associated
    mapping(uint256 => Tx) private s_transactions;
    //for a given transaction nonce, track if a owner address has confirmed a transaction
    mapping(uint256 => mapping(address => bool)) hasConfirmed;
    //calculated number of owners required to execute a transaction
    uint256 private s_nbOwnerConfirmationsRequiredForApproval;

    //A transaction object
    struct Tx {
        address to;
        uint256 nonce;
        uint256 value;
        bytes data;
        bool executed;
        uint8 nbOwnerConfirmationsProcessed;
    }

    // Modifier
    /**
     * Prevents any single owner to interact with the here-below functions decorated with this modifier
     * It is used in addOwner and removeOwner functions
     * The goal is to force proposal on adding/removing a user using this multisig wallet
     */
    modifier onlyThisWallet() {
        require(msg.sender == address(this));
        _;
    }

    // Modifier
    /**
     * Allows only owners registered into this contract to use functions decorated with this modifier
     */
    modifier onlyOwner() {
        if (!s_isOwner[msg.sender]) revert MultiSig__OnlyOwner();
        _;
    }

    // Modifier
    /**
     * Prevents the confirmation of a non-existing transaction
     */
    modifier txExists(uint256 nonce) {
        if (s_transactions[nonce].to == address(0))
            revert MultiSig__TxDoesNotExist();
        _;
    }

    // Modifier
    /**
     * Prevents the execution of a transaction that has already been executed
     */
    modifier txNotExecuted(uint256 nonce) {
        if (s_transactions[nonce].executed)
            revert MultiSig__TxAlreadyExecuted();
        _;
    }

    // Modifier
    /**
     * Prevents the execution of a transaction that has already been confirmed
     */
    modifier txNotConfirmed(uint256 nonce) {
        if (hasConfirmed[nonce][msg.sender])
            revert MultiSig__TxAlreadyConfirmed();
        _;
    }

    // Constructor
    /**
     * Initializes the contract with a pre-defined list of owners
     * Calculate the number of owners required to execute a transaction
     */
    constructor(address[] memory listOfOwners) {
        if (listOfOwners.length < i_minimumOwnersCount)
            revert MultiSig__CtorNotEnoughOwners();
        if (listOfOwners.length > i_maximumOwnersCount)
            revert MultiSig__CtorTooManyOwners();

        for (uint8 i = 0; i < listOfOwners.length; i++) {
            address owner = listOfOwners[i];
            if (owner == address(0)) revert MultiSig__OwnerInvalidAddress();
            if (s_isOwner[owner])
                revert MultiSig__CtorListOfOwnersHasDuplicatedAddresses();
            s_isOwner[owner] = true;
        }
        s_owners = listOfOwners;
        s_nbOwnerConfirmationsRequiredForApproval = calculateNumberOfOwnersRequiredForApproval();
    }

    /**
     * Submits a proposal (transaction)
     * The proposal is for this use case a contract function call passed into the _data parameter
     * I may later use the value for funds withdrawal proposal
     */
    function submitTx(
        address _to,
        uint256 _nonce,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        //only one submission per nonce value
        if (s_transactions[_nonce].to != address(0))
            revert MultiSig__TxAlreadySubmitted();

        s_transactions[_nonce] = Tx({
            to: _to,
            nonce: _nonce,
            value: _value,
            data: _data,
            executed: false,
            nbOwnerConfirmationsProcessed: 0
        });
        emit TxSubmitted(msg.sender, _nonce, _to, _value, _data);
    }

    /**
     * Confirms a proposal (transaction)
     * Every owner stored in this contract may confirm the proposal
     */
    function confirmTx(uint256 _nonce)
        external
        onlyOwner
        txExists(_nonce)
        txNotExecuted(_nonce)
        txNotConfirmed(_nonce)
    {
        Tx storage transaction = s_transactions[_nonce];
        transaction.nbOwnerConfirmationsProcessed += 1;
        hasConfirmed[_nonce][msg.sender] = true;

        emit TxConfirmed(msg.sender, _nonce);
    }

    /**
     * Executes a proposal (transaction) if enough owners confirmed it.
     * Any owner stored in this contract may confirm the proposal, even if one has not confirmed it.
     */
    function executeTx(uint256 _nonce)
        external
        onlyOwner
        txExists(_nonce)
        txNotExecuted(_nonce)
    {
        uint256 numberOfApprovalsNeeded = calculateNumberOfOwnersRequiredForApproval();
        Tx storage transaction = s_transactions[_nonce];
        if (transaction.nbOwnerConfirmationsProcessed < numberOfApprovalsNeeded)
            revert MultiSig__TxCannotExecute();
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert MultiSig__TxExecuteFailed();
        emit TxExecuted(msg.sender, _nonce);
    }

    /**
     * Adds a new owner to this contract.
     * A single owner from this contract cannot add a new owner, he/her must send a proposal.
     */
    function addOwner(address newOwner) external onlyThisWallet {
        if (newOwner == address(0)) revert MultiSig__OwnerInvalidAddress();
        if (s_owners.length == i_maximumOwnersCount)
            revert MultiSig__AddOwnerFailed();
        if (s_isOwner[newOwner]) revert MultiSig__AddOwnerFailed();

        s_owners.push(newOwner);
        s_isOwner[newOwner] = true;

        //update number of approvals needed for executing a transaction
        s_nbOwnerConfirmationsRequiredForApproval = calculateNumberOfOwnersRequiredForApproval();

        emit MultiSigOwnerAdded(newOwner, block.timestamp);
    }

    /**
     * Removes an exising owner from this contract.
     * A single owner from this contract cannot remove an existing owner, he/her must send a proposal.
     */
    function removeOwner(address owner) external onlyThisWallet {
        if (owner == address(0)) revert MultiSig__OwnerInvalidAddress();
        if (s_owners.length == i_minimumOwnersCount)
            revert MultiSig__RemoveOwnerFailed();

        uint256 index = ownersArrayIndexOf(owner);
        ownersArrayRemoveAtIndex(index);
        s_isOwner[owner] = false;

        //update number of approvals needed for executing a transaction
        s_nbOwnerConfirmationsRequiredForApproval = calculateNumberOfOwnersRequiredForApproval();

        emit MultiSigOwnerRemoved(owner, block.timestamp);
    }

    /**
     * Get immutable percentage variable of owners required for a transaction execution.
     */
    function getPercentageOfOwnersRequiredForApproval()
        external
        pure
        returns (uint8 nbOwnersRequired)
    {
        nbOwnersRequired = i_percentageOwnersRequiredForApproval;
    }

    /**
     * Retrieves the number of owners required for a transaction execution.
     */
    function getNumberOfOwnersRequiredForApproval()
        external
        view
        returns (uint256 nbOwnersRequired)
    {
        nbOwnersRequired = s_nbOwnerConfirmationsRequiredForApproval;
    }

    /**
     * Calculates the number of owners required for a transaction execution.
     */
    function calculateNumberOfOwnersRequiredForApproval()
        private
        view
        returns (uint256 nbOwnersRequired)
    {
        nbOwnersRequired = s_owners
            .length
            .mul(i_percentageOwnersRequiredForApproval)
            .div(100);
    }

    /**
     * Returns a list of all owners stored in this contract.
     */
    function getOwnersAddresses() external view returns (address[] memory) {
        return s_owners;
    }

    /**
     * Returns the index of a given address in the owners array
     */
    function ownersArrayIndexOf(address value) private view returns (uint256) {
        uint i = 0;
        while (s_owners[i] != value) {
            i++;
        }
        return i;
    }

    /**
     * Removes a value from the owners array
     */
    function ownersArrayRemoveAtIndex(uint _index) private {
        require(_index < s_owners.length, "index out of bound");

        for (uint i = _index; i < s_owners.length - 1; i++) {
            s_owners[i] = s_owners[i + 1];
        }
        s_owners.pop();
    }

    /**
     * Gets a transaction object for a given nonce
     */
    function getTransaction(uint256 nonce) external view returns (Tx memory) {
        return s_transactions[nonce];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}