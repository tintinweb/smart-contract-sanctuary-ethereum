/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Topics covered: Types, Variables, Functions.

contract SimpleStorage {
    // Types:
    // boolean, uint, int address, bytes
    // Solidity is a strictly typed language,
    // so we need to type it when its declared.
    // Strings are basically Bytes non-fixed arrays.
    // Bytes arrays could also be fixed up to 32 bytes.

    uint8 public favoriteNumber;

    // Structs.
    // Structs are generally structures of data.

    People public person = People({favoriteNumber: 2, name: "Alex"});
    struct People {
        uint8 favoriteNumber;
        string name;
    }

    // Arrays.
    // Arrays could be fixed[x] and non-fixed [].
    People[] public people;

    // Mappings.
    // Mappings are essentially a dictionary.
    // For mapping we have to specify key => velue types.

    mapping(string => uint8) public nameToFavoriteNumber;

    // Functions.
    // Every function in Solidity SHOULD have a visibity option.
    // While variables CAN have a visibility option as well.
    // public - means visible externaly (getter) and internaly,
    // private - only visible in the current contract,
    // external - only visible externaly (ff via this.func),
    // internal - only visible for contract and children.

    // Scope of functions and contracts are defined by {}.

    function store(uint8 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // There are other keywords used in Solidity functions:
    // view - defines that function is only reading data.
    // pure - not even gets data from blockchain.
    // These functions are gas-free, unless we use other functions.
    // If the function should return smth, we should specify it.

    function retrieve() public view returns (uint8) {
        return favoriteNumber;
    }

    // Parameters of the function could also take keywords
    // for data location specification:
    // memory - is used to keep parameter only in memory.
    // calldata - as well temporarily but can't be modified.
    // storage - permament variables that could be modified.
    // Location can only be specified for array, struct or mapping.

    function addPerson(string memory _name, uint8 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}