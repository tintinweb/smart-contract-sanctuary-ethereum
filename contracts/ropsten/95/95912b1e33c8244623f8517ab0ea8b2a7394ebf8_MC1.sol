/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity = 0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MC1 {
    uint vvar1;
    uint vvar2;
    string ddd1;
constructor ()  {
    vvar1 = 2;
      vvar2 = 2;
      ddd1 = 'abc123';
}
function Rread() view public returns(uint, uint, string memory) {
return(vvar1, vvar2, ddd1);
}
function Wwrite(uint vvv, string memory dddd ) public {
    vvar1=vvar1+1;
    vvar2=vvar2 + vvv;
    ddd1 = dddd;

}


}