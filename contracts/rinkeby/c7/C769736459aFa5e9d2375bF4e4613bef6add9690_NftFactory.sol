// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './interface/IFACTORYITEM.sol';

contract NftFactory {

    event NftSpawned(address newNft, address _owner);

    address private deployer;
    address[] public spawnedNftArray;

    mapping(address => bool) public spawnedNftMapping;

    constructor(){ deployer = msg.sender; }

    function spawn(
        address nftToSpawn,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bytes calldata data
    ) external returns (address){
        address nft = IFACTORYITEM(nftToSpawn).spawnNft(
            name,
            symbol,
            uri,
            data
        );

        emit NftSpawned(nft, msg.sender);
        return nft;
    }

    function owner() external view returns(address) {
        return deployer;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

 interface IFACTORYITEM{

    function spawnNft(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bytes calldata data
    )external returns(address);
 }