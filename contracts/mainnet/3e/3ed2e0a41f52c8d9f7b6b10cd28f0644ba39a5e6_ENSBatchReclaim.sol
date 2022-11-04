/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRegistrarImplementation {
    function ownerOf(uint256 tokenId) external view returns (address);
    function reclaim(uint256 id, address owner) external;
}

contract ENSBatchReclaim {
    IBaseRegistrarImplementation ensRegistrar = IBaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    function batchSetController(uint256[] calldata ids) public {
        for (uint i=0; i<ids.length; i++){
            require(msg.sender == ensRegistrar.ownerOf(ids[i]), "You do not own all the domains");
        }
        for (uint i=0; i<ids.length; i++){
            // the reclaim function in ensRegistrar sets the controller for the ens nft
            ensRegistrar.reclaim(ids[0], msg.sender);
        }
    }
}