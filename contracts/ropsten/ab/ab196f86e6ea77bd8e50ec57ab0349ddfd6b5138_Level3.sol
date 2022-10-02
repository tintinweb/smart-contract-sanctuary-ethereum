/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

pragma solidity ^0.8.0;

interface IFlag {
    event CallForFlag(string flag);

    function getFlag() external;
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

    function callForFlag() external {
        caller.push(msg.sender);
        flag.getFlag();
    }

}