/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract FlavorFactory {

    event NewFlavor(uint flavorId, string name, uint attributesId);

    uint attributesLength = 16;
    uint attributesModulus = 10 ** attributesLength;

    struct Flavor {
        string name;
        uint attributesId;
    }

    Flavor[] public Flavors;

    function _createFlavor(string memory _name, uint _attributesId) private {
        Flavors.push(Flavor(_name, _attributesId));
        uint flavorId = Flavors.length - 1;
        emit NewFlavor(flavorId, _name, _attributesId);
    }

    function _generateRandomAttributesId(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % attributesModulus;
    }

    function createRandomFlavor(string memory _name) public {
        uint randAttributes = _generateRandomAttributesId(_name);
        _createFlavor(_name, randAttributes);
    }

}