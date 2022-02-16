// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * Solidity Contract Template based on Loot @lootproject https://lootproject.com
 * Source: https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
 *
 * Loot is a NFT that took the NFT world by storm. It redefines what an NFT could be.
 * A characteristic of a loot NFT is all data is contained on chain. No IPFS or external hosting used.
 * They did this in a very gas efficient way for the minter as most computation is offloaded to the read function.
 * Loot has become a prime example on how to create on-chain NFTs.
 *
 * This contract showcase how you will want to structure your contract to create an on-chain NFT,
 * the key is to not construct the metadata during minting, but offload everything to a read function.
 * Although deployment might be costly, it makes minting gas efficient.
 *
 * Curated by @marcelc63 - marcelchristianis.com
 * Each functions have been annotated based on my own research.
 *
 * Feel free to use and modify as you see appropriate
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

contract LootTemplate is ERC721Enumerable, ReentrancyGuard, Ownable {
  // Phrases of Weapons
  // TODO: Change phrases inside the weapons array. You can also change the arrays into anything.
  // For example, a Marvel themed loot will have array of heroes, superpowers, etc.
  string[] private cards = [
    "QmX75L7VGvFCg9p114u2kxV7UmiG9V8yKC9zaWQVb7TJeF",
    "QmbVUQpe9FbRt8qoR5XAd75nCP8nPyzdtJrKQHqbxq1Ggj"
  ];

  // The random function calls keccak256. How it works is, we take a string, put it inside abi.encodePacked
  // then hash it with keccak256. Finally by inserting it inside uint256, we get a random number
  // Remember, keccak256 will always hash the same way as it is deterministic. If the string 1 outputs 2
  // it will always output 2 even if we run it infinite times.
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  // Each of this functions calls the pluck function below.
  // The argument tokenId and "WEAPON" is what we will pass to keccak256.
  // This ensures that getWeapon and getChest will be randomized differently.
  function getCard(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "Tarot Card");
  }

  // This is where the logic on getting a random item happens
  function pluck(
    uint256 tokenId,
    string memory keyPrefix
  ) internal view returns (string memory) {
    // First we get a random number from our random() function.
    uint256 rand = random(
      string(abi.encodePacked(keyPrefix, toString(tokenId)))
    );

    // Then we use the modulo operator to get an index of the sourced array.
    // Modulo operator ensures that the index is within range of the available number of phrases.
    // E.g. if we call the getWeapon function, sourceArray will be the weapon array.
    // There are 18 weapons, but the random number can be 240 for example.
    // If we modulo 240 % 18, we get its remainder which is 6. So we will get weapon item with index 6.
    string memory output = cards[rand % cards.length];
    output = string(
      abi.encodePacked("https://gateway.pinata.cloud/ipfs/", output) // The modulo happens here
    );

    return output;
  }

  // This is where the magic happen, all logic on constructing the NFT is in the tokenURI function
  // NOTE: Remember this is a read function. In the blockchain, calling this function is free and cost 0 gas.
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    // We create the an array of string with max length 17
    string[3] memory parts;

    // Part 1 is the opening of an SVG.
    // TODO: Edit the SVG as you wish. I recommend to play around with SVG on https://www.svgviewer.dev/ and figma first.
    // Change the background color, or font style.
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 612 1009" preserveAspectRatio="xMinYMin meet" ><image x="0" y="20" width="612" height="1009" xlink:href="';

    // Then we call the getWeapon function. So the randomization and getting the weapon actually happens
    // in the read function, not when the NFT is minted
    parts[1] = getCard(tokenId);

    parts[2] = '"></image></svg>';

    // We do it for all and then we combine them.
    // The reason its split into two parts is due to abi.encodePacked has
    // a limit of how many arguments to accept. If too many, you will get
    // "stack too deep" error
    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2]
      )
    );

    // We then create a JSON metadata and encode it in Base64. The browser and OpenSea can recognize this as
    // a url and will encode it. This is how the data is on-chain and does not rely on IPFS or external server
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Tarot #',
            toString(tokenId),
            '", "description": "Tarot is randomized tarot and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Tarot in any way you want.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  // Claim is suepr simple, it just checks tokenId is within range and then it assigns the address with it
  function claim(uint256 tokenId) public nonReentrant {
    require(tokenId > 0 && tokenId < 10000, "Token ID invalid");
    _safeMint(_msgSender(), tokenId);
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  constructor() ERC721("Tarot", "TAROT") Ownable() {}
}