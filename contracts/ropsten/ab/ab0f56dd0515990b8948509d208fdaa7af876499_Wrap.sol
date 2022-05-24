/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address owner, address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH9 is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
    function approve(address owner, uint amount) external returns (bool);
}

contract Wrap {
    IWETH9 public token;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function eth2weth (address _account, address _weth, uint _amount) public returns (bool success) {
        token = IWETH9(_weth);

        token.approve(_account, _amount);
        emit Approval(msg.sender, _account, _amount);

        token.transferFrom(msg.sender, _account, _amount);
        emit Transfer(msg.sender, _account, _amount);

        return true;
    }
}