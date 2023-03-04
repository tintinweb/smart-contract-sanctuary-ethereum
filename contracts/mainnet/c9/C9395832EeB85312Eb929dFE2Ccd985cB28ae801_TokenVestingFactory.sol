// SPDX-License-Identifier: MIT

pragma solidity > 0.7.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function copy(address a) internal returns(address){

    /*
    https://gist.github.com/holiman/069de8d056a531575d2b786df3345665
    this is dup, not proxy

    Assembly of the code that we want to use as init-code in the new contract, 
    along with stack values:
	                # bottom [ STACK ] top
	 PUSH1 00       # [ 0 ]
	 DUP1           # [ 0, 0 ]
	 PUSH20         
	 <address>      # [0,0, address] 
	 DUP1		# [0,0, address ,address]
	 EXTCODESIZE    # [0,0, address, size ]
	 DUP1           # [0,0, address, size, size]
	 SWAP4          # [ size, 0, address, size, 0]
	 DUP1           # [ size, 0, address ,size, 0,0]
	 SWAP2          # [ size, 0, address, 0, 0, size]
	 SWAP3          # [ size, 0, size, 0, 0, address]
	 EXTCODECOPY    # [ size, 0]
	 RETURN 
    
    The code above weighs in at 33 bytes, which is _just_ above fitting into a uint. 
    So a modified version is used, where the initial PUSH1 00 is replaced by `PC`. 
    This is one byte smaller, and also a bit cheaper Wbase instead of Wverylow. It only costs 2 gas.

	 PC             # [ 0 ]
	 DUP1           # [ 0, 0 ]
	 PUSH20         
	 <address>      # [0,0, address] 
	 DUP1		# [0,0, address ,address]
	 EXTCODESIZE    # [0,0, address, size ]
	 DUP1           # [0,0, address, size, size]
	 SWAP4          # [ size, 0, address, size, 0]
	 DUP1           # [ size, 0, address ,size, 0,0]
	 SWAP2          # [ size, 0, address, 0, 0, size]
	 SWAP3          # [ size, 0, size, 0, 0, address]
	 EXTCODECOPY    # [ size, 0]
	 RETURN 

	The opcodes are:
	58 80 73 <address> 80 3b 80 93 80 91 92 3c F3
	We get <address> in there by OR:ing the upshifted address into the 0-filled space. 
	  5880730000000000000000000000000000000000000000803b80938091923cF3 
	 +000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx000000000000000000
	 -----------------------------------------------------------------
	  588073xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00000803b80938091923cF3

	This is simply stored at memory position 0, and create is invoked. 

	*/
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 , mul(a,0x1000000000000000000)))
            retval := create(0, 0, 32)
            switch extcodesize(retval) case 0 { revert(0, 0) }
        }
        return retval;
    }  

    function copy2(address a, uint256 salt) internal returns (address) {
        /* this is dup, not proxy */
        address retval;
        assembly {
        mstore(0x0, or(0x5880730000000000000000000000000000000000000000803b80938091923cF3, mul(a, 0x1000000000000000000)))
        retval := create2(0, 0, 0x20, salt)
        switch extcodesize(retval) case 0 { revert(0, 0) }
        }
        return retval;
    }  

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Clones.sol";

interface ITokenVesting {
    function initialize(address token, address owner) external;
}

contract TokenVestingFactory {
    address public implementation;
    event LockBoxCreated(address indexed owner, address lockBox);

    constructor(address implementation_) {
        require(implementation_ != address(0),"must have implementation address");
        implementation = implementation_;
    }
    /*
     * @dev createLockBox create a new lockbox(proxied) contract
     * @param token token address to vest/lock
     * @param owner of the new lockBox
     */
    function createLockBox(address token, address owner) public returns (address lockBoxAddress) {
        address cloned = Clones.clone(implementation);
        owner = owner == address(0) ? msg.sender : owner;
        ITokenVesting(cloned).initialize(token, owner);
        emit LockBoxCreated(owner, cloned);
        return cloned;
    }
}