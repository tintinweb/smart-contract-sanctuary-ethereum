// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlockchainCard {
    struct Person {
        string name;
        bool gender;
        string nationality;
        string history;
        string birthPlace;
        string image;
        string id;
        uint256 birthYear;
        uint256 birthMonth;
        uint256 birthDay;
    }

    mapping(string => mapping(string => Person)) private persons;
    mapping(string => string[]) private nationPopulation;

    address[] private owners;

    event getPerson(Person);

    constructor() {}

    function addNewOwner() external {}

    function removeOwner(address _owner) external {}

    function setPersonPassed(string memory _firstName, uint256 _id) external {}

    function addNewPerson(
        string memory _name,
        bool _gender,
        string memory _nation,
        string memory _birthPlace,
        string memory _image,
        string memory _id,
        uint256 _bY,
        uint256 _bM,
        uint256 _bD
    ) external {
        string memory history = "";
        persons[_nation][_id] = Person(
            _name,
            _gender,
            _nation,
            history,
            _birthPlace,
            _image,
            _id,
            _bY,
            _bM,
            _bD
        );
        nationPopulation[_nation].push(_id);
    }

    function movePerson(
        string memory _nation,
        string memory _id,
        string memory _toNation,
        string memory _toId
    ) external {
        persons[_toNation][_toId] = persons[_nation][_id];

        uint256 len = nationPopulation[_nation].length;
        for (uint256 i = 0; i < len; i++) {
            if (
                keccak256(abi.encodePacked(nationPopulation[_nation][i])) ==
                keccak256(abi.encodePacked(_id))
            ) {
                nationPopulation[_nation][i] = nationPopulation[_nation][
                    len - 1
                ];
                break;
            }
        }
        nationPopulation[_toNation].push(_toId);
    }

    function getPersonByIndex(string memory _nation, uint256 index)
        public
        view
        returns (Person memory)
    {
        uint256 cnt = nationPopulation[_nation].length;
        require(index < cnt, "Out of cnt");
        return persons[_nation][nationPopulation[_nation][index]];
    }

    function getNationCount(string memory _nation)
        public
        view
        returns (uint256)
    {
        return nationPopulation[_nation].length;
    }

    // function getPersonByName(string memory _nation, string memory _name)
    //     public
    // {
    //     uint256 i = 0;
    //     uint256 cnt = nationPopulation[_nation].length;
    //     for (; i < cnt; i++) {
    //         string memory id = nationPopulation[_nation][i];
    //         if (
    //             keccak256(abi.encodePacked(persons[_nation][id].name)) ==
    //             keccak256(abi.encodePacked(_name)) ||
    //             keccak256(abi.encodePacked(persons[_nation][id].secondName)) ==
    //             keccak256(abi.encodePacked(_name))
    //         ) {
    //             emit getPerson(persons[_nation][id]);
    //         }
    //     }
    // }

    function getPersonByID(string memory _nation, string memory _id)
        public
        view
        returns (Person memory)
    {
        return persons[_nation][_id];
    }
}