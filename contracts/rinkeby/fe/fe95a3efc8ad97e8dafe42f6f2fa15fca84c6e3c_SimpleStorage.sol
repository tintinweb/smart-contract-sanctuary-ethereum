/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {

    // This gets initializes to zero.
    uint256 public favoriteNumber;

    People[] public people;
    mapping(string => uint256) public nameToFavNumber;
    struct People{
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
    }

    // view functions does not cost anything to run(when not run by a contract, which is another function that make modifications to the chain)
    // can only view(return) the data on the chain, but not modifying it.
    function retreive() view public returns(uint256){
        return favoriteNumber;
    }
    // pure functions has all limiteations of view functions, but with one more restriction:
    // You cannot view anything on-chain either. 
    // A "pure" functions is analogous to a "helper" function in a triditional-programming-language sense, 
    // where they are used to minimize repetitive code(adder, xor, etc.)
    //TODO:
    //      1. Why having completely identical logics, a pure function costs more to run than view function?
    function add_pure(uint256 num1, uint num2) public pure returns (uint256){
        return num1 + num2;
    }

    // There are three types of memory the data can be stored in: calldata, memory, storage
    // calldata and memory only exists during the TRANSACTION that this function is called.
    //      calldata(temp var): like read-only variable that cannot be re-assigned once set. Perfect for function parameters.
    //      memory(temp var): can be changed, but will be gone after a transaction is complete.
    // storage variable will exist no matter if there is a function is executed.
    //      storage(perm var): can be modified, and will continue to exist cross-transaction.
    //
    // We only need to specify the storage location of array, struct and mapping types.
    // and string in solidity is a byte array.
    //
    // In function parameters, only memory or calldata can be given because it is not getting stored anywhere
    // TODO: 
    //      1. When a struct instance is instantiated and placed in storage, after the function is complete, how to access it in the future? 
    //      2. How does storing it in the storage change the logic?
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);
        //OR
        //people.push(People(_favouriteNumber, _name));

        nameToFavNumber[_name] = _favouriteNumber;
    }
}