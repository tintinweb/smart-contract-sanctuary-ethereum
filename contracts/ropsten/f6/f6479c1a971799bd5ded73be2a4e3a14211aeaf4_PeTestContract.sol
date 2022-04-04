// contracts/PeTestContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract PeTestContract is ERC721URIStorage, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public _counter;

    constructor() ERC721("PeTestContract", "PETE") {}
    
    function mintNFT(address to, string memory tokenURI) public onlyOwner returns (uint256){
        require(to != address(0), "ERC721: query for the zero address");
        require(_counter+1 <= MAX_NFT_SUPPLY, "The minting of coins is completed.");
        _safeMint(to, _counter);
        _setTokenURI(_counter, tokenURI);
        _counter += 1;
        return _counter;
    }
    
    function tokensOfOwner(address owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            for (uint256 id = 0; id <= MAX_NFT_SUPPLY; id++) {
                if (_exists(id)){
                    if (ownerOf(id) == owner) {
                        result[resultIndex] = id;
                        resultIndex++;
                    }
                }
            }

            return result;
        }
    }
}