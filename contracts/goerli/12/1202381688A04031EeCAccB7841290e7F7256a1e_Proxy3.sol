// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IStakeFactory {
    function impl() external view returns(address);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./interface/IStakeFactory.sol";

contract Proxy3 {
    
        bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.proxy.owner");
        bytes32 private constant factory = keccak256("com.saitama.proxy.factory");

    constructor(address owner) {
        setProxyOwner(owner);

    }

    function setProxyOwner(address newProxyOwner) private  {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function setFactory(address _factory) public  {
        require(msg.sender == proxyOwner(), "ONLY_OWNER_CAN_CHANGE");
        bytes32 position = factory;
        assembly {
            sstore(position, _factory)
        }
    }

    function getFactory() public view returns (address _factory) {
        bytes32 position = factory;
        assembly {
            _factory := sload(position)
        }
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }


    function implementation() public view returns (address) {
        return IStakeFactory(getFactory()).impl();
    }
    


    fallback() external payable {
        address _impl = implementation();

            assembly 
                {
                let ptr := mload(0x40)

                // (1) copy incoming call data
                calldatacopy(ptr, 0, calldatasize())

                // (2) forward call to logic contract
                let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
                let size := returndatasize()

                // (3) retrieve return data
                returndatacopy(ptr, 0, size)

                // (4) forward return data back to caller
                switch result
                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
                }
    }

}