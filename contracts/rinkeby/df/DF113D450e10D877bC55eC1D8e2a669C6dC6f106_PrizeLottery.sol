//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*                                                                
_________   _...._              .--.                __.....__      
\        |.'      '-.           |__|            .-''         '.    
 \        .'```'.    '. .-,.--. .--.           /     .-''"'-.  `.  
  \      |       \     \|  .-. ||  |          /     /________\   \ 
   |     |        |    || |  | ||  |.--------.|                  | 
   |      \      /    . | |  | ||  ||____    |\    .-------------' 
   |     |\`'-.-'   .'  | |  '- |  |    /   /  \    '-.____...---. 
   |     | '-....-'`    | |     |__|  .'   /    `.             .'  
  .'     '.             | |          /    /___    `''-...... -'    
'-----------'           |_|         |         |                    
                                    |_________|                    
*/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/ICToken.sol";
import "./utils/Controller.sol";
import "./token/Ticket.sol";
import "./yield-source-interactor/CompoundYieldSourceInteractor.sol";

contract PrizeLottery is
  Controller,
  Ownable,
  CompoundYieldSourceInteractor,
  KeeperCompatibleInterface,
  VRFConsumerBaseV2
{
  using Counters for Counters.Counter;

  /* Lottery parameters */
  uint256 public constant DRAWING_PERIOD = 5 minutes; //@TODO CHANGE TO 10 DAYS
  uint256 public constant MINIMUM_DEPOSIT = 1e18; // 1

  enum State {
    OPEN,
    AWARDING_WINNER,
    CLOSED
  }

  /* Lottery parameters */
  string public name;
  Counters.Counter public lotteryId;
  State public state;
  uint256 public lotteryStart;
  uint256 public lotteryEnd;

  /* Tokens */
  Ticket internal ticket;
  IERC20 internal token;
  ICToken internal cToken;

  /* Chainlink VRF parameters */
  uint16 internal constant REQUEST_CONFIRMATIONS = 3;
  uint32 internal constant NUM_WORDS = 1;
  uint32 internal constant CALLBACK_GAS_LIMIT = 100000;

  /* Chainlink VRF parameters */
  VRFCoordinatorV2Interface internal immutable vrfCoordinator;
  uint64 internal immutable subscriptionId;
  bytes32 internal immutable keyHash;

  /* Events */
  event LotteryStarted(uint256 indexed lotteryId, IERC20 token, ICToken cToken);
  event PlayerDeposited(
    uint256 indexed lotteryId,
    address indexed player,
    uint256 amount
  );
  event UnderlyingAssetRedeemed(
    uint256 indexed lotteryId,
    address indexed player,
    uint256 amount
  );
  event LotteryWinnerRequested(
    uint256 indexed lotteryId,
    uint64 subscriptionId,
    uint256 requestId
  );
  event LotteryWinnerAwarded(
    uint256 indexed lotteryId,
    address indexed player,
    uint256 amount
  );
  event StateChanged(uint256 indexed lotteryId, State oldState, State newState);

  event Test1();
  event Test2();
  event Test3();

  constructor(
    string memory _name,
    address _ticket,
    address _token,
    address _cToken,
    uint64 _subscriptionId,
    address _vrfCoordinator,
    bytes32 _keyHash
  )
    CompoundYieldSourceInteractor(address(this))
    VRFConsumerBaseV2(_vrfCoordinator)
  {
    name = _name;
    ticket = Ticket(_ticket);
    token = IERC20(_token);
    cToken = ICToken(_cToken);
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    subscriptionId = _subscriptionId;
    keyHash = _keyHash;

    state = State.CLOSED;

    _initialize();
  }

  function _initialize() internal {
    require(
      keccak256(abi.encodePacked(state)) !=
        keccak256(abi.encodePacked(State.OPEN)),
      "PrizeLottery: REQUIRE_STATE_NOT_OPEN"
    );

    uint256 reserve = token.balanceOf(address(this));

    if (reserve > 0) {
      require(
        _supplyToCompound(address(token), address(cToken), reserve) == 0,
        "PrizeLottery: SUPPLY_FAILED"
      );
    }

    lotteryStart = block.timestamp;
    lotteryEnd = 0;
    lotteryId.increment();
    state = State.OPEN;

    emit LotteryStarted(lotteryId.current(), token, cToken);
  }

  /**
   * @notice Allows the msg.sender to deposit tokens and join the lottery
   * for the chance of winning. The amount of tokens deposited is transferred
   * into a yield protocol (Compound) and a corresponding number of tickets
   * is minted for the msg.sender. (1 ticket for each token deposited)
   * @param _amount The amount of tokens deposited
   * @return The ID of the user (msg.sender) and the amount of tickets he has
   * on that moment
   */
  function deposit(uint256 _amount) external returns (bytes32, uint256) {
    require(
      keccak256(abi.encodePacked(state)) ==
        keccak256(abi.encodePacked(State.OPEN)),
      "PrizeLottery: REQUIRE_STATE_OPEN"
    );

    require(
      _amount >= MINIMUM_DEPOSIT,
      "PrizeLottery: INSUFFICIENT_DEPOSIT_AMOUNT"
    );

    IERC20(token).transferFrom(_msgSender(), address(this), _amount);

    require(
      _supplyToCompound(address(token), address(cToken), _amount) == 0,
      "PrizeLottery: SUPPLY_FAILED"
    );

    ticket.controlledMint(_msgSender(), _amount);

    emit PlayerDeposited(lotteryId.current(), _msgSender(), _amount);

    return (
      bytes32(uint256(uint160(_msgSender()))),
      ticket.stakeOf(_msgSender())
    );
  }

  /**
   * @notice Allow the msg.sender to converts cTokens into a specified
   * quantity of the underlying asset, and returns them to the msg.sender
   * @param _tokenAmount The amount of underlying to be redeemed
   * @return The amount of tickets the caller has
   */
  function redeem(uint256 _tokenAmount) external returns (uint256) {
    require(
      _tokenAmount <= ticket.stakeOf(_msgSender()),
      "PrizeLottery: INSUFFICIENT_FUNDS_TO_REDEEM"
    );

    require(
      keccak256(abi.encodePacked(state)) !=
        keccak256(abi.encodePacked(State.AWARDING_WINNER)),
      "PrizeLottery: REQUIRE_STATE_NOT_AWARDING_WINNER"
    );

    require(
      _redeemUnderlyingFromCompound(address(cToken), _tokenAmount) == 0,
      "PrizeLottery: REDEEM_FAILED"
    );

    ticket.controlledBurn(_msgSender(), _tokenAmount);
    token.transfer(_msgSender(), _tokenAmount);

    emit UnderlyingAssetRedeemed(
      lotteryId.current(),
      _msgSender(),
      _tokenAmount
    );

    return (ticket.stakeOf(_msgSender()));
  }

  /**
   * @notice Function that calls the Chainlink VRF to get a random number.
   */
  function requestRandomWords() internal {
    require(
      keccak256(abi.encodePacked(state)) ==
        keccak256(abi.encodePacked(State.AWARDING_WINNER)),
      "PrizeLottery: REQUIRE_STATE_AWARDING_WINNER"
    );

    uint256 requestId = vrfCoordinator.requestRandomWords(
      keyHash,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    emit LotteryWinnerRequested(lotteryId.current(), subscriptionId, requestId);
  }

  /**
   * @notice Function that Chainlink VRF node calls when a random number is generated.
   * @param _randomWords Array containing `NUM_WORDS` random generated numbers
   */
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory _randomWords
  ) internal override {
    _draw(_randomWords[0]);
    _initialize();
  }

  /**
   * @notice Function that, given a random generated number, picks an
   * address and decrees it as the winner.
   * @param _randomNumber The random number generated by the Chainlink VRF
   */
  function _draw(uint256 _randomNumber) internal {
    emit Test1();
    address pickedWinner = ticket.draw(_randomNumber);

    require(isPickValid(pickedWinner), "PrizeLottery: PICK_NOT_VALID");

    emit Test2();
    lotteryEnd = block.timestamp;
    uint256 prize = prizePool();

    emit Test3();
    ticket.controlledMint(pickedWinner, prize);

    emit LotteryWinnerAwarded(lotteryId.current(), pickedWinner, prize);
  }

  /**
   * @notice This is the function that the Chainlink Keeper nodes call
   * they look for `upkeepNeeded` to return True.
   * the following should be true for this to return true:
   * 1. The time interval has passed between lottery runs
   * 2. The lottery is open
   * 3. The lottery is not empty
   * @return upkeepNeeded True if the lottery is ready to draw, otherwise False
   */
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
    bool isOpen = State.OPEN == state;
    bool timePassed = ((block.timestamp - lotteryStart) >= DRAWING_PERIOD);

    upkeepNeeded = (timePassed && isOpen && !isLotteryEmpty());
  }

  /**
   * @notice Once `checkUpkeep` is returning `true`, this function is called
   * and it kicks off a Chainlink VRF call to get a random winner.
   * ADD VRF AND MOVE `_DRAW` AND `_INTIALIZE` INSIDE THE CALLBACK FUNCTION
   */
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    (bool upkeepNeeded, ) = checkUpkeep("0x");

    require(upkeepNeeded, "PrizeLottery: UPKEEP_NOT_NEEDED");

    state = State.AWARDING_WINNER;

    requestRandomWords();
  }

  /**
   * @notice Utility function used to retrieve the current prize pool
   * @return The current prize pool
   */
  function prizePool() public returns (uint256) {
    uint256 depositedAmount = ticket.totalSupply();
    uint256 totalAmount = balanceOfUnderlyingCompound(address(cToken));

    uint256 prize = (totalAmount < depositedAmount)
      ? type(uint256).min
      : (totalAmount - depositedAmount);

    return prize;
  }

  /**
   * @notice Utility function that allows the owner to change the lottery state.
   * @param _state The new state
   */
  function changeState(State _state) external onlyOwner {
    if (_state == state) return;
    State oldState = state;
    state = _state;

    emit StateChanged(lotteryId.current(), oldState, state);
  }

  /**
   * @notice Utility function that checks if the a certain address picked is valid.
   * To be valid it needs to:
   * 1. Not be the zero address
   * 2. be an address of a played that deposited and joined the lottery
   * @param _playerPicked The address that needs to be checked
   * @return True if the address is valid, otherwise False
   */
  function isPickValid(address _playerPicked) public view returns (bool) {
    if (
      _playerPicked == address(0) ||
      ticket.stakeOf(_playerPicked) == type(uint256).min
    ) return false;
    return true;
  }

  /**
   * @notice Utility function that checks if the lottery is empty or not.
   * @return True if the lottery is empty, otherwise False
   */
  function isLotteryEmpty() public view returns (bool) {
    if (ticket.totalSupply() > 0) return false;
    return true;
  }
}

/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity ^0.8.0;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* internal */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* internal Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start
     *  @return values The values of the returned leaves
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) internal view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) internal view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICToken.sol";
import "../utils/Controller.sol";

contract CompoundYieldSourceInteractor is Controller {
  event SuppliedToCompound(
    address indexed token,
    address indexed cToken,
    uint256 amount
  );
  event RedeemedFromCompound(address indexed cToken, uint256 cTokenAmount);
  event RedeemedUnderlyingFromCompound(
    address indexed cToken,
    uint256 tokenAmount
  );

  constructor(address _controller) Controller(_controller) {}

  /**
   * @notice Allow the controller to supply assets to Compound, minting cTokens
   * @param _token The address of the token supplied
   * @param _cToken The address of the corresponding cToken
   * @param _amount The amount of tokens supplied
   * @return 0 on success, otherwise an Error code
   */
  function _supplyToCompound(
    address _token,
    address _cToken,
    uint256 _amount
  ) internal returns (uint256) {
    IERC20 token = IERC20(_token);
    ICToken cToken = ICToken(_cToken);

    token.approve(_cToken, _amount);
    uint256 mintResult = cToken.mint(_amount);

    emit SuppliedToCompound(_token, _cToken, _amount);

    return mintResult;
  }

  /**
   * @notice Allow the controller to converts a specified quantity of cTokens
   * into the underlying asset, and returns them to the msg.sender
   * @param _cToken The address of the cToken
   * @param _cTokenAmount The number of cTokens to be redeemed
   * @return 0 on success, otherwise an Error code
   */
  function _redeemFromCompound(address _cToken, uint256 _cTokenAmount)
    internal
    returns (uint256)
  {
    ICToken cToken = ICToken(_cToken);

    uint256 redeemResult = cToken.redeem(_cTokenAmount);

    emit RedeemedFromCompound(_cToken, _cTokenAmount);

    return redeemResult;
  }

  /**
   * @notice Allow the controller to converts cTokens into a specified
   * quantity of the underlying asset, and returns them to the msg.sender
   * @param _cToken The address of the cToken
   * @param _tokenAmount The amount of underlying to be redeemed
   * @return 0 on success, otherwise an Error code
   */
  function _redeemUnderlyingFromCompound(address _cToken, uint256 _tokenAmount)
    internal
    returns (uint256)
  {
    ICToken cToken = ICToken(_cToken);

    uint256 redeemResult = cToken.redeemUnderlying(_tokenAmount);

    emit RedeemedUnderlyingFromCompound(_cToken, _tokenAmount);

    return redeemResult;
  }

  /**
   * @notice The user's underlying balance, representing their
   * assets in the protocol, is equal to the user's cToken balance
   * multiplied by the Exchange Rate.
   * @param _cToken The address of the cToken
   * @return The amount of underlying currently owned by this contract.
   */
  function balanceOfUnderlyingCompound(address _cToken)
    public
    returns (uint256)
  {
    ICToken cToken = ICToken(_cToken);
    return cToken.balanceOfUnderlying(address(this));
  }

  /**
   * @notice Get the current supply rate per block
   * @param _cToken The address of the cToken
   * @return The current supply rate as an unsigned integer, scaled by 1e18.
   */
  function supplyRatePerBlockCompound(address _cToken)
    public
    returns (uint256)
  {
    ICToken cToken = ICToken(_cToken);
    return cToken.supplyRatePerBlock();
  }

  /**
   * @notice Get the current exchange rate
   * @param _cToken The address of the cToken
   * @return The current exchange rate as an unsigned integer,
   * scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)
   */
  function exchangeRateCompound(address _cToken) public returns (uint256) {
    ICToken cToken = ICToken(_cToken);
    return cToken.exchangeRateCurrent();
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Controller {
  event ControllerRoleTransferred(
    address indexed oldController,
    address indexed newController
  );

  address private _controller;

  constructor(address _currentController) {
    _transferControllerRole(_currentController);
  }

  function controller() public view virtual returns (address) {
    return _controller;
  }

  function transferControllerRole(address _newController)
    public
    virtual
    onlyController
  {
    require(
      _newController != address(0),
      "Controller: CONTROLLER_IS_ZERO_ADDRESS"
    );
    _transferControllerRole(_newController);
  }

  function _transferControllerRole(address _newController) internal virtual {
    address oldController = _controller;
    _controller = _newController;

    emit ControllerRoleTransferred(oldController, _newController);
  }

  modifier onlyController() {
    require(controller() == msg.sender, "Controller: CALLER_IS_NOT_CONTROLLER");
    _;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "sortition-sum-tree-factory/contracts/SortitionSumTreeFactory.sol";
import "./ControlledToken.sol";
import "../interfaces/ITicket.sol";

contract Ticket is ITicket, ControlledToken {
  using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

  uint256 private constant MAX_TREE_LEAVES = 5;
  bytes32 private treeKey;

  SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

  /**
   * @notice Create the Ticket token contract
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _controller The controller
   */
  constructor(
    string memory _name,
    string memory _symbol,
    address _controller
  ) ControlledToken(_name, _symbol, _controller) {
    require(_controller != address(0), "Ticket: CONTROLLER_NOT_ZERO");
    treeKey = keccak256(abi.encodePacked(_name));
    sortitionSumTrees.createTree(treeKey, MAX_TREE_LEAVES);
  }

  /**
   * Return the amount of tickets owned by the `user`
   * @param _user Address of the user
   * @return The amount of token owned by the `user`
   */
  function stakeOf(address _user) external view override returns (uint256) {
    return sortitionSumTrees.stakeOf(treeKey, bytes32(uint256(uint160(_user))));
  }

  /**
   * Draw an address from a tree using a number.
   * Note that this function reverts if the sum of all values in the tree is 0.
   * @param _number The drawn number
   * @return The address drawn
   */
  function draw(uint256 _number) external view override returns (address) {
    uint256 bound = totalSupply();
    address selected;
    if (bound == 0) {
      selected = address(0);
    } else {
      selected = address(
        uint160(uint256(sortitionSumTrees.draw(treeKey, _number)))
      );
    }
    return selected;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _amount);

    if (_from == _to) {
      return;
    }

    if (_from != address(0)) {
      uint256 fromBalance = balanceOf(_from) - _amount;
      sortitionSumTrees.set(
        treeKey,
        fromBalance,
        bytes32(uint256(uint160(_from)))
      );
    }

    if (_to != address(0)) {
      uint256 toBalance = balanceOf(_to) + _amount;
      sortitionSumTrees.set(treeKey, toBalance, bytes32(uint256(uint160(_to))));
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/Controller.sol";

contract ControlledToken is Controller, ERC20 {
  /**
   * @notice Create a ControlledToken token
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _controller The address of the controller
   */
  constructor(
    string memory _name,
    string memory _symbol,
    address _controller
  ) Controller(_controller) ERC20(_name, _symbol) {}

  /**
   * @notice Allows the controller to mint `_amount` of tokens
   * to the `_user` address
   * @param _user The address to mint tokens to
   * @param _amount The amount of tokens to mint
   */
  function controlledMint(address _user, uint256 _amount)
    external
    onlyController
  {
    _mint(_user, _amount);
  }

  /**
   * @notice Allows the controller to burn `_amount` of tokens
   * from the `_user` address
   * @param _user The address to burn tokens from
   * @param _amount The amount of tokens to burn
   */
  function controlledBurn(address _user, uint256 _amount)
    external
    onlyController
  {
    _burn(_user, _amount);
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITicket {
  /*function players() external view returns (address[] memory);*/

  function stakeOf(address user) external view returns (uint256);

  /*function stakes() external view returns (uint256[] memory);*/

  function draw(uint256 randomNumber) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICToken is IERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view override returns (uint256);

  function underlying() external view returns (address);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function supplyRatePerBlock() external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 amount) external returns (uint256);

  function balanceOf(address user) external view override returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
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