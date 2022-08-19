/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7; //Solidity version 0.8.8  ^means mentioned version and above , we can also do >= and <=

contract SimpleStorage {
        uint256 favoriteNumber; //This gets initialized to zero.

        mapping(string => uint256) public nameToFavoriteNumber;

        /* People public person1 = People({favoriteNumber:2,name: "Sansar"});
    People public person2 = People({favoriteNumber:7,name: "Maske"});
    */
        struct People {
                uint256 favoriteNumber;
                string name;
        }

        //uint256[] public favoriteNumberLists;
        People[] public people; //This is an dynamic array of type 'People'

        //To be able to override this function later, we need the function to be virtual
        function store(uint256 _favoriteNumber) public virtual {
                favoriteNumber = _favoriteNumber;

                //if this calls retrieve(), we have to pay gas for the retrieve()'s execution
        }

        //0xd9145CCE52D386f254917e481eB44e9943F39138

        //View and pure functions, when called alone doesn't spend gas. They disallow modifcation of the state.
        //Pure functions additionally disallow reading from the blockchain state
        function retrieve() public view returns (uint256) {
                return favoriteNumber;
        }

        function addPerson(string memory _name, uint256 _favoriteNumber)
                public
        {
                people.push(People(_favoriteNumber, _name));
                nameToFavoriteNumber[_name] = _favoriteNumber;
        }
}