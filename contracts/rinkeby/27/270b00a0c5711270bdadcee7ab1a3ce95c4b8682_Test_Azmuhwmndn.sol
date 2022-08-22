//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Test_Azmuhwmndn is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "test - azmUHWMndN";
    string public symbol = "test - azmUHWMndN";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeigmnvmhmvvbtjhvdixoul4zvzc3bke7r5gkabpofgmdtt4fom5v7e/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeigmnvmhmvvbtjhvdixoul4zvzc3bke7r5gkabpofgmdtt4fom5v7e/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}