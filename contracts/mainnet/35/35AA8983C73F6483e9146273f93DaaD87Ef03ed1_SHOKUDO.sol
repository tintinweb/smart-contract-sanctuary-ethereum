/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title SHOKUDO (食堂)
 * @author 0xSumo
 */

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    mapping(address => bool) public admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    modifier onlyAdmin { require(admin[msg.sender], "Not Admin"); _; }
    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface ICHANCO {
    function owner() external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external;
    function burnFrom(address from_, uint256 amount_) external;
}

contract SHOKUDO is OwnControll {
    
    mapping(uint256 => wlItems) public wlVending;
    mapping(address => string) public names;
    mapping(uint256 => mapping(address => bool)) hasPurchased; 
    mapping(uint256 => address[]) public hasPurchasedBy;

    event Purchase (uint256 indexed _id, address indexed _address);

    ICHANCO public CHANCO = ICHANCO(0xbBEf6C4D5c23351C0A1C23528F547985B25dD366);

    uint256 public itemCount;

    struct wlItems {
        string title;
        string imageUri;
        string projectUri;
        uint256 id;
        uint256 price;
        uint256 amountAvailable;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    function addToVending(uint256 id_, wlItems memory wlItems_) external onlyAdmin {
        require(bytes(wlItems_.title).length > 0, "You must specify a Title");
        require(uint256(wlItems_.endTime) > block.timestamp, "Already expired timestamp");
        require(wlItems_.endTime > wlItems_.startTime, "End time not right");

        wlVending[id_] = wlItems(
            wlItems_.title,
            wlItems_.imageUri,
            wlItems_.projectUri,
            wlItems_.id,
            wlItems_.price * 10 ** 18,
            wlItems_.amountAvailable,
            wlItems_.amount, //always 0
            wlItems_.startTime,
            wlItems_.endTime
        );
        itemCount++;
    }

    function deleteItem(uint256 _id) external onlyAdmin {
        require(wlVending[_id].amount == 0, "Cannot delete item");
        delete wlVending[_id];
        itemCount--;
    }

    function purchaseAsAdmin(uint256 _id) external onlyAdmin {
        require(wlVending[_id].amountAvailable > wlVending[_id].amount, "No spots left");
        require(!hasPurchased[_id][msg.sender], "Address has already purchased");
        require(wlVending[_id].startTime <= block.timestamp, "Not started yet");
        require(wlVending[_id].endTime >= block.timestamp, "Past deadline");
        unchecked { wlVending[_id].amount++; }
        hasPurchased[_id][msg.sender] = true;
        hasPurchasedBy[_id].push(msg.sender);
    }

    function purchaseAsUser(uint256 _id) external {
        require(wlVending[_id].amountAvailable > wlVending[_id].amount, "No spots left");
        require(bytes(names[msg.sender]).length > 0, "No name set");
        require(!hasPurchased[_id][msg.sender], "Address has already purchased");
        require(CHANCO.balanceOf(msg.sender) >= wlVending[_id].price, "Not enough tokens");
        require(wlVending[_id].startTime <= block.timestamp, "Not started yet");
        require(wlVending[_id].endTime >= block.timestamp, "Past deadline");

        unchecked { wlVending[_id].amount++; }
        hasPurchased[_id][msg.sender] = true;
        hasPurchasedBy[_id].push(msg.sender);
        CHANCO.burnFrom(msg.sender, wlVending[_id].price);

        emit Purchase(_id, msg.sender);  
    }

    function setName(string memory _name) external {
        names[msg.sender] = _name;
    }

    function addressHasPurchased(uint256 _id, address _address) public view returns (bool) {
        return hasPurchased[_id][_address];
    }

    function getPurchaserNames(uint256 _id) external view returns (string[] memory) {
        address[] memory purchaserAddresses = hasPurchasedBy[_id];
        string[] memory purchaserNames = new string[](purchaserAddresses.length);
        for (uint256 i = 0; i < purchaserAddresses.length; i++) {
            purchaserNames[i] = names[purchaserAddresses[i]];
        }
        return purchaserNames;
    }

    function setCHANCO(address address_) external onlyOwner {
        CHANCO = ICHANCO(address_);
    }
}