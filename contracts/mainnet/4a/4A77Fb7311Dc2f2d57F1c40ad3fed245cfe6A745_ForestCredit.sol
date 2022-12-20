pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";
import "./IERC1404.sol";

contract ForestCredit is IERC20, IERC1404, IERC20Metadata, Ownable {
	/**
	 * Arithmetic operations in Solidity wrap on overflow. This can easily result
	 * in bugs, because programmers usually assume that an overflow raises an
	 * error, which is the standard behavior in high level programming languages.
	 * `SafeMath` restores this intuition by reverting the transaction when an
	 * operation overflows.
	 *
	 * Using this library instead of the unchecked operations eliminates an entire
	 * class of bugs, so it's recommended to use it always.
	 */
	using SafeMath for uint256;

	/**
	 * Library for managing addresses assigned to a Role.
	 */
	using Roles for Roles.Role;

	Roles.Role _transferblock;
	Roles.Role _kyc;

	mapping(address => uint256) private _balances;
	mapping(uint8 => string) private _restrictionCodes;
	mapping(uint8 => string) private _burnCodes;
	mapping(uint8 => string) private _mintCodes;
	mapping(uint8 => string) private _blockCodes;
	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	uint8 private constant CODE_TYPE_RESTRICTION = 1;
	uint8 private constant CODE_TYPE_BURN = 2;
	uint8 private constant CODE_TYPE_MINT = 3;
	uint8 private constant CODE_TYPE_BLOCK = 4;

	uint8 private constant NO_RESTRICTIONS = 0;
	uint8 private constant FROM_NOT_IN_KYC_ROLE = 1;
	uint8 private constant TO_NOT_IN_KYC_ROLE = 2;
	uint8 private constant FROM_IN_TRANSFERBLOCK_ROLE = 3;
	uint8 private constant TO_IN_TRANSFERBLOCK_ROLE = 4;
	uint8 private constant NOT_ENOUGH_FUNDS = 5;

	constructor(string memory name, string memory symbol) {
		_name = name;
		_symbol = symbol;

		_restrictionCodes[0] = "NO_RESTRICTIONS";
		_restrictionCodes[1] = "FROM_NOT_IN_KYC_ROLE";
		_restrictionCodes[2] = "TO_NOT_IN_KYC_ROLE";
		_restrictionCodes[3] = "FROM_IN_TRANSFERBLOCK_ROLE";
		_restrictionCodes[4] = "TO_IN_TRANSFERBLOCK_ROLE";
		_restrictionCodes[5] = "NOT_ENOUGH_FUNDS";

		_mintCodes[0] = "SALE";
		_mintCodes[1] = "REPLACE_TOKENS";
		_mintCodes[2] = "OTHER";

		_burnCodes[0] = "REPLACE_TOKENS";
		_burnCodes[1] = "TECHNICAL_ISSUE";
		_burnCodes[2] = "OTHER";

		_blockCodes[0] = "KYC_ISSUE";
		_blockCodes[1] = "MAINTENANCE";
		_blockCodes[2] = "OTHER";
	}

	/**
	 * Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256) {
		return _balances[account];
	}

	/**
	 * Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount)
		external
		returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount)
		external
		returns (bool)
	{
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * Moves `amount` tokens from `sender` to `recipient` using the
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
	) external returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	/**
	 * Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	/**
	 * Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"ERC20: decreased allowance below zero"
			)
		);
		return true;
	}

	/**
	 * Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(
			recipient != address(0),
			"ERC20: transfer to the zero address"
		);
		require(
			detectTransferRestriction(sender, recipient, amount) ==
				NO_RESTRICTIONS,
			cat(
				_name,
				": Transferrestriction detected please call detectTransferRestriction(address from, address to, uint256 value) for detailed information"
			)
		);
		_balances[sender] = _balances[sender].sub(
			amount,
			"ERC20: transfer amount exceeds balance"
		);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/**
	 * Concatenate Strings with an optimized Method.
	 *
	 * Requirements
	 *
	 * - `a` a String
	 * - `b` a String
	 */
	function cat(string memory a, string memory b)
		internal
		pure
		returns (string memory)
	{
		return string(abi.encodePacked(a, b));
	}

	/**
	 * Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal onlyOwner {
		require(account != address(0), "ERC20: mint to the zero address");
		require(_kyc.has(account), cat(_name, ": address is not in kyc list"));
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal onlyOwner {
		require(account != address(0), "ERC20: burn from the zero address");
		_balances[account] = _balances[account].sub(
			amount,
			"ERC20: burn amount exceeds balance"
		);
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * Destroys `amount` tokens from `account`.
	 *
	 * See {_burn}.
	 */
	function burn(
		address account,
		uint256 amount,
		uint8 code
	) external onlyOwner {
		require(
			codeExist(code, CODE_TYPE_BURN),
			cat(_name, ": The code does not exist")
		);
		_burn(account, amount);
		emit Burn(account, amount, code);
	}

	/**
	 * Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Mint} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function mintTo(
		address account,
		uint256 amount,
		uint8 code
	) external onlyOwner {
		require(
			codeExist(code, CODE_TYPE_MINT),
			cat(_name, ": The code does not exist")
		);
		_mint(account, amount);
		emit Mint(account, amount, code);
	}

	/**
	 * Returns a human-readable message for a given restrictioncode
	 */
	function messageForTransferRestriction(uint8 restrictionCode)
		external
		view
		returns (string memory)
	{
		require(
			codeExist(restrictionCode, CODE_TYPE_RESTRICTION),
			cat(_name, ": The code does not exist")
		);
		return _restrictionCodes[restrictionCode];
	}

	/**
	 * Returns a human-readable message for a given burncode
	 */
	function messageForBurnCode(uint8 burnCode)
		external
		view
		returns (string memory)
	{
		require(
			codeExist(burnCode, CODE_TYPE_BURN),
			cat(_name, ": The code does not exist")
		);
		return _burnCodes[burnCode];
	}

	/**
	 * Returns a human-readable message for a given mintcode
	 */
	function messageForMintCode(uint8 mintCode)
		external
		view
		returns (string memory)
	{
		require(
			codeExist(mintCode, CODE_TYPE_MINT),
			cat(_name, ": The code does not exist")
		);
		return _mintCodes[mintCode];
	}

	/**
	 * Returns a human-readable message for a given blockcode
	 */
	function messageForBlockCode(uint8 blockCode)
		external
		view
		returns (string memory)
	{
		require(
			codeExist(blockCode, CODE_TYPE_BLOCK),
			cat(_name, ": The code does not exist")
		);
		return _blockCodes[blockCode];
	}

	/**
	 * Detects if a transfer will be reverted and if so returns an appropriate reference code
	 */
	function detectTransferRestriction(
		address from,
		address to,
		uint256 value
	) public view returns (uint8) {
		if (!_kyc.has(from)) {
			return FROM_NOT_IN_KYC_ROLE;
		} else if (!_kyc.has(to)) {
			return TO_NOT_IN_KYC_ROLE;
		} else if (_transferblock.has(from)) {
			return FROM_IN_TRANSFERBLOCK_ROLE;
		} else if (_transferblock.has(to)) {
			return TO_IN_TRANSFERBLOCK_ROLE;
		} else if (_balances[from] < value) {
			return NOT_ENOUGH_FUNDS;
		} else {
			return NO_RESTRICTIONS;
		}
	}

	/**
	 * Mark a List of `address` with the kyc Role
	 */
	function addUserListToKycRole(address[] calldata whitelistedAddresses)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
			_kyc.add(whitelistedAddresses[i]);
		}
	}

	/**
	 * Remove the Role kyc from an `address`
	 */
	function removeUserFromKycRole(address whitelistedAddress)
		external
		onlyOwner
	{
		require(
			_balances[whitelistedAddress] == 0,
			cat(
				_name,
				": To remove someone from the whitelist the balance have to be 0"
			)
		);
		_kyc.remove(whitelistedAddress);
	}

	/**
	 * Add the Role `transferblock` to an `address`
	 */
	function addTransferBlock(address blockedAddress, uint8 code)
		external
		onlyOwner
	{
		require(
			codeExist(code, CODE_TYPE_BLOCK),
			cat(_name, ": The code does not exist")
		);
		_transferblock.add(blockedAddress);
		emit Block(blockedAddress, code);
	}

	/**
	 * Remove the Role `transferblock` from an `address`
	 */
	function removeTransferblock(address unblockAddress, uint8 code)
		external
		onlyOwner
	{
		require(
			codeExist(code, CODE_TYPE_BLOCK),
			cat(_name, ": The code does not exist")
		);
		_transferblock.remove(unblockAddress);
		emit Unblock(unblockAddress, code);
	}

	/**
	 * Add a new `restrictionCode` with a related `codeText` to the available `_restrictionCodes`
	 */
	function setRestrictionCode(uint8 code, string calldata codeText)
		external
		onlyOwner
	{
		require(
			!codeExist(code, CODE_TYPE_RESTRICTION),
			cat(_name, ": The code already exists")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		_restrictionCodes[code] = codeText;
	}

	/**
	 * Add a new `burncode` with a related `codeText` to the available `_burnCodes`
	 */
	function setBurnCode(uint8 code, string calldata codeText)
		external
		onlyOwner
	{
		require(
			!codeExist(code, CODE_TYPE_BURN),
			cat(_name, ": The code already exists")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		_burnCodes[code] = codeText;
	}

	/**
	 * Add a new `mintcode` with a related `codeText` to the available `_mintCodes`
	 */
	function setMintCode(uint8 code, string calldata codeText)
		external
		onlyOwner
	{
		require(
			!codeExist(code, CODE_TYPE_MINT),
			cat(_name, ": The code already exists")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		_mintCodes[code] = codeText;
	}

	/**
	 * Add a new `blockcode` with a related `codeText` to the available `_blockCodes`
	 */
	function setBlockCode(uint8 code, string calldata codeText)
		external
		onlyOwner
	{
		require(
			!codeExist(code, CODE_TYPE_BLOCK),
			cat(_name, ": The code already exists")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		_blockCodes[code] = codeText;
	}

	/**
	 * Remove a `restrictioncode` from the available `_restrictionCodes`
	 */
	function removeRestrictionCode(uint8 restrictionCode)
		external
		onlyOwner
	{
		require(
			codeExist(restrictionCode, CODE_TYPE_RESTRICTION),
			cat(_name, ": The code does not exist")
		);
		require(
			restrictionCode > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		delete _restrictionCodes[restrictionCode];
	}

	/**
	 * Remove a `burncode` from the available `_burnCodes`
	 */
	function removeBurnCode(uint8 code) external onlyOwner {
		require(
			codeExist(code, CODE_TYPE_BURN),
			cat(_name, ": The code does not exist")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		delete _burnCodes[code];
	}

	/**
	 * Remove a `mintcode` from the available `_mintCodes`
	 */
	function removeMintCode(uint8 code) external onlyOwner {
		require(
			codeExist(code, CODE_TYPE_MINT),
			cat(_name, ": The code does not exist")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		delete _mintCodes[code];
	}

	/**
	 * Remove a `blockcode` from the available `_blockCodes`
	 */
	function removeBlockCode(uint8 code) external onlyOwner {
		require(
			codeExist(code, CODE_TYPE_BLOCK),
			cat(_name, ": The code does not exist")
		);
		require(
			code > 100,
			"ERC1404: Codes till 100 are reserverd for the SmartContract internals"
		);
		delete _blockCodes[code];
	}

	/**
	 * Check if the given Code exists
	 */
	function codeExist(uint8 code, uint8 codeType)
		internal
		view
		returns (bool)
	{
		bytes memory memString;
		if (codeType == CODE_TYPE_RESTRICTION) {
			memString = bytes(_restrictionCodes[code]);
		} else if (codeType == CODE_TYPE_BURN) {
			memString = bytes(_burnCodes[code]);
		} else if (codeType == CODE_TYPE_MINT) {
			memString = bytes(_mintCodes[code]);
		} else if (codeType == CODE_TYPE_BLOCK) {
			memString = bytes(_blockCodes[code]);
		}
		if (memString.length == 0) {
			return false;
		} else {
			return true;
		}
	}

	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5.05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless this function is
	 * overridden;
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public pure returns (uint8) {
		return 18;
	}

	/**
	 * Emitted when `value` tokens are burned from one account (`from`)
	 */
	event Burn(address indexed from, uint256 value, uint8 code);

	/**
	 * Emitted when `value` tokens are minted to a account (`to`)
	 */
	event Mint(address indexed to, uint256 value, uint8 code);

	/**
	 * Emitted when `blockAddress` is blocked for transfers for a reason (`code`)
	 */
	event Block(address indexed blockAddress, uint8 code);

	/**
	 * Emitted when `unblockAddress` is no more blocked for transfers for a reason (`code`)
	 */
	event Unblock(address indexed unblockAddress, uint8 code);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
	struct Role {
		mapping(address => bool) bearer;
	}

	/**
	 * @dev give an account access to this role
	 */
	function add(Role storage role, address account) internal {
		require(account != address(0));
		require(!has(role, account));

		role.bearer[account] = true;
	}

	/**
	 * @dev remove an account's access to this role
	 */
	function remove(Role storage role, address account) internal {
		require(account != address(0));
		require(has(role, account));

		role.bearer[account] = false;
	}

	/**
	 * @dev check if an account has this role
	 * @return bool
	 */
	function has(Role storage role, address account)
		internal
		view
		returns (bool)
	{
		require(account != address(0));
		return role.bearer[account];
	}
}

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
interface IERC1404 {
	/// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
	/// @param from Sending address
	/// @param to Receiving address
	/// @param value Amount of tokens being transferred
	/// @return Code by which to reference message for rejection reasoning
	function detectTransferRestriction(
		address from,
		address to,
		uint256 value
	) external view returns (uint8);

	/// @notice Returns a human-readable message for a given restriction code
	/// @param restrictionCode Identifier for looking up a message
	/// @return Text showing the restriction's reasoning
	function messageForTransferRestriction(uint8 restrictionCode)
		external
		view
		returns (string memory);
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