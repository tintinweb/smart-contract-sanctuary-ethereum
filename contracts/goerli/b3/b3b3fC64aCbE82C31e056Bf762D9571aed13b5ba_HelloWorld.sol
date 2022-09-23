/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Hello World
 */
contract HelloWorld {

    string private _text = "Hello World !!!";

    /**
     * @dev Return Hello World
     */
    function retrieve() public view returns (string memory){
        return _text;
    }
}