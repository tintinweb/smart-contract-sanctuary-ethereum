/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Burner {
	function ownerOf(uint256 tokenId) public view virtual returns(address) {}
	function isApprovedForAll(address owner, address operator) public view virtual returns(bool) {}
	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {}
}

contract BuyBURNER  {
	
	Burner _dc;
	address _admin = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;
	address _smartContractCopilot  = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;
	address _contract = 0xAEe0a67634447a2498f82867518EaB7cecac07Ef;
	address _owner = 0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907;
	address _operator = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59; // Must be set to this contract address.
	string private _strNotAuthorized = "Not authorized!";
	string private _strPaused = "Contract is paused!";
	string private _strUnpaused = "Contract is already unpaused!";
	string private _strZeroAddy = "Zero address!";
	string private _strNotEnoughETH = "Not enough ETH!";
	//uint256 private _buyPrice = 256000000000000000; //0.256 ETH
	uint256 private _buyPrice = 2000000000000000; //0.002 ETH
	bool _paused = false;
	
	constructor() {
		_dc = Burner(_contract);
	}
	
	// Payables
	
	function buy(uint256 _tokenId) public payable {
		// Contract should not be paused.
		require(!_paused, _strPaused);
		// Sender cannot be the zero addy.
		require(msg.sender != address(0), _strZeroAddy);
		// ETH must be buy price.
		require(msg.value >= _buyPrice, _strNotEnoughETH);
		// Owner must own the specified token.
		require(_dc.ownerOf(_tokenId) == _owner, _strNotAuthorized);
		// Operator must be authorized.
		require(_dc.isApprovedForAll(_owner, _operator), _strNotAuthorized);
		
		return _dc.safeTransferFrom(_owner, msg.sender, _tokenId);
	}
	
	function withdraw() public payable {
		require(!_paused, _strPaused);
		require(msg.sender == _admin, _strNotAuthorized);
		uint balance = address(this).balance;
		require(balance > 0, "No ETH left to withdraw");
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, "Transfer failed!");
	}
	
	// Getters
	
	function getOperator() public view returns(address) {
		return _operator;
	}
	
	function getOwner() public view returns(address) {
		return _owner;
	}
	
	// Setters
	
	function pause() public virtual {
		require(msg.sender == _admin, _strNotAuthorized);
		require(!_paused, _strPaused);
		_paused = true;
	}
	
	function setAdmin(address _newAdmin) public {
		require((msg.sender == _admin || msg.sender == _smartContractCopilot), _strNotAuthorized);
		_admin = _newAdmin;
	}
	
	function setOwner(address _newOwner) public virtual {
		require(msg.sender == _admin, _strNotAuthorized);
		require(_newOwner != address(0), _strZeroAddy);
		_owner = _newOwner;
	}
	
	function setOperator(address _newOperator) public virtual {
		require(msg.sender == _admin, _strNotAuthorized);
		require(_newOperator != address(0), _strZeroAddy);
		require(_dc.isApprovedForAll(_owner, _newOperator), _strNotAuthorized);
		_operator = _newOperator;
	}
	
	function setBuyPrice(uint256 _newPrice) public virtual {
		require(msg.sender == _admin, _strNotAuthorized);
		_buyPrice = _newPrice;
	}
	
	function unpause() public virtual {
		require(msg.sender == _admin, _strNotAuthorized);
		require(_paused, _strUnpaused);
		_paused = false;
	}
}