// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

contract InitializedProxy {
    address public immutable logic;
    constructor(
        address _logic
        // ,
        // bytes memory _initializationCalldata
    ) {
        logic = _logic;
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) =
            _logic.delegatecall(abi.encodeWithSignature( "initialize(address,address,uint256,uint256,uint256,uint256,string,string)", 0x4F08853c3a785198cbAd232980F5aca5b9681a27,0x0000000000000000000000000000000000000000,0,1000,1000,10,"Token Vault","TVK"));
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    // ======== Fallback =========

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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

    // ======== Receive =========

    receive() external payable {} // solhint-disable-line no-empty-blocks
}