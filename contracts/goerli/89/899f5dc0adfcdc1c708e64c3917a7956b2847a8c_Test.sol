/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity 0.8.4;

contract Test {
    uint256 constant FEE_MULTIPLIER = 100;


    function divide_checked(uint256 a,uint256 b) public pure returns(uint256) {
        
        uint256 result;
        // unchecked {
            result = a/b;
        // }
        return result;
    }

    function divide_unchecked(uint256 a,uint256 b) public pure returns(uint256) {
        
        uint256 result;
        unchecked {
            result = a/b;
        }
        return result;
    }

    function divide_assembly(uint256 a,uint256 b) public pure returns(uint256) {
        
        uint256 result;
        assembly {
            result := div(a,b)
        }
        return result;
    }

    function divide_unchecked_assembly(uint256 a,uint256 b) public pure returns(uint256) {
        
        uint256 result;
        unchecked {
        assembly {
            result := div(a,b)
        }
        }
        return result;
    }
}