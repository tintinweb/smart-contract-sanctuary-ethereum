/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: BSD2
pragma solidity 0.8.7;

contract SimpleStorage {

    // This get initialiized to zero!
    uint256 favoriteNumber;

    mapping ( string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public pepole;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // `view` function only allow resding from blockchain (no modifications allow), and does not spend gas.
    // `pure` functions, in aditions to the above features also disallow reading the blockchain.
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // `memory` data short lived during the defined scope.
    // `calldata` same as memory, but immutable.
    // `storage` lives beyond the defined scope.
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People( { favoriteNumber: _favoriteNumber, name: _name} );
        //pepole.push(newPerson);

        pepole.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}