// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '../interfaces/IUpgradable.sol';

contract Proxy {
    error InvalidImplementation();
    error SetupFailed();
    error EtherNotAccepted();
    error NotOwner();
    error AlreadyInitialized();

    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    constructor() {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, caller())
        }
    }

    function init(
        address implementationAddress,
        address newOwner,
        bytes memory params
    ) external {
        address owner;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner := sload(_OWNER_SLOT)
        }
        if (msg.sender != owner) revert NotOwner();
        if (implementation() != address(0)) revert AlreadyInitialized();
        if (IUpgradable(implementationAddress).contractId() != contractId()) revert InvalidImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementationAddress)
            sstore(_OWNER_SLOT, newOwner)
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementationAddress.delegatecall(
            //0x9ded06df is the setup selector.
            abi.encodeWithSelector(0x9ded06df, params)
        );
        if (!success) revert SetupFailed();
    }

    // solhint-disable-next-line no-empty-blocks
    function contractId() internal pure virtual returns (bytes32) {}

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata data) public {}

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address implementaion_ = implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable virtual {
        revert EtherNotAccepted();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Proxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Proxy.sol";

contract SquidRouterProxy is Proxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }
}