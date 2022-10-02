/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

pragma solidity ^0.8.0;

interface IFlag {
    function getFlag() external returns (string memory);
}

contract Level3{
    IFlag private flag;
    address[] private caller;

    constructor(address flagAddress) {
        flag = IFlag(flagAddress);
    }

    function name() external pure returns (string memory){
        return "Level3";
    }

    function version() external pure returns (uint256){
        return 1;
    }

    function callForFlag() external returns (string memory){
        caller.push(msg.sender);
        return flag.getFlag();
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