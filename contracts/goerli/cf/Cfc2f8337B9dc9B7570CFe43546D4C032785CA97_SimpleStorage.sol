/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A contract to store my friends and their fav colors
contract SimpleStorage {
  // my fav color
  string myFavoriteColor;

  // Friend constructor
  struct Friend {
    string favoriteColor;
    string name;
  }
  Friend[] public friends;

  // maps name to fav color
  mapping(string => string) nameTofavoriteColor;

  // store my fav color
  function store(string memory _favoriteColor) public virtual {
    myFavoriteColor = _favoriteColor;
  }

  // get my favorite color
  function retrieveMyFavColor() public view returns (string memory) {
    return myFavoriteColor;
  }

  // add a new friend to my list
  function addFriend(string memory _name, string memory _favoriteColor) public {
    friends.push(Friend(_favoriteColor, _name));
    nameTofavoriteColor[_name] = _favoriteColor;
  }

  // get friends favorite color given name
  function getFriendFavoriteColor(string memory _name)
    public
    view
    returns (string memory)
  {
    return nameTofavoriteColor[_name];
  }
}