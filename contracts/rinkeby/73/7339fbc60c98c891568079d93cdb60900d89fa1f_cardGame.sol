// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "./ERC1155.sol";
import "./CharacterFactory.sol";

contract cardGame is ERC1155, CharacterFactory {

    uint256 public equipmentsCount; //range from 10^18 to 2*10^18 -1
    uint256 public characterPrice; //range from 2*10^18 to 10**69

    mapping(uint => uint) public equipmentIdToType; //use equipment id to check the type of equipment

    constructor() ERC1155("") {
        characterPrice = 0;
        cardsCount = 3;
        equipmentsCount = 3;
    }

    function newCharacter() external payable {
        require(msg.value == characterPrice, "price is not enough to buy an character");

        _newCharacter();
        _mint(msg.sender, CHARACTER_ID, 1, "");
        CHARACTER_ID++;
    }

    function totalCharacterSupply() public view returns (uint) {
        return characters.length;
    }

    function updateCharacterPrice(uint _newPrice) external onlyOwner {
        characterPrice = _newPrice;
    }

    //////////// for test /////////////////
    
    function kill() external {
        selfdestruct(payable(msg.sender));
    }
}