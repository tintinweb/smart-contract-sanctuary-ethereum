/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MC1 {
    uint vvar1;
    uint vvar2;
constructor ()  {
    vvar1 = 2;
      vvar2 = 2;
}
function Rread() view public returns(uint, uint) {
return(vvar1, vvar2);
}
function Wwrite(uint vvv) public {
    vvar1=vvar1+1;
    vvar2=vvar2 + vvv;
    
}


}