// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Base64.sol";
import "./Traits.sol";

contract Dungeon is Ownable, IERC721Receiver {
    address public raidsAddress;

    struct Gear {
        string name;
        string tier;
        string status;
        uint256 value;
    }

    struct RaidInventory {
        Gear shirt;
        Gear pants;
        Gear head;
        Gear feet;
        Gear chest;
        Gear shoulders;
        Gear ring;
        Gear mainhand;
        Gear offhand;
        Gear artifact;
    }

    mapping(uint256 => RaidInventory) public tokenInventory;

    function generateTokenInventory(uint256 tokenId) external {
        require(msg.sender == raidsAddress, "You do not have permission to generate an inventory for that token");
        tokenInventory[tokenId] = RaidInventory(Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0));
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        RaidInventory storage _inventory = tokenInventory[tokenId];
        return Traits.getTokenURI(_inventory, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }

    constructor(){}

}