// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositBNB is Ownable {
    mapping(uint256 => TransactionDeposit) private idToListTransaction;
    mapping(address => TotalDepositUsers) private idToTotalDepositUsers;

    uint256 public TransactionCount;

    struct TransactionDeposit {
        uint256 idTransaction;
        address from;
        uint256 value;
        string name;
    }

    struct TotalDepositUsers {
        address from;
        uint256 total;
    }

    constructor() {
        TransactionCount = 0;
    }

    function DepositBNBs() public payable returns (string memory) {
        uint256 amountTobuy = msg.value;
        require(
            amountTobuy >= 100000000000000000,
            "You need to deposit at least 0.1 bnb to Account"
        );

        uint256 _idTransaction = TransactionCount++;
        idToListTransaction[_idTransaction].idTransaction = _idTransaction;
        idToListTransaction[_idTransaction].from = msg.sender;
        idToListTransaction[_idTransaction].value = amountTobuy;
        idToListTransaction[_idTransaction].name = "DepositBNBs";

        idToTotalDepositUsers[msg.sender].from = msg.sender;
        idToTotalDepositUsers[msg.sender].total += amountTobuy;

        require(
            idToListTransaction[_idTransaction].value == msg.value,
            "Save transaction failed"
        );

        require(
            idToTotalDepositUsers[msg.sender].total >= amountTobuy,
            "Save Total transaction failed"
        );
        return
            "You have sent successfully and please check your BNB wallet in our system";
    }

    function WithdrawBNBUsers(uint256 amount) public returns (bool) {
        require(
            amount >= 100000000000000000,
            "You need to deposit at least 0.1 bnb to buy Rom"
        );

        uint256 balanceTotal = (idToTotalDepositUsers[msg.sender].total * 17) /
            20;
        require(amount <= balanceTotal, "Balance not enough");

        uint256 amountWithdraw = (amount * 17) / 20;

        address payable to = payable(msg.sender);
        to.transfer(amountWithdraw);

        uint256 _idTransaction = TransactionCount++;
        idToListTransaction[_idTransaction].idTransaction = _idTransaction;
        idToListTransaction[_idTransaction].from = msg.sender;
        idToListTransaction[_idTransaction].value = amount;
        idToListTransaction[_idTransaction].name = "WithdrawBNBs";

        idToTotalDepositUsers[msg.sender].total =
            idToTotalDepositUsers[msg.sender].total -
            amount;

        return true;
    }

    function GetBalanceofBNB() public view returns (uint256) {
        return address(this).balance;
    }

    function WithdrawBNB(uint256 amount) public onlyOwner returns (bool) {
        address payable to = payable(owner());
        to.transfer(amount);
        return true;
    }

    function GetTransactionDepositAll()
        public
        view
        returns (TransactionDeposit[] memory)
    {
        TransactionDeposit[] memory transaction = new TransactionDeposit[](
            TransactionCount
        );
        for (uint256 i = 0; i < TransactionCount; i++) {
            TransactionDeposit storage info = idToListTransaction[i];
            transaction[i] = info;
        }
        return transaction;
    }

    function GetBoxexByType(uint256 _id)
        public
        view
        returns (TransactionDeposit memory)
    {
        return idToListTransaction[_id];
    }

    function GetBoxexByType(address _address)
        public
        view
        returns (TotalDepositUsers memory)
    {
        return idToTotalDepositUsers[_address];
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