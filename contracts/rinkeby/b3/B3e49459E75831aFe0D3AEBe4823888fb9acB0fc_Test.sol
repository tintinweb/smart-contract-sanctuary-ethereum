/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.0;

contract Test {
    /*
    * 1. Data Types
    * 2. Data Types visibility
    * 3. Variable name
    * storage variable --> fungsinya untuk nyimpen data yg persistent
    */
    uint256 public result; 

    function multiply(uint256 a, uint256 b) public {
        // Bukan lagi storage, tapi ini itu memory (ga persistent)
        uint256 temp = a * b;
        result = temp;
    }

    /*
    * Visibility itu ada 4 jenis:
    * 1. Public --> function / variable itu bisa di akses dari luar / dalam
    * 2. Private --> hanya bisa di akses di dalam contract ini aja
    * 3. External --> ini hanya bisa di akses dari luar
    * 4. Protected --> ini bisa di akses dari dalam + dari smart contract turunannya (inherit)
    */
}