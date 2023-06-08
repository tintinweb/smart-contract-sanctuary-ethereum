// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract GameFactory is VRFConsumerBaseV2, ConfirmedOwner, AutomationCompatibleInterface {
    using SafeMath for uint256;
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    VRFCoordinatorV2Interface COORDINATOR;

    // Sepolia coordinator
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;

    // Sepolia gas lane
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    
    bool public factoryPaused = false; //change to true when deployed
    uint256 public platformFee = 1000; // Basis points (% = value/100)
    uint256 public communityFee = 0;
    uint256 public gameFee = 0;

    uint256 private totalFees;
    
    uint256 private nextCommunityId;
    uint256 private nextGameId;
    uint256 private nextEntryId;
    uint256 private nextPurchaseId;

    mapping(address => Community) private communities;
    mapping(uint256 => Game) private games;
    //mapping(uint256 => Entry) private entries;
    mapping(address => User) private users;
    mapping(uint256 => Purchase) private purchases;

    mapping(address => mapping(uint256 => bool)) hasEnteredGame;

    address[] private communityList;
    //address[] private userList;
    uint[] private openGames;
    uint[] private drawGames;
    uint[] private completedGames;
    uint[] private claimableGames;
    uint[] private closedGames;
    uint[] private upcomingGames;
    DiscountTier[] discounts;
    address private s_owner;

    // Chainlink subscription ID.
    uint64 s_subscriptionId;

    mapping(uint256 => RequestStatus)
        public s_requests;

    mapping(uint256 => PriceTier[5]) public prices;

    enum Status {
        Created,
        Open,
        Completed,
        Claimable,
        Closed
    }

    enum GameType {
        NftGame,
        EthGame,
        ERC20
    }

    struct DiscountTier {
        uint256 points;
        uint discountBasis;
    }

    struct User {
        address wallet;
        uint256[] purchaseList;
        uint256 points;
        bool hasValue;
    }

    struct Community {
        uint256[] gameList;
        uint256 id;
        string name;
        string description;
        string imageUrl;
        address owner;
        bool hasValue;
    }

    struct PriceTier {
        uint256 number;
        uint256 price;
    }

    struct Game {
        uint256 id;
        GameType typeOfGame;
        uint256 nextEntryId;
        address owner;
        Status status;
        string name;
        string image;
        string description;
        string community;
        uint256 interval;
        uint256 startTime;
        uint256 endTime;
        PriceTier[] prices;
        uint256 maxEntries;
        uint256 minStartingBalance;
        uint256 jackpot;
        uint256 winningEntry;
        address[] nfts;

        uint256[] purchaseList;
        uint256 uniqueEntrants;
        uint256 commission;
        uint256 lastRequestId;
        uint256 numberWinner;
        uint256 payout;
        uint32 callbackGasLimit;
        bool hasValue;    
    }

    struct Purchase {
        uint256 id;
        address owner;
        uint256 upperBound;
        uint256 parentGameId;
        uint256 amountSpent;
        uint256 numEntries;
    }

    struct Nft {
        address contractAddress;
        uint256 tokenId;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    constructor(uint64 subscriptionId) 
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) 
        ConfirmedOwner(msg.sender) 
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        nextCommunityId = 1;
        nextGameId = 1;
        nextEntryId = 1;
        totalFees = 0;
        s_subscriptionId = subscriptionId;
        s_owner = msg.sender;
    }

    function setCallbackGasLimit(uint256 lotto_id, uint32 new_limit) public {
        require(games[lotto_id].owner == msg.sender, "You do not own this lottery");
        games[lotto_id].callbackGasLimit = new_limit;
    }

    function calculateCommission(uint256 amount) internal view returns(uint256){
        return (amount.mul(platformFee)).div(10000);
    }

    function buyEntries(uint256 _gameId, uint256 _numEntries) public payable {
        require(!factoryPaused, "Game Factory is currently paused. Come back later");
        require(msg.sender != games[_gameId].owner, "You own the Game. You can not enter");

        //uint256 _entryPrice = games[_gameId].entryPrice;
        //require(msg.value >= _entryPrice, "Please send funds for the correct entry price");
        //require(games[_gameId].status == Status.Open, "Game is not currently open");
        bool matchingTierFlag = false;
        for(uint i = 0; i < 5; i++) {
            if((prices[_gameId][i].number == _numEntries) && (prices[_gameId][i].price == msg.value)) {
                matchingTierFlag = true;
            }
        }
        require(matchingTierFlag, "That is not a valid purchase");
        //uint256 _commission = calculateCommission(_entryPrice);
        //games[_gameId].commission = SafeMath.add(games[_gameId].commission, _commission);
        //totalFees = totalFees.add(_commission);
        //games[_gameId].jackpot.add(_entryPrice.sub(_commission));
        
        Purchase memory purchase = Purchase({
            id: nextPurchaseId,
            upperBound: nextEntryId + (_numEntries - 1),
            owner: msg.sender,
            parentGameId: _gameId,
            amountSpent: msg.value,
            numEntries: _numEntries
        });

        User memory user = users[msg.sender];
        if(!user.hasValue) {
            user.wallet = msg.sender;
            user.hasValue = true;
            users[msg.sender].purchaseList.push(purchase.id);
        } else {
            users[msg.sender].purchaseList.push(purchase.id);
        }
        if(!hasEnteredGame[msg.sender][_gameId]) {
            hasEnteredGame[msg.sender][_gameId] = true;
            games[_gameId].uniqueEntrants++;
        }
        purchases[purchase.id] = purchase;
        games[_gameId].purchaseList.push(purchase.id); 
        games[_gameId].nextEntryId += _numEntries;
        nextPurchaseId += 1;
        //emit EntryPurchased(msg.sender, entry.parentGameId, entry.id);
    }

    function getPurchase(uint256 _purchaseId) external view returns(Purchase memory) {
        Purchase memory _purchase = purchases[_purchaseId];
        return _purchase;
    }

    function getPurchaseListForGame(uint256 _gameId) external view returns(uint256[] memory) {
        uint256[] memory _purchases = games[_gameId].purchaseList;
        return _purchases;
    }

    function hasUserEntered(address _user, uint256 _gameId) external view returns(bool) {
        return hasEnteredGame[_user][_gameId];
    }

    function isGameComplete(uint _id) internal view returns(bool) {
        if(block.timestamp > games[_id].endTime) {
            return true;
        }
        return false;
    }

    function getOpenGames() external view returns (uint[] memory) {
        uint[] memory _openGames;
        _openGames = openGames;
        return _openGames;
    }

    function getDrawGames() external view returns (uint[] memory) {
        uint[] memory _drawGames;
        _drawGames = drawGames;
        return _drawGames;
    }

    function getCompletedGames() external view returns (uint[] memory) {
        uint[] memory _completedGames;
        _completedGames = completedGames;
        return _completedGames;
    }

    function getClaimableGames() external view returns (uint[] memory) {
        uint[] memory _claimableGames;
        _claimableGames = claimableGames;
        return _claimableGames;
    }

    function getUpcomingGames() external view returns (uint[] memory) {
        uint[] memory _upcomingGames;
        _upcomingGames = upcomingGames;
        return _upcomingGames;
    }


    function getCommunities() external view returns (address[] memory) {
        address[] memory _communityList;
        _communityList = communityList;
        return _communityList;
    }

    function getPriceTier(uint256 _gameId, uint _tierNum) external view returns (PriceTier memory) {
        PriceTier memory _prices;
       _prices = prices[_gameId][_tierNum];
        return _prices;
    }

    function getCommunityForOwner(address _owner) external view returns (Community memory) {
        Community memory _community = communities[_owner];
        return _community;
    }

    function removeGameArray(uint id, uint[] storage array) internal {
        uint index;
        for(uint j = 0; j < array.length; j++) {
            if( id == array[j]) {
                index = j;
            }
        }
        for(uint i = index; i < array.length-1; i++) {
            array[i] = array[i+1];      
        }
        array.pop();
    }

    /*function viewEntry(uint256 _entryId) external view returns (Entry memory) {
        Entry memory _entry;
        _entry = entries[_entryId];
        return (_entry);
    }*/

    function createCommunity(string memory _name, string memory _description, string memory _imageUrl) public payable {
        require(!factoryPaused, "Lottery Factory is currently paused. Come back later");
        require(msg.value >= communityFee, "Please pay community creation fee");
        require(!communities[msg.sender].hasValue, "You have already created a community");//add back after testing
        Community storage community = communities[msg.sender];
        community.id = nextCommunityId;
        community.name = _name;
        community.description = _description;
        community.owner = msg.sender;
        community.imageUrl = _imageUrl;
        community.hasValue = true;
        
        communityList.push(community.owner);
        nextCommunityId++;
        totalFees.add(msg.value);
        emit CommunityCreated(community);
    }

    event PurchaseMade(
        Purchase purchase
    );

    event GameCreated(
        Game game
    );

    event GameFunded(
        Game game
    );

    event GameStatusChange(
        Game game
    );

    event CommunityCreated(
        Community community
    );

    event UserCreated(
        User user
    );

    function fundGame(uint256 _id) external payable {
        require(games[_id].hasValue, "That is not a valid lottery ID");
        require(games[_id].owner == msg.sender, "You do not own this lottery");
        require(msg.value > 0, "Please send some amount of ether");
        uint256 fee = (msg.value * platformFee) / 10000;
        uint256 net = msg.value - fee;
        totalFees += fee;
        games[_id].jackpot += net;
        if(games[_id].jackpot >= games[_id].minStartingBalance) {
            startGame(_id);
        }
        emit GameFunded(games[_id]);
    }

    function createGame(
        string memory _name,
        string memory _description,
        string memory _imageUrl, 
        uint256 _interval,
        uint256 minStartingValue, 
        GameType _gameType, 
        PriceTier[] calldata _prices
    ) external payable {
        require(!factoryPaused, "Lottery Factory is currently paused. Come back later");
        require(msg.value >= gameFee, "Please pay the lottery fee");
        require(communities[msg.sender].hasValue, "You must own a community to create a game");

        PriceTier[] memory priceTiers = _prices;
        Game storage game = games[nextGameId];
        for(uint i = 0; i < priceTiers.length; i++) {
            require(priceTiers[i].number > 0, "All price tiers need an entry number" );
            PriceTier memory p = PriceTier({
                number: _prices[i].number,
                price: _prices[i].price
            });
            prices[nextGameId][i] = p;
        }
        
        game.id = nextGameId;
        game.interval = _interval;
        game.owner = msg.sender;
        game.name = _name;
        game.nextEntryId = 1;
        game.uniqueEntrants = 0;
        game.community = communities[msg.sender].name;
        game.description = _description;
        game.image = _imageUrl;
        game.typeOfGame = _gameType;
        game.callbackGasLimit = 2500000;
        game.status = Status.Created;
        game.minStartingBalance = minStartingValue;
        //game.startTime = block.timestamp;
        //game.endTime = _endTime;
        game.winningEntry = 0;
        game.hasValue = true;        
        communities[msg.sender].gameList.push(games[nextGameId].id);
        totalFees.add(msg.value);
        upcomingGames.push(nextGameId);
        nextGameId++;
        if(msg.value >= game.minStartingBalance) {
            startGame(game.id);
            //game.status = Status.Open;            
        } 
        emit GameCreated(
            game
        );
    }

    function startGame(uint256 _id) internal {
        removeGameArray(_id, upcomingGames);
        games[_id].startTime = block.timestamp;
        games[_id].endTime = games[_id].startTime + (games[_id].interval * 1 days);
        openGames.push(_id);
        emit GameStatusChange(games[_id]);
    }

    function getGameIdsForCommunity(address owner) external view returns(uint256[] memory) {
        uint256[] memory _games;
        _games = communities[owner].gameList;
        return _games;
    }

    function closeGame(uint256 _id) external onlyOwner {
        require(games[_id].status == Status.Open, "Lottery is not open");
        //require(block.timestamp > lotteries[_id].endTime, "Lottery is not over");
        //require(openLotteries.length > 0, "There are no lotteries to close");
        uint32 callbackGasLimit;
        uint256 requestId;

        games[_id].status = Status.Closed;
        callbackGasLimit = games[_id].callbackGasLimit;
        requestId = requestRandomWords();
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        games[_id].lastRequestId = requestId;
        removeGameArray(_id, openGames);
        drawGames.push(_id);
        emit GameStatusChange(games[_id]);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = false;
        for(uint x = 0; x < openGames.length; x++) {
            if(isGameComplete(openGames[x])) {
                upkeepNeeded = true;
            }
        }
        if(drawGames.length > 0) {
            upkeepNeeded = true;
        }
        //upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        closeManyGames();
        drawNumbers();
        //countWinners();
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function closeManyGames() internal {
        //uint32 _numWords;
        uint32 callbackGasLimit;
        uint256 requestId;
        uint _id;
        for(uint x = 0; x < openGames.length; x++) {
            _id = openGames[x];
            if(isGameComplete(openGames[x])) {
                games[_id].status = Status.Closed;
                callbackGasLimit = games[_id].callbackGasLimit;
                requestId = requestRandomWords();
                s_requests[requestId] = RequestStatus({
                    randomWords: new uint256[](0),
                    exists: true,
                    fulfilled: false
                });
                games[_id].lastRequestId = requestId;
                removeGameArray(_id, openGames);
                drawGames.push(_id);
                emit GameStatusChange(games[_id]);
            }
        }
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256) {
        // Will revert if subscription is not set and funded.
        uint256 returnRequest;
        returnRequest = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            2500000,
            1
        );
        return returnRequest;
    }

    function getRequestStatus(uint256 id
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        uint256 request_id = games[id].lastRequestId;
        require(s_requests[request_id].exists, "request not found");
        RequestStatus memory request = s_requests[request_id];
        return (request.fulfilled, request.randomWords);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "Request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function drawNumbers() internal {
        uint256 lastRequestId;
        uint256[] memory numArray;
        uint256 finalNumber;
        uint _id;
        uint256 numEntries;
        for(uint x = 0; x < drawGames.length; x++) {
            _id = drawGames[x];
            lastRequestId = games[_id].lastRequestId;
            numEntries = games[_id].nextEntryId - 1;
            if(s_requests[lastRequestId].fulfilled == true) {
                numArray = s_requests[lastRequestId].randomWords;
                finalNumber = numArray[0] % numEntries + 1;
                games[_id].winningEntry = finalNumber;
                games[_id].status = Status.Claimable;
                completedGames.push(_id);
                removeGameArray(_id, drawGames);
                emit GameStatusChange(games[_id]);
            }
        }
   }
  
   /*function getEntry(uint256 _id) public view returns(Entry memory) {
        return entries[_id];
    }*/

   function claimPrize(uint256 _gameId) external {
        require(games[_gameId].status == Status.Claimable, "Not Payable");
        //require(entries[games[_gameId].winningEntry].owner == msg.sender, "You are not a winner");
        uint256 payout = games[_gameId].jackpot;
        payable(msg.sender).transfer(payout);
        games[_gameId].status = Status.Closed;
        emit GameStatusChange(games[_gameId]);
   }

   function getUserPurchases(address _owner) external view returns(uint256[] memory) {
    uint256[] memory _purchases = users[_owner].purchaseList;
    
    // = users[_owner].purchaseList;
    return _purchases;
   }

    function getGame(uint256 id) external view returns(Game memory) {
        Game memory _game = games[id];
        return _game;
    }

    function setGameFee(uint256 _newFee) external onlyOwner {
        gameFee = _newFee;
    }

    function setPlatformFee(uint256 _newFee) external onlyOwner {
        platformFee = _newFee;
    }

    function setCommunityFee(uint256 _newFee) external onlyOwner {
        communityFee = _newFee;
    }

    function flipFactoryPaused(bool _paused) external onlyOwner {
        factoryPaused = _paused;
    }

    function setGameStatus(uint256 id, uint256 status) external onlyOwner {
        if (status == 0) {
            games[id].status = Status.Open;
        } else if (status == 1) {
            games[id].status = Status.Closed;
        }
        emit GameStatusChange(games[id]);
    }

    function withdrawFees(address payable _wallet) external onlyOwner {
        _wallet.transfer(totalFees);
        totalFees = 0;
    }

    // Remove this after testing
    function withdraw(address payable _wallet) external onlyOwner {
        _wallet.transfer(address(this).balance);
    }

    /*function entryPrice(uint _gameId) external view returns(uint) {
        return games[_gameId].entryPrice;
    }*/
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}