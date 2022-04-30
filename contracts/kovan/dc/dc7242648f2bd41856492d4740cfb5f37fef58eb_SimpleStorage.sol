/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.6.0;

//Create a contract that stores a users name and their favorite food
// mapping/dictionary to store the useras the key and the food as it's value
// store each user in a users array
contract SimpleStorage{
    mapping(string=>string) public userToFoodMapping;
    
    //userToFoodMapping[] users;

    function storeUsersToFavoriteFood(string memory username, string memory userFavFood) public {
        userToFoodMapping[username] = userFavFood;
    }
    
}