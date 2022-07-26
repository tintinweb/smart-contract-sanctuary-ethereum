// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 ID;
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;
    uint256 private currentID = 0;

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => string) public favoriteNumberToName;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(currentID, _favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        favoriteNumberToName[_favoriteNumber] = _name;
        currentID++;
    }

    function retrievePersonsNumber(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoriteNumber[_name];
    }

    function retrievePersonsName(uint256 _number)
        public
        view
        returns (string memory)
    {
        return favoriteNumberToName[_number];
    }

    function retrieveAPerson(uint256 _ID)
        public
        view
        returns (string memory, uint256)
    {
        People memory peopleToReturn;
        for (uint256 i = 0; i < people.length; i++) {
            if (people[i].ID == _ID) {
                peopleToReturn = people[i];
                break;
            }
        }
        return (peopleToReturn.name, peopleToReturn.favoriteNumber);
    }

    function returnAllPeople()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        uint256[] memory IDS = new uint256[](people.length);
        uint256[] memory favoriteNumbers = new uint256[](people.length);
        string[] memory names = new string[](people.length);

        for (uint256 i = 0; i < people.length; i++) {
            IDS[i] = people[i].ID;
            favoriteNumbers[i] = people[i].favoriteNumber;
            names[i] = people[i].name;
        }

        return (IDS, favoriteNumbers, names);
    }
}