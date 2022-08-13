//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // uint256 favoriteNumber = 5;
    // string favoriteNUmberInWords = "Five"; //strings are secretly just array of bytes only for texts
    // int256 myNumber = -5;
    // address myAddress = 0x03389E9fAd596020b1A23bD2D729A35B3f5e50AD;
    // bytes32 favoriteBytes = "cat" //Typically look like 0x.... but if not gets automatically converted to bytes, can be upto max 32

    //Gets initialized to 0
    //uint can have bits specified as to how many bits should be allocated for it to store, uint8/64/128/256, default is 256
    // public visibility specifier just creates a getter function for a variable
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 2, name: "Zee"});

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    //function <func name>() <visibility> returns (dataType) {}
    //https://docs.soliditylang.org/en/v0.7.3/contracts.html#visibility-and-getters
    // default visibility is internal, that is only current contract and it's child
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 1;
    }

    // view and pure notes that a function doesn't need to spend any gas.
    // view & pure both disallow any state modification, pure on the top of it also disallows reading from blockchain state
    // Pure is essentially a function with no state acccess or modification, like a generic util function
    // If a gas guzzling function calls a pure/view function only then will it cost gas
    function retrieveFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    function addBasic() public pure returns (uint256) {
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber:_favoriteNumber, name:_name});
        //people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //Data Location must be memory or calldata for paramters in function
    //EVM can access and store data info in six places: stack, memory, storage, calldata, code, logs
    //Only memory, calldata and storage can be specified. Memory and calldata are temp store only withing function scope, storage is permanent.
    //calldaya specified param cannot be modified but memory specified param can be.
    //Data location can only be specified for array, struct or mapping types.
}