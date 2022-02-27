// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;


contract Vote {

    uint number; 
         struct candidate_detail { 
            string first_name;
            string last_name;
            int number;
            string party;
            string picture;
            int score;
        }
        candidate_detail[]  candidate_vote ;


   constructor(){
        candidate_vote.push(candidate_detail("4Liq4Lir4Lij4Lix4LiV4LiZ4LmM","4Lib4Lij4Li44LiH4LmB4LiB4LmJ4Lin",1,"4Lie4Lix4LiB4Lic4LmI4Lit4LiZ4LmA4LiW4Lit4Liw","xxx", 0));
        candidate_vote.push(candidate_detail("4Lib4Lij4Liw4Lii4Li44LiX4LiY4LmM","4LiI4Lix4LiZ4LmC4Lit4LiK4Liy",2,"4Lib4Lij4Liw4LiK4Liy4Lij4Lix4LiQ","xxx", 0));
        candidate_vote.push(candidate_detail("4Lib4Li04Lii4Lia4Li44LiV4Lij","4LmB4Liq4LiH4LiB4LiZ4LiB4LiB4Li44Lil",3,"4LiB4LmJ4Liy4Lin4LmE4LiB4Lil","xxxx", 0));
   }

    function voteCandidate(uint number_candidate) public {
        candidate_vote[number_candidate].score = candidate_vote[number_candidate].score+1;
    }


    function getAllCandidate() public view returns (candidate_detail[] memory){
        return candidate_vote;
    }

    
}