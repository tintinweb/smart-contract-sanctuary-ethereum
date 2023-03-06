//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

contract Marketplace {

	enum State {
		Purchased,
		Activated,
		Deactivated
	}

	struct Item {
		uint id;
		uint price; 
		bytes32 proof; 
		address owner;
		State state;
	}

	// mapping itemHash to Item data
	mapping(bytes32 => Item) private ownedItems;

	// mapping of itemId to ItemHash			
	mapping(uint => bytes32) private ownedItemsHash;

	// number of all items + id of the items
	uint private totalOwnedItems;

	// contract owner
	address payable private owner;

	constructor() {
		_setContractOwner(msg.sender);
	}

	/// Item already purchased!
	error ItemHasOwner();

	modifier onlyOwner() {
		require(msg.sender == owner, "You are not the owner of this contract");
		_;
	}

	function purchaseItem(
		bytes16 _itemId, // 0x00000000000000000000000000003130 hex value so it fits the bytes16 format of the itemId
		bytes32 _proof // 0x0000000000000000000000000000313000000000000000000000000000003130 placeholder 
	) external payable {
		require(msg.value > 0, "You must send some Ether");

		uint _id = totalOwnedItems++;
		bytes32 itemHash = keccak256(abi.encodePacked(_itemId, msg.sender));
		
		if (_hasItemOwnership(itemHash)) {
			revert ItemHasOwner();
		}
		// keccak256 hash of the item id and the msg.sender
			// site - 0xc4eaa3558504e2baa2669001b43f359b8418b44a4477ff417b4b007d7cc86e37
			// function itemHash - 0xc4eaa3558504e2baa2669001b43f359b8418b44a4477ff417b4b007d7cc86e37
		// WORKS!!!
		
		ownedItemsHash[_id] = itemHash;
		ownedItems[itemHash] = Item(
			_id, 
			msg.value, 
			_proof, 
			msg.sender, 
			State.Purchased
		);
	}

	function transferOwnership(address _newOwner) 
		external 
		onlyOwner
	{
		require(_newOwner != address(0), "You must provide a valid address");
		require(_newOwner != owner, "You are already the owner of this contract");

		_setContractOwner(_newOwner);
	}

	function getItemCount()
		external
		view
		returns (uint) 
	{
		return totalOwnedItems;
	}

	function getItemHashAtIndex(uint _index)
		external
		view
		returns (bytes32)
	{
		return ownedItemsHash[_index];
	}

	function getItemByHash(bytes32 _itemHash)
		external
		view
		returns (Item memory)
	{
		return ownedItems[_itemHash];
	}

	function getContractOwner()
		external
		view
		returns (address)
	{
		return owner;
	}

	function _setContractOwner(address _newOwner)
		private
	{
		owner = payable(_newOwner);
		owner.transfer(address(this).balance);
	}

	function _hasItemOwnership(bytes32 _itemHash)
		private
		view
		returns (bool)
	{
		return ownedItems[_itemHash].owner == msg.sender;
	}
}