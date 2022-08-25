/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.14;

    contract Nadra {
    
    
    uint private playerCount=0;
    uint[] playerArray ;

   /** @dev Player structure is used to save details of Player
    *  @param name ,cnic ,dob , treenumber, addr store name, cnic 
    * number , date of birth , family treenumber and ethereum contract 
    * repectively
    */
    struct Player {     
     string  name ;
     uint cnic;
     uint dob;
     uint  treeNumber;
     address addr;
     }

   /** @dev Player_Details stores Player struc
    */

    mapping (uint  => Player) private Player_Details;

   /**
    * @dev function add_Details takes _name, _cnic, _dob, _addr in parameters

    */
    function add_Details(
     string memory _name, 
     uint _cnic,
     uint _dob, 
     uint _treeNumber,
     address _addr
     ) 
     public
     {

   /**@dev stored add_Details store _name, _cnic, _dob, _treeNumber, _addr in mapping Player
    */       
        Player_Details[playerCount] =Player(_name, _cnic , _dob, _treeNumber,_addr);    
        
        playerCount++;
     }

    function get_details(
     uint  _id)
     public 
     view 
     returns (Player memory )
     {
        return Player_Details[_id];
     }


    function test_function(
     string memory _randomString)
     pure
     public 
     returns (string memory )
     {
      string memory test_string= _randomString;
      return test_string;
}

    function  getAllPlayers()
     public
     view 
     returns (
     Player[] memory)
     {
     Player[] memory playerRecord = new  Player[](playerCount);

    for (uint i=0; i<playerCount ; i++){
     playerRecord[i]= Player_Details[i];
     }   
     return playerRecord;
     }
}