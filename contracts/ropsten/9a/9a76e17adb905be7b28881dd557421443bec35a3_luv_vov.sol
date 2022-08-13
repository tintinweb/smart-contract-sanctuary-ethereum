/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract luv_vov{
    address public owner;
    string name = "Hello";

  constructor ()  {
        owner = msg.sender;
  }

    function view_create_contract() external view returns(address) {
        return owner;
    }

    function view_name() public view returns(string memory) {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
        return name;
    }

    function mint_nft_start(uint x) public view returns(string memory){
        require(msg.sender == owner, "Ownable: Not start sale");
        require(x == 1, "Not 1");
        return "Start sale, GO!";

    }


}