/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

// SECTION BitWise 

library BitDegas {

    /// Efficient retrieve
    function get_element(uint8 bit_array, uint8 index) public pure returns(uint8 value) {
        return ((bit_array & index) > 0) ? 1 : 0;
    }


    function TrueOrFalse(uint8 boolean_array, uint8 bool_index) public pure returns(bool bool_result) {
        return (boolean_array & bool_index) > 0;
    }

    function setTrue(uint8 boolean_array, uint8 bool_index) public pure returns(uint8 resulting_array){
        return boolean_array | (((boolean_array & bool_index) > 0) ? 1 : 0);
    }

    function setFalse(uint8 boolean_array, uint8 bool_index) public pure returns(uint8 resulting_array){
         return boolean_array & (((boolean_array & bool_index) > 0) ? 1 : 0);
    }

    /// Mathematics

    function addition(uint a, uint b) public pure returns(uint) {
        while(!(b==0)) {
            uint carry = a & b;
            a = a^b;
            b = carry << 1;
        }
        return a;
    }

    function subtraction(uint a, uint b) public pure returns(uint) {
        while(!(b==0)) {
            uint carry = (~a) & b;
            a = a^b;
            b = carry << 1;
        }
        return a;
    }

    function multiply(uint x, uint y) public pure returns (uint) {
        uint reg = 0;
        while (y != 0)
        {
            if (!((y) & uint(1)==0))
            {
                reg += x;
            }
            x <<= 1;
            y >>= 1;
        }
        return reg;
    }


    function division(uint dividend, uint divisor) public pure returns(uint) {
        uint quotient = 0;
        while (dividend >= divisor) {
            dividend -= divisor;
            quotient+=1;
        }

        // Return the value of quotient with the appropriate sign.
        return quotient;
    }
        
}
// !SECTION BitWise