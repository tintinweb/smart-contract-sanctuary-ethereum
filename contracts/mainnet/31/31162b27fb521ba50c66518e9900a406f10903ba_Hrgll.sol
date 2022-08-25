/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

/**

Hrgll

👑👑👑👑👑

L amcl rlbb glmb; l ihecl nhi zngli.
 
mjd nj nhi zbmali epg rewl lqwngli.
 
rlmwlj, hee, ni alglbo epg sglmhnej.
 
l smj vgmjh epgilbwli epg ej imbwmhnej.
 
mbb hrmh’i gltpngld ni namvnjmhnej.

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
contract Hrgll is IBEP20 {
    string private constant _name = 'Hrgll';
    string private constant _symbol = 'Hrgll';

    constructor() {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}

}