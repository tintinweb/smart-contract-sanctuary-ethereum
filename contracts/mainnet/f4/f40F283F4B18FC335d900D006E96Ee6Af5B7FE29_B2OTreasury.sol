/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _setOwner(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract B2OTreasury is Pausable, Ownable, ReentrancyGuard {
    /* ========== VARIABLES ========== */

    mapping(address => bool) private _isAdmin;
    mapping(address => uint256) private _totalDeposit;
    mapping(address => uint256) private _totalWithdraw;

    address private _safeTreasury = 0x8fb77bf1036004B97BeEA01de70f541AD04c8175;

    /* ========== MODIFIER ========== */

    modifier onlyAdmin() {
        require(
            _isAdmin[_msgSender()] || _msgSender() == owner(),
            "BitOptionTreasury: caller is not admin"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event Receive(address indexed account, uint256 amount);

    event DepositNativeToken(address indexed account, uint256 amount);
    event WithdrawNativeToken(
        address indexed account,
        address indexed to,
        uint256 amount,
        string requestId
    );
    event WithdrawToSafe(
        address indexed account,
        address indexed to,
        uint256 amount
    );
    event SetAdmin(address indexed account, address indexed admin, bool status);
    event SetSafeTreasury(
        address indexed account,
        address indexed oldAddress,
        address indexed newAddress
    );

    /* ========== VIEWS ========== */

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address account) public view returns (uint256) {
        return address(account).balance;
    }

    function isAdmin(address account) public view returns (bool) {
        return _isAdmin[account] || _msgSender() == owner();
    }

    function safeTreasury() public view returns (address) {
        return _safeTreasury;
    }

    function totalTransaction(address account)
        public
        view
        returns (uint256 totalDeposit, uint256 totalWithdraw)
    {
        return (_totalDeposit[account], _totalWithdraw[account]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function withdrawToSafe(uint256 amount) external onlyOwner {
        _withdrawToSafe(amount);
    }

    function withdrawNativeToken(
        address to,
        uint256 amount,
        string memory requestId
    ) external onlyAdmin {
        _withdrawNativeToken(to, amount, requestId);
    }

    function multiWithdrawNativeToken(
        address[] memory tos,
        uint256[] memory amounts,
        string[] memory requestIds
    ) external onlyAdmin {
        uint256 length = tos.length;
        require(
            amounts.length == length &&
                requestIds.length == length &&
                length > 0,
            "MultiWithdrawNativeToken: input length invalid"
        );
        for (uint256 i = 0; i < length; i++) {
            _withdrawNativeToken(tos[i], amounts[i], requestIds[i]);
        }
    }

    function setAdmin(address newAdmin, bool status) external onlyOwner {
        require(newAdmin != address(0), "SetAdmin: new admin is zero token");
        _isAdmin[newAdmin] = status;

        emit SetAdmin(_msgSender(), newAdmin, status);
    }

    function setSafeTreasury(address newAddress) external onlyOwner {
        require(newAddress != address(0), "SetAdmin: new admin is zero token");

        address oldSafe = _safeTreasury;
        _safeTreasury = newAddress;

        emit SetSafeTreasury(_msgSender(), oldSafe, newAddress);
    }

    function setPause() external onlyOwner {
        bool isPaused = paused();
        if (isPaused) {
            _unpause();
        } else {
            _pause();
        }
    }

    /* ========== FUNCTIONS ========== */

    function deposit() external payable {
        _depositNativeToken(_msgSender(), msg.value);
    }

    receive() external payable {
        emit Receive(_msgSender(), msg.value);
    }

    /* ========== PRIVATES ========== */

    function _depositNativeToken(address sender, uint256 amount)
        private
        nonReentrant
        whenNotPaused
    {
        require(sender != address(0), "Deposit: sender is zero address");
        require(amount > 0, "Deposit: amount must be greater than zero");

        _totalDeposit[sender] += amount;

        emit DepositNativeToken(sender, amount);
    }

    function _withdrawNativeToken(
        address to,
        uint256 amount,
        string memory requestId
    ) private nonReentrant whenNotPaused {
        require(to != address(0), "WithdrawNativeToken: to is zero address");
        require(
            amount > 0,
            "WithdrawNativeToken: amount must greater than zero"
        );

        _totalWithdraw[to] += amount;

        payable(to).transfer(amount);

        emit WithdrawNativeToken(_msgSender(), to, amount, requestId);
    }

    function _withdrawToSafe(uint256 amount)
        private
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "WithdrawToSafe: amount must greater than zero");

        _totalWithdraw[_safeTreasury] += amount;

        payable(_safeTreasury).transfer(amount);

        emit WithdrawToSafe(_msgSender(), _safeTreasury, amount);
    }
}