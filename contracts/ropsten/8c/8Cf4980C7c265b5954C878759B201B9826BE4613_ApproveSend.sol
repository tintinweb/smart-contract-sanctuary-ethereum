/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract ApproveSend {
    address public _WETH = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    IERC20 public WETH = IERC20(_WETH);

    function transferToC (uint amount) public
    {
        WETH.approve(address(this),amount);
        WETH.transferFrom(msg.sender,address(this),amount);
    }
    
    function transferFromC(uint amount) public{
        WETH.approve(address(this),amount);
        WETH.transferFrom(address(this),msg.sender,amount);
    }
    
    function getbal() public view returns(uint){
        return WETH.balanceOf(msg.sender);
    }
    
    
}