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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/ITokenVendor.sol';
import './interfaces/IMoney.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TokenVendor is ITokenVendor, Ownable {
	/// @notice Address of the token contract used by the TokenVendor
	/// @return The tokens address
	IMoney public money;

	/// @inheritdoc ITokenVendor
	uint256 public override moniesPerEth = 100;

	constructor(address tokenAddress) {
		money = IMoney(tokenAddress);
	}

	/// @inheritdoc ITokenVendor
	function buy() external payable override {
		uint256 tokenAmount = msg.value * moniesPerEth;
		require(tokenAmount > 0, 'Invalid Amount');

		emit Bought(msg.sender, tokenAmount);
		money.print(msg.sender, tokenAmount);
	}

	/// @inheritdoc ITokenVendor
	function sell(uint256 tokenAmount) public override {
		require(tokenAmount > 0, 'Invalid Amount');

		uint256 amountOfEth = tokenAmount / moniesPerEth;
		require(address(this).balance >= amountOfEth, 'Not enough Ether available');

		emit Sold(msg.sender, tokenAmount);
		money.burn(msg.sender, tokenAmount);

		(bool sent, ) = msg.sender.call{value: amountOfEth}('');
		require(sent, 'Failed to send Ether');
	}

	/// @inheritdoc ITokenVendor

	function sellWithPermit(
		uint256 tokenAmount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override {
		money.permit(msg.sender, address(this), tokenAmount, deadline, v, r, s);
		sell(tokenAmount);
	}

	/// @inheritdoc ITokenVendor

	function withdraw(uint256 amount) external override onlyOwner {
		require(amount <= address(this).balance, 'Withdrawing more than available');

		(bool sent, ) = owner().call{value: amount}('');
		require(sent, 'Failed to send Ether');
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

interface IMoney is IERC20, IERC20Permit {
	/// @notice Mints a given amount of Money to an account
	/// @param to The receiver of the Money
	/// @param amount The amount of Money that will be minted
	function print(address to, uint256 amount) external;

	/// @notice Burns a given amount of Money from an account
	/// If the receiver approved the transfer/burn
	/// @param from The account the money will be burned from
	/// @param amount The amount of Money that will be burned
	function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenVendor {
	/// @notice Emitted when a user buys tokens from the TokenVendor
	/// @param buyer The user who bought the tokens
	/// @param amount The amount of tokens bought
	event Bought(address indexed buyer, uint256 amount);

	/// @notice Emitted when a user sells tokens to the TokenVendor
	/// @param seller The user who sold the tokens
	/// @param amount The amount of tokens sold
	event Sold(address indexed seller, uint256 amount);

	/// @notice Amount of Money exchanged for one Ether
	/// @return Amount of tokens per eth
	function moniesPerEth() external view returns (uint256);

	/// @notice Transfers newly minted money to caller based
	/// on amount of sent ether
	/// @dev Emits a Bought and Transfer event
	function buy() external payable;

	/// @notice Transfers ether to the message sender
	/// calculated based on the given amount of sent money
	/// @dev Emits a Sold and Transfer event.
	/// Sent money will be burned
	function sell(uint256 amount) external;

	/// @notice Transfers ether to the message sender
	/// calculated based on the given amount of sent money
	/// @dev Same as `sellTokens` with additional, with additional
	/// signature parameters which which allow the approval and
	/// transfer of Money in a single Transaction using EIP-2612 Permits
	/// Emits a Sold and Transfer event.
	/// @param tokenAmount Amount of tokens that will be burned by the TokenVendor
	/// @param deadline timestamp until when the given signature will be valid
	/// @param v The parity of the y co-ordinate of r of the signature
	/// @param r The x co-ordinate of the r value of the signature
	/// @param s The x co-ordinate of the s value of the signature
	function sellWithPermit(
		uint256 tokenAmount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/// @notice Transfers given amount of ether to the contract owner
	/// @dev Only executable by contract owner
	/// @param amount Amount of ether that should be transferred
	function withdraw(uint256 amount) external;
}