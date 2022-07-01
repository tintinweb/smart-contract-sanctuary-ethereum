// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RoyalLibrary} from "./lib/RoyalLibrary.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";
import {IQueenPalace} from "../interfaces/IQueenPalace.sol";
import {BaseContractControllerUpgradeable} from "./base/BaseContractControllerUpgradeable.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract QueenAuctionHouse is
  IQueenAuctionHouse,
  BaseContractControllerUpgradeable
{
  using Address for address;

  string public constant implementationVersion = "0.10";
  // The minimum bid % raise over last successfull bid
  uint8 public bidRaiseRate;
  //minimum bid increment by queene rarity traits
  uint256[] rarityBidRaiseMap; //(rarityId-1 => %)
  // The minimum amount of time left in an auction after a new bid is created
  uint256 public timeTolerance;
  // The initial minimun bid of the auction
  uint256 public initialBid;
  //fallback funds
  uint256 public fallbackDaoFunds;
  // The duration of a single auction
  uint256 public duration;
  // The address of the WETH contract
  address public weth;
  // current auction
  RoyalLibrary.sAUCTION public currentAuction;

  /**
   * @notice Initialize the auction house and base contracts,
   * populate configuration values, and pause the contract.
   * @dev This function can only be called once.
   */
  function initialize(
    IQueenPalace _queenPalace,
    address _weth,
    uint256 _timeTolerance,
    uint256 _initialBid,
    uint8 _bidRaiseRate,
    uint256 _duration
  ) external initializer {
    if (!initialized) {
      __Pausable_init();
      __ReentrancyGuard_init();
      __Ownable_init();

      _registerInterface(type(IQueenAuctionHouse).interfaceId);

      _pause();

      queenPalace = _queenPalace;
      weth = _weth;

      timeTolerance = _timeTolerance;
      initialBid = _initialBid;
      bidRaiseRate = _bidRaiseRate;
      duration = _duration;

      rarityBidRaiseMap.push(0); //increment for rarityId 1
      rarityBidRaiseMap.push(5); //increment for rarityId 2
      rarityBidRaiseMap.push(10); //increment for rarityId 3

      initialized = true;
    }
  }

  function setWeth(address _weth)
    external
    onlyOwnerOrChiefDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    weth = _weth;
  }

  /**
   * @notice End the current auction, send value to contracts and QueenE to Winner.
   */
  function endAuction() external override nonReentrant {
    _endAuction();
  }

  /**
   * @notice End the current auction, send value to contracts and QueenE to Winner.
   */
  function settleAuction() external nonReentrant whenNotPaused {
    if (!currentAuction.ended) _endAuction();
    if (currentAuction.ended) _startAuction();
  }

  /**
   * @notice try to make bid for QueenE with giver value (WEI).
   * @dev This contract only accepts payment in ETH.
   */
  function bid(uint256 queeneId) external payable override {
    RoyalLibrary.sAUCTION memory _currentAuction = currentAuction;

    require(!_currentAuction.ended, "Current Auction Ended");
    require(_currentAuction.queeneId == queeneId, "QueenE is not for auction");
    require(
      block.timestamp < _currentAuction.auctionEndTime,
      "Auction expired"
    );

    require(
      msg.value >= _currentAuction.initialBidPrice,
      string(
        abi.encodePacked(
          "Must send at least initial Bid value ",
          Strings.toString(_currentAuction.initialBidPrice)
        )
      )
    );
    require(
      msg.value >=
        _currentAuction.lastBidAmount +
          ((_currentAuction.lastBidAmount * bidRaiseRate) / 100),
      "Bid must be at least bidRaiseRate percentage above last bid!"
      //string(abi.encodePacked('Bid must be at least ', Strings.toString(bidRaiseRate), ' above last bid!'))
    );
    require(
      queenPalace.isWhiteListed(msg.sender),
      "Address not allowed to bid"
    );

    address payable lastBidder = _currentAuction.bidder;

    // Refund the last bidder, if applicable
    if (lastBidder != address(0)) {
      _safeTransferETHWithFallback(lastBidder, _currentAuction.lastBidAmount);
    }

    currentAuction.lastBidAmount = msg.value;
    currentAuction.bidder = payable(msg.sender);

    // Extend the auction if the bid was received within `timeTolerance` of the auction end time
    bool extended = _currentAuction.auctionEndTime - block.timestamp <
      timeTolerance;
    if (extended) {
      currentAuction.auctionEndTime = currentAuction.auctionEndTime =
        block.timestamp +
        timeTolerance;
    }

    emit AuctionBid(currentAuction.queeneId, msg.sender, msg.value, extended);

    if (extended) {
      emit AuctionExtended(
        currentAuction.queeneId,
        currentAuction.auctionEndTime
      );
    }
  }

  /**
   * @notice Pause the Queens auction house.
   */
  function pause()
    external
    override(BaseContractControllerUpgradeable, IQueenAuctionHouse)
    onlyOwnerOrDeveloper
  {
    _pause();
  }

  /**
   * @notice Unpause the Queens auction house.
   */
  function unpause()
    external
    override(BaseContractControllerUpgradeable, IQueenAuctionHouse)
    onlyOwnerOrDeveloper
  {
    require(
      !queenPalace.isOnImplementation(),
      "Can't Unpause while implementing"
    );

    _unpause();

    if (currentAuction.auctionStartTime == 0 || currentAuction.ended) {
      _startAuction();
    }
  }

  /**
   * @notice Set the auction time tolerance for bid.
   * @dev Only callable by the owner.
   */
  function setTimeTolerance(uint256 _timeTolerance)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    timeTolerance = _timeTolerance;

    emit AuctionTimeToleranceUpdated(_timeTolerance);
  }

  /**
   * @notice Set the auction initial bid price.
   * @dev Only callable by the owner.
   */
  function setInitialBid(uint256 _initialBid)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    initialBid = _initialBid;

    emit AuctionInitialBidUpdated(_initialBid);
  }

  /**
   * @notice Set the auction next bid increment percentage.
   * @dev Only callable by the owner.
   */
  function setBidRaiseRate(uint8 _bidRaiseRate)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    bidRaiseRate = _bidRaiseRate;

    emit AuctionInitialBidUpdated(bidRaiseRate);
  }

  /**
   * @notice Set the auction duration time.
   * @dev Only callable by the owner.
   */
  function setDuration(uint256 _duration)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    duration = _duration;

    emit AuctionDurationUpdated(duration);
  }

  /**
   * @notice Start an new auction.
   */
  function _startAuction() internal {
    require(
      !queenPalace.isOnImplementation(),
      "Can't Start while implementing"
    );

    try queenPalace.QueenE().mint() returns (uint256 queeneId) {
      uint256 startTime = block.timestamp;
      //starts with 4h duration and scalates 1 hour till max duration
      uint256 endTime = startTime +
        LowerNumber(duration, (10800 + (queeneId * 3600)));

      uint256 rarityIncrement = queenPalace
        .QueenLab()
        .getQueenRarityBidIncrement(
          queenPalace.QueenE().getQueenE(queeneId).dna,
          rarityBidRaiseMap
        );

      currentAuction = RoyalLibrary.sAUCTION({
        queeneId: queeneId,
        lastBidAmount: 0,
        auctionStartTime: startTime,
        auctionEndTime: endTime,
        initialBidPrice: initialBid +
          (SafeMath.div(initialBid, 100) * rarityIncrement),
        bidder: payable(0),
        ended: false
      });

      emit AuctionStarted(queeneId, startTime, endTime);
    } catch Error(string memory err) {
      _pause();
      revert(err);
    }
  }

  /**
   * @notice Settle an auction, finalizing the bid and paying out to the owner.
   * @dev If there are no bids, the Noun is burned.
   */
  function _endAuction() internal {
    RoyalLibrary.sAUCTION memory _currentAuction = currentAuction;

    require(_currentAuction.auctionStartTime != 0, "Auction hasn't begun");
    require(!_currentAuction.ended, "Auction has already ended");
    require(
      block.timestamp >= _currentAuction.auctionEndTime,
      "Auction hasn't completed."
    );

    if (_currentAuction.bidder == address(0)) {
      queenPalace.QueenE().burn(_currentAuction.queeneId);
      currentAuction.ended = true;
    } else {
      queenPalace.QueenE().transferFrom(
        address(this),
        _currentAuction.bidder,
        _currentAuction.queeneId
      );

      //transfer funds
      uint256 daoFunds = _currentAuction.lastBidAmount;

      if (daoFunds > 0) _safeDepositToTreasure(daoFunds);

      currentAuction.ended = true;
    }

    emit AuctionEnded(
      _currentAuction.queeneId,
      _currentAuction.bidder,
      _currentAuction.lastBidAmount
    );
  }

  /**
   * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
   */
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (!_safeTransferETH(to, amount)) {
      IWETH(weth).deposit{value: amount}();
      IERC20(weth).transfer(to, amount);
    }
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
    return success;
  }

  function _safeDepositToTreasure(uint256 value)
    internal
    returns (bool success)
  {
    (success, ) = payable(queenPalace.RoyalTowerAddr()).call{
      value: value,
      gas: 80000
    }(
      abi.encodeWithSignature(
        "depositToDAOTreasure(uint256)",
        currentAuction.queeneId
      )
    );

    if (!success) fallbackDaoFunds += value;
  }

  /**
   * @notice withdraw fallback funds.
   */
  function withdrawFallbackFund() external nonReentrant {
    require(
      msg.sender == owner() || msg.sender == queenPalace.RoyalTowerAddr(),
      "Invalid Withdrawer"
    );
    (bool successTower, ) = payable(queenPalace.RoyalTowerAddr()).call{
      value: fallbackDaoFunds,
      gas: 80000
    }("");

    if (successTower) {
      emit WithdrawnFallbackFunds(
        queenPalace.RoyalTowerAddr(),
        fallbackDaoFunds
      );
      fallbackDaoFunds = 0;
    }
  }

  function LowerNumber(uint256 firstNumber, uint256 secondNumber)
    private
    pure
    returns (uint256)
  {
    return (firstNumber > secondNumber) ? secondNumber : firstNumber;
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

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        bytes artName;
        bytes uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artName;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        uint256 description; //index of the description
        string finalArt;
        sDNA[] dna;
        uint8 queenesGallery;
        uint8 sirAward;
    }

    struct sSIR {
        address sirAddress;
        uint256 queene;
    }

    struct sAUCTION {
        uint256 queeneId;
        uint256 lastBidAmount;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 initialBidPrice;
        address payable bidder;
        bool ended;
    }

    enum queeneRarity {
        COMMON,
        RARE,
        SUPER_RARE,
        LEGENDARY
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
    uint8 constant houseOfLords = 1;
    uint8 constant houseOfCommons = 2;
    uint8 constant houseOfBanned = 3;

    error InvalidAddressError(string _caller, string _msg, address _address);
    error AuthorizationError(string _caller, string _msg, address _address);
    error MinterLockedError(
        string _caller,
        string _msg,
        address _minterAddress
    );
    error StorageLockedError(
        string _caller,
        string _msg,
        address _storageAddress
    );
    error LabLockedError(string _caller, string _msg, address _labAddress);
    error InvalidParametersError(
        string _caller,
        string _msg,
        string _arg1,
        string _arg2,
        string _arg3
    );

    function concat(string memory self, string memory part2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, part2));
    }

    function stringEquals(string storage self, string memory b)
        public
        view
        returns (bool)
    {
        if (bytes(self).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(self)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    function extractRevertReason(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import {IBaseContractControllerUpgradeable} from "./IBaseContractControllerUpgradeable.sol";

interface IQueenAuctionHouse is IBaseContractControllerUpgradeable {
  event WithdrawnFallbackFunds(address withdrawer, uint256 amount);
  event AuctionSettled(
    uint256 indexed queeneId,
    address settler,
    uint256 amount
  );

  event AuctionStarted(
    uint256 indexed queeneId,
    uint256 startTime,
    uint256 endTime
  );

  event AuctionBid(
    uint256 indexed queeneId,
    address sender,
    uint256 value,
    bool extended
  );

  event AuctionExtended(uint256 indexed queeneId, uint256 endTime);

  event AuctionEnded(uint256 indexed queeneId, address winner, uint256 amount);

  event AuctionTimeToleranceUpdated(uint256 timeBuffer);

  event AuctionInitialBidUpdated(uint256 initialBid);

  event AuctionDurationUpdated(uint256 duration);

  event AuctionMinBidIncrementPercentageUpdated(
    uint256 minBidIncrementPercentage
  );

  function endAuction() external;

  function bid(uint256 queeneId) external payable;

  function pause() external;

  function unpause() external;

  function setTimeTolerance(uint256 _timeTolerance) external;

  function setBidRaiseRate(uint8 _bidRaiseRate) external;

  function setInitialBid(uint256 _initialBid) external;

  function setDuration(uint256 _duration) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.9;

import {IQueenLab} from "../interfaces/IQueenLab.sol";
import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenE} from "../interfaces/IQueenE.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";

interface IQueenPalace {
    function royalMuseum() external view returns (address);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function isArtist(address addr) external view returns (bool);

    function dao() external view returns (address);

    function daoExecutor() external view returns (address);

    function RoyalTowerAddr() external view returns (address);

    function developer() external view returns (address);

    function isDeveloper(address devAddr) external view returns (bool);

    function minter() external view returns (address);

    function QueenLab() external view returns (IQueenLab);

    function QueenTraits() external view returns (IQueenTraits);

    function QueenAuctionHouse() external view returns (IQueenAuctionHouse);

    function QueenE() external view returns (IQueenE);

    function whiteListed() external view returns (uint256);

    function isWhiteListed(address _addr) external view returns (bool);

    function QueenAuctionHouseProxyAddr() external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ERC165StorageUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IBaseContractControllerUpgradeable} from "../../interfaces/IBaseContractControllerUpgradeable.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract BaseContractControllerUpgradeable is
  ERC165StorageUpgradeable,
  IBaseContractControllerUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  IQueenPalace internal queenPalace;
  bool internal initialized;

  /************************** vCONTROLLER REGION *************************************************** */

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external virtual onlyOwner whenNotPaused {
    _pause();
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external virtual onlyOwner whenPaused {
    _unpause();
  }

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  function QueenPalace() public view returns (IQueenPalace) {
    return queenPalace;
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function setQueenPalace(IQueenPalace _queenPalace)
    external
    nonReentrant
    whenPaused
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    _setQueenPalace(_queenPalace);
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function _setQueenPalace(IQueenPalace _queenPalace) internal {
    queenPalace = _queenPalace;
  }

  /************************** ^vCONTROLLER REGION *************************************************** */

  /************************** vMODIFIERS REGION ***************************************************** */

  modifier onlyChiefArtist() {
    isChiefArtist();
    _;
  }
  modifier onlyArtist() {
    isArtist();
    _;
  }

  modifier onlyChiefDeveloper() {
    isChiefDeveloper();
    _;
  }

  modifier onlyDeveloper() {
    isDeveloper();
    _;
  }

  modifier onlyMinter() {
    isMinter();
    _;
  }

  modifier onlyActor() {
    isActor();
    _;
  }

  modifier onlyActorOrDAO() {
    isActorOrDAO();
    _;
  }

  modifier onlyOwnerOrChiefArtist() {
    isOwnerOrChiefArtist();
    _;
  }

  modifier onlyOwnerOrArtist() {
    isOwnerOrArtist();
    _;
  }

  modifier onlyOwnerOrChiefDeveloper() {
    isOwnerOrChiefDeveloper();
    _;
  }

  modifier onlyOwnerOrDeveloper() {
    isOwnerOrDeveloper();
    _;
  }
  modifier onlyOwnerOrChiefDeveloperOrDAO() {
    isOwnerOrChiefDeveloperOrDAO();
    _;
  }

  modifier onlyOwnerOrDeveloperOrDAO() {
    isOwnerOrDeveloperOrDAO();
    _;
  }

  modifier onlyOwnerOrChiefArtistOrDAO() {
    isOwnerOrChiefArtistOrDAO();
    _;
  }

  modifier onlyOwnerOrArtistOrDAO() {
    isOwnerOrArtistOrDAO();
    _;
  }
  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();
    _;
  }

  modifier onlyOwnerOrMinter() {
    isOwnerOrMinter();
    _;
  }

  modifier onlyOwnerOrAuctionHouse() {
    isOwnerOrAuctionHouse();
    _;
  }

  modifier onlyOwnerOrAuctionHouseProxy() {
    isOwnerOrAuctionHouseProxy();
    _;
  }

  modifier onlyOwnerOrQueenPalace() {
    isOwnerOrQueenPalace();
    _;
  }

  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();
    _;
  }

  modifier onlyOnImplementationOrPaused() {
    isOnImplementationOrPaused();
    _;
  }

  /************************** ^MODIFIERS REGION ***************************************************** */

  /**
   *IN
   *OUT
   *if given address is owner
   */
  function isOwner(address _address) external view override returns (bool) {
    return owner() == _address;
  }

  function isOwnerOrChiefArtistOrDAO() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == queenPalace.artist() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Artist, DAO"
    );
  }

  function isChiefArtist() internal view {
    require(msg.sender == queenPalace.artist(), "Not Chief Artist");
  }

  function isArtist() internal view {
    require(queenPalace.isArtist(msg.sender), "Not Artist");
  }

  function isChiefDeveloper() internal view {
    require(msg.sender == queenPalace.developer(), "Not Chief Dev");
  }

  function isDeveloper() internal view {
    require(queenPalace.isDeveloper(msg.sender), "Not Dev");
  }

  function isMinter() internal view {
    require(msg.sender == queenPalace.minter(), "Not Minter");
  }

  function isActor() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        queenPalace.isDeveloper(msg.sender),
      "Invalid Actor"
    );
  }

  function isActorOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        queenPalace.isDeveloper(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Invalid Actor, DAO"
    );
  }

  function isOwnerOrChiefArtist() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.artist(),
      "Not Owner, Chief Artist"
    );
  }

  function isOwnerOrArtist() internal view {
    require(
      msg.sender == owner() || queenPalace.isArtist(msg.sender),
      "Not Owner, Artist"
    );
  }

  function isOwnerOrChiefDeveloper() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.developer(),
      "Not Owner, Chief Developer"
    );
  }

  function isOwnerOrDeveloper() internal view {
    require(
      msg.sender == owner() || queenPalace.isDeveloper(msg.sender),
      "Not Owner, Developer"
    );
  }

  function isOwnerOrChiefDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == queenPalace.developer() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Chief Developer, DAO"
    );
  }

  function isOwnerOrDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isDeveloper(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Developer, DAO"
    );
  }

  function isOwnerOrArtistOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Artist, DAO"
    );
  }

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
      "Not Owner, DAO"
    );
  }

  function isOwnerOrMinter() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.minter(),
      "Not Owner, Minter"
    );
  }

  function isOwnerOrAuctionHouse() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == address(queenPalace.QueenAuctionHouse()),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrAuctionHouseProxy() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == address(queenPalace.QueenAuctionHouseProxyAddr()),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrQueenPalace() internal view {
    require(
      msg.sender == owner() || msg.sender == address(queenPalace),
      "Not Owner,Queen Palace"
    );
  }

  function isOnImplementationOrDAO() internal view {
    require(
      queenPalace.isOnImplementation() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not On Implementation sender not DAO"
    );
  }

  function isOnImplementationOrPaused() internal view {
    require(
      queenPalace.isOnImplementation() || paused(),
      "Not On Implementation,Paused"
    );
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

interface IBaseContractControllerUpgradeable is IERC165Upgradeable {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

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
interface IERC165Upgradeable {
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

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib//RoyalLibrary.sol";
import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenE} from "./IQueenE.sol";

interface IQueenLab is IRoyalContractBase {
    function buildDna(uint256 queeneId, bool isSir)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function produceBlueBlood(RoyalLibrary.sDNA[] memory dna)
        external
        view
        returns (RoyalLibrary.sBLOOD[] memory blood);

    function generateQueen(uint256 _queenId, bool isSir)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function getQueenRarity(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (RoyalLibrary.queeneRarity finalRarity);

    function getQueenRarityBidIncrement(
        RoyalLibrary.sDNA[] memory _dna,
        uint256[] calldata map
    ) external pure returns (uint256 value);

    function getQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (string memory rarityName);

    function constructTokenUri(
        RoyalLibrary.sQUEEN memory _queene,
        string memory _ipfsUri
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.9;

//import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";

interface IQueenTraits is IRoyalContractBase {
  event RarityCreated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );
  event RarityUpdated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );

  event TraitCreated(
    uint256 indexed traitId,
    string _traitName,
    uint8 _enabled
  );

  event TraitEnabled(uint256 indexed traitId, string _traitName);
  event TraitDisabled(uint256 indexed traitId, string _traitName);

  event ArtCreated(
    uint256 traitId,
    uint256 rarityId,
    bytes artName,
    bytes artUri
  );
  event ArtRemoved(uint256 traitId, uint256 rarityId, bytes artUri);

  function rarityPool() external view returns (uint256[] memory);

  function getRarityById(uint256 _rarityId)
    external
    view
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarityByName(string memory _rarityName)
    external
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarities(bool onlyWithArt, uint256 _traitId)
    external
    view
    returns (RoyalLibrary.sRARITY[] memory raritiesList);

  function getTrait(uint256 _id)
    external
    view
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraitByName(string memory _traitName)
    external
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraits(bool _onlyEnabled)
    external
    view
    returns (RoyalLibrary.sTRAIT[] memory _traits);

  function getDescriptionByIdx(uint256 _rarityId, uint256 _index)
    external
    view
    returns (bytes memory description);

  function getDescriptionsCount(uint256 _rarityId)
    external
    view
    returns (uint256);

  function getArtByUri(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) external returns (RoyalLibrary.sART memory art);

  function getArtCount(uint256 _traitId, uint256 _rarityId)
    external
    view
    returns (uint256 quantity);

  function getArt(
    uint256 _traitId,
    uint256 _rarityId,
    uint256 _artIdx
  ) external view returns (RoyalLibrary.sART memory art);

  function getArts(uint256 _traitId, uint256 _rarityId)
    external
    returns (RoyalLibrary.sART[] memory artsList);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenLab} from "./IQueenLab.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {IERC721} from "./IERC721.sol";

interface IQueenE is IRoyalContractBase, IERC721 {
    function _currentAuctionQueenE() external view returns (uint256);

    function contractURI() external view returns (string memory);

    function mint() external returns (uint256);

    function getQueenE(uint256 _queeneId)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function burn(uint256 queeneId) external;

    function lockMinter() external;

    function lockQueenTraitStorage() external;

    function lockQueenLab() external;

    function nominateSir(address _sir) external returns (bool);

    function getHouseSeats(uint8 _seatType) external view returns (uint256);

    function getHouseSeat(address addr) external view returns (uint256);

    function IsSir(address _address) external view returns (bool);

    function isSirReward(uint256 queeneId) external view returns (bool);

    function isMuseum(uint256 queeneId) external view returns (bool);

    function dnaMapped(uint256 dnaHash) external view returns (bool);

    function isHouseOfLordsFull() external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IRoyalContractBase is IERC165 {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
/// @title IERC721 Interface

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

// LICENSE
// IERC721.sol modifies OpenZeppelin's interface IERC721.sol to user our own ERC165 standard:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
//
// MODIFICATIONS:
// Its the latest `IERC721` interface from OpenZeppelin (v4.4.5) using our own ERC165 controller.

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IRoyalContractBase {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}