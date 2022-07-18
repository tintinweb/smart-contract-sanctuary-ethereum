// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { IERC721TokenReceiver } from "./interfaces/IERC721TokenReceiver.sol";
import { VRFConsumerBaseV2 } from "chainlink/v0.8/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title NFT Lotteries
/// @author Rohan Sanjay (https://github.com/rohansanjay/nft-lotteries)
/// @notice An NFT Betting Protocol
contract NFTLotteries is Owned, VRFConsumerBaseV2 {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/ 

    event NewLotteryListed(Lottery lottery);
    event LotteryCancelled(uint256 indexed lotteryId, Lottery lottery);
    event NewBet(Bet bet);
    event BetSettled(bool indexed won, Bet bet, Lottery lottery);
    event RakeSet(uint256 oldRake, uint256 newRake);
    
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error BetAmountZero();
    error InvalidPercent();
    error InsufficientFunds();
    error BetIsPending();
    error WrongLotteryId();
    error InvalidAddress();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Percents are 6-decimal places. Ex: 10 * 10**6 = 10%
    uint256 internal constant PERCENT_MULTIPLIER = 10**6;

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Parameters for Lotteries
    /// @param nftOwner The address of the original NFT owner
    /// @param nftCollection The collection of the NFT offered
    /// @param tokenId The Id of the NFT within the collection
    /// @param betAmount The required wager to win the NFT 
    /// @param winProbability The probability of winning the NFT (6-decimal places)
    /// @param betIsPending Store if a bet on the Lottery is pending
    struct Lottery {
        address nftOwner;
        ERC721 nftCollection;
        uint256 tokenId;
        uint256 betAmount;
        uint256 winProbability;
        bool betIsPending;
    }

    /// @dev Parameters for Bet
    /// @param lotteryId Lottery Id of Bet
    /// @param requestor Address of user making Bet
    struct Bet {
        uint256 lotteryId;
        address user;
    }

    /*//////////////////////////////////////////////////////////////
                            NFT LOTTERY STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice A list of all NFT Lotteries indexed by lottery Id
    mapping (uint256 => Lottery) public openLotteries;

    /// @notice The Id used for the next Lottery
    uint256 public nextLotteryId = 1;

    /// @notice Rake fee (6 decimals). ex: 10 * 10 ** 6 = 10%
    uint256 public rake;

    /// @notice Recipient of rake fee
    address public rakeRecipient;

    /*//////////////////////////////////////////////////////////////
                                VRF STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice VRF coordinator contract
    VRFCoordinatorV2Interface internal COORDINATOR;

    /// @notice VRF gas lane see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public keyHash;

    /// @notice VRF subscription Id used for funding requests
    uint64 public subscriptionId;

    /// @notice VRF callback request gas limit
    uint32 public callbackGasLimit = 50000;

    /// @notice VRF number of random values in one request
    uint32 internal numWords =  1;

    /// @notice VRF number of confirmations node waits before responding
    uint16 public requestConfirmations = 20;

    /// @notice VRF maps request Id corresponding Bet
    mapping(uint256 => Bet) public vrfRequestIdToBet;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates new NFT lottery contract and Chainlink VRF
    /// @param _subscriptionId The subscription Id the contract will use for funding requests
    /// @param _vrfCoordinator The address of the Chainlink VRF contract
    /// @param _keyHash The gas lane key hash value for VRF job
    /// @param _rake The rake fee
    /// @param _rakeRecipient The address that will receive the rake fee
    constructor(
        uint64 _subscriptionId, 
        address _vrfCoordinator, 
        bytes32 _keyHash,
        uint256 _rake,
        address _rakeRecipient
    ) Owned (msg.sender) VRFConsumerBaseV2(_vrfCoordinator) {
        if (_vrfCoordinator == address(0)) revert InvalidAddress();
        if (_rake > 100 * PERCENT_MULTIPLIER) revert InvalidPercent();
        if (_rakeRecipient == address(0)) revert InvalidAddress();

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        rake = _rake;
        rakeRecipient = _rakeRecipient;
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit NFT into contract and list lottery
    /// @param _nftCollection The contract address of the NFT collection
    /// @param _tokenId The id of the NFT within the collection
    /// @param _betAmount The required wager to win the NFT 
    /// @param _winProbability The probability of winning the NFT (6-decimal places)
    /// @return The id of the listed lottery
    function listLottery(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _betAmount,
        uint256 _winProbability
    ) external payable returns (uint256) {
        // The lister must own the NFT
        if (ERC721(_nftCollection).ownerOf(_tokenId) != msg.sender) revert Unauthorized();

        // The specified bet amount to win the NFT must be greater than 0
        if (_betAmount == 0) revert BetAmountZero();

        // The probability of winning must be > 0 and < 100
        if (_winProbability == 0 || _winProbability > 100 * PERCENT_MULTIPLIER) revert InvalidPercent();

        Lottery memory lottery = Lottery({
            nftOwner: msg.sender,
            nftCollection: ERC721(_nftCollection),
            tokenId: _tokenId,
            betAmount: _betAmount,
            winProbability: _winProbability,
            betIsPending: false
        });

        openLotteries[nextLotteryId] = lottery;

        emit NewLotteryListed(lottery);

        lottery.nftCollection.safeTransferFrom(msg.sender, address(this), lottery.tokenId);

        return nextLotteryId++;
    }

    /// @notice Cancel lottery and send NFT back to original owner
    /// @param _lotteryId The Id of the lottery to cancel
    function cancelLottery(uint256 _lotteryId) external payable {
        Lottery memory lottery = openLotteries[_lotteryId];

        // Only the original owner can withdraw
        if (lottery.nftOwner != msg.sender) revert Unauthorized(); 

        // Cannot cancel a Lottery if there is a pending bet
        if (lottery.betIsPending) revert BetIsPending();

        delete openLotteries[_lotteryId];

        emit LotteryCancelled(_lotteryId, lottery);

        lottery.nftCollection.safeTransferFrom(address(this), msg.sender, lottery.tokenId);
    }

    /// @notice User bets on NFT and function calls VRF for random number
    /// @param _lotteryId The Id of the lottery with NFT being bet on
    /// @return The VRF request Id
    function placeBet(uint256 _lotteryId) external payable returns (uint256) {
        Lottery memory lottery = openLotteries[_lotteryId];

        // Check if the Lottery Id is valid (win probability can't be 0)
        if (lottery.winProbability == 0) revert WrongLotteryId();

        // Cannot place a bet if there is already one pending (reentrancy check)
        if (lottery.betIsPending) revert BetIsPending();

        // Ensure funds sent cover betAmount specified by NFT owner
        if (msg.value < lottery.betAmount) revert InsufficientFunds(); 

        // Refund any extra ETH to sender
        if (msg.value > lottery.betAmount) {
            payable(msg.sender).transfer(msg.value - lottery.betAmount);
        }

        // Change betIsPending to true
        _flipBetIsPendingStatus(_lotteryId, lottery.betIsPending);

        // Send rake to rake recipient
        uint256 rakeAmount = (lottery.betAmount * rake) / (100 * PERCENT_MULTIPLIER);
        payable(rakeRecipient).transfer(rakeAmount);

        // Send bet amount to nft owner after deducting rake
        payable(lottery.nftOwner).transfer(lottery.betAmount - rakeAmount);

        // Random number generation
        uint256 requestId = requestRandomWords();

        Bet memory bet = Bet({
            lotteryId: _lotteryId,        
            user: msg.sender
        });

        emit NewBet(bet);

        vrfRequestIdToBet[requestId] = bet;

        return requestId;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/ 

    /// @notice Settles pending bet in a lottery by simulating random outcome
    /// @param _requestId The Id of the VRF request
    /// @param _randomNumber The random number generated by VRF
    function _settleBet(uint256 _requestId, uint256 _randomNumber) internal {
        Bet memory bet = vrfRequestIdToBet[_requestId];
        Lottery memory lottery = openLotteries[bet.lotteryId];

        // If random number is ≤ win probability, user wins the lottery (corresponds to lottery.winProbability chance of winning)
        if (_randomNumber <= lottery.winProbability) {
            delete openLotteries[bet.lotteryId];
            
            emit BetSettled(true, bet, lottery);

            lottery.nftCollection.safeTransferFrom(address(this), bet.user, lottery.tokenId); 
        } else {
            emit BetSettled(false, bet, lottery);

            // Change bet status from pending
            _flipBetIsPendingStatus(bet.lotteryId, lottery.betIsPending);
        }

        delete vrfRequestIdToBet[_requestId];
    }

    /// @notice Flips pending bet status
    /// @param _lotteryId The Id of the Lottery to change pending status for
    /// @param _status The current betIsPending value for the Lottery
    function _flipBetIsPendingStatus(uint256 _lotteryId, bool _status) internal {
        _status ? openLotteries[_lotteryId].betIsPending = false : openLotteries[_lotteryId].betIsPending = true;
    }

    /*//////////////////////////////////////////////////////////////
                                VRF LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requests random number from Chainlink VRF 
    /// @return The Id of the VRF request
    function requestRandomWords() internal returns (uint256) {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        // Return the requestId to the requester.
        return requestId;
    }

    /// @notice Receives random number from Chainlink VRF 
    /// @param requestId The Id initially returned by VRF request
    /// @param randomWords The VRF output 
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // convert number into range 0 to 100 * 10^6
        // TODO: confirm this!
        uint256 _randomNumber = randomWords[0] % (100 * PERCENT_MULTIPLIER + 1);

        // settle bet once VRF random number is returned
        _settleBet(requestId, _randomNumber);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRF key hash
    /// @dev Only owner
    /// @param _keyHash the new key hash
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /// @notice Sets VRF subscription Id
    /// @dev Only owner
    /// @param _subscriptionId the new subscription Id
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /// @notice Sets VRF callback gas limit
    /// @dev Only owner
    /// @param _callbackGasLimit the new callback gas limit
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    /// @notice Sets VRF number of confirmations
    /// @dev Only owner
    /// @param _requestConfirmations the new number of request confirmations
    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    /// @notice Sets the rake fee
    /// @dev Only owner
    /// @param _rake New rake fee (6 decimals ex: 10 * 10 ** 6 = 10%)
    function setRake(uint256 _rake) external onlyOwner {
        if (_rake > 100 * PERCENT_MULTIPLIER) revert InvalidPercent();

        emit RakeSet(rake, _rake);

        rake = _rake;
    }

    /// @notice Sets the rake fee recipient
    /// @dev Only owner
    /// @param _rakeRecipient Address of new rake fee recipient
    function setRakeRecipient(address _rakeRecipient) external onlyOwner {
        if (_rakeRecipient == address(0) || _rakeRecipient == address(rakeRecipient)) revert InvalidAddress();

        if (_rakeRecipient == rakeRecipient) revert InvalidAddress();

        rakeRecipient = _rakeRecipient;
    }

    /// @notice Sets the pending bet status to false for a lottery
    /// @dev Only owner (to unlock NFTs incase VRF reverts)
    /// @param _lotteryId The Id of the lottery
    function setPendingBetStatusToFalse(uint256 _lotteryId) external onlyOwner {
        _flipBetIsPendingStatus(_lotteryId, true);
    }

    /// @notice Sets a new bet amount for a lottery
    /// @param _lotteryId The Id of the lottery
    /// @param _betAmount New bet amount
    function setBetAmount(uint256 _lotteryId, uint256 _betAmount) external {
        // The specified bet amount to win the NFT must be greater than 0
        if (_betAmount == 0) revert BetAmountZero();

        Lottery memory lottery = openLotteries[_lotteryId];

        // Cannot change bet amount if there is already a bet pending
        if (lottery.betIsPending) revert BetIsPending();

        // Only the original owner can change the bet amount
        if (lottery.nftOwner != msg.sender) revert Unauthorized(); 

        lottery.betAmount = _betAmount;

        openLotteries[_lotteryId] = lottery;
    }

    /// @notice Sets a new win probability a lottery
    /// @param _lotteryId The Id of the lottery
    /// @param _winProbability New win probability
    function setWinProbability(uint256 _lotteryId, uint256 _winProbability) external {
        // The probability of winning must be > 0 and < 100
        if (_winProbability == 0 || _winProbability > 100 * PERCENT_MULTIPLIER) revert InvalidPercent();

        Lottery memory lottery = openLotteries[_lotteryId];

        // Cannot change win probability if there is already a bet pending
        if (lottery.betIsPending) revert BetIsPending();

        // Only the original owner can change the bet amount
        if (lottery.nftOwner != msg.sender) revert Unauthorized(); 

        lottery.winProbability = _winProbability;

        openLotteries[_lotteryId] = lottery;
    }

    /*//////////////////////////////////////////////////////////////
                         ERC-721 RECEIVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows this contract to custody ERC721 Tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
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