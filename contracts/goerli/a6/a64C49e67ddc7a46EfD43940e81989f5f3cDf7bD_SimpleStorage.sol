// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 public favouriteNumber;

    struct Person {
        uint256 favouriteNumber;
        string name;
    }

    Person[] public persons;

    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure keywords do not require gas to run because we are just asking to view the state not modify

    // view function is just to read state, disallows modification of state/storage/variable in blockchain

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // pure function disallows modification and reading of state/storage/variable in blockchain

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // calling view functions from inside of gas calling function will then cost gas for view functions also

    function store_with_gas(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
        retrieve();
    }

    // EVM (Ethereum Virtual Machine) store information in: memory, calldata, storage (CALL DATA KEYWORD)

    // memory and calldata are temporiraly holders for the values
    // storage value continue to exist even after after function code execution, the favouriteNumber defined on top is a storage
    // type of variable which continues the exist even after computation

    function add_person(string memory _name, uint256 _favouriteNumber) public {
        // solidity know uint256 is of "memory" type because solidity knows it is temporary storage
        // solidty does not knows the storing info type of arrays, struct and other mapping types
        // here string is an array of bytes that is why it needed memory keyword

        persons.push(Person(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // we can use calldata instead of memory if we do not change the value of _name

    //function add_person(string calldata _name, uint256 _favouriteNumber) public {
    //   _name = "change is not allowed when using calldata";
    //   persons.push(Person(_favouriteNumber,_name));
    //}
}