// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
error Lottery__UpkeepNotNeeded(uint256 lotteryState);
error Auction__SendMoreToMakeBid();
error Auction__TransferFailed();

contract Auction is  KeeperCompatibleInterface {


    enum AuctionState {
        OPEN,
        CLOSE
    }

   
    /* Type declarations */
    
    /* State variables */
    uint256 public constant i_originalPrice = 0.01 ether;
    uint256 public  temporaryHighestBid;
    uint256 public returnLoser;
    mapping(address => uint256) public s_adressesToBid;
    address payable[] public s_bidders;
    address payable public currentWinner;
    //address payable public seller;
    bool public auctionStarted = false;
    AuctionState private s_auctionState = AuctionState.CLOSE;
    uint256 private immutable i_interval = 180;
    uint256 private s_lastTimeStamp;


     function makeBid() public payable {
        if (msg.value < temporaryHighestBid ) {
            revert Auction__SendMoreToMakeBid();
        }
        if (msg.value < i_originalPrice ) {
            revert Auction__SendMoreToMakeBid();
        }
        if(auctionStarted){
           returnLoser = s_adressesToBid[currentWinner];
            (bool success, ) = currentWinner.call{value: returnLoser}("");
        }

        temporaryHighestBid= msg.value;
        s_bidders.push(payable(msg.sender));
        currentWinner = payable(msg.sender);
        s_adressesToBid[msg.sender]= msg.value;
        s_auctionState = AuctionState.OPEN;
        s_lastTimeStamp = block.timestamp;
         (bool success, ) = address(this).call{value: msg.value}("");
        // require(success, "Transfer failed");
        auctionStarted = true;


    }

 function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = AuctionState.OPEN == s_auctionState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        upkeepNeeded = (timePassed && isOpen);
        return (upkeepNeeded, "0x0"); 
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                uint256(s_auctionState)
            );
        }
        //We will transfer nft here
        s_auctionState = AuctionState.CLOSE;
        s_bidders = new address payable[](0);


    }

}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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