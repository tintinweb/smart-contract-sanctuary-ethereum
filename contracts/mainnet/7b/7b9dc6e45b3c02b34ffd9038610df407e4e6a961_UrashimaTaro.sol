/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/**

88 holders.

88 of you that do not open the box.

for only then will we release our medium article.

inside this article will guide you to our telegram.

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
contract UrashimaTaro is IBEP20 {
    string private constant _name = 'Urashima';
    string private constant _symbol = '$Taro';

    constructor() {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}

}