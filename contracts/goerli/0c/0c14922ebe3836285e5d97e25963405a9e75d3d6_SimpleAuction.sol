/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: auction.sol


pragma solidity ^0.8.7;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

// contract MyToken is ERC20  {
//     address public admin;
    
//         //_setupDecimals(2);
        
// //     }

contract SimpleAuction{
    address payable public beneficiary=payable(msg.sender);
    uint public auctionEndTime;

    address payable public highestBidder;
    uint public highestBid;

    mapping(address => uint) public pendingReturns;
    bool ended = false;

    event HighestBidIncrease(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // constructor(address payable _benef)
    // {
    //     beneficiary=_benef;
    // }
    // constructor() ERC20("VIT VLR","VLR"){
    //     _mint(msg.sender,1000*10);
    //     admin=msg.sender;
    // }

    function bid() public payable{

        if(msg.value <= highestBid)
        {
            revert("the is already a higher bid or equal bid");
        }

        if(highestBid!=0)
        {
            pendingReturns[highestBidder]+=highestBid;
        }

        highestBidder=payable(msg.sender);
        highestBid=msg.value;

        emit HighestBidIncrease(msg.sender,msg.value);
    }
    function withdraw() public payable returns(bool)
    {
        uint amount = pendingReturns[msg.sender];
        payable(msg.sender).transfer(amount);
        if(amount>0){
            pendingReturns[msg.sender]=0;

        }
        return true;
    }
    function auctionEnd() public payable{
        payable(beneficiary).transfer(highestBid);
        emit AuctionEnded(highestBidder,highestBid);

        
    }


}