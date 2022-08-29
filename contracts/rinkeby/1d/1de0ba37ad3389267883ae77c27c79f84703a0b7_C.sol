/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.0;

library C 
{
    function add(uint256 a, uint256 b) 
    public pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;  }
}


library D {
        function sub(uint256 a, uint256 b) 
        public pure returns (uint256) {
            uint256 c = a - b;
            assert(c <= a);
            return c;
            }
}