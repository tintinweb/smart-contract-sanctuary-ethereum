// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    //basic types: boolean, uint, int address, bytes
    uint256 favoriteNumber; //is zelfde als uint256 favoriteNumber=0

    //met struct maak je een nieuwe data type met aangegeven attributen (zoals een object in python)
    // (object) People heeft 2 attributen: favoriteNumber en name
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // maken van array People en geven het een naam zodat ernaar gerevereerd kan worden zoals een variabele
    People[] public people;

    //maken van een mapping (ong zelfde als dictionary in pythin)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view functions veranderen nix op de blockchain, alleen bekijken
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // // pure functions veranderen nix op de blockchain en kunnen niet opgevraagd worden
    // function add() public pure returns (uint256) {
    //     return (1 + 1);
    // }

    //toevoegen van een nieuwe people variable in array People
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //People memory newPerson = People(_favoriteNumber, _name);
        //bovenstaande code kan versimpelt worden maar is wel minder expliciet
        //onderstaande code is een oneliner zonder keyword memory
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    //je kan data opslaan in: stack, memory, storage, calldata, code en logs
    // calldata en memory staan local(in de functie) variabele op alleen wanneer de functie aangeroepen word
    // storage variabele worden opgeslagen buiten de functie, bijf: geinitaliseerde variabelen binnen het contract
    // verschil tussen calldata en memory is dat calldata niet verandert kan worden, memory wel
    // dus calldata is tijdelijk en overanderlijk, memory is tijdelijk en veranderbaar, storage is permanent en veranderbaar
    // wanneer een string, array, struct of mapping gebruikt word moet dit worden aangegeven met memory, calldata of storage
}