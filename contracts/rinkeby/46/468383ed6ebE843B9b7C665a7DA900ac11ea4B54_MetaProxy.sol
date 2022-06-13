// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaProxy {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract.meta.proxy:2022");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract.meta.proxy:2022");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "MetaProxy: only proxy owner");
        _;
    }

    /**
     * @dev Returns the address of proxy owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Returns the address of implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Upgrade to the new implementation
     */
    function upgradeTo(address impl) public onlyProxyOwner {
        address currentImpl = implementation();
        require(
            currentImpl != impl,
            "MetaProxy: upgrade to current implementation"
        );
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /** 
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        uint256[] memory, /* data */
        address[] memory, /* addrs */
        bytes[] memory, /* signatures */
        bytes32, /* requestType */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public returns (bytes memory) {
        _delegatecall();
    }

    /**
     * @dev Transfer the proxy ownership to the new owner
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(
            newOwner != address(0),
            "MetaProxy: new owner is the zero address"
        );
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        _setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Store the `impl` to the `implementationPosition` slot
     */
    function _setImplementation(address impl) private {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, impl)
        }
    }

    /**
     * @dev Store the `account` to the `proxyOwnerPosition`
     */
    function _setUpgradeabilityOwner(address account) private {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, account)
        }
    }

    function _delegatecall() private {
        address impl = implementation();
        require(
            impl != address(0),
            "MetaProxy: Implementation is zero address"
        );

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    fallback() external payable {
        _delegatecall();
    }

    receive() external payable {}
}