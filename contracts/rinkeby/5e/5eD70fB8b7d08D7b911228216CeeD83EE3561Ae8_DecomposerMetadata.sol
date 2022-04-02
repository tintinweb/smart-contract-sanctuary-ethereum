pragma solidity ^0.5.0;
/**
* Metadata contract is upgradeable and returns metadata about Token
*/

import "./Metadata.sol";

contract DecomposerMetadata is Metadata {
    function tokenURI(uint _tokenId) public pure returns (string memory _infoUrl) {
        string memory base = "https://decomposer.folia.app/v1/metadata/";
        string memory id = uint2str(_tokenId);
        return base.toSlice().concat(id.toSlice());
    }
}