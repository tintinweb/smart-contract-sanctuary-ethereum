/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier: MIT Licensed

pragma solidity ^0.8.7;

contract Bidding {

    address payable public Seller;
    address payable public highestBidder;
 

    uint public start_time;
    uint public end_time;
    uint  public highestBid;
    uint public hightestpayableBid;
    uint public bidIncreament;

  address[] public AllBiders;

    mapping(address => uint) public bids;
     mapping(uint256 => address) private owners;
      mapping(address => uint256) private balances;

    event Transfer (address indexed from, address indexed to, uint256 tokenId);
    enum status {start, end , running , cancel }
    status public stage;



    constructor(){
   Seller = payable(msg.sender);
   start_time = block.number;
   end_time = start_time + 2576;
   bidIncreament = 1 ether;
   stage = status.running;
}


modifier seller (){
    require(msg.sender == Seller);
    _;
}
modifier NOtseller (){
    require(msg.sender != Seller);
     _;
}
modifier running (){
    require(block.number<end_time);
     _;
}
modifier ending (){
    require(block.number>end_time);
     _;
}


  function min(uint a, uint b)
        private
      
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

      function _exists(uint tokenId) internal view virtual returns (bool) {
        return owners[tokenId] != address(0);
    }

 function mint(address to, uint256 tokenId) public virtual {
        require(to != address(0), "ERC721: Address belongs to zero");
        require(!_exists(tokenId), "Token Already Exists");

        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

    }
      function balanceOf(address owner) public view virtual  returns (uint256) {
        return balances[owner];
    }


function bid() payable public  NOtseller running{
    require(stage == status.running);
    require(msg.value >= 1 ether);


    uint newBid = bids[msg.sender] + msg.value;


    require (newBid > hightestpayableBid ) ;

     bids[msg.sender] = newBid;

     AllBiders.push(payable(msg.sender));

    if(newBid<bids[highestBidder]){

        hightestpayableBid = min(newBid + bidIncreament , bids[highestBidder]);
    }
    else{
        hightestpayableBid = min(newBid , bids[highestBidder] + bidIncreament );
        highestBidder = payable(msg.sender);



    }
   


    

}
 function getBIDERCount() public view returns(uint count) {
        return AllBiders.length;
    }




function widraw() public returns( string memory) {
    
   
   Seller.transfer(hightestpayableBid);
    
    for(uint i=0; i<=AllBiders.length; i++ ) {
  
      

        if( AllBiders[i] == highestBidder ){
        
           
           payable(AllBiders[i]).transfer(bids[AllBiders[i]]- hightestpayableBid);
          
            return "successfully widraw completed";

        }
        if(AllBiders[i]!= highestBidder)
        {
            
     
             payable(AllBiders[i]).transfer(bids[AllBiders[i]]);
            //    return "hi 2 for if";
        }

      
       

    }
     

    

}


}