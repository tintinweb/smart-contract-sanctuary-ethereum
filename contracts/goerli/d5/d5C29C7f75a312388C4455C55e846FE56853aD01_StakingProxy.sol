/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/StakingProxy.sol


pragma solidity >=0.7.0 <0.9.0;

contract StakingProxy {
    
    bytes32 private constant master = keccak256("com.saitama.proxy.master");
    bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.proxy.owner");
   
    constructor(address _imp, address _owner) {
        setImplementation(_imp);
        setProxyOwner(_owner);
    }


    function setProxyOwner(address newProxyOwner) public  {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function setImplementation(address _newImplementation) public {
        // require(proxyOwner() == msg.sender, "INVALID_ADMIN");
        bytes32 position = master;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function implementation() public view returns (address impl) {
        bytes32 position = master;
        assembly {
            impl := sload(position)
        }
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