// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {Asset} from "./Asset.sol";

contract Factory {
    address public immutable OBSERVER;

    event FactoryConstructed(address indexed observer, bytes code);

    event AssetCreated(
        address indexed at,
        uint256 id,
        string holder,
        uint256 key
    );

    mapping(address => uint256) public assets;
    mapping(uint256 => address) public contracts;

    constructor(address _observer) {
        OBSERVER = _observer;
        bytes memory code = type(Asset).creationCode;
        emit FactoryConstructed(OBSERVER, code);
    }

    function deploy(
        uint256 _id,
        string memory _holder,
        string memory _symbol,
        string memory _name
    ) public returns (address) {
        bytes memory args = abi.encodePacked(_id, _holder, _symbol, _name);
        uint256 key = uint256(keccak256(args));
        address old = contracts[key];
        if (old != address(0)) {
            return old;
        }

        Asset asset = new Asset{salt: bytes32(key)}(_symbol, _name);
        asset.transfer(OBSERVER, asset.totalSupply());
        address addr = address(asset);
        assets[addr] = key;
        contracts[key] = addr;
        emit AssetCreated(addr, _id, _holder, key);
        return addr;
    }
}