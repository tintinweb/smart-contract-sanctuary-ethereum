// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DABridgeProxy {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract.diamond-alpha-bridge:2022");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract.diamond-alpha-bridge:2022");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
     * @dev To get the address of the proxy contract's owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev To get the address of the proxy contract
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev  To get the address of the proxy contract
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(
            _newOwner != address(0),
            "Implementation: Transfer proxy ownership to zero address"
        );
        require(
            _newOwner != proxyOwner(),
            "Implementation: Transfer proxy ownership to current owner"
        );
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    /**
     * @dev To upgrade the logic contract to new one
     */
    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    /**
     * @dev Update the value of implementationPosition slot in storage
     */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Update the value of proxyOwnerPosition slot in storage
     */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function _delegatecall() internal {
        address _impl = implementation();
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
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