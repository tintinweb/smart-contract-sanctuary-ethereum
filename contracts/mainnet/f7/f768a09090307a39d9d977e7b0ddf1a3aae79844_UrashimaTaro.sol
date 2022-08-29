/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/**
Urashima Taro opened the box and was greatly saddened.

If you do not open the box, you will receive a letter from the deployer wallet.

This letter will guide you into the private telegram.

When those that do not open the box 88 - our medium will be publish.

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