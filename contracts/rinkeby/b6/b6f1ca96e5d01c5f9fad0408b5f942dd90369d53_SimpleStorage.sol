/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity 0.6.0 ;

contract SimpleStorage {
   // this will get initialized to 0!
    uint256  favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }


    People[] public leute;
    mapping(string => uint256) public nameToFavoritNumber;

    function store(uint256 _favoritNumber) public {
        favoriteNumber = _favoritNumber;   
        
    }

    //view, pure
    function retieve () public view returns(uint256){
        uint256 test;
        test = favoriteNumber + favoriteNumber;
        return test;

    }

    function addperosn (string memory _name, uint256 _favoritNumber) public{
        leute.push(People({favoriteNumber: _favoritNumber, name: _name}));
        nameToFavoritNumber[_name] = _favoritNumber;

    }
}