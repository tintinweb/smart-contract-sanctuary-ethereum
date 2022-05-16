//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

// Import Ownable from the OpenZeppelin Contracts library

contract WXDCBridge {
    // transaction nonce tracking
    uint256 internal _lastNonce;
    uint256[] internal _pendingTransactions;
    /*
     * @dev This variable is used to track the balances of the XDC deposited by a user
     * in the bridge contract until WXDC is minted on foregin  Chain
     * the user withdraws the funds.
     */
    mapping(address => uint256) internal _balances;
    /*
     * @dev This variable is used to keep a track of all the transactions happening on the bridge contract
     */
    mapping(uint256 => Transaction) internal _transactions;

    // transaction added event
    event TransactionAdded(Transaction transaction);
    // structure for a simple transaction
    struct Transaction {
        uint256 nonce;
        uint256 amount;
        address xinfinAddress;
        address ethAddress;
        bool completedStatus;
        string ethTxnHash;
    }

    // initalizer
    function initialize() public {
        _lastNonce = 0;
    }

    // deposit xdc
    function deposit(address eth_address) public payable {
        // increment the nonce
        _lastNonce = _lastNonce + 1;

        // add to list of nonces
        _pendingTransactions.push(_lastNonce);

        // update the balance of the account
        _balances[msg.sender] += msg.value;

        // add a transaction with this nonce
        _transactions[_lastNonce] = Transaction(
            _lastNonce,
            msg.value,
            msg.sender,
            eth_address,
            false,
            ""
        );

        emit TransactionAdded(_transactions[_lastNonce]);
    }

    // returns how much xdc an address is owed
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function sendXDC(address payable reciever, uint256 amount) public {
        require(balanceOf(reciever) > amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        reciever.transfer(amount);
    }

    function getTransaction(uint256 _nonce)
        public
        view
        returns (Transaction memory)
    {
        return _transactions[_nonce];
    }

    function getNonceIndex(uint256[] memory _array, uint256 _element)
        private
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _element) {
                return i;
            }
        }
        return _array.length + 1;
    }

    function markTransactionAsComplete(uint256 _nonce) public {
        // reduce the balance of the sender
        _balances[_transactions[_nonce].xinfinAddress] -= _transactions[_nonce]
            .amount;

        // todo:
        // check if transaction exists by checking the addresses in the
        // _transactions mapping

        // mark transaction as completed
        _transactions[_nonce].completedStatus = true;

        // remove the nonce from the pending array
        _pendingTransactions[
            getNonceIndex(_pendingTransactions, _nonce)
        ] = _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.pop();
    }

    function getPendingTransactions() public view returns (uint256[] memory) {
        uint256[] memory arr = _pendingTransactions;
        return arr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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