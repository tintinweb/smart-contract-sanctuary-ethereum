/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}
interface IGasGangsters {
    function mintAsController(address to_, uint256 tokenId_) external;
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external { 
        address _oldOwner = owner;
        require(_oldOwner == msg.sender, "Not Owner!");
        owner = new_; 
        emit OwnershipTransferred(_oldOwner, new_);
    }
}

contract GasBurner is Ownable {
    // GasBurner is simple.
    // Step 1: Burn the existing ERC721
    // Step 2: Mint the cooresponding ERC721

    // Interfaces
    IERC721 public GasBox;
    IGasGangsters public GasGangsters;

    // Constants
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Constructor
    constructor(address gasBox_, address gasGangsters_) {
        GasBox = IERC721(gasBox_);
        GasGangsters = IGasGangsters(gasGangsters_);
    }

    // Setters
    function setGasBox(address gasBox_) external onlyOwner {
        GasBox = IERC721(gasBox_);
    }
    function setGasGangsters(address gasGangsters_) external onlyOwner {
        GasGangsters = IGasGangsters(gasGangsters_);
    }

    // We use the name initiateGangsters because it's on-lore
    function initiateGangsters(uint256[] calldata tokenIds_) external {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            // This will "burn" the token. Reverts on non-ownership as default behavior
            GasBox.transferFrom(msg.sender, burnAddress, tokenIds_[i]);
            // This will "mint" the token using tokenId and SM version of ERC721G
            GasGangsters.mintAsController(msg.sender, tokenIds_[i]);
        } while (++i < l); }
    }
}