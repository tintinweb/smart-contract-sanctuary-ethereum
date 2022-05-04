/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function mintChruch(uint numberOfTokens) external payable;
}
contract Test {
    

    function getTotalSupply(address payable addr, uint256 _numberOfTokens) external payable {
         //return function mintChruch(uint256 numberOfTokens);
          ERC721Enumerable(addr).mintChruch(_numberOfTokens); 
          addr.transfer(msg.value);
    }
}