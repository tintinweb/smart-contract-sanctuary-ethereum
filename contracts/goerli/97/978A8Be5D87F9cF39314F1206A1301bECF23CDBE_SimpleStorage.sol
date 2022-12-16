// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // solidity verziju moramo obavezno staviti. Ako stavimo ^ ispred verzije znači da želimo da se vrti na svim verzijama od te na gore

// EVM, Ethereum Virtual Machine
// možemo Deploy na Avalanche, Fantom, Polygon

contract SimpleStorage {
    // bool, uint, int, address, bytes
    // po defaultu su varijable i funkcije internal
    uint256 favouriteNumber;

    // dictionary u koje se mapiraju 'favouriteNumber' na 'name'
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // dynamic array jer nismo rekli koliko elemenata ima
    People[] public people;

    // količina GAS-a ovisi o tome koliko je složena funkcionalnost
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view i pure funkcije ne troše GAS da bi se odradile. Praktički se koriste samo da bi se pročitala vrijednost s blockchaina. Nema transakcija.
    // GAS se plaća samo u slučaju da se view/pure funkcija poziva unutar smart contract funkcije
    // view - samo dohvaćanje vrijednosti, onemogućuje mijenjanje blockchaina
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // pure - onemogućuje mijenjanje blockchaina. Helper funkcije koje trebaju odradit neku kalkulaciju nevezanu za blockchain
    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // calldata - varijabla postoji samo privremeno unutar ove transakcije i ne može se modificirati (const)
    // memory   - varijabla postoji samo privremeno unutar ove transakcije i može se modificirati
    // storage  - varijable postoje i nakon izvršenja transakcije (funkcije). Gore 'favouriteNumber' je automatski castan u storage varijablu
    // ove varijable se koriste samo za arrays, structs i mapping type. uint će uvijek bit samo u memoriji
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}