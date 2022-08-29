/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Keyboards {

	address payable owner;

	enum KeyboardKind{
		SixtyPercent,
		SeventyFivePercent,
		EightyPercent,
		Iso105
	}
	
	struct Keyboard {
		KeyboardKind kind;
		//ABS = false, PBT = true
		bool isPBT;
		//tailwind filters to layer over
		string filter;
		address owner;
	}
	
	event KeyboardCreated(Keyboard keyboard);
	event TipSent(address recipient, uint256 amount);
	
	Keyboard[] public createdKeyboards;
	
	function getKeyboards() public view returns (Keyboard[] memory){
		return createdKeyboards;
	}
	
	function create(KeyboardKind _kind, bool _isPBT, string calldata _filter) external {
		
		Keyboard memory newKeyboard = Keyboard({
		kind: _kind,
		isPBT: _isPBT,
		filter: _filter,
		owner: msg.sender
		});
		createdKeyboards.push(newKeyboard);
		emit KeyboardCreated(newKeyboard);
	}
	
	function tip(uint256 _index) external payable {
		owner = payable(createdKeyboards[_index].owner);
		owner.transfer(msg.value);
		emit TipSent(owner, msg.value);
	}
	
}