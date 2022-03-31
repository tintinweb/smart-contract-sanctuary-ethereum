// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract GenArtPaymentSplitterV2 is GenArtAccess, IGenArtPaymentSplitterV2 {
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
    mapping(address => uint256) public _wethBalances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;
    address public _wethAddress;
    bool public _destoryed = false;

    constructor(address wethAddress_) GenArtAccess() {
        _wethAddress = wethAddress_;
    }

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || (owner() == sender) || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitterV2: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(_payments[msg.sender].payees.length > 0)
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
            _paymentsRoyalties[msg.sender].payees.length > 0
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

    function splitPaymentRoyaltyWETH(address collection, uint256 wethAmount)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        IERC20(_wethAddress).transferFrom(
            collection,
            address(this),
            wethAmount
        );
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 wethAmountShare = (wethAmount *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _wethBalances[payee] += wethAmountShare;
            }
            emit IncomingPayment(collection, 1, payee, wethAmountShare);
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
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        uint256 amount = _balances[account];
        uint256 wethAmount = _wethBalances[account];
        require(
            amount > 0 || wethAmount > 0,
            "GenArtPaymentSplitterV2: no funds to release"
        );
        if (amount > 0) {
            _balances[account] = 0;
            payable(account).transfer(amount);
        }
        if (wethAmount > 0) {
            _wethBalances[account] = 0;
            IERC20(_wethAddress).transfer(account, wethAmount);
        }
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
            "GenArtPaymentSplitterV2: sender is not current payee"
        );
        payment.payees[payeeIndex] = newPayee;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        return _balances[account];
    }

    function emergencyWithdraw() public onlyOwner {
        _destoryed = true;
        payable(owner()).transfer(address(this).balance);
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

interface IGenArtPaymentSplitterV2 {
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

    function splitPaymentRoyaltyWETH(address collection, uint256 wethAmount)
        external
        payable;

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}