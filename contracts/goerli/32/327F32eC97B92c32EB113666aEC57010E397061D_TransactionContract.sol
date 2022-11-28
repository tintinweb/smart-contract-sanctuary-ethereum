// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TransactionContract is Ownable {
    struct Transaction {
        uint256 transaction_id;
        string place_no_id;
        string certificate_no_id;
        string transaction_date;
        string transaction_behavior;
        string transaction_volume;
        string target_place_no_id; //canBlank
        bool is_valid;
    }

    struct Paction {
        uint256 paction_blockchain_id;
        string paction_no;
        string paction_type;
        string paction_issue_date;
        string paction_valid_date;
        string contact_name; //canBlank
        string contact_mail; //canBlank
        string contact_tel; //canBlank
        string place_no;
        string paction_toxic_no;
        string paction_concentractionQ11;
        string paction_concentractionQ12;
    }

    Transaction[] public transactions;
    Paction[] public pactions;

    mapping(uint256 => Transaction) public transactionMap;
    mapping(uint256 => Paction) public pactionMap;

    // address public immutable owner;

    event InputTransaction(
        string _place_no_id,
        string _certificate_no_id,
        string _transaction_date,
        string _transaction_behavior,
        string _transaction_volume,
        bool _is_valid
    );
    event InputPaction(
        string _paction_no,
        string _paction_type,
        string _paction_issue_date,
        string _paction_valid_date,
        string _place_no,
        string _paction_toxic_no,
        string _paction_concentractionQ11,
        string _paction_concentractionQ12
    );

    constructor() {
        // owner = msg.sender;
    }

    function inputTransaction(
        uint256 _transaction_id,
        string memory _place_no_id,
        string memory _certificate_no_id,
        string memory _transaction_date,
        string memory _transaction_behavior,
        string memory _transaction_volume,
        string memory _target_place_no_id,
        bool _is_valid
    ) external onlyOwner {
        // require(msg.sender == owner, "Sender is not the owner!!"); //not sure if this is needed or not?

        Transaction memory newTx = Transaction(
            _transaction_id,
            _place_no_id,
            _certificate_no_id,
            _transaction_date,
            _transaction_behavior,
            _transaction_volume,
            _target_place_no_id,
            _is_valid
        );
        transactions.push(newTx);
        transactionMap[_transaction_id] = newTx;
        emit InputTransaction(
            _place_no_id,
            _certificate_no_id,
            _transaction_date,
            _transaction_behavior,
            _transaction_volume,
            _is_valid
        );
    }

    function inputPaction(
        uint256 _paction_blockchain_id,
        string memory _paction_no,
        string memory _paction_type,
        string memory _paction_issue_date,
        string memory _paction_valid_date,
        string memory _contact_name, //canBlank
        string memory _contact_mail, //canBlank
        string memory _contact_tel, //canBlank
        string memory _place_no,
        string memory _paction_toxic_no,
        string memory _paction_concentractionQ11,
        string memory _paction_concentractionQ12
    ) external onlyOwner {
        // require(msg.sender == owner, "Sender is not the owner!!"); //not sure if this is needed or not?

        Paction memory newPac = Paction(
            _paction_blockchain_id,
            _paction_no,
            _paction_type,
            _paction_issue_date,
            _paction_valid_date,
            _contact_name, //canBlank
            _contact_mail, //canBlank
            _contact_tel, //canBlank
            _place_no,
            _paction_toxic_no,
            _paction_concentractionQ11,
            _paction_concentractionQ12
        );

        pactions.push(newPac);
        pactionMap[_paction_blockchain_id] = newPac;
        emit InputPaction(
            _paction_no,
            _paction_type,
            _paction_issue_date,
            _paction_valid_date,
            _place_no,
            _paction_toxic_no,
            _paction_concentractionQ11,
            _paction_concentractionQ12
        );
    }
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