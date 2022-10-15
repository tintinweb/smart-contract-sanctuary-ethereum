// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;//Coordinates gives a error if this doesn't exist

import "./itemFactory.sol";
import "./erc721.sol";


contract DSC is itemFactory, ERC721{

    event ItemBurned(address indexed _from, uint indexed _tokenId);
    
    mapping (uint => address) itemApprovals;

    address voidAddress = 0x000000000000000000000000000000000000dEaD;

    modifier onlyOwnerOf(uint itemId) {
        require(msg.sender == itemToOwner[itemId],"Your address is not the owner of the Item");
        _;
    }

    function balanceOf(address _owner) external view returns (uint256){
        return ownerItemCount[_owner];
    }

    function ownerOf(uint256 _itemId) external view returns (address){
        return itemToOwner[_itemId];
    }

    function transferFrom(address _from, address _to, uint256 _itemId)  external payable existingInstitution(_from){
        require(itemToOwner[_itemId] == msg.sender || itemApprovals[_itemId] == msg.sender, "Your address is not the owner nor the approved of the Item");
        _tranferItem(_from, _to, _itemId);
        emit Transfer(_from, _to, _itemId);
    }

    function approve(address _approved, uint256 _itemId) external payable onlyOwnerOf(_itemId){
        require(addressToInstitution[_approved] > 0, "Approved address must be registered as institution");
        itemApprovals[_itemId]  = _approved;
        emit Approval(msg.sender, _approved, _itemId);
    }

    function burnItem(uint256 _itemId) public onlyOwnerOf(_itemId){
        itemToOwner[_itemId] = voidAddress;
        ownerItemCount[msg.sender]--;
        emit ItemBurned(msg.sender, _itemId);
    }

    function getInstitution(address _institutionAddress) public view returns(Institution memory institution) {
        uint _institutionId = addressToInstitution[_institutionAddress];
        Institution memory _institution = institutions[_institutionId];
        return (_institution);
    }

    function getToken(uint256 _itemId) public view returns(string memory name, string memory description) {
        Item memory _item = items[_itemId];
        return (_item.name, _item.description);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;//Coordinates gives a error if this doesn't exist


contract itemFactory{

    struct Coordinates {
        int16 value; //-32767 -> 32768
        uint32 digits; // .000000000
    }

    struct Item {
        string name;
        string description;
    }

    struct Institution {
        string name;
        string description;
        Coordinates latitudeGPS;
        Coordinates longitudeGPS;
    }

	//Arrays to save the items and institutions
	Item [] public items;
    Institution [] public institutions;

	// See who the owner of an item is
	mapping (uint => address) internal itemToOwner;
    mapping (address => uint) internal ownerItemCount;
    mapping (address => uint) internal addressToInstitution;

    constructor() public {
        //this is because when I try to see if a institution exists, if it returns 0, I can't know if it does't exist or if it is the intitution nr zero.
        string memory initial = "";
        institutions.push(Institution(initial, initial,Coordinates(0,0),Coordinates(0,0)));
    }

    //verifies if the address is already registered in the contract
    modifier existingInstitution(address _address) {
        require(addressToInstitution[_address] > 0, "Address must be registered as institution to create an Item");
        _;
    }

    /**
     * @param _name Name of the item
     * @param _description A small description
     */
    function createItem(string calldata _name, string calldata _description) external existingInstitution(msg.sender){
        uint id = items.push(Item(_name, _description)) - 1;
        itemToOwner[id] = msg.sender;
        ownerItemCount[msg.sender]++;
    }
    /**
     * @param _name Name of the institution
     * @param _description A small description
     * @param _latitudeInt The integer part of the latitude of the institution
     * @param _latitudeDigits The decimal part of the latitude of the institution
     * @param _longitudeInt The integer part of the longitude of the institution
     * @param _longitudeDigits The decimal part of the longitude of the institution
     */
    function registerInstitution
    (string calldata _name, string calldata _description, int16 _latitudeInt, uint32 _latitudeDigits, int16 _longitudeInt, uint32 _longitudeDigits) external {
        require(addressToInstitution[msg.sender] == 0, "Intitution already registered");
        require((_latitudeInt < 90 && _latitudeInt > -90) && (_longitudeInt < 180 && _longitudeInt > -180), "Wrong coordinates format");

        uint id = institutions.push(Institution(_name, _description, Coordinates(_latitudeInt,_latitudeDigits), Coordinates(_longitudeInt,_longitudeDigits))) - 1;
        addressToInstitution[msg.sender] = id;
    }
    
    //Transfers a token to another address. But it has to be the owner, and the two addresses have to be registered
    function _tranferItem(address _from, address _to, uint256 _itemId) internal existingInstitution(_to){
        itemToOwner[_itemId] = _to;
        ownerItemCount[_to]++;
        ownerItemCount[_from]--;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.6.0;

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function balanceOf(address _owner) external view returns (uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function transferFrom(address _from, address _to, uint256 _tokenId)  external payable;
  
  function approve(address _approved, uint256 _tokenId) external payable;
}