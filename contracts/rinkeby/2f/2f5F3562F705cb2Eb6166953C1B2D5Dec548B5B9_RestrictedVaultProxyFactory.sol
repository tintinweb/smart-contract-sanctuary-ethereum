// SPDX-License-Identifier: Unlicensed
// solhint-disable no-unused-vars
pragma solidity ^0.8.0;

import "../factory/RestrictedProxyFactory.sol";
import "./RestrictedVaultProxy.sol";

contract RestrictedVaultProxyFactory is RestrictedProxyFactory {
  /**
   * @dev Factory function for creating the factory instance.
   * @param implementation Implementation address for the proxy.
   * @param initdata Initializer call data (unused).
   * @return Newly created proxy address.
   */
  function createProxyInstance (
    address implementation,
    bytes memory initdata
  ) internal override virtual returns (address) {
    return address(new RestrictedVaultProxy(implementation));
  }

  /**
   * @dev Returns the runtime code for the factory instance type.
   * @return Creation code for factory instance type (`type(T).runtimeCode`).
   */
  function proxyRuntimeCode ()
  public override virtual pure returns (bytes memory) {
    return type(RestrictedVaultProxy).runtimeCode;
  }

  /**
   * @dev Returns the creation code for the factory instance type.
   * @return Creation code for factory instance type (`type(T).creationCode`).
   */
  function proxyCreationCode ()
  public override virtual pure returns (bytes memory) {
    return type(RestrictedVaultProxy).creationCode;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice An abstract contract for creating proxies based on a implementation
 * implementation with optional initialization call data. This contract
 * implements the same public interface as the `GnosisSafeProxyFactory`
 * contract from the `gnosis.pm/safe-contracts` module.
 * @dev Extending contracts should emit a `ProxyCreation(proxy, implementation)`
 * event after a proxy has successfully been created.
 */
abstract contract RestrictedProxyFactory is Ownable {
  /**
   * @dev Emitted when a proxy is created.
   * @param proxy Newly created proxy address.
   * @param implementation Implementation address for proxy.
   */
  event ProxyCreation(address proxy, address implementation);

  /**
   * @dev Returns the runtime code for the factory instance type.
   * @return Creation code for factory instance type (`type(T).runtimeCode`).
   */
  function proxyRuntimeCode ()
  public virtual pure returns (bytes memory);

  /**
   * @dev Returns the creation code for the factory instance type.
   * @return Creation code for factory instance type (`type(T).creationCode`).
   */
  function proxyCreationCode ()
  public virtual pure returns (bytes memory);

  /**
   * @dev Factory function for creating the factory instance.
   * @param implementation Implementation address for the proxy.
   * @param initdata Initializer call data.
   * @return Newly created proxy address.
   */
  function createProxyInstance (
    address implementation,
    bytes memory initdata
  ) internal virtual returns (address);

  /**
   * @dev Computes ABI bytecode for factory instance type and implementation.
   * @param implementation The implementation address to compute ABI encoded bytecode.
   * @return ABI encoded packed bytecode.
   */
  function computeProxyBytecode (
    address implementation
  ) public pure virtual returns (bytes memory) {
    bytes memory creationCode = proxyCreationCode();
    return abi.encodePacked(creationCode, uint256(uint160(implementation)));
  }

  /**
   * @dev Computes proxy address for given `implementation`,
   * `initdata`, and `nonce` arguments that would otherwise be
   * used with the `create()` function from this contract.
   * @param implementation Implementation address for the proxy.
   * @param initdata Initializer call data.
   * @param nonce Salt nonce for this proxy.
   * @return Computed proxy address.
   */
  function computeProxyAddress (
    address implementation,
    bytes memory initdata,
    uint256 nonce
  ) internal virtual returns (address) {
    bytes memory bytecode = computeProxyBytecode(implementation);
    bytes32 bytehash = keccak256(bytecode);
    bytes32 salt = keccak256(abi.encodePacked(keccak256(initdata), nonce));

    return address(uint160(uint256(keccak256(abi.encodePacked(
      bytes1(0xff),
      address(this),
      salt,
      bytehash
    )))));
  }

  /**
   * @dev Creates proxy with implementation details given at
   * an `implementation` address.
   * @param implementation Implementation address for the proxy.
   * @param initdata Initializer call data.
   * @return Newly created proxy address.
   */
  function createProxy (
    address implementation,
    bytes memory initdata
  ) public returns (address) {
    require(
      implementation != address(0),
      "address: implementation cannot be 0 address."
    );

    address proxy = createProxyInstance(implementation, initdata);

    require(
      address(proxy) != address(0),
      "createProxy: failed to create proxy instance."
    );

    if (initdata.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        if eq(call(gas(), proxy, 0, add(initdata, 0x20), mload(initdata), 0, 0), 0) {
          revert(0, 0)
        }
      }
    }

    emit ProxyCreation(proxy, implementation);

    return proxy;
  }

  /**
   * @dev Creates proxy with implementation details given at
   * an `implementation` address and a `nonce` value used as input to the
   * salt computation value for `create2()`.
   * @param implementation Implementation address for the proxy.
   * @param initdata Initializer call data.
   * @param nonce Salt nonce for this proxy.
   */
  function createProxyWithNonce (
    address implementation,
    bytes memory initdata,
    uint256 nonce
  ) public returns (address proxy) {
    require(
      implementation != address(0),
      "address: implementation cannot be 0 address."
    );

    bytes memory bytecode = computeProxyBytecode(implementation);
    bytes32 salt = keccak256(abi.encodePacked(keccak256(initdata), nonce));

    // solhint-disable-next-line no-inline-assembly
    assembly {
      proxy := create2(0x0, add(bytecode, 0x20), mload(bytecode), salt)
    }

    require(
      address(proxy) != address(0),
      "create2: failed to create proxy"
    );

    if (initdata.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        if eq(call(gas(), proxy, 0, add(initdata, 0x20), mload(initdata), 0, 0), 0) {
          revert(0, 0)
        }
      }
    }

    emit ProxyCreation(proxy, implementation);
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";

/**
 * @dev TODO
 */
contract RestrictedVaultProxy is Proxy {
  address internal restrictedVaultImplementation;

  /**
   * @dev {RestrictedVaultProxy} contract constructor.
   * @param implementation {RestrictedVault} implementation address.
   */
  constructor (address implementation) {
    restrictedVaultImplementation = implementation;
  }

  function _implementation ()
  override internal view virtual returns (address) {
    return restrictedVaultImplementation;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}