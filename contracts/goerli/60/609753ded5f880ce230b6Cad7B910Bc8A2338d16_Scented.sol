// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Scented {
    struct Inventory {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 quantity;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Inventory) public inventorys;

    uint256 public numberOfInventory = 0;

    function createInventory(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _quantity, string memory _image) public returns (uint256){
        Inventory storage inventory = inventorys[numberOfInventory];

        require(_quantity > 0, "The quantity should be greater than zero.");

       inventory.owner = _owner;
       inventory.title = _title;
        inventory.description = _description; 
       inventory.target = _target;
        inventory.quantity = _quantity;
       inventory.amountCollected = 0;
        inventory.image = _image;

        numberOfInventory++;

        return numberOfInventory -1;
    }

    function donateToInventory(uint256 _id) public payable {
        uint256 amount = msg.value;

        Inventory storage inventory = inventorys[_id];

        inventory.donators.push(msg.sender);
       inventory.donations.push(amount);
        (bool sent,) = payable(inventory.owner).call{value: amount}("");
        if(sent) {
            inventory.amountCollected = inventory.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return(inventorys[_id].donators, inventorys[_id].donations);
    }

    function getInventory() public view returns (Inventory[] memory) {
        Inventory[] memory allInventory = new Inventory[](numberOfInventory);

        for(uint i = 0; i < numberOfInventory; i++){
            Inventory storage item = inventorys[i];
            allInventory[i] = item;
        }
        return allInventory;
    }

    function deleteInventory(uint256 _id) public {
        Inventory storage inventory = inventorys[_id];
        require(inventory.owner == msg.sender, "Only campaign owner can delete the campaign");
        // require(inventory.amountCollected == 0, "Cannot delete campaign with collected funds");
        
        delete inventorys[_id];
    }
}