/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

pragma solidity ^0.8.0;

contract Level1{
    function name() external pure returns (string memory){
        return "Level1";
    }

    function version() external pure returns (uint256){
        return 1;
    }

    function flag() external pure returns (string memory){
        return "70cad810-423c-11ed-b878-0242ac120002";
    }

    function mul(uint256 multiplier1, uint256 multiplier2) external pure returns (uint256){
        return multiplier1 * multiplier2;
    }

    function add(uint256 multiplier1, uint256 multiplier2) external pure returns (uint256){
        return multiplier1 + multiplier2;
    }

    function minus(uint256 multiplier1, uint256 multiplier2) external pure returns (uint256){
        return multiplier1 - multiplier2;
    }

    function div(uint256 multiplier1, uint256 multiplier2) external pure returns (uint256){
        return multiplier1 / multiplier2;
    }


}