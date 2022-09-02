/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

/* SPDX-License-Identifier: AGPL-3.0 */
pragma solidity ^0.8.0;

contract HexHex
{
	string public name = "Hex Hex";
	string public symbol = "HEXHEX";

	mapping(uint => address) public ownerOf;
	mapping(address => uint) public balanceOf;
	mapping(uint => address) public getApproved;
	mapping(address => mapping(address => bool)) isApprovedForAll;

	constructor ()
	{
		ownerOf[0] = msg.sender;
		ownerOf[1] = msg.sender;
		balanceOf[msg.sender] = 2;
	}

	function approve (address operator, uint token) external
	{
		getApproved[token] = operator;
	}

	function setApprovalForAll (address operator, bool approved) external
	{
		isApprovedForAll[msg.sender][operator] = approved;
	}

	function transferFrom (address sender, address receiver, uint token) external
	{
		ownerOf[token] = receiver;
		balanceOf[sender]--;
		balanceOf[receiver]++;
	}

	function saveTransferFrom (address sender, address receiver, uint token) external
	{
		ownerOf[token] = receiver;
		balanceOf[sender]--;
		balanceOf[receiver]++;
	}

	function saveTransferFrom (address sender, address receiver, uint token, bytes calldata data) external
	{
		ownerOf[token] = receiver;
		balanceOf[sender]--;
		balanceOf[receiver]++;
	}

	event Transfer(address indexed sender, address indexed receiver, uint256 indexed token);
	event Approval(address indexed owner, address indexed operator, uint256 indexed token);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}