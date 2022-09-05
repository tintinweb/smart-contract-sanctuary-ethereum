// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//Imports 

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract Auction is KeeperCompatible{

// Self Defined DataTypes 

enum AuctionSatus{
    OPEN,
    ENDED
}

struct Auction{
    address creator;
    string asset;
    uint256 endTime;
    uint256 startTime;
    AuctionSatus status;
}

Auction[1] private s_auction;

// A Mapping structure which will store bidders addresses and there bids

mapping(address => uint256) private bidderAddressTobid;

address[] private s_bidders;

uint256 private s_auctionStartingTimeStamp;
uint256 private s_auctionEndingTimeStamp;
uint256 private HighestBidAmount;

// Errors

error BidTooLow();
error BidIsLessThanTheCurrentHighestBid();
error AuctionAlreadyExists();
error AuctionHasEnded();
error InvalidTime();
error OnlyTheCreatorCanWithdrawFunds();
error WithdrawFailure();
error UpkeepNotNeeded();
error YouDoNotHaveABid();
error NoAuctionGoingOnRightNow();

// Event 

event AuctionCreated(
    address indexed creater,
    string asset,
    uint256 indexed endTime,
    uint256 indexed startTime
);

event AuctionEnded();

// Modifier


     function createAuction(string memory _asset,uint256 _endTime) public {
         
         // Checking if a auction is already created or not

        if (s_auction[0].endTime != 0){
            revert AuctionAlreadyExists();
        }

        if(_endTime < block.timestamp){
            revert InvalidTime();
        }

        Auction memory newAuction = Auction(msg.sender,_asset,_endTime,block.timestamp,AuctionSatus.OPEN);
        s_auction[0] = (newAuction);
        s_auctionStartingTimeStamp=block.timestamp;
        s_auctionEndingTimeStamp = _endTime;

        emit AuctionCreated(msg.sender,_asset,_endTime,block.timestamp);

     }

// Allowing bidders to plac there bids

    function placeBid() public payable{

      // Only let them participate if an auction actually exists

      if(s_auction[0].endTime == 0){
        revert NoAuctionGoingOnRightNow();
      }

      // If someone tries to place a bid after the auction has ended we revert

      if(s_auction[0].endTime < block.timestamp){
        revert AuctionHasEnded();
      }

     // If they run this function without actually paying anything we revert

       if(msg.value == 0){
        revert BidTooLow();
       }


       // Getting the total bid of the person placing the bid

       uint256 totalBid = bidderAddressTobid[msg.sender] + msg.value;

       // In Auction we will not let the person place the bid if its lower than the current highest bid cause thats of no use

       // A bid placed is always higher than the previous highest one

       if ( totalBid <= getHighestBidAmount()){
         revert BidIsLessThanTheCurrentHighestBid();
       }

       /* Add the bidder to our mapping strucuture */

    // CHecking as well if the bidder has already placed some amount as bid before if so then we add this amount on top of that 

    if (bidderAddressTobid[msg.sender] != 0){

       // If they have paid some amount before then we can add what they paid now to the amount they have already bidded

        bidderAddressTobid[msg.sender] += msg.value;
    } else {
      
       // If not then we will set their bid as there value proportional to their address in the mapping structure

        bidderAddressTobid[msg.sender] = msg.value;
    }

    // Appending the bidders address to the array
        s_bidders.push(msg.sender);

    }

    function getHighestBidAmount() public returns(uint256){

        // Creating a variable which will store the highest bid

        /** I think explaining this code in a seperate file would be better */

        for (uint i = 0; i < s_bidders.length; i++) {
            uint256 bidAtIndex = bidderAddressTobid[s_bidders[i]];
            if (bidAtIndex> HighestBidAmount){
                HighestBidAmount = bidAtIndex; 
            }
        }
        return HighestBidAmount;
    }

    function getHighestBidderAddress() public returns(address){

        // Same shit different output

        address HighestBidderAddress;

        for (uint index = 0; index < s_bidders.length; index++) {
            address bidderAddress = s_bidders[index];
            uint256 bid = bidderAddressTobid[bidderAddress];
            if (bid == getHighestBidAmount()){
                HighestBidderAddress = bidderAddress;
            }
        }
        return HighestBidderAddress;
    }

    // A withdraw function to let the Bidders withdraw their funds 

    function withdrawBid(address bidder) public payable{

        uint256 bid = bidderAddressTobid[bidder];
        
        if(bid == 0){
            revert YouDoNotHaveABid();
        }

    // Tranferring the amount the bidder bidded 
        (bool withdrawSuccess , ) = bidder.call{value : bid}("");

        if(!withdrawSuccess){
            revert WithdrawFailure();
        }
       bidderAddressTobid[bidder] = 0;
    }

    function checkUpkeep(bytes memory /* checkData */)public view override returns(bool UpkeepNeeded, bytes memory /* performData */){
        UpkeepNeeded = (block.timestamp > s_auctionEndingTimeStamp && s_bidders.length != 0);
    }

    function performUpkeep(bytes calldata /* performData */) external override{

        (bool UpkeepNeeded,) = checkUpkeep("");

        if(!UpkeepNeeded){
            revert UpkeepNotNeeded();
        }

        (s_auction[0].creator).call{value : getHighestBidAmount()}("");

        // Setting the highestbidder's bid tp zero

        bidderAddressTobid[getHighestBidderAddress()] = 0;

        for (uint index = 0; index < s_bidders.length; index++) {
            address bidderAddress = s_bidders[index];
            if ( bidderAddress != getHighestBidderAddress()){
                if (bidderAddressTobid[bidderAddress] != 0){
                    withdrawBid(bidderAddress);
                }
            }
        }
        // HighestBidAmount = new uint256;
        s_bidders = new address[](0);
        delete s_auction[0];
        emit AuctionEnded();
    }

    // View / Pure functions 

    function getBidder(uint256 index)public view returns(address){
        return s_bidders[index];
    }

    function getBidByBidder(address bidderAddress)public view returns(uint256){
        return bidderAddressTobid[bidderAddress];
    }

    function getStartingTimeStamp()public view returns(uint256){
        return s_auctionStartingTimeStamp;
    }
    
    function getEndingTimeStamp()public view returns(uint256){
        return s_auctionEndingTimeStamp;
    }

    function getAuctionInfo()public view returns(Auction memory){
            return s_auction[0];
        }
    }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}