/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Features {
    /// @dev Valid range [0, 11)
    uint8 background;
    /// @dev Valid range [0, 20)
    uint8 beak;
    /// @dev Valid range [0, 113)
    uint8 body;
    /// @dev Valid range [0, 63)
    uint8 eyes;
    /// @dev Valid range [0, 13)
    uint8 eyewear;
    /// @dev Valid range [0, 38)
    uint8 headwear;
    /// @dev Valid range [0, 9)
    uint8 outerwear;
}

struct Mutators {
    bool useProofBackground;
}

interface IMoonbirds {
    function renderingContract() external view returns (address);
}

interface ITokenURIGenerator {
    function getFeatures(uint256 tokenId) external view returns (Features memory);
    function getMutators(uint256 tokenId) external view returns (Mutators memory);
    function artworkURI(Features memory features, Mutators memory mutators, uint32 scaleupFactor) external view returns (string memory);
}

abstract contract Ownable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}

// https://etherscan.io/address/0x85701AD420553315028a49A16f078D5FF62F4762#code
contract MoonbirdsRender is Ownable{

    IMoonbirds public moonbirds;
    uint32 internal _bmpScale;

    constructor(IMoonbirds _moonbirds) {
        moonbirds = _moonbirds;
        _bmpScale = 12;
    }

    function setBmpScale(uint32 bmpScale_) external onlyOwner {
        _bmpScale = bmpScale_;
    }

    function render(uint256 tokenId) external view returns (bytes memory) {
        ITokenURIGenerator generator = ITokenURIGenerator(moonbirds.renderingContract());
        Features memory features = generator.getFeatures(tokenId);
        Mutators memory mutators = generator.getMutators(tokenId);
        string memory img = generator.artworkURI(features, mutators, _bmpScale);
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="">',
                '<body>',
                    '<img src="', img, '"/>',
                '</body>',
            '</html>'
        );
    }
}