// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; 

contract Proxy {
    bytes32 internal constant IMPLEMENTATION_SLOT =
    0x177667240aeeea7e35eabe3a35e18306f336219e1386f7710a6bf8783f761b24;

    uint256 public systemAssetType; 
    mapping(uint256=> bytes) public assetTypeToAssetInfo; 
    
    function setImplementation(address newImplementation) public {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function implementation() public view returns(address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

        function setSystemAssetType(uint256 assetType) external {
        systemAssetType = assetType;
    }
    
    function setMapping(uint256 assetType, bytes memory assetInfo) external {
    assetTypeToAssetInfo[assetType] = assetInfo;
    }
    

    fallback() external payable {
        address _implementation = implementation();
        require (_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}