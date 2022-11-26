/**
 *Submitted for verification at Etherscan.io on 2022-11-26
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: GamoFlip.sol



pragma solidity ^0.8.7;




contract GamoFlip is VRFConsumerBaseV2 {

    /////////////////////////////////// ChainLink Variables ///////////////////////////////////
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    // Goerli LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint64 public s_subscriptionId;
    bool public result;

    /////////////////////////////////// Gamoflip Variables ///////////////////////////////////
    address public owner;
    uint public nextFlip;
    uint public nextDegen;
    uint[] public validAmounts;
    uint feePercentage;

    // Structs
    struct flip {
        uint id;
        bool exists;
        address degen;
        uint flipResult;
        uint choice;
        uint result;
        uint date;
        uint ethBetted;
        int ethWon;
        int ethLost;
    }

    struct degen {
        uint id;
        bool exists;
        address degenAddress;
        uint lastFlip;
    }

    // Mappings
    mapping(uint256 => flip) public Flips;
    mapping (uint256 => address) public IdsToDegens;
    mapping (address => degen) public Degens;


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        owner = msg.sender;
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
        validAmounts = [10000000000000000, 20000000000000000, 25000000000000000, 50000000000000000, 75000000000000000, 100000000000000000];
        nextFlip = 1;
        nextDegen = 1;
        feePercentage = 5;
    }

    // Helper Functions
    receive() external payable {

    }

    function withdrawEth() external onlyOwner {
        (bool os,) = payable(owner).call{value:address(this).balance}("");
        require(os);
    }

    ////////////////////////////////////// ChainLink Functions /////////////////////////////////////////
    
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    ////////////////////////////////////// GAMOFLIP Functions /////////////////////////////////////////

    // Assumes the subscription is funded sufficiently.
    function flipEth(bool expectation) payable external {
        require(msg.value == validAmounts[0] || msg.value == validAmounts[1] || msg.value == validAmounts[2] || msg.value == validAmounts[3] || msg.value == validAmounts[4] || msg.value == validAmounts[5], "You can't bet this ETH amount");
        // Get Random Number From ChainLink
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        degen storage newDegen = Degens[msg.sender];

        if (newDegen.exists == false) {
            newDegen.id = nextDegen;
            newDegen.exists = true;
            newDegen.degenAddress = msg.sender;

            IdsToDegens[nextDegen] = msg.sender;
            nextDegen++;
        }

        newDegen.lastFlip = block.timestamp;

        // Get Heads Or Tails Depending On The Request Id Value
        if ((s_requestId % 2) == 0) {

            if (expectation) {
                flip storage newFlip = Flips[nextFlip];
                newFlip.id = nextFlip;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 1;
                newFlip.choice = 1;
                newFlip.result = 1;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = msg.value;
                newFlip.ethWon = int256(msg.value);
                newFlip.ethLost = 0;

                nextFlip++;

                // Get amount to reward minus fees.
                uint amountToPay = (msg.value * 2) - ((msg.value * feePercentage) / 100);
                payable(msg.sender).call{value: amountToPay}("");


            } else {
                flip storage newFlip = Flips[nextFlip];
                newFlip.id = nextFlip;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 1;
                newFlip.choice = 2;
                newFlip.result = 2;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = msg.value;
                newFlip.ethWon = 0;
                newFlip.ethLost = int256(msg.value);

                nextFlip++;

            }

        } else {

            if (!expectation) {
                flip storage newFlip = Flips[nextFlip];
                newFlip.id = nextFlip;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 2;
                newFlip.choice = 2;
                newFlip.result = 1;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = msg.value;
                newFlip.ethWon = int256(msg.value);
                newFlip.ethLost = 0;

                nextFlip++;

                // Get amount to reward minus fees.
                uint amountToPay = (msg.value * 2) - ((msg.value * feePercentage) / 100);
                payable(msg.sender).call{value: amountToPay}("");


            } else {
                flip storage newFlip = Flips[nextFlip];
                newFlip.id = nextFlip;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 2;
                newFlip.choice = 1;
                newFlip.result = 2;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = msg.value;
                newFlip.ethWon = 0;
                newFlip.ethLost = int256(msg.value);

                nextFlip++;

            }
        }
    }

    function changeFeePercentage(uint newFee) external onlyOwner {
        feePercentage = newFee;
    }

    function changeValidAmounts(uint newAmount1, uint newAmount2, uint newAmount3, uint newAmount4, uint newAmount5, uint newAmount6) external onlyOwner {
        validAmounts[0] = newAmount1;
        validAmounts[1] = newAmount2;
        validAmounts[2] = newAmount3;
        validAmounts[3] = newAmount4;
        validAmounts[4] = newAmount5;
        validAmounts[5] = newAmount6;
    }

    function getPlayerFlipsTotal(address player) public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].degen == player) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getPlayerFlipsToday(address player) public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].degen == player && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getPlayerProfitsToday(address player) public view returns (int) {
        int wins;
        int losses;
        flip[] memory userFlips = getPlayerFlipsToday(player);
        // Get Wins
        for (uint i = 0; i < userFlips.length; i++) {
            wins += userFlips[i].ethWon;
        }
        // Get Losses
        for (uint i = 0; i < userFlips.length; i++) {
            losses += userFlips[i].ethLost;
        }
        // Get Pnl
        int pnl = wins - losses;
        return pnl;
    }

    function getPlayerProfitsTotal(address player) public view returns (int) {
        int wins;
        int losses;
        flip[] memory userFlips = getPlayerFlipsTotal(player);
        // Get Wins
        for (uint i = 0; i < userFlips.length; i++) {
            wins += userFlips[i].ethWon;
        }
        // Get Losses
        for (uint i = 0; i < userFlips.length; i++) {
            losses += userFlips[i].ethLost;
        }
        // Get Pnl
        int pnl = wins - losses;
        return pnl;
    }

    function getAllFlips() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].exists == true) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllFlipsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].exists == true && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllFlipsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllFlipsToday();
        return flipsTemp.length;
    }

    function getTotalEthFlipped() public view returns (uint) {
        uint total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethBetted;
        }
        return total;
    }

    function getTotalEthFlippedToday() public view returns (uint) {
        uint total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethBetted;
        }
        return total;
    }

    function getAllFlipsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllFlips();
        return flipsTemp.length;
    }

    function getAllWins() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 1) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllWinsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 1 && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllWinsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllWinsToday();
        return flipsTemp.length;
    }

    function getTotalEthWon() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethWon;
        }
        return total;
    }

    function getTotalEthWonToday() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethWon;
        }
        return total;
    }

    function getAllWinsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllWins();
        return flipsTemp.length;
    }

    function getAllRugs() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 2) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllRugsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllRugs();
        return flipsTemp.length;
    }

    function getAllRugsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 2 && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllRugsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllRugsToday();
        return flipsTemp.length;
    }

    function getTotalEthRugged() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethLost;
        }
        return total;
    }

    function getTotalEthRuggedToday() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethLost;
        }
        return total;
    }
}