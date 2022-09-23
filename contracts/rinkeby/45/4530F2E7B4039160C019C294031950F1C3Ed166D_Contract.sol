// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Contract is Ownable {
    string public name;
    uint256 public totalAmount;

    struct transaction {
        address sender;
        address receiver;
        uint256 amountInWei;
        uint256 fiat;
        bool locked;
        bool released;
    }

    mapping(uint256 => transaction) public trxs;

    event Recorded(
        uint256 indexed paymentId,
        address indexed sender,
        address indexed receiver,
        uint256 amountInWei,
        uint256 fiat
    );
    event Locked(uint256 indexed paymentId, uint256 amountInWei);
    event Released(
        uint256 indexed paymentId,
        address indexed sender,
        address indexed receiver,
        uint256 amountInWei,
        uint256 fiat
    );

    constructor(string memory _name) {
        name = _name;
        totalAmount = 0;
    }

    function createRecord(
        uint256 _paymentId,
        address _sender,
        address _receiver,
        uint256 _amountInWei,
        uint256 _fiat
    ) public onlyOwner {
        require(
            _sender != address(0) && _receiver != address(0),
            "Sender or receiver cannot be zero address"
        );
        require(
            trxs[_paymentId].amountInWei == 0,
            "Record already has been created"
        );
        require(
            _sender != _receiver,
            "Sender and receiver must be different addresses"
        );
        require(_amountInWei > 0, "Amount cannot be zero");
        require(_fiat > 0, "Fiat value cannot be zero");

        transaction memory trx = transaction(
            _sender,
            _receiver,
            _amountInWei,
            _fiat,
            false,
            false
        );
        trxs[_paymentId] = trx;

        emit Recorded(_paymentId, _sender, _receiver, _amountInWei, _fiat);
    }

    function lockFund(uint256 _paymentId) public payable {
        require(trxs[_paymentId].amountInWei > 0, "Record not found");
        require(msg.sender == trxs[_paymentId].sender, "Invalid sender");
        require(msg.value == trxs[_paymentId].amountInWei, "Invalid amount");
        require(
            msg.sender.code.length > 0 == false,
            "Caller cannot be a contract"
        );
        require(
            trxs[_paymentId].locked == false,
            "Fund has already been locked"
        );

        totalAmount += msg.value;
        trxs[_paymentId].locked = true;

        emit Locked(_paymentId, trxs[_paymentId].amountInWei);
    }

    function releaseFund(uint256 _paymentId) public onlyOwner {
        require(trxs[_paymentId].amountInWei > 0, "Record not found");
        require(trxs[_paymentId].locked == true, "Error in transaction status");
        require(
            trxs[_paymentId].released == false,
            "Error in transaction status"
        );

        address payable to = payable(trxs[_paymentId].receiver);

        to.transfer(trxs[_paymentId].amountInWei);
        totalAmount -= trxs[_paymentId].amountInWei;
        trxs[_paymentId].released = true;

        emit Released(
            _paymentId,
            trxs[_paymentId].sender,
            trxs[_paymentId].receiver,
            trxs[_paymentId].amountInWei,
            trxs[_paymentId].fiat
        );
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getTransactionById(uint256 _paymentId)
        public
        view
        returns (transaction memory)
    {
        return trxs[_paymentId];
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