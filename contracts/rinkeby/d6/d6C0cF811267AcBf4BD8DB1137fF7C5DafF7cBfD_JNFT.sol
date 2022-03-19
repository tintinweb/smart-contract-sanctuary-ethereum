// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We first import some OpenZeppelin Contracts.
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./console.sol";

// We need to import the helper functions from the contract that we copy/pasted.
import {Base64} from "./Base64.sol";

// We inherit the contract we imported. This means we'll have access
// to the inherited contract's methods.
contract JNFT is ERC721URIStorage {
    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // We need to pass the name of our NFTs token and it's symbol.
    constructor() ERC721("JOSHNFT", "JNFT") {
        console.log("This is my NFT contract. Woah!");
    }

    // A function our user will hit to get their NFT.
    function makeJNFT(string memory name, string memory image) public {
        // Get the current tokenId, this starts at 0.
        uint256 newItemId = _tokenIds.current();

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            string(
                abi.encodePacked(
                    '{"name": "',
                    name,
                    " -- NFT #: ",
                    Strings.toString(newItemId),
                    '", "description": "This is one of JoshNFT!", "image": "',
                    image,
                    '"}'
                )
            )
        );

        // Just like before, we prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, newItemId);

        // Update your URI!!!
        _setTokenURI(newItemId, finalTokenUri);

        _tokenIds.increment();
    }
}