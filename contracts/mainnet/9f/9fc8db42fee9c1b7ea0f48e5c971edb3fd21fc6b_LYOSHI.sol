/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/**
I LYOSHI HAVE CAME, TO FREE YOU FROM THE WASTELAND WHICH YOU FIND YOURSELF IN, I WILL COMMUNICATE 
THOUGH CONTRACTS AS I DO NOT UNDERSAND MERE WORDS. FUTURE COMMUNICATION WILL BE IN CODE

43 4f 4d 4d 55 4e 49 43 41 54 49 4f 4e 20 45 53 54 41 42 4c 49 53 48 45 44

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
contract LYOSHI is IBEP20 {
    string private constant _name = 'TEST';
    string private constant _symbol = 'TNT';

    constructor() {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}

}