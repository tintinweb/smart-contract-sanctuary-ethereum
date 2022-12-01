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

// File: contracts\IBettingPair.sol


pragma solidity ^0.8.13;

interface IBettingPair {
    enum CHOICE { WIN, DRAW, LOSE }
    enum BETSTATUS { BETTING, REVIEWING, CLAIMING }
    enum TOKENTYPE { ETH, WCI }

    function setBetData(
        address[] memory _account,
        uint256[] memory _playerWin, uint256[] memory _playerDraw, uint256[] memory _playerLose,
        uint256[] memory _playerWinWci, uint256[] memory _playerDrawWci, uint256[] memory _playerLoseWci,
        uint256[] memory _betHistoryWin, uint256[] memory _betHistoryDraw, uint256[] memory _betHistoryLose,
        uint256[] memory _betHistoryWinWci, uint256[] memory _betHistoryDrawWci, uint256[] memory _betHistoryLoseWci,
        uint256[] memory _claimHistory, uint256[] memory _claimHistoryWci,
        uint256 _totalBet, uint256 _totalBetWci,
        uint256 _totalBetWin, uint256 _totalBetDraw, uint256 _totalBetLose,
        uint256 _totalBetWinWci, uint256 _totalBetDrawWci, uint256 _totalBetLoseWci,
        BETSTATUS _status,
        CHOICE _result
    ) external;

    function bet(address, uint256, CHOICE, TOKENTYPE) external;
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

    constructor() {}

    /*
    * @Functions to recover the past bets
    */
    function setBetData(
        address[] calldata _account,
        uint256[] calldata _playerWin, uint256[] calldata _playerDraw, uint256[] calldata _playerLose,
        uint256[] calldata _playerWinWci, uint256[] calldata _playerDrawWci, uint256[] calldata _playerLoseWci,
        uint256[] calldata _betHistoryWin, uint256[] calldata _betHistoryDraw, uint256[] calldata _betHistoryLose,
        uint256[] calldata _betHistoryWinWci, uint256[] calldata _betHistoryDrawWci, uint256[] calldata _betHistoryLoseWci,
        uint256[] calldata _claimHistory, uint256[] calldata _claimHistoryWci,
        uint256 _totalBet, uint256 _totalBetWci,
        uint256 _totalBetWin, uint256 _totalBetDraw, uint256 _totalBetLose,
        uint256 _totalBetWinWci, uint256 _totalBetDrawWci, uint256 _totalBetLoseWci,
        BETSTATUS _status,
        CHOICE _result
    ) external override onlyOwner {
        for (uint256 i=0; i<_account.length; i++) {
            players[_account[i]][TOKENTYPE.ETH][CHOICE.WIN] = _playerWin[i];
            players[_account[i]][TOKENTYPE.ETH][CHOICE.DRAW] = _playerDraw[i];
            players[_account[i]][TOKENTYPE.ETH][CHOICE.LOSE] = _playerLose[i];
            players[_account[i]][TOKENTYPE.WCI][CHOICE.WIN] = _playerWinWci[i];
            players[_account[i]][TOKENTYPE.WCI][CHOICE.DRAW] = _playerDrawWci[i];
            players[_account[i]][TOKENTYPE.WCI][CHOICE.LOSE] = _playerLoseWci[i];

            betHistory[_account[i]][TOKENTYPE.ETH][CHOICE.WIN] = _betHistoryWin[i];
            betHistory[_account[i]][TOKENTYPE.ETH][CHOICE.DRAW] = _betHistoryDraw[i];
            betHistory[_account[i]][TOKENTYPE.ETH][CHOICE.LOSE] = _betHistoryLose[i];
            betHistory[_account[i]][TOKENTYPE.WCI][CHOICE.WIN] = _betHistoryWinWci[i];
            betHistory[_account[i]][TOKENTYPE.WCI][CHOICE.DRAW] = _betHistoryDrawWci[i];
            betHistory[_account[i]][TOKENTYPE.WCI][CHOICE.LOSE] = _betHistoryLoseWci[i];

            claimHistory[_account[i]][TOKENTYPE.ETH] = _claimHistory[i];
            claimHistory[_account[i]][TOKENTYPE.WCI] = _claimHistoryWci[i];

            totalBet[TOKENTYPE.ETH] = _totalBet;
            totalBet[TOKENTYPE.WCI] = _totalBetWci;

            totalBetPerChoice[TOKENTYPE.ETH][CHOICE.WIN] = _totalBetWin;
            totalBetPerChoice[TOKENTYPE.ETH][CHOICE.DRAW] = _totalBetDraw;
            totalBetPerChoice[TOKENTYPE.ETH][CHOICE.LOSE] = _totalBetLose;
            totalBetPerChoice[TOKENTYPE.WCI][CHOICE.WIN] = _totalBetWinWci;
            totalBetPerChoice[TOKENTYPE.WCI][CHOICE.DRAW] = _totalBetDrawWci;
            totalBetPerChoice[TOKENTYPE.WCI][CHOICE.LOSE] = _totalBetLoseWci;

            betStatus = _status;
            betResult = _result;
        }
    }

    /*
    * @Function to bet (Main function).
    * @params:
    *   _player: user wallet address
    *   _amount: bet amount
    *   _choice: bet choice (3 choices - First team wins, draws and loses)
    *   _token: Users can bet using ETH or WCI
    */
    function bet(address _player, uint256 _amount, CHOICE _choice, TOKENTYPE _token)
        external
        override
        onlyOwner 
    {
        require(betStatus == BETSTATUS.BETTING, "You can not bet at this time.");
        totalBet[_token] += _amount;
        totalBetPerChoice[_token][_choice] += _amount;
        players[_player][_token][_choice] += _amount;
        betHistory[_player][_token][_choice] += _amount;
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
        uint256[] memory res = new uint256[](2);

        uint256 userBal = players[_player][_token][_choice];

        // If there are no opponent bets, the player will claim his original bet amount.
        if (totalBetPerChoice[_token][CHOICE.WIN] == totalBet[_token] && players[_player][_token][CHOICE.WIN] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.WIN];
            return res;
        } else if (totalBetPerChoice[_token][CHOICE.DRAW] == totalBet[_token] && players[_player][_token][CHOICE.DRAW] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.DRAW];
            return res;
        } else if (totalBetPerChoice[_token][CHOICE.LOSE] == totalBet[_token] && players[_player][_token][CHOICE.LOSE] > 0) {
            res[0] = betHistory[_player][_token][CHOICE.LOSE];
            return res;
        } else if (totalBetPerChoice[_token][_choice] == 0) {
            return res;
        }

        uint256 _wciTokenBal = wciToken.balanceOf(_player);

        // If the token is ETH, the player will take 5% tax if he holds enough WCI token. Otherwise he will take 10% tax.
        if (_token == TOKENTYPE.ETH) {
            if (_wciTokenBal >= wciTokenThreshold) {
                res[0] = userBal + userBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).mul(19).div(20).div(totalBetPerChoice[_token][_choice]);
                res[1] = userBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).div(20).div(totalBetPerChoice[_token][_choice]);
            } else {
                res[0] = userBal + userBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).mul(9).div(10).div(totalBetPerChoice[_token][_choice]);
                res[1] = userBal.mul(totalBet[_token]-totalBetPerChoice[_token][_choice]).div(10).div(totalBetPerChoice[_token][_choice]);
            }
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
                return 980;
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

// File: contracts\BettingRouter.sol


pragma solidity ^0.8.13;
contract BettingRouter is Ownable {
    using SafeMath for uint256;

    mapping (uint256 => address) pairs; // All pair contract addresses
    uint256 matchId;
    address taxCollectorAddress = 0xC9dc42525637a96Ac978C81e35f059201c5039c8;        // Tax collector address
    uint256 totalClaimEth;
    uint256 totalClaimWci;
    uint256 totalWinnerCountEth;
    uint256 totalWinnerCountWci;
    uint256 wciTax = 2;

    IERC20 wciToken = IERC20(0xC5a9BC46A7dbe1c6dE493E84A18f02E70E2c5A32);

    constructor() {}

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
    function betEther(uint256 _pairId, IBettingPair.CHOICE _choice) external payable
        onlyValidPair(_pairId)
        betConditions(msg.value, IBettingPair.TOKENTYPE.ETH)
    {
        IBettingPair(pairs[_pairId]).bet(msg.sender, msg.value, _choice, IBettingPair.TOKENTYPE.ETH);
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
        IBettingPair(pairs[_pairId]).bet(msg.sender, _betAmount.mul(100-wciTax).div(100), _choice, IBettingPair.TOKENTYPE.WCI);
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
    function withdrawPFromRouter(uint256 _amount, IBettingPair.TOKENTYPE _token) external onlyOwner {
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
            res[i] = uint256(IBettingPair(pairs[i]).getBetStatus());
            res[matchId + i] = uint256(IBettingPair(pairs[i]).getBetResult());
            res[matchId*2 + i] = IBettingPair(pairs[i]).getPlayerClaimHistory(_player, _token);
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
    function getBetStatsData() external view returns (uint256, uint256, uint256, uint256) {
        return (totalClaimEth, totalWinnerCountEth, totalClaimWci, totalWinnerCountWci);
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
    function getWciTokenThreshold() external view returns (uint256) {
        if (matchId == 0) return 50000 * 10**9;
        else return IBettingPair(pairs[0]).getWciTokenThreshold();
    }

    /*
    * @Function to get WCI token tax amount.
    */
    function getWciTax() external view returns (uint256) {
        return wciTax;
    }

    /*
    * @Function to set WCI token tax amount.
    */
    function setWciTax(uint256 tax) external onlyOwner {
        require(tax >= 0 && tax < 100, "Tax should be between 0 and 100");
        wciTax = tax;
    }

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
    * @Function to deposit ETH.
    */
    function depositEth() external payable {
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01");
    }

    /*
    * @Function to deposit WCI
    */
    function depositWci(uint256 amount) external onlyOwner {
        require(amount >= 1000 * 10 ** 9, "Minimum deposit WCI amount is 1000");
        wciToken.transferFrom(msg.sender, address(this), amount);
    }

    /*
    * @Function to initiate the bets
    */
    function initiateBets(
        uint256 _pairId,
        address[] calldata _account,
        uint256[] calldata _playerWin, uint256[] calldata _playerDraw, uint256[] calldata _playerLose,
        uint256[] calldata _playerWinWci, uint256[] calldata _playerDrawWci, uint256[] calldata _playerLoseWci,
        uint256[] calldata _betHistoryWin, uint256[] calldata _betHistoryDraw, uint256[] calldata _betHistoryLose,
        uint256[] calldata _betHistoryWinWci, uint256[] calldata _betHistoryDrawWci, uint256[] calldata _betHistoryLoseWci,
        uint256[] calldata _claimHistory, uint256[] calldata _claimHistoryWci,
        uint256 _totalBet, uint256 _totalBetWci,
        uint256 _totalBetWin, uint256 _totalBetDraw, uint256 _totalBetLose,
        uint256 _totalBetWinWci, uint256 _totalBetDrawWci, uint256 _totalBetLoseWci,
        IBettingPair.BETSTATUS _status,
        IBettingPair.CHOICE _result
    ) external onlyValidPair(_pairId) onlyOwner {
        IBettingPair(pairs[_pairId]).setBetData(
            _account,
            _playerWin, _playerDraw, _playerLose,
            _playerWinWci, _playerDrawWci, _playerLoseWci,
            _betHistoryWin, _betHistoryDraw, _betHistoryLose,
            _betHistoryWinWci, _betHistoryDrawWci, _betHistoryLoseWci,
            _claimHistory, _claimHistoryWci,
            _totalBet, _totalBetWci,
            _totalBetWin, _totalBetDraw, _totalBetLose,
            _totalBetWinWci, _totalBetDrawWci, _totalBetLoseWci,
            _status,
            _result
        );
    }
}