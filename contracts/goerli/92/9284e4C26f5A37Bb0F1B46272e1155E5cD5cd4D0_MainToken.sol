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

import "./IListingOwner.sol";
import "./Models.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// listing contract is effectively an IERC20 token swap contract, 
// with both parties required to trust it, 
// by already preapproving it as a spender for the corresponding amount
contract ListingContract {
  address public creator;
  uint256 public listingId;
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
      listingAddr: address(this),
      player1: player1,
      token1: token1,
      token1Amt: token1Amt,
      player2: player2,
      token2: token2,
      token2Amt: token2Amt,
      fulfilled: fulfilled
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
    address listingAddr;
    address player1;
    address token1;
    uint256 token1Amt;
    address player2;
    address token2;
    uint256 token2Amt;

    bool fulfilled;
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