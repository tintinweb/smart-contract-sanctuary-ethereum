// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ImmutableGoodMetadataRepository {
    address[] public contractAddresses = [
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0x1e061d4b8118c64C9113d0d7aE4b565F5aeA0b52,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0,
        0xE1E37CAe8c93026ada3AE91328C94b11450967D0
    ];
    uint[] public tokenIds = [
        12,
        7,
        27,
        21,
        25,
        26,
        24,
        23,
        19,
        9,
        151,
        144,
        150,
        4,
        14,
        5,
        2,
        146,
        110,
        131
    ];
    uint _rnd;

    function add(
        address contractAddress,
        uint tokenId,
        bool throwError
    ) external {
    }

    function remove(uint index) external {
    }

    function getSpecifyingRnd(
        uint _rndValue
    ) external view returns (address, uint) {
        uint rndValue = _rndValue % contractAddresses.length;
        address contractAddress = contractAddresses[rndValue];
        uint tokenId = tokenIds[rndValue];
        return (contractAddress, tokenId);
    }

    function get() external returns (address, uint) {
        uint rndValue = rnd() % contractAddresses.length;
        address contractAddress = contractAddresses[rndValue];
        uint tokenId = tokenIds[rndValue];
        return (contractAddress, tokenId);
    }

    function rnd() internal returns (uint) {
        _rnd += 1;
        return uint(keccak256(abi.encodePacked(block.number, _rnd)));
    }

    function hashState() external view returns (uint) {
        return uint(keccak256(abi.encodePacked(contractAddresses, tokenIds)));
    }
}