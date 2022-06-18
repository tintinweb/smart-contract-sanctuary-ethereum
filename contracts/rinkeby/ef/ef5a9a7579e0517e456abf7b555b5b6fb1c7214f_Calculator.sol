/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// ----------------------------------------------------------------------------


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }



    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }


    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }
}



// pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Calculator {
    
    uint public x;
    uint public y;
    uint public percent;
    
    
    constructor()
    {
        x=0;
        y=0;
        percent=0;
    }

    function setX(uint _x)  public{
        x = _x;
    }

    function setY(uint _y) public{
        y = _y;
    }

    function addition() view public returns (uint sum)
    {
        
        sum = SafeMath.add(x, y);
        return sum;
    }

    function subtraction() view public returns (uint diff)
    {
        diff = SafeMath.sub(x,y);
        return diff;
    }

    function multiplication() view public returns (uint product){
        if (x == 0 || y == 0)
        {
            product = 0;
        }
        else
            product = SafeMath.mul(x,y);
        return product;
    }

    function division() view public returns (uint quotient)
    {
        require(y>0 || y<0, "Cannot divide by zero!");
        quotient = SafeMath.div((x),y);
        return quotient;
    }

    function factorial() view public returns (uint fact0rial){
        fact0rial = 1;
        for (uint z = 1; z <= x; z ++){
            fact0rial= fact0rial * z;  
        }
        
        return fact0rial;
    
    }

    function exponential() view public returns (uint exp){
        exp = x ** y;
        
        return exp;
    }

    function remainder() view public returns (uint remain){
        require (y>0 || y<0, "Cannot divide by zero!");
        remain = x % y;
        /*if (remain >= 1){
            uint decimal10 = SafeMath.div((x*10000000000),y);
            return decimal10;
        }
        else
        */
            return remain;
        
    }

    // how to add decimal10 and division
    function decimalDivision() view public returns (string memory quotient, uint remain, string memory quotientDecimal){
        require (y>0 || y<0, "Cannot divide by zero!");
        remain = x % y;
        if (remain >= 1){
            uint c = SafeMath.div(x,y);
            uint decimal10 = SafeMath.div((x*10000000000),y);
            quotient = Strings.toString(c);
            string memory rem2 = Strings.toString(decimal10);
            string memory rem3 = ".";
            string memory rem4 = string.concat(quotient,rem3);
            quotientDecimal = string.concat(rem4, rem2);
            
            return (quotient, remain, quotientDecimal);
        }
        else{
            uint c = SafeMath.div(x,y);
            quotient = Strings.toString(c);
            return (quotient, remain, "0");
            }

    }

    function minimum() view public returns (uint _min){
        _min = Math.min(x, y);
        return _min;

    }

    function maximum() view public returns (uint _max){
        _max = Math.max(x,y);
        return _max;
    }

    function average() view public returns (uint mean){
        mean = Math.average(x,y);
        return mean;
    }

    function setPercentage(uint _percent) public{
        percent = _percent;
    }
   
    function percentage() view public returns (uint a, uint b){
        a = 100;
        b = ((x/a)* percent) + ((x/(a*10))*percent) + ((x/(a*100))*percent) + ((x/(a*1000))*percent) + ((x/(a*10000))*percent) + ((x/(a*100000))*percent) + ((x/(a*1000000))*percent);
        return (x, b);

    }

    function tax() view public returns (uint _tax){
        
        uint _rPurchase = Math.max(x,y);
        uint _wTaxPerc = 10;
        uint _taxPerc = 3;
        if (_rPurchase > (1 * 10 **6) )
        {
            uint a = 100;
            uint b = ((_rPurchase/a)* _wTaxPerc) + ((_rPurchase/(a*10))*_wTaxPerc) + ((_rPurchase/(a*100))*_wTaxPerc) + ((_rPurchase/(a*1000))*_wTaxPerc) + ((_rPurchase/(a*10000))*_wTaxPerc) + ((_rPurchase/(a*100000))*_wTaxPerc) + ((_rPurchase/(a*1000000))*_wTaxPerc) + ((_rPurchase/(a*10000000))*_wTaxPerc) + ((_rPurchase/(a*100000000))*_wTaxPerc) + ((_rPurchase/(a*1000000000))*_wTaxPerc);
            _tax = b;
            return _tax;
        } 
        else 
        {   
            uint a = 100;
            uint b = ((_rPurchase/a)* _taxPerc) + ((_rPurchase/(a*10))*_taxPerc) + ((_rPurchase/(a*100))*_taxPerc) + ((_rPurchase/(a*1000))*_taxPerc) + ((_rPurchase/(a*10000))*_taxPerc) + ((_rPurchase/(a*100000))*_taxPerc) + ((_rPurchase/(a*1000000))*_taxPerc) + ((_rPurchase/(a*10000000))*_taxPerc) + ((_rPurchase/(a*100000000))*_taxPerc);
            _tax = b;
            return _tax;
        }
    }

    function rTotal() view public returns (uint _rTotal){
        
        uint _tax;
        uint _rPurchase = Math.max(x,y);
        uint _wTaxPerc = 10;
        uint _taxPerc = 3;
        if (_rPurchase > (1 * 10 **6) )
        {
            uint a = 100;
            uint b = ((_rPurchase/a)* _wTaxPerc) + ((_rPurchase/(a*10))*_wTaxPerc) + ((_rPurchase/(a*100))*_wTaxPerc) + ((_rPurchase/(a*1000))*_wTaxPerc) + ((_rPurchase/(a*10000))*_wTaxPerc) + ((_rPurchase/(a*100000))*_wTaxPerc) + ((_rPurchase/(a*1000000))*_wTaxPerc) + ((_rPurchase/(a*10000000))*_wTaxPerc) + ((_rPurchase/(a*100000000))*_wTaxPerc);
            _tax = b;
            _rTotal = _rPurchase - _tax;
            return _rTotal;
        } 
        else 
        {   
            uint a = 100;
            uint b = ((_rPurchase/a)* _taxPerc) + ((_rPurchase/(a*10))*_taxPerc) + ((_rPurchase/(a*100))*_taxPerc) + ((_rPurchase/(a*1000))*_taxPerc) + ((_rPurchase/(a*10000))*_taxPerc) + ((_rPurchase/(a*100000))*_taxPerc) + ((_rPurchase/(a*1000000))*_taxPerc) + ((_rPurchase/(a*10000000))*_taxPerc);
            _tax = b;
            _rTotal = _rPurchase - _tax;
            return _rTotal;
        }

    }

}