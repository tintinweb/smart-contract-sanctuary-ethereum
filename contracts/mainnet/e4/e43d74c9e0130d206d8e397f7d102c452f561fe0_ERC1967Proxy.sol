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