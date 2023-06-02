// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./CLPCData.sol";
import "./MaliciousRegister.sol";

contract CLPC is IERC20, IERC165, IERC20Metadata, MaliciousRegister, CLPCData {
    string private _symbol;
    uint8 private _decimals;
    string private _name;
    bool private initialized;

    function init(
        string memory name,
        string memory symbol,
        uint _version
    ) external {
        if(initialized){
            return;
        }

        initOwnable();
        initData(_version);

        _symbol = symbol;
        _name = name;
        _supportsInterface[type(IERC165).interfaceId] = true;
        _supportsInterface[type(IERC20).interfaceId] = true;
        _supportsInterface[type(IERC20Metadata).interfaceId] = true;
        _decimals = 0;
        initialized = true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private whenNotPaused {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        decreaseBalanceOf(_from, _value);
        increaseBalanceOf(_to, _value);

        emit Transfer(_from, _to, _value);
    }

    function _allowance(
        address _owner,
        address _spender
    ) private view whenNotPaused returns (uint256 remaining) {
        return getAllowanceOf(_owner, _spender);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal whenNotPaused returns (bool) {
        require(
            increaseAllowanceOf(owner, spender, addedValue),
            "ICLPCData error en increaseAllowanceOf"
        );

        emit Approval(owner, spender, getAllowanceOf(owner, spender));

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        noMalicious
        noMaliciousAddress(spender)
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();

        return _increaseAllowance(owner, spender, addedValue);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal whenNotPaused returns (bool) {
        require(
            decreaseAllowanceOf(owner, spender, subtractedValue),
            "ICLPCData error en decreaseAllowanceOf"
        );

        emit Approval(owner, spender, getAllowanceOf(owner, spender));

        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        noMalicious
        whenNotPaused
        noMaliciousAddress(spender)
        returns (bool)
    {
        return _decreaseAllowance(_msgSender(), spender, subtractedValue);
    }

    function burn(
        uint256 amount
    ) external whenNotPaused noMalicious {
        address account = _msgSender();

        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = getBalanceOf(account);

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        decreaseBalanceOf(account, amount);
        increaseBurnBalanceOf(account, amount);
        decreaseTotalSuply(amount);
        increaseTotalBurnBalance(amount);

        emit Transfer(account, address(0), amount);
    }

    function mint(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner whenNotPaused {
        uint256 totalAmount;

        for (uint i = 0; i < tos.length; i++) {
            address account = tos[i];
            uint256 amount = amounts[i];

            require(account != address(0), "ERC20: mint to the zero address");
            require(amount > 0, "ERC20: mint with more than 0 amount");

            totalAmount += amount;

            increaseBalanceOf(account, amount);

            emit Transfer(address(0), account, amount);
        }

        increaseTotalSuply(totalAmount);
    }

    function setDecimals(uint8 newDecimals) external onlyOwner whenNotPaused {
        _decimals = newDecimals;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function transfer(
        address _to,
        uint256 _value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(_to)
        returns (bool success)
    {
        address from = _msgSender();

        _transfer(from, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(_from)
        noMaliciousAddress(_to)
        returns (bool success)
    {
        address spender = _msgSender();

        _decreaseAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);

        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view override(IERC165) returns (bool) {
        return _supportsInterface[interfaceId];
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override(IERC20) returns (uint256 remaining) {
        return _allowance(_owner, _spender);
    }

    function balanceOf(
        address _owner
    ) external view override(IERC20) returns (uint256 balance) {
        return getBalanceOf(_owner);
    }

    function totalSupply()
        external
        view
        override(IERC20)
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @notice This function was disabled for security, the definition was left only for compatibility but calling this function will always return false
     * @dev Deprecated
     * @return success false
     *
     */
    function approve(
        address _spender,
        uint256 _value
    ) external pure override(IERC20) returns (bool success) {
        return false;
    }

    function burnAmount() external view returns (uint256 amount) {
        return getTotalBurnBalance();
    }

    function burnAmountOf(
        address _address
    ) external view returns (uint256 amountOf) {
        return getBurnBalanceOf(_address);
    }

    function setPause(bool enabled) external onlyOwner {
        if (enabled) {
            _pause();
        } else {
            _unpause();
        }
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IMaliciousRegister.sol";
import "./Ownable.sol";

abstract contract MaliciousRegister is
    IMaliciousRegister,
    Ownable,
    Pausable
{
    mapping(address => bool) private _isMaliciousAccount;

    modifier noMalicious() {
        require(
            !isMaliciousAccount(_msgSender()),
            "MaliciousRegister you can't do this action, your address has been marked as malicious."
        );

        _;
    }

    modifier noMaliciousAddress(address addressToCheck) {
        require(
            !isMaliciousAccount(addressToCheck),
            "MaliciousRegister you can't do this action, the address you used has been marked as malicious."
        );

        _;
    }

    function isMaliciousAccount(
        address accountToCheck
    ) public view override returns (bool) {
        return _isMaliciousAccount[accountToCheck];
    }

    function addMaliciousAccounts(
        address[] memory accountsToAdd
    ) external override onlyOwner whenNotPaused returns (bool added) {
        for (uint i = 0; i < accountsToAdd.length; i++) {
            _isMaliciousAccount[accountsToAdd[i]] = true;
        }

        return true;
    }

    function removeMaliciousAccounts(
        address[] memory accountsToRemove
    ) external override onlyOwner whenNotPaused returns (bool removed) {
        for (uint i = 0; i < accountsToRemove.length; i++) {
            _isMaliciousAccount[accountsToRemove[i]] = false;
        }

        return true;
    }
}

// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

contract CLPCData {
    uint256 internal _totalSupply;

    string public constant currency = "CLP";
    uint public version;

    mapping(address => uint256) private _balanceOf;
    mapping(address => uint256) private _burnAmountOf;
    mapping(address => mapping(address => uint256)) private _allowancesOf;
    mapping(bytes4 => bool) internal _supportsInterface;

    uint256 private _burnAmount;

    function initData(uint _version) internal {
        version = _version;
    }

    function getAllowanceOf(
        address owner,
        address spender
    ) internal view returns (uint256 remaining) {
        return _allowancesOf[owner][spender];
    }

    function allowanceCheck(address owner, address spender) private pure {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
    }

    function increaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToAdd
    ) internal returns (bool) {
        allowanceCheck(owner, spender);

        _allowancesOf[owner][spender] += allowanceToAdd;

        return true;
    }

    function decreaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToSustract
    ) internal returns (bool) {
        allowanceCheck(owner, spender);

        require(
            _allowancesOf[owner][spender] >= allowanceToSustract,
            "CLPCData: decreased allowance below zero"
        );

        unchecked {
            _allowancesOf[owner][spender] -= allowanceToSustract;
        }

        return true;
    }

    function getBalanceOf(address who) internal view returns (uint256 balance) {
        return _balanceOf[who];
    }

    function getBurnBalanceOf(address who) internal view returns (uint256) {
        return _burnAmountOf[who];
    }

    function getTotalBurnBalance() internal view returns (uint256) {
        return _burnAmount;
    }

    function decreaseBalanceOf(
        address who,
        uint256 balanceToSustract
    ) internal returns (uint256 newBalance) {
        uint256 fromBalance = _balanceOf[who];

        require(
            fromBalance >= balanceToSustract,
            "CLPCData: decrease amount below 0"
        );

        unchecked {
            _balanceOf[who] -= balanceToSustract;
        }

        return _balanceOf[who];
    }

    function increaseBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBalance) {
        _balanceOf[who] += balanceToAdd;

        return _balanceOf[who];
    }

    function increaseBurnBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        _burnAmountOf[who] += balanceToAdd;

        return _burnAmountOf[who];
    }

    function increaseTotalBurnBalance(
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        _burnAmount += balanceToAdd;

        return _burnAmount;
    }

    function increaseTotalSuply(
        uint256 balanceToAdd
    ) internal returns (uint256 newTotalSupply) {
        _totalSupply += balanceToAdd;

        return _totalSupply;
    }

    function decreaseTotalSuply(
        uint256 balanceToSustract
    ) internal returns (uint256 newTotalSupply) {
        _totalSupply -= balanceToSustract;

        return _totalSupply;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initOwnable() internal {
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

// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

interface IMaliciousRegister{
    function isMaliciousAccount(address accountToCheck) external view returns (bool);

    function addMaliciousAccounts(address[] memory accountsToAdd) external returns (bool added);

    function removeMaliciousAccounts(address[] memory accountsToRemove) external returns (bool removed);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}