// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MagayoOracle is ChainlinkClient, Ownable {
  event RequestName(bytes32 indexed requestId);

  event RequestCountry(bytes32 indexed requestId);

  event RequestState(bytes32 indexed requestId);

  event RequestMainMin(bytes32 indexed requestId);

  event RequestMainMax(bytes32 indexed requestId);

  event RequestMainDrawn(bytes32 indexed requestId);

  event RequestBonusMin(bytes32 indexed requestId);

  event RequestBonusMax(bytes32 indexed requestId);

  event RequestBonusDrawn(bytes32 indexed requestId);

  event RequestSameBalls(bytes32 indexed requestId);

  event RequestDigits(bytes32 indexed requestId);

  event RequestDrawn(bytes32 indexed requestId);

  // event RequestIsOption(
  //   bytes32 indexed requestId
  // );

  // event RequestOptionDesc(
  //   bytes32 indexed requestId
  // );

  // event RequestNextDraw(
  //   bytes32 indexed requestId
  // );

  event FulfillName(bytes32 indexed requestId, bytes32 name);

  event FulfillCountry(bytes32 indexed requestId, bytes32 country);

  event FulfillState(bytes32 indexed requestId, bytes32 state);

  event FulfillMainMin(bytes32 indexed requestId, uint256 mainMin);

  event FulfillMainMax(bytes32 indexed requestId, uint256 mainMax);

  event FulfillMainDrawn(bytes32 indexed requestId, uint256 mainDrawn);

  event FulfillBonusMin(bytes32 indexed requestId, uint256 bonusMin);

  event FulfillBonusMax(bytes32 indexed requestId, uint256 bonusMax);

  event FulfillBonusDrawn(bytes32 indexed requestId, uint256 bonusDrawn);

  event FulfillSameBalls(bytes32 indexed requestId, bool sameBalls);

  event FulfillDigits(bytes32 indexed requestId, uint256 digits);

  event FulfillDrawn(bytes32 indexed requestId, uint256 drawn);

  // event FulfillIsOption(
  //   bytes32 indexed requestId,
  //   bool isOption
  // );

  // event FulfillOptionDesc(
  //   bytes32 indexed requestId,
  //   bytes32 optionDesc
  // );

  // event FulfillNextDraw(
  //   bytes32 indexed requestId,
  //   uint256 nextDraw
  // );

  struct Game {
    bytes32 name;
    bytes32 country;
    bytes32 state;
    uint256 mainMin;
    uint256 mainMax;
    uint256 mainDrawn;
    uint256 bonusMin;
    uint256 bonusMax;
    uint256 bonusDrawn;
    bool sameBalls;
    uint256 digits;
    uint256 drawn;
    uint256 duration;
    // bool isOption;
    // bytes32 optionDesc;
    // uint256 nextDraw;
  }

  // Kovan Oracle Info
  address oracleAddress = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
  bytes32 bytes32JobId = "50fc4215f89443d185b061e5d7af9490";
  bytes32 uint256JobId = "29fa9aa13bf1468788b7cc4a500a45b8";
  bytes32 boolJobId = "6d914edc36e14d6c880c9c55bda5bc04";

  // Rinkeby Oracle Info
  // address oracleAddress = 0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e;
  // bytes32 bytes32JobId = "b0bde308282843d49a3a8d2dd2464af1";
  // bytes32 uint256JobId = "6d1bfe27e7034b1d87b5270556b17277";
  // bytes32 boolJobId = "4ce9b71a1ac94abcad1ff9198e760b8c";

  uint256 oraclePayment = 0.1 * 10**18; // 0.1 LINK;

  mapping(bytes32 => Game) public games;

  bytes32 public oracleName;
  bytes32 public game;

  constructor(string memory _game, uint256 _duration) public {
    setPublicChainlinkToken();

    // Game
    game = stringToBytes32(_game);
    // Should get from requestNextDraw but the conversion is difficult
    games[game].duration = _duration;
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function requestAll(string calldata _apiKey, string calldata _game) external {
    requestName(_apiKey, _game);
    requestCountry(_apiKey, _game);
    requestState(_apiKey, _game);
    requestMainMin(_apiKey, _game);
    requestMainMax(_apiKey, _game);
    requestMainDrawn(_apiKey, _game);
    requestBonusMin(_apiKey, _game);
    requestBonusMax(_apiKey, _game);
    requestBonusDrawn(_apiKey, _game);
    requestSameBalls(_apiKey, _game);
    requestDigits(_apiKey, _game);
    // requestIsOption(_apiKey, _game);
    // requestOptionDesc(_apiKey, _game);
    // requestNextDraw(_apiKey, _game);
  }

  function requestName(string calldata _apiKey, string calldata _game) public {
    require(games[game].name == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32JobId,
      address(this),
      this.fulfillName.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "name");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestName(requestId);
  }

  function fulfillName(bytes32 _requestId, bytes32 _name)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillName(_requestId, _name);
    games[game].name = _name;
  }

  function requestCountry(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].country == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32JobId,
      address(this),
      this.fulfillCountry.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "country");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestCountry(requestId);
  }

  function fulfillCountry(bytes32 _requestId, bytes32 _country)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillCountry(_requestId, _country);
    games[game].country = _country;
  }

  function requestState(string calldata _apiKey, string calldata _game) public {
    require(games[game].state == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32JobId,
      address(this),
      this.fulfillState.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "state");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestState(requestId);
  }

  function fulfillState(bytes32 _requestId, bytes32 _state)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillState(_requestId, _state);
    games[game].state = _state;
  }

  function requestMainMin(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].mainMin == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillMainMin.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "main_min");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestMainMin(requestId);
  }

  function fulfillMainMin(bytes32 _requestId, uint256 _mainMin)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillMainMin(_requestId, _mainMin);
    games[game].mainMin = _mainMin;
  }

  function requestMainMax(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].mainMax == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillMainMax.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "main_max");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestMainMax(requestId);
  }

  function fulfillMainMax(bytes32 _requestId, uint256 _mainMax)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillMainMax(_requestId, _mainMax);
    games[game].mainMax = _mainMax;
  }

  function requestMainDrawn(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].mainDrawn == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillMainDrawn.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "main_drawn");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestMainDrawn(requestId);
  }

  function fulfillMainDrawn(bytes32 _requestId, uint256 _mainDrawn)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillMainDrawn(_requestId, _mainDrawn);
    games[game].mainDrawn = _mainDrawn;
  }

  function requestBonusMin(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].bonusMin == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillBonusMin.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "bonus_min");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestBonusMin(requestId);
  }

  function fulfillBonusMin(bytes32 _requestId, uint256 _bonusMin)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillBonusMin(_requestId, _bonusMin);
    games[game].bonusMin = _bonusMin;
  }

  function requestBonusMax(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].bonusMax == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillBonusMax.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "bonus_max");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestBonusMax(requestId);
  }

  function fulfillBonusMax(bytes32 _requestId, uint256 _bonusMax)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillBonusMax(_requestId, _bonusMax);
    games[game].bonusMax = _bonusMax;
  }

  function requestBonusDrawn(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].bonusDrawn == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillBonusDrawn.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "bonus_drawn");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestBonusDrawn(requestId);
  }

  function fulfillBonusDrawn(bytes32 _requestId, uint256 _bonusDrawn)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillBonusDrawn(_requestId, _bonusDrawn);
    games[game].bonusDrawn = _bonusDrawn;
  }

  function requestSameBalls(string calldata _apiKey, string calldata _game)
    public
  {
    Chainlink.Request memory req = buildChainlinkRequest(
      boolJobId,
      address(this),
      this.fulfillSameBalls.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "same_balls");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestSameBalls(requestId);
  }

  // Todo: need to handle save N to false;
  function fulfillSameBalls(bytes32 _requestId, bool _sameBalls)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillSameBalls(_requestId, _sameBalls);
    games[game].sameBalls = _sameBalls;
  }

  function requestDigits(string calldata _apiKey, string calldata _game)
    public
  {
    require(games[game].digits == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillDigits.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "digits");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestDigits(requestId);
  }

  function fulfillDigits(bytes32 _requestId, uint256 _digits)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillDigits(_requestId, _digits);
    games[game].digits = _digits;
  }

  function requestDrawn(string calldata _apiKey, string calldata _game) public {
    require(games[game].drawn == 0, "already-got-value");
    Chainlink.Request memory req = buildChainlinkRequest(
      uint256JobId,
      address(this),
      this.fulfillDrawn.selector
    );
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "drawn");
    bytes32 requestId = sendChainlinkRequestTo(
      oracleAddress,
      req,
      oraclePayment
    );
    emit RequestDrawn(requestId);
  }

  function fulfillDrawn(bytes32 _requestId, uint256 _drawn)
    external
    recordChainlinkFulfillment(_requestId)
  {
    emit FulfillDrawn(_requestId, _drawn);
    games[game].drawn = _drawn;
  }

  /*
  function requestIsOption(string calldata _apiKey, string calldata _game) public {
    Chainlink.Request memory req = buildChainlinkRequest(boolJobId, address(this), this.fulfillIsOption.selector);
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "is_option");
    bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, oraclePayment);
    emit RequestIsOption(requestId);
  }
 */

  /*
  function fulfillIsOption(bytes32 _requestId, bool _isOption) external recordChainlinkFulfillment(_requestId){
    emit FulfillIsOption(_requestId, _isOption);
    games[game].isOption = _isOption;
  }
 */

  /*
  function requestOptionDesc(string calldata _apiKey, string calldata _game) public {
    require(games[game].optionDesc == 0, "already-got-value" );
    Chainlink.Request memory req = buildChainlinkRequest(bytes32JobId, address(this), this.fulfillOptionDesc.selector);
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "option_desc");
    bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, oraclePayment);
    emit RequestOptionDesc(requestId);
  }
 */

  /*
  function fulfillOptionDesc(bytes32 _requestId, bytes16 _optionDesc) external recordChainlinkFulfillment(_requestId){
    emit FulfillOptionDesc(_requestId, _optionDesc);
    games[game].optionDesc = _optionDesc;
  }
 */

  /*
  function requestNextDraw(string calldata _apiKey, string calldata _game) public {
    require(games[game].nextDraw == 0, "already-got-value" );
    Chainlink.Request memory req = buildChainlinkRequest(bytes32JobId, address(this), this.fulfillNextDraw.selector);
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "next_draw");
    bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, oraclePayment);
    emit RequestNextDraw(requestId);
  }
 */

  /*
  function requestNextDraw(string calldata _apiKey, string calldata _game) public {
    require(games[game].nextDraw == 0, "already-got-value" );
    Chainlink.Request memory req = buildChainlinkRequest(bytes32JobId, address(this), this.fulfillNextDraw.selector);
    req.add(
      "get",
      string(
        abi.encodePacked(
          "https://www.magayo.com/api/info.php",
          "?api_key=",
          _apiKey,
          "&game=",
          _game
        )
      )
    );
    req.add("path", "next_draw");
    bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, oraclePayment);
    emit RequestNextDraw(requestId);
  }
 */

  /*
  function fulfillNextDraw(bytes32 _requestId, bytes32 _nextDraw) external recordChainlinkFulfillment(_requestId){
    emit FulfillNextDraw(_requestId, _nextDraw);
    string memory nextDraw = bytes32ToString(_nextDraw);
    games[game].nextDraw = dt.toTimestamp(nextDraw[:3], nextDraw[5:6], nextDraw[9:9]);
  }
 */

  function withdrawLink() external onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  ) external onlyOwner {
    cancelChainlinkRequest(
      _requestId,
      _payment,
      _callbackFunctionId,
      _expiration
    );
  }

  function stringToBytes32(string memory source)
    private
    pure
    returns (bytes32 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }

  function bytes32ToString(bytes32 _bytes32)
    internal
    pure
    returns (string memory)
  {
    bytes32 _temp;
    uint256 count;
    for (uint256 i; i < 32; i++) {
      _temp = _bytes32[i];
      if (_temp != bytes32(0)) {
        count += 1;
      }
    }
    bytes memory bytesArray = new bytes(count);
    for (uint256 i; i < count; i++) {
      bytesArray[i] = (_bytes32[i]);
    }
    return (string(bytesArray));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

pragma solidity ^0.6.0;

import { Buffer as Buffer_Chainlink } from "./Buffer.sol";

library CBOR {
  using Buffer_Chainlink for Buffer_Chainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  function encodeType(Buffer_Chainlink.buffer memory buf, uint8 major, uint value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(Buffer_Chainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(Buffer_Chainlink.buffer memory buf, uint value) internal pure {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(Buffer_Chainlink.buffer memory buf, int value) internal pure {
    if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(Buffer_Chainlink.buffer memory buf, bytes memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeString(Buffer_Chainlink.buffer memory buf, string memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(Buffer_Chainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(Buffer_Chainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(Buffer_Chainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

pragma solidity ^0.6.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(bytes memory b) internal pure returns(buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint a, uint b) private pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

pragma solidity ^0.6.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

pragma solidity ^0.6.0;

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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

pragma solidity ^0.6.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}

pragma solidity ^0.6.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion, // Currently unused, always "1"
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

pragma solidity ^0.6.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";
import { SafeMath as SafeMath_Chainlink } from "./vendor/SafeMath.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;
  using SafeMath_Chainlink for uint256;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param _specId The Job Specification ID that the request will be created for
   * @param _callbackAddress The callback address that the response will be sent to
   * @param _callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param _oracle The address of the oracle for the request
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param _requestId The request ID
   * @param _payment The amount of LINK sent for the request
   * @param _callbackFunc The callback function specified for the request
   * @param _expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param _oracle The address of the oracle contract
   */
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

  /**
   * @notice Sets the LINK token address
   * @param _link The address of the LINK token contract
   */
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param _oracle The address of the oracle contract that will fulfill the request
   * @param _requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param _ens The address of the ENS contract
   * @param _node The ENS node hash
   */
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Encodes the request to be sent to the oracle contract
   * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
   * will be validated in the oracle contract.
   * @param _req The initialized Chainlink Request
   * @return The bytes payload for the `transferAndCall` method
   */
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param _requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param _requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param _requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}

pragma solidity ^0.6.0;

import { CBOR as CBOR_Chainlink } from "./vendor/CBOR.sol";
import { Buffer as Buffer_Chainlink } from "./vendor/Buffer.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBOR_Chainlink for Buffer_Chainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    Buffer_Chainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param _id The Job Specification ID
   * @param _callbackAddress The callback address
   * @param _callbackFunction The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    Buffer_Chainlink.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param _data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    Buffer_Chainlink.init(self.buf, _data.length);
    Buffer_Chainlink.append(self.buf, _data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The string value to add
   */
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The bytes value to add
   */
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The int256 value to add
   */
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The uint256 value to add
   */
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _values The array of string values to add
   */
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}