/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-18
  SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.7.6;

contract FreeMoney {
    
    function enterHallebarde() public returns (uint) {}
    
}
contract payload  {
    FreeMoney dc;
    
    constructor(address _t) {
        dc = FreeMoney(_t);
    }

    function inject() public {
        dc.enterHallebarde();
    }
    
}