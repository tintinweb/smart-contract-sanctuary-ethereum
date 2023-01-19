/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    function harvest(address _to) external; 
}

contract BeefyMultiStratHarvester {

    struct Config {
        uint256 lowerWaitForExec;
        uint256 upperWaitForExec;
        uint256 gasPriceLimit;
        uint256 lowerTvlLimit;
        uint256 upperTvlLimit;
    }

    Config public config;

    address public beefyTreasury; 
    address public owner;

    event Harvest(address[] indexed strats, uint256 time);

    constructor(
        address _treasury
    ) {
        beefyTreasury = _treasury;
        owner = msg.sender;
    }

    modifier onlyOwner {
         require(msg.sender == owner, "!Owner");
         _;
    }

    function encodeData(address one, address two, address three, uint num) external pure returns (bytes memory) {
        if (num == 1) {
            return abi.encode(one);
        } else if (num == 2) {
            return abi.encode(one, two);
        } else {
            return abi.encode(one, two, three);
        }
    }

    function decodeData(bytes memory _data, uint num) internal pure returns (address[] memory) {
        if (num == 1) {
            address[] memory strats = new address[](num);
            address decodedAddress = abi.decode(_data, (address));
            strats[0] = decodedAddress;
            return strats;
        } else if (num == 2) {
            address[] memory strats = new address[](num);
            (address one, address two) = abi.decode(_data, (address, address));
            strats[0] = one;
            strats[1] = two;
            return strats;
        } else {
            (address one, address two, address three) = abi.decode(_data, (address, address, address));
            address[] memory strats = new address[](num);
            strats[0] = one;
            strats[1] = two;
            strats[2] = three;
            return strats;
        }
    }

    function harvestMultiple(bytes memory _data, uint num) external {
        address[] memory strats = decodeData(_data, num);
        
        for (uint i; i < strats.length;) {
            try IStrategy(strats[i]).harvest(beefyTreasury) {} catch {}
            unchecked { ++i; }
        }

        emit Harvest(strats, block.timestamp);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setTreasury(address _treasury) external onlyOwner {
        beefyTreasury = _treasury;
    }

    // Sets harvester configuration
    function setConfig(Config calldata _config) external onlyOwner {
         config = _config;
    }
}