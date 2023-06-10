// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {
    address public owner;
    address public winnerAddress;
    string public eventName;
    uint public totalVote;
    bool votingStarted;
    // bool finaldata=false;

    struct Candidate {
        string name;
        uint age;
        bool registered;
        address candidateAddress;
        uint votes;
        uint id;
        uint aadarNum;
        
    }

   struct Transation{
       address from;
       address to;
       uint time;
   }


    struct Voter {
        bool registered;
        address VoterAddress;
        bool voted;
         string name;
        uint aadarNum;
         address giveVote;
         bool  winner_data ;
    }

    event success(string msg);
    mapping(address => uint) public candidates;
    Candidate[] public candidateList;
     mapping  (address => uint) public votermap;
   
    Voter[] public voterinfo;


    Candidate[] public winnerList;
    Transation [] public  transation;
    mapping (  uint => address) public aadartocandidates;
    mapping (  uint => address) public aadartoaddress;

    
    constructor(string memory _eventName) {
        owner = msg.sender;
        eventName = _eventName;
        totalVote = 0;
        votingStarted = false;
    }





    function registerCandidates(
        string memory _name,
        uint _age,
        address _candidateAddress,
        uint _aadarNum
    ) public {
        require(msg.sender == owner, "Only owner can register Candidate!!");
        require(_candidateAddress != owner, "Owner can not participate!!");
        require(
            candidates[_candidateAddress] == 0,
            "Candidate already registered"
        );
        require(aadartocandidates[_aadarNum]==0x0000000000000000000000000000000000000000,"  This aadar has been used ");
       
       
        Candidate memory candidate = Candidate({
            name: _name,
            age: _age,
            registered: true,
            votes: 0,
            candidateAddress: _candidateAddress,
            id: candidateList.length,
            aadarNum: _aadarNum
            
        });
          aadartocandidates[_aadarNum]=_candidateAddress;
                  if (candidateList.length == 0) {
            //not pushing any candidate on location zero;
            candidateList.push();
        }

        candidates[_candidateAddress] = candidateList.length;
        candidateList.push(candidate);
        emit success("Candidate registered!!");
    }

function whiteListAddress(address _voterAddress, string memory _name, uint _aadarNum ) public {
        require(_voterAddress != owner, "Owner can not vote!!");
        require(
            msg.sender == owner,
            "Only owner can whitelist the addresses!!"
        );
        require(
           
                 votermap[_voterAddress]==0,
            "Voter already registered!!"
        );
        require(aadartoaddress[_aadarNum]==0x0000000000000000000000000000000000000000,"  This aadar has been used ");
           
         if (voterinfo.length == 0) {
            //not pushing any candidate on location zero;
            voterinfo.push();
        }

        Voter memory voter = Voter({registered: true, voted: false,name: _name,aadarNum:_aadarNum, giveVote:0x0000000000000000000000000000000000000000,VoterAddress:_voterAddress,winner_data:false});

          aadartoaddress[_aadarNum]=_voterAddress;

            votermap[_voterAddress]=voterinfo.length;

         voterinfo.push(voter);
        emit success("Voter registered!!");
    }

    function startVoting() public {
        require(msg.sender == owner, "Only owner can start voting!!");
        if (votingStarted == true) {
            emit success("Voting already  Start!!");
        } else {
            votingStarted = true;
            emit success("Voting Started!!");
        }
    }

    function winner() public {
        uint can_len = candidateList.length;
        uint max = 0;
              uint len = winnerList.length;
                    while (len > 0) {
                        winnerList.pop();
                        len--;
                    }



        for (uint j = 1; j < can_len; j++) {
            if (candidateList[j].votes == max) {
                winnerList.push(candidateList[j]);
            } else {
                if (candidateList[j].votes > max) {
                    uint len1 = winnerList.length;
                    while (len1 > 0) {
                        winnerList.pop();
                        len1--;
                    }
                    winnerList.push(candidateList[j]);
                    max = candidateList[j].votes;
                }
            }
        }
    }
      

    function putVote(address _candidateAddress) public {
        require(votingStarted == true, "Voting not started yet or ended!!");
        require(msg.sender != owner, "Owner can not vote!!");
        require(
           
              votermap[msg.sender]!=0, "Voter not registered!"


        );
       
        require(voterinfo[votermap[msg.sender]].voted==false ,"Already voted!!");

        require(
            candidateList[candidates[_candidateAddress]].registered == true,
            "Candidate not registered"
        );

        candidateList[candidates[_candidateAddress]].votes++;
        totalVote++;
       voterinfo[votermap[msg.sender]].voted = true;
        voterinfo[votermap[msg.sender]].giveVote = _candidateAddress;


        winner();
    



          Transation  memory t= Transation({
              to: _candidateAddress,
              from: msg.sender,
              time: block.timestamp
          }); 
          transation.push(t);

        emit success("Voted !!");
    }




   

    function stopVoting() public {
        require(msg.sender == owner, "Only owner can start voting!!");

        if (votingStarted == false) {
            emit success("Voting already stoped!!");
        } else {
            votingStarted = false;
            winner();
            emit success("Voting stoped!!");
        }
    }
   




  function d() public 
    {
         
      require(votingStarted!=true, " Voting  is on going ");

       winner();
     for ( uint i=0; i<voterinfo.length;i++)
     {
          
          
           Voter memory  d=voterinfo[i];
             for ( uint k=0;k<winnerList.length;k++)
             {
                   if (d.giveVote==winnerList[k].candidateAddress)
                   {
                       d.winner_data=true;
                       break ;
                   }
             }
          voterinfo[i] = d;
              



     }        


        



  }
    


    function getAllCandidate() public view returns (Candidate[] memory list) {
        return candidateList;
    }

    function votingStatus() public view returns (bool) {
        return votingStarted;
    }

    function removeCandidates(address _candidateAddress) public {
        require(
            msg.sender == owner,
            "Only owner can  remove register Candidate!!"
        );
        require(votingStarted == false);
        uint number = candidates[_candidateAddress];

        candidateList[candidateList.length - 1].id = candidates[_candidateAddress];
        candidateList[number] = candidateList[candidateList.length - 1];

        candidateList.pop();
        candidates[_candidateAddress] = 0;
        winner();

        emit success("Candidate removed!!");
    }

    function getAllWinner() public view returns (Candidate[] memory list) {
        return winnerList;
    }
    function TransationList() public view returns (Transation[] memory list) {
        return transation;
    }
   


function getAllVoter() public view returns ( Voter[] memory list) {
        return voterinfo;
    }

//    function onlyinfo(  ) public view returns (Voter memory) {
//          uint d=votermap[msg.sender];
//         return voterinfo[d];
//     }


     function onlyinfo( address d ) public  view  returns (Voter memory)
      {
          return voterinfo[votermap[d]];
        
    }




}