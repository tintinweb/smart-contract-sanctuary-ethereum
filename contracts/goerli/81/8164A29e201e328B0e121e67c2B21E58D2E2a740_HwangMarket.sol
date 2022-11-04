// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ListingContract.sol";
import "./IListingOwner.sol";
import "./Models.sol";
import "./HwangMarket.sol";
import "./IterableMapping.sol";
import "./GameERC20Token.sol";
import "./GameERC20TokenFactory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GameContract is IListingOwner {
  using SafeMath for uint256;
  using IterableMapping for IterableMapping.ListingsMap;

  address public hwangMarketAddr; 
  Models.GameMetadata public gameInfo;

  AggregatorV3Interface internal priceFeed;

  // Trx types constant
  string constant BetActivityType = "BET";
  string constant WithdrawActivityType = "WITHDRAW";

  // conversion rate from 1 HMTKN to 1 Game Token
  uint constant mainTkn2GameTknConversionRate = 1;
  uint constant supplyLimit = 1000;

  Models.Trx[] trxs;
  uint256 internal trxId;

  address public gameNoTokenContractAddress;
  address public gameYesTokenContractAddress;

  IterableMapping.ListingsMap private listingContracts;
  uint256 public listingsCount;

  event NewListing(Models.ListingInfo listingInfo);
  event ListingFulfilled(Models.ListingInfo listingInfo);

  // constructor takes in a resolve time, a oracleAddr (oracle address), and a threshold, 
  // where a gameSide of NO indicates < threshold, and a gameSide of YES indicates >= threshold
  constructor(address hmAddr , uint256 _resolveTime, address _oracleAddr, int256 thres, string memory _tag, string memory _title, uint256 _id, address gytAddr, address gntAddr) {
    hwangMarketAddr = hmAddr;
    priceFeed = AggregatorV3Interface(_oracleAddr);
    gameInfo = Models.GameMetadata({
      id: _id,
      createdTime: block.timestamp,
      addr: address(this),
      tag: _tag,
      title: _title,
      oracleAddr: _oracleAddr,
      resolveTime: _resolveTime,
      threshold: thres,
      totalAmount: 0,
      betYesAmount: 0,
      betNoAmount: 0,
      gameOutcome: 0
    });

    // every game contract deploys 2 IERC20 token contracts
    // yes and no tokens
    gameNoTokenContractAddress = gntAddr;
    gameYesTokenContractAddress = gytAddr;
  }

  // creates a new listing
  function newListing(address _player, uint256 token1Amt, address token2, uint256 token2Amt) public returns(Models.ListingInfo memory) {
    require(msg.sender == gameNoTokenContractAddress || msg.sender == gameYesTokenContractAddress, "only game token can create new listings");
    uint256 newListingId = listingsCount;
    ListingContract newListingContract = new ListingContract(newListingId, _player, msg.sender, token1Amt, token2, token2Amt);
    Models.ListingInfo memory listingInfo = Models.ListingInfo({
      listingId: newListingId,
      createdTime: newListingContract.createdTime(),
      listingAddr: address(newListingContract),
      player1: _player,
      token1: msg.sender,
      token1Amt: token1Amt,
      player2: address(0),
      token2: token2,
      token2Amt: token2Amt,
      fulfilled: false,
      fulfilledTime: 0
    });
    listingContracts.set(newListingId, listingInfo);

    listingsCount++;

    emit NewListing(listingInfo);
    return listingInfo;
  }

  function getListingContractAddressById(uint listingId) external view returns(address) {
    return listingContracts.get(listingId).listingAddr;
  }

  function getGameInfo() external view returns (Models.GameMetadata memory) {
    return gameInfo;
  }

  function getAllListings() external view returns (Models.ListingInfo[] memory) {
    return listingContracts.getlistingValues();
  }

  function updateListing(Models.ListingInfo memory listingInfo) public {
    listingContracts.set(listingInfo.listingId, listingInfo);

    emit ListingFulfilled(listingInfo);
  }

  /**
    * Returns the latest price
    */
  function getLatestPrice() public view returns (int) {
      (
          /*uint80 roundID*/,
          int price,
          /*uint startedAt*/,
          /*uint timeStamp*/,
          /*uint80 answeredInRound*/
      ) = priceFeed.latestRoundData();
      return price;
  }

  // payable keyword should allow depositing of ethereum into smart contract
  // allow msg.sender address to register as a player
  function addPlayer(address _player, uint256 hwangMktTokenAmt, uint8 betSide) public {
      require(gameInfo.gameOutcome == 0, "Game is closed, no further bets accepted");
      require(betSide == 1 || betSide == 2, "bet side is not recognised");
      require(block.timestamp <= gameInfo.resolveTime, "cannot put bets after resolve time");

      GameERC20Token gameTokenContract = GameERC20Token(gameNoTokenContractAddress);
      if (betSide == 1) {
        gameTokenContract = GameERC20Token(gameYesTokenContractAddress);
      }
      uint256 requestedMintAmt = hwangMktTokenAmt * mainTkn2GameTknConversionRate;
      // mint the respective 1-1 game token to the player
      gameTokenContract.mint(_player, requestedMintAmt);
      // collect the player's main token, deposit under the game address
      HwangMarket hm = HwangMarket(hwangMarketAddr);
      _safeTransferFrom(IERC20(hm.mainTokenAddress()), _player, address(this), hwangMktTokenAmt);

      // book keeping
      if (betSide == 1) {
        gameInfo.betYesAmount += hwangMktTokenAmt;
      } else {
        gameInfo.betNoAmount += hwangMktTokenAmt;
      }
      uint256 timestamp = block.timestamp;
      trxs.push(Models.Trx({
        trxId: trxId,
        activityType: BetActivityType,
        gameSide: betSide,
        trxAmt: hwangMktTokenAmt,
        trxTime: timestamp,
        from: address(this),
        to: _player
      }));
      trxId++;

      hm.playerJoinedSide(_player, betSide, hwangMktTokenAmt, timestamp);
    }

  // impt: anyone can call the contract to perform upkeep but it has a guard to protect against early resolves
  // and it checks against a "trusted" oracle chainlink to fetch the result
  function performUpkeep() public {
    if (block.timestamp < gameInfo.resolveTime || gameInfo.gameOutcome != 0) {
      return;
    }

    uint8 rawSide = 2;
    if (getLatestPrice() >= gameInfo.threshold) {
      rawSide = 1;
    }
    gameInfo.gameOutcome = rawSide;

    HwangMarket(hwangMarketAddr).concludeGame(rawSide);
  }

  // allow winners to withdraw their winnings in term of HMTKN
  function withdrawWinnings(uint withdrawAmt) public {
    require(gameInfo.gameOutcome != 0, "game outcome cannot be unknown"); // game outcome cannot be unknown
    IERC20 gameTokenContract = IERC20(gameNoTokenContractAddress);
    if (gameInfo.gameOutcome == 1) {
      gameTokenContract = IERC20(gameYesTokenContractAddress);
    }
    require(gameTokenContract.allowance(msg.sender, address(this)) >= withdrawAmt, "player must approve withdraw amount");
    require(gameTokenContract.balanceOf(msg.sender) >= withdrawAmt, "player must have game token amount to withdraw");

    // where to calculate amount of winnings
    // calculated winnings = (player's bet amount / total bet amount on winning side) * total bet amount on losing side
    uint256 amtOnWinning = gameInfo.betNoAmount;
    uint256 amtOnLosing = gameInfo.betYesAmount;
    if (gameInfo.gameOutcome == 1) {
      amtOnWinning = gameInfo.betYesAmount;
      amtOnLosing = gameInfo.betNoAmount;
    }
    uint256 deposit = (1 / mainTkn2GameTknConversionRate) * withdrawAmt;
    uint256 winnings = ((deposit / amtOnWinning) * amtOnLosing) + deposit;

    // initiate transfer of hwang market tokens from game to player
    IERC20(HwangMarket(hwangMarketAddr).mainTokenAddress()).transfer(msg.sender, winnings);
    // initiate transfer of game token from player back to game
    _safeTransferFrom(gameTokenContract, msg.sender, address(this), withdrawAmt);

    uint256 timestamp = block.timestamp;
    trxs.push(Models.Trx({
      trxId: trxId,
      activityType: WithdrawActivityType,
      gameSide: gameInfo.gameOutcome,
      trxAmt: winnings,
      trxTime: timestamp,
      from: address(this),
      to: msg.sender
    }));
    trxId++;
    HwangMarket(hwangMarketAddr).playerWithdrawWinnings(msg.sender, gameInfo.gameOutcome, winnings, timestamp);
  }

  function _safeTransferFrom(
    IERC20 token,
    address sender,
    address recipient,
    uint amount
    ) private {
      bool sent = token.transferFrom(sender, recipient, amount);
      require(sent, "Token transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./GameContract.sol";

contract GameContractFactory {
  function createGame(address hmAddr, uint256 resolveTime, address oracleAddr, int256 threshold, string memory tag, string memory title, uint256 id, address gytAddr, address gntAddr) external returns (address) {
    return address(new GameContract(hmAddr, resolveTime, oracleAddr, threshold, tag, title, id, gytAddr, gntAddr));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IListableToken.sol";
import "./GameContract.sol";
import "./ListingContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GameERC20Token is IERC20, IListableToken {
  using SafeMath for uint256;
  
  uint public supplyLimit;
  uint public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;
  string public name;
  string public symbol;
  address creator;
  // mapping(address => uint) public totalAllowanceCommited;
  GameContract gameContract;

  constructor(string memory _name, string memory _symbol, uint _supplyLimit) {
    creator = msg.sender;
    name = _name;
    symbol = _symbol;
    supplyLimit = _supplyLimit;
    totalSupply = 0;
    gameContract = GameContract(msg.sender);
  }

  function transfer(address recipient, uint amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    balanceOf[msg.sender] -= amount;
    balanceOf[recipient] += amount;
    // totalAllowanceCommited[msg.sender] -= amount;
    allowance[msg.sender][recipient] -= amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    // require(totalAllowanceCommited[msg.sender] + amount <= balanceOf[msg.sender], "total allowance for approver overcommited, you cannot allow more than you own");
    allowance[msg.sender][spender] = amount;
    // totalAllowanceCommited[msg.sender] += amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  // similar to transfer but difference is that someone else is authorised to
  // trigger the transfer
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool) {
    require(allowance[sender][msg.sender] >= amount, "insufficient allowance to recipient from sender");
    require(balanceOf[sender] >= amount, "insufficient balance in sender");
    
    // totalAllowanceCommited[sender] -= amount;
    allowance[sender][msg.sender] -= amount;
    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  // a player has to provide some HMTKN in exchange for the game token,
  // 1 HMTKN = 1 gametoken
  function mint(address _player, uint amount) external {
    require(msg.sender == creator, "Not authorized");
    require(totalSupply + amount <= supplyLimit, "cannot mint the requested amount of tokens, supply limit too low");
    balanceOf[_player] += amount;
    totalSupply += amount;

    emit Transfer(address(0), _player, amount);
  }

  function burn(uint amount) external {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
  }

  // player1 has to approve the token1 amount to the listing contract for spending
  function listUpTokensForExchange(uint256 token1Amt, address token2, uint256 token2Amt) external returns (Models.ListingInfo memory) {
    require(balanceOf[msg.sender] >= token1Amt, "insufficient balance in sender");
    // require(totalAllowanceCommited[msg.sender] + token1Amt <= balanceOf[msg.sender], "total allowance for approver overcommited, you cannot allow more than you own");

    // create a listing and approve the transfer amount for the newly listed contract
    Models.ListingInfo memory listingInfo = gameContract.newListing(msg.sender, token1Amt, token2, token2Amt);
    address listingAddress = listingInfo.listingAddr;
    allowance[msg.sender][listingAddress] += token1Amt;
    // totalAllowanceCommited[msg.sender] += token1Amt;
    emit Approval(msg.sender, listingAddress, token1Amt);

    return listingInfo;
  }

  function acceptTokenExchange(address listingAddress) external returns (Models.ListingInfo memory) {
    ListingContract listingContract = ListingContract(listingAddress);
    require(listingContract.token2() == address(this), "listing wants a different token2");
    require(balanceOf[msg.sender] >= listingContract.token2Amt(), "insufficient balance in sender");
    // require(totalAllowanceCommited[msg.sender] + listingContract.token2Amt() <= balanceOf[msg.sender], "total allowance for approver overcommited, you cannot allow more than you own");

    // perform approval
    allowance[msg.sender][listingAddress] += listingContract.token2Amt();
    // totalAllowanceCommited[msg.sender] += listingContract.token2();
    emit Approval(msg.sender, listingAddress, listingContract.token2Amt());

    // trigger listing via main contract for book keeping
    Models.ListingInfo memory listingInfo = listingContract.trigger(msg.sender);

    return listingInfo;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./GameERC20Token.sol";

contract GameERC20TokenFactory {
  function createGameERC20Token(string memory _name, string memory _symbol, uint _supplyLimit) external returns (address) {
    return address(new GameERC20Token(_name, _symbol, _supplyLimit));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MainToken.sol";
import "./GameContract.sol";
import "./GameContractFactory.sol";
import "./GameERC20TokenFactory.sol";
import "./Models.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HwangMarket {
  using SafeMath for uint256;
  address public mainTokenAddress;

  // factory contracts are used to reduce contract build size :(
  GameContractFactory gameFactory;
  GameERC20TokenFactory gameTokenFactory;

  // for all activity
  uint256 private trxId;

  // for all games created
  uint256 private gameCount;
  mapping(uint256 => address) public gameId2Addr;
  mapping(address => uint256) public gameAddr2Id;
  
  // for all ongoing games
  uint256 private ongoingGamesCnt; // record end of ongoing games array
  address[] public ongoingGames;
  mapping(uint256 => int256) ongoingGamesId2Idx;

  // for all closed games
  address[] public closedGames;

  // Activity types constant
  string constant BetActivityType = "BET";
  string constant WithdrawActivityType = "WITHDRAW";

  mapping(address => Models.Activity[]) public playersRecords;

  constructor(address mainTokenAddr, address gameContractFactoryAddr, address gameTokenFactoryAddr) {
    // we start counting from game 1, game id 0 is nonsense since its also default value
    gameCount = 1;
    mainTokenAddress = mainTokenAddr;
    gameFactory = GameContractFactory(gameContractFactoryAddr);
    gameTokenFactory = GameERC20TokenFactory(gameTokenFactoryAddr);
  }

  event GameCreated(Models.GameMetadata gameMetadata);
  event PlayerJoinedGameEvent(address player, uint256 gameId, address gameAddr, uint8 betSide, uint256 amount);
  event PlayerWithdrawedWinnings(address player, uint256 gameId, address gameAddr, uint8 betSide, uint256 withdrawedAmt);
  event GameConcluded(uint256 gameId, address gameAddr, uint8 gameOutcome);
  event NewListing(Models.ListingInfo listingInfo);
  event ListingFulfilled(Models.ListingInfo listingInfo);

  // create game contract instance
  function createGame(uint256 resolveTime, address oracleAddr, int256 threshold, string memory tag, string memory title) external {
    address gytAddr = gameTokenFactory.createGameERC20Token("GameYes", "GYT", 1000);
    address gntAddr = gameTokenFactory.createGameERC20Token("GameNo", "GNT", 1000);
    address newGameAddress = gameFactory.createGame(address(this), resolveTime, oracleAddr, threshold, tag, title, gameCount, gytAddr, gntAddr);
    gameId2Addr[gameCount] = newGameAddress;
    gameAddr2Id[newGameAddress] = gameCount;

    ongoingGamesId2Idx[gameCount] = int256(ongoingGamesCnt);
    ongoingGames.push(newGameAddress);

    ongoingGamesCnt = SafeMath.add(ongoingGamesCnt, 1);

    emit GameCreated(GameContract(newGameAddress).getGameInfo());

    gameCount = SafeMath.add(gameCount, 1);
  }
  
  // fetches all games
  function getAllGames() public view returns (Models.AllGames memory) {
    return Models.AllGames({ongoingGames: ongoingGames, closedGames: closedGames});
  }

  // callable only by the game itself
  // A player joined the game on a particular side
  function playerJoinedSide(address player, uint8 betSide, uint256 amount, uint256 timestamp) external {
    require(gameAddr2Id[msg.sender] != 0 && ongoingGamesId2Idx[gameAddr2Id[msg.sender]] != -1);
    address gameAddr = msg.sender;
    uint256 gameId = gameAddr2Id[gameAddr];

    // record this activity as well
    playersRecords[player].push(Models.Activity({
      trxId: trxId,
      activityType: BetActivityType,
      gameId: gameId,
      trxAmt: amount,
      trxTime: timestamp,
      gameSide: betSide,
      from: player,
      to: gameAddr
    }));

    trxId = SafeMath.add(trxId, 1);

    emit PlayerJoinedGameEvent(player, gameId, gameAddr, betSide, amount);
  }

  // callable only by contract
  // note: withdraw winnings means recording player's owned game tokens -> hwang market tokens
  function playerWithdrawWinnings(address _player, uint8 betSide, uint256 withdrawAmt, uint256 timestamp) external {
    require(gameAddr2Id[msg.sender] != 0);
    address gameAddr = msg.sender;
    uint256 gameId = gameAddr2Id[gameAddr];
    playersRecords[_player].push(Models.Activity({
      trxId: trxId,
      activityType: WithdrawActivityType,
      gameId: gameId,
      trxAmt: withdrawAmt,
      trxTime: timestamp,
      gameSide: betSide,
      from: gameAddr,
      to: _player
    }));

    trxId = SafeMath.add(trxId, 1);

    emit PlayerWithdrawedWinnings(_player, gameId, gameAddr, betSide, withdrawAmt);
  }

  function concludeGame(uint8 gameOutcome) external {
    require(gameAddr2Id[msg.sender] != 0);
    address gameAddr = msg.sender;
    uint256 gameId = gameAddr2Id[gameAddr];

    // move game out of existing ongoing games
    int256 temp = ongoingGamesId2Idx[gameId];
    if (temp == -1) { // already concluded
      return;
    }
    uint256 existingGameIdx = uint256(temp);
    address finishedGameAddress = ongoingGames[existingGameIdx];
    address lastOngoingGameAddress = ongoingGames[SafeMath.sub(ongoingGamesCnt, 1)];
    ongoingGamesId2Idx[gameAddr2Id[lastOngoingGameAddress]] = int256(existingGameIdx);
    ongoingGamesId2Idx[gameId] = -1;
    ongoingGames[existingGameIdx] = lastOngoingGameAddress;
    ongoingGamesCnt = SafeMath.sub(ongoingGamesCnt, 1);

    // add this game to array of closedGames
    closedGames.push(finishedGameAddress);
    ongoingGames.pop();

    emit GameConcluded(gameId, gameAddr, gameOutcome);
  }

  function getPlayersTrxRecords(address player) public view returns (Models.Activity[] memory) {
    return playersRecords[player];
  }

  function checkAllOngoingGamesUpkeep() external {
    for (uint256 i=0; i<ongoingGamesCnt; i++) {
      GameContract(ongoingGames[i]).performUpkeep();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Models.sol";

/*
  To list tokens up on the site, we require tokens to follow the following interface, with the following methods.
  However, it is still possible to perform token listing with the standard approve and transfer IERC20 token interface,
  just that it cannot be done via the UI which will expect these methods to be implemented on the token contract.
  */
interface IListableToken {
  function acceptTokenExchange(address listingAddress) external returns (Models.ListingInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Models.sol";

interface IListingOwner {
  function updateListing(Models.ListingInfo memory listingInfo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Models.sol";

library IterableMapping {
  struct ListingsMap {
    uint[] keys;
    mapping(uint => Models.ListingInfo) values;
    mapping(uint => uint) indexOf;
    mapping(uint => bool) inserted;
    Models.ListingInfo[] listingValues;
  }

  function contains(ListingsMap storage map, uint key) public view returns(bool) {
    return map.inserted[key];
  }

  function get(ListingsMap storage map, uint key) public view returns (Models.ListingInfo memory) {
      return map.values[key];
  }

  function getKeyAtIndex(ListingsMap storage map, uint index) public view returns (uint) {
      return map.keys[index];
  }

  function size(ListingsMap storage map) public view returns (uint) {
      return map.keys.length;
  }

  function getlistingValues(ListingsMap storage map) public view returns (Models.ListingInfo[] memory) {
    return map.listingValues;
  }

  function set(
    ListingsMap storage map,
    uint key,
    Models.ListingInfo memory val
  ) public {
    if (map.inserted[key]) {
        map.values[key] = val;
        map.listingValues[map.indexOf[key]] = val;
    } else {
        map.inserted[key] = true;
        map.values[key] = val;
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
        map.listingValues.push(val);
    }
  }

  function remove(ListingsMap storage map, uint key) public {
    if (!map.inserted[key]) {
        return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    uint lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
    map.listingValues[index] = map.listingValues[lastIndex];
    map.listingValues.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IListingOwner.sol";
import "./Models.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// listing contract is effectively an IERC20 token swap contract, 
// with both parties required to trust it, 
// by already preapproving it as a spender for the corresponding amount
contract ListingContract {
  address public creator;
  uint256 public listingId;
  uint256 public createdTime;
  uint256 public newListingContract;
  address public player1;
  address public token1;
  IERC20 public token1Contract;
  uint256 public token1Amt;

  address public player2;
  address public token2;
  IERC20 public token2Contract;
  uint256 public token2Amt;

  bool public fulfilled;

  constructor(uint256 _listingId, address _player, address _token1, uint256 _token1Amt, address _token2, uint256 _token2Amt) {
    creator = msg.sender;
    listingId = _listingId;
    createdTime = block.timestamp;
    player1 = _player;
    token1 = _token1;
    token1Amt = _token1Amt;
    token2 = _token2;
    token2Amt = _token2Amt;

    token1Contract = IERC20(_token1);
    require(token1Contract.balanceOf(_player) >= _token1Amt, "player 1 has insufficient balance of token 1 to create a listing");
    token2Contract = IERC20(_token2);
    
    fulfilled = false;
  }

  // trigger means when there is a suitable player 2, offering up the asked amount of token2 
  // to execute the trade
  function trigger(address _player2) external returns (Models.ListingInfo memory) {
    require(
      token1Contract.allowance(player1, address(this)) >= token1Amt,
      "Token 1 allowance too low"
    );
    require(
      token2Contract.allowance(_player2, address(this)) >= token2Amt,
      "Token 2 allowance too low"
    );

    _safeTransferFrom(token1Contract, player1, _player2, token1Amt);
    _safeTransferFrom(token2Contract, _player2, player1, token2Amt);
    player2 = _player2;
    fulfilled = true;

    Models.ListingInfo memory listingInfo = Models.ListingInfo({
      listingId: listingId,
      createdTime: createdTime,
      listingAddr: address(this),
      player1: player1,
      token1: token1,
      token1Amt: token1Amt,
      player2: player2,
      token2: token2,
      token2Amt: token2Amt,
      fulfilled: fulfilled,
      fulfilledTime: block.timestamp
    });
    IListingOwner(creator).updateListing(listingInfo);

    return listingInfo;
  }

  function _safeTransferFrom(
    IERC20 token,
    address sender,
    address recipient,
    uint amount
  ) private {
    bool sent = token.transferFrom(sender, recipient, amount);
    require(sent, "Token transfer failed");
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IListableToken.sol";
import "./ListingContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MainToken is IERC20, IListableToken {
  using SafeMath for uint256;
  /*
    IERC20 implementation
  */
  uint public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;
  string public name = "HwangMarket";
  string public symbol = "HMTKN";
  uint8 public decimals = 18;
  uint256 public totalEthSupply = 0;

  uint constant public eth2TknConversionRate = 1;

  constructor() {}

  function transfer(address recipient, uint amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    balanceOf[msg.sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool) {
    require(allowance[sender][msg.sender] >= amount, "insufficient allowance to recipient from msg sender");
    require(balanceOf[sender] >= amount, "insufficient balance in sender");
    
    allowance[sender][msg.sender] -= amount;
    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  // a player has to provide some eth in exchange for hwang market token,
  // 1 wei = 1 HMTKN
  function mint(address _player, uint256 amount) external payable {
    uint256 _ethAmt = amount * (1 / eth2TknConversionRate);
    require(msg.value >= _ethAmt, "Insufficient msg value to cover eth amount");
    require(_ethAmt <= msg.sender.balance, "You do not have enough balance");

    balanceOf[_player] += amount;
    totalSupply += amount;
    totalEthSupply += msg.value;
    emit Transfer(address(this), _player, amount);
  }

  // player can exchange in HwangMarket tokens for eth
  function cashout(uint tokenAmt) external {
    require(balanceOf[msg.sender] >= tokenAmt, "insufficient balance in player");

    uint ethAmt = tokenAmt * (1 / eth2TknConversionRate);
    payable(msg.sender).transfer(ethAmt);
    balanceOf[msg.sender] -= tokenAmt;
    emit Transfer(msg.sender, address(this), tokenAmt);
    totalSupply -= tokenAmt;
    totalEthSupply -= ethAmt;
  }

  function burn(uint amount) external {
    require(balanceOf[msg.sender] >= amount, "insufficient balance in sender");
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
  }

  function acceptTokenExchange(address listingAddress) external returns (Models.ListingInfo memory) {
    ListingContract listingContract = ListingContract(listingAddress);
    require(listingContract.token2() == address(this), "listing wants a different token2");
    require(balanceOf[msg.sender] >= listingContract.token2Amt(), "insufficient balance in sender");

    // perform approval
    allowance[msg.sender][listingAddress] = listingContract.token2Amt();
    emit Approval(msg.sender, listingAddress, listingContract.token2Amt());

    // trigger listing via main contract for book keeping
    Models.ListingInfo memory listingInfo = listingContract.trigger(msg.sender);

    return listingInfo;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Models {
  struct ListingInfo {
    uint256 listingId;
    uint256 createdTime;
    address listingAddr;
    address player1;
    address token1;
    uint256 token1Amt;
    address player2;
    address token2;
    uint256 token2Amt;

    bool fulfilled;
    uint256 fulfilledTime;
  }

  // Additionally, we want to keep a record of all player's movements on chain.
  // That is, we want to record everytime a player bets (buys a position), or sells his position (and to who), or withdraws his winnings
  struct Activity {
    // Common fields
    uint256 trxId;
    string activityType;  // "BET", "SELL", "WITHDRAW"
    uint256 gameId;
    uint256 trxAmt;
    uint256 trxTime; // when the trx was initiated
    uint8 gameSide; // 1 - YES, 2 - NO
    address from;
    address to;
  }

  struct GameMetadata {
    uint256 id;
    uint256 createdTime;
    address addr;
    string tag;
    string title;
    address oracleAddr;
    uint256 resolveTime;
    int256 threshold;

    uint256 totalAmount;
    uint256 betYesAmount;
    uint256 betNoAmount;
    uint8 gameOutcome;
  }

  struct AllGames {
    address[] ongoingGames;
    address[] closedGames;
  }

  struct TokenInfo {
    address tokenAddr;
    uint8 betSide;

    uint256 gameId;
    address gameAddr;
    string gameTag;
    string gameTitle;
    address gameOracleAddr;
    uint256 gameResolveTime;
    int256 gameThreshold;
  }

  // for every record, we track a list of transactions
  struct Trx {
    // Common fields
    uint256 trxId;
    string activityType;  // "BET", "SELL"
    uint256 trxAmt;
    uint256 trxTime; // when the trx was initiated
    uint8 gameSide;

    // if BET, from = game contract addr, to = player addr
    // if SELL, from = seller addr, to = buyer addr
    address from;
    address to;
  }
}