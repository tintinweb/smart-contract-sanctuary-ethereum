// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract UserDetails{
    address public owner; //creatore del corso
    uint256 private counter; //id dell'id


    constructor(){
        counter= 0;
        owner=msg.sender;
    }
   // Structure of employee
   struct Utente{
       
       // State variables
        address utente;    
        string username;
        string email;
        string hash;
   }

    event utenteCreato(
        address utente,
        string username,
        string email,
        string hash
    );


   
    mapping(uint256 => Utente) Utenti;
  
   // Function to add 
   // employee details
   function addUtente(
        address utente,
        string memory username,
        string memory email,
        string memory hash
   ) public{

        Utente storage newUtenti= Utenti[counter];
        newUtenti.hash=hash;
        newUtenti.email=email;
        newUtenti.username=username;
        newUtenti.utente=msg.sender;
        Utenti[counter]= newUtenti;
        counter++;
        emit utenteCreato(utente, username, email, hash);
   }
  
  // Function to get
  // details of employee
   function getUtente(address userid) external view returns(string[] memory _utenti){
        _utenti = new string[](counter);
        uint256 j=0;
        for (uint256 i = 0; i < _utenti.length; i++) {
            if(Utenti[i].utente==userid) 
            {
                _utenti[j] = Utenti[i].hash;
                j++;
            }
        }
        return _utenti;
   }


//    function changeDetails(string calldata oldHash,string calldata newHash,string calldata username,string calldata email) public returns(string memory)
//    {
//         for (uint256 i = 0; i <counter; i++) {
//             if (keccak256(abi.encodePacked(Utenti[i].hash)) == keccak256(abi.encodePacked(oldHash)))             
//             {
//                 Utenti[i].hash=newHash;
//                 Utenti[i].username=username;
//                 Utenti[i].email=email;
//                 return(Utenti[i].hash);
//             }
//         }
//    }
}