/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// File: contracts/StakingProxy.sol


pragma solidity >=0.7.0 <0.9.0;

contract StakingProxy {
    
    bytes32 private constant master = keccak256("com.saitama.proxy.master");
    bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.proxy.owner");
   
    constructor(address _imp) {
        setImplementation(_imp);
        // setProxyOwner(_owner);
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
    


    // fallback() external payable {
    //     address _impl = implementation();
    //         assembly 
    //             {
    //             let ptr := mload(0x40)

    //             // (1) copy incoming call data
    //             calldatacopy(ptr, 0, calldatasize())

    //             // (2) forward call to logic contract
    //             let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
    //             let size := returndatasize()

    //             // (3) retrieve return data
    //             returndatacopy(ptr, 0, size)

    //             // (4) forward return data back to caller
    //             switch result
    //             case 0 { revert(ptr, size) }
    //             default { return(ptr, size) }
    //             }
    // }

    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}