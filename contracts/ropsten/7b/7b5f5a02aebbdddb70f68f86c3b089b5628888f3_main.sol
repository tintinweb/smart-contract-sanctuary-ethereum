// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./SafeERC20.sol";



contract main{

    using SafeERC20 for IERC20; 
    IERC20 lptoken = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    function checkValue() public view returns(uint256){
        return address(this).balance;
    }

    function withdrawEmergency(uint256 amount) public returns(bool){
        
        lptoken.safeTransfer(address(msg.sender), amount);
        return true;

    }

    function getToken() external payable returns(bool){
        return true;
    }

}