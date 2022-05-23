// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned} from "./ERC1822Versioned.sol";

/* ------------- Diamond Storage ------------- */

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant DIAMOND_STORAGE_ERC1967_UPGRADE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

struct ERC1967UpgradeDS {
    address implementation;
    uint256 version;
}

function ds() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC1967_UPGRADE
    }
}

/* ------------- Errors ------------- */

error InvalidUUID();
error InvalidOwner();
error NotAContract();
error InvalidVersion();

/* ------------- ERC1967 ------------- */

abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        bytes32 uuid = IERC1822Versioned(logic).proxiableUUID();
        uint256 newVersion = IERC1822Versioned(logic).proxiableVersion();

        if (newVersion <= ds().version) revert InvalidVersion();
        if (uuid != DIAMOND_STORAGE_ERC1967_UPGRADE) revert InvalidUUID();

        ds().implementation = logic;

        emit Upgraded(logic);

        if (data.length != 0) _delegateCall(logic, data);

        ds().version = newVersion;
    }

    function _delegateCall(address logic, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = logic.delegatecall(data);

        if (success) return returndata;

        assembly {
            let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)
        }
    }
}

/* ------------- ERC1967Proxy ------------- */

contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        // ownableDS().owner = msg.sender; // @note: should move to __init() and make user responsible?
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        // address implementation = ds().implementation;

        assembly {
            let implementation := sload(DIAMOND_STORAGE_ERC1967_UPGRADE)

            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1822Versioned {
    function proxiableVersion() external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);
}

abstract contract ERC1822Versioned is IERC1822Versioned {
    function proxiableVersion() public view virtual returns (uint256);
}