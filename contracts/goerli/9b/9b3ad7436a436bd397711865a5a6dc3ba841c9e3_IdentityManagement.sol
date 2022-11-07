/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

contract IdentityManagement {

    address MHRE;

    constructor() {
        MHRE = msg.sender;
    }

    struct Client {
        uint aadharNo;
        uint picHash;
        uint like;
    }

    struct Agency {
        uint agencyNo;  //4 digit random code
        string  name ;
        string description;
    }

    mapping(address => Client) clientdb;
    address[] clientAddr;
    
    mapping  (address => Agency)public Agencydb ;
    address[] AgencyAddrlist;
    mapping(address=>bool)AgencyAddr;
    mapping(uint =>bool)agencyNolist;
    
    // function addAgency()
    function addAgency(address ag_add,string memory name,string memory description) public isOwner{
        uint time=block.timestamp;
        uint num=(time%10000);
        uint agencyNo = checkRandom(num);
        Agencydb[ag_add]=Agency(agencyNo,name,description);
        AgencyAddr[ag_add]=true;
        AgencyAddrlist.push(ag_add);
        }   

    //function to check random number    
    function checkRandom(uint num)internal  returns(uint){
        while (agencyNolist[num]==true) {
             // while loop
                num=num+1;
                if(num >=10000){
                    num=0;
                }
            }
            agencyNolist[num]=true;
            return num;
        }
    
    modifier isOwner() {
        require(msg.sender == MHRE, "Caller is not owner");
        _;
    }
     //function to view agency
        function viewAgencyPresntinArray (uint index)public  view returns(Agency memory){ 
            address agency_add=AgencyAddrlist[index];
            return Agencydb[agency_add];
     }

     //function to add client based by agency
    function addclient(address client_add,uint adhar,uint hashpic)public  {
        require(AgencyAddr[msg.sender],"Only Register agency can add"); // only registered agency can add the client 
        clientdb[client_add]=Client(adhar,hashpic,1);
        clientAddr.push(client_add);

    }
    //check the client details based on address for registered agency 
    function viewclient(address client) public view returns(Client memory){
        require(AgencyAddr[msg.sender]);
        return clientdb[client];

    }
    //check the client data and match
    function validateClientData(address client,uint adhar,uint hashpic) public returns(uint)
    {
       uint ad=clientdb[client].aadharNo;
       uint hash1=clientdb[client].picHash;
       if(ad==adhar && hash1==hashpic)
       {      
         clientdb[client].like= clientdb[client].like+1;
         return(clientdb[client].like);

       }
       else
       {
           clientdb[client].like= clientdb[client].like-1;
            return(clientdb[client].like);
       }

    }


}