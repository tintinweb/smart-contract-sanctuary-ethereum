// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {OwnableUDS, s as ownableDS} from "UDS/auth/OwnableUDS.sol";
import {ERC1967_PROXY_STORAGE_SLOT} from "UDS/proxy/ERC1967Proxy.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_STATIC_PROXY = keccak256("diamond.storage.static.proxy");

struct StaticProxyDS {
    address staticImplementation;
}

function s() pure returns (StaticProxyDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_STATIC_PROXY;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// ------------- errors

error NotAuthorized();
error StaticImplementationNotSet();

/// @title Static Proxy
/// @author phaze (https://github.com/0xPhaze)
/// @notice Allows for continued staticcalls to implementation
///         contract. Disables all non-static calls.
contract StaticProxy is UUPSUpgrade, OwnableUDS {
    bool public constant isStaticProxy = true;

    /* ------------- init ------------- */

    function init(address implementation) public reinitializer {
        if (owner() == address(0)) {
            ownableDS().owner = msg.sender;
        }

        if (implementation != address(0)) s().staticImplementation = implementation;
        if (s().staticImplementation == address(0)) revert StaticImplementationNotSet();
    }

    /* ------------- external ------------- */

    // function upgradeToAndCall(address logic, bytes calldata data) external override {
    //     _authorizeUpgrade();
    //     _upgradeToAndCall(logic, data);
    // }

    function upgradeStaticImplementation(address logic) external {
        _authorizeUpgrade();
        s().staticImplementation = logic;
    }

    /* ------------- upkeep ------------- */

    /// @dev pause all upkeeps
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory data) {}

    /* ------------- fallback ------------- */

    fallback() external {
        if (msg.sender != address(this) && tx.origin != owner()) {
            // open static-call context, loop back in
            // and continue with 'else' control-flow
            assembly {
                calldatacopy(0, 0, calldatasize())

                let success := staticcall(gas(), address(), 0, calldatasize(), 0, 0)

                returndatacopy(0, 0, returndatasize())

                if success {
                    return(0, returndatasize())
                }

                revert(0, returndatasize())
            }
        } else {
            // must be in static-call context now
            // and we can safely perform delegatecalls

            address target = s().staticImplementation;

            assembly {
                calldatacopy(0, 0, calldatasize())

                let success := delegatecall(gas(), target, 0, calldatasize(), 0, 0)

                returndatacopy(0, 0, returndatasize())

                if success {
                    return(0, returndatasize())
                }

                revert(0, returndatasize())
            }
        }
    }

    /* ------------- override ------------- */

    function _authorizeUpgrade() internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Context, Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = _msgSender();
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(_msgSender(), newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (_msgSender() != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Context
/// @notice Overridable context for meta-transactions
/// @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}