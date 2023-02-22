/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Count {
    uint256 count;

    function  getCount() view public returns(uint256){
        return count;
    }

    function incrementCount()  public {
        count += 1;
    }

      function decrementCount()  public {
        count -= 1;
    }
}