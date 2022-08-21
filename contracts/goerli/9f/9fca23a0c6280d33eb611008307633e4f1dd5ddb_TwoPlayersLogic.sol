// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract TwoPlayersLogic is VRFConsumerBaseV2 {

    address public factory;
    address public creator;
    uint256 public time;
    uint64 public subId;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // address LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // address VRF = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    // bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    address VRF = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    struct Path {
        Name name;
        Room room;
        uint256 id;
    }

    enum Name {
        evenOdd,
        rockPaperScissors,
        kickDefense
    }

    enum Room {
        One,
        Ten,
        Hundred,
        Thousand
    }

    struct Game {
        address winner;
        address player1;
        address player2;
        uint256 move1;
        uint256 move2;
        uint256 time1;
        uint256 time2;
        uint256 random;
        bytes32 proof;  // keccak256("word1 word2 word3")
        bytes32 cipher; // keccak256(move1, proof)
    }

    mapping(Name => mapping(Room => uint256)) public id;                     // Name => Room => ID++
    mapping(Name => mapping(Room => mapping(uint256 => Game))) public games; // Name => Room => ID => Game
    mapping(uint256 => Path) public requests;                                // RequestID => Path
    
    constructor(
        address creator_,
        uint256 time_,
        address vrf_,
        address link_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrf_) {
        time = time_;
        creator = creator_;
        factory = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(vrf_);
        LINKTOKEN = LinkTokenInterface(link_);
        keyHash = keyHash_;
        createNewSubscription();
    }

    function move1(
        Name name_,
        bytes32 cipher_
    ) public payable returns(Game memory, uint256) {

        Room room = getRoom(msg.value);

        id[name_][room]++;
        games[name_][room][id[name_][room]] = Game({
            winner: address(0),
            player1: msg.sender,
            player2: address(0),
            move1: 0,
            move2: 0,
            time1: block.timestamp,
            time2: 0,
            random: 0,
            proof: "",
            cipher: cipher_
        });

        return (games[name_][room][id[name_][room]], id[name_][room]);
    }

    function move2(
        Name name_,
        uint256 id_,
        uint256 move_
    ) public payable returns(Game memory, uint256) {

        Room room = getRoom(msg.value);
        Game storage game = games[name_][room][id_];

        require(game.move2 == 0, "Move 2 exists");

        game.player2 = msg.sender;
        game.move2 = move_;

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            3,
            200000,
            1
        );

        requests[requestId] = Path(name_, room, id_);

        return (game, requestId);
    }

    function winnerAddress(
        Name name_,
        Room room_,
        uint256 id_,
        uint256 move_,
        bytes32 proof_
    ) public view returns(address winner) {
        Game memory game = games[name_][room_][id_];
        bytes32 cipher = getCipher(move_, proof_);

        require(game.cipher == cipher, "Invalid proof");
        require(game.random != 0, "Random not found");

        uint256 m1 = move_;
        uint256 m2 = game.move2;

        if (name_ == Name.evenOdd) {
            if (m1 % 2 == m2 % 2) {
                if (game.random % 2 == 0) {
                    winner = game.player1;
                } else {
                    winner = game.player2;
                }
            } else {
                if (game.random % 2 == m1 % 2) {
                    winner = game.player1;
                } else {
                    winner = game.player2;
                }
            }
        } else if (name_ == Name.rockPaperScissors) {
            if (
                (m1 == 1 && m2 == 1) ||
                (m1 == 2 && m2 == 2) ||
                (m1 == 3 && m2 == 3)
            ) {
                if (game.random % 2 == 0) {
                    winner = game.player1;
                } else {
                    winner = game.player2;
                }
            }
            if (m1 == 1 && m2 == 2) {
                winner = game.player2;
            }
            if (m1 == 1 && m2 == 3) {
                winner = game.player1;
            }
            if (m1 == 2 && m2 == 1) {
                winner = game.player1;
            }
            if (m1 == 2 && m2 == 3) {
                winner = game.player2;
            }
            if (m1 == 3 && m2 == 1) {
                winner = game.player2;
            }
            if (m1 == 3 && m2 == 2) {
                winner = game.player1;
            }
        } else if (name_ == Name.kickDefense) {
            bool[] memory p1 = splitMove(m1);
            bool[] memory p2 = splitMove(m2);
            bool w1 = 
                (p2[0] && p1[3]) ||
                (p2[1] && p1[4]) ||
                (p2[2] && p1[5]);
            bool w2 = 
                (p1[0] && p2[3]) ||
                (p1[1] && p2[4]) ||
                (p1[2] && p2[5]);
            if (w1 && w2) {
                if (game.random % 2 == 0) {
                    winner = game.player1;
                } else {
                    winner = game.player2;
                }
            } else if (w1) {
                winner = game.player1;
            } else if (w2) {
                winner = game.player2;
            }
        }
    }

    function claim(
        Name name_,
        Room room_,
        uint256 id_,
        uint256 move_,
        bytes32 proof_
    ) public returns(address) {
        Game storage game = games[name_][room_][id_];

        require(
            game.winner == address(0),
            "Winner is determined"
        );

        if (move_ != 0 && proof_[0] != 0) {
            game.winner = winnerAddress(name_, room_, id_, move_, proof_);
            require(
                game.winner != address(0),
                "Claim error"
            );
            game.proof = proof_;
            game.move1 = move_;
        } else {
            require(
                block.timestamp >= game.time2 + time,
                "Result is not ready"
            );
            game.winner = game.player2;
        }

        uint256 prize = getPrize(room_);

        uint256 fee = prize / 100;
        (bool sent,) = payable(game.winner).call{value: prize - fee - fee}("");
        require(sent, "Failed to send MATIC for winner");
        (bool sent2,) = payable(creator).call{value: fee}("");
        require(sent2, "Failed to send MATIC for creator");
        (bool sent3,) = payable(factory).call{value: fee}("");
        require(sent3, "Failed to send MATIC for factory");

        return game.winner;
    }

    function stop(
        Name name_,
        Room room_,
        uint256 id_
    ) public returns(bool) {
        Game storage game = games[name_][room_][id_];
        require(
            msg.sender == game.player1,
            "Player not found"
        );
        require(
            game.time1 + 3600 <= block.timestamp,
            "Wait 1 hour"
        );
        require(
            game.move2 == 0,
            "Move 2 exists"
        );
        require(
            game.cipher[0] != 0,
            "Cipher not exists"
        );
        game.cipher = "";
        uint256 prize = getPrize(room_) / 2;
        (bool sent,) = payable(game.player1).call{value: prize}("");
        require(sent, "Failed to send MATIC for player1");
        return sent;
    }

    function splitMove(
        uint256 move_
    ) internal pure returns (bool[] memory) {
        bool[] memory arr = new bool[](6);
        arr[0] = (move_ % 1000000 / 100000) == 2;
        arr[1] = (move_ % 100000 / 10000) == 2;
        arr[2] = (move_ % 10000 / 1000) == 2;
        arr[3] = (move_ % 1000 / 100) == 2;
        arr[4] = (move_ % 100 / 10) == 2;
        arr[5] = (move_ % 10 / 1) == 2;
        bool kickTrue = true;
        bool defenceTrue = true;
        for (uint8 i = 0; i < 3; i++) {
            if (arr[i] == true && kickTrue) {
                kickTrue = false;
            } else {
                arr[i] = false;
            }
            if (arr[i + 3] == true && defenceTrue) {
                defenceTrue = false;
            } else {
                arr[i + 3] = false;
            }
        }
        return arr;
    }

    function getRoom(uint256 value_) public pure returns(Room room) {
        if (value_ == 1 * 10**18) {
            room = Room.One;
        } else if (value_ == 10 * 10**18) {
            room = Room.Ten;
        } else if (value_ == 100 * 10**18) {
            room = Room.Hundred;
        } else if (value_ == 1000 * 10**18) {
            room = Room.Thousand;
        } else {
            revert("Room 1,10,100,1000 MATIC");
        }
    }

    function getPrize(Room room_) internal pure returns(uint256 prize) {
        if (room_ == Room.One) {
            prize = 2 * 10**18;
        } else if (room_ == Room.Ten) {
            prize = 20 * 10**18;
        } else if (room_ == Room.Hundred) {
            prize = 200 * 10**18;
        } else if (room_ == Room.Thousand) {
            prize = 2000 * 10**18;
        } else {
            revert("Prize 2,20,200,2000 MATIC");
        }
    }

    function getId(Name name_, Room room_) public view returns(uint256) {
        return id[name_][room_];
    }

    function getGame(Name name_, Room room_, uint256 id_) public view returns(Game memory) {
        return games[name_][room_][id_];
    }

    function getCipher(uint256 move_, bytes32 proof_) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(move_, proof_));
    }

    function getProof(string calldata proof_) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(proof_));
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        Path memory r = requests[requestId];
        games[r.name][r.room][r.id].random = randomWords[0];
        games[r.name][r.room][r.id].time2 = block.timestamp;
    }

    function createNewSubscription() private {
        subId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subId, address(this));
    }

    function topUpSubscription(uint256 amount) external {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(subId));
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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