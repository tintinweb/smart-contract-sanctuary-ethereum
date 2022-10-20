/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public value; //automatically cast to a storage variable

    function setdata(uint x) public virtual {
        value = x;
    }

    function retrieve() public view returns (uint) {
        return value;
    }

    struct People {
        uint favNum;
        string name;
    }
    mapping(string => uint256) public nameToFavNum;
    People public person = People({favNum: 5, name: "Ujjawal"});
    People[] public PeopleArray;

    function setArray(string memory s1, uint fav) public {
        PeopleArray.push(People(fav, s1));
        nameToFavNum[s1] = fav;
        /*
        We can also do above as:
        People memory peoples=People(fav,s1); Order must be same
        OR
        People memory peoples=People(favNum:fav,name:s1);
        PeopleArray.push(peoples);
        */
    }

    /* There are six places where we can store data in Solidity
    3 important are
    Memory:Variable is temporary,Modification is possible. Used for Arrays, Strings, mappings, structs
    Calldata:Existence of Variable is temporary, Modification is not possible
    Storage: Exist even outside the given function, Can be modified, Most of times it's implicit






    /*
    View and Pure don't require Gas for execution
    But if a gas calling function calls a view or pure function
    ->then only it will cost gas 
    View Function-> Only read from the contract but disallows writting
    Pure Function-> Disallows reading as well as writting from contract
    Pure function mainly used for mathematical computation or algorithm 
    in which we don't require reading and writing
    Ex of Pure function:
    function viewdata() public pure returns(uint){
        return (1+1);
    }
    */
    function viewdata() public view returns (uint) {
        return value;
    }
}