/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SoulGem {
    //uint64 favoriteNumber = 4;
    People public horikita = People({favoriteNumber: 5, name: "Horikita"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // mapping
    // the string name is being mapped to the uint256 fav number
    mapping(string => uint256) public nameToFavoriteNumber;

    //array
    People[] public gente;
    uint64[5] public numeri;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //_name = "Kei"; = impossible if _name would be calldata
        gente.push(People(_favoriteNumber, _name));
        // kiyotaka = 3
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // view function (can read from the blockchain, cannot change it)
    function horikitaWaDare() public view returns (People memory) {
        return horikita;
    }

    // pure function (cannot read from the blockchain or change it)
    function printHorikita() public pure virtual returns (string memory) {
        string memory hori = "Horikita";
        return hori;
    }

    function returnNametoFavoriteNumber(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoriteNumber[_name];
    }

    /*  calldata, memory = var exists temporarily
        storage = exist even outside function

        calldata = temp var that can't be modified
        memory = temp var that can be modified
        storage = permanent var that can be modified

        memory only needed for array, struct or mapping type
    */
}