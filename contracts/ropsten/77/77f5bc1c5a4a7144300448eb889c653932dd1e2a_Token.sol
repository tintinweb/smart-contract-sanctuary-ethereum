/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract Token {

    constructor() {
        assembly {
            sstore(caller(), 1000000000000000000000000) // add total supply to deployer balance (1 million tokens)
            sstore(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                1000000000000000000000000
            ) // add total supply to supply count
        }
    }

    /*
     * ------------------
     * METADATA FUNCTIONS
     * ------------------
     */

    function name() external pure returns (string memory) {
        return "Token Name";
    }

    function symbol() external pure returns (string memory) {
        return "TOKEN";
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    /*
     * --------------
     * VIEW FUNCTIONS
     * --------------
     */

    function totalSupply() external view returns (uint256 tokenTotalSupply) {
        assembly {
            tokenTotalSupply := sload(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // load last storage slot
        }
    }

    function balanceOf(address account) external view returns (uint256 tokenBalance) {
        assembly {
            tokenBalance := sload(account) // load storage slot at account
        }
    }

    function allowance(address owner, address spender) external view returns (uint256 approved) {
        assembly {
            mstore(0, owner)
            mstore(0x20, spender)
            approved := sload(keccak256(0, 0x40)) // load storage slot at hash of owner and spender
        }
    }

    /*
     * ------------------
     * EXTERNAL FUNCTIONS
     * ------------------
     */
    
    function transfer(address to, uint256 amount) external returns (bool success) {
        assembly {
            let bal := sload(caller()) // load balance of sender
            if eq(lt(bal, amount), 1) { revert(0, 0) } // check sender has enough tokens
            sstore(caller(), sub(bal, amount)) // subtract amount from sender balance
            sstore(to, add(sload(to), amount)) // add amount to recipient balance

            mstore(0, amount) // store non-indexed approval event parameter
            log3(
                0, 0x20, // non-indexed parameter memory slot
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // transfer event signature
                caller(), to // indexed event parameters
            )

            success := true // return true
        }
    }

    function approve(address spender, uint256 amount) external returns (bool success) {
        assembly {
            mstore(0, caller())
            mstore(0x20, spender)
            sstore(keccak256(0, 0x40), amount) // write amount at storage slot of approval

            mstore(0, amount) // store non-indexed approval event parameter
            log3(
                0, 0x20, // non-indexed parameter memory slot
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, // approval event signature
                caller(), spender // indexed event parameters
            )

            success := true // return true
        }
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        assembly {
            mstore(0, from)
            mstore(0x20, to)
            let approval := keccak256(0, 0x40) // get storage slot of approval
            let approved := sload(approval) // load approved amount

            if eq(lt(approved, amount), 1) { revert(0, 0) } // check spender has enough allowance
            sstore(approval, sub(approved, amount)) // subtract spent from approval
            sstore(from, sub(sload(from), amount)) // subtract amount from sender
            sstore(to, add(sload(to), amount)) // add amount to recipient balance

            mstore(0, amount) // store non-indexed approval event parameter
            log3(
                0, 0x20, // non-indexed parameter memory slot
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // transfer event signature
                from, to // indexed event parameters
            )

            success := true // return true
        }
    }

}