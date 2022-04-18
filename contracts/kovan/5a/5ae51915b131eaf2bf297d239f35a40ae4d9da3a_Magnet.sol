/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Magnet {

    mapping (string => bool) public known_magnet;
    mapping (string => mapping(string => string)) public known_name;

    event NewMagnetPublished(
        address indexed publisher,
        string indexed name1, 
        string indexed name2, 
        string magnet
    );

    /**
     * @dev Publish a new magnet link.
     */
    function publish(string calldata name1, string calldata name2, string calldata magnet) public {
        require(isEmpty(known_name[name1][name2]), "This name is already used");
        require(!known_magnet[magnet], "This magnet is already published");
        known_name[name1][name2] = magnet;
        known_magnet[magnet] = true;
        emit NewMagnetPublished(msg.sender, name1, name2, magnet);
    }

    /**
     * @dev Find a magnet by its name.
     */
    function lookup(string calldata name1, string calldata name2) public view returns (string memory) {
        require(!isEmpty(known_name[name1][name2]), "This name has no magnet link associated with it");
        return known_name[name1][name2];
    }

    function isEmpty(string memory _s) internal pure returns (bool) {
        return bytes(_s).length == 0;
    }
}