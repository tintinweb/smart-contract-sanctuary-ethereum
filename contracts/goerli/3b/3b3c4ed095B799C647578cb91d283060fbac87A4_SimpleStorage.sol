// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

contract SimpleStorage{
    //types of data in solidity. boolean, uint, int, address, bytes
    uint256 public FavoriteNumber ; // since we didnt assign any value, the default value is zero at this point
    // visibility is internal by default. You can have either public, private, external or internal
    // a getter function would be automatically created
    //people public person = people({FavoriteNumber: 2, name: "Tochi"});
    // array is a better way to create lists

    uint256[] favoriteNumbersList;
    //the best way to create a list is to use an array
    People[] public people;

    // mapping is a data structure wwhere a key is mapped to a single value
    // you can think of it as a dictionary
    mapping(string => uint256)  public nameToFavoriteNumber;


    struct People{
            uint256 FavoriteNumber;
            string name;
        }
    // function

    function store( uint256 _favoriteNumber)public virtual{
        FavoriteNumber = _favoriteNumber;
        //we made the function virtual to make it overidable
        

        

    } // change the value of favorite number to new value

   // function something() public{
     //   testVar = 6; 
    //} // this variable cannot see testvar because it is outside the store function

    // view and pure don't require gas to run. however 'store' requires gas to run
    function retrieve() public view returns(uint256){
      return FavoriteNumber;  

    }


    function addPerson(string memory _name, uint256 _favoriteNumber)public {
     People memory newPerson = People({FavoriteNumber: _favoriteNumber, name: _name});
     people.push(newPerson);
     nameToFavoriteNumber[_name] = _favoriteNumber;
    }



//----------------------------------------------
// evm compatible blockchains. Avalancche, fantom and polygon



}