//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// ^0.8.7 - any version above specified
// >=0.8.7 <0.9.0 - any version between

// docs.soliditylang.org/en/v0.8.13/types.html
// boolean, uint, int, address, bytes
// bool hasFavoritr = true
// uint v1 = 5
// int v2 = -5
// string v3 = "five"
// bytes32 v4 = "cat"

contract SimpleStorage {
    uint256 favoriteNumnber; //automatically defined as storage if not indicatated smth else

    People public person = People({favoriteNumnber: 1, name: "Patrik"});

    mapping(string => uint256) public nameToFavoriteNumber; // Storage type

    struct People {
        uint256 favoriteNumnber;
        string name;
    }

    People[] public persons;

    //function changes state and costs some gas
    //more computation is required the  more gas it needs
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumnber = _favoriteNumber;
    }

    // view, puredo not make any changes to state and do notrequire gas
    // unless they are call from changing a state function
    function retrieve() public view returns (uint256) {
        return favoriteNumnber;
    }

    // pure - does not need access to the contract at  all
    function adding() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumnber: _favoriteNumber,
            name: _name
        });
        persons.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
// Smart Contract Address

// bochkoviy ogurcy

// calldata, memory, storage
// calldata temporary variable can NOT be modified
// memory temporary variable can be modified.
// can de specified onnly for : array, struct, mapping

// Etherscan 0x883d074cA530507fd9Ebadc18C13d8d403A50778