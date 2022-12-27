/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// File: contracts/IStakeFactory.sol



pragma solidity ^0.8.0;

interface IStakeFactory {
    function impl() external view returns(address);
}
// File: contracts/Proxy2.sol


pragma solidity ^0.8.0;


contract Proxy2 {
    
    bytes32 private constant master = keccak256("com.saitama.proxy");
    // bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.proxy.owner");
        bytes32 private constant factory = keccak256("com.saitama.proxy.factory");

    // constructor(address _imp) {
    //     setImplementation(_imp);
    //     // setProxyOwner(_owner);
    // }


    // function setProxyOwner(address newProxyOwner) public  {
    //     bytes32 position = proxyOwnerPosition;
    //     assembly {
    //         sstore(position, newProxyOwner)
    //     }
    // }

    function setFactory(address _factory) public  {
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

    // function proxyOwner() public view returns (address owner) {
    //     bytes32 position = proxyOwnerPosition;
    //     assembly {
    //         owner := sload(position)
    //     }
    // }

    // function setImplementation(address _factory) public {
    //     // require(proxyOwner() == msg.sender, "INVALID_ADMIN");
    //     bytes32 position = master;
    //     address _imp = Factory(getFactory()).imp();
    //     assembly {
    //         sstore(position, _imp)
    //     }
    // }

    function implementation() public view returns (address) {
        // bytes32 position = master;
        // assembly {
        //     impl := sload(position)
        // }
        return IStakeFactory(getFactory()).impl();
    }
    


    fallback() external payable {
        address _impl = implementation();
        // address _impl = Factory(getFactory()).imp();

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