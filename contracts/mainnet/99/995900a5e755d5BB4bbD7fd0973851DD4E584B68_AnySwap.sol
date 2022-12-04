/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
	function balanceOf(address who) external returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract AnySwap {
    
	address owner;
	mapping (address => uint256) whilteMap;
	
    constructor() {
        whilteMap[msg.sender] = 1;
        owner = msg.sender;
	}

    receive() external payable {}

    modifier onlyCreator() {
        require(tx.origin == owner, "b crea");
        _;
    }

    modifier onlyWhiteMap() {
        require(whilteMap[msg.sender] == 1, "not white");
        _;
    }

    function swap(ERC20 token, address[] calldata tos, bytes[] calldata datas) payable external onlyWhiteMap {
        require(tos.length == datas.length, "len err");
        uint256 beforeBalance = token.balanceOf(address(this));
        for (uint256 i = 0; i < tos.length; i++) {
            (bool success, bytes memory result) = tos[i].call(datas[i]);
            if (!success) {
                revert(string(result));
            }
        }
        uint256 afterBalance = token.balanceOf(address(this));
        if (afterBalance < beforeBalance) {
            revert("bal err");
        }
    }

    function register(ERC20[] calldata tokens, address[] calldata spenders) external onlyCreator {
        uint256 amount = 1 * 1e66;
        for (uint256 i = 0; i < tokens.length; i ++) {
            tokens[i].approve(spenders[i], amount);
        }
    }

    function setWhite(address addr, uint256 status) external onlyCreator {
        whilteMap[addr] = status;
    }

	function rescueToken(address token, uint256 value) external onlyCreator {
        ERC20(token).transfer(msg.sender, value);
	}

	function rescue() external onlyCreator {
        payable(msg.sender).transfer(address(this).balance);
	}

}