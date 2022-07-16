// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //Stable version of solidity(it keeps on changing)
 
contract SimpleStorage {
      // solidity types : mainly 5 types boolean(t/f),uint(unsigned integer),int,address(address of wallet),bytes

        // this gets initialised to zero
    uint256 favouriteNumber;
    //People public person = People({favouriteNumber: 2, name: "uday"});

    mapping(string => uint256) public nameToFavouriteNumber; // mapping is a ds with which we can map a parameter to another
        // string is mapped to uint256

    struct People{
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual { // virtual keyword is necessary to specify if a function can be override
        favouriteNumber = _favouriteNumber;
    }
        // view, pure (no gas fees) disallow any modification in blockchain
        // pure disallows to read from blockcahin state
        // view can only read and return values
    function retrieve() public view returns (uint256){
        return favouriteNumber;

    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public{
       People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
       // People memory newPerson = People({_favouriteNumber, _name}); (we put variable in order they appear)
       // people.push(People(_favouriteNumber, _name));
       people.push(newPerson);
       // calldata(temp with non-modifiable data), memory (temp with modifiable data)
       //(these two are temporary storage and are cleared after functoin use), storage(more than function storage) 
       // structs mapping and arrays should be given memory or calldata keyword
        nameToFavouriteNumber[_name] = _favouriteNumber;
       
    }

    
    
   
}