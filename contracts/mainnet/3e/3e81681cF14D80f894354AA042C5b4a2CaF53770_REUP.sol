// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IBridgeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Implements cross-chain bridging functionality (for our purposes, in an ERC20)

    The bridge (an off-chain process) can sign instructions for minting, which users can submit to the blockchain.

    Users can also send funds to the bridge, which can be detected by the bridge processor looking for "BridgeOut" events
 */
abstract contract Bridgeable is IBridgeable
{
    bytes32 private constant BridgeInstructionFulfilledSlotPrefix = keccak256("SLOT:Bridgeable:bridgeInstructionFulfilled");

    bool public constant isBridgeable = true;
    bytes32 private constant bridgeInTypeHash = keccak256("BridgeIn(uint256 instructionId,address to,uint256 value)");

    // A fully constructed contract would likely use "Minter" contract functions to implement this
    function bridgeCanMint(address user) internal virtual view returns (bool);
    // A fully constructed contract would likely use "RERC20" contract functions to implement these
    function bridgeSigningHash(bytes32 dataHash) internal virtual view returns (bytes32);
    function bridgeMint(address to, uint256 amount) internal virtual;
    function bridgeBurn(address from, uint256 amount) internal virtual;

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IBridgeable(newImplementation).isBridgeable());
    }

    function bridgeInstructionFulfilled(uint256 instructionId)
        public
        view
        returns (bool)
    {
        return StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instructionId))).value;
    }

    function throwStatus(uint256 status)
        private
        pure
    {
        if (status == 1) { revert ZeroAmount(); }
        if (status == 2) { revert InvalidBridgeSignature(); }
        if (status == 3) { revert DuplicateInstruction(); }
    }

    /** Returns 0 on success */
    function bridgeInCore(BridgeInstruction calldata instruction)
        private
        returns (uint256)
    {
        if (instruction.value == 0) { return 1; }
        if (!bridgeCanMint(
                ecrecover(
                    bridgeSigningHash(
                        keccak256(
                            abi.encode(
                                bridgeInTypeHash, 
                                instruction.instructionId,
                                instruction.to, 
                                instruction.value))),
                instruction.v,
                instruction.r,
                instruction.s))) 
        {
            return 2;
        }
        StorageSlot.BooleanSlot storage fulfilled = StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instruction.instructionId)));
        if (fulfilled.value) { return 3; }
        fulfilled.value = true;
        bridgeMint(instruction.to, instruction.value);
        emit BridgeIn(instruction.instructionId, instruction.to, instruction.value);
        return 0;
    }

    /** Mints according to the bridge instruction, or reverts on failure */
    function bridgeIn(BridgeInstruction calldata instruction)
        public
    {
        uint256 status = bridgeInCore(instruction);
        if (status != 0) { throwStatus(status); }
    }

    /** Mints according to multiple bridge instructions.  Only reverts if no instructions succeeded */
    function multiBridgeIn(BridgeInstruction[] calldata instructions)
        public
    {
        bool anySuccess = false;
        uint256 status = 0;
        for (uint256 x = instructions.length; x > 0;) 
        {
            unchecked { --x; }
            status = bridgeInCore(instructions[x]);
            if (status == 0) { anySuccess = true; }
        }
        if (!anySuccess) 
        {
            throwStatus(status); 
            revert ZeroArray();
        }
    }

    /** Sends funds to the bridge */
    function bridgeOut(address controller, uint256 value)
        public
    {
        if (value == 0) { revert ZeroAmount(); }
        if (controller == address(0)) { revert ZeroAddress(); }
        bridgeBurn(msg.sender, value);
        emit BridgeOut(msg.sender, controller, value);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./RERC20.sol";
import "./IBridgeRERC20.sol";
import "./Bridgeable.sol";

/**
    A bridgeable ERC20 contract
*/
abstract contract BridgeRERC20 is RERC20, Minter, Bridgeable, IBridgeRERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(RERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        RERC20.checkUpgrade(newImplementation);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./SelfStakingERC20.sol";
import "./IBridgeSelfStakingERC20.sol";
import "./Bridgeable.sol";

/**
    A bridgeable self-staking ERC20 contract
*/
abstract contract BridgeSelfStakingERC20 is SelfStakingERC20, Minter, Bridgeable, IBridgeSelfStakingERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(SelfStakingERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        SelfStakingERC20.checkUpgrade(newImplementation);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/*
    Including things we want hardhat to compile so that we can use artifacts or load contract factories
*/

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/**
    Functionality to help implement "permit" on ERC20's
 */
abstract contract EIP712 
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory name) 
    {
        nameHash = keccak256(bytes(name));
    }

    bytes32 private constant eip712DomainHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant versionHash = keccak256(bytes("1"));
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 public immutable nameHash;
    
    function domainSeparator()
        internal
        view
        returns (bytes32) 
    {
        // Can't cache this in an upgradeable contract unfortunately
        return keccak256(abi.encode(
            eip712DomainHash,
            nameHash,
            versionHash,
            block.chainid,
            address(this)));
    }
    
    function getSigningHash(bytes32 dataHash)
        internal
        view
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IBridgeable
{
    struct BridgeInstruction
    {
        uint256 instructionId;
        uint256 value;
        address to;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event BridgeIn(uint256 indexed instructionId, address indexed to, uint256 value);
    event BridgeOut(address indexed from, address indexed controller, uint256 value);

    error ZeroAmount();
    error ZeroAddress();
    error ZeroArray();
    error DuplicateInstruction();
    error InvalidBridgeSignature();

    function isBridgeable() external view returns (bool);
    function bridgeInstructionFulfilled(uint256 instructionId) external view returns (bool);

    function bridgeIn(BridgeInstruction calldata instruction) external;
    function multiBridgeIn(BridgeInstruction[] calldata instructions) external;
    function bridgeOut(address controller, uint256 value) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./IRERC20.sol";
import "./IBridgeable.sol";

interface IBridgeRERC20 is IBridgeable, IMinter, IRERC20
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./ISelfStakingERC20.sol";
import "./IBridgeable.sol";

interface IBridgeSelfStakingERC20 is IBridgeable, IMinter, ISelfStakingERC20
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICanMint is IERC20
{
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Full is IERC20Metadata, IERC20Permit {
    /** This function might not exist */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IMinter
{
    event SetMinter(address user, bool canMint);
    
    error NotMinter();
    error NotMinterOwner();
    
    function isMinter(address user) external view returns (bool);
    
    function setMinter(address user, bool canMint) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IOwned
{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    error NotOwner();
    error AlreadyInitialized();

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/CheapSafeERC20.sol";

interface IRECoverable
{
    error NotRECoverableOwner();
    
    function recoverERC20(IERC20 token) external;
    function recoverNative() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IERC20Full.sol";

interface IRERC20 is IERC20Full
{
    error InsufficientAllowance();
    error InsufficientBalance();
    error TransferFromZeroAddress();
    error MintToZeroAddress();
    error DeadlineExpired();
    error InvalidPermitSignature();
    error NameMismatch();
    
    function isRERC20() external view returns (bool);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREStablecoins.sol";
import "../IREUSD.sol";
import "../IRECustodian.sol";

interface IREUSDMinterBase
{
    event MintREUSD(address indexed minter, IERC20 paymentToken, uint256 reusdAmount);

    function REUSD() external view returns (IREUSD);
    function stablecoins() external view returns (IREStablecoins);
    function totalMinted() external view returns (uint256);
    function totalReceived(IERC20 paymentToken) external view returns (uint256);
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount) external view returns (uint256 reusdAmount);
    function custodian() external view returns (IRECustodian);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRERC20.sol";
import "./IOwned.sol";

interface ISelfStakingERC20 is IRERC20
{
    event RewardAdded(uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event Excluded(address indexed user, bool excluded);

    error InvalidParameters();
    error TooMuch();
    error WrongRewardToken();
    error NotDelegatedClaimer();
    error NotRewardManager();
    error NotSelfStakingERC20Owner();

    function isSelfStakingERC20() external view returns (bool);
    function rewardToken() external view returns (IERC20);
    function isExcluded(address addr) external view returns (bool);
    function totalStakingSupply() external view returns (uint256);
    function rewardData() external view returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute);
    function pendingReward(address user) external view returns (uint256);
    function isDelegatedClaimer(address user) external view returns (bool);
    function isRewardManager(address user) external view returns (bool);

    function claim() external;
    
    function claimFor(address user) external;

    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external;
    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function setExcluded(address user, bool excluded) external;
    function setDelegatedClaimer(address user, bool enable) external;
    function setRewardManager(address user, bool enable) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IUUPSUpgradeableVersion.sol";
import "./IRECoverable.sol";
import "./IOwned.sol";

interface IUpgradeableBase is IUUPSUpgradeableVersion, IRECoverable, IOwned
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IUUPSUpgradeable
{
    event Upgraded(address newImplementation);

    error ProxyDelegateCallRequired();
    error DelegateCallForbidden();
    error ProxyNotActive();
    error NotUUPS();
    error UnsupportedProxiableUUID();
    error UpgradeCallFailed();
    
    function proxiableUUID() external view returns (bytes32);
    
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IUUPSUpgradeable.sol";

interface IUUPSUpgradeableVersion is IUUPSUpgradeable
{
    error UpgradeToSameVersion();

    function contractVersion() external view returns (uint256);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IMinter.sol";
import "../Library/Roles.sol";

/**
    Exposes minter role functionality
 */
abstract contract Minter is IMinter
{
    bytes32 private constant MinterRole = keccak256("ROLE:Minter");

    // Probably implemented using "Owned" contract functions
    function getMinterOwner() internal virtual view returns (address);

    function isMinter(address user)
        public
        view
        returns (bool)
    {
        return Roles.hasRole(MinterRole, user);
    }

    modifier onlyMinter()
    {
        if (!isMinter(msg.sender)) { revert NotMinter(); }
        _;
    }

    function setMinter(address user, bool canMint)
        public
    {
        if (msg.sender != getMinterOwner()) { revert NotMinterOwner(); }
        emit SetMinter(user, canMint);
        Roles.setRole(MinterRole, user, canMint);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IOwned.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Allows contract ownership, but not renunciation
 */
abstract contract Owned is IOwned
{
    bytes32 private constant OwnerSlot = keccak256("SLOT:Owned:owner");
    bytes32 private constant PendingOwnerSlot = keccak256("SLOT:Owned:pendingOwner");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable firstOwner = msg.sender;

    function owner() public view returns (address)
    {
        address o = StorageSlot.getAddressSlot(OwnerSlot).value;
        return o == address(0) ? firstOwner : o;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        StorageSlot.getAddressSlot(PendingOwnerSlot).value = newOwner;
    }

    function claimOwnership()
        public
    {
        StorageSlot.AddressSlot storage pending = StorageSlot.getAddressSlot(PendingOwnerSlot);
        if (pending.value != msg.sender) { revert NotOwner(); }
        emit OwnershipTransferred(owner(), msg.sender);
        pending.value = address(0);
        StorageSlot.getAddressSlot(OwnerSlot).value = msg.sender;
    }

    modifier onlyOwner() 
    {
        if (msg.sender != owner()) { revert NotOwner(); }
        _;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECoverable.sol";

using CheapSafeERC20 for IERC20;

/**
    Allows for recovery of funds
 */
abstract contract RECoverable is IRECoverable 
{
    // Probably implemented using "Owned" contract functions
    function getRECoverableOwner() internal virtual view returns (address);

    function recoverERC20(IERC20 token)
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverERC20(token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function beforeRecoverERC20(IERC20 token) internal virtual {}

    function recoverNative()
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverNative();
        (bool success,) = msg.sender.call{ value: address(this).balance }(""); 
        assert(success);
    }

    function beforeRecoverNative() internal virtual {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./EIP712.sol";
import "./IRERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../Library/StringHelper.sol";

/**
    Our ERC20 (also supporting "permit")

    RERC20... because RE... real estate... uh....... yeah.  It was just hard to name it.

    It does not use any default-slot storage
 */
abstract contract RERC20 is EIP712, IRERC20
{
    bytes32 private constant TotalSupplySlot = keccak256("SLOT:RERC20:totalSupply");
    bytes32 private constant BalanceSlotPrefix = keccak256("SLOT:RERC20:balanceOf");
    bytes32 private constant AllowanceSlotPrefix = keccak256("SLOT:RERC20:allowance");
    bytes32 private constant NoncesSlotPrefix = keccak256("SLOT:RERC20:nonces");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable nameBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable symbolBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 public immutable decimals;

    bool public constant isRERC20 = true;
    bool public constant isUUPSERC20 = true; // This can be removed after all deployed contracts are upgraded
    bytes32 private constant permitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals) 
        EIP712(_name)
    {
        nameBytes = StringHelper.toBytes32(_name);
        symbolBytes = StringHelper.toBytes32(_symbol);
        decimals = _decimals;
    }

    function name() public view returns (string memory) { return StringHelper.toString(nameBytes); }
    function symbol() public view returns (string memory) { return StringHelper.toString(symbolBytes); }
    function version() public pure returns (string memory) { return "1"; }

    function balanceSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(BalanceSlotPrefix, user))); }
    function allowanceSlot(address owner, address spender) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(AllowanceSlotPrefix, owner, spender))); }
    function noncesSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(NoncesSlotPrefix, user))); }

    function totalSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalSupplySlot).value; }
    function balanceOf(address user) public view returns (uint256) { return balanceSlot(user).value; }
    function allowance(address owner, address spender) public view returns (uint256) { return allowanceSlot(owner, spender).value; }
    function nonces(address user) public view returns (uint256) { return noncesSlot(user).value; }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IRERC20(newImplementation).isRERC20());
        assert(EIP712(newImplementation).nameHash() == nameHash);
    }

    function approveCore(address _owner, address _spender, uint256 _amount) internal returns (bool)
    {
        allowanceSlot(_owner, _spender).value = _amount;
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function transferCore(address _from, address _to, uint256 _amount) internal returns (bool)
    {
        if (_from == address(0)) { revert TransferFromZeroAddress(); }
        if (_to == address(0)) 
        {
            burnCore(_from, _amount);
            return true;
        }
        StorageSlot.Uint256Slot storage fromBalanceSlot = balanceSlot(_from);
        uint256 oldBalance = fromBalanceSlot.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeTransfer(_from, _to, _amount);
        unchecked 
        {
            fromBalanceSlot.value = oldBalance - _amount; 
            balanceSlot(_to).value += _amount;
        }
        emit Transfer(_from, _to, _amount);
        afterTransfer(_from, _to, _amount);
        return true;
    }

    function mintCore(address _to, uint256 _amount) internal
    {
        if (_to == address(0)) { revert MintToZeroAddress(); }
        beforeMint(_to, _amount);
        StorageSlot.getUint256Slot(TotalSupplySlot).value += _amount;
        unchecked { balanceSlot(_to).value += _amount; }
        afterMint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burnCore(address _from, uint256 _amount) internal
    {
        StorageSlot.Uint256Slot storage fromBalance = balanceSlot(_from);
        uint256 oldBalance = fromBalance.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeBurn(_from, _amount);
        unchecked
        {
            fromBalance.value = oldBalance - _amount;
            StorageSlot.getUint256Slot(TotalSupplySlot).value -= _amount;
        }
        emit Transfer(_from, address(0), _amount);
        afterBurn(_from, _amount);
    }

    function approve(address _spender, uint256 _amount) public returns (bool)
    {
        return approveCore(msg.sender, _spender, _amount);
    }

    function transfer(address _to, uint256 _amount) public returns (bool)
    {
        return transferCore(msg.sender, _to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        StorageSlot.Uint256Slot storage fromAllowance = allowanceSlot(_from, msg.sender);
        uint256 oldAllowance = fromAllowance.value;
        if (oldAllowance != type(uint256).max) 
        {
            if (oldAllowance < _amount) { revert InsufficientAllowance(); }
            unchecked { fromAllowance.value = oldAllowance - _amount; }
        }
        return transferCore(_from, _to, _amount);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function afterTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function beforeBurn(address _from, uint256 _amount) internal virtual {}
    function afterBurn(address _from, uint256 _amount) internal virtual {}
    function beforeMint(address _to, uint256 _amount) internal virtual {}
    function afterMint(address _to, uint256 _amount) internal virtual {}

    function DOMAIN_SEPARATOR() public view returns (bytes32) { return domainSeparator(); }

    function permit(address _owner, address _spender, uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public
    {
        if (block.timestamp > _deadline) { revert DeadlineExpired(); }
        uint256 nonce;
        unchecked { nonce = noncesSlot(_owner).value++; }
        address signer = ecrecover(getSigningHash(keccak256(abi.encode(permitTypeHash, _owner, _spender, _amount, nonce, _deadline))), _v, _r, _s);
        if (signer != _owner || signer == address(0)) { revert InvalidPermitSignature(); }
        approveCore(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREUSD.sol";
import "./IREUSDMinterBase.sol";
import "../Library/CheapSafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

using CheapSafeERC20 for IERC20;

/**
    Functionality for a contract that wants to mint REUSD

    It knows how to mint the correct amount and take payment from an accepted stablecoin
 */
abstract contract REUSDMinterBase is IREUSDMinterBase
{
    bytes32 private constant TotalMintedSlot = keccak256("SLOT:REUSDMinterBase:totalMinted");
    bytes32 private constant TotalReceivedSlotPrefix = keccak256("SLOT:REUSDMinterBase:totalReceived");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREUSD public immutable REUSD;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREStablecoins public immutable stablecoins;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECustodian public immutable custodian;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
    {
        assert(_REUSD.isREUSD() && _stablecoins.isREStablecoins() && _custodian.isRECustodian());
        REUSD = _REUSD;
        stablecoins = _stablecoins;
        custodian = _custodian;
    }    

    function totalMinted() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalMintedSlot).value; }
    function totalReceivedSlot(IERC20 paymentToken) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(TotalReceivedSlotPrefix, paymentToken))); }
    function totalReceived(IERC20 paymentToken) public view returns (uint256) { return totalReceivedSlot(paymentToken).value; }

    /** 
        Gets the amount of REUSD that will be minted for an amount of an acceptable payment token
        Reverts if the payment token is not accepted
        
        All accepted stablecoins have 6 or 18 decimals
    */
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount)
        public
        view
        returns (uint256 reusdAmount)
    {        
        return stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? paymentTokenAmount * 10**12 : paymentTokenAmount;
    }

    /**
        This will:
            Take payment (or revert if the payment token is not acceptable)
            Send the payment to the custodian address
            Mint REUSD
     */
    function mintREUSDCore(address from, IERC20 paymentToken, address recipient, uint256 reusdAmount)
        internal
    {
        uint256 factor = stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? 10**12 : 1;
        uint256 paymentAmount = reusdAmount / factor;
        unchecked { if (paymentAmount * factor != reusdAmount) { ++paymentAmount; } }
        paymentToken.safeTransferFrom(from, address(custodian), paymentAmount);
        REUSD.mint(recipient, reusdAmount);
        emit MintREUSD(from, paymentToken, reusdAmount);
        StorageSlot.getUint256Slot(TotalMintedSlot).value += reusdAmount;
        totalReceivedSlot(paymentToken).value += paymentAmount;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./RERC20.sol";
import "./ISelfStakingERC20.sol";
import "../Library/CheapSafeERC20.sol";
import "../Library/Roles.sol";

using CheapSafeERC20 for IERC20;

/**
    An ERC20 which gives out staking rewards just for owning the token, without the need to interact with staking contracts

    This seems... odd.  But it was necessary to avoid weird problems with other approaches with a separate staking contract

    The functionality is similar to masterchef or other popular staking contracts, with some notable differences:

        Interacting with it doesn't trigger rewards to be sent to you automatically
            Instead, it's tracked via "Owed" storage slots
            Necessary to stop contracts from accidentally earning USDC (ie: Uniswap, Sushiswap, etc)
        We add a reward, and it's split evenly over a period of time
        We can exclude addresses from receiving rewards (curve pools, uniswap, sushiswap, etc)
 */
abstract contract SelfStakingERC20 is RERC20, ISelfStakingERC20
{
    bytes32 private constant TotalStakingSupplySlot = keccak256("SLOT:SelfStakingERC20:totalStakingSupply");
    bytes32 private constant TotalRewardDebtSlot = keccak256("SLOT:SelfStakingERC20:totalRewardDebt");
    bytes32 private constant TotalOwedSlot = keccak256("SLOT:SelfStakingERC20:totalOwed");
    bytes32 private constant RewardInfoSlot = keccak256("SLOT:SelfStakingERC20:rewardInfo");
    bytes32 private constant RewardPerShareSlot = keccak256("SLOT:SelfStakingERC20:rewardPerShare");
    bytes32 private constant UserRewardDebtSlotPrefix = keccak256("SLOT:SelfStakingERC20:userRewardDebt");
    bytes32 private constant UserOwedSlotPrefix = keccak256("SLOT:SelfStakingERC20:userOwed");

    bytes32 private constant DelegatedClaimerRole = keccak256("ROLE:SelfStakingERC20:delegatedClaimer");
    bytes32 private constant RewardManagerRole = keccak256("ROLE:SelfStakingERC20:rewardManager");
    bytes32 private constant ExcludedRole = keccak256("ROLE:SelfStakingERC20:excluded");

    struct RewardInfo 
    {
        uint32 lastRewardTimestamp;
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint160 amountToDistribute;
    }

    bool public constant isSelfStakingERC20 = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable rewardToken;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol, uint8 _decimals) 
        RERC20(_name, _symbol, _decimals)
    {
        rewardToken = _rewardToken;
    }

    // Probably hooked up using functions from "Owned"
    function getSelfStakingERC20Owner() internal virtual view returns (address);

    /** The total supply MINUS balances held by excluded addresses */
    function totalStakingSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalStakingSupplySlot).value; }

    function userRewardDebtSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserRewardDebtSlotPrefix, user))); }
    function userOwedSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserOwedSlotPrefix, user))); }

    function isExcluded(address user) public view returns (bool) { return Roles.hasRole(ExcludedRole, user); }
    function isDelegatedClaimer(address user) public view returns (bool) { return Roles.hasRole(DelegatedClaimerRole, user); }
    function isRewardManager(address user) public view returns (bool) { return Roles.hasRole(RewardManagerRole, user); }

    modifier onlySelfStakingERC20Owner()
    {
        if (msg.sender != getSelfStakingERC20Owner()) { revert NotSelfStakingERC20Owner(); }
        _;
    }

    function getRewardInfo()
        internal
        view
        returns (RewardInfo memory rewardInfo)
    {
        unchecked
        {
            uint256 packed = StorageSlot.getUint256Slot(RewardInfoSlot).value;
            rewardInfo.lastRewardTimestamp = uint32(packed >> 224);
            rewardInfo.startTimestamp = uint32(packed >> 192);
            rewardInfo.endTimestamp = uint32(packed >> 160);
            rewardInfo.amountToDistribute = uint160(packed);
        }
    }
    function setRewardInfo(RewardInfo memory rewardInfo)
        internal
    {
        unchecked
        {
            StorageSlot.getUint256Slot(RewardInfoSlot).value = 
                (uint256(rewardInfo.lastRewardTimestamp) << 224) |
                (uint256(rewardInfo.startTimestamp) << 192) |
                (uint256(rewardInfo.endTimestamp) << 160) |
                uint256(rewardInfo.amountToDistribute);
        }
    }

    /** 
        Excludes/includes an address from being able to receive rewards

        Any rewards already owing will be lost to the user, and will end up being added into the rewards pool next time rewards are added
     */
    function setExcluded(address user, bool excluded)
        public
        onlySelfStakingERC20Owner
    {
        if (isExcluded(user) == excluded) { return; }

        /*
            Our strategy is
                Nuke their balance (forces calculations to be done, too) 
                Set them as excluded/included
                If they're being excluded, we nuke their owed rewards
                Restore their balance
        */
        
        uint256 balance = balanceOf(user);
        if (balance > 0)
        {
            burnCore(user, balance);
        }

        Roles.setRole(ExcludedRole, user, excluded);

        if (excluded)
        {
            StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
            uint256 oldOwed = owedSlot.value;
            if (oldOwed != 0)
            {
                owedSlot.value = 0;
                StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
            }
        }

        if (balance > 0)
        {
            mintCore(user, balance);
        }

        emit Excluded(user, excluded);
    }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        override
        view
        onlySelfStakingERC20Owner
    {
        ISelfStakingERC20 newContract = ISelfStakingERC20(newImplementation);
        assert(newContract.isSelfStakingERC20());
        if (newContract.rewardToken() != rewardToken) { revert WrongRewardToken(); }
        super.checkUpgrade(newImplementation);
    }

    function rewardData()
        public
        view
        returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute)
    {
        RewardInfo memory rewardInfo = getRewardInfo();
        lastRewardTimestamp = rewardInfo.lastRewardTimestamp;
        startTimestamp = rewardInfo.startTimestamp;
        endTimestamp = rewardInfo.endTimestamp;
        amountToDistribute = rewardInfo.amountToDistribute;
    }

    /** Calculates how much NEW reward should be released based on the distribution rate and time passed */
    function calculateReward(RewardInfo memory reward)
        private
        view
        returns (uint256)
    {
        if (block.timestamp <= reward.lastRewardTimestamp ||
            reward.lastRewardTimestamp >= reward.endTimestamp ||
            block.timestamp <= reward.startTimestamp ||
            reward.startTimestamp == reward.endTimestamp)
        {
            return 0;
        }
        uint256 from = reward.lastRewardTimestamp < reward.startTimestamp ? reward.startTimestamp : reward.lastRewardTimestamp;
        uint256 until = block.timestamp < reward.endTimestamp ? block.timestamp : reward.endTimestamp;
        return reward.amountToDistribute * (until - from) / (reward.endTimestamp - reward.startTimestamp);
    }

    function pendingReward(address user)
        public
        view
        returns (uint256)
    {
        if (isExcluded(user)) { return 0; }
        uint256 perShare = StorageSlot.getUint256Slot(RewardPerShareSlot).value;
        RewardInfo memory reward = getRewardInfo();
        uint256 totalStaked = totalStakingSupply();
        if (totalStaked != 0) 
        {
            perShare += calculateReward(reward) * 1e30 / totalStaked;
        }
        return balanceOf(user) * perShare / 1e30 - userRewardDebtSlot(user).value + userOwedSlot(user).value;
    }

    /** Updates the state with any new rewards, and returns the new rewardPerShare multiplier */
    function update() 
        private
        returns (uint256 rewardPerShare)
    {
        StorageSlot.Uint256Slot storage rewardPerShareSlot = StorageSlot.getUint256Slot(RewardPerShareSlot);
        rewardPerShare = rewardPerShareSlot.value;        
        RewardInfo memory reward = getRewardInfo();
        uint256 rewardToAdd = calculateReward(reward);
        if (rewardToAdd == 0) { return rewardPerShare; }

        uint256 totalStaked = totalStakingSupply();
        if (totalStaked > 0) 
        {
            rewardPerShare += rewardToAdd * 1e30 / totalStaked;
            rewardPerShareSlot.value = rewardPerShare;
        }

        reward.lastRewardTimestamp = uint32(block.timestamp);
        setRewardInfo(reward);
    }

    /** Adds rewards and updates the timeframes.  Any leftover rewards not yet distributed are added */
    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp)
        public
    {
        if (!isRewardManager(msg.sender) && msg.sender != getSelfStakingERC20Owner()) { revert NotRewardManager(); }
        if (startTimestamp < block.timestamp) { startTimestamp = block.timestamp; }
        if (startTimestamp >= endTimestamp || endTimestamp > type(uint32).max) { revert InvalidParameters(); }
        uint256 rewardPerShare = update();
        rewardToken.transferFrom(msg.sender, address(this), amount);
        uint256 amountToDistribute = rewardToken.balanceOf(address(this)) + StorageSlot.getUint256Slot(TotalRewardDebtSlot).value - StorageSlot.getUint256Slot(TotalOwedSlot).value - totalStakingSupply() * rewardPerShare / 1e30;
        if (amountToDistribute > type(uint160).max) { revert TooMuch(); }
        setRewardInfo(RewardInfo({
            amountToDistribute: uint160(amountToDistribute),
            startTimestamp: uint32(startTimestamp),
            endTimestamp: uint32(endTimestamp),
            lastRewardTimestamp: uint32(block.timestamp)
        }));
        emit RewardAdded(amount);
    }

    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(address(rewardToken)).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        addReward(amount, startTimestamp, endTimestamp);
    }

    /** Pays out all rewards */
    function claim()
        public
    {
        claimCore(msg.sender);
    }

    function claimFor(address user)
        public
    {
        if (!isDelegatedClaimer(msg.sender)) { revert NotDelegatedClaimer(); }
        claimCore(user);
    }

    function claimCore(address user)
        private
    {
        if (isExcluded(user)) { return; }
        uint256 rewardPerShare = update();
        StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
        uint256 oldOwed = owedSlot.value;
        StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 newDebt = balanceOf(user) * rewardPerShare / 1e30;
        uint256 claimAmount = oldOwed + newDebt - oldDebt;
        if (claimAmount == 0) { return; }
        owedSlot.value = 0;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
        sendReward(user, claimAmount);
    }

    function sendReward(address user, uint256 amount)
        private
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) { amount = balance; }
        rewardToken.safeTransfer(user, amount);
        emit RewardPaid(user, amount);
    }

    /** update() must be called before this */
    function updateOwed(address user, uint256 rewardPerShare, uint256 currentBalance, uint256 newBalance)
        private
    {
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 pending = currentBalance * rewardPerShare / 1e30 - oldDebt;
        StorageSlot.getUint256Slot(TotalOwedSlot).value += pending;
        userOwedSlot(user).value += pending;
        uint256 newDebt = newBalance * rewardPerShare / 1e30;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
    }

    function setDelegatedClaimer(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(DelegatedClaimerRole, user, enable);
    }

    function setRewardManager(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(RewardManagerRole, user, enable);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) 
        internal
        override
    {
        bool fromExcluded = isExcluded(_from);
        bool toExcluded = isExcluded(_to);
        if (!fromExcluded || !toExcluded)
        {
            uint256 rewardPerShare = update();
            uint256 balance;
            if (!fromExcluded)
            {
                balance = balanceOf(_from);
                updateOwed(_from, rewardPerShare, balance, balance - _amount);
            }
            if (!toExcluded)
            {
                balance = balanceOf(_to);
                updateOwed(_to, rewardPerShare, balance, balance + _amount);
            }
        }
        if (fromExcluded || toExcluded)
        {
            StorageSlot.Uint256Slot storage totalStaked = StorageSlot.getUint256Slot(TotalStakingSupplySlot);
            totalStaked.value = 
                totalStaked.value
                + (fromExcluded ? _amount : 0)
                - (toExcluded ? _amount : 0);
        }
    }    

    function beforeBurn(address _from, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_from))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_from);
            updateOwed(_from, rewardPerShare, balance, balance - _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value -= _amount;
        }
    }

    function beforeMint(address _to, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_to))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_to);
            updateOwed(_to, rewardPerShare, balance, balance + _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value += _amount;
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./UUPSUpgradeableVersion.sol";
import "./RECoverable.sol";
import "./Owned.sol";
import "./IUpgradeableBase.sol";

/**
    All deployable upgradeable contracts should derive from this
 */
abstract contract UpgradeableBase is UUPSUpgradeableVersion, RECoverable, Owned, IUpgradeableBase
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
        UUPSUpgradeableVersion(__contractVersion)
    {
    }

    function getRECoverableOwner() internal override view returns (address) { return owner(); }
    
    function beforeUpgradeVersion(address newImplementation)
        internal
        override
        view
        onlyOwner
    {
        checkUpgradeBase(newImplementation);
    }

    function checkUpgradeBase(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./IUUPSUpgradeable.sol";

/**
    Adapted from openzeppelin's UUPSUpgradeable

    However, with some notable differences
        
        We don't use the whole "initializers" scheme.  It's error-prone and awkward.  A couple contracts
        may have an initialize function, but it's not some special built-in scheme that can be screwed up.

        We don't use beacons, and we don't need to upgrade from old UUPS or other types of proxies.  We
        only support UUPS.  We don't support rollbacks.

        We don't use default-slot storage.  It's also error-prone and awkward.  It's weird that it was ever
        done that way in the first place.  But regardless, we don't.

        We have no concept of "Admin" at this stage.  Whoever implements "beforeUpgrade" can decide to
        check access if they want to.  For us, we do this in "UpgradeableBase".

 */

abstract contract UUPSUpgradeable is IUUPSUpgradeable
{
    bytes32 private constant ImplementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable self = address(this);

    function beforeUpgrade(address newImplementation) internal virtual view;
    
    modifier notDelegated()
    {
        if (address(this) != self) { revert DelegateCallForbidden(); }
        _;
    }

    modifier onlyProxy()
    {
        if (address(this) == self) { revert ProxyDelegateCallRequired(); }
        if (StorageSlot.getAddressSlot(ImplementationSlot).value != self) { revert ProxyNotActive(); }
        _;
    }

    function proxiableUUID()
        public
        virtual
        view
        notDelegated
        returns (bytes32)
    {
        return ImplementationSlot;
    }

    function upgradeTo(address newImplementation)
        public
        onlyProxy
    {
        try IUUPSUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot)
        {
            if (slot != ImplementationSlot) { revert UnsupportedProxiableUUID(); }
            beforeUpgrade(newImplementation);
            StorageSlot.getAddressSlot(ImplementationSlot).value = newImplementation;
            emit Upgraded(newImplementation);
        }
        catch
        {
            revert NotUUPS();
        }
    }
    
    function upgradeToAndCall(address newImplementation, bytes memory data)
        public
    {
        upgradeTo(newImplementation);
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returndata) = newImplementation.delegatecall(data);
        if (!success)
        {
            if (returndata.length > 0)
            {
                assembly
                {                                
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert UpgradeCallFailed();
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./IUUPSUpgradeableVersion.sol";

/**
    Adds contract versioning

    Contract upgrades to a new contract with the same version will be rejected
 */
abstract contract UUPSUpgradeableVersion is UUPSUpgradeable, IUUPSUpgradeableVersion
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable _contractVersion;

    function contractVersion() public virtual view returns (uint256) { return _contractVersion; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
    {
        _contractVersion = __contractVersion;
    }

    function beforeUpgrade(address newImplementation)
        internal
        override
        view
    {
        if (IUUPSUpgradeableVersion(newImplementation).contractVersion() == contractVersion()) { revert UpgradeToSameVersion(); }        
        beforeUpgradeVersion(newImplementation);
    }

    function beforeUpgradeVersion(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface ICurveFactory
{
    function find_pool_for_coins(address from, address to, uint256 index) external view returns (address);
    function deploy_metapool(address base_pool, string memory name, string memory symbol, address token, uint256 A, uint256 fee) external returns (address);
    function get_gauge(address _pool) external view returns (address);
    function deploy_gauge(address _pool) external returns (address);
    function pool_count() external view returns (uint256);
    function pool_list(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./ICurveStableSwap.sol";

interface ICurveGauge is IERC20Full
{
    struct Reward
    {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function lp_token() external view returns (ICurveStableSwap);
    function deposit(uint256 amount, address receiver, bool _claim_rewards) external;
    function withdraw(uint256 amount, bool _claim_rewards) external;
    function claim_rewards(address addr) external;
    function working_supply() external view returns (uint256);
    function working_balances(address _user) external view returns (uint256);
    function claimable_tokens(address _user) external view returns (uint256);
    function claimable_reward(address _user, address _token) external view returns (uint256);
    function claimed_reward(address _user, address _token) external view returns (uint256);
    function reward_tokens(uint256 index) external view returns (address);
    function deposit_reward_token(address _token, uint256 amount) external;
    function reward_count() external view returns (uint256);
    function reward_data(address token) external view returns (Reward memory);
    
    /** Permission works only on sidechains */
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface ICurveGaugeManagerProxy
{
    function deploy_gauge(address _pool) external returns (address);
    function add_reward(address _gauge, address _reward_token, address _distributor) external;
    function set_reward_distributor(address _gauge, address _reward_token, address _distributor) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/IERC20Full.sol";

interface ICurvePool
{
    function coins(uint256 index) external view returns (IERC20Full);
    function balances(uint256 index) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] memory minAmounts) external returns (uint256[2] memory receivedAmounts);
    function remove_liquidity(uint256 amount, uint256[3] memory minAmounts) external returns (uint256[3] memory receivedAmounts);
    function remove_liquidity(uint256 amount, uint256[4] memory minAmounts) external returns (uint256[4] memory receivedAmounts);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./ICurvePool.sol";

interface ICurveStableSwap is IERC20Full, ICurvePool
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract DeployedTestStablecoin is ERC20, ERC20Permit {
    uint8 immutable _decimals;
    bool immutable _hasPermit;

    bool public constant isFakeStablecoin = true;

    constructor(uint8 __decimals, bool __hasPermit)
        ERC20(
            __decimals == 6 ? "Test 6 Decimals" : "Test 18 Decimals",
            __decimals == 6 ? "Test6" : "Test18"
        )
        ERC20Permit(__decimals == 6 ? "Test 6 Decimals" : "Test 18 Decimals")
    {
        assert(__decimals == 6 || __decimals == 18);
        _decimals = __decimals;
        _hasPermit = __hasPermit;
        _mint(msg.sender, __decimals == 6 ? 10**19 : 10**31);
    }

    function decimals() public view virtual override returns (uint8)
    {
        return _decimals;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        assert(_hasPermit);
        ERC20Permit.permit(owner, spender, value, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";

interface IREBacking is IUpgradeableBase
{
    event PropertyAcquisitionCost(uint256 newAmount);

    function isREBacking() external view returns (bool);
    function propertyAcquisitionCost() external view returns (uint256);
    
    function setPropertyAcquisitionCost(uint256 amount) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Curve/ICurveGauge.sol";
import "./Base/ISelfStakingERC20.sol";
import "./Base/IUpgradeableBase.sol";

interface IREClaimer is IUpgradeableBase
{
    function isREClaimer() external view returns (bool);
    function claim(ICurveGauge[] memory gauges, ISelfStakingERC20[] memory tokens) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREUSD.sol";
import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./IRECustodian.sol";

interface IRECurveBlargitrage is IUpgradeableBase
{
    error MissingDesiredToken();
    
    function isRECurveBlargitrage() external view returns (bool);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function desiredToken() external view returns (IERC20);
    function REUSD() external view returns (IREUSD);
    function custodian() external view returns (IRECustodian);

    function balance() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveGauge.sol";
import "./Base/ICanMint.sol";

interface IRECurveMintedRewards is IUpgradeableBase
{
    event RewardRate(uint256 perDay, uint256 perDayPerUnit);

    error NotRewardManager();

    function isRECurveMintedRewards() external view returns (bool);
    function gauge() external view returns (ICurveGauge);
    function lastRewardTimestamp() external view returns (uint256);
    function rewardToken() external view returns (ICanMint);
    function perDay() external view returns (uint256);
    function perDayPerUnit() external view returns (uint256);
    function isRewardManager(address user) external view returns (bool);
    
    function sendRewards(uint256 units) external;
    function sendAndSetRewardRate(uint256 perDay, uint256 perDayPerUnit, uint256 units) external;
    function setRewardManager(address manager, bool enabled) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Base/IERC20Full.sol";
import "./Base/IREUSDMinterBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./Curve/ICurvePool.sol";
import "./Curve/ICurveGauge.sol";

interface IRECurveZapper is IREUSDMinterBase, IUpgradeableBase
{
    error UnsupportedToken();
    error ZeroAmount();
    error PoolMismatch();
    error TooManyPoolCoins();
    error TooManyBasePoolCoins();
    error MissingREUSD();
    error BasePoolWithREUSD();

    function isRECurveZapper() external view returns (bool);
    function basePoolCoinCount() external view returns (uint256);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function basePoolToken() external view returns (IERC20);
    function gauge() external view returns (ICurveGauge);

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD) external;
    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function unzap(IERC20 token, uint256 tokenAmount) external;    

    struct TokenAmount
    {        
        IERC20 token;
        uint256 amount;
    }
    struct PermitData
    {
        IERC20Full token;
        uint32 deadline;
        uint8 v;
        uint256 permitAmount;
        bytes32 r;
        bytes32 s;
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts) external;
    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";

interface IRECustodian is IUpgradeableBase
{
    function isRECustodian() external view returns (bool);
    function amountRecovered(address token) external view returns (uint256);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IERC20Full.sol";
import "./Base/IUpgradeableBase.sol";

interface IREStablecoins is IUpgradeableBase
{
    struct StablecoinConfig
    {
        IERC20Full token;
        uint8 decimals;
        bool hasPermit;
    }
    struct StablecoinConfigWithName
    {
        StablecoinConfig config;
        string name;
        string symbol;
    }

    error TokenNotSupported();
    error TokenMisconfigured();
    error StablecoinAlreadyExists();
    error StablecoinDoesNotExist();
    error StablecoinBakedIn();

    function isREStablecoins() external view returns (bool);
    function supportedStablecoins() external view returns (StablecoinConfigWithName[] memory);
    function getStablecoinConfig(address token) external view returns (StablecoinConfig memory config);

    function addStablecoin(address stablecoin, bool hasPermit) external;
    function removeStablecoin(address stablecoin) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeRERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUP is IBridgeRERC20, ICanMint, IUpgradeableBase
{
    function isREUP() external view returns (bool);
    function url() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeRERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUSD is IBridgeRERC20, ICanMint, IUpgradeableBase
{
    function isREUSD() external view returns (bool);
    function url() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Base/IREUSDMinterBase.sol";

interface IREUSDMinter is IUpgradeableBase, IREUSDMinterBase
{
    function isREUSDMinter() external view returns (bool);

    function mint(IERC20 paymentToken, uint256 reusdAmount) external;
    function mintPermit(IERC20Full paymentToken, uint256 reusdAmount, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function mintTo(IERC20 paymentToken, address recipient, uint256 reusdAmount) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveGauge.sol";
import "./Base/ISelfStakingERC20.sol";

interface IREWardSplitter is IUpgradeableBase
{
    error GaugeNotExcluded();
    
    function isREWardSplitter() external view returns (bool);
    function splitRewards(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges) external view returns (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts);

    function approve(IERC20 rewardToken, address[] memory targets) external;
    function addReward(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges) external;
    function addRewardPermit(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeSelfStakingERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREYIELD is IBridgeSelfStakingERC20, ICanMint, IUpgradeableBase
{
    function isREYIELD() external view returns (bool);
    function url() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/*
    Adapted from openzeppelin's `Address.sol`    
*/

library CheapSafeCall
{
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        It does not revert on failures
     */
    function callOptionalBooleanNoThrow(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        return success && (result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool)));        
    }
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        Returns false if 'false' was returned
        Returns false if the call failed and nothing was returned
        Bubbles up the revert reason if the call reverted
     */
    function callOptionalBoolean(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success) 
        {
            return result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool));
        }
        else 
        {
            if (result.length == 0) { return false; }
            assembly 
            {
                let resultSize := mload(result)
                revert(add(32, result), resultSize)
            }
        }        
    }
    /**
        Makes a call
        Returns true if the call succeded, and it was to a contract address (ignores any return value)        
        Returns false if the call succeeded and nothing was returned
        Bubbles up the revert reason if the call reverted
     */
    function call(address addr, bytes memory data)
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success)
        {
            return result.length > 0 || addr.code.length > 0;
        }
        if (result.length == 0) { return false; }
        assembly 
        {
            let resultSize := mload(result)
            revert(add(32, result), resultSize)
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CheapSafeERC20.sol";
import "./CheapSafeCall.sol";

using CheapSafeERC20 for IERC20;

/**
    An attempt to more safely work with all the weird quirks of Curve

    Sometimes, Curve contracts have X interface.  Sometimes, they don't.  Sometimes, they return a value.  Sometimes, they don't.
 */

library CheapSafeCurve
{
    error AddCurveLiquidityFailed();
    error NoPoolTokensMinted();
    error RemoveCurveLiquidityOneCoinCallFailed();
    error InsufficientTokensReceived();

    /**
        We call "add_liquidity", ignoring any return value or lack thereof
        Instead, we check to see if any pool tokens were minted.  If not, we'll revert because we know the call failed.
        On success, we'll return however many new pool tokens were minted for us.
     */
    function safeAddLiquidityCore(address pool, IERC20 poolToken, bytes memory data)
        private
        returns (uint256 poolTokenAmount)
    {
        uint256 balance = poolToken.balanceOf(address(this));
        if (!CheapSafeCall.call(pool, data)) { revert AddCurveLiquidityFailed(); }
        uint256 newBalance = poolToken.balanceOf(address(this));
        if (newBalance <= balance) { revert NoPoolTokensMinted(); }
        unchecked { return newBalance - balance; }
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[2] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", amounts, minMintAmount));
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[3] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[3],uint256)", amounts, minMintAmount));
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[4] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[4],uint256)", amounts, minMintAmount));
    }

    /**
        We'll call "remove_liquidity_one_coin", ignoring any return value or lack thereof
        Instead, we'll check to see how many tokens we received.  If not enough, then we revert.
        On success, we'll return however many tokens we received
     */
    function safeRemoveLiquidityOneCoin(address pool, IERC20 token, uint256 tokenIndex, uint256 amount, uint256 minReceived, address receiver)
        internal
        returns (uint256 amountReceived)
    {
        uint256 balance = token.balanceOf(address(this));
        if (!CheapSafeCall.call(pool, abi.encodeWithSignature("remove_liquidity_one_coin(uint256,int128,uint256)", amount, int128(int256(tokenIndex)), 0))) { revert RemoveCurveLiquidityOneCoinCallFailed(); }
        uint256 newBalance = token.balanceOf(address(this));
        if (newBalance < balance + minReceived) { revert InsufficientTokensReceived(); }
        unchecked { amountReceived = newBalance - balance; }
        if (receiver != address(this))
        {
            token.safeTransfer(receiver, amountReceived);
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CheapSafeCall.sol";

/*
    Adapted from openzeppelin's `SafeERC20.sol`

    But implemented using custom errors, and with different 'safeApprove' functionality
*/

library CheapSafeERC20 
{
    error TransferFailed();
    error ApprovalFailed();

    /**
        Calls 'transfer' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransfer(IERC20 token, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transfer.selector, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'transferFrom' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'approve' on an ERC20
        If it fails, it attempts to approve for 0 amount then to the requested amount
        If that also fails, it will revert with either the ERC20's error message or 'ApprovalFailed'
     */
    function safeApprove(IERC20 token, address spender, uint256 value)
        internal
    {
        if (!CheapSafeCall.callOptionalBooleanNoThrow(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
        {
            if (value == 0 ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, 0)) ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
            {
                revert ApprovalFailed(); 
            }
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Arbitrary 'role' functionality to assign roles to users
 */
library Roles
{
    error MissingRole();

    bytes32 private constant RoleSlotPrefix = keccak256("SLOT:Roles:role");

    function hasRole(bytes32 role, address user)
        internal
        view
        returns (bool)
    {
        return StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(RoleSlotPrefix, role, user))).value;
    }

    function setRole(bytes32 role, address user, bool enable)
        internal
    {
        StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(RoleSlotPrefix, role, user))).value = enable;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/**
    Allows for conversions between bytes32 and string

    Not necessarily super efficient, but only used in constructors or view functions

    Used in our upgradeable ERC20 implementation so that strings can be stored as immutable bytes32
 */
library StringHelper
{
    error StringTooLong();

    /**
        Converts the string to bytes32
        Throws if 33 bytes or longer
        The string may not be well-formed and there may be dirty bytes after the null terminator, if there even IS a null terminator
    */
    function toBytes32(string memory str)
        internal
        pure
        returns (bytes32 val)
    {
        val = 0;
        if (bytes(str).length > 0) 
        { 
            if (bytes(str).length >= 33) { revert StringTooLong(); }
            assembly 
            {
                val := mload(add(str, 32))
            }
        }
    }

    /**
        Converts bytes32 back to string
        The string length is minimized; only characters before the first null byte are returned
     */
    function toString(bytes32 val)
        internal
        pure
        returns (string memory)
    {
        unchecked
        {
            uint256 x = 0;
            while (x < 32)
            {
                if (val[x] == 0) { break; }
                ++x;
            }
            bytes memory mem = new bytes(x);
            while (x-- > 0)
            {
                mem[x] = val[x];            
            }
            return string(mem);
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IREBacking.sol";

/**
    An informational contract, not used for anything other than
    display purposes at the moment
 */
contract REBacking is UpgradeableBase(1), IREBacking
{
    uint256 public propertyAcquisitionCost;

    //------------------ end of storage

    bool public constant isREBacking = true;

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREBacking(newImplementation).isREBacking());
    }
    
    function setPropertyAcquisitionCost(uint256 amount)
        public
        onlyOwner
    {
        propertyAcquisitionCost = amount;
        emit PropertyAcquisitionCost(amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREClaimer.sol";
import "./IREYIELD.sol";
import "./Base/UpgradeableBase.sol";

/**
    A convenience contract for users to be able to collect all the rewards
    from our ecosystem in a single transaction
 */
contract REClaimer is UpgradeableBase(1), IREClaimer
{
    bool public constant isREClaimer = true;

    function claim(ICurveGauge[] memory gauges, ISelfStakingERC20[] memory tokens)
        public
    {
        unchecked
        {
            for (uint256 x = gauges.length; x > 0;)
            {
                gauges[--x].claim_rewards(msg.sender);
            }
            for (uint256 x = tokens.length; x > 0;)
            {
                tokens[--x].claimFor(msg.sender);
            }
        }
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREClaimer(newImplementation).isREClaimer());
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREUSD.sol";
import "./Base/UpgradeableBase.sol";
import "./IRECustodian.sol";
import "./Library/CheapSafeCurve.sol";
import "./IRECurveBlargitrage.sol";

/**
    An arbitrage contract

    If a curve pool is made of REUSD + 3CRV, for example...

    If there's more 3CRV than REUSD, then calling "balance" will mint REUSD
    and exchange it for 3CRV to bring the pool back into balance.

    More specifically, it actually extracts one of the underlying tokens
    like USDC from 3CRV after doing the balancing.  USDC goes to custodian.

    However, if there's more REUSD than 3CRV, there's nothing this
    contract can do.  We could manually add funds from the custodian if
    it seems appropriate.

    A call to "balance" can be the last step in zap/unzap in the 
    RECurveZapper contract.
 */
contract RECurveBlargitrage is UpgradeableBase(2), IRECurveBlargitrage
{
    uint256 public totalAmount;
    
    //------------------ end of storage

    uint256 constant MinImbalance = 1000 ether;
    bool public constant isRECurveBlargitrage = true;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREUSD immutable public REUSD;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveStableSwap immutable public pool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurvePool immutable public basePool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable reusdIndex;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable basePoolIndex;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECustodian immutable public custodian;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable public desiredToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable desiredTokenIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _reusd, ICurveStableSwap _pool, ICurvePool _basePool, IERC20 _desiredToken)
    {
        assert(_reusd.isREUSD() && _custodian.isRECustodian());
        custodian = _custodian;
        REUSD = _reusd;
        pool = _pool;
        basePool = _basePool;
        desiredToken = _desiredToken;
        reusdIndex = _pool.coins(0) == _reusd ? 0 : 1;
        basePoolIndex = 1 - reusdIndex;
        assert(reusdIndex == 0 || _pool.coins(1) == _reusd);
        basePoolToken = _pool.coins(basePoolIndex);
        
        uint256 _index = 3;
        if (_basePool.coins(0) == _desiredToken) { _index = 0; }
        else if (_basePool.coins(1) == _desiredToken) { _index = 1; }
        else if (_basePool.coins(2) == _desiredToken) { _index = 2; }
        desiredTokenIndex = _index;
        // ^-- workaround for https://github.com/sc-forks/solidity-coverage/issues/751
        //desiredTokenIndex = _basePool.coins(0) == _desiredToken ? 0 : _basePool.coins(1) == _desiredToken ? 1 : _basePool.coins(2) == _desiredToken ? 2 : 3;

        assert(desiredTokenIndex < 3 || _basePool.coins(desiredTokenIndex) == _desiredToken);
    }

    function initialize()
        public
    {
        REUSD.approve(address(pool), type(uint256).max);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveBlargitrage(newImplementation).isRECurveBlargitrage());
    }

    function balance()
        public
        virtual
    {
        uint256 baseDollarValue = pool.balances(basePoolIndex) * basePool.get_virtual_price() / 1 ether;
        uint256 reusdBalance = pool.balances(reusdIndex);
        if (reusdBalance >= baseDollarValue) { return; }
        uint256 imbalance = baseDollarValue - reusdBalance;
        if (imbalance < MinImbalance) { return; }
        REUSD.mint(address(this), imbalance);
        uint256 received = CheapSafeCurve.safeAddLiquidity(address(pool), pool, reusdIndex == 0 ? [imbalance, 0] : [0, imbalance], 0);
        uint256[2] memory amounts = pool.remove_liquidity(received, [uint256(0), 0]);
        REUSD.transfer(address(0), amounts[reusdIndex]);
        totalAmount += CheapSafeCurve.safeRemoveLiquidityOneCoin(address(basePool), desiredToken, desiredTokenIndex, amounts[basePoolIndex], 0, address(custodian));
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECurveMintedRewards.sol";
import "./Base/UpgradeableBase.sol";
import "./Library/Roles.sol";

/**
    This works with curve gauges

    We set a reward rate

    Occasionally, we call "sendRewards", which calculates how much to add to the curve gauge

    The gauge will distribute rewards for the following 7 days

    A "unit" can be anything, for example "$1000 of curve liquidity".  Rewards will be the sum
    of a flat rate, plus the rate multiplied by units.
 */
contract RECurveMintedRewards is UpgradeableBase(1), IRECurveMintedRewards
{
    bytes32 constant RewardManagerRole = keccak256("ROLE:RECurveMintedRewards:rewardManager");

    uint256 public perDay;
    uint256 public perDayPerUnit;
    uint256 public lastRewardTimestamp;

    //------------------ end of storage

    bool public constant isRECurveMintedRewards = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICanMint public immutable rewardToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveGauge public immutable gauge;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICanMint _rewardToken, ICurveGauge _gauge)
    {
        rewardToken = _rewardToken;
        gauge = _gauge;
    }

    function initialize()
        public
    {
        rewardToken.approve(address(gauge), type(uint256).max);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveMintedRewards(newImplementation).isRECurveMintedRewards());
    }
    
    function isRewardManager(address user) public view returns (bool) { return Roles.hasRole(RewardManagerRole, user); }

    modifier onlyRewardManager()
    {
        if (!isRewardManager(msg.sender) && msg.sender != owner()) { revert NotRewardManager(); }
        _;
    }

    function sendRewards(uint256 units)
        public
        onlyRewardManager
    {
        uint256 interval = block.timestamp - lastRewardTimestamp;
        if (interval == 0) { return; }
        lastRewardTimestamp = block.timestamp;
        
        uint256 amount = interval * (units * perDayPerUnit + perDay) / 86400;
        if (amount > 0)
        {
            rewardToken.mint(address(this), amount);
            gauge.deposit_reward_token(address(rewardToken), amount);
        }
    }

    function sendAndSetRewardRate(uint256 _perDay, uint256 _perDayPerUnit, uint256 units)
        public
        onlyRewardManager
    {
        sendRewards(units);
        perDay = _perDay;
        perDayPerUnit = _perDayPerUnit;
        emit RewardRate(_perDay, _perDayPerUnit);
    }
    
    function setRewardManager(address manager, bool enabled) 
        public
        onlyOwner
    {
        Roles.setRole(RewardManagerRole, manager, enabled);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IRECurveZapper.sol";
import "./Library/CheapSafeERC20.sol";
import "./Base/REUSDMinterBase.sol";
import "./Library/CheapSafeCurve.sol";
import "./IRECurveBlargitrage.sol";

using CheapSafeERC20 for IERC20;
using CheapSafeERC20 for ICurveStableSwap;

contract RECurveZapper is REUSDMinterBase, UpgradeableBase(2), IRECurveZapper
{
    /*
        addWrapper(unwrappedToken, supportedButWrappedToken, wrapSig, unwrapSig);
        ^-- potential approach to future strategy for pools dealing with wrapped assets
    */
    bool public constant isRECurveZapper = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveStableSwap public immutable pool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurvePool public immutable basePool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable basePoolToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveGauge public immutable gauge;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable basePoolCoinCount;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECurveBlargitrage immutable blargitrage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICurveGauge _gauge, IREStablecoins _stablecoins, IRECurveBlargitrage _blargitrage)
        REUSDMinterBase(_blargitrage.custodian(), _blargitrage.REUSD(), _stablecoins)
    {
        /*
            Stableswap pools:
                Always have 2 coins
                One of them must be REUSD
                The pool token is always the pool itself
            Other pools:
                Have at least 2 coins
                We support 2-4 coins
                Must not include REUSD
        */
        assert(_blargitrage.isRECurveBlargitrage());
        
        gauge = _gauge;
        blargitrage = _blargitrage;
        basePool = _blargitrage.basePool();
        pool = gauge.lp_token();
        poolCoin0 = pool.coins(0); 
        poolCoin1 = pool.coins(1);
        basePoolToken = address(poolCoin0) == address(REUSD) ? poolCoin1 : poolCoin0;

        if (pool != _blargitrage.pool()) { revert PoolMismatch(); }

        basePoolCoin0 = basePool.coins(0);
        basePoolCoin1 = basePool.coins(1);
        uint256 count = 2;
        try basePool.coins(2) returns (IERC20Full coin2)
        {
            basePoolCoin2 = coin2;
            count = 3;
            try basePool.coins(3) returns (IERC20Full coin3)
            {
                basePoolCoin3 = coin3;
                count = 4;
            }
            catch {}
        }
        catch {}
        basePoolCoinCount = count;

        try pool.coins(2) returns (IERC20Full) { revert TooManyPoolCoins(); } catch {}
        try basePool.coins(4) returns (IERC20Full) { revert TooManyBasePoolCoins(); } catch {}        

        if (address(poolCoin0) != address(REUSD) && address(poolCoin1) != address(REUSD)) { revert MissingREUSD(); }
        if (basePoolCoin0 == REUSD || basePoolCoin1 == REUSD || basePoolCoin2 == REUSD || basePoolCoin3 == REUSD) { revert BasePoolWithREUSD(); }
    }

    function initialize()
        public
    {
        poolCoin0.safeApprove(address(pool), type(uint256).max);
        poolCoin1.safeApprove(address(pool), type(uint256).max);
        basePoolCoin0.safeApprove(address(basePool), type(uint256).max);
        basePoolCoin1.safeApprove(address(basePool), type(uint256).max);
        if (address(basePoolCoin2) != address(0)) { basePoolCoin2.safeApprove(address(basePool), type(uint256).max); }
        if (address(basePoolCoin3) != address(0)) { basePoolCoin3.safeApprove(address(basePool), type(uint256).max); }
        basePoolToken.safeApprove(address(basePool), type(uint256).max);
        pool.safeApprove(address(gauge), type(uint256).max);
    }
    
    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveZapper(newImplementation).isRECurveZapper());
    }

    function isBasePoolToken(IERC20 token) 
        private
        view
        returns (bool)
    {
        return address(token) != address(0) &&
            (
                token == basePoolCoin0 ||
                token == basePoolCoin1 ||
                token == basePoolCoin2 ||
                token == basePoolCoin3
            );
    }

    function addBasePoolLiquidity(IERC20 token, uint256 amount)
        private
        returns (uint256)
    {
        uint256 amount0 = token == basePoolCoin0 ? amount : 0;
        uint256 amount1 = token == basePoolCoin1 ? amount : 0;
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1], 0);
        }
        uint256 amount2 = token == basePoolCoin2 ? amount : 0;
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2], 0);
        }
        uint256 amount3 = token == basePoolCoin3 ? amount : 0;
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2, amount3], 0);
    }

    function addBasePoolLiquidity(uint256[] memory amounts)
        private
        returns (uint256)
    {
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1]], 0);
        }
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2]], 0);
        }
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2], amounts[3]], 0);
    }

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD)
        public
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }

        if (mintREUSD && token != REUSD) 
        {
            /*
                Convert whatever the user is staking into REUSD, and
                then continue onwards as if the user is staking REUSD
            */
            tokenAmount = getREUSDAmount(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            mintREUSDCore(msg.sender, token, address(this), tokenAmount);
            token = REUSD;
        }
        else 
        {
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }
        
        if (isBasePoolToken(token)) 
        {
            /*
                Add liquidity to the base pool, and then continue onwards
                as if the user is staking the base pool token
            */
            tokenAmount = addBasePoolLiquidity(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = address(poolCoin0) == address(REUSD) ? poolCoin1 : poolCoin0;
        }
        if (token == poolCoin0 || token == poolCoin1) 
        {
            /*
                Add liquidity to the pool, and then continue onwards as if
                the user is staking the pool token
            */
            tokenAmount = CheapSafeCurve.safeAddLiquidity(address(pool), pool, [
                token == poolCoin0 ? tokenAmount : 0,
                token == poolCoin1 ? tokenAmount : 0
                ], 0);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = pool;
        }
        else if (token != pool) { revert UnsupportedToken(); }

        gauge.deposit(tokenAmount, msg.sender, true);

        blargitrage.balance();
    }

    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        token.permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        zap(token, tokenAmount, mintREUSD);
    }

    function unzap(IERC20 token, uint256 tokenAmount)
        public
    {
        unzapCore(token, tokenAmount);
        blargitrage.balance();
    }

    function unzapCore(IERC20 token, uint256 tokenAmount)
        private
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }       

        gauge.transferFrom(msg.sender, address(this), tokenAmount);
        gauge.claim_rewards(msg.sender);
        gauge.withdraw(tokenAmount, false);

        /*
            Now, we have pool tokens (1 gauge token yields 1 pool token)
        */

        if (token == pool)
        {
            // If they want the pool token, just send it and we're done
            token.safeTransfer(msg.sender, tokenAmount);
            return;
        }
        if (token == poolCoin0 || token == poolCoin1)
        {
            // If they want either REUSD or the base pool token, then
            // remove liquidity to them directly and we're done
            CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), token, token == poolCoin0 ? 0 : 1, tokenAmount, 1, msg.sender);
            return;
        }
        
        if (!isBasePoolToken(token)) { revert UnsupportedToken(); }

        // They want one of the base pool coins, so remove pool
        // liquidity to get base pool tokens, then remove base pool
        // liquidity directly to the them
        tokenAmount = CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), basePoolToken, poolCoin0 == basePoolToken ? 0 : 1, tokenAmount, 1, address(this));
        
        CheapSafeCurve.safeRemoveLiquidityOneCoin(
            address(basePool), 
            token, 
            token == basePoolCoin0 ? 0 : token == basePoolCoin1 ? 1 : token == basePoolCoin2 ? 2 : 3,
            tokenAmount, 
            1, 
            msg.sender);
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts)
        public
    {
        /*
            0-3 = basePoolCoin[0-3]
            4 = reusd
            5 = base pool token
            6 = pool token

            We'll loop through the parameters, adding whatever we find
            into the amounts[] array.

            Then we add base pool liquidity as required

            Then we add pool liquidity as required
        */
        uint256[] memory amounts = new uint256[](7);
        for (uint256 x = mints.length; x > 0;)
        {
            IERC20 token = mints[--x].token;
            uint256 amount = getREUSDAmount(token, mints[x].amount);
            mintREUSDCore(msg.sender, token, address(this), amount);
            amounts[4] += amount;
        }
        for (uint256 x = tokenAmounts.length; x > 0;)
        {
            IERC20 token = tokenAmounts[--x].token;
            uint256 amount = tokenAmounts[x].amount;
            if (token == basePoolCoin0)
            {
                amounts[0] += amount;
            }
            else if (token == basePoolCoin1)
            {
                amounts[1] += amount;
            }
            else if (token == basePoolCoin2)
            {
                amounts[2] += amount;
            }
            else if (token == basePoolCoin3)
            {
                amounts[3] += amount;
            }
            else if (token == REUSD)
            {
                amounts[4] += amount;
            }
            else if (token == basePoolToken)
            {
                amounts[5] += amount;
            }
            else if (token == pool)
            {
                amounts[6] += amount;
            }
            else 
            {
                revert UnsupportedToken();
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        if (amounts[0] > 0 || amounts[1] > 0 || amounts[2] > 0 || amounts[3] > 0)
        {
            amounts[5] += addBasePoolLiquidity(amounts);
        }
        if (amounts[4] > 0 || amounts[5] > 0)
        {
            amounts[6] += CheapSafeCurve.safeAddLiquidity(address(pool), pool, poolCoin0 == REUSD ? [amounts[4], amounts[5]] : [amounts[5], amounts[4]], 0);            
        }
        if (amounts[6] == 0)
        {
            revert ZeroAmount();
        }

        gauge.deposit(amounts[6], msg.sender, true);

        blargitrage.balance();
    }

    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits)
        public
    {
        for (uint256 x = permits.length; x > 0;)
        {
            --x;
            permits[x].token.permit(msg.sender, address(this), permits[x].permitAmount, permits[x].deadline, permits[x].v, permits[x].r, permits[x].s);
        }
        multiZap(mints, tokenAmounts);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECustodian.sol";
import "./Base/UpgradeableBase.sol";

/**
    Any funds that will end up purchasing real estate should land here
 */
contract RECustodian is UpgradeableBase(1), IRECustodian
{
    bool public constant isRECustodian = true;
    mapping (address => uint256) public amountRecovered;
    
    receive() external payable {}

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECustodian(newImplementation).isRECustodian());
    }

    function beforeRecoverNative()
        internal
        override
    {
        amountRecovered[address(0)] += address(this).balance;
    }
    function beforeRecoverERC20(IERC20 token)
        internal
        override
    {
        amountRecovered[address(token)] += token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREStablecoins.sol";
import "./Base/UpgradeableBase.sol";

/**
    Supported stablecoins configuration

    The "baked in" stablecoins are a gas optimization.  We support up to 3 of them, or could increase this (but we probably won't!)

    All stablecoins MUST have 6 or 18 decimals.  If this ever changes, we need to change code in other contracts which rely on this behavior

    For each stablecoin, we track the # of decimals and whether or not it supports "permit"

    External contracts probably just call "getStablecoinConfig".  Everything else is front-end helpers or admin, pretty much.
 */
contract REStablecoins is UpgradeableBase(1), IREStablecoins
{
    address[] private moreStablecoinAddresses;
    mapping (address => StablecoinConfig) private moreStablecoins;

    //------------------ end of storage
    
    bool public constant isREStablecoins = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin1; // Because `struct StablecoinConfig` can't be stored as immutable
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(StablecoinConfig memory _stablecoin1, StablecoinConfig memory _stablecoin2, StablecoinConfig memory _stablecoin3)
    {
        stablecoin1 = toUint256(_stablecoin1);
        stablecoin2 = toUint256(_stablecoin2);
        stablecoin3 = toUint256(_stablecoin3);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREStablecoins(newImplementation).isREStablecoins());
    }

    function supportedStablecoins()
        public
        view
        returns (StablecoinConfigWithName[] memory stablecoins)
    {
        unchecked
        {
            uint256 builtInCount = 0;
            if (stablecoin1 != 0) { ++builtInCount; }
            if (stablecoin2 != 0) { ++builtInCount; }
            if (stablecoin3 != 0) { ++builtInCount; }
            stablecoins = new StablecoinConfigWithName[](builtInCount + moreStablecoinAddresses.length);
            uint256 at = 0;
            if (stablecoin1 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin1)); }
            if (stablecoin2 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin2)); }
            if (stablecoin3 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin3)); }
            for (uint256 x = moreStablecoinAddresses.length; x > 0;) 
            {
                stablecoins[at++] = toStablecoinConfigWithName(moreStablecoins[moreStablecoinAddresses[--x]]);
            }
        }
    }

    function toUint256(StablecoinConfig memory stablecoin)
        private
        view
        returns (uint256)
    {        
        unchecked
        {
            if (address(stablecoin.token) == address(0)) { return 0; }
            if (stablecoin.decimals != 6 && stablecoin.decimals != 18) { revert TokenNotSupported(); }
            if (stablecoin.decimals != stablecoin.token.decimals()) { revert TokenMisconfigured(); }
            if (stablecoin.hasPermit) { stablecoin.token.DOMAIN_SEPARATOR(); }
            return uint256(uint160(address(stablecoin.token))) | (uint256(stablecoin.decimals) << 160) | (stablecoin.hasPermit ? 1 << 168 : 0);
        }
    }

    function toStablecoinConfig(uint256 data)
        private
        pure
        returns (StablecoinConfig memory config)
    {
        unchecked
        {
            config.token = IERC20Full(address(uint160(data)));
            config.decimals = uint8(data >> 160);
            config.hasPermit = data >> 168 != 0;
        }
    }

    function toStablecoinConfigWithName(StablecoinConfig memory config)
        private
        view
        returns (StablecoinConfigWithName memory configWithName)
    {
        return StablecoinConfigWithName({
            config: config,
            name: config.token.name(),
            symbol: config.token.symbol()
        });
    }

    function getStablecoinConfig(address token)
        public
        view
        returns (StablecoinConfig memory config)
    {
        unchecked
        {
            if (token == address(0)) { revert TokenNotSupported(); }
            if (token == address(uint160(stablecoin1))) { return toStablecoinConfig(stablecoin1); }
            if (token == address(uint160(stablecoin2))) { return toStablecoinConfig(stablecoin2); }
            if (token == address(uint160(stablecoin3))) { return toStablecoinConfig(stablecoin3); }
            config = moreStablecoins[token];
            if (address(config.token) == address(0)) { revert TokenNotSupported(); }            
        }
    }

    function addStablecoin(address stablecoin, bool hasPermit)
        public
        onlyOwner
    {
        if (stablecoin == address(uint160(stablecoin1)) ||
            stablecoin == address(uint160(stablecoin2)) ||
            stablecoin == address(uint160(stablecoin3)) ||
            address(moreStablecoins[stablecoin].token) != address(0))
        {
            revert StablecoinAlreadyExists();
        }
        if (hasPermit) { IERC20Full(stablecoin).DOMAIN_SEPARATOR(); }
        uint8 decimals = IERC20Full(stablecoin).decimals();
        if (decimals != 6 && decimals != 18) { revert TokenNotSupported(); }
        moreStablecoinAddresses.push(stablecoin);
        moreStablecoins[stablecoin] = StablecoinConfig({
            token: IERC20Full(stablecoin),
            decimals: decimals,
            hasPermit: hasPermit
        });
    }

    function removeStablecoin(address stablecoin)
        public
        onlyOwner
    {
        if (stablecoin == address(uint160(stablecoin1)) ||
            stablecoin == address(uint160(stablecoin2)) ||
            stablecoin == address(uint160(stablecoin3)))
        {
            revert StablecoinBakedIn();
        }
        if (address(moreStablecoins[stablecoin].token) == address(0)) { revert StablecoinDoesNotExist(); }
        delete moreStablecoins[stablecoin];
        for (uint256 x = moreStablecoinAddresses.length - 1; ; --x) 
        {
            if (moreStablecoinAddresses[x] == stablecoin) 
            {
                moreStablecoinAddresses[x] = moreStablecoinAddresses[moreStablecoinAddresses.length - 1];
                moreStablecoinAddresses.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeRERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUP.sol";

/**
    The mysterious REUP token :)
 */
contract REUP is BridgeRERC20, UpgradeableBase(2), IREUP
{
    bool public constant isREUP = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        RERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUP(newImplementation).isREUP());
        BridgeRERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeRERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUSD.sol";

/** REUSD = Real Estate USD, our stablecoin */
contract REUSD is BridgeRERC20, UpgradeableBase(2), IREUSD
{
    bool public constant isREUSD = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        RERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSD(newImplementation).isREUSD());
        BridgeRERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IREUSDMinter.sol";
import "./Base/REUSDMinterBase.sol";

/**
    Lets people directly mint REUSD
 */
contract REUSDMinter is REUSDMinterBase, UpgradeableBase(2), IREUSDMinter
{
    bool public constant isREUSDMinter = true;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
        REUSDMinterBase(_custodian, _REUSD, _stablecoins)
    {
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSDMinter(newImplementation).isREUSDMinter());
    }

    function mint(IERC20 paymentToken, uint256 reusdAmount)
        public
    {
        mintREUSDCore(msg.sender, paymentToken, msg.sender, reusdAmount);
    }

    function mintPermit(IERC20Full paymentToken, uint256 reusdAmount, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(paymentToken).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        mintREUSDCore(msg.sender, paymentToken, msg.sender, reusdAmount);
    }

    function mintTo(IERC20 paymentToken, address recipient, uint256 reusdAmount)
        public
    {
        mintREUSDCore(msg.sender, paymentToken, recipient, reusdAmount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREWardSplitter.sol";
import "./Base/ISelfStakingERC20.sol";
import "./Base/UpgradeableBase.sol";

/**
    When we dump USDC rewards into the system, it needs to be split
    between REYIELD holders.  But we don't want people to have to
    repeatedly claim REYIELD from the curve gauge in order to not
    miss out on rewards.

    So, this will split the USDC proportionally

    Curve gauges distribute rewards over 1 week, so we match that.

    Wild fluctuations in curve liquidity may result in either
    curve or REYIELD being slightly more profitable to participate
    in, but it should be minor, and average itself out.  If it's
    genuinely a problem, we can mitigate it by adding rewards
    more frequently
 */
contract REWardSplitter is UpgradeableBase(1), IREWardSplitter
{
    bool public constant isREWardSplitter = true;

    function approve(IERC20 rewardToken, address[] memory targets)
        public
        onlyOwner
    {
        for (uint256 x = targets.length; x > 0;)
        {
            rewardToken.approve(targets[--x], type(uint256).max);
        }
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREWardSplitter(newImplementation).isREWardSplitter());
    }

    function splitRewards(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges)
        public
        view 
        returns (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts)
    {
        /*
            Goal:  Split REYIELD rewards between REYIELD holders and the gauge

            Total effective staked = totalStakingSupply + balanceOf(gauges)

            Quirk:  We want to calculate how much REYIELD is in a gauge which
            is eligible for staking.  This is the amount being distributed by
            the gauge, including funds waiting for users to claim via
            claim_rewards, plus the amount yet to be distributed over the next
            week.  We're using balanceOf(gauge) to get that number.  However,
            if someone simply transfers REYIELD to the gauge (ie, without
            calling deposit_reward_token), then the gauge will not distribute
            those tokens and our reward estimation is forevermore increased
            (although there are ways to mitigate).  ...But, let's just say
            "that's okay", and call it a feature "how to donate your REYIELD
            to boost curve rewards for everyone else".  No problem.
        */
        uint256 totalEffectiveSupply = selfStakingERC20.totalStakingSupply();
        gaugeAmounts = new uint256[](gauges.length);
        selfStakingERC20Amount = amount;
        for (uint256 x = gauges.length; x > 0;)
        {
            ICurveGauge gauge = gauges[--x];
            if (!selfStakingERC20.isExcluded(address(gauge))) { revert GaugeNotExcluded(); }
            uint256 gaugeAmount = selfStakingERC20.balanceOf(address(gauge));
            gaugeAmounts[x] = gaugeAmount;
            totalEffectiveSupply += gaugeAmount;            
        }
        if (totalEffectiveSupply != 0)
        {
            for (uint256 x = gauges.length; x > 0;)
            {
                uint256 gaugeAmount = amount * gaugeAmounts[--x] / totalEffectiveSupply;
                gaugeAmounts[x] = gaugeAmount;
                selfStakingERC20Amount -= gaugeAmount;
            }
        }
    }

    function addReward(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges)
        public
        onlyOwner
    {
        (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts) = splitRewards(amount, selfStakingERC20, gauges);
        IERC20 rewardToken = selfStakingERC20.rewardToken();
        rewardToken.transferFrom(msg.sender, address(this), amount);
        if (selfStakingERC20Amount > 0)
        {
            selfStakingERC20.addReward(selfStakingERC20Amount, block.timestamp, block.timestamp + 60 * 60 * 24 * 7); 
        }
        for (uint256 x = gauges.length; x > 0;)
        {
            uint256 gaugeAmount = gaugeAmounts[--x];
            if (gaugeAmount > 0)
            {
                gauges[x].deposit_reward_token(address(rewardToken), gaugeAmount);
            }
        }
    }

    function addRewardPermit(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(address(selfStakingERC20.rewardToken())).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        addReward(amount, selfStakingERC20, gauges);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeSelfStakingERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREYIELD.sol";

/** REYIELD = Real Estate Yields ... rental income or other income may be distributed to holders */
contract REYIELD is BridgeSelfStakingERC20, UpgradeableBase(2), IREYIELD
{
    bool public constant isREYIELD = true;
    string public constant url = "https://reup.cash";
    
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        SelfStakingERC20(_rewardToken, _name, _symbol, 18)
    {
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREYIELD(newImplementation).isREYIELD());
        BridgeSelfStakingERC20.checkUpgrade(newImplementation);
    }

    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount) 
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/BridgeRERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestBridgeRERC20 is BridgeRERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() 
        RERC20("Test Token", "TST", 18) 
    {        
    }

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }
    
    function checkUpgradeBase(address newImplementation) internal override view {}
    function getMinterOwner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/BridgeSelfStakingERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestBridgeSelfStakingERC20 is BridgeSelfStakingERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken) 
        SelfStakingERC20(_rewardToken, "Test Token", "TST", 18)
    {        
    }

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view {}
    function getMinterOwner() internal override view returns (address) { return owner(); }
    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/CheapSafeERC20.sol";

contract TestCheapSafeERC20
{
    function safeTransfer(IERC20 token, address to, uint256 value)
        public
    {
        CheapSafeERC20.safeTransfer(token, to, value);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value)
        public
    {
        CheapSafeERC20.safeTransferFrom(token, from, to, value);
    }

    function safeApprove(IERC20 token, address spender, uint256 value)
        public
    {
        CheapSafeERC20.safeApprove(token, spender, value);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Curve/ICurveGauge.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestDummyGauge is ERC20("test", "TST"), ERC20Permit("test"), ICurveGauge
{
    ICurveStableSwap public lp_token;
    address public claimRewardsAddress;

    constructor(ICurveStableSwap _pool)
    {
        lp_token = _pool;
    }

    function deposit(uint256 amount, address receiver, bool _claim_rewards) external 
    {
        lp_token.transferFrom(msg.sender, address(this), amount);
        _mint(receiver, amount);
        if (_claim_rewards) { claim_rewards(msg.sender); }
    }
    function withdraw(uint256 amount, bool _claim_rewards) external
    {
        if (_claim_rewards) { claim_rewards(msg.sender); }
        _burn(msg.sender, amount);
        lp_token.transfer(msg.sender, amount);
    }
    function claim_rewards(address addr) public { claimRewardsAddress = addr; }
    function working_supply() external view returns (uint256) {}
    function working_balances(address _user) external view returns (uint256) {}
    function claimable_tokens(address _user) external view returns (uint256) {}
    function claimed_reward(address _user, address _token) external view returns (uint256) {}
    function claimable_reward(address _user, address _token) external view returns (uint256) {}
    function reward_tokens(uint256 index) external view returns (address) {}
    function deposit_reward_token(address _token, uint256 amount) external
    {
        IERC20Full(_token).transferFrom(msg.sender, address(this), amount);
    }
    function reward_count() external view returns (uint256) {}
    function reward_data(address token) external view returns (Reward memory) {}
    function add_reward(address _reward_token, address _distributor) external {}
    function set_reward_distributor(address _reward_token, address _distributor) external {}

    function version() external view returns (string memory) {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Curve/ICurveStableSwap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestDummyStableswap is ERC20("test", "TST"), ERC20Permit("test"), ICurveStableSwap
{
    IERC20Full immutable coin0;
    IERC20Full immutable coin1;
    uint256 public get_virtual_price = 1 ether;

    uint256 public removeLiquidityAmount;
    uint256 public removeLiquidityMinAmounts0;
    uint256 public removeLiquidityMinAmounts1;
    uint256 public removeLiquidityMinAmounts2;
    uint256 public removeLiquidityMinAmounts3;
    uint256 nextAddLiquidityMintAmount;
    uint256 public addLiquidityAmounts0;
    uint256 public addLiquidityAmounts1;
    uint256 public addLiquidityMinAmount;
    bool public addLiquidityCalled;
    uint256 nextRemoveLiquidityOneCoinReceived;
    uint256 public removeLiquidityOneCoinAmount;
    uint256 public removeLiquidityOneCoinMinReceived;
    bool addLiquidityTransfer;
    bool skipRemoveLiquidityBurn;

    mapping (uint256 => uint256) _balances;

    constructor(IERC20Full _coin0, IERC20Full _coin1)
    {
        coin0 = _coin0;
        coin1 = _coin1;
    }

    function mint(address to, uint256 amount) public { _mint(to, amount); }

    function coins(uint256 index) public view returns (IERC20Full)
    {
        if (index == 0) { return coin0; }
        if (index == 1) { return coin1; }
        revert();
    }
    function balances(uint256 index) public view returns (uint256) { return _balances[index]; }

    function setBalance(uint256 index, uint256 balance) public { _balances[index] = balance; }
    function setVirtualPrice(uint256 newPrice) public { get_virtual_price = newPrice; }
    function setNextAddLiquidityMintAmount(uint256 amount) public { nextAddLiquidityMintAmount = amount; }
    function setNextRemoveLiquidityOneCoinReceived(uint256 amount) public { nextRemoveLiquidityOneCoinReceived = amount; }

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256) {}

    function version() external view returns (string memory) {}

    function remove_liquidity(uint256 amount, uint256[2] memory minAmounts) external returns (uint256[2] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
    }
    function remove_liquidity(uint256 amount, uint256[3] memory minAmounts) external returns (uint256[3] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        removeLiquidityMinAmounts2 = minAmounts[2];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
        receivedAmounts[2] = 345;
    }
    function remove_liquidity(uint256 amount, uint256[4] memory minAmounts) external returns (uint256[4] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        removeLiquidityMinAmounts2 = minAmounts[2];
        removeLiquidityMinAmounts3 = minAmounts[3];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
        receivedAmounts[2] = 345;
        receivedAmounts[3] = 456;
    }
    function setAddLiquidityTransfer(bool transfer) public { addLiquidityTransfer = transfer; }
    function add_liquidity(uint256[2] memory amounts, uint256 minMintAmount) external
    {
        _mint(msg.sender, nextAddLiquidityMintAmount);
        if (addLiquidityTransfer)
        {
            coin0.transferFrom(msg.sender, address(this), amounts[0]);
            coin1.transferFrom(msg.sender, address(this), amounts[1]);
        }
        addLiquidityAmounts0 = amounts[0];
        addLiquidityAmounts1 = amounts[1];
        addLiquidityMinAmount = minMintAmount;
        addLiquidityCalled = true;
    }
    function setSkipLiquidityBurn(bool skip) public { skipRemoveLiquidityBurn = skip; }
    function remove_liquidity_one_coin(uint256 amount, int128 tokenIndex, uint256 minReceived) external
    {
        if (!skipRemoveLiquidityBurn)
        {
            _burn(msg.sender, amount);
        }
        coins(uint128(tokenIndex)).transfer(msg.sender, nextRemoveLiquidityOneCoinReceived);
        removeLiquidityOneCoinAmount = amount;
        removeLiquidityOneCoinMinReceived = minReceived;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestERC20 is ERC20("test", "TST"), ERC20Permit("test")
{
    uint8 _decimals = 18;
    constructor() 
    {
        _mint(msg.sender, 1000000000 ether);
    }
    function decimals() public view virtual override returns (uint8) { return _decimals; }
    function setDecimals(uint8 __decimals) public { _decimals = __decimals; }
    function mint(address user, uint256 amount) public { _mint(user, amount); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestGrumpyERC20 is ERC20("test", "TST"), ERC20Permit("test")
{
    function approve(address spender, uint256 amount) public override returns (bool)
    {
        require(amount == 0 || allowance(msg.sender, spender) == 0, "Set to 0 first");
        return super.approve(spender, amount);
    }

    function transfer(address, uint256) public override pure returns (bool) 
    {
        require(false, "Blarg");
        return false;
    }

    function transferFrom(address, address, uint256) public override pure returns (bool) 
    {
        require(false, "Blarg");
        return false;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/Minter.sol";
import "../Base/Owned.sol";

contract TestMinter is Minter, Owned
{
    function test()
        public
        onlyMinter
    {}

    function getMinterOwner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/Owned.sol";

contract TestOwned is Owned
{
    function test()
        public
        onlyOwner
    {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REBacking.sol";

contract TestREBacking is REBacking
{    
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/ISelfStakingERC20.sol";
import "../Base/RERC20.sol";

contract TestREClaimer_SelfStakingERC20 is RERC20("Test", "TST", 18), ISelfStakingERC20
{
    address public claimForAddress;

    function isSelfStakingERC20() external view returns (bool) {}
    function rewardToken() external view returns (IERC20) {}
    function isExcluded(address addr) external view returns (bool) {}
    function totalStakingSupply() external view returns (uint256) {}
    function rewardData() external view returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute) {}
    function pendingReward(address user) external view returns (uint256) {}
    function isDelegatedClaimer(address user) external view returns (bool) {}
    function isRewardManager(address user) external view returns (bool) {}

    function claim() external {}
    
    function claimFor(address user) external { claimForAddress = user; }

    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external {}
    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {}
    function setExcluded(address user, bool excluded) external {}
    function setDelegatedClaimer(address user, bool enable) external {}
    function setRewardManager(address user, bool enable) external {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REClaimer.sol";

contract TestREClaimer is REClaimer
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/RECoverable.sol";
import "../Base/Owned.sol";

contract TestRECoverable is RECoverable, Owned
{
    error Nope();

    bool allow = true;

    function setAllow(bool _allow) 
        public 
    { 
        allow = _allow; 
    }

    function beforeRecoverNative() 
        internal
        override
    {
        if (!allow) { revert Nope(); }
        super.beforeRecoverNative();
    }

    function beforeRecoverERC20(IERC20 token) 
        internal
        override
    {
        if (!allow) { revert Nope(); }
        super.beforeRecoverERC20(token);
    }

    receive() external payable {}

    function getRECoverableOwner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveBlargitrage.sol";

contract TestRECurveBlargitrage is RECurveBlargitrage
{    
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _reusd, ICurveStableSwap _pool, ICurvePool _basePool, IERC20 _desiredToken)
        RECurveBlargitrage(_custodian, _reusd, _pool, _basePool, _desiredToken)
    {        
    }

    function getREUSDIndex() external view returns (uint256) { return reusdIndex; }
    function getBasePoolIndex() external view returns (uint256) { return basePoolIndex; }
    function getBasePoolToken() external view returns (IERC20) { return basePoolToken; }

    bool skipBalance;
    uint256 public balanceCallCount;
    function setSkipBalance(bool skip) public { skipBalance = skip; }

    function balance() public override
    {
        ++balanceCallCount;
        if (!skipBalance) { super.balance(); }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveMintedRewards.sol";

contract TestRECurveMintedRewards is RECurveMintedRewards
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICanMint _rewardToken, ICurveGauge _gauge)
        RECurveMintedRewards(_rewardToken, _gauge)
    {        
    }

    function sendRewardsTwice(uint256 units)
        public
    {
        sendRewards(units);
        sendRewards(units);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveZapper.sol";

contract TestRECurveZapper is RECurveZapper
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICurveGauge _gauge, IREStablecoins _stablecoins, IRECurveBlargitrage _blargitrage)
        RECurveZapper(_gauge, _stablecoins, _blargitrage)
    {    
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECustodian.sol";

contract TestRECustodian is RECustodian
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/RERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestRERC20 is RERC20("Test Token", "TST", 18), UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view {}
    function mintDirect(address user, uint256 amount) public { mintCore(user, amount); }
    function burnDirect(address user, uint256 amount) public { burnCore(user, amount); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REStablecoins.sol";

contract TestREStablecoins is REStablecoins
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(StablecoinConfig memory _stablecoin1, StablecoinConfig memory _stablecoin2, StablecoinConfig memory _stablecoin3)
        REStablecoins(_stablecoin1, _stablecoin2, _stablecoin3)
    {        
    }

    function getStablecoin1() external view returns (StablecoinConfig memory) { return supportedStablecoins()[0].config; }
    function getStablecoin2() external view returns (StablecoinConfig memory) { return supportedStablecoins()[1].config; }
    function getStablecoin3() external view returns (StablecoinConfig memory) { return supportedStablecoins()[2].config; }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUP.sol";

contract TestREUP is REUP
{    
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        REUP(_name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUSD.sol";

contract TestREUSD is REUSD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        REUSD(_name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUSDMinter.sol";

contract TestREUSDMinter is REUSDMinter
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
        REUSDMinter(_custodian, _REUSD, _stablecoins)
    {        
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REWardSplitter.sol";

contract TestREWardSplitter is REWardSplitter
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REYIELD.sol";

contract TestREYIELD is REYIELD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        REYIELD(_rewardToken, _name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/SelfStakingERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestSelfStakingERC20 is SelfStakingERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken)
        SelfStakingERC20(_rewardToken, "Test Token", "TST", 18)
    {}

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function burn(uint256 amount) public 
    {
        burnCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view { SelfStakingERC20.checkUpgrade(newImplementation); }
    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function _checkUpgrade(address newImplementation) public view { checkUpgrade(newImplementation); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/StringHelper.sol";

contract TestStringHelper
{
    function getBytes(string memory str) public pure returns (bytes32) { return StringHelper.toBytes32(str); }
    function getString(bytes32 data) public pure returns (string memory) { return StringHelper.toString(data); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/UUPSUpgradeable.sol";

contract TestUUPSUpgradeable is UUPSUpgradeable
{
    error Nope();
    error Exploded();

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable self = address(this);
    
    bool canUpgrade;
    function setCanUpgrade(bool can) public { canUpgrade = can; }
    function beforeUpgrade(address) internal override view { if (!canUpgrade) { revert Nope(); } }

    function yayInitializer(bool explode)
        public
    {
        if (explode) 
        { 
            canUpgrade = true; // just to make it not a view function
            revert Exploded(); 
        }
    }

    function _() external {} // 0xb7ba4583
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/UUPSUpgradeableVersion.sol";

contract TestUUPSUpgradeableVersion is UUPSUpgradeableVersion(123)
{
    uint256 nextContractVersion;
    function contractVersion() public override view returns (uint256) { return nextContractVersion == 0 ? super.contractVersion() : nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    error Nope();
    
    bool canUpgrade;
    function setCanUpgrade(bool can) public { canUpgrade = can; }
    function beforeUpgradeVersion(address) internal override view { if (!canUpgrade) { revert Nope(); } }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IUniswapV2Router
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}