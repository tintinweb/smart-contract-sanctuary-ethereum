/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity ^0.5.2;

contract heyue {
    function plzz(address payable[] memory  dizhi,uint256 shuliang) public payable {
    for(uint i = 0; i < dizhi.length; i++)
        {
           dizhi[i].transfer(shuliang);
          
        }
    }
}