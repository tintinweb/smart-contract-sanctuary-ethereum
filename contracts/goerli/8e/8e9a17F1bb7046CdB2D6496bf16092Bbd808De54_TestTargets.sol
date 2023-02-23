/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;

contract TestTargets {

    //bytes32 private initial_target = abi.encode(hex"0000000000000000000000000000000000000000");
    uint16 constant expinc = 8;
    uint16 constant niter = 256/expinc;
    
    constructor() {
       
    }

    function increment_target(bytes32 t, uint16 increment) public pure returns (bytes32) {
        bytes memory result = new bytes(32);

        assembly {
            mstore(add(result, 32), t)
        }

        for (uint8 i = 0; i < 32; i++) {
            if (uint8(result[i]) != 255 && uint8(result[i]) + increment <= 255) {
                result[i] = bytes1( uint8(result[i]) + uint8(increment) );
                break;
            } else if (uint8(result[i]) != 255)  {
                result[i] = hex"ff";
                break;
            }
        }

        bytes32 output;
        assembly {
            output := mload(add(result, 32))
        }
        return output;
    }

    function increaseBytes() public pure returns (bytes32[32*niter] memory) {
       
        bytes32[32*niter] memory outputs;
        outputs[0] = hex"0000000000000000000000000000000000000000";

        for (uint8 i = 1; i < 32*niter; i++) {
           outputs[i] = increment_target(outputs[i-1], expinc);
        }
        
        return outputs;
    }
    
}