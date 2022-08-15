/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/*
 This smart contract facilitates the swap from old DIAMONDS tokens to new DIAMONDS tokens.
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface iERC20 {

	function balanceOf(address who) external view returns (uint256 balance);

	function allowance(address owner, address spender) external view returns (uint256 remaining);

	function transfer(address to, uint256 value) external returns (bool success);

	function approve(address spender, uint256 value) external returns (bool success);

	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

library SafeERC20 {
	function safeTransfer(iERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
	function safeTransferFrom(iERC20 _token, address _from, address _to, uint256 _value) internal {
		require(_token.transferFrom(_from, _to, _value));
	}
}

contract Controllable is Context {
    mapping (address => bool) public controllers;

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
	}

	modifier onlyController() {
		require(controllers[_msgSender()], "Controllable: caller is not a controller");
		_;
	}

    function addController(address _address) public onlyController {
        controllers[_address] = true;
    }

    function removeController(address _address) public onlyController {
        delete controllers[_address];
    }
}

contract Pausable is Controllable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract DIAMONDS_tokenswap is Controllable, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for iERC20;

	mapping (address => bool) public blocklist;
	mapping (address => uint256) public v2TokenBalance;

	bool public v2LiquidityActive = false;

    iERC20 public constant tokenOld = iERC20(0xbBCD93A1809239E3A4bEB1B02fa6f8a83f7000B2); 
    iERC20 public tokenNew;
    uint256 public blocked;

	constructor() {
    	controllers[msg.sender] = true;
	}
	
	function setNewToken(address _newToken) public onlyController {
	    tokenNew = iERC20(_newToken);
	}

	function receiveEther() public payable {
		revert();
	}

    function swap() public {
        uint256 _amount = tokenOld.balanceOf(msg.sender);
        require(_amount > 0,"No balance of DIAMONDS tokens");
        _swap(_amount);
    }

    function _swap(uint256 _amount) internal {
        tokenOld.safeTransferFrom(address(msg.sender), address(this), _amount);
        if (blocklist[msg.sender]) {
            blocked.add(_amount);
        } else {
			uint256 currentAmount = v2TokenBalance[msg.sender];

			v2TokenBalance[msg.sender] = currentAmount.add(_amount);
        }
        emit swapped(_amount);
    }

	function claimV2() public {
		require(address(tokenNew) != address(0), "New token address to claim has not been set");
		require(v2LiquidityActive, "Can not claim v2 tokens until liquidity has been added");
		require(v2TokenBalance[msg.sender] > 0, "No claimable v2 DIAMONDS tokens");

        uint256 _amount = v2TokenBalance[msg.sender];

		require(tokenNew.balanceOf(address(this)) >= _amount, "Not enough v2 tokens in contract to disburse.");

		bool success = tokenNew.transfer(address(msg.sender), _amount);
		if (success) {
			v2TokenBalance[msg.sender] = _amount.sub(_amount);
			emit claimed(_amount);
		} else {
			revert();
		}
	}

	function setLiquidity(bool state) external onlyController {
		v2LiquidityActive = state;
	}
    
    function blockAddress(address _address, bool _state) external onlyController returns (bool) {
		blocklist[_address] = _state;
		return true;
	}

	function transferToken(address tokenAddress, uint256 amount) external onlyController {
		iERC20(tokenAddress).transfer(address(msg.sender),amount);
	}

	function flushToken(address tokenAddress) external onlyController {
		uint256 amount = iERC20(tokenAddress).balanceOf(address(this));
		iERC20(tokenAddress).transfer(address(msg.sender),amount);
	}

    event swapped(uint256 indexed amount);
	event claimed(uint256 indexed amount);
}