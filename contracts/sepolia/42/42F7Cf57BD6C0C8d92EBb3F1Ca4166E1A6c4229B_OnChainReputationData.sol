/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

pragma solidity ^0.4.26;

contract OnChainReputationData{

    //struct to store the aggr score with seller id and 
    //mapping of seller id to uint score

    //function to add aggr score (passes seller id and aggr score)

    //function get_rep_score(seller_id) returns the aggr score (uint)
    mapping(uint => uint) seller_score;
    uint [] scoreArr;

    function add_rep_data(uint _seller_id, uint _score){
        seller_score[_seller_id] = _score;
        scoreArr.push(_seller_id) -1;
    }

    function get_rep_data(uint _seller_id) returns (uint) {
        return seller_score[_seller_id];
    }

}