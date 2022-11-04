// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract VerifyingPaymasterProxy {

    /* This is the keccak-256 hash of "biconomy.paymaster.proxy.implementation" subtracted by 1, and is validated in the constructor */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x396cb660e6e8daa7b387f1f198b46e21cbeb4eb8ce888649d091e80e86c4c314;

    event Received(uint indexed value, address indexed sender, bytes data);

    constructor(address _implementation) {
         assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("biconomy.paymaster.proxy.implementation")) - 1));
         assembly {
             sstore(_IMPLEMENTATION_SLOT,_implementation) 
         }
    }

    fallback() external payable {
        address target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            target := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }

}