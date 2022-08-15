/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract counter {

    uint256 public count = 0;

    constructor() {

    

    }

    function incrementCount() public {

    count = count + 1;

    }

    function decrementCount()public {

    count = count -1;

    }

    function mintNft() public {

        incrementCount();
    }


}