// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitter.sol";

contract GenArtPaymentSplitter is GenArtAccess, IGenArtPaymentSplitter {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(
        address collection,
        uint256 paymentType,
        address payee,
        uint256 amount
    );

    mapping(address => uint256) public _balances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitter: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _payments[msg.sender].payees.length > 0 &&
                _payments[msg.sender].payees[0] != address(0)
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 0);
        for (uint8 i; i < _payments[collection].payees.length; i++) {
            address payee = _payments[collection].payees[i];
            uint256 ethAmount = (msg.value * _payments[collection].shares[i]) /
                totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0 &&
                _paymentsRoyalties[msg.sender].payees[0] != address(0)
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 ethAmount = (msg.value *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentsRoyalties
     */
    function getTotalSharesOfCollection(address collection, uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        sanityCheck(collection, paymentType);
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) public override {
        uint256 amount = _balances[account];
        require(amount > 0, "GenArtPaymentSplitter: no funds to release");
        _balances[account] = 0;
        payable(account).transfer(amount);
    }

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) public override {
        sanityCheck(collection, paymentType);
        Payment storage payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        address oldPayee = payment.payees[payeeIndex];
        require(
            oldPayee == _msgSender(),
            "GenArtPaymentSplitter: sender is not current payee"
        );
        uint256 amount = _balances[oldPayee];
        _balances[oldPayee] = 0;
        payment.payees[payeeIndex] = newPayee;
        _balances[newPayee] = amount;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitter {
    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function splitPayment(address collection) external payable;

    function splitPaymentRoyalty(address collection) external payable;

    function getTotalSharesOfCollection(address collection, uint8 _payment)
        external
        view
        returns (uint256);

    function release(address account) external;

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
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