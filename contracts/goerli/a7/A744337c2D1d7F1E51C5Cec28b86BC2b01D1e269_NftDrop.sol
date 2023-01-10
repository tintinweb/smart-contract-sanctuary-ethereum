// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract NftDrop {
    // 0xA744337c2D1d7F1E51C5Cec28b86BC2b01D1e269
    //@dev create NFT drop struct to track each drop

    struct Drop {
        string imageUri;
        string name;
        string description;
        string social1;
        string social2;
        string WebsiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    //@dev drops to hold all Drop
    Drop[] public drops;
    address public owner;
    mapping(uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }
    
    function updateDrop( 
        uint256 _index,
        Drop memory _drop)
        public {
        require(msg.sender == users[_index],
         "This is not your drop");    
         _drop.approved = false;
        drops[_index] = _drop;
    }
    //@dev  addDrop() to add new drops
    //@param _drop the Drop struct 
    function addDrop(Drop memory _drop ) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    //@dev approveDrop() for owner to approve drops
    //@param _index position of drop in the drops list
    function approveDrop(uint256 _index) public  onlyOwner {
      Drop storage drop = drops[_index];
      drop.approved = true;
    }
    
    // Getter functions

    //@dev getDrops() to retrieve all drops inside our drops list
    function getDrops() public view returns(Drop[] memory){
        return drops;
    }

    // modifiers
    modifier onlyOwner {
        require(owner == msg.sender, "You are not an owner");
        _;
    }
}