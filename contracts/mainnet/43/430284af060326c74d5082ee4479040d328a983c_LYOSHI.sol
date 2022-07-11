/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/**
54 48 49 53 20 49 53 20 4f 4e 4c 59 20 54 48 45 20 42 45 47 47 49 4e 49 4e 47 20

LYOSHIINU.COM

https://twitter.com/lyoshi_inu

https://t.me/LyoshiInu
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
contract LYOSHI is IBEP20 {
    string private constant _name = 'LYOSHI INU';
    string private constant _symbol = 'LYOSHI';

    constructor() {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}

}