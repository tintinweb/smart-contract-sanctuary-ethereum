// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "ens-contracts/wrapper/IMetadataService.sol";


contract MockMetadataService is IMetadataService {

    function uri(uint256) external view returns (string memory){
        return "mock_uri";
    }
}

pragma solidity >=0.8.4;

interface IMetadataService {
    function uri(uint256) external view returns (string memory);
}