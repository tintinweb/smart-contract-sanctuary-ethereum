//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract MoonloveHeartStrings is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "MoonLove Heart Strings";
    string public symbol = "MoonLove Heart Strings";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeibdmkt6ak2xqemmmmvkcf4r3nnwuzros4dlgetdj73xyq3rnusu2q/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeibdmkt6ak2xqemmmmvkcf4r3nnwuzros4dlgetdj73xyq3rnusu2q/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}