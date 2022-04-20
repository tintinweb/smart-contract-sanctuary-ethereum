/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier: MIT Licensed;

pragma solidity ^0.8.7;


contract Auction {

    address payable public owner ;
    address payable public highestBidder;

    uint public start_time ; 
    uint public end_time ;
    uint public highestBid;
    uint public hightestpayableBid;
    uint public bid_inc;




    enum status {bid_starting , bid_ending , running_bid, canceling_bid}
    status public stage ;

    constructor () 
    {
        owner =  payable(msg.sender);
        start_time = block.number;
        end_time= start_time + 11520;
        bid_inc = 1 ether;
        stage = status.running_bid;
    }

    modifier Owner ()
    {
        require( owner == msg.sender);
        _;
    }

    modifier NOtowner (){
    require(msg.sender != owner);
     _;
    }
    modifier running_bid (){
    require(block.number<end_time);
     _;
    }
    modifier bid_ending (){
    require(block.number>end_time);
     _;
    }


//  function End_Auction () public Owner 
//  {
//      stage = status.canceling_bid;
//  }


 function min ( uint a , uint b ) public pure  returns ( uint ){
     if ( a< b ) {
         return a;
     }
     else {
         return b;
     }
 }



function Bid () payable public NOtowner {
    require (stage == status.running_bid);
    require (msg.value >= 1 ether );


     uint new_Bidder_bid = Bids[msg.sender] + msg.value ;

    

    require ( new_Bidder_bid > hightestpayableBid);
    Bids[msg.sender] = new_Bidder_bid ;


     Array.push(payable(msg.sender));

    if ( new_Bidder_bid < Bids[highestBidder]){
        hightestpayableBid = min( new_Bidder_bid + bid_inc, Bids[highestBidder]);
    }
    else {
        hightestpayableBid = min(new_Bidder_bid, Bids[highestBidder] + bid_inc);
        highestBidder =  payable(msg.sender);
    }


}


 mapping(address=> uint ) public Bids;

 address [] public Array ;  


function getBIDERCount() public view returns(uint count) {
        return Array.length;
    }


  function Withdraw ( ) public {

 stage == status.bid_ending;
owner.transfer(hightestpayableBid);


for ( uint i = 0; i< Array.length; i++){
    if ( Array[i] == highestBidder )
    {
         payable( Array[i]).transfer(Bids[Array[i]]- hightestpayableBid);
    }
    if (Array[i] != highestBidder){
        payable( Array[i]).transfer(Bids[Array[i]]);
    }
}

  }

}