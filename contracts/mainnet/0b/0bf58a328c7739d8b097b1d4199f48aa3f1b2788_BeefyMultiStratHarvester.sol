/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    function harvest(address _to) external; 
}

contract BeefyMultiStratHarvester {
    address public beefyTreasury; 
    address public owner;

    constructor(
        address _treasury
    ) {
        beefyTreasury = _treasury;
        owner = msg.sender;
    }

    function endcodeData(address one, address two, address three, uint num) external pure returns (bytes memory) {
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
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "!Owner");
        owner = _newOwner;
    }

    function setTreasury(address _treasury) external {
        require(msg.sender == owner, "!Owner");
        beefyTreasury = _treasury;
    }

}