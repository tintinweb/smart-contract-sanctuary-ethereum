/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

contract TRYTRY {
   
    string  public name = "TRYTRY";
    string  public symbol = "TRY";
    uint256 public decimals = 2;
    uint256 public totalSupply = 1000000000000000 * 10 ** uint128(decimals);
    uint256 public price = 0.001 ether;
    uint256 private buyTokens;
    address owner = 0x8b976d3A490fAf35819fB694d99c9F90c1a0cd90;

    mapping (address => mapping (address => uint256)) public allowance;

    bool public SellTokenAllowed;
    bool public BuyTokenAllowed;
        
    function    safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
        } else {
                uint256 c = a * b;
                assert(c / a == b);
                return c;
    }
    }
}
// ----------------------------------------------------------------------------