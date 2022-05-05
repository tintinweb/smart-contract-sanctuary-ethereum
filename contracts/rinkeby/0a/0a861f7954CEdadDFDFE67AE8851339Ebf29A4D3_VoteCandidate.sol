/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;


contract VoteCandidate {

        bool public is_vote = true;
        address owner; 
        struct candidate_detail { 
                string first_name; // ชื่อจริงผู้สมัคร
                string last_name; // นามสกุลผู้สมัคร
                string detail; // รายละเอียด นโยบาย
                string picture; // รูปภาพ
                uint number;  // หมายเลข
                uint score; // คะแนน
                uint timestamp;  // TimeStamp
        }
        
       struct voter {
        string employee_id; 
        string first_name;
        string last_name;
        bool is_vote;
        uint timestamp;
    }
    

    //[["first_name", "last_name","detail", "picture", 1, 0,1648559907] ]
    mapping(uint => candidate_detail) public candidate;
    // key = หมายเลขผู้ลงสมัคร, value = candidate_detail

    mapping(string => voter) public voters;
    // key = employee_id, value = voter

    event updateScore(candidate_detail val);

    string[] voter_all;
    // mapping(string => voter)[]  voter_all =[];


    // [["employee_id", "first_name","last_name", true, 1648559907] ]
    constructor(voter[] memory voter_, candidate_detail[] memory candidate_detail_, address address_owner){
        owner = address_owner;
        for (uint i = 0; i < voter_.length; i++) {
            voters[voter_[i].employee_id] = voter( 
                voter_[i].employee_id, 
                voter_[i].first_name, 
                voter_[i].last_name,
                voter_[i].is_vote, 
                voter_[i].timestamp);
        }

                for (uint i = 0; i < candidate_detail_.length; i++) {
            candidate[candidate_detail_[i].number] = candidate_detail( 
                candidate_detail_[i].first_name, 
                candidate_detail_[i].last_name, 
                candidate_detail_[i].detail, 
                candidate_detail_[i].picture, 
                candidate_detail_[i].number,
                candidate_detail_[i].score,
                candidate_detail_[i].timestamp);
        }

    }


     function set_is_vote(address address_owner) public {
         if(address_owner == owner){
            is_vote = !is_vote;
         }
         
     }


      function vote(string memory employee_id, uint number_candidate) public {
            require (is_vote == true,"Cannot vote because time out vote");
            require(voters[employee_id].is_vote == true, "You voted !!!!");
            candidate[number_candidate].score = candidate[number_candidate].score+1;
            voters[employee_id].is_vote = false;
            voters[employee_id].timestamp = block.timestamp;
            candidate[number_candidate].timestamp = block.timestamp;
            emit updateScore(candidate[number_candidate]);
    }


      function validate_permission_vote(string memory employee_id) public view returns ( voter  memory ){
          return voters[employee_id];
    }

    function  candidate_all() public view returns (candidate_detail memory, candidate_detail memory, candidate_detail memory, candidate_detail memory){
        return (candidate[1], candidate[2], candidate[3], candidate[4]);
    } 

    function voters_all()  public view returns (string[] memory ){

        return voter_all;
    }


}