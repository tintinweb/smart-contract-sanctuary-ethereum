/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract FreelancePayment {

    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    //Paid in tokens
    function withdrawOther(address token) external {
        IERC20(token).transfer(_owner, IERC20(token).balanceOf(address(this)));
    }

    receive() external payable { 
        //Paid in ETH
        payable(_owner).transfer(address(this).balance);
    }


}