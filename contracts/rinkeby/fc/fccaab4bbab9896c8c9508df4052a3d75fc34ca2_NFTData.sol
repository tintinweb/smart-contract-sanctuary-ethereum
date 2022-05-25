/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

pragma solidity ^0.8.7;

contract NFTData {
    uint[] private allData = [69, 420, 6000000];

    function getNFTs() external view returns(uint[] memory){
        return allData;
    }
}