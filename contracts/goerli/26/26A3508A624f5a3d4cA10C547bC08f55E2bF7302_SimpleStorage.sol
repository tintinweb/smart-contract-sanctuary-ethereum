//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

//Stel je wilt een soldity versie gebruiken die 0.8.8 en der boven is is oke
// pragma solidity ^0.8.8
// Maar als je een solidity versie wilt in een bepaalde range
// pragma solidity >=0.8.0 <0.9.0;

//om een contract te definen moet je contract typen hierdoor weet solidity dat de volgende stukken code een contract zullen zijn
// een contract kun je zien als een classe
contract SimpleStorage {
    //Dit wordt dus geinitialiseerd naar 0
    uint256 public favoriteNumber; // uint256 favoriteNumber = 0; is het zelfde als uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People public person = People({favoriteNumber: 2, name: "Patrick"});

    //Storing verschillende mensen met verschillende favorietje nummers. Dit doe je met een struct.
    //Hierdoor hebben we een nieuw type namelijk"People"
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });

        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138