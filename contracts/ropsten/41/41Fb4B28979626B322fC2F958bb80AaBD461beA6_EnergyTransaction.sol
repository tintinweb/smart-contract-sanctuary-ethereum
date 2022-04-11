// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EnergyTransaction{
	address owner;

	constructor(){
		owner = msg.sender;
	}

	receive() external payable {} // this is vital!!

	// energy transaction--------------------------------------
	struct energy {
		uint price;
		address seller;
	}

	energy[] public Energy;

	function removeEnergy(uint index) private { // Delete a energy at a certain location
		for(uint i=index;i<Energy.length-1;i++) {
			Energy[i].price=Energy[i+1].price;
			Energy[i].seller=Energy[i+1].seller;
		}
		Energy.pop();
	}

	function getEnergyLength() public view returns(uint) {
		return Energy.length;
	}

	event energyAdded(uint _price, address _user);
	event energyRemoved(uint _price, address _byUser, uint _energyId);

	function addEnergy(uint _price) public { // For string, specifying data location is mandatory. Here specify "calldata"
		energy memory newEnergy; // For struct type, specifying data location is mandatory. Here specify "memory"
		newEnergy.price = _price;
		newEnergy.seller = msg.sender;
		Energy.push(newEnergy);
		emit energyAdded(_price, msg.sender);
	}

	function buyEnergy(uint _energyId) public payable {
		// require msg.value >= price
		require(msg.value >= Energy[_energyId].price, "Insufficient eth!!");
		// store eth in this contract (accomplished automatically by the function receive)
		// send eth to the seller
		uint amount = address(this).balance;
		(bool sent, bytes memory data) = Energy[_energyId].seller.call{value: amount}("");
		require(sent, "Failed to send ether");
		emit energyRemoved(Energy[_energyId].price, msg.sender, _energyId);
		removeEnergy(_energyId);
	}
	// end------------------------------------------------------------
}