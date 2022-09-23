/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: PeaceRabbitVRF.sol



/*


        $$$$$$$\                            $$\                               
        $$  __$$\                           $$ |                              
        $$ |  $$ | $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$\  $$$$$$\$$$$\        
        $$$$$$$  | \____$$\ $$  __$$\ $$  __$$ |$$  __$$\ $$  _$$  _$$\       
        $$  __$$<  $$$$$$$ |$$ |  $$ |$$ /  $$ |$$ /  $$ |$$ / $$ / $$ |      
        $$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ | $$ | $$ |      
        $$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |\$$$$$$  |$$ | $$ | $$ |      
        \__|  \__| \_______|\__|  \__| \_______| \______/ \__| \__| \__|      
                                                                            
                                                                            
                                                                            
        $$$$$$$\            $$\       $$\       $$\   $$\                     
        $$  __$$\           $$ |      $$ |      \__|  $$ |                    
        $$ |  $$ | $$$$$$\  $$$$$$$\  $$$$$$$\  $$\ $$$$$$\                   
        $$$$$$$  | \____$$\ $$  __$$\ $$  __$$\ $$ |\_$$  _|                  
        $$  __$$<  $$$$$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |                    
        $$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$\                 
        $$ |  $$ |\$$$$$$$ |$$$$$$$  |$$$$$$$  |$$ |  \$$$$  |                
        \__|  \__| \_______|\_______/ \_______/ \__|   \____/                 
                                                                            
                                                                            
                                                                            
        $$$$$$\  $$\                                                         
        $$  __$$\ $$ |                                                        
        $$ /  \__|$$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$\  $$$$$$\   $$$$$$\  
        $$ |      $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|$$  __$$\ $$  __$$\ 
        $$ |      $$ |  $$ |$$ /  $$ |$$ /  $$ |\$$$$$$\  $$$$$$$$ |$$ |  \__|
        $$ |  $$\ $$ |  $$ |$$ |  $$ |$$ |  $$ | \____$$\ $$   ____|$$ |      
        \$$$$$$  |$$ |  $$ |\$$$$$$  |\$$$$$$  |$$$$$$$  |\$$$$$$$\ $$ |      
        \______/ \__|  \__| \______/  \______/ \_______/  \_______|\__|      
                                                                            
                                                                
*/

pragma solidity ^0.8.7;



/**
* @title Smart contract written to choose random RandomPeaceRabbit NFT holder
* @author PeaceRabbitNFT
* @notice Only wallets holding more than 5 NFT's are considered
* @dev All function calls are currently implemented without side effects
*/

contract RandomRabbitChooser is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D; //for GOERLI
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; //for MAINNET
  
  
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; //for GOERLI
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //for MAINNET
  
  
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 200000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  
  ///
    uint256 randomResult;
    address owner;
    address WINNING_ADDRESS1;
    address WINNING_ADDRESS2;
    address[] emptyArray;
    bool public winner1Chosen;
    address[] public HOLDERS_ARRAY = [
        0x16992aC238aD27E97b95e54ae8367054b0ff7cCb,
        0x52fad22dE6b3A5cAC9Be0774c46113091a5C8252,
        0xcdC0F3041CeDA2367C526230aF601c7024F0844a,
        0x3aF0FC0fd48427e9AB10c3084e9017b10Ca2cAB7,
        0xd5c2ddBe444a98A0C86f7cF4Be58a38A80B6F741,
        0xb5EF55fc625459Bb7516B9ddc7C236F630dB1A18,
        0xC092F610c5B65CA1Cb857eF67e488bb764bE8be2,
        0x1A95F21d8666e2715FE5B00e534a771930b22714,
        0x5113AeDaFe0960210B44ee53531B0fc0adaDa0df,
        0x7a87cDdc5cfeFc53ECb4d7e7bd6dD3658383F766,
        0xaD4384117782A3392a0480648284b424b5E4A175,
        0x4E1e937cFd65f367008B24ddB9ce25D0Aa65A4E0,
        0x8413f65e93d31f52706C301BCc86e0727FD7c025,
        0xBF707D776e8A6E46Df879e4b13A709B3f395935c,
        0xc176ba88EfEfc132EC977253d6937E864E284912,
        0xFCA731905063e8Aa7e3dBf3c0EdACB879f052814,
        0xbB3AAc0E153c3bd81a1335F3F45E816c3c36Dcc5,
        0x39E121297240Ac7F72E7487D799a0fC06422e216,
        0xd32eC8b8Ef48E454803B03479503007c5013C959,
        0x7710DFdCF742E68B7A1C90D59EdEdCef047fC50f,
        0x5f58a3499bC7Bd393c5DAB9Ec256313c8622cE95,
        0xAb0e259AeEAE3d8b5e843330f0B952B79DfbeDc3,
        0xbBE45c89A92a266335E6aAB8C773BF28672b1A7F,
        0xAFA605a5513534C284859dDa1Bd263239343297f,
        0x210CA1610a9E4d220eA1E2A7e8D4e84eB46b52a8,
        0xBC7B2f725C6D89E5709955c2A5FDa43FA860Ef40,
        0x3cFc3Bf0d1ae098854422091B80C1ef6A595bbc7,
        0xFF59a9EEd61E49Db47eE7C544ACeB0b4717de904,
        0x202992D9e6D171805d562f278D5f28621faE289F,
        0xF73fB512d10E3224aa4a232AdEb1Daae66122162,
        0xA39d385628bd00438F8A9Ba4050a25A0210f84eb,
        0xe73647C5f486975ecf2913F4F1263321c56AaB4D,
        0x56db552729ef80A0C0e6fBe1ea98F19CE51939A2,
        0x760bF2BCA1546D13DC44e08104EBA13c6554897B,
        0xe5DF39DEE0eB73Bf5a1487911ed8D94565907E1e,
        0x0085c0659aC63716E6A9F7A1B2dE9706e50267b1,
        0x773Ba05f8A152888ACc88adD541aa5C58b497F41,
        0x81863F0Cf78358fAdA029B7D5fa0b84674802eF1,
        0x7858F91c6752400F2234584A25006335bE6D09Bb,
        0xc855d03edb308080e70f0FBC4e2f3BE7c383782c,
        0x745165B9895832475AbD3AF9Bed1fBC9002f5FFc,
        0x996e778ff6e7Fca4b8FCf8a9ec2E85C878241bC4,
        0x40Da2891C23748d1e521C563bB7c71d822f17D3e,
        0x5c5b4A9872Fd5218693eb59936fF60dfDCCF284d,
        0xe4F4c76d44A3ac80dB8f08DF3F4EF76f1ab5c8bE,
        0xBfAd8f7175E5a5A7d47bFaDBCE23791779Dab25f,
        0x318d6b1bE87106Ac1C1f7b4e23EC035e37500f5F,
        0x7D2Cbc2Ba50819082bfD3003e820C069834Cf9ba,
        0xf5674a7C6B089Cc40723c4285979caB57c695Ac7,
        0x74180F751b4501931C9d400E9598Bb2c69fE1118,
        0x84bC0197765D84729A8d8D94E025104C50a2e028,
        0x08C2ceEcA0E01066B4e46081AcC621a34E8e21F1,
        0x18c43569593a10C124FB738C00c33B75748B971E,
        0x03bC3A5EB3407d01E11D02D567a7452Be0147F09,
        0x05F5EB1f02aCB65dF6A2f0f6D7Ba36490eE2D693,
        0xA683f51239c74cb509CEdc8F89Cb54Ad2Aec1e4E,
        0x1E53A50Ef5b9Db2C3992B6023bD6C0C0051924c5,
        0xa34ef3Eeb75e7ff28c30Be9dAD130D6A7Ec96de5,
        0x8110cbb5F4B68Fe717F95B69cFc00C65E1cB74Ff,
        0x91e19c1a3173B4f4A35E6818458205F6b5555D1b,
        0xeeFbc827847d018d79095216674112eDA4Be2EC2,
        0x8B1332e6414C830e823110667A6f0c10463D0f98,
        0xBfcC73DC4b03f0fEBb5Ce1d53e5E410a3ee8CFC1,
        0x354809401DbfEf365aB228AB07bf9623801b5698,
        0xC6371FaE52199704312d115bcDfD1bCa9f05329c,
        0x5e5dB90DF94B99eA57402Bf24AF10E32ea742F7D,
        0x02b4aCcdc4256572Ecc4fC39476299680F8C9Cd0,
        0x32201AaFD9ccf4Aa5ebF49D03c47707b8109Cf71,
        0x954Cfc3B0cD64C88Ea075F676262e5f93E071b9E,
        0x63d5E112731bc68BF25D6393902B6b175E116f71,
        0xaADD2cFb46ea8EdCe4B03527B0cfCeE0900d13BE,
        0x52E274B37Be544f8EB5372B239882d2725375484,
        0x82D8cA3Bd5199C6a382f61DB06Ca7826f6335b12,
        0xE6Fe340553C3EeCa04cB8a87747889e7F00a319D,
        0xa8c5bf8a6a4489E4882542451D2F75F2254FF904,
        0xF1C3d2609Bbfa60DFa6A0b184B0fCc02E1233673,
        0xC1923cAe3b5ff75c87A1CEfA8E80e2985E1232A8,
        0xBE6b69D2f957572DB8852056D70cFc38c3EB3CA6,
        0x5d94A7740b4D76a488dC6AbE8839D033AD296f85,
        0xfB37A1a91B572888d08B05f0D461eaBe619D4A85,
        0x3E3f7386277A4Ef0E8caf4BBb8D7E28811654467,
        0x43f2De85222A6C1fad109D0831A12f7209514124,
        0xF66668363AfA40bc3B4Ea605e0275947dB4127aC,
        0xD2Cb0715999643c3D6eF33b08d67D2e43B15a1e4,
        0x8Cc5c4e70404181e88F92499973320Cb539229d7,
        0x00C980F967b3E94e471C94d226Da998E1eb55A33,
        0x41Fc5DE56b095F594a7fe0e758FD6769D060a376,
        0xBc5D9c6458B3746229Ae889B8D6B14232B48e87f,
        0xe18500956df2f053D46bd36Ad71ce05677B7d911,
        0xa7cC503461E125fee89380d01cd0A7c453906fF4,
        0xAB4ce2a08cBeA809692218DD7841F681B80069A9,
        0x3A8713065e4DAa9603b91Ef35d6a8336eF7b26C6,
        0xDa2A02C9F8B66f756f76d795D1ae0aD58788B009
    ];
    
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    /**
        * Requests randomness
        * @notice triggers a random number call from chainlink VRF
        * @notice can only be called by owner of contract 
        * @notice please fund the contract with LINK tokens before proceeding
        */
    function chooseWinner1() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }


    /**
     * Callback function used by VRF Coordinator
     * @notice the WINNING_ADDRESS1 is chosen
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomResult = (randomWords[0]%HOLDERS_ARRAY.length);
            WINNING_ADDRESS1 = HOLDERS_ARRAY[randomResult];       
            winner1Chosen=true; 
    }

    /**
     * Calculates the second winner for the raffle
     * @notice can be called only by owner
     * @notice returns the winning address
     */
    function calculateSecondWinner() external onlyOwner{
        require(winner1Chosen,"Winner 1 is not yet chosen");
        uint secondNum = uint(keccak256(abi.encodePacked(randomResult,WINNING_ADDRESS1)))%HOLDERS_ARRAY.length;
        uint count=1;
        while(secondNum==randomResult){
            secondNum = uint(keccak256(abi.encodePacked(count,randomResult,WINNING_ADDRESS1)))%HOLDERS_ARRAY.length;
            count=count+1;
        }
        WINNING_ADDRESS2 = HOLDERS_ARRAY[secondNum]; 
        
    }   


    /**
     * Allow withdraw of Link tokens from the contract
     * @notice returns the winning address
     */
    function getWinners() public view returns(address,address){
        require(WINNING_ADDRESS1!=address(0),"Winner not yet chosen");
        require(WINNING_ADDRESS2!=address(0),"Second winner not yet chosen");
        return (WINNING_ADDRESS1,WINNING_ADDRESS2);
    }    


    /**
     * Resets the contract to reuse it
     * @notice once reset, the new particpants need to be added using addToHoldersArray() function
     * @notice can be called only by the owner of the contract
     */
    function resetContract() external onlyOwner{
        HOLDERS_ARRAY=emptyArray;
        WINNING_ADDRESS1=address(0);
        WINNING_ADDRESS2=address(0);
        winner1Chosen=false;

    }


    /**
     * add holders
     * @notice adds eligible NFT holders for participating
     * @notice can be called only by the owner of the contract
     * @param _arr array of eligible addresses, add in bunches, max 100 at a time, eg. ["0x...","0x..."]
     */
    function addToHoldersArray(address[] memory _arr) external onlyOwner{
        for(uint i=0;i<_arr.length;i++){
            HOLDERS_ARRAY.push(_arr[i]);
        }
    }     
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}