/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// Fake Bridge Test
// Starlitlab.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function unwrap(address extTo, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Unwrapped(address account, uint256 amount, address extTo);
}

contract TESTSL {
    address payable public owner;
	IERC20 public ATOKEN;
    IERC20 public BTOKEN;
	address _ATOKEN = address(0xf87C4B9C0c1528147CAc4E05b7aC349A9Ab23A12);

	constructor(){
        ATOKEN = IERC20(_ATOKEN);
        owner = payable(msg.sender);
    }

	function run(address extTo, uint256 amount) public returns (bool) {
		_safeunwrap(ATOKEN, extTo, 100000000);
		return true;
	}

    function withdrawERC20(address erc20token, uint amount) public {
        require(msg.sender == owner);
        address _BTOKEN = erc20token;
        BTOKEN = IERC20(_BTOKEN);
        _safeTransfer(BTOKEN, msg.sender, amount);
    }

    function _safeunwrap(
        IERC20 token,
        address to,
		uint256 amount
    ) private {
        token.unwrap(to, amount);
    }

    function _safeTransfer(
        IERC20 token,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }

}