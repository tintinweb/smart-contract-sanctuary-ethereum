//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Terraducks is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Terraducks";
    string public symbol = "Terraducks";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeieexzghsss7m3y6iq2efbhkkirpfgxvqqopumz7o6goj2wwlxw5yy/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeieexzghsss7m3y6iq2efbhkkirpfgxvqqopumz7o6goj2wwlxw5yy/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}