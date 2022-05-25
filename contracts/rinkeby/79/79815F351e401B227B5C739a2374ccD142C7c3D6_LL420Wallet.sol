//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Wallet
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error ZeroAddress();
error InvalidAmount();
error ExceededAmount();
error NotAllowedSender();
error NotAllowedAction();

contract LL420Wallet is Ownable {
    struct UserWallet {
        uint256 balance;
    }

    mapping(address => UserWallet) public wallets;
    mapping(address => bool) public permissioned;
    bool public selfWithdrawAllowed;

    event Deposit(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event WithdrawToPoint(address indexed _user, uint256 _amount, uint256 _timestamp);

    modifier onlyAllowed() {
        if (permissioned[_msgSender()] == false) revert NotAllowedSender();
        _;
    }

    constructor() {}

    function deposit(address _user, uint256 _amount) external onlyAllowed {
        // _deposit(_user, _amount||);
        /// @notice This is only for test purpose
        _deposit(_user, _amount == 100 ? 10000 : _amount);
    }

    function withdraw(address _user, uint256 _amount) external onlyAllowed {
        _withdraw(_user, _amount);
    }

    function balance(address _user) external view returns (uint256) {
        return wallets[_user].balance;
    }

    function withdraw(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);
    }

    function withdrawToPoint(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);

        emit WithdrawToPoint(_msgSender(), _amount, block.timestamp);
    }

    function initialize() external onlyOwner {
        allowAddress(_msgSender(), true);
    }

    function allowAddress(address _user, bool _allowed) public onlyOwner {
        if (_user == address(0)) revert ZeroAddress();

        permissioned[_user] = _allowed;
    }

    function allowSelfWithdraw(bool _enable) public onlyOwner {
        selfWithdrawAllowed = _enable;
    }

    function _deposit(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();

        wallets[_user].balance += _amount;

        emit Deposit(_user, _amount);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();
        if (wallets[_user].balance < _amount) revert ExceededAmount();

        wallets[_user].balance -= _amount;

        emit Withdraw(_user, _amount);
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