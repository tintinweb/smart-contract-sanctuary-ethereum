/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
// File: contracts/ICreate2Factory.sol
pragma solidity ^0.8.10;
/// @notice Integrated, used to deploy contracts using Create2, only the owner can call.
contract IDestinyDeployer{
    event Deployed(address addr, bytes32 salt);
    /// @notice Calculate create2 deploy contract address.
    function getAddress(bytes memory bytecode, string memory salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), keccak256(abi.encodePacked(salt)), keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }
    
    /**
    * @custom:title Deploy the contract
    * @notice Check the event log Deployed which contains the address of the deployed Contract.
    * The address in the log should equal the address computed from above.
    */
    function deploy(bytes memory bytecode, bytes32 salt) internal returns(bool){
        address addr;
        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                salt // Salt from function arguments
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
        return true;
    }
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The above verification passed.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/