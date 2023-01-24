//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract ImaginariumStudiosWhitelistCoin is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Imaginarium Studios Whitelist Coin";
    string public symbol = "Imaginarium Studios Whitelist Coin";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeidus5trihpscvxochau4zywlt7mebxbuid7nouszpzfvgidutu5za/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeidus5trihpscvxochau4zywlt7mebxbuid7nouszpzfvgidutu5za/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}