// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // ^ is for 0.8.8 and 0.8.9

// EVM: Etherium Virtual Machine
// Avalance, Fantom, Polygon

contract SimpleStorage {
    // Types: boolen, uint(just positive), ,int, address, bytes, address

    bool O_hasFavoriteNumber = true;
    uint256 O_favoriteNumber = 53;
    uint256 O_favoriteNumber_256 = 53; // with uint we can choose alloceting space for this data
    int256 O_favoriteNumber_Int = -53;
    string O_favoriteNumberInText = "fiftythree";
    address O_myAddress = 0xAE8dC4c95CCc79b39445fe9BD457FA22dbE87Ae7;
    bytes32 O_favoriteBytes = "cat";

    uint256 O0_favoriteNumber; // gets initialized to 0 ----- INTERNAL (DEFAULT)
    uint256 public favoriteNumber; // change visibilty to everyone --- PUBLIC

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 53, name: "yunus"});

    People public davinci = People({favoriteNumber: 1453, name: "davinci"});

    uint256[] public someNumbers;
    People[] public peopleArray; // dynamic array. we can add person how much we want
    People[3] public peopleLimited; // fixed array. we can add just 3 person.

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        People memory somePerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });

        // People memory newPerson = People(_favoriteNumber,_name);// this is same as above.....

        peopleArray.push(somePerson);
        // calldata: TEMPORARY but CANT be modifed
        // memory: TEMPORARY but CAN be modifed
        // storage: permenant

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure not spend gas.
    // view and pure dont allow change state of chain
    // pure also can not allow the read the state
    // BUT IF WE CALL THESE FUNTIONS FROM OTHER FUNCTIONS WE NEED TO PAY GAS. // (50323 --> 50484)
    function retrieveView() public view returns (uint256) {
        // favoriteNumber += 1; NOT ALLOWED
        return favoriteNumber;
    }

    function retrievePure(uint256 wow) public pure returns (uint256) {
        // return favoriteNumber; NOT ALLOWED
        return wow + 5;
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138 contracts are being deployed to addresses.
}