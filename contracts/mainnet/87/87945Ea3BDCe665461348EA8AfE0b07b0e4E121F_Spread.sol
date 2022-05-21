// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Spread Dapp, Edition Ethereum.
/// @author @dadogg80, Viken Blockchain Solutions.
/// @notice Transfer your cryptocurrency to multiple accounts in one transaction.
/// @dev The purpose of this smart-contract was to create an updated dapp
///      of what is already available on the blockchain network.


contract Spread is Ownable {
    
    /// @dev authentication error.
    error Error_1();

    /// @dev thrown by receive function.
    error Error_2();

    /// @dev thrown if zero values.
    error ZeroValues();

    constructor() {
    }

    modifier noZeroValues(address[] calldata recipients, uint256[] calldata values) {
      if (recipients.length <= 0 ||  values.length <= 0) revert ZeroValues();
      _;
    }

    /// @dev Receive function.
    receive() external payable {
        revert Error_2();
    } 

    /// This will allow you to batch transfers of an mainnet asset like Ethereum, Matic, etc, to multiple accounts.
    /// @param recipients List with the recipient accounts.
    /// @param values List with the values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: ["value","value","value"].
    function spreadAsset(address[] calldata recipients, uint256[] calldata values) external payable noZeroValues(recipients, values) {
            for (uint256 i = 0; i < recipients.length; i++)
                payable(recipients[i]).transfer(values[i]);
    }

    /// This will allow you to batch transfers of erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value,value,value].
    function spreadERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValues(recipients, values) {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    /// This is a cheaper way to batch transfer erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value, value, value].
    function spreadERC20Simple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValues(recipients, values) {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }

    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param token The ERC20 contract address.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC20(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(address(msg.sender), amount));
    }

    /// This will allow the owner account to save any stuck main asset.
    /// @dev Restricted by onlyOwner modifier.
    function saveAsset() external onlyOwner {
        uint256 asset = address(this).balance;
        payable(msg.sender).transfer(asset);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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