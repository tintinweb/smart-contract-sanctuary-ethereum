/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

/**

Zepg

n ma mjd n mbmoi nbb fgnjv hrl zngl he oepg rlbb.

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
contract Zepg is IBEP20 {
    string private constant _name = 'Zepg';
    string private constant _symbol = 'Zepg';

    constructor() {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}

}