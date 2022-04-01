/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract A {
    A private A_instance = A(address(this));
    uint256 private a = 5;
    
    /**
     * @dev
     * A list of 4 types of function visibilities
     */
    function f_external() external view returns (uint256) {
        return a ** 2;
    }
    
    function f_public() public view returns (uint256) {
        return a ** 2;
    }
    
    function f_internal() internal view returns (uint256) {
        return a ** 2;
    }
    
    function f_private() private view returns (uint256) {
        return a ** 2;
    }
    
    /**
     * @dev
     * 4 different usages of function call
     * [Link]: https://docs.soliditylang.org/en/v0.8.13/control-structures.html#function-calls
     */
    function method1() public returns (uint256) {
        // Use a message call and not directly via jumps.
        return this.f_public() + this.f_external();
    }
    
    function method2() public returns (uint256) {
        // Use a message call and not directly via jumps.
        return A_instance.f_public() + A_instance.f_external();
    }

    function method3() public returns (uint256) {
        // Use jumps inside the EVM
        return A.f_public() + A.f_internal();
    }
    
    function method4() public returns (uint256) {
        // Use jumps inside the EVM
        return f_public() + f_internal() + f_private();
    }
}