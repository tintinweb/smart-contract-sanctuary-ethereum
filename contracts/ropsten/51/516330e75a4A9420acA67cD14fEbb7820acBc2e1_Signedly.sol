/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Signedly{

    address owner;
    string file_hax;
    string doc_id;

    constructor() {
      owner = msg.sender;
   }
   
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   function read_owner() public view returns(address){
      return owner;
   }

   function set(string memory _hash, string memory _doc_id) public {
      file_hax = _hash;
      doc_id = _doc_id;
   }

}