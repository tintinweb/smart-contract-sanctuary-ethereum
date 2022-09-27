// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositBUSD is Ownable {
    mapping(uint256 => TransactionDeposit) private idToListTransaction;
    mapping(address => TotalDepositUsers) private idToTotalDepositUsers;

    uint256 public TransactionCount;
    IERC20 public busd;
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

    constructor(IERC20 tokenBUSD) {
        TransactionCount = 0;
        busd = tokenBUSD;
    }

    function DepositBUSDs(uint256 amount)
        public
        payable
        returns (string memory)
    {
        require(
            amount > 10000000000000000000,
            "You need to sell at least some tokens"
        );
        uint256 allowance = busd.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        busd.transferFrom(msg.sender, address(this), amount);

        uint256 _idTransaction = TransactionCount++;
        idToListTransaction[_idTransaction].idTransaction = _idTransaction;
        idToListTransaction[_idTransaction].from = msg.sender;
        idToListTransaction[_idTransaction].value = amount;
        idToListTransaction[_idTransaction].name = "DepositBUSD";

        idToTotalDepositUsers[msg.sender].from = msg.sender;
        idToTotalDepositUsers[msg.sender].total += amount;

        require(
            idToListTransaction[_idTransaction].value == msg.value,
            "Save transaction failed"
        );

        require(
            idToTotalDepositUsers[msg.sender].total >= amount,
            "Save Total transaction failed"
        );

        return
            "You have sent successfully and please check your BNB wallet in our system";
    }

    function WithdrawBUSDUsers(uint256 amount) public returns (bool) {
        uint256 balanceTotal = (idToTotalDepositUsers[msg.sender].total * 17) /
            20;
        require(amount <= balanceTotal, "Balance not enough");

        uint256 amountWithdraw = (amount * 17) / 20;

        require(
            msg.sender == idToTotalDepositUsers[msg.sender].from,
            "Not Balance"
        );

        busd.transfer(msg.sender, amountWithdraw);

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

    function WithdrawBNBOwner(uint256 amount) public onlyOwner returns (bool) {
        address payable to = payable(owner());
        to.transfer(amount);
        return true;
    }

    function GetBalanceofBUSD() external view returns (uint256) {
        return busd.balanceOf(address(this));
    }

    function WithdrawBUSDOwner(uint256 amount) public onlyOwner returns (bool) {
        busd.transfer(owner(), amount);
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

    function GetTransactionByID(uint256 _id)
        public
        view
        returns (TransactionDeposit memory)
    {
        return idToListTransaction[_id];
    }

    function GetTotalByAddress(address _address)
        public
        view
        returns (TotalDepositUsers memory)
    {
        return idToTotalDepositUsers[_address];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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