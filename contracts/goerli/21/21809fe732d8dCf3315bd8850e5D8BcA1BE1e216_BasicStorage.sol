//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract BasicStorage {
    uint256 public favNumber;
    struct Guy {
        uint256 number;
        string name;
    }
    mapping(string => uint256) public nameToFavNumber;
    Guy[] public guys;

    function setFavNumber(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function addFavNumber(string calldata _name, uint256 _favNumber) public {
        nameToFavNumber[_name] = _favNumber;
        guys.push(Guy(_favNumber, _name));
    }

    function retrieveByName(
        string calldata _name
    ) public view returns (uint256) {
        return nameToFavNumber[_name];
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}