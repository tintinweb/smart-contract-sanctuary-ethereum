// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./Lottery.sol";

/*
* @author Leonie, Remo, Ralf
* @notice Contract that handles participation and winner selection of lottery.
*/
contract MooneryLottery is Lottery, VRFConsumerBase {

    // Events for Web3 Frontend
    event LotteryPotUpdated(uint256 potValue);
    event LotteryTicketAmountChanged(uint256 amountOfTickets);
    event LotteryWinnerDetected(address winner, uint256 payout);
    event LotteryWinnerNotFound(uint256 randomPointer);
    event LotteryRestarted(address lastWinner, uint256 lastPayout);

    // Chainlink contracts for VRF on Kovan
    address vrfCoordinator = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9;
    address priceFeedContract = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address linkToken = 0xa36085F69e2889c224210F603D836748e7dC0088;
    bytes32 keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    uint256 linkFee;
    bytes32 vrfRequestId;

    // Get the ETH/USD price from chainlink price feed
    AggregatorV3Interface priceFeed;
    uint256 public usdMinTicketPrice;

    constructor() VRFConsumerBase(vrfCoordinator, linkToken) Lottery() {
        priceFeed = AggregatorV3Interface(priceFeedContract);
        linkFee = 0.1 * 10 ** 18; // 0.1 LINK for Kovan network
        usdMinTicketPrice = 5 * (10**18); // 5 USD
    }

    modifier requireMinTicketPrice(uint256 payed, uint256 minTicketCost) {
        require(payed >= minTicketCost, "You need to pay at least 5$ to enter the lottery.");
        _;
    }

    modifier requireLotteryEndBlockNr(uint256 endBlockNr) {
        require(block.number >= endBlockNr, "The current block number is less than the determined block number of the lottery end.");
        _;
    }

    /// Method to enter the lottery. Lottery needs to be open and a minimum ticket price of 5$ is required
    function enter() public payable requireOpenState(currentLottery.state) requireMinTicketPrice(msg.value, getMinTicketPrice()) override {
        LotteryEntry storage l = currentLottery;

        tickets.push(Ticket(payable(msg.sender), l.pot, l.pot + msg.value));
        emit LotteryTicketAmountChanged(tickets.length);

        emit LotteryPotUpdated(l.pot += msg.value);

        // Check if end blocknumber is reached. If so, select winner and restart lottery
        if (block.number >= l.endBlockNr) {
            endAndRestartLottery();
        }
    }

    /// Get current price of ETH in USD
    function getLatestEthUsdPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    /// Returns the minimum ticket price (5$) in ETH to enter lottery.
    function getMinTicketPrice() public view returns(uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**18; // 18 decimals
        return (usdMinTicketPrice * 10**18) / adjustedPrice;
    }

    /// Method to select winner and restart lottery. Requires open lottery and higher blocknumber that end blocknumber.
    function endAndRestartLottery() public requireOpenState(currentLottery.state) requireLotteryEndBlockNr(currentLottery.endBlockNr) override {
        // Set lottery state to CALCULATING_WINNER till random number from Chainlink is recieved to stop further entries.
        currentLottery.state = LOTTERY_STATE.CALCULATING_WINNER;

        // Request random number from Chainlink to get winner of lottery. 
        // Logic is handled in fulfillRandomness function.
        vrfRequestId = requestRandomness(keyHash, linkFee);
    }

    /// Callback function for Chainlink VRF. Selects winner and pays out pot. Lottery is restarted afterwards.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(_requestId == vrfRequestId, "Request id doesn't match with id from requestRandomness");
        
        int256 winnerIndex = _determineRandomWinnerTicketIndex(_randomness);
        
        if (winnerIndex != -1) {
            Ticket memory winnerTicket = tickets[uint256(winnerIndex)];
            
            currentLottery.winner = winnerTicket.playerAddress;

            // Payout pot to the winner
            winnerTicket.playerAddress.transfer(currentLottery.pot);
            emit LotteryWinnerDetected(winnerTicket.playerAddress, currentLottery.pot);
            
            _restartLottery();
        }
    }

    /// Algorithm to determine winner ticket. 
    function _determineRandomWinnerTicketIndex(uint256 randomness) internal returns (int256) {
        // Map random value to value between 0 and pot size
        uint256 randomPotRangePointer = randomness % currentLottery.pot;

        // Loop through all tickets
        int256 winnerIndex = -1;
        for(uint256 i = 0; i < tickets.length; i++) {
            Ticket memory currentTicket = tickets[i];
            
            // Check if random pointer (0-pot size) is between the tickets starting pot and added stake
            if(currentTicket.potAtParticipation >= randomPotRangePointer && randomPotRangePointer < currentTicket.potWithStake){
                winnerIndex = int256(i);
                break;
            }
        }

        // If no winner ticket found, reopen lottery. Should not happen.
        if (winnerIndex == -1) {
            currentLottery.state = LOTTERY_STATE.OPEN;
            emit LotteryWinnerNotFound(randomPotRangePointer);
        }

        return winnerIndex;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/*
* @author Leonie, Remo, Ralf
* @notice Lottery factory to create and restart lotteries.
*/
abstract contract Lottery {

    /// Enum that represents possible states of an lottery.
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    struct LotteryEntry {
        uint256 pot;
        uint256 endBlockNr;
        address winner;
        LOTTERY_STATE state;
    }

    struct Ticket {
        address payable playerAddress;
        uint256 potAtParticipation;
        uint256 potWithStake;
    }

    Ticket[] public tickets;

    LotteryEntry public currentLottery;
    LotteryEntry public previousLottery;

    // Block duration of lottery. Kovan block time 4s => 75 Blocks = 5min
    uint8 lotteryBlockDuration = 75;

    event LotteryEndBlockNrDetermined(uint256 blockNr);

    constructor() {
        currentLottery = _createLottery();
    }

    modifier requireOpenState(LOTTERY_STATE state) {
        require(state == LOTTERY_STATE.OPEN, "Lottery needs to be open.");
        _;
    }

    modifier requireClosedState(LOTTERY_STATE state) {
        require(state == LOTTERY_STATE.CLOSED, "Lottery needs to be closed.");
        _;
    }

    /// handles entry to lottery
    function enter() public payable virtual;

    /// handles end and restart of lottery
    function endAndRestartLottery() public virtual;

    function _createLottery() internal returns (LotteryEntry memory) {
      uint lotteryEndBlockNr = _determineEndBlockNr(lotteryBlockDuration);
      return LotteryEntry(0, lotteryEndBlockNr, address(0), LOTTERY_STATE.OPEN);
    }

    function _restartLottery() internal {
      previousLottery = currentLottery;
      previousLottery.state = LOTTERY_STATE.CLOSED;
      currentLottery = _createLottery();
    }

    /// Method to determine the block number after which lottery can be ended.
    function _determineEndBlockNr(uint8 step) internal returns (uint) {
        uint256 endBlockNr = block.number + uint256(step);
        emit LotteryEndBlockNrDetermined(endBlockNr);
        return endBlockNr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
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