//SPDX-License-Identifier: TODO
pragma solidity ^0.8.15;

import "./BlankLogic.sol";
import "./interfaces/ISwimFactory.sol";

interface IUUPSUpgradeable {
  function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

//Our deploy code for proxy (all numbers in hex):
// PUSH20 blankLogicAddress (PUSH20 = 73)
// PUSH32 360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc (PUSH32 = 7F)
// SSTORE (= 55)
// PUSH2 proxyContractSize (= 2FA (762 in base 10)) (PUSH2 = 61)
// DUP1 (= 80)
// PUSH1 deployCodeSize (= 44 (68 in base 10)) (PUSH1 = 60)
// PUSH1 0
// CODECOPY (= 39)
// PUSH1 0
// RETURN (= F3)
// STOP (= 00)

//Deploy code length:
// 33 + 21 + 1 + 3 + 1 + 2 + 2 + 1 + 2 + 1 + 1 = 68 = 0x44
//Deploy opcode:
// 73XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX7F360894a13ba1a3210667
// c828492db98dca3e2076cc3735a920a3ca505d382bbc5561####8060ZZ600039
// 6000F300
//
//Where:
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = blankLogicAddress
// YYYY = proxyContractSize
// ZZ = deployCodeSize

//Hardhat-deploy ERC1967Proxy opcode stripped of aux data:
// 60806040523661001357610011610017565b005b6100115b6100276100226100
// 74565b6100b9565b565b606061004e8383604051806060016040528060278152
// 6020016102fb602791396100dd565b9392505050565b73ffffffffffffffffff
// ffffffffffffffffffffff163b151590565b90565b60006100b47f360894a13b
// a1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5473ffffff
// ffffffffffffffffffffffffffffffffff1690565b905090565b366000803760
// 0080366000845af43d6000803e8080156100d8573d6000f35b3d6000fd5b6060
// 73ffffffffffffffffffffffffffffffffffffffff84163b610188576040517f
// 08c379a000000000000000000000000000000000000000000000000000000000
// 815260206004820152602660248201527f416464726573733a2064656c656761
// 74652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000
// 000000000000000000000000000000000000000000000060648201526084015b
// 60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffff
// ffff16856040516101b0919061028d565b600060405180830381855af4915050
// 3d80600081146101eb576040519150601f19603f3d011682016040523d82523d
// 6000602084013e6101f0565b606091505b509150915061020082828661020a56
// 5b9695505050505050565b6060831561021957508161004e565b825115610229
// 5782518084602001fd5b816040517f08c379a000000000000000000000000000
// 000000000000000000000000000000815260040161017f91906102a9565b6000
// 5b83811015610278578181015183820152602001610260565b83811115610287
// 576000848401525b50505050565b6000825161029f81846020870161025d565b
// 9190910192915050565b60208152600082518060208401526102c88160408501
// 6020870161025d565b601f017fffffffffffffffffffffffffffffffffffffff
// ffffffffffffffffffffffffe016919091016040019291505056
//
//Auxdata (solc fingerprint):
// 416464726573733a206c6f772d6c6576656c2064656c65676174652063616c6c
// 206661696c6564a26469706673582212201e3c9348ed6dd2f363e89451207bd8
// df182bc878dc80d47166301a510c8801e964736f6c634300080a0033
//
//Original Hardhat-deploy opcode =
// stripped opcode + fe + auxdata
// fe is the invalid opcode which (unnecessarily) separates the deployed code
// from the auxdata/fingerprint (unnecessarily, because the last opcode
// is 56 which is a jump, so we can never hit fe anyway)
//
//762 (stripped length) + 1 (invalid opcode) + 96 (fingerprint) = 855 (original code length)

contract SwimFactory is ISwimFactory {
  uint256 private constant PROXY_DEPLOYMENT_CODESIZE = 68;
  uint256 private constant PROXY_STRIPPED_DEPLOYEDCODESIZE = 762;
  uint256 private constant PROXY_TOTAL_CODESIZE =
    PROXY_DEPLOYMENT_CODESIZE + PROXY_STRIPPED_DEPLOYEDCODESIZE;
  uint256 private constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  event ContractCreated(address indexed addr, bool isLogic);

  address public owner;
  uint256 private reentrancyCount;
  address private blankLogicAddress;

  constructor(address _owner) {
    owner = _owner;
    blankLogicAddress = address(new BlankLogic());
  }

  modifier onlyOwnerOrAlreadyDeploying() {
    require(msg.sender == owner || reentrancyCount > 0);
    ++reentrancyCount;
    _;
    --reentrancyCount;
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Not Authorized");
    owner = newOwner;
  }

  function createLogic(bytes memory code, bytes32 salt)
    external
    onlyOwnerOrAlreadyDeploying
    returns (address)
  {
    address logic = create2(code, salt);
    emit ContractCreated(logic, true);
    return logic;
  }

  function createProxy(
    address implementation,
    bytes32 salt,
    bytes memory call
  ) external onlyOwnerOrAlreadyDeploying returns (address) {
    bytes memory code = proxyDeploymentCode();
    address proxy = create2(code, salt);
    try IUUPSUpgradeable(proxy).upgradeToAndCall(implementation, call) {} catch (
      bytes memory lowLevelData
    ) {
      revert ProxyConstructorFailed(lowLevelData);
    }
    emit ContractCreated(proxy, false);
    return proxy;
  }

  function determineLogicAddress(bytes memory code, bytes32 salt) external view returns (address) {
    return determineAddress(code, salt);
  }

  function determineProxyAddress(bytes32 salt) external view returns (address) {
    return determineAddress(proxyDeploymentCode(), salt);
  }

  // -------------------------------- INTERNAL --------------------------------

  function create2(bytes memory code, bytes32 salt) internal returns (address) {
    bytes memory _code = code;
    bytes32 _salt = salt;
    address ct;
    bool failed;
    assembly ("memory-safe")
    {
      ct := create2(0, add(_code, 32), mload(_code), _salt)
      failed := iszero(extcodesize(ct))
    }
    if (failed) revert ContractAlreadyExists(ct);
    return ct;
  }

  function determineAddress(bytes memory code, bytes32 salt) internal view returns (address) {
    return
      address(
        bytes20(
          keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code))) << 96
        )
      );
  }

  function proxyDeploymentCode() internal view returns (bytes memory) {
    // doesn't work because stack too deep... => gotta do it ourselves
    // return bytes.concat(
    //   bytes1(0x73), //PUSH20
    //   bytes20(blankLogicAddress), //sstore val argument
    //   bytes1(0x7f), //PUSH32
    //   IMPLEMENTATION_SLOT, //sstore key argument
    //   bytes1(0x55), //SSTORE
    //   bytes1(0x61), //PUSH2
    //   bytes2(uint16(PROXY_STRIPPED_DEPLOYEDCODESIZE)), //return len argument
    //   bytes1(0x80), //DUP - codecopy len argument
    //   bytes1(0x60), //PUSH1
    //   bytes1(uint8(PROXY_DEPLOYMENT_CODESIZE)), //codecopy ost argument
    //   bytes1(0x60), //PUSH1
    //   bytes1(0),    //codecopy dstOst argument
    //   bytes1(0x39), //CODECOPY
    //   bytes1(0x60), //PUSH1
    //   bytes1(0),    //return ost argument
    //   bytes1(0xf3), //RETURN
    //   bytes1(0x00), //STOP
    //   bytes32(0x60806040523661001357610011610017565b005b6100115b6100276100226100),
    //   bytes32(0x74565b6100b9565b565b606061004e8383604051806060016040528060278152),
    //   bytes32(0x6020016102fb602791396100dd565b9392505050565b73ffffffffffffffffff),
    //   bytes32(0xffffffffffffffffffffff163b151590565b90565b60006100b47f360894a13b),
    //   bytes32(0xa1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5473ffffff),
    //   bytes32(0xffffffffffffffffffffffffffffffffff1690565b905090565b366000803760),
    //   bytes32(0x0080366000845af43d6000803e8080156100d8573d6000f35b3d6000fd5b6060),
    //   bytes32(0x73ffffffffffffffffffffffffffffffffffffffff84163b610188576040517f),
    //   bytes32(0x08c379a000000000000000000000000000000000000000000000000000000000),
    //   bytes32(0x815260206004820152602660248201527f416464726573733a2064656c656761),
    //   bytes32(0x74652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000),
    //   bytes32(0x000000000000000000000000000000000000000000000060648201526084015b),
    //   bytes32(0x60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffff),
    //   bytes32(0xffff16856040516101b0919061028d565b600060405180830381855af4915050),
    //   bytes32(0x3d80600081146101eb576040519150601f19603f3d011682016040523d82523d),
    //   bytes32(0x6000602084013e6101f0565b606091505b509150915061020082828661020a56),
    //   bytes32(0x5b9695505050505050565b6060831561021957508161004e565b825115610229),
    //   bytes32(0x5782518084602001fd5b816040517f08c379a000000000000000000000000000),
    //   bytes32(0x000000000000000000000000000000815260040161017f91906102a9565b6000),
    //   bytes32(0x5b83811015610278578181015183820152602001610260565b83811115610287),
    //   bytes32(0x576000848401525b50505050565b6000825161029f81846020870161025d565b),
    //   bytes32(0x9190910192915050565b60208152600082518060208401526102c88160408501),
    //   bytes32(0x6020870161025d565b601f017fffffffffffffffffffffffffffffffffffffff),
    //   bytes26(0xffffffffffffffffffffffffe016919091016040019291505056)
    // );
    uint256 _PROXY_DEPLOYMENT_CODESIZE = PROXY_DEPLOYMENT_CODESIZE;
    uint256 _PROXY_STRIPPED_DEPLOYEDCODESIZE = PROXY_STRIPPED_DEPLOYEDCODESIZE;
    uint256 _IMPLEMENTATION_SLOT = IMPLEMENTATION_SLOT;
    uint256 _blankLogicAddress = uint256(uint160(blankLogicAddress));
    bytes memory code = new bytes(PROXY_TOTAL_CODESIZE);
    assembly ("memory-safe")
    {
      mstore(add(code, 32), add(add(shl(248, 0x73), shl(88, _blankLogicAddress)), shl(80, 0x7f)))
      mstore(add(code, 54), _IMPLEMENTATION_SLOT)
      mstore(
        add(code, 86),
        add(
          add(
            add(
              add(shl(240, 0x5561), shl(224, _PROXY_STRIPPED_DEPLOYEDCODESIZE)),
              shl(208, 0x8060)
            ),
            shl(200, _PROXY_DEPLOYMENT_CODESIZE)
          ),
          shl(144, 0x6000396000f300)
        )
      )
      mstore(add(code, 100), 0x60806040523661001357610011610017565b005b6100115b6100276100226100)
      mstore(add(code, 132), 0x74565b6100b9565b565b606061004e8383604051806060016040528060278152)
      mstore(add(code, 164), 0x6020016102fb602791396100dd565b9392505050565b73ffffffffffffffffff)
      mstore(add(code, 196), 0xffffffffffffffffffffff163b151590565b90565b60006100b47f360894a13b)
      mstore(add(code, 228), 0xa1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5473ffffff)
      mstore(add(code, 260), 0xffffffffffffffffffffffffffffffffff1690565b905090565b366000803760)
      mstore(add(code, 292), 0x0080366000845af43d6000803e8080156100d8573d6000f35b3d6000fd5b6060)
      mstore(add(code, 324), 0x73ffffffffffffffffffffffffffffffffffffffff84163b610188576040517f)
      mstore(add(code, 356), 0x08c379a000000000000000000000000000000000000000000000000000000000)
      mstore(add(code, 388), 0x815260206004820152602660248201527f416464726573733a2064656c656761)
      mstore(add(code, 420), 0x74652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000)
      mstore(add(code, 452), 0x000000000000000000000000000000000000000000000060648201526084015b)
      mstore(add(code, 484), 0x60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffff)
      mstore(add(code, 516), 0xffff16856040516101b0919061028d565b600060405180830381855af4915050)
      mstore(add(code, 548), 0x3d80600081146101eb576040519150601f19603f3d011682016040523d82523d)
      mstore(add(code, 580), 0x6000602084013e6101f0565b606091505b509150915061020082828661020a56)
      mstore(add(code, 612), 0x5b9695505050505050565b6060831561021957508161004e565b825115610229)
      mstore(add(code, 644), 0x5782518084602001fd5b816040517f08c379a000000000000000000000000000)
      mstore(add(code, 676), 0x000000000000000000000000000000815260040161017f91906102a9565b6000)
      mstore(add(code, 708), 0x5b83811015610278578181015183820152602001610260565b83811115610287)
      mstore(add(code, 740), 0x576000848401525b50505050565b6000825161029f81846020870161025d565b)
      mstore(add(code, 772), 0x9190910192915050565b60208152600082518060208401526102c88160408501)
      mstore(add(code, 804), 0x6020870161025d565b601f017fffffffffffffffffffffffffffffffffffffff)
      mstore(add(code, 836), shl(48, 0xffffffffffffffffffffffffe016919091016040019291505056))
    }
    return code;
  }
}

//SPDX-License-Identifier: TODO
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract BlankLogic is UUPSUpgradeable {
  //the contract will always be upgraded
  function _authorizeUpgrade(address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error ContractAlreadyExists(address contrct);
error ProxyConstructorFailed(bytes lowLevelData);

interface ISwimFactory {
  function createLogic(bytes memory code, bytes32 salt) external returns (address);

  function createProxy(
    address implementation,
    bytes32 salt,
    bytes memory call
  ) external returns (address);

  function determineLogicAddress(bytes memory code, bytes32 salt) external view returns (address);

  function determineProxyAddress(bytes32 salt) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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