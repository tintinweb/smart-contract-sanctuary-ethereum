/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: NONE

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BlackDAOClaimer is Ownable {

    IERC20 token;

    struct Whitelister {
        bool isValid;
        uint256 amountToClaim;
    }

    mapping (address => Whitelister) private Whitelist;

    // constructor

    constructor() {}

    // getter

    function getWhitelist(address user) external view onlyOwner returns (Whitelister memory) {
        return Whitelist[user];
    }

    // setter

    function setToken(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }

    // functions

    function addToWhitelist(address user, uint256 amount) external onlyOwner {
        require(Whitelist[user].isValid == false, "BlackDAOClaimer: User already whitelisted");
        Whitelist[user] = Whitelister(true, amount);
    }

    function addToWhitelistBatch(address[] memory users, uint256[] memory amounts) external onlyOwner {
        require(users.length == amounts.length, "BlackDAOClaimer: Incorrect length of arguments");

        uint256 counterForWhitelisters;
        for (uint256 i = 0 ; i < users.length ; i++ ) {
            Whitelist[users[i]] = Whitelister(true, amounts[i]);
            counterForWhitelisters++;
        }

        if (counterForWhitelisters != users.length) {
            require(false, "BlackDAOClaimer: Some users already whitelisted");
        }
    }

    function removeFromWhitelist(address user) external onlyOwner {
        require(Whitelist[user].isValid == true, "BlackDAOClaimer: User not whitelisted");
        Whitelist[user] = Whitelister(false, 0);
    }

    function removeFromWhitelistBatch(address[] memory users) external onlyOwner {
        uint256 counterForWhitelisters;
        for (uint256 i = 0 ; i < users.length ; i++ ) {
            Whitelist[users[i]] = Whitelister(false, 0);
            counterForWhitelisters++;
        }

        if (counterForWhitelisters != users.length) {
            require(false, "BlackDAOClaimer: Some users not whitelisted");
        }
    }

    function claim() external {
        Whitelister memory tempWhitelister = Whitelist[msg.sender];
        require(tempWhitelister.isValid == true, "BlackDAOClaimer: User not whitelisted");

        token.transfer(msg.sender, tempWhitelister.amountToClaim);

        Whitelist[msg.sender] = Whitelister(false, 0);
    }

    /*
     * @dev used to withdraw token balance of this contract back to the owner
     */
    function withdraw() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}