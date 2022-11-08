// SPDX-License-Identifier: No License
pragma solidity 0.8.17;

import "./ERC721A.sol";
import "./Percentages.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DonationPool is ERC721A, Ownable, Percentages, ReentrancyGuard {
    struct Entity {
        string name;
        address payable payReciever;
        uint256 payout;
    }
    Entity[] public entities;
    mapping(string => uint256) public name_to_index;
    mapping(address => bool) public used_address;
    
    uint256 public price;

    constructor() ERC721A("DecentDono", "DONO") {
        entities.push(Entity("NULL", payable(address(0)), 0));
        price = 1000000000000000;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function isInitialized(string memory name) public view returns(bool) {
        uint256 index = name_to_index[name];
        return entities[index].payReciever != address(0);
    }

    function addEntity(string memory name, address payable _payRecipient) external onlyOwner {
        require(!isInitialized(name), "Name already in use");
        require(!used_address[_payRecipient], "Address already in use");
        name_to_index[name] = entities.length;
        entities.push(Entity(name, _payRecipient, 0));
    }

    function removeEntity(string memory name) external onlyOwner {
        require(isInitialized(name), "Entity does not exist");
        used_address[entities[name_to_index[name]].payReciever] = false;
        entities[name_to_index[name]] = entities[entities.length - 1];
        entities.pop();
        name_to_index[name] = 0;
    }

    function mint(string memory name, uint256 amount) external payable nonReentrant{
        require(msg.value == price * amount, "Incorrect amount of ETH sent");
        require(isInitialized(name), "Entity does not exist");

        uint256 value = msg.value;
        uint256 distribute = percentageOf(msg.value, 1);

        (bool success,) = entities[name_to_index[name]].payReciever.call{value: percentageOf(value, 99)}("");
        require(success, "Transfer fail");

        for(uint i = 0; i < entities.length; i++) {
            entities[i].payout += (distribute / entities.length);
        }
    }

    function emergencyWithdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value: balanceOf(address(this))}("");
        require(success, "Transfer fail");
    }

    function entityWithdraw(string memory name) external {
        uint256 index = name_to_index[name];
        require(entities[index].payReciever == _msgSender(), "Caller is not designated receiver for entity");

        uint256 value = entities[index].payout;
        entities[index].payout = 0;

        (bool success,) = payable(entities[index].payReciever).call{value: value}("");
        require(success, "Transfer fail");
    }
}