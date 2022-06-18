pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Lottery__NotEnufAmt();
error Lottery__AlrdyInLotteryOrCollectRewards();
error Lottery__TransferFailed();
error Lottery__StateMustBeCoolDown();
error Lottery__StateMustBeOpen();
error Lottery__upkeepFalse();
error Lottery__NotaWinner();


contract Lottery is KeeperCompatibleInterface, VRFConsumerBaseV2{

    enum LotteryState{
        OPEN,
        CALCULATING,
        COOLDOWN
    }
    address public immutable i_owner;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_gasLimit;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_contractMinBalance = 10000000000000000;

    //lottery variables
    LotteryState public s_lotteryState;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_open_interval;
    uint256 public immutable i_cooldown_interval;
    uint256 public s_currentLotteryPool;
    address payable[] public entrants;
    uint256[] private cummulativeEntrantsDeposits;
    mapping(address => uint256) private entrantsDeposits;
    mapping(uint16 => mapping(address => uint256)) private addressToEntrantsIdx;
    uint16 public lotteryNumber;

    //winner details    
    uint256 public numWinners;    
    uint256 private startingWinnerIndex;
    uint256 private endingWinnerIndex;    
    
    //events
    event NoLottery();
    event GotReqId(uint256 indexed requestId);
    event WinnersPicked(uint256 indexed randNum);
    event LotteryEnter(address indexed player);
    event Rewarded(uint256 indexed rewardAmount);
    event AmountTransferredToOwner(uint256 indexed curbal, uint256 indexed minbal);

    constructor(
                address vrfCoordinatorAddress, uint256 _entranceFee, uint256 _open_interval, uint256 _cooldown_interval, bytes32 gasLane, uint64 subscriptionId, uint32 gasLimit) 
                VRFConsumerBaseV2(vrfCoordinatorAddress) {

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        i_owner = msg.sender;
        i_entranceFee = _entranceFee;
        i_open_interval = _open_interval;
        i_cooldown_interval = _cooldown_interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_gasLimit = gasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes memory) public override view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = false;
        if (s_lotteryState == LotteryState.OPEN){
            bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_open_interval);
            upkeepNeeded = timePassed;
        }        
        if (s_lotteryState == LotteryState.COOLDOWN){
            bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_cooldown_interval);
            upkeepNeeded = timePassed;
        }        
    }

    function performUpkeep(bytes calldata) external override{ 
        (bool upkeepNeeded, ) = checkUpkeep('0x0');
        if(!upkeepNeeded){
            revert Lottery__upkeepFalse();
        }
        if(s_lotteryState == LotteryState.OPEN){
            s_lotteryState = LotteryState.CALCULATING;            
            if(entrants.length < 10){      // minimum 10 players
                emit NoLottery();
                s_lotteryState = LotteryState.COOLDOWN;
                s_lastTimeStamp = block.timestamp;
            }
            else{
                uint256 requestId = i_vrfCoordinator.requestRandomWords(
                                    i_gasLane,
                                    i_subscriptionId,
                                    3, // request confirmations
                                    i_gasLimit,  //limit gas for fulfillrandomwords
                                    1 // one random word(number)
                                    );
                emit GotReqId(requestId);
            }
        }
        else if(s_lotteryState == LotteryState.COOLDOWN){            
            if (i_contractMinBalance < address(this).balance) {
                (bool success, ) = payable(i_owner).call{value : address(this).balance - i_contractMinBalance}("");
                if(!success){
                    revert Lottery__TransferFailed();
                }
                emit AmountTransferredToOwner(address(this).balance,i_contractMinBalance);
            }
            s_lotteryState == LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
            s_currentLotteryPool = 0;
            entrants = new address payable[](0);
            cummulativeEntrantsDeposits = new uint256[](0);
            lotteryNumber += 1;
        }
    }

    function pseudoCheckWinner(uint256 strt, uint256 end) internal view returns (bool){
        if(strt < end){
            if(strt <= addressToEntrantsIdx[lotteryNumber][msg.sender] && addressToEntrantsIdx[lotteryNumber][msg.sender] < end){
                return true;
            }
        }
        else{
            if(strt <= addressToEntrantsIdx[lotteryNumber][msg.sender] || addressToEntrantsIdx[lotteryNumber][msg.sender] < end){
                return true;
            }
        }
        return false;
    }

    function checkIfWinner() public view returns (bool winBool){
        if(s_lotteryState == LotteryState.COOLDOWN){
            return winBool = (pseudoCheckWinner(startingWinnerIndex, endingWinnerIndex)) && addressToEntrantsIdx[lotteryNumber][msg.sender] != 0;
        }
        revert Lottery__StateMustBeCoolDown();
    }

    function fulfillRandomWords(uint256 /*reIdfrom_vrf.requestRandomWords*/, uint256[] memory randomWords) internal override{
        numWinners = entrants.length * 4 / 5;
        startingWinnerIndex = (randomWords[0] % entrants.length) + 1; //1 indexing
        endingWinnerIndex = ((startingWinnerIndex - 1  + numWinners) % entrants.length) + 1;
        emit WinnersPicked(randomWords[0]); 
        
        s_lotteryState = LotteryState.COOLDOWN;
        s_lastTimeStamp = block.timestamp;
    }

    function getWinnersPool(uint256 s,uint256 e) public view returns(uint256){
        if(e<s){
            return cummulativeEntrantsDeposits[s-1] - cummulativeEntrantsDeposits[e-1];
        }        
        uint256 lastElement = cummulativeEntrantsDeposits[cummulativeEntrantsDeposits.length-1];
        return lastElement - cummulativeEntrantsDeposits[e-1] + cummulativeEntrantsDeposits[s-1];
    }

    function claimRewards() public payable{
        if(s_lotteryState == LotteryState.COOLDOWN){
            if(entrants.length < 10){
                uint256 amtToTransfer = entrantsDeposits[msg.sender];
                (bool success, ) = payable(msg.sender).call{value : amtToTransfer}("");
                if(!success){
                    revert Lottery__TransferFailed();
                }
                // emit Rewarded(amtToTransfer);
            }
            else if(pseudoCheckWinner(startingWinnerIndex, endingWinnerIndex)){
                uint256 winnersPool = getWinnersPool(startingWinnerIndex, endingWinnerIndex);
                uint256 amtToTransfer = entrantsDeposits[msg.sender] + entrantsDeposits[msg.sender] * winnersPool/s_currentLotteryPool;

                // uint256 indexOfWinner = addressToEntrantsIdx[lotteryNumber][msg.sender];
                // address payable Winner = entrants[indexOfWinner];
                (bool success, ) = (msg.sender).call{value : amtToTransfer}("");
                
                if(!success){
                    revert Lottery__TransferFailed();
                }                
                addressToEntrantsIdx[lotteryNumber][msg.sender] = 0;
                emit Rewarded(amtToTransfer);
            }            
            else{
                revert Lottery__NotaWinner();
            }
        }
        else {
            revert Lottery__StateMustBeCoolDown();
        }
    }

    function enterLottery() public payable{
        if(s_lotteryState != LotteryState.OPEN){
            revert Lottery__StateMustBeOpen();
        }
        if (msg.value < i_entranceFee){
            revert Lottery__NotEnufAmt();
        }
        s_currentLotteryPool += msg.value;
        entrantsDeposits[msg.sender] = msg.value;
        entrants.push(payable(msg.sender));
        addressToEntrantsIdx[lotteryNumber][msg.sender] = entrants.length;

        if(cummulativeEntrantsDeposits.length == 0){ //change to 1 indexing
            cummulativeEntrantsDeposits.push(0);
        }        
        uint256 lastElement = cummulativeEntrantsDeposits[cummulativeEntrantsDeposits.length-1];
        cummulativeEntrantsDeposits.push(lastElement + msg.value);
        emit LotteryEnter(msg.sender);
        
    }
    function fundContract() public payable{
        
    }

    function getMinEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }
    function getLotteryPool() public view returns (uint256){
        return s_currentLotteryPool;
    }
    function getlotteryState() public view returns (LotteryState){
        return s_lotteryState;
    }
    function getlotteryNumber() public view returns (uint256){
        return lotteryNumber;
    }
    function getIntervals() public view returns (uint256, uint256){
        return (i_open_interval, i_cooldown_interval);
    }
    function getAmountDeposited() public view returns (uint256){
        return entrantsDeposits[msg.sender];
    }
    function getNumPlayers() public view returns (uint256){
        return entrants.length;
    }

    function getWinnersIndices() public view returns (uint256, uint256){
        return (startingWinnerIndex, endingWinnerIndex);
    }
    function getPlayerIndex() public view returns (uint256){
        return addressToEntrantsIdx[lotteryNumber][msg.sender];
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}