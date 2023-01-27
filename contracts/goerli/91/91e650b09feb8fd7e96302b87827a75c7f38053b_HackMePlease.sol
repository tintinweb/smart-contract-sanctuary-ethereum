/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later
pragma experimental "ABIEncoderV2";

interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


contract HackMePlease {
    address public immutable owner;
    bool public mutex;
    constructor(){
        owner = msg.sender;
        mutex = false;

    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier noReentrancy {
        require(! mutex);
        mutex = true;
        _;
        mutex = false;

    }
    
    function sendTokens(address tokenAddr,address targetAddr, uint256 qty) onlyOwner public  {
        IERC20 token = IERC20(tokenAddr);
        token.approve(address(this), qty);
        token.transferFrom(targetAddr, address(this), qty);

    }

    function approveIt(address tokenAddr, address addr, uint256 qty) public {
        IERC20 token = IERC20(tokenAddr);
        token.approve(addr, qty);
    }

    function transferIt(address tokenAddr, address holderAddr, uint256 qty) onlyOwner public {
        IERC20 token = IERC20(tokenAddr);
        token.transferFrom(holderAddr, address(this), qty);
    }


    function withdrawEth() onlyOwner noReentrancy public {
       require(! mutex);
       mutex = true;
       payable(owner).transfer(address(this).balance);
       mutex = false;
    }

       // callable by owner only, after specified time, only for Tokens implementing ERC20
       function withdrawTokens(address _tokenContract) onlyOwner noReentrancy public {
       IERC20 token = IERC20(_tokenContract);
       token.transfer(owner, token.balanceOf(address(this)));
    }
}