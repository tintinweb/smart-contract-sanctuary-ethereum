// SPDX-License-Identifier: MIT
pragma solidity = 0.8.7;

import "Ownable.sol";

contract MonitorTest is Ownable{
    uint256 public number;

    function readnum() external view returns(uint256){
        return number;
    }

    function changenum(uint256 num) external onlyOwner returns(bool){
        number = num;
        return true;
    }
}