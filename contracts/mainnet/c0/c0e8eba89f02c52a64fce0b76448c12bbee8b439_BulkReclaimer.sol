/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface Registrar {
    function reclaim(uint256 id, address owner) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BulkReclaimer {
    Registrar registrar;
    constructor(address _registrar) {
        registrar = Registrar(_registrar);
    }

    function bulkUpdateController(uint256[] memory tokenIDs, address controller) public {
        uint256 len = tokenIDs.length;
        for(uint i = 0; i < len;) {
            uint256 tokenID = tokenIDs[i];
            if(registrar.ownerOf(tokenID) == msg.sender) {
                registrar.reclaim(tokenID, controller);
            }
            unchecked {
                ++i;
            }
        }
    }

}