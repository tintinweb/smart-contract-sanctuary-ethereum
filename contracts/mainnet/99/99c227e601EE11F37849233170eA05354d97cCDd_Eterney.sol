/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Eterney {
    // Contract name
    string public  name = 'Eterney';

    uint public peopleCount = 0;
    mapping(uint => Person) public people;

    struct Person {
        string name;
        string dates;
        string bio;
    }

    mapping(address => uint[]) public userSubmissions;

    mapping(bytes32 => uint[]) public searchByHash;

    // Address of admin account
    address public admin;
    //Contract fee
    uint public fee = 0;

    modifier isAdmin {
        require(admin == msg.sender, "not-an-admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Function to add a person
    function addPerson(string memory _name, string memory _dates, string memory _bio) external payable {
        require(msg.sender != address(0));
        require(msg.value == fee, 'The payment is lower than the contract fee');
        // Make sure file name exists
        require(bytes(_name).length > 0, 'The name can not be empty');
        // Make sure dates is more than 0
        require(bytes(_dates).length > 0, 'The dates can not be empty');

        people[peopleCount] = Person(_name, _dates, _bio);

        userSubmissions[msg.sender].push(peopleCount);

        bytes32 hash = hashIt(_name);
        searchByHash[hash].push(peopleCount);

        // Increment peopleCount
        peopleCount ++;
    }

    // Function to delete a person (just deletes name)
    function deletePerson(uint _id) external isAdmin {
        require(_id < peopleCount, 'Id must exist');
        people[_id].dates = '';
    }

    function getPeopleByIds(uint[] memory _ids) external view returns (Person[] memory _people) {
        _people = new Person[](_ids.length);

        for (uint index = 0; index < _ids.length; index++) {
            uint id = _ids[index];
            _people[index].name = people[id].name;
            _people[index].dates = people[id].dates;
            _people[index].bio = people[id].bio;
        }
    }

    // Returns user submissions or search result paginated
    function getUserOrSearchSubmissionsPaginated(bool _isSearch, string memory _name, uint _page, uint _resultsPerPage) external view returns (
        uint totalAmountOfSubmissions,
        Person[] memory submissions,
        uint[] memory ids){

        bytes32 hash;
        if (_isSearch) {
            hash = hashIt(_name);
            totalAmountOfSubmissions = searchByHash[hash].length;
        } else {
            totalAmountOfSubmissions = userSubmissions[msg.sender].length;
        }

        if (_page == 0 || _resultsPerPage == 0) {
            return (totalAmountOfSubmissions, new Person[](0), new uint[](0));
        }

        uint _index = _resultsPerPage * _page - _resultsPerPage;

        // return empty array if already empty or _index is out of bounds
        if (
            totalAmountOfSubmissions == 0 ||
            _index > totalAmountOfSubmissions - 1
        ) {
            return (totalAmountOfSubmissions, new Person[](0), new uint[](0));
        }

        submissions = new Person[](_resultsPerPage);
        ids = new uint[](_resultsPerPage);
        // start starting counter for return array
        uint _returnCounter = 0;
        // loop through array from starting point to end point
        for (
            _index;
            _index < _resultsPerPage * _page;
            _index++
        ) {
            // add array item unless out of bounds if so add uninitialized value (0 in the case of uint)
            if (_index < totalAmountOfSubmissions) {
                uint reversedIndex = totalAmountOfSubmissions - 1 - _index;
                uint id;
                if (_isSearch) {
                    id = searchByHash[hash][reversedIndex];
                } else {
                    id = userSubmissions[msg.sender][reversedIndex];
                }

                submissions[_returnCounter] = Person({
                name : people[id].name,
                dates : people[id].dates,
                bio : people[id].bio
                });
                ids[_returnCounter] = id;
            }
            _returnCounter++;
        }
        return (totalAmountOfSubmissions, submissions, ids);
    }

    // Function to withdraw contract balance
    function withdraw(uint _value) external isAdmin {
        require(address(this).balance >= _value, 'Not enough funds to withdraw');
        payable(msg.sender).transfer(_value);
    }

    // Function to change contract fee
    function changeFee(uint _fee) external isAdmin {
        require(fee != _fee, "Fee must be different");
        fee = _fee;
    }

    function hashIt(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}