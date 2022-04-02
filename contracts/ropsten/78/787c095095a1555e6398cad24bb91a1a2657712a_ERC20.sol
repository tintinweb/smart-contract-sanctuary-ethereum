/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/*
 * Extended ERC20 implementation with optional functions and mint function
 * This implementation is inheritable and usable with other Solidity contracts
 */

contract ERC20 {

    /*
     * Storage layout:
     * 0x1000: total supply
     * 0x1001...: token balances [address + 0x1001]
     * [keccak256(owner + spender)]: token approvals
     */
    
    string private _name;
    string private _symbol;

    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _mint(msg.sender, 10 ** 6 * 1e18);
    }

    /*
     * ------------------
     * METADATA FUNCTIONS
     * ------------------
     */
    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return 18;
    }

    /*
     * --------------
     * VIEW FUNCTIONS
     * --------------
     */
    
    function totalSupply() public view virtual returns (uint256 tokenTotalSupply) {
        assembly {
            tokenTotalSupply := sload(0x1000) // load total supply storage slot
        }
    }

    function balanceOf(address account) public view virtual returns (uint256 tokenBalance) {
        assembly {
            tokenBalance := sload(add(account, 0x1001)) // load storage slot at [account + 0x1001]
        }
    }

    function allowance(address owner, address spender) public view virtual returns (uint256 approved) {
        assembly {
            mstore(0, owner)
            mstore(0x20, spender)
            approved := sload(keccak256(0, 0x40)) // load storage slot at hash of owner and spender
        }
    }

    /*
     * ----------------
     * PUBLIC FUNCTIONS
     * ----------------
     */
    
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        assembly {
            mstore(0, from)
            mstore(0x20, to)
            let approval := keccak256(0, 0x40) // get storage slot of approval
            let approved := sload(approval) // load approved amount

            if eq(lt(approved, amount), 1) { revert(0, 0) } // check spender has enough allowance
            sstore(approval, sub(approved, amount)) // subtract spent from approval
        }
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool success) {
        uint256 newApproved;
        assembly {
            mstore(0, caller())
            mstore(0x20, spender)
            let approval := keccak256(0, 0x40) // get storage slot of approval
            let approved := sload(approval) // load approved amount

            newApproved := add(approved, addedValue) // calculate new allowance
            if iszero(gt(newApproved, approved)) { revert(0, 0) } // check addition overflow
            sstore(approval, newApproved) // write new approval amount to storage
        }
        _approveEvent(msg.sender, spender, newApproved);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool success) {
        uint256 newApproved;
        assembly {
            mstore(0, caller())
            mstore(0x20, spender)
            let approval := keccak256(0, 0x40) // get storage slot of approval
            let approved := sload(approval) // load approved amount

            newApproved := sub(approved, subtractedValue) // calculate new allowance
            if iszero(lt(newApproved, approved)) { revert(0, 0) } // check subtraction underflow
            sstore(approval, newApproved) // write new approval amount to storage
        }
        _approveEvent(msg.sender, spender, newApproved);
        return true;
    }

    /*
     * ------------------
     * INTERNAL FUNCTIONS
     * ------------------
     */
    
    function _transfer(address from, address to, uint256 amount) internal virtual {
        assembly {
            let bal := sload(add(from, 0x1001)) // load balance of sender
            if eq(lt(bal, amount), 1) { revert(0, 0) } // check sender has enough tokens
            sstore(add(from, 0x1001), sub(bal, amount)) // subtract amount from sender balance
            sstore(add(to, 0x1001), add(sload(add(to, 0x1001)), amount)) // add amount to recipient balance
        }
        _transferEvent(from, to, amount);
    }

    function _transferEvent(address from, address to, uint256 amount) internal virtual {
        assembly {
            mstore(0, amount) // store non-indexed approval event parameter
            log3(
                0, 0x20, // non-indexed parameter memory slot
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // transfer event signature
                from, to // indexed event parameters
            )
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        assembly {
            mstore(0, owner)
            mstore(0x20, spender)
            sstore(keccak256(0, 0x40), amount) // write amount at storage slot of approval
        }
        _approveEvent(owner, spender, amount);
    }

    function _approveEvent(address owner, address spender, uint256 amount) internal virtual {
        assembly {
            mstore(0, amount) // store non-indexed approval event parameter
            log3(
                0, 0x20, // non-indexed parameter memory slot
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, // approval event signature
                owner, spender // indexed event parameters
            )
        }
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        assembly {
            let bal := sload(add(account, 0x1001)) // load balance of recipient
            let newBal := add(bal, amount) // calculate new balance
            if iszero(gt(newBal, bal)) { revert(0, 0) } // check addition overflow
            sstore(add(account, 0x1001), newBal) // write balance to storage
            sstore(0x1000, add(sload(0x1000), amount)) // add minted to total supply
        }
        _transferEvent(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        assembly {
            let bal := sload(add(account, 0x1001)) // load balance of recipient
            let newBal := sub(bal, amount) // calculate new balance
            if iszero(lt(newBal, bal)) { revert(0, 0) } // check subtraction underflow
            sstore(add(account, 0x1001), newBal) // write balance to storage
            sstore(0x1000, sub(sload(0x1000), amount)) // subtract burned from total supply
        }
        _transferEvent(account, address(0), amount);
    }

}