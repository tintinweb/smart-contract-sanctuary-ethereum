// SPDX-License-Identifier: MIT

/* 
    ___T_  
   | o o |
   |__-__|
   /| []|\
 ()/|___|\()
    |_|_|
    /_|_\
    
https://onchainrobots.com/
https://twitter.com/robotsonchain
*/

pragma solidity ^0.8.13;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "IRobotDescriptor.sol";

contract Robots is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IRobotDescriptor public descriptor;
    uint256 public maxSupply = 10000;
    uint256 public publicPrice = 0.0015 ether;
    uint256 public maxFreeMint = 1;
    bool public minting = true;
    mapping(address => uint256) private _freeMintedCount;

    constructor(IRobotDescriptor newDescriptor) ERC721("Robots", "ROBOT") {
        descriptor = newDescriptor;
    }

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        uint256 price = publicPrice;
        uint256 freeMintCount = _freeMintedCount[msg.sender];
        if(count<=(maxFreeMint-freeMintCount)){
            price=0;
            _freeMintedCount[msg.sender] += count;
        }
        require(msg.value >= (price*count), "Not enough ether to purchase Robots.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDescriptor(IRobotDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function withdrawTo(address receiver) public onlyOwner {        
        (bool withdrawalSuccess, ) = payable(receiver).call{value: address(this).balance}("");
        if (!withdrawalSuccess) revert("Withdrawal failed");
    }

    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        seeds[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
    }


    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        delete seeds[tokenId];
        _burn(tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Robot does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Robot does not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 hairSeed = 100 * (r % 7 + 10) + ((r >> 48) % 20 + 10);
        uint256 eyesSeed = 100 * ((r >> 96) % 9 + 10) + ((r >> 48) % 10 + 10);
        uint256 faceSeed = 100 * ((r >> 144) % 9 + 10) + ((r >> 96) % 10 + 10);
        uint256 armSeed = 100 * (r % 9 + 10) + ((r >> 192) % 10 + 10);
        uint256 bodySeed = 100 * ((r >> 144) % 7 + 10) + ((r >> 144) % 10 + 10);
        uint256 legsSeed = 100 * ((r >> 192) % 2 + 10) + ((r >> 48) % 8 + 10);
        return 10000 * (10000 * (10000 * (10000 * hairSeed + faceSeed) + eyesSeed) + bodySeed) + (10000 * legsSeed) + armSeed;
    }

    function setRound(uint256 _maxFreeMint, uint256 _newMax, uint256 newPublicPrice) external onlyOwner {
      maxFreeMint = _maxFreeMint;
      publicPrice = newPublicPrice;
      maxSupply = _newMax;

    }




    function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}