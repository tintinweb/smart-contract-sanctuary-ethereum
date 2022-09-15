// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

contract Battles is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address public mainBattleToken = 0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;
  mapping(uint256 => bytes32) private _battleSettleInit;
  mapping(bytes32 => uint256) private _battleSettleInitReqId;

  struct Battle {
    bytes32 id;
    uint256 allIndex;
    uint256 activeIndex;
    uint256 timestamp;
    address player1;
    address player2;
    address requiredPlayer2; // if player1 wants to battle specific address, provide here
    bool isNativeToken; // ETH, BNB, etc.
    address erc20Token;
    uint256 desiredAmount;
    uint256 actualAmount;
    bool isSettled;
    bool isCancelled;
  }
  bytes32[] public allBattles;
  bytes32[] public activeBattles;
  mapping(bytes32 => Battle) public battlesIndexed;

  uint256 public battleWinMainPercentage = (PERCENT_DENOMENATOR * 95) / 100; // 95% wager amount
  uint256 public battleWinAltPercentage = (PERCENT_DENOMENATOR * 90) / 100; // 90% wager amount
  uint256 public battleAmountBattled;
  uint256 public battlesInitiatorWon;
  uint256 public battlesChallengerWon;
  mapping(address => uint256) public battlesUserWon;
  mapping(address => uint256) public battlesUserLost;
  mapping(address => uint256) public battleUserAmountWon;
  mapping(address => uint256) public battleUserAmountLost;
  mapping(address => bool) public lastBattleWon;

  event CreateBattle(
    bytes32 indexed battleId,
    address player1,
    bool isNative,
    address erc20Token,
    uint256 amountWagered
  );
  event CancelBattle(bytes32 indexed battleId);
  event EnterBattle(
    bytes32 indexed battleId,
    uint256 requestId,
    address player1,
    address player2,
    bool isNative,
    address erc20Token,
    uint256 amountWagered
  );
  event SettledBattle(
    bytes32 indexed battleId,
    uint256 requestId,
    address player1,
    address player2,
    bool isNative,
    address erc20Token,
    uint256 amountWagered,
    address winner,
    uint256 amountWon
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function createBattle(
    bool _isNative,
    address _erc20,
    uint256 _amount,
    address _requiredPlayer2
  ) external payable {
    uint256 _actualAmount = _amount;
    if (_isNative) {
      require(
        msg.value >= _amount + getFinalServiceFeeWei(),
        'not enough ETH in wallet to battle this much'
      );
    } else {
      IERC20 token = IERC20(_erc20);
      require(
        token.balanceOf(msg.sender) > _amount,
        'not enough of token in wallet to battle this much'
      );
      uint256 _balBefore = token.balanceOf(address(this));
      token.transferFrom(msg.sender, address(this), _amount);
      _actualAmount = token.balanceOf(address(this)) - _balBefore;
    }

    bytes32 _battleId = getBattleId(
      msg.sender,
      _isNative,
      _erc20,
      block.timestamp
    );
    require(battlesIndexed[_battleId].timestamp == 0, 'battle already created');

    battlesIndexed[_battleId] = Battle({
      id: _battleId,
      allIndex: allBattles.length,
      activeIndex: activeBattles.length,
      timestamp: block.timestamp,
      player1: msg.sender,
      player2: address(0),
      requiredPlayer2: _requiredPlayer2,
      isNativeToken: _isNative,
      erc20Token: _erc20,
      desiredAmount: _amount,
      actualAmount: _actualAmount,
      isSettled: false,
      isCancelled: false
    });
    allBattles.push(_battleId);
    activeBattles.push(_battleId);

    _payServiceFee();
    emit CreateBattle(_battleId, msg.sender, _isNative, _erc20, _amount);
  }

  function cancelBattle(bytes32 _battleId) external {
    Battle storage _battle = battlesIndexed[_battleId];
    require(_battle.timestamp > 0, 'battle not created yet');
    require(
      _battle.player1 == msg.sender || owner() == msg.sender,
      'user not authorized to cancel'
    );
    require(
      _battle.player2 == address(0),
      'battle settlement is already underway'
    );
    require(
      !_battle.isSettled && !_battle.isCancelled,
      'battle already settled or cancelled'
    );

    _battle.isCancelled = true;
    _removeActiveBattle(_battle.activeIndex);

    if (_battle.isNativeToken) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_battle.player1).call{
        value: _battle.actualAmount
      }('');
      require(success, 'could not refund player1 original battle fee');
      require(
        address(this).balance >= _balBefore - _battle.actualAmount,
        'too much withdrawn'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      token.transfer(_battle.player1, _battle.actualAmount);
    }
    emit CancelBattle(_battleId);
  }

  function enterBattle(bytes32 _battleId) external payable {
    require(_battleSettleInitReqId[_battleId] == 0, 'already initiated');
    _payServiceFee();
    Battle storage _battle = battlesIndexed[_battleId];
    require(
      _battle.requiredPlayer2 == address(0) ||
        _battle.requiredPlayer2 == msg.sender,
      'battler is invalid user'
    );
    _battle.player2 = msg.sender;
    if (_battle.isNativeToken) {
      require(
        msg.value >= _battle.actualAmount + getFinalServiceFeeWei(),
        'not enough ETH in wallet to battle this much'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      uint256 _balBefore = token.balanceOf(address(this));
      token.transferFrom(msg.sender, address(this), _battle.desiredAmount);
      require(
        token.balanceOf(address(this)) >= _balBefore + _battle.actualAmount,
        'not enough transferred probably because of token taxes'
      );
    }

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );
    _battleSettleInit[requestId] = _battleId;
    _battleSettleInitReqId[_battleId] = requestId;

    _removeActiveBattle(_battle.activeIndex);

    emit EnterBattle(
      _battleId,
      requestId,
      _battle.player1,
      _battle.player2,
      _battle.isNativeToken,
      _battle.erc20Token,
      _battle.actualAmount
    );
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleBattle(requestId, randomWords[0]);
  }

  function manualFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settleBattle(requestId, randomWords[0]);
  }

  function _settleBattle(uint256 requestId, uint256 randomNumber) private {
    bytes32 _battleId = _battleSettleInit[requestId];
    Battle storage _battle = battlesIndexed[_battleId];
    require(!_battle.isSettled, 'battle already settled');
    _battle.isSettled = true;

    uint256 _feePercentage = _battle.isNativeToken
      ? battleWinAltPercentage
      : _battle.erc20Token == mainBattleToken
      ? battleWinMainPercentage
      : battleWinAltPercentage;
    uint256 _amountToWin = _battle.actualAmount +
      (_battle.actualAmount * _feePercentage) /
      PERCENT_DENOMENATOR;

    address _winner = randomNumber % 2 == 0 ? _battle.player1 : _battle.player2;
    address _loser = _battle.player1 == _winner
      ? _battle.player2
      : _battle.player1;
    if (_battle.isNativeToken) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_winner).call{ value: _amountToWin }('');
      require(success, 'could not pay winner battle winnings');
      require(
        address(this).balance >= _balBefore - _amountToWin,
        'too much withdrawn'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      token.transfer(_winner, _amountToWin);

      if (_battle.erc20Token == mainBattleToken) {
        _addPlayThrough(_battle.player1, _battle.desiredAmount);
        _addPlayThrough(_battle.player2, _battle.desiredAmount);
      }
    }

    battleAmountBattled += _battle.desiredAmount * 2;
    battlesInitiatorWon += randomNumber % 2 == 0 ? 1 : 0;
    battlesChallengerWon += randomNumber % 2 == 0 ? 0 : 1;
    battlesUserWon[_winner]++;
    battlesUserLost[_loser]++;
    battleUserAmountWon[_winner] += _amountToWin - _battle.actualAmount;
    battleUserAmountLost[_loser] += _battle.desiredAmount;
    lastBattleWon[_winner] = true;
    lastBattleWon[_loser] = false;

    // emit SettledBattle(_battleId, _winner, _amountToWin);
    emit SettledBattle(
      _battleId,
      requestId,
      _battle.player1,
      _battle.player2,
      _battle.isNativeToken,
      _battle.erc20Token,
      _battle.actualAmount,
      _winner,
      _amountToWin
    );
  }

  function _removeActiveBattle(uint256 _activeIndex) internal {
    if (activeBattles.length > 1) {
      activeBattles[_activeIndex] = activeBattles[activeBattles.length - 1];
      battlesIndexed[activeBattles[_activeIndex]].activeIndex = _activeIndex;
    }
    activeBattles.pop();
  }

  function _addPlayThrough(address _user, uint256 _amount) internal {
    ISmoltingInu(mainBattleToken).addPlayThrough(
      _user,
      _amount,
      percentageWagerTowardsRewards
    );
  }

  function getBattleId(
    address _player1,
    bool _isNative,
    address _erc20Token,
    uint256 _timestamp
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(_player1, _isNative, _erc20Token, _timestamp));
  }

  function getNumBattles() external view returns (uint256) {
    return allBattles.length;
  }

  function getNumActiveBattles() external view returns (uint256) {
    return activeBattles.length;
  }

  function getAllActiveBattles() external view returns (Battle[] memory) {
    Battle[] memory _battles = new Battle[](activeBattles.length);
    for (uint256 i = 0; i < activeBattles.length; i++) {
      _battles[i] = battlesIndexed[activeBattles[i]];
    }
    return _battles;
  }

  function setMainBattleToken(address _token) external onlyOwner {
    mainBattleToken = _token;
  }

  function setBattleWinMainPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    battleWinMainPercentage = _percentage;
  }

  function setBattleWinAltPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    battleWinAltPercentage = _percentage;
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev SmoltingInu token interface
 */

interface ISmoltingInu is IERC20 {
  function gameMint(address _user, uint256 _amount) external;

  function gameBurn(address _user, uint256 _amount) external;

  function addPlayThrough(
    address _user,
    uint256 _amountWagered,
    uint8 _percentContribution
  ) external;

  function setCanSellWithoutElevation(address _wallet, bool _canSellWithoutElev)
    external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/ISmolGame.sol';
import './interfaces/ISmolGameFeeAdjuster.sol';

contract SmolGame is ISmolGame, Ownable {
  address payable public treasury;
  uint256 public serviceFeeUSDCents = 200; // $2
  uint8 public percentageWagerTowardsRewards = 0; // 0%

  address[] public walletsPlayed;
  mapping(address => bool) internal _walletsPlayedIndexed;

  ISmolGameFeeAdjuster internal _feeDiscounter;
  AggregatorV3Interface internal _feeUSDConverterFeed;

  uint256 public gameMinWagerAbsolute;
  uint256 public gameMaxWagerAbsolute;
  uint256 public gameMinWhaleWagerAbsolute = 500 * 10**18;
  uint256 public gameMaxWhaleWagerAbsolute;
  mapping(address => bool) public isGameWhale;

  constructor(address _clPriceFeed) {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    _feeUSDConverterFeed = AggregatorV3Interface(_clPriceFeed);
  }

  function _payServiceFee() internal {
    uint256 _serviceFeeWei = getFinalServiceFeeWei();
    if (_serviceFeeWei > 0) {
      require(msg.value >= _serviceFeeWei, 'not able to pay service fee');
      address payable _treasury = treasury == address(0)
        ? payable(owner())
        : treasury;
      (bool success, ) = _treasury.call{ value: msg.value }('');
      require(success, 'could not pay service fee');
    }
    if (!_walletsPlayedIndexed[msg.sender]) {
      walletsPlayed.push(msg.sender);
      _walletsPlayedIndexed[msg.sender] = true;
    }
  }

  function getFinalServiceFeeWei() public view override returns (uint256) {
    uint256 _serviceFeeWei = getBaseServiceFeeWei(serviceFeeUSDCents);
    if (address(_feeDiscounter) != address(0)) {
      _serviceFeeWei = _feeDiscounter.getFinalServiceFeeWei(_serviceFeeWei);
    }
    return _serviceFeeWei;
  }

  function getBaseServiceFeeWei(uint256 _costUSDCents)
    public
    view
    override
    returns (uint256)
  {
    // Creates a USD balance with 18 decimals
    uint256 paymentUSD18 = (10**18 * _costUSDCents) / 100;

    // adding back 18 decimals to get returned value in wei
    return (10**18 * paymentUSD18) / _getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function _getLatestETHPrice() internal view returns (uint256) {
    uint8 decimals = _feeUSDConverterFeed.decimals();
    (, int256 price, , , ) = _feeUSDConverterFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function _enforceMinMaxWagerLogic(address _wagerer, uint256 _wagerAmount)
    internal
    view
  {
    if (isGameWhale[_wagerer]) {
      require(
        _wagerAmount >= gameMinWhaleWagerAbsolute,
        'does not meet minimum whale amount requirements'
      );
      require(
        gameMaxWhaleWagerAbsolute == 0 ||
          _wagerAmount <= gameMaxWhaleWagerAbsolute,
        'exceeds maximum whale amount requirements'
      );
    } else {
      require(
        _wagerAmount >= gameMinWagerAbsolute,
        'does not meet minimum amount requirements'
      );
      require(
        gameMaxWagerAbsolute == 0 || _wagerAmount <= gameMaxWagerAbsolute,
        'exceeds maximum amount requirements'
      );
    }
  }

  function getNumberWalletsPlayed() external view returns (uint256) {
    return walletsPlayed.length;
  }

  function getFeeDiscounter() external view returns (address) {
    return address(_feeDiscounter);
  }

  function setFeeDiscounter(address _discounter) external onlyOwner {
    _feeDiscounter = ISmolGameFeeAdjuster(_discounter);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = payable(_treasury);
  }

  function setServiceFeeUSDCents(uint256 _cents) external onlyOwner {
    serviceFeeUSDCents = _cents;
  }

  function setPercentageWagerTowardsRewards(uint8 _percent) external onlyOwner {
    require(_percent <= 100, 'cannot be more than 100%');
    percentageWagerTowardsRewards = _percent;
  }

  function setGameMinWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMinWagerAbsolute = _amount;
  }

  function setGameMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMaxWagerAbsolute = _amount;
  }

  function setGameMinWhaleWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMinWhaleWagerAbsolute = _amount;
  }

  function setGameMaxWhaleWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMaxWhaleWagerAbsolute = _amount;
  }

  function setIsGameWhale(address _user, bool _isWhale) external onlyOwner {
    isGameWhale[_user] = _isWhale;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.9;

/**
 * @dev ISmolGame interface
 */

interface ISmolGame {
  function getFinalServiceFeeWei() external view returns (uint256);

  function getBaseServiceFeeWei(uint256 costUSDCents)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev ISmolGameFeeAdjuster interface
 */

interface ISmolGameFeeAdjuster {
  function getFinalServiceFeeWei(uint256 _baseFeeWei)
    external
    view
    returns (uint256);
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
pragma solidity ^0.8.9;

import './interfaces/AggregatorProxy.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title PricePrediction
 * @dev Predict if price goes up or down over a time period
 */
contract PricePrediction is SmolGame {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  struct PredictionConfig {
    uint256 timePeriodSeconds;
    uint256 payoutPercentage;
  }
  struct Prediction {
    address priceFeedProxy;
    uint256 configTimePeriodSeconds;
    uint256 configPayoutPercentage;
    bool isLong; // true if price should go higher, otherwise price expected to go lower
    uint256 amountWagered;
    uint16 startPhaseId;
    uint80 startRoundId;
    uint16 endPhaseId; // not set until prediction is settled
    uint80 endRoundId; // not set until prediction is settled
    bool isDraw; // not set until prediction is settled
    bool isWinner; // not set until prediction is settled
  }

  uint256 public minBalancePerc = (PERCENT_DENOMENATOR * 35) / 100; // 35% user's balance
  uint256 public minWagerAbsolute;
  uint256 public maxWagerAbsolute;
  uint8 public maxOpenPredictions = 20;

  uint80 public roundIdStartOffset = 1;

  address[] public validPriceFeedProxies;
  mapping(address => bool) public isValidPriceFeedProxy;

  PredictionConfig[] public predictionOptions;

  address public smol = 0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e;
  ISmoltingInu private smolContract = ISmoltingInu(smol);

  uint256 public totalPredictionsMade;
  uint256 public totalPredictionsWon;
  uint256 public totalPredictionsLost;
  uint256 public totalPredictionsDraw;
  uint256 public totalPredictionsAmountWon;
  uint256 public totalPredictionsAmountLost;
  // user => predictions[]
  mapping(address => Prediction[]) public predictions;
  mapping(address => uint256[]) public openPredictions;
  mapping(address => uint256) public predictionsUserWon;
  mapping(address => uint256) public predictionsUserLost;
  mapping(address => uint256) public predictionsUserDraw;
  mapping(address => uint256) public predictionsAmountUserWon;
  mapping(address => uint256) public predictionsAmountUserLost;

  event Predict(
    address indexed user,
    address indexed proxy,
    uint16 startPhase,
    uint80 startRound,
    uint256 amountWager
  );
  event Settle(
    address indexed user,
    address indexed proxy,
    bool isWinner,
    bool isDraw,
    uint256 amountWon
  );

  constructor(address _nativeUSDFeed) SmolGame(_nativeUSDFeed) {}

  function getAllValidPriceFeeds() external view returns (address[] memory) {
    return validPriceFeedProxies;
  }

  function getNumberUserPredictions(address _user)
    external
    view
    returns (uint256)
  {
    return predictions[_user].length;
  }

  function getOpenUserPredictions(address _user)
    external
    view
    returns (Prediction[] memory)
  {
    uint256[] memory _indexes = openPredictions[_user];
    Prediction[] memory _open = new Prediction[](_indexes.length);
    for (uint256 i = 0; i < _indexes.length; i++) {
      _open[i] = predictions[_user][_indexes[i]];
    }
    return _open;
  }

  function getLatestUserPrediction(address _user)
    external
    view
    returns (Prediction memory)
  {
    require(predictions[_user].length > 0, 'no predictions for user');
    return predictions[_user][predictions[_user].length - 1];
  }

  /**
   * Returns the latest price with returned value from a price feed proxy at 18 decimals
   * more info (proxy vs agg) here:
   * https://stackoverflow.com/questions/70377502/what-is-the-best-way-to-access-historical-price-data-from-chainlink-on-a-token-i/70389049#70389049
   *
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getRoundInfoAndPriceUSD(address _proxy)
    public
    view
    returns (
      uint16,
      uint80,
      uint256
    )
  {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint16 phaseId = priceFeed.phaseId();
    uint8 decimals = priceFeed.decimals();
    (uint80 proxyRoundId, int256 price, , , ) = priceFeed.latestRoundData();
    return (phaseId, proxyRoundId, uint256(price) * (10**18 / 10**decimals));
  }

  function getPriceUSDAtRound(address _proxy, uint80 _roundId)
    public
    view
    returns (uint256)
  {
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.getRoundData(_roundId);
    return uint256(price) * (10**18 / 10**decimals);
  }

  // https://docs.chain.link/docs/historical-price-data/
  function getHistoricalPriceFromAggregatorInfo(
    address _proxy,
    uint16 _phaseId,
    uint80 _aggRoundId,
    bool _requireCompletion
  )
    public
    view
    returns (
      uint80,
      uint256,
      uint256,
      uint80
    )
  {
    AggregatorProxy proxy = AggregatorProxy(_proxy);
    uint80 _proxyRoundId = _getProxyRoundId(_phaseId, _aggRoundId);
    (
      uint80 roundId,
      int256 price,
      ,
      uint256 timestamp,
      uint80 answeredInRound
    ) = proxy.getRoundData(_proxyRoundId);
    uint8 decimals = proxy.decimals();
    if (_requireCompletion) {
      require(timestamp > 0, 'Round not complete');
    }
    return (
      roundId,
      uint256(price) * (10**18 / 10**decimals),
      timestamp,
      answeredInRound
    );
  }

  // _isLong: if true, user wants price to go up, else price should go down
  function predict(
    uint256 _configIndex,
    address _priceFeedProxy,
    uint256 _amountWager,
    bool _isLong
  ) external payable {
    require(
      isValidPriceFeedProxy[_priceFeedProxy],
      'not a valid price feed to predict'
    );
    require(
      _amountWager >=
        (smolContract.balanceOf(msg.sender) * minBalancePerc) /
          PERCENT_DENOMENATOR,
      'did not wager enough of balance'
    );
    require(_amountWager >= minWagerAbsolute, 'did not wager at least minimum');
    require(
      maxWagerAbsolute == 0 || _amountWager <= maxWagerAbsolute,
      'wagering more than maximum'
    );

    address _user = msg.sender;
    require(
      openPredictions[_user].length <= maxOpenPredictions,
      'cannot exceed max open predictions at a time'
    );

    if (predictions[_user].length > 0) {
      Prediction memory _openPrediction = predictions[_user][
        predictions[_user].length - 1
      ];
      require(
        _openPrediction.endRoundId > 0,
        'there is an open prediction you must settle before creating a new one'
      );
    }

    _enforceMinMaxWagerLogic(msg.sender, _amountWager);
    smolContract.transferFrom(msg.sender, address(this), _amountWager);
    smolContract.addPlayThrough(
      msg.sender,
      _amountWager,
      percentageWagerTowardsRewards
    );
    (uint16 _phaseId, uint80 _proxyRoundId, ) = getRoundInfoAndPriceUSD(
      _priceFeedProxy
    );
    (, uint64 _aggRoundId) = getAggregatorPhaseAndRoundId(_proxyRoundId);
    uint80 _startRoundId = _getProxyRoundId(
      _phaseId,
      _aggRoundId + roundIdStartOffset
    );

    PredictionConfig memory _config = predictionOptions[_configIndex];
    require(_config.timePeriodSeconds > 0, 'invalid config provided');

    Prediction memory _newPrediction = Prediction({
      priceFeedProxy: _priceFeedProxy,
      configTimePeriodSeconds: _config.timePeriodSeconds,
      configPayoutPercentage: _config.payoutPercentage,
      isLong: _isLong,
      amountWagered: _amountWager,
      startPhaseId: _phaseId,
      startRoundId: _startRoundId,
      endPhaseId: 0,
      endRoundId: 0,
      isDraw: false,
      isWinner: false
    });
    openPredictions[_user].push(predictions[_user].length);
    predictions[_user].push(_newPrediction);

    totalPredictionsMade++;
    _payServiceFee();
    emit Predict(
      msg.sender,
      _priceFeedProxy,
      _phaseId,
      _startRoundId,
      _amountWager
    );
  }

  // in order to settle an open prediction, the settling executor must know the
  // user with the open prediction they are settling and the round ID that corresponds
  // to the time it should be settled.
  function settlePrediction(
    address _user,
    uint256 _openPredIndex,
    uint16 _answeredPhaseId,
    uint80 _answeredAggRoundId
  ) public {
    _user = _user == address(0) ? msg.sender : _user;
    require(predictions[_user].length > 0, 'no predictions created yet');
    uint256 _predIndex = openPredictions[_user][_openPredIndex];
    Prediction storage _openPrediction = predictions[_user][_predIndex];
    require(
      _openPrediction.priceFeedProxy != address(0),
      'no predictions created yet to settle'
    );
    require(
      _openPrediction.endRoundId == 0,
      'latest prediction already settled'
    );

    (uint256 priceStart, uint80 roundActual) = _validateAndGetPriceInfo(
      _openPrediction,
      _answeredPhaseId,
      _answeredAggRoundId
    );

    uint256 settlePrice = getPriceUSDAtRound(
      _openPrediction.priceFeedProxy,
      roundActual
    );

    bool _isDraw = settlePrice == priceStart;
    bool _isWinner = false;
    if (!_isDraw) {
      _isWinner = _openPrediction.isLong
        ? settlePrice > priceStart
        : settlePrice < priceStart;
    }

    _openPrediction.endPhaseId = _answeredPhaseId;
    _openPrediction.endRoundId = roundActual;
    _openPrediction.isDraw = _isDraw;
    _openPrediction.isWinner = _isWinner;

    uint256 _finalWinAmount = _isWinner
      ? (_openPrediction.amountWagered *
        _openPrediction.configPayoutPercentage) / PERCENT_DENOMENATOR
      : 0;

    if (_isDraw || _isWinner) {
      smolContract.transfer(_user, _openPrediction.amountWagered);
      if (_finalWinAmount > 0) {
        smolContract.gameMint(_user, _finalWinAmount);
      }
    } else {
      smolContract.gameBurn(address(this), _openPrediction.amountWagered);
    }

    openPredictions[_user][_openPredIndex] = openPredictions[_user][
      openPredictions[_user].length - 1
    ];
    openPredictions[_user].pop();
    _updateAnalytics(
      _user,
      _isDraw,
      _isWinner,
      _openPrediction.amountWagered,
      _finalWinAmount
    );

    emit Settle(
      _user,
      _openPrediction.priceFeedProxy,
      _isWinner,
      _isDraw,
      _finalWinAmount
    );
  }

  function settlePredictionShortCircuitLoss(uint256 _openPredIndex) external {
    require(predictions[msg.sender].length > 0, 'no predictions created yet');
    uint256 _predIndex = openPredictions[msg.sender][_openPredIndex];
    Prediction storage _prediction = predictions[msg.sender][_predIndex];
    require(
      _prediction.priceFeedProxy != address(0),
      'no predictions created yet to settle'
    );
    require(_prediction.endRoundId == 0, 'prediction already settled');
    // just set the end phase and round to the start if we short circuit here
    _prediction.endPhaseId = _prediction.startPhaseId;
    _prediction.endRoundId = _prediction.startRoundId;
    smolContract.gameBurn(address(this), _prediction.amountWagered);
    openPredictions[msg.sender][_openPredIndex] = openPredictions[msg.sender][
      openPredictions[msg.sender].length - 1
    ];
    openPredictions[msg.sender].pop();
    _updateAnalytics(msg.sender, false, false, _prediction.amountWagered, 0);
    emit Settle(msg.sender, _prediction.priceFeedProxy, false, false, 0);
  }

  function settleMultiplePredictions(
    address[] memory _users,
    uint256[] memory _openIndexes,
    uint16[] memory _phaseIds,
    uint80[] memory _aggRoundIds
  ) external {
    require(
      _users.length == _openIndexes.length,
      'need to be same size arrays'
    );
    require(_users.length == _phaseIds.length, 'need to be same size arrays');
    require(
      _users.length == _aggRoundIds.length,
      'need to be same size arrays'
    );
    for (uint256 i = 0; i < _users.length; i++) {
      settlePrediction(
        _users[i],
        _openIndexes[i],
        _phaseIds[i],
        _aggRoundIds[i]
      );
    }
  }

  function _validateAndGetPriceInfo(
    Prediction memory _openPrediction,
    uint16 _answeredPhaseId,
    uint80 _answeredAggRoundId
  ) internal view returns (uint256, uint80) {
    (
      ,
      uint256 priceStart,
      uint256 timestampStart,
      uint80 answeredInRoundIdStart
    ) = getHistoricalPriceFromAggregatorInfo(
        _openPrediction.priceFeedProxy,
        _openPrediction.startPhaseId,
        _openPrediction.startRoundId,
        true
      );
    require(
      answeredInRoundIdStart > 0 && timestampStart > 0,
      'start round is not fresh'
    );
    (
      uint80 roundActual,
      ,
      uint256 timestampActual,

    ) = getHistoricalPriceFromAggregatorInfo(
        _openPrediction.priceFeedProxy,
        _answeredPhaseId,
        _answeredAggRoundId,
        true
      );
    (, , uint256 timestampAfter, ) = getHistoricalPriceFromAggregatorInfo(
      _openPrediction.priceFeedProxy,
      _answeredPhaseId,
      _answeredAggRoundId + 1,
      false
    );
    require(
      roundActual > 0 && timestampActual > 0,
      'actual round not finished yet'
    );
    require(
      timestampActual <=
        timestampStart + _openPrediction.configTimePeriodSeconds,
      'actual round was completed after our time period'
    );
    require(
      timestampAfter >
        timestampStart + _openPrediction.configTimePeriodSeconds ||
        (timestampAfter == 0 &&
          block.timestamp >
          timestampStart + _openPrediction.configTimePeriodSeconds),
      'after round was completed before our time period'
    );
    return (priceStart, roundActual);
  }

  function _updateAnalytics(
    address _user,
    bool _isDraw,
    bool _isWinner,
    uint256 _amountWagered,
    uint256 _finalWinAmount
  ) internal {
    totalPredictionsWon += _isWinner ? 1 : 0;
    predictionsUserWon[_user] += _isWinner ? 1 : 0;
    totalPredictionsLost += !_isWinner && !_isDraw ? 1 : 0;
    predictionsUserLost[_user] += !_isWinner && !_isDraw ? 1 : 0;
    totalPredictionsDraw += _isDraw ? 1 : 0;
    predictionsUserDraw[_user] += _isDraw ? 1 : 0;
    totalPredictionsAmountWon += _isWinner ? _finalWinAmount : 0;
    predictionsAmountUserWon[_user] += _isWinner ? _finalWinAmount : 0;
    totalPredictionsAmountLost += !_isWinner && !_isDraw ? _amountWagered : 0;
    predictionsAmountUserLost[_user] += !_isWinner && !_isDraw
      ? _amountWagered
      : 0;
  }

  function _getProxyRoundId(uint16 _phaseId, uint80 _aggRoundId)
    internal
    pure
    returns (uint80)
  {
    return uint80((uint256(_phaseId) << 64) | _aggRoundId);
  }

  function getAggregatorPhaseAndRoundId(uint256 _proxyRoundId)
    public
    pure
    returns (uint16, uint64)
  {
    uint16 phaseId = uint16(_proxyRoundId >> 64);
    uint64 aggregatorRoundId = uint64(_proxyRoundId);
    return (phaseId, aggregatorRoundId);
  }

  function getAllPredictionOptions()
    external
    view
    returns (PredictionConfig[] memory)
  {
    return predictionOptions;
  }

  function setMinBalancePerc(uint256 _perc) external onlyOwner {
    require(_perc <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    minBalancePerc = _perc;
  }

  function setMinWagerAbsolute(uint256 _amount) external onlyOwner {
    minWagerAbsolute = _amount;
  }

  function setMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    maxWagerAbsolute = _amount;
  }

  function setMaxOpenPredictions(uint8 _amount) external onlyOwner {
    maxOpenPredictions = _amount;
  }

  function addPredictionOption(uint256 _seconds, uint256 _percentage)
    external
    onlyOwner
  {
    require(_seconds > 60, 'must be longer than 60 seconds');
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    predictionOptions.push(
      PredictionConfig({
        timePeriodSeconds: _seconds,
        payoutPercentage: _percentage
      })
    );
  }

  function removePredictionOption(uint256 _index) external onlyOwner {
    predictionOptions[_index] = predictionOptions[predictionOptions.length - 1];
    predictionOptions.pop();
  }

  function updatePredictionOption(
    uint256 _index,
    uint256 _seconds,
    uint256 _percentage
  ) external onlyOwner {
    PredictionConfig storage _pred = predictionOptions[_index];
    _pred.timePeriodSeconds = _seconds;
    _pred.payoutPercentage = _percentage;
  }

  function setWagerToken(address _token) external onlyOwner {
    smol = _token;
    smolContract = ISmoltingInu(_token);
  }

  function setRoundIdStartOffset(uint80 _offset) external onlyOwner {
    require(_offset > 0, 'must be at least an offset of 1 round');
    roundIdStartOffset = _offset;
  }

  function addPriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        require(false, 'price feed already in feed list');
      }
    }
    isValidPriceFeedProxy[_proxy] = true;
    validPriceFeedProxies.push(_proxy);
  }

  function removePriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        delete isValidPriceFeedProxy[_proxy];
        validPriceFeedProxies[i] = validPriceFeedProxies[
          validPriceFeedProxies.length - 1
        ];
        validPriceFeedProxies.pop();
        break;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';

/**
 * @dev Interface for chainlink feed proxy, that contains info
 * about all aggregators for data feed
 */

interface AggregatorProxy is AggregatorV2V3Interface {
  function aggregator() external view returns (address);

  function phaseId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

/******************************************************************************************************
smolting inu (SMOL)

Website: https://smoltinginu.com
Twitter: https://twitter.com/smoltinginu
Telegram: https://t.me/smoltinginu

smolting, wassies, & inus unite!

all da lil shids, y r u here... u no y, for smolting inu!

SMOL wil sen wit hayste, cum joyn us frens
_______________________________________________________________________________________________________
Brand new innovative features:
  1. Nuke SMOL tokens from the liquidity pool on sells. This means over time sells will have less of a
     price impact and keep the price floor lifted, where buys have the full impact.
  2. Initial elevated sell tax that you can reduce by "flipping coins" using Chainlink VRF
     for your chance to both double your bag IN ADDITION TO remove sell tax elevation.
     See FLIP A COIN below
  3. Perpetual ETH biggest buyer reward every single hour, paid out on any transfer after
     that hour is completed, forever


TOKENOMICS

4% taxes - SELL ONLY
  - 1% token burn
  - 1% hourly biggest buy rewards
  - 2% auto LP (lowers price impact, support whales long term)

buy: 0%
sell: 8/4% -- 8% default, reduced to 4% when you flip a coin for SMOL (see FLIP A COIN below on reducing sell tax)


HOURLY BIGGEST BUYER REWARD

We keep track of the biggest buyer (defined by the number of SMOL received) every hour, and this buyer
will receive a portion of the contract ETH balance on the subsequent trade following the completion of the hour.
Keep an eye our in your wallet for ETH to come flowing in if you are the biggest buyer within an hour.


FLIP A COIN (DOUBLE YOUR BAG & REDUCE SELL TAX)

We offer the ability to flip a coin (using Chainlink verifiable random functions for true randomization)
where you can wager a portion of your SMOL bag, and if you win you will win that amount back to your wallet
IN ADDITION TO remove the default elevated sell tax.

discuss

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl',cdx:.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;,''';cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,'lkOOOx,;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl..;cllc;'..:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.,xOOOOOO:'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc..oOOOOOOko,..cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.;xOOOOOOOl'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl .oOOOOOOOOOkl. 'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.,xOOOOOOOOl'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..cOOOOOOOOOOOOx;..:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.'dOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,xOOOOOOOOOOOOOkl. .dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.,dOOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOx:. ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl'.:xOOOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .dOOOOkdolodxkOOOOOko,..;xKWMMMMWWWNNXXXKK00OOkxdolc;'.'cdOOOOOOOOOOOOOo'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; 'xOOOo;',,,,,',lxOOOOko;. .;clc:;,,''''.......''',;:coxkOOOOOOOOOOOOOOOx,;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,kOOk:.:ccc:'':okOOOOOOOxl;,'.',;;:cclllooddxxkkOOOOOOOOOOOOOOOOOOOOOOOOd,;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,xOOk;':ccc,.ckOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx:':kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; 'xOOk:.:cccc,.,okOOOOOOOOOOOOOOOOOOkxddollllloodxkOOOOOOOOOOOOOOOOOOOOOOOOOd:,;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX: .oOOOl.;cc;,,,:okOOOOOOOOOOOOOkdl:;;;;;;:::::::;;;::ldkOOOOOOOOOOOOOOOOOOOOOOxo;,,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo .cOOOd'.',;cdkOOOOOOOOOOOOOxl:;;:coxkkOOOOOOOOOkkdoc;,;:lxOOOOOOkkxddolllllllllc:,....;okKWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ;kOOkc,cdkOOOOOOOOOOOOOko;,;cdkOOOOOOOOOOOOOOOOOOOOOkdc,,;cc:::::::::ccccccccccccc:;'...';lkXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .dOOOOkOOOOOOOOOOOOOOOOkocdkOOOOOOOOOOOOOOOOOOOOOOOOOOOkd:..,oxxkkOOOOOOOOOOOOOOOOOOOkkxol:::coxKWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxddollccc::ccc:'.'lxOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdl::cd0WMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0; .ckOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxo:;;;;;:::::ccccc:::,'',:loxOOOOOOOkxollcc:::::::::::ccllc;,lXMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxo;,;:loollcc::::::::ccllodolc;,cxdoc:::;;,,,,,,,,,,,,,,,,;;;;;'.ckXWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc .ckOOOOOOOOOO000KK00OOOOOOOOOOOOOOkxo:,,,:ooc:;;,''''..''''',,,,,;;;:c'.,,,'',,;;;;,,,,,'....''',,,;,,;;,,,xWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo. ;kOOOOOOOOOO0KKKKKKK00OOOOOOkxdoc:;,;:clc:,''''...  .:ccc:;;,,'''',,,,,',,;;;:ccc:,'....  .,;,,''....'',,,.'OWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. 'xOOOOOOOOOO0KKKKKKKKKK0OOOOOxc;;;;::::;,'....       .cKMMWWNXK0kdl:,'''';lool:,..  ...    .lXNXK0kdl:,'.....,dXMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl .lOOOOOOOOOO0KKKKKKKKKKK0Okdc::;;;;;;,,'...    ,odl'    :KMMMMMMMMMMWNKko,.,:,.     'xOOl.   .dWMMMMMMWN0xl,....xMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, .dOOOOOOOOO0KKKKKKKKKKKKK0o'';::ccll:'.   ...  :kOx,     oWMMMMMMMMMMMMMMO.    .;;. .cdo;     ,KMMMMMMMMMMMN0d'.lNMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' 'xOOOOOOOOO0KKKKKKKKKKKKK0x:,;;;;,,.      ,o;   ...      :NMMMMMMMMMMMMMMk.    .:;.           '0MMMMMMMMMMMMMWx.,0MM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' ,xOOOOOOOO0KKKKKKKKKKKKKK0OOkxxxxdl,.                    oWMMMMMMMMMMMMMX:                    :XMMMMMMMMMMWNKd,.dNMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. ;kOOOOOOOO0KKKKKKKKKKKKKKK0OOOOOOOOkd:'.                ;KMMMMMMMMMWN0xl,.                   ;0WMWWNX0Oxol:,..;OWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. cOOOOOOOO00KKKKKKKKKKKKKKKK00OOOOOkocoxdc;,.           :0NNNNNX0Oxl:,'',:,..'.              .;lc::;,,''',,,,.'kMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX: .dOOOOOOOO0KKKKKKKKKKKKKKKKKKK000OOOd:,,;cloooc:,'.... .',,,;;,,,',;:ldxdc';xkxdlc::;,,,,,,,,,;;::clodxkd:;:coOWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..lkOOOOOOOO0KKKKKKKKKKKKKKKKKKKKKK00OOOkdl:;;;;;::ccclllllcccllllooollc:;,;lkOOOOOOOOOOOOOOOOOOOOOOOOOOOo,;kXWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'.:kOOOOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKK00OOOOOOkkdocc:;;;;;;::;;:;;;;;'.,cloxOOOOOOOOOOOOOOOOOOOOOOOOOOOko;,lKMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;xOOOOOOOOO00KKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOkkkkkkxxkkxo:,,:xOOOOOOOOdccoxkkOOOOOOOOOOkkxoc:;:o0WMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWx.'dOOOOOOOOOO0KKKKKKOxollx0KKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOkdlc;,,:lxOOOOOOOOOOxl:;;;,,;::::::;;,,,..;ONMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMK,.lOOOOOOOOOOO0KKKK0d:;:c,.:OKKKKKKKKKKKKKKKK00OOOOOOOOOkdlc:;;,;:ldkOOOOOOOOOOOOOOOOOkxl,..,:ccccloxxd:,cOWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNo.:kOOOOOOOOOOO0KKKKx,:xOOx;.l0KKKKKKKKKKKKKKKKK00OOOOOOOkl::loxkOOOOOOOOOOOOOOOOOOOOOOOOOkocldddooodxkOOd:,l0WMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMO''dOOOOOOOOOOOO0KKKKo'lkkkkd,'xKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdlc;,'....    ...':okd;,oXMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNc.cOOOOOOOOOOOOO0KKKKx,:kOkkkd:;d0KKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;..        .......    ,oko,;OWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMk.,xOOOOOOOOOOOOO0KKKK0c'okkkkkkl;lOKKKKKKKKKKKKKKK0kolldxOOOOOOOOOOOOOOOOOOOOOOOOOx;.     .........',;,,..  .oOx:,dNMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMX:.lOOOOOOOOOOOOOO0KKKKKO:,dkkkkkkdc:oOKKKKKKKKKKKOkl......,cokOOOOOOOOOOOOOOOOOOOOk:   ...............,,'.    :kOkl,lKMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWx.'xOOOOOOOOOOOOOO0KKKKKKk;:xOkkkkOkdccok0KKKKKKK0l...;cc:;'..';lxOOOOOOOOOOOOOOOOOx'       ...........'..    .oOOOOo':KMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMX:.ckOOOOOOOOOOOOOOO0KKKKKKd,lkkkkkkkkkxlclok0KKK0x' .;ccccccc:,...;lxOOOOOOOOOOOOOOkc.         .........     .ckOOOOOc.oWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMk..dOOOOOOOOOOOOOOOO0KKKKKK0c;dOkkkOkkkkkkdccccloxo' .:cc;,,:cccc:;...;lxOOOOOOOOOOOOkl'         ........    .ckOOOOkd,..lxKWMM
MMMMMMMMMMMMMMMMMMMMMMNc ;kOOOOOOOOOOOOOOOO0KKKKKKKx;ckkkkkkkkkkkkkkxl:;;,. .,cc:,...',:ccc:,...;okOOOOOOOOOOOko,.       .....     'lkOOkdc,..','.'lKM
MMMMMMMMMMMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOO00KKKKKK0:;xOkkkkkkkkkkkkkkkkkxol,.,:cccc;,...,:ccc:,...:okOOOOOOOOOOkxl;..          .,lxkxo:,..';ccccc'.cX
MMMMMMMMMMMMMMMMMMMMMWo..dOOOOOOOOOOOOOOOOOO0KKKKKKKo,oOkkkkkkkkkkkkkkkkkkOOxc'.',:cccc:,'..,:ccc:,...;ldkOOOOOOOOOOkxolc::;::clool:,'..,:cccccccc;.:X
MMMMMMMMMMMMMMMMMMMMMX; ,xOOOOOOOOOOOOOOOOOOO0KKKKKKx':kkkkkkkkkkOkkkkkkkkkOOkxo:,'.';cccc:,..',:ccc:,...';:lodxxxxxxdddollc:;,''..',;ccccccccccc:..dW
MMMMMMMMMMMMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOO0KKKKKKk',xOkkkkkkkkkkkkkkkkkkkkkkkkkxl;'.',:ccc:,...,:cccc:,'....''''''.......'',;:ccccccccccccc:;'.,xNM
MMMMMMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOOOOOO0KKKKKk,'dOkkkkkkkkkkkkkkkkkkkkkkkOkkOkxo:,.',:ccc:,...',:cccccc:::::::::cccccccccccccccc::;,'......:0WM
MMMMMMMMMMMMMMMMMMMMNl .oOOOOOOOOOOOOOOOOOOOOOO0KKKKO,.lOkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkd:,..,:ccc:;'....'',;;;::::::;;;;,,,,'''''..........',::,.'oX
MMMMMMMMMMMMMMMMMMMMNc .oOOOOOOOOOOOOOOOOOOOOOOO00KKO;.cOOkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkdc,.',:ccccc:;,''...................''',,;;:::cccccccc:'.:
MMMMMMMMMMMMMMMMMMMMX: .oOOOOOOOOOOOOOOOOOOOOOOOOO0KO;.ckOkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkkdc,..,:cccccccccccccccccccccccccccccccccccccccccccccc'.
MMMMMMMMMMMMMMMMMMMM0' 'dOOOOOOOOOOOOOOOOOOOOOOOOOO0k;.:kOkkkkkkkkkkkkxddxxxkkkkkkkkkkkkkkkkkkOkkkdc,..';:ccccccccccccccccccccccccccccccccccccccccc:..
MMMMMMMMMMMMMMMMMMMWx. ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kkkkkkkkkkkkkkkxdddddxxkkkkkkkkkkkkkkkkkOOkkkdc;'..',;;::ccccccccccccccccccccccccccccccc:;'.'d
MMMMMMMMMMMMMMMMMMMNc  :OOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kkkkkkkkkkkkkOkxxdddddddxxkkkkkkkkkkkkkkkOkkOkkkxdl:;,'''...................''''''''''',,;lxXW
MMMMMMMMMMMMMMMMMMMX; .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.ckkkkkkkkkkkkkkkkkxdddddddddxxxkkkkkkkkkkkkkkkkkkkkkkkkkxddoolllllcc:::::;..ckkOOOOOOO00KNWMMMM
MMMMMMMMMMMMMMMMMMMX; .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.lOkkkkkkkkkkkkkkkkkxddddddddddddxxxkkkkkkkkkkkkkOOOkkkkkxxxkkkOOkOkkxddddl.'OMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMK, .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lOkkkkkkkkkkkkkkkkkkkxxdddddddddddddxxxkkkkkkkkkkxxxxxxddddxkkOkkOkkxdddd:.;XMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMO. .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddxxxxxxxdddddddddddxkkkkkkkkkxdddd;.lNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWx. 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'xOkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddxkkkOkkkkkkxddddo'.dWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWo  ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.,xOkkkkkkkkkkkkkkkkOkkkkOOkkxxdddddddddddddddddddddddddxxkkkkkkkkkkkxddddl..OMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNc  :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.:kOkkkOkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddxxkkkkkkkkkkkkkkxdddd:.,KMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMX: .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddxxxkkkkkkkkkkkkkkkxddddd; cNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMM0' 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxkkkkkkkkkkkkkkkkkkxxddddo'.oWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWx. :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkOkkOkxdddddl..xMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWl .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddc.'OMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMX: .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;.:kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddd; ;KMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMK, ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddd, cNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMO. ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOk:.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddo'.oWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMk. cOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..lOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddl..xMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOOOOOOOOOOOOk: ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddc.'OMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWo .oOOOOOOOOOOOOOOOOOOOOOOOOOOOd'.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd; ,KMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWl .dOOOOOOOOOOOOOOOOOOOOOOOOOOOc..dOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxkOkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd; cNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOOk, ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;.ckkkkkkkkkkkkkkkkkkkkkkkkkkkOkxdddddddo,.oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN: ;kOOOOOOOOOOOOOOOOOOOOOOOOOOd..ckkkOkkkkkkkkkkkkkkkkkkkkOkkkkdccc,;xkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddo..xMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMX; :kOOOOOOOOOOOOOOOOOOOOOOOOOOc..oOkkkkkkkkkkkkkkkkkkkkkkkkkkxccxKo:xOkkkkkkkkkkkkkkkkkkkkkkkkkkOkxddddddddl..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMK, cOOOOOOOOOOOOOOOOOOOOOOOOOOk; 'dOkOkkkkkkkkkkkkkkkkkkkkOkko:oXM0clkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl.'0MMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOx' ;xOkkkkkkkkkkkkkkkkkkkOkkkko:xNMMO:okkOkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOo. ckkkkkkkkkkkkkkkkkkkkkkkOxo:oNMMMKcckkkOkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWd..dOOOOOOOOOOOOOOOOOOOOOOOOOOc..lkkkkkkkkkkkkkkkkkkkkkkkkl,:0MMMMWd:dOkkkkkkOkkkkkkkkkkkkkkkkkkkkkxddddddddo,.kMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOk: .dOkkkkkkkkkkkkkkkkkkkkkkkc'cKMMMMMXl:xOkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.dWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK, ;kOOOOOOOOOOOOOOOOOOOOOOOOOk; 'xOkkOkkkkkkkkkkkkkkkkkkkkc'cKMMMMMMKl:dkkkOkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.lNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMk. :kOOOOOOOOOOOOOOOOOOOOOOOOOx' ,xOkkkkkkkkkkkkkkkkkkkkkkko;:OMMMMMMMNx:lxkkkkOkkkkkkkkkkkkkkkkkkkxdddddddddd: ,KMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWd..cOOOOOOOOOOOOOOOOOOOOOOOOOOd. :kkkkkkkkkkkkkkkkkkkkkkkOOxd:lXMMMMMMMWKdccdkkOkkkkkkkkkkkkkkkkkkkxllddddddddc..xWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNl .oOOOOOOOOOOOOOOOOOOOOOOOOOOo..ckkkkkkkkkkkkkkkkkkkkkkOkkkkd:dNMMMMMMMMWXxocloxkkOkkkOkkkkkkkkdoc,.:ddddddddl. :XMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMX; .dOOOOOOOOOOOOOOOOOOOOOOOOOOo..okkkkkkkkkkkkkkkkkkkkkkkkkOkkd:oKWMMMMMMMMMWKkdolllloooooolllloodl,;oddddddddl. .dWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMX; 'xOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkOkkOkkkkkkkkkkkkkkkkkkkOkkkOxlcdKWMMMMMMMMMMMWXKOkxxxxxxxk0KNXx:codddddddddl.  'OMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM0' ;kOOOOOOOOOOOOOOOOOOOOOOOOOOd..dOkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkdlcokXWMMMMMMMMMMMMMMMMMMMMMNKxlcoxddddddddddo....:XMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOOOOOOOOOd..oOkkkkkkkkkkkkkkkkkkkkkkkOkkkkkOkkxocloxOKNWMMMMMMMMMMWWX0kdolldkkxddddddddddo'.,..xWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMk. cOOOOOOOOOOOOOOOOOOOOOOOOOOOd'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkdllloddxxkkkkxxddollldxkkkkkxddddddddddd, ;; ;KMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWx..lOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdoolllloodxkkkkkOkkkkkxxdddddddddd, ,l..xWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWo..dOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.:kOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,d; cNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWl 'dOOOOOOOOOOOOOOOOOOOOOOOOOOOk; ;kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xl.'OMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOk: ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xx' oWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMN: ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xk: ,0MMMMMMMMMMMMMMM
MMMMMMMMMMMMMX; :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xOl..dWMMMMMMMMMMMMMM
MMMMMMMMMMMMMK,.cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'dOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xOd. cNMMMMMMMMMMMMMM
MMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xOk; ;KMMMMMMMMMMMMMM
MMMMMMMMMMMMMO..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,kOOc '0MMMMMMMMMMMMMM
MMMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ;kOOo..kMMMMMMMMMMMMMM
MMMMMMMMMMMMMx..dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.lkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ;kOOd..dWMMMMMMMMMMMMM
MMMMMMMMMMMMWd.'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.:kOOx' lWMMMMMMMMMMMMM
MMMMMMMMMMMMWo.,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..oOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.cOOOk;.lNMMMMMMMMMMMMM
MMMMMMMMMMMMNl ,kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,.cOOOO:.:NMMMMMMMMMMMMM
MMMMMMMMMMMMNc ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,.lOOOOl.,KMMMMMMMMMMMMM
MMMMMMMMMMMMX; :OOOOOOOOOOOOOOOOOOOOOOOOOOOOOk:.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkxdddddddddd,.lOOOOo..OMMMMMMMMMMMMM
MMMMMMMMMMMMK, cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.:kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkxdddddddddd,.lOOOOd..xMMMMMMMMMMMMM
MMMMMMMMMMMMK,.cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo..lOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkxdddddddddo'.oOOOOd..dWMMMMMMMMMMMM
MMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOOOk: 'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddo'.oOOOOx,.oWMMMMMMMMMMMM
MMMMMMMMMMMMO..lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk, lWMMMMMMMMMMMM
MMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOc..oOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..dOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMMx..oOOOOOOOOOOOOOOOOOOOOOOOOOOOx, ;xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..dOOOOk:.lWMMMMMMMMMMMM
MMMMMMMMMMMWd..dOOOOOOOOOOOOOOOOOOOOOOOOOOOl..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk:.lWMMMMMMMMMMMM
MMMMMMMMMMMWo .dOOOOOOOOOOOOOOOOOOOOOOOOOOx' ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMWl 'xOOOOOOOOOOOOOOOOOOOOOOOOOkc..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddc..oOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMNc 'xOOOOOOOOOOOOOOOOOOOOOOOOOd' ;xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd:..oOOOOk,.oWMMMMMMMMMMMM
MMMMMMMMMMMX: ,xOOOOOOOOOOOOOOOOOOOOOOOOk: .okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOx'.dWMMMMMMMMMMMM
MMMMMMMMMMMK, ;kOOOOOOOOOOOOOOOOOOOOOOOOo. :kkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOd..xMMMMMMMMMMMMM
MMMMMMMMMMM0' ;kOOOOOOOOOOOOOOOOOOOOOOOx, 'dOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOd..kMMMMMMMMMMMMM
MMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOOOOOk: .ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .dOOOOo..OMMMMMMMMMMMMM
MMMMMMMMMMMk. :OOOOOOOOOOOOOOOOOOOOOOOo. ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd, .dOOOOc.'0MMMMMMMMMMMMM
MMMMMMMMMMMx. cOOOOOOOOOOOOOOOOOOOOOOd' .okkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo' .dOOOk: ;XMMMMMMMMMMMMM
MMMMMMMMMMWd..cOOOOOOOOOOOOOOOOOOOOOx; .ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo' .dOOOk; cNMMMMMMMMMMMMM
MMMMMMMMMMWo .lOOOOOOOOOOOOOOOOOOOOkc. ;xkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'dOOOx'.dWMMMMMMMMMMMMM
MMMMMMMMMMWo .lOOOOOOOOOOOOOOOOOOOOl. 'dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOOo..OMMMMMMMMMMMMMM
MMMMMMMMMMWl .oOOOOOOOOOOOOOOOOOOOo. .okkOkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOOc.:XMMMMMMMMMMMMMM
MMMMMMMMMMNc .dOOOOOOOOOOOOOOOOOOd. .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOx,.dWMMMMMMMMMMMMMM
MMMMMMMMMMNc .dOOOOOOOOOOOOOOOOOd' .ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOl.'0MMMMMMMMMMMMMMM
MMMMMMMMMMNc 'dOOOOOOOOOOOOOOOOd' .:kOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. ,xOx, cNMMMMMMMMMMMMMMM
MMMMMMMMMMX: 'xOOOOOOOOOOOOOOko. .ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. ,xOc..kMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ,xOOOOOOOOOOOOOkc. .ckOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddc. ,xd. cNMMMMMMMMMMMMMMMM
MMMMMMMMMMN: ,xOOOOOOOOOOOOx;  .okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd:. ,d; .OMMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ;kOOOOOOOOOOkl.  ;dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  ':. lNMMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ;kOOOOOOOOko,  .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  .. ,0MMMMMMMMMMMMMMMMMM
MMMMMMMMMMK; :OOOOOOOkd;. .:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;    .dWMMMMMMMMMMMMMMMMMM
MMMMMMMMMM0, cOOOOOko,. .;dkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;    cXMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMO. cOOkdc'  .:dkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd,   ,0MMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMx..:oc'. .,lxkOkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo'  .xWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWo  .    .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl.  cNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWo. .:xd. ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkxdddddddddl. .xMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNOOXXx'.'okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkxdddddddddc. .OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWKo'..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  ,0MMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNOc...cdkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,  :NMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWXx;..,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkxdddddddddl. .dWMMMMMMMMMMMMMMMMMMMMMM
MMMMW0l...:okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;  ,KMMMMMMMMMMMMMMMMMMMMMMM
MMXk:..,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddddc. .dWMMMMMMMMMMMMMMMMMMMMMMM
Xd'..:dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddl'  cXMMMMMMMMMMMMMMMMMMMMMMMM
; .:dkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddo'  :KMMMMMMMMMMMMMMMMMMMMMMMMM
:. .';cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdddddddddddddddl'  :KMMMMMMMMMMMMMMMMMMMMMMMMMM
N0dl;....;cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddo:. .lXMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWXOo:....;ldkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl'  'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWXkl;. .':oxkkkkkkkkkkkkkkkkkkkkkxxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl,. .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWKxc'...;ldkkkkkkkkkkkkkkxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo:'. .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN0d;. .,cdkkkkkkkxxxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddol:;..   .lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWKxc'..':odxxddddddddddddddddddddddddddddddddddddooolcccccccccccccccclllllllcccc:;;,'... ......  ..,cdOKWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWNOl,...;coddddddddddddddddddddddddddolc:;,''..... ............   ......       ....,;:clooolcc:,..  .,lx0NWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMN0d:. .';clodddddddddddddoolc;,'.....',:lodxx;.:llllllccc::::::;;;;;;;:::ccllooooooooooodkOOkxo:,.. .':oOXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx. ......',;;;;;;,,'.........;x0KNWMMMMMWo.:ooooooooooooooooooooooooooooooooooooooooxOOOOOOOOkdl;'.  .:oONMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. 'lc:,'.........',,;:cllol:;dXMMMMMMMMWo...,,:clooooooooooooooooooooooooooooooodxkOOOOOOOOOOOOOkxl;'. .'lONMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. 'loooooollllloooooooooooooc;c0WMMMMMMM0l,...  ..';codxddddddoooooooooooooooddxkOOOOOOOOOOOOOOOOOOOkdc,.  'l0WMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. 'odooooooooooooooddxxxxdddoo;,dNMMMMMMMMWXKOxo:'.  .'cdkOOkkkkxxdddooddddxkkOOOOOOOOOOOOOOOOOOOOOOOOOOxl,. .:kNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. ,xOkxddooooooddxkkOOOOOOOkkkkl,lXMMMMMMMMMMMMMWN0d:.  .,lkOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkd:. .:OWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ,xOOOOkkkxxxkkOOOOOOOOOOOOOOOOl':KMMMMMMMMMMMMMMMMWXx:.  'okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxxdoollllllllloool'  .xWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOkl.:KMMMMMMMMMMMMMMMMMMW0l. .;xOOOOOOOOOOOOOOOOOOOOOOOOxl;,...      ...      .    .OMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkl.;KMMMMMMMMMMMMMMMMMMMWKl. .okOOOOOOOOOOOOOOOOOOOOOOc  .,clodxkkOOOOkkxddool:;':0MMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkc.:KMMMMMMMMMMMMMMMMMMMMW0:..:xOOOOOOOOOOOOOOOOOOOOOl. '0MMMMMMMMMMMMMMMMMMMMWNWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  :kOOOOOOOOOOOOOOOOOOOkdoxkOOOOOOk:.cXMMMMMMMMMMMMMMMMMMMMMNx'.,dOOOOOOOOOOOOOOOOOOOOx,  oNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. 'dOOOOOOOOOOOOOOOOOOOd'..,:okOOOOk;.dWMMMMMMMMMMMMMMMMMMMMMMKc..lkOOOxolllodxxkOOOOOOo. .xWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .cOOOOOOOOOOOOOOOOOOOo.'xx:'':dkOOd''OMMMMMMMMMMMMMMMMMMMMMMMNx..;xOo'      ...',:cldxc. .kWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl  'dOko:;:lxOOOOOOOOOOl.,KMW0d;.,cxkl.:XMMMMMMMMMMMMMMMMMMMMMMMW0;..l; .lxdolc:,...   ..   .xNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  :xc. .  .,cdkOOOOOOc ,KMMMMNOl,';:..kMMMMMMMMMMMMMMMMMMMMMMMMMXo.   lNMMMMMWWNK0kdl;'.   .kWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK: .'. c0Oo;. .,cxOOOO: ,KMMMMMMMXkc. .dWMMMMMMMMMMMMMMMMMMMMMMMMMWk;.,OMMMMMMMMMMMMMMWNKOdldKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'  :KMMMW0d;. .;okk: ,KMMMMMMMMMWKddKMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkkXMMMMMMMW0o,. .;' ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'   :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl''xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/ISmoltingInu.sol';

contract SmoltingInu is ISmoltingInu, ERC20, Ownable {
  int256 internal constant OFFSET19700101 = 2440588;
  uint256 internal constant ONE_DAY = 1 days;
  uint256 internal constant ONE_HOUR = 1 hours;
  uint256 internal constant PERCENT_DENOMENATOR = 1000;
  address internal constant DEAD = address(0xdead);

  uint256 public minRakeBackPlayThrough = 1000 * 10**18;
  uint256 public rakeBackPercentage = 50; // 5%
  uint256 public totalPlayThrough;
  mapping(address => uint256) public userPlayThrough;
  // user => month => amount
  mapping(address => mapping(uint256 => uint256)) public userMonthlyPlayThrough;
  // user => month => amount
  mapping(address => mapping(uint256 => uint256)) public userPlayThroughClaimed;

  uint256 public minTransferForSideEffectsToRecipient;

  uint256 public biggestBuyRewardPercentage = (PERCENT_DENOMENATOR * 20) / 100; // 20%
  uint256 public maxBuyerRewardBuyPercentage = (PERCENT_DENOMENATOR * 5) / 100; // 5%
  mapping(uint256 => address) public biggestBuyer;
  mapping(uint256 => uint256) public biggestBuyerAmount;
  mapping(uint256 => uint256) public biggestBuyerPaid;
  uint256 public lastBiggestBuyerHour;
  uint256 public currentBiggestBuyerHour;

  address internal _lpReceiver;
  address internal _nukeRecipient = DEAD;
  uint256 public lpNukeBuildup;
  uint256 public nukePercentPerSell = (PERCENT_DENOMENATOR * 5) / 100; // 5%
  bool public lpNukeEnabled = true;

  mapping(address => bool) internal _isTaxExcluded;

  uint256 public taxBurn = (PERCENT_DENOMENATOR * 1) / 100; // 1%
  uint256 public taxBuyer = (PERCENT_DENOMENATOR * 1) / 100; // 1%
  uint256 public taxLp = (PERCENT_DENOMENATOR * 3) / 100; // 3%
  uint256 public sellTaxUnwageredMultiplier = 20; // init 8% (4% * 2)
  uint256 internal _totalTax;
  bool internal _taxesOff;
  mapping(address => bool) public canSellWithoutElevation;

  mapping(address => uint256) public lastGameWin;
  uint256 public gameWinSellPenaltyTimeSeconds = 1 hours; // 1 hour
  uint256 public gameWinSellPenaltyMultiplier = 30; // init 12% (4% * 3)

  uint256 internal _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100; // 1%
  uint256 public launchTime;
  uint256 public launchTimeTopHour;
  uint256 public launchTimeTopMonth;
  uint256 internal _launchBlock;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => bool) internal _isBot;

  mapping(address => bool) public isGameContract;
  mapping(address => bool) public isPlayBlacklisted;

  bool internal _swapEnabled = true;
  bool internal _swapping = false;

  event GameMint(address indexed wagerer, uint256 amount);
  event GameBurn(address indexed wagerer, uint256 amount);
  event AddPlayThrough(address indexed wagerer, uint256 amount);
  event CanSellWithoutElevation(
    address indexed wagerer,
    bool canSellWithoutElev
  );

  modifier onlyGame() {
    require(isGameContract[_msgSender()], 'not a smol game');
    _;
  }

  modifier swapLock() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20('smolting inu', 'SMOL') {
    _mint(address(this), 1_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _setTotalTax();
    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[msg.sender] = true;
  }

  // _percent: 1 == 0.1%, 1000 = 100%
  function launch(uint16 _percent) external payable onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be between 0-100%');
    require(launchTime == 0, 'already launched');
    require(_percent == 0 || msg.value > 0, 'need ETH for initial LP');

    uint256 _lpSupply = (totalSupply() * _percent) / PERCENT_DENOMENATOR;
    uint256 _leftover = totalSupply() - _lpSupply;
    if (_lpSupply > 0) {
      _addLp(_lpSupply, msg.value);
    }
    if (_leftover > 0) {
      _transfer(address(this), owner(), _leftover);
    }
    uint256 _topHourDiff = block.timestamp % ONE_HOUR;
    uint256 _year = _getYear(block.timestamp);
    uint256 _month = _getMonth(block.timestamp);
    launchTime = block.timestamp;
    launchTimeTopHour = block.timestamp - _topHourDiff;
    launchTimeTopMonth = _timestampFromDate(_year, _month, 1);
    _launchBlock = block.number;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() || recipient == owner();
    uint256 contractTokenBalance = balanceOf(address(this));

    bool _isContract = sender == address(this) || recipient == address(this);
    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    uint256 _hourAfterLaunch = getHour();

    if (isPlayBlacklisted[sender]) {
      require(
        !isGameContract[recipient],
        'user blacklisted from playing games'
      );
    }

    if (_isBuy) {
      canSellWithoutElevation[recipient] = false;
      if (block.number <= _launchBlock + 2) {
        _isBot[recipient] = true;
      } else if (amount > biggestBuyerAmount[_hourAfterLaunch]) {
        if (currentBiggestBuyerHour != _hourAfterLaunch) {
          lastBiggestBuyerHour = currentBiggestBuyerHour;
          currentBiggestBuyerHour = _hourAfterLaunch;
        }
        biggestBuyer[_hourAfterLaunch] = recipient;
        biggestBuyerAmount[_hourAfterLaunch] = amount;
      }
    } else {
      require(!_isBot[recipient], 'Stop botting!');
      require(!_isBot[sender], 'Stop botting!');
      require(!_isBot[_msgSender()], 'Stop botting!');

      if (
        !_isSell &&
        !_isContract &&
        amount > minTransferForSideEffectsToRecipient
      ) {
        canSellWithoutElevation[recipient] = false;
        if (lastGameWin[recipient] < lastGameWin[sender]) {
          lastGameWin[recipient] = lastGameWin[sender];
        }
      }
    }

    _checkAndPayBiggestBuyer(lastBiggestBuyerHour);

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
      PERCENT_DENOMENATOR;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      launchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      launchTime != 0 &&
      _isSell &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      tax = _calcTaxAndProcess(sender, amount);
    }

    super._transfer(sender, recipient, amount - tax);

    if (_isSell && lpNukeEnabled && sender != address(this)) {
      lpNukeBuildup +=
        ((amount - tax) * nukePercentPerSell) /
        PERCENT_DENOMENATOR;
    }
  }

  function _calcTaxAndProcess(address sender, uint256 amount)
    internal
    returns (uint256)
  {
    bool _taxIsElevated = !canSellWithoutElevation[sender];
    uint256 tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
    if (tax > 0) {
      if (
        block.timestamp < lastGameWin[sender] + gameWinSellPenaltyTimeSeconds
      ) {
        tax = (tax * gameWinSellPenaltyMultiplier) / 10;
      } else if (_taxIsElevated) {
        tax = (tax * sellTaxUnwageredMultiplier) / 10;
      }
      super._transfer(sender, address(this), tax);
    }
    return tax;
  }

  function _swap(uint256 _amountToSwap) internal swapLock {
    uint256 balBefore = address(this).balance;
    uint256 burnTokens = (_amountToSwap * taxBurn) / _totalTax;
    uint256 liquidityTokens = (_amountToSwap * taxLp) / _totalTax / 2;
    uint256 tokensToSwap = _amountToSwap - burnTokens - liquidityTokens;

    if (burnTokens > 0) {
      _burn(address(this), burnTokens);
    }

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokensToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokensToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - balBefore;
    if (balToProcess > 0) {
      _processFees(balToProcess, liquidityTokens);
    }
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) internal {
    uint256 lpETH = (amountETH * taxLp) / _totalTax;
    if (amountLpTokens > 0) {
      _addLp(amountLpTokens, lpETH);
    }
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) internal {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      _lpReceiver == address(0) ? owner() : _lpReceiver,
      block.timestamp
    );
  }

  function _lpTokenNuke(uint256 _amount) internal {
    // cannot nuke more than 20% of token supply in pool
    if (_amount > 0 && _amount <= (balanceOf(uniswapV2Pair) * 20) / 100) {
      if (_nukeRecipient == DEAD) {
        _burn(uniswapV2Pair, _amount);
      } else {
        super._transfer(uniswapV2Pair, _nukeRecipient, _amount);
      }
      IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
      pair.sync();
    }
  }

  function _checkAndPayBiggestBuyer(uint256 _hourToPay) internal {
    if (
      _hourToPay > 0 &&
      biggestBuyerAmount[_hourToPay] > 0 &&
      biggestBuyerPaid[_hourToPay] == 0
    ) {
      uint256 _before = address(this).balance;
      if (_before > 0) {
        uint256 _buyerAmount = (_before * biggestBuyRewardPercentage) /
          PERCENT_DENOMENATOR;
        uint256 _maxRewardAmount = (biggestBuyerAmount[_hourToPay] *
          maxBuyerRewardBuyPercentage) / PERCENT_DENOMENATOR;
        _buyerAmount = _buyerAmount > _maxRewardAmount
          ? _maxRewardAmount
          : _buyerAmount;
        biggestBuyerPaid[_hourToPay] = _buyerAmount;
        payable(biggestBuyer[_hourToPay]).call{ value: _buyerAmount }('');
        require(
          address(this).balance >= _before - _buyerAmount,
          'too much ser'
        );
      }
    }
  }

  function gameMint(address _wallet, uint256 _amount)
    external
    override
    onlyGame
  {
    lastGameWin[_wallet] = block.timestamp;
    _mint(_wallet, _amount);
    emit GameMint(_wallet, _amount);
  }

  function gameBurn(address _wallet, uint256 _amount)
    external
    override
    onlyGame
  {
    _burn(_wallet, _amount);
    emit GameBurn(_wallet, _amount);
  }

  function addPlayThrough(
    address _wallet,
    uint256 _amountWagered,
    uint8 _percentContribution
  ) external override onlyGame {
    uint256 _amountAddedToPlaythrough = (_amountWagered *
      _percentContribution) / 100;
    _addPlayThrough(_wallet, _amountAddedToPlaythrough);
    emit AddPlayThrough(_wallet, _amountAddedToPlaythrough);
  }

  function setCanSellWithoutElevation(address _wallet, bool _canSellWithoutElev)
    external
    override
    onlyGame
  {
    canSellWithoutElevation[_wallet] = _canSellWithoutElev;
    emit CanSellWithoutElevation(_wallet, _canSellWithoutElev);
  }

  function _addPlayThrough(address _wallet, uint256 _amount) internal {
    totalPlayThrough += _amount;
    userPlayThrough[_wallet] += _amount;
    userMonthlyPlayThrough[_wallet][getMonth()] += _amount;
  }

  function getPlayThroughThisMonth(address _wallet)
    external
    view
    returns (uint256)
  {
    return userMonthlyPlayThrough[_wallet][getMonth()];
  }

  function claimRakeBack(uint256 _month) external {
    uint256 _playThrough = userMonthlyPlayThrough[msg.sender][_month];
    uint256 _amountToClaim = calculateRakebackAmountToClaim(msg.sender, _month);
    userPlayThroughClaimed[msg.sender][_month] += _amountToClaim;
    require(
      _playThrough >= minRakeBackPlayThrough,
      'must have played minimum amount for rake back'
    );
    require(_amountToClaim > 0, 'must have rewards to claim for the month');
    _mint(msg.sender, _amountToClaim);
  }

  function calculateRakebackAmountToClaim(address _user, uint256 _month)
    public
    view
    returns (uint256)
  {
    _month = _month == 0 ? getMonth() : _month;
    uint256 _playThrough = userMonthlyPlayThrough[_user][_month];
    uint256 _claimedAlready = userPlayThroughClaimed[_user][_month];
    uint256 _amountClaimTotal = (_playThrough * rakeBackPercentage) /
      PERCENT_DENOMENATOR;
    return _amountClaimTotal - _claimedAlready;
  }

  function nukeLpTokenFromBuildup() external {
    require(
      msg.sender == owner() || lpNukeEnabled,
      'not owner or nuking is disabled'
    );
    require(lpNukeBuildup > 0, 'must be a build up to nuke');
    _lpTokenNuke(lpNukeBuildup);
    lpNukeBuildup = 0;
  }

  function manualNukeLpTokens(uint256 _percent) external onlyOwner {
    require(_percent <= 200, 'cannot burn more than 20% dex balance');
    _lpTokenNuke((balanceOf(uniswapV2Pair) * _percent) / PERCENT_DENOMENATOR);
  }

  // starts at 1 and increments forever every hour after launch starting top of hour
  function getHour() public view returns (uint256) {
    uint256 secondsSinceLaunchTopHour = block.timestamp - launchTimeTopHour;
    return 1 + (secondsSinceLaunchTopHour / ONE_HOUR);
  }

  // starts at 1 and increments forever every month after launch starting top of month
  function getMonth() public view returns (uint256) {
    uint256 secondsSinceLaunchTopMonth = block.timestamp - launchTimeTopMonth;
    return 1 + (secondsSinceLaunchTopMonth / 30 days);
  }

  function _getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / ONE_DAY);
  }

  function _getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / ONE_DAY);
  }

  function _timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256) {
    return _daysFromDate(year, month, day) * ONE_DAY;
  }

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   https://aa.usno.navy.mil/faq/JD_formula.html
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    return uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function isBotBlacklisted(address account) external view returns (bool) {
    return _isBot[account];
  }

  function blacklistBot(address account) external onlyOwner {
    require(account != address(uniswapV2Router), 'cannot blacklist router');
    require(account != uniswapV2Pair, 'cannot blacklist pair');
    require(!_isBot[account], 'user is already blacklisted');
    _isBot[account] = true;
  }

  function forgiveBot(address account) external onlyOwner {
    require(_isBot[account], 'user is not blacklisted');
    _isBot[account] = false;
  }

  function _setTotalTax() internal {
    _totalTax = taxBurn + taxBuyer + taxLp;
    require(
      _totalTax <= (PERCENT_DENOMENATOR * 25) / 100,
      'tax cannot be above 25%'
    );
    require(
      (_totalTax * sellTaxUnwageredMultiplier) / 10 <=
        (PERCENT_DENOMENATOR * 49) / 100,
      'total cannot be more than 49%'
    );
  }

  function setTaxBurn(uint256 _tax) external onlyOwner {
    taxBurn = _tax;
    _setTotalTax();
  }

  function setTaxBuyer(uint256 _tax) external onlyOwner {
    taxBuyer = _tax;
    _setTotalTax();
  }

  function setTaxLp(uint256 _tax) external onlyOwner {
    taxLp = _tax;
    _setTotalTax();
  }

  // _mult = 10 means x1, 20 means x2
  function setSellTaxUnwageredMultiplier(uint256 _mult) external onlyOwner {
    require(
      (_totalTax * _mult) / 10 <= (PERCENT_DENOMENATOR * 49) / 100,
      'cannot be more than 49%'
    );
    sellTaxUnwageredMultiplier = _mult;
  }

  // _mult = 10 means x1, 20 means x2
  function setGameWinSellPenaltyMultiplier(uint256 _mult) external onlyOwner {
    require(
      (_totalTax * _mult) / 10 <= (PERCENT_DENOMENATOR * 49) / 100,
      'total cannot be more than 49%'
    );
    gameWinSellPenaltyMultiplier = _mult;
  }

  function setLpReceiver(address _wallet) external onlyOwner {
    _lpReceiver = _wallet;
  }

  function setIsGameContract(address _game, bool _isGame) external onlyOwner {
    isGameContract[_game] = _isGame;
  }

  function setIsPlayBlacklisted(address _wallet, bool _isBlacklisted)
    external
    onlyOwner
  {
    isPlayBlacklisted[_wallet] = _isBlacklisted;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setNukePercentPerSell(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    nukePercentPerSell = _percent;
  }

  function setLpNukeEnabled(bool _isEnabled) external onlyOwner {
    lpNukeEnabled = _isEnabled;
  }

  function setBiggestBuyRewardPercentage(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    biggestBuyRewardPercentage = _percent;
  }

  function setMaxBuyerRewardBuyPercentage(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    maxBuyerRewardBuyPercentage = _percent;
  }

  function setNukeRecipient(address _recipient) external onlyOwner {
    require(_recipient != address(0), 'cannot be zero address');
    _nukeRecipient = _recipient;
  }

  function setGameWinSellPenaltyTimeSeconds(uint256 _seconds)
    external
    onlyOwner
  {
    gameWinSellPenaltyTimeSeconds = _seconds;
  }

  function setMinTransferForSideEffectsToRecipient(uint256 _amount)
    external
    onlyOwner
  {
    minTransferForSideEffectsToRecipient = _amount;
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/ISMOLNftRewards.sol';
import './interfaces/ISmoltingInu.sol';

contract SMOLNftRewards is ISMOLNftRewards, Ownable {
  struct Reward {
    uint256 totalExcluded; // excluded reward
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }

  IERC721 shareholderNFT;
  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event ClaimReward(address user);
  event DistributeReward(address indexed user);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyToken() {
    require(msg.sender == address(shareholderNFT), 'must be token contract');
    _;
  }

  constructor(address _shareholderNFT) {
    shareholderNFT = IERC721(_shareholderNFT);
  }

  function setShare(address shareholder, uint256 newBalance)
    external
    onlyToken
  {
    // _addShares and _removeShares takes the amount to add or remove respectively,
    // so we should handle the diff from the new balance when passing in the amounts
    // to these functions
    if (shares[shareholder].amount > newBalance) {
      _removeShares(shareholder, shares[shareholder].amount - newBalance);
    } else if (shares[shareholder].amount < newBalance) {
      _addShares(shareholder, newBalance - shares[shareholder].amount);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder);
    }

    uint256 sharesBefore = shares[shareholder].amount;

    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    require(
      shares[shareholder].amount > 0 &&
        (amount == 0 || amount <= shares[shareholder].amount),
      'you can only unstake if you have some staked'
    );
    _distributeReward(shareholder);

    uint256 removeAmount = amount == 0 ? shares[shareholder].amount : amount;

    totalSharesDeposited -= removeAmount;
    shares[shareholder].amount -= removeAmount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards(uint256 _amount) external override onlyOwner {
    require(
      totalSharesDeposited > 0,
      'must be shares deposited to be rewarded rewards'
    );

    totalRewards += _amount;
    rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
    smol.gameMint(address(this), _amount);
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      totalDistributed += amount;
      smol.transfer(shareholder, amount);
      emit DistributeReward(shareholder);
    }
  }

  function claimReward() external override {
    _distributeReward(msg.sender);
    emit ClaimReward(msg.sender);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getShareholderNFT() external view returns (address) {
    return address(shareholderNFT);
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setShareholderNFT(address _nft) external onlyOwner {
    shareholderNFT = IERC721(_nft);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISMOLNftRewards {
  function claimReward() external;

  function depositRewards(uint256 _amount) external;

  function getShares(address wallet) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/ISmoltingInu.sol';
import './SMOLNftRewards.sol';

/**
 * SMOL yield bearing NFTs
 */
contract SMOLNft is Ownable, ERC721Burnable, ERC721Enumerable, ERC721Pausable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint16 public constant PERCENT_DENOMENATOR = 1000;
  uint16 private constant FIVE_MINUTES = 60 * 5;

  Counters.Counter private _tokenIds;

  SMOLNftRewards private _rewards;
  mapping(address => bool) private _isRewardsExcluded;

  // user => timestamp of last mint
  // used for throttling wallets from minting too often
  mapping(address => uint256) public userLastMinted;

  // Base token uri
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while

  address public smol = 0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e;
  uint256 public nativeCost = 9 ether / 100; // 0.09 ETH
  uint256 public smolCost = 100 * 10**18;
  uint8 public maxPerMint = 10;

  // Payment address
  address public paymentAddress = 0x98c574473313EAC3FC6af9740245949380ec166E;

  // Royalties address
  address public royaltyAddress = 0x98c574473313EAC3FC6af9740245949380ec166E;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // Token info
  string public constant TOKEN_NAME = 'yield bearing smolting';
  string public constant TOKEN_SYMBOL = 'ybSMOL'; // yield bearing SMOL
  uint256 public constant TOTAL_TOKENS = 4269;

  // Public sale params
  uint256 public publicSaleStartTime;
  bool public publicSaleActive;
  bool public isRevealing;

  mapping(address => bool) public canMintFreeNft;
  mapping(address => uint256) public mintedFreeNftTimestamp;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferredAt;

  event PublicSaleStart(uint256 indexed _saleStartTime);
  event PublicSalePaused(uint256 indexed _timeElapsed);
  event PublicSaleActive(bool indexed _publicSaleActive);
  event RoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);

  // Public sale active modifier
  modifier whenPublicSaleActive() {
    require(publicSaleActive, 'Public sale is not active');
    _;
  }

  // Public sale not active modifier
  modifier whenPublicSaleNotActive() {
    require(
      !publicSaleActive && publicSaleStartTime == 0,
      'Public sale is already active'
    );
    _;
  }

  // Owner or public sale active modifier
  modifier whenOwnerOrPublicSaleActive() {
    require(
      owner() == _msgSender() || publicSaleActive,
      'Public sale is not active'
    );
    _;
  }

  // -- Constructor --//
  constructor(string memory _baseTokenURI) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
    baseTokenURI = _baseTokenURI;
    _rewards = new SMOLNftRewards(address(this));
    _rewards.transferOwnership(_msgSender());

    _isRewardsExcluded[address(this)] = true;
    _isRewardsExcluded[address(_rewards)] = true;
  }

  // -- External Functions -- //
  // Start public sale
  function startPublicSale() external onlyOwner whenPublicSaleNotActive {
    publicSaleStartTime = block.timestamp;
    publicSaleActive = true;
    emit PublicSaleStart(publicSaleStartTime);
  }

  // Set this value to the block.timestamp you'd like to reset to
  // Created as a way to fast foward in time for tier timing unit tests
  // Can also be used if needing to pause and restart public sale from original start time (returned in startPublicSale() above)
  function setPublicSaleStartTime(uint256 _publicSaleStartTime)
    external
    onlyOwner
  {
    publicSaleStartTime = _publicSaleStartTime;
    emit PublicSaleStart(publicSaleStartTime);
  }

  // Toggle public sale
  function togglePublicSaleActive() external onlyOwner {
    publicSaleActive = !publicSaleActive;
    emit PublicSaleActive(publicSaleActive);
  }

  // Pause public sale
  function pausePublicSale() external onlyOwner whenPublicSaleActive {
    publicSaleActive = false;
    emit PublicSalePaused(getElapsedSaleTime());
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (
      royaltyAddress,
      (_salePrice * royaltyBasisPoints) / PERCENT_DENOMENATOR
    );
  }

  function getElapsedSaleTime() public view returns (uint256) {
    return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
  }

  function getRewards() external view returns (address) {
    return address(_rewards);
  }

  // Get mints left
  function getMintsLeft() public view returns (uint256) {
    uint256 currentSupply = super.totalSupply();
    return TOTAL_TOKENS - currentSupply;
  }

  // Mint token - requires tier and amount
  function mint(uint256 _amount) public payable whenOwnerOrPublicSaleActive {
    bool _isOwner = owner() == _msgSender();
    require(_isOwner || getElapsedSaleTime() > 0, 'sale not active');
    require(
      _isOwner || block.timestamp > userLastMinted[_msgSender()] + FIVE_MINUTES,
      'can only mint once per 5 minutes'
    );
    require(
      _amount > 0 && (_isOwner || _amount <= maxPerMint),
      'must mint at least one and cannot exceed max amount'
    );
    // Check there enough NFTs left to mint
    require(_amount <= getMintsLeft(), 'minting would exceed max supply');

    userLastMinted[_msgSender()] = block.timestamp;

    // pay for NFTs & handle free NFT mint logic here as well
    if (
      canMintFreeNft[_msgSender()] && mintedFreeNftTimestamp[_msgSender()] == 0
    ) {
      mintedFreeNftTimestamp[_msgSender()] = block.timestamp;
      _payToMint(_amount - 1);
    } else {
      _payToMint(_amount);
    }

    for (uint256 i = 0; i < _amount; i++) {
      _tokenIds.increment();

      // Safe mint
      _safeMint(_msgSender(), _tokenIds.current());

      // Store minted at timestamp by token id
      tokenMintedAt[_tokenIds.current()] = block.timestamp;
    }
  }

  function _payToMint(uint256 _amount) internal whenOwnerOrPublicSaleActive {
    require(_amount > 0, 'must mint at least 1');
    bool isOwner = owner() == _msgSender();
    if (isOwner) {
      if (msg.value > 0) {
        Address.sendValue(payable(_msgSender()), msg.value);
      }
      return;
    }

    ISmoltingInu smolToken = ISmoltingInu(smol);
    uint256 totalNativeCost = nativeCost * _amount;
    uint256 totalSmolCost = smolCost * _amount;

    if (totalNativeCost > 0) {
      require(
        msg.value >= totalNativeCost,
        'not enough native token provided to mint'
      );
      uint256 balanceBefore = address(this).balance;
      Address.sendValue(payable(paymentAddress), totalNativeCost);
      // refund user for any extra native sent
      if (msg.value > totalNativeCost) {
        Address.sendValue(payable(_msgSender()), msg.value - totalNativeCost);
      }
      require(
        address(this).balance >= balanceBefore - msg.value,
        'too much native sent'
      );
    } else if (msg.value > 0) {
      Address.sendValue(payable(_msgSender()), msg.value);
    }

    if (totalSmolCost > 0) {
      require(
        smolToken.balanceOf(_msgSender()) >= totalSmolCost,
        'not enough SMOL balance to mint'
      );
      smolToken.gameBurn(_msgSender(), totalSmolCost);
    }
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
  }

  // Set royalty wallet address
  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
  }

  function setSmolToken(address _smol) external onlyOwner {
    smol = _smol;
  }

  function setNativeCost(uint256 _wei) external onlyOwner {
    nativeCost = _wei;
  }

  function setSmolCost(uint256 _numTokens) external onlyOwner {
    smolCost = _numTokens;
  }

  // Set royalty basis points
  function setRoyaltyBasisPoints(uint256 _basisPoints) external onlyOwner {
    royaltyBasisPoints = _basisPoints;
    emit RoyaltyBasisPoints(_basisPoints);
  }

  // Set base URI
  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
  }

  function setRewards(address _contract) external onlyOwner {
    _rewards = SMOLNftRewards(_contract);
  }

  function setIsRewardsExcluded(address _wallet, bool _isExcluded)
    public
    onlyOwner
  {
    _isRewardsExcluded[_wallet] = _isExcluded;
    if (_isExcluded) {
      _rewards.setShare(_wallet, 0);
    } else {
      _rewards.setShare(_wallet, balanceOf(_wallet));
    }
  }

  function setMaxPerMint(uint8 _max) external onlyOwner {
    require(maxPerMint > 0, 'have to be able to mint at least 1 NFT');
    maxPerMint = _max;
  }

  function setCanMintFreeNft(address _wallet, bool _canMintFree)
    external
    onlyOwner
  {
    canMintFreeNft[_wallet] = _canMintFree;
  }

  function setCanMintFreeNftBulk(address[] memory _wallets, bool _canMintFree)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _wallets.length; i++) {
      canMintFreeNft[_wallets[i]] = _canMintFree;
    }
  }

  function isRewardsExcluded(address _wallet) external view returns (bool) {
    return _isRewardsExcluded[_wallet];
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'Nonexistent token');

    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  function isMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  // Pauses all token transfers - See {ERC721Pausable}
  function pause() public virtual onlyOwner {
    _pause();
  }

  // Unpauses all token transfers - See {ERC721Pausable}
  function unpause() public virtual onlyOwner {
    _unpause();
  }

  function reveal() external onlyOwner {
    require(!isRevealing, 'already revealing');
    isRevealing = true;
  }

  //-- Internal Functions --//

  function _setRewardsShares(address _from, address _to) internal {
    if (!_isRewardsExcluded[_from] && _from != address(0)) {
      _rewards.setShare(_from, balanceOf(_from));
    }
    if (!_isRewardsExcluded[_to] && _to != address(0)) {
      _rewards.setShare(_to, balanceOf(_to));
    }
  }

  // Get base URI
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  // before all token transfer
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    // Store token last transfer timestamp by id
    tokenLastTransferredAt[_tokenId] = block.timestamp;

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  // after all token transfer
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721) {
    _setRewardsShares(_from, _to);

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title OverUnder
 * @dev Chainlink VRF powered number picker chance game
 */
contract OverUnder is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public minBalancePerc = (PERCENT_DENOMENATOR * 5) / 100; // 5% user's balance
  uint256 public minWagerAbsolute;
  uint256 public maxWagerAbsolute;

  uint256 public payoutMultipleFactor = 985;

  uint8 public numberFloor = 1;
  uint8 public numberCeil = 100;

  uint256 public selectionsMade;
  uint256 public selectionsWon;
  uint256 public selectionsLost;
  uint256 public selectionsAmountWon;
  uint256 public selectionsAmountLost;
  mapping(address => uint256) public selectionsUserWon;
  mapping(address => uint256) public selectionsUserLost;
  mapping(address => uint256) public selectionsUserAmountWon;
  mapping(address => uint256) public selectionsUserAmountLost;
  mapping(uint8 => uint256) public numbersDrawn;

  mapping(uint256 => address) private _selectInitUser;
  mapping(uint256 => uint256) private _selectInitAmount;
  mapping(uint256 => uint8) private _selectInitSideSelected;
  mapping(uint256 => bool) private _selectInitIsOver;
  mapping(uint256 => uint256) private _selectInitPayout;
  mapping(uint256 => uint256) private _selectInitNonce;
  mapping(uint256 => bool) private _selectInitSettled;
  mapping(address => uint256) public userWagerNonce;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event SelectNumber(
    address indexed user,
    uint256 indexed nonce,
    uint8 indexed numSelected,
    bool isOver,
    uint256 payoutMultiple,
    uint256 amountWagered,
    uint256 requestId
  );
  event GetResult(
    address indexed user,
    uint256 indexed nonce,
    uint8 indexed numSelected,
    bool isWinner,
    bool isOver,
    uint256 payoutMultiple,
    uint256 amountWagered,
    uint8 numDrawn,
    uint256 amountToWin,
    uint256 requestId
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function selectNumber(
    uint8 _numSelected,
    bool _isOver,
    uint256 _percent
  ) external payable {
    require(
      _numSelected > numberFloor && _numSelected < numberCeil,
      'number selected must be between floor and ceil'
    );
    require(
      _percent >= minBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager more than minimum balance'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;
    require(
      _finalWagerAmount >= minWagerAbsolute,
      'does not meet minimum amount requirements'
    );
    require(
      maxWagerAbsolute == 0 || _finalWagerAmount <= maxWagerAbsolute,
      'exceeded maximum amount requirements'
    );

    _enforceMinMaxWagerLogic(msg.sender, _finalWagerAmount);
    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);
    smol.addPlayThrough(
      msg.sender,
      _finalWagerAmount,
      percentageWagerTowardsRewards
    );
    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _selectInitUser[requestId] = msg.sender;
    _selectInitAmount[requestId] = _finalWagerAmount;
    _selectInitSideSelected[requestId] = _numSelected;
    _selectInitIsOver[requestId] = _isOver;
    _selectInitPayout[requestId] = getPayoutMultiple(_numSelected, _isOver);
    _selectInitNonce[requestId] = userWagerNonce[msg.sender];
    userWagerNonce[msg.sender]++;
    selectionsMade++;
    _payServiceFee();
    emit SelectNumber(
      msg.sender,
      _selectInitNonce[requestId],
      _numSelected,
      _isOver,
      _selectInitPayout[requestId],
      _finalWagerAmount,
      requestId
    );
  }

  function getPayoutMultiple(uint8 _numSelected, bool _isOver)
    public
    view
    returns (uint256)
  {
    require(
      _numSelected > numberFloor && _numSelected < numberCeil,
      'number selected must be between floor and ceil'
    );
    uint256 odds;
    if (_isOver) {
      odds = (numberCeil * payoutMultipleFactor) / (numberCeil - _numSelected);
    } else {
      odds = (numberCeil * payoutMultipleFactor) / (_numSelected - numberFloor);
    }
    return odds - 1000;
  }

  function manualSettleSelection(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settle(requestId, randomWords[0]);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settle(requestId, randomWords[0]);
  }

  function _settle(uint256 requestId, uint256 randomNumber) internal {
    address _user = _selectInitUser[requestId];
    require(_user != address(0), 'number selection record does not exist');
    require(!_selectInitSettled[requestId], 'already settled');
    _selectInitSettled[requestId] = true;

    uint256 _amountToWin = (_selectInitAmount[requestId] *
      _selectInitPayout[requestId]) / PERCENT_DENOMENATOR;
    uint8 _numberDrawn = uint8(randomNumber % (numberCeil - numberFloor + 1)) +
      numberFloor;
    bool _didUserWin = _selectInitIsOver[requestId]
      ? _numberDrawn > _selectInitSideSelected[requestId]
      : _numberDrawn < _selectInitSideSelected[requestId];

    if (_didUserWin) {
      smol.transfer(_user, _selectInitAmount[requestId]);
      smol.gameMint(_user, _amountToWin);
      selectionsWon++;
      selectionsAmountWon += _amountToWin;
      selectionsUserWon[_user]++;
      selectionsUserAmountWon[_user] += _amountToWin;
    } else if (_numberDrawn == _selectInitSideSelected[requestId]) {
      // draw
      smol.transfer(_user, _selectInitAmount[requestId]);
    } else {
      smol.gameBurn(address(this), _selectInitAmount[requestId]);
      selectionsLost++;
      selectionsAmountLost += _selectInitAmount[requestId];
      selectionsUserLost[_user]++;
      selectionsUserAmountLost[_user] += _selectInitAmount[requestId];
    }
    numbersDrawn[_numberDrawn]++;

    emit GetResult(
      _user,
      _selectInitNonce[requestId],
      _selectInitSideSelected[requestId],
      _didUserWin,
      _selectInitIsOver[requestId],
      _selectInitPayout[requestId],
      _selectInitAmount[requestId],
      _numberDrawn,
      _amountToWin,
      requestId
    );
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setPayoutMultipleFactor(uint256 _factor) external onlyOwner {
    payoutMultipleFactor = _factor;
  }

  function setFloorAndCeil(uint8 _floor, uint8 _ceil) external onlyOwner {
    require(
      _ceil > _floor && _ceil - _floor >= 2,
      'floor and ceil must be at least 2 units apart'
    );
    numberFloor = _floor;
    numberCeil = _ceil;
  }

  function setMinBalancePerc(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be less than 100%');
    minBalancePerc = _percent;
  }

  function setMinWagerAbsolute(uint256 _amount) external onlyOwner {
    minWagerAbsolute = _amount;
  }

  function setMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    maxWagerAbsolute = _amount;
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title Lottery
 * @dev Chainlink VRF powered lottery for ERC-20 tokens
 */
contract Lottery is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public currentMinWinAmount = 1000 * 10**18;
  uint256 public percentageFeeWin = (PERCENT_DENOMENATOR * 95) / 100;
  uint256 public lottoEntryFee = 10**18; // 1 token (assuming 18 decimals)
  uint256 public lottoTimespan = 60 * 60 * 24; // 24 hours
  uint16 public numberWinners = 1;

  uint256[] public lotteries;
  // lottoTimestamp => isSettled
  mapping(uint256 => bool) public isLotterySettled;
  // lottoTimestamp => participants
  mapping(uint256 => address[]) public lottoParticipants;
  // user => currentLottery => numEntries
  mapping(address => mapping(uint256 => uint256)) public lotteryEntriesPerUser;
  // lottoTimestamp => winner
  mapping(uint256 => address[]) public lottoWinners;
  // lottoTimestamp => amountWon
  mapping(uint256 => uint256) public lottoWinnerAmounts;

  mapping(uint256 => uint256) private _lotterySelectInit;
  mapping(uint256 => uint256) private _lotterySelectReqIdInit;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event DrawWinner(uint256 indexed lottoTimestamp);
  event SelectedWinners(
    uint256 indexed lottoTimestamp,
    address[] winner,
    uint256 amountWon
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function launch() external onlyOwner {
    lotteries.push(block.timestamp);
  }

  function enterLotto(uint256 _entries) external payable {
    _enterLotto(msg.sender, msg.sender, _entries);
  }

  function enterLottoForUser(address _user, uint256 _entries) external payable {
    _enterLotto(msg.sender, _user, _entries);
  }

  function _enterLotto(
    address _payingUser,
    address _entryUser,
    uint256 _entries
  ) internal {
    _payServiceFee();
    uint256 _currentLottery = getCurrentLottery();
    if (block.timestamp > _currentLottery + lottoTimespan) {
      selectLottoWinner();
      _currentLottery = getCurrentLottery();
    }

    smol.transferFrom(_payingUser, address(this), _entries * lottoEntryFee);
    smol.addPlayThrough(
      _entryUser,
      _entries * lottoEntryFee,
      percentageWagerTowardsRewards
    );
    lotteryEntriesPerUser[_entryUser][_currentLottery] += _entries;
    for (uint256 i = 0; i < _entries; i++) {
      lottoParticipants[_currentLottery].push(_entryUser);
    }
  }

  function selectLottoWinner() public {
    uint256 _currentLottery = getCurrentLottery();
    require(
      block.timestamp > _currentLottery + lottoTimespan,
      'lottery time period must be past'
    );
    require(currentMinWinAmount > 0, 'no jackpot to win');
    require(_lotterySelectInit[_currentLottery] == 0, 'already initiated');
    lotteries.push(block.timestamp);

    if (lottoParticipants[_currentLottery].length == 0) {
      _lotterySelectInit[_currentLottery] = 1;
      isLotterySettled[_currentLottery] = true;
      return;
    }

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      numberWinners
    );
    _lotterySelectInit[_currentLottery] = requestId;
    _lotterySelectReqIdInit[requestId] = _currentLottery;
    emit DrawWinner(_currentLottery);
  }

  function manualSettleLottery(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOwner
  {
    _settleLottery(requestId, randomWords);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleLottery(requestId, randomWords);
  }

  function _settleLottery(uint256 requestId, uint256[] memory randomWords)
    internal
  {
    uint256 _lotteryToSettle = _lotterySelectReqIdInit[requestId];
    require(_lotteryToSettle != 0, 'lottery selection does not exist');

    uint256 _amountWon = getLotteryRewardAmount(_lotteryToSettle);
    address[] memory _winners = new address[](randomWords.length);
    for (uint256 i = 0; i < randomWords.length; i++) {
      uint256 _winnerIdx = randomWords[i] %
        lottoParticipants[_lotteryToSettle].length;
      _winners[i] = lottoParticipants[_lotteryToSettle][_winnerIdx];
      smol.gameMint(_winners[i], _amountWon / randomWords.length);
    }

    smol.gameBurn(address(this), smol.balanceOf(address(this)));
    lottoWinners[_lotteryToSettle] = _winners;
    lottoWinnerAmounts[_lotteryToSettle] = _amountWon;
    isLotterySettled[_lotteryToSettle] = true;
    emit SelectedWinners(_lotteryToSettle, _winners, _amountWon);
  }

  function getLottoToken() external view returns (address) {
    return address(smol);
  }

  function getCurrentLottery() public view returns (uint256) {
    return lotteries[lotteries.length - 1];
  }

  function getNumberLotteries() external view returns (uint256) {
    return lotteries.length;
  }

  function getCurrentNumberEntriesForUser(address _user)
    external
    view
    returns (uint256)
  {
    return lotteryEntriesPerUser[_user][getCurrentLottery()];
  }

  function getCurrentLotteryRewardAmount() external view returns (uint256) {
    return getLotteryRewardAmount(getCurrentLottery());
  }

  function getLotteryRewardAmount(uint256 _lottery)
    public
    view
    returns (uint256)
  {
    uint256 _participants = getLotteryEntries(_lottery);
    uint256 _entryFeesTotal = _participants * lottoEntryFee;
    uint256 _entryFeeWinAmount = (_entryFeesTotal * percentageFeeWin) /
      PERCENT_DENOMENATOR;

    if (_entryFeeWinAmount < currentMinWinAmount) {
      return currentMinWinAmount;
    }
    return _entryFeeWinAmount;
  }

  function getCurrentLotteryEntries() external view returns (uint256) {
    return getLotteryEntries(getCurrentLottery());
  }

  function getLotteryEntries(uint256 _lottery) public view returns (uint256) {
    return lottoParticipants[_lottery].length;
  }

  function setCurrentMinWinAmount(uint256 _amount) external onlyOwner {
    currentMinWinAmount = _amount;
  }

  function setPercentageFeeWin(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    require(_percent > 0, 'has to be more than 0%');
    percentageFeeWin = _percent;
  }

  function setLottoToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setLottoTimespan(uint256 _seconds) external onlyOwner {
    lottoTimespan = _seconds;
  }

  function setLottoEntryFee(uint256 _fee) external onlyOwner {
    lottoEntryFee = _fee;
  }

  function setNumberWinners(uint16 _number) external onlyOwner {
    require(_number > 0 && _number <= 20, 'no more than 20 winners');
    numberWinners = _number;
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title Dice
 * @dev Chainlink VRF powered dice roller
 */
contract Dice is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public diceMinBalancePerc = (PERCENT_DENOMENATOR * 5) / 100; // 5% user's balance
  uint256 public diceMinWagerAbsolute;
  uint256 public diceMaxWagerAbsolute;
  uint256 public payoutMultiple = PERCENT_DENOMENATOR * 5;
  uint256 public diceWon;
  uint256 public diceLost;
  uint256 public diceAmountWon;
  uint256 public diceAmountLost;
  mapping(address => uint256) public diceUserWon;
  mapping(address => uint256) public diceUserLost;
  mapping(address => uint256) public diceUserAmountWon;
  mapping(address => uint256) public diceUserAmountLost;
  mapping(address => bool) public lastRollDiceWon;
  mapping(uint8 => uint256) public sidesRolled;

  mapping(uint256 => address) private _rollDiceInitUser;
  mapping(uint256 => uint256) private _rollDiceInitAmount;
  mapping(uint256 => uint8) private _rollDiceInitSideSelected;
  mapping(uint256 => uint256) private _rollDiceInitNonce;
  mapping(uint256 => bool) private _rollDiceInitSettled;
  mapping(address => uint256) public userWagerNonce;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event RollDice(
    address indexed wagerer,
    uint256 indexed nonce,
    uint8 indexed sideSelected,
    uint256 requestId,
    uint256 amountWagered
  );
  event GetDiceResult(
    address indexed wagerer,
    uint256 indexed nonce,
    uint8 indexed sideSelected,
    uint256 requestId,
    uint256 amountWagered,
    uint8 sideRolled,
    bool isWinner,
    uint256 amountWon
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function rollDice(uint8 _sideSelected, uint256 _percent) external payable {
    require(_sideSelected > 0 && _sideSelected <= 6, 'invalid side selected');
    require(
      _percent >= diceMinBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager between half and your entire bag'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;
    require(
      _finalWagerAmount >= diceMinWagerAbsolute,
      'does not meet minimum amount requirements'
    );
    require(
      diceMaxWagerAbsolute == 0 || _finalWagerAmount <= diceMaxWagerAbsolute,
      'exceeded maximum amount requirements'
    );

    _enforceMinMaxWagerLogic(msg.sender, _finalWagerAmount);
    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);
    smol.addPlayThrough(
      msg.sender,
      _finalWagerAmount,
      percentageWagerTowardsRewards
    );
    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _rollDiceInitUser[requestId] = msg.sender;
    _rollDiceInitAmount[requestId] = _finalWagerAmount;
    _rollDiceInitSideSelected[requestId] = _sideSelected;
    _rollDiceInitNonce[requestId] = userWagerNonce[msg.sender];
    userWagerNonce[msg.sender]++;

    _payServiceFee();
    emit RollDice(
      msg.sender,
      _rollDiceInitNonce[requestId],
      _sideSelected,
      requestId,
      _finalWagerAmount
    );
  }

  function manualSettleRollDice(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOwner
  {
    _settleRollDice(requestId, randomWords[0]);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleRollDice(requestId, randomWords[0]);
  }

  function _settleRollDice(uint256 requestId, uint256 randomNumber) internal {
    address _user = _rollDiceInitUser[requestId];
    require(_user != address(0), 'dice record does not exist');
    require(!_rollDiceInitSettled[requestId], 'already settled');
    _rollDiceInitSettled[requestId] = true;

    uint256 _amountWagered = _rollDiceInitAmount[requestId];
    uint256 _nonce = _rollDiceInitNonce[requestId];
    uint256 _amountToWin = (_amountWagered * payoutMultiple) /
      PERCENT_DENOMENATOR;
    uint8 _sideSelected = _rollDiceInitSideSelected[requestId];
    // `X mod 6` returns 0-5, so need to subtract side selected by 1 to get real result
    bool _didUserWin = randomNumber % 6 == _sideSelected - 1;
    uint8 _sideRolled = uint8(randomNumber % 6) + 1;
    sidesRolled[_sideRolled]++;

    if (_didUserWin) {
      smol.transfer(_user, _amountWagered);
      smol.gameMint(_user, _amountToWin);
      diceWon++;
      diceAmountWon += _amountToWin;
      diceUserWon[_user]++;
      diceUserAmountWon[_user] += _amountToWin;
      lastRollDiceWon[_user] = true;
    } else {
      smol.gameBurn(address(this), _amountWagered);
      diceLost++;
      diceAmountLost += _amountWagered;
      diceUserLost[_user]++;
      diceUserAmountLost[_user] += _amountWagered;
      lastRollDiceWon[_user] = false;
    }

    emit GetDiceResult(
      _user,
      _nonce,
      _sideSelected,
      requestId,
      _amountWagered,
      _sideRolled,
      _didUserWin,
      _amountToWin
    );
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setPayoutMultiple(uint256 _multiple) external onlyOwner {
    require(_multiple > 0, 'must be more than 0');
    payoutMultiple = _multiple;
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setDiceMinBalancePerc(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be less than 100%');
    diceMinBalancePerc = _percent;
  }

  function setDiceMinWagerAbsolute(uint256 _amount) external onlyOwner {
    diceMinWagerAbsolute = _amount;
  }

  function setDiceMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    diceMaxWagerAbsolute = _amount;
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

contract CoinFlip is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;
  mapping(uint256 => address) private _flipWagerInitUser;
  mapping(uint256 => bool) private _flipWagerInitIsHeads;
  mapping(uint256 => uint256) private _flipWagerInitAmount;
  mapping(uint256 => uint256) private _flipWagerInitNonce;
  mapping(uint256 => bool) private _flipWagerInitSettled;
  mapping(address => uint256) public userWagerNonce;

  uint256 public coinFlipMinBalancePerc = (PERCENT_DENOMENATOR * 50) / 100; // 50% user's balance
  uint256 public coinFlipWinPercentage = (PERCENT_DENOMENATOR * 95) / 100; // 95% wager amount
  uint256 public coinFlipsWon;
  uint256 public coinFlipsLost;
  uint256 public coinFlipAmountWon;
  uint256 public coinFlipAmountLost;
  mapping(address => uint256) public coinFlipsUserWon;
  mapping(address => uint256) public coinFlipsUserLost;
  mapping(address => uint256) public coinFlipUserAmountWon;
  mapping(address => uint256) public coinFlipUserAmountLost;
  mapping(address => bool) public lastCoinFlipWon;

  event InitiatedCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 requestId,
    bool isHeads,
    uint256 amountWagered
  );
  event SettledCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 requestId,
    bool isHeads,
    uint256 amountWagered,
    bool isWinner,
    uint256 amountWon
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  // coinFlipMinBalancePerc <= _percent <= 1000
  function flipCoin(uint16 _percent, bool _isHeads) external payable {
    require(smol.balanceOf(msg.sender) > 0, 'must have a bag to wager');
    require(
      _percent >= coinFlipMinBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager between the minimum and your entire bag'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;

    _enforceMinMaxWagerLogic(msg.sender, _finalWagerAmount);
    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _flipWagerInitUser[requestId] = msg.sender;
    _flipWagerInitAmount[requestId] = _finalWagerAmount;
    _flipWagerInitNonce[requestId] = userWagerNonce[msg.sender];
    _flipWagerInitIsHeads[requestId] = _isHeads;
    userWagerNonce[msg.sender]++;

    smol.addPlayThrough(
      msg.sender,
      _finalWagerAmount,
      percentageWagerTowardsRewards
    );
    smol.setCanSellWithoutElevation(msg.sender, true);
    _payServiceFee();
    emit InitiatedCoinFlip(
      msg.sender,
      _flipWagerInitNonce[requestId],
      requestId,
      _isHeads,
      _finalWagerAmount
    );
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleCoinFlip(requestId, randomWords[0]);
  }

  function manualFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settleCoinFlip(requestId, randomWords[0]);
  }

  function _settleCoinFlip(uint256 requestId, uint256 randomNumber) internal {
    address _user = _flipWagerInitUser[requestId];
    require(_user != address(0), 'coin flip record does not exist');
    require(!_flipWagerInitSettled[requestId], 'already settled');
    _flipWagerInitSettled[requestId] = true;

    uint256 _amountWagered = _flipWagerInitAmount[requestId];
    uint256 _nonce = _flipWagerInitNonce[requestId];
    bool _isHeads = _flipWagerInitIsHeads[requestId];
    uint256 _amountToWin = (_amountWagered * coinFlipWinPercentage) /
      PERCENT_DENOMENATOR;
    uint8 _selectionMod = _isHeads ? 0 : 1;
    bool _didUserWin = randomNumber % 2 == _selectionMod;

    if (_didUserWin) {
      smol.transfer(_user, _amountWagered);
      smol.gameMint(_user, _amountToWin);
      coinFlipsWon++;
      coinFlipAmountWon += _amountToWin;
      coinFlipsUserWon[_user]++;
      coinFlipUserAmountWon[_user] += _amountToWin;
      lastCoinFlipWon[_user] = true;
    } else {
      smol.gameBurn(address(this), _amountWagered);
      coinFlipsLost++;
      coinFlipAmountLost += _amountWagered;
      coinFlipsUserLost[_user]++;
      coinFlipUserAmountLost[_user] += _amountWagered;
      lastCoinFlipWon[_user] = false;
    }
    emit SettledCoinFlip(
      _user,
      _nonce,
      requestId,
      _isHeads,
      _amountWagered,
      _didUserWin,
      _amountToWin
    );
  }

  function setCoinFlipMinBalancePerc(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    coinFlipMinBalancePerc = _percentage;
  }

  function setCoinFlipWinPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    coinFlipWinPercentage = _percentage;
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './ISmoltingInu.sol';

/**
 * @dev SmoltingInu token interface with decimals
 */

interface ISmoltingInuDecimals is ISmoltingInu {
  function decimals() external view returns (uint8);
}