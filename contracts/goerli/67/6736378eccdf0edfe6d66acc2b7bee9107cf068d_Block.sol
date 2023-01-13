/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

pragma solidity =0.8.0;


contract Block  {
    function number() public view returns(uint256, uint256)  {
        return (block.number, block.timestamp);
    }
}