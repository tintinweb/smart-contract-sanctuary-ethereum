// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import { ProxyOwnable } from  "./ProxyOwnable.sol";
import { Ownable } from "./Ownable.sol";


contract Proxy is ProxyOwnable, Ownable {
    bytes32 private constant implementationPosition = keccak256("implementation.contract:2022");
    
    event Upgraded(address indexed implementation);

    constructor(address _impl) ProxyOwnable() Ownable() {
        _setImplementation(_impl);
    }

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "Same implementation");
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    function _setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function _delegatecall() internal {
        address _impl = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
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

    fallback() external {
        _delegatecall();
    }

    receive() external payable {
        _delegatecall();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract ProxyOwnable {
    bytes32 private constant proxyOwnerPosition = keccak256("proxy.owner:2022");

    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Proxy: Caller not proxy owner");
        _;
    }

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != proxyOwner(), "Proxy: new owner is the current owner");
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Ownable {
    bytes32 private constant ownerPosition = keccak256("owner.contract:2022");

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner(), "Caller not proxy owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address _owner) {
        bytes32 position = ownerPosition;
        assembly {
            _owner := sload(position)
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner(), "New owner is the current owner");
        emit OwnershipTransferred(owner(), _newOwner);
        _setOwner(_newOwner);
    }

    function _setOwner(address _newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
}