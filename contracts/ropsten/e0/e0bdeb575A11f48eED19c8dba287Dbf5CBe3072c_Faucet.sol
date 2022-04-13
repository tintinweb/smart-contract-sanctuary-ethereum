/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Faucet is Ownable {

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
    }

    mapping(address => User) public users;
    uint256 public max_payout_cap = 6250000e6; //6.25M LYT ~~edit
    uint256 deposit_bracket_size = 1250000e6;   // 5% increase whale tax per 1.25M tokens(1% of total supply)... 10 below cuts it at 50% since 5 * 10
    uint256 deposit_bracket_max = 10;  // sustainability fee is (bracket * 5)
    uint256 payoutRate = 1;  // payout 1% per day
    uint256 CompoundTax = 5;  
    uint256 ExitTax = 10; 

    function calculateTransferTaxes(uint256 amount) internal returns (uint256 adjustedValue, uint256 taxAmount){
        uint256 transferTax = 15;   
        taxAmount= amount.mul(transferTax).div(100);
        adjustedValue= SafeMath.sub(amount, taxAmount);
    }

    function deposit(address _upline, uint256 _amount) external returns (uint256){

        address _addr = msg.sender;

        (uint256 realizedDeposit, uint256 taxAmount) = calculateTransferTaxes(_amount);
        uint256 _total_amount = realizedDeposit;

        _setUpline(_addr, _upline);


        //Transfer DRIP to the contract
        // require(
        // dripToken.transferFrom(
        //     _addr,
        //     address(dripVaultAddress),
        //     _amount
        // ),
        // "DRIP token transfer failed"
        // );
        /*
        User deposits 10;
        1 goes for tax, 9 are realized deposit
        */

        _deposit(_addr, _total_amount);

    }
    
    //@dev Deposit
    function _deposit(address _addr, uint256 _amount) internal {
        //Can't maintain upline referrals without this being set

        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        //stats
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = block.timestamp;


        //10% direct commission; only if net positive
        address _up = users[_addr].upline;
        if(_up != address(0) && isNetPositive(_up)) {
            uint256 _bonus = _amount / 10;

            //Log historical and add to deposits
            users[_up].direct_bonus += _bonus;
            users[_up].deposits += _bonus;
        }
    }

    //@dev Claim, transfer, and topoff
    function claim() public {
      address _addr = msg.sender;

      uint256 to_payout = _claim(_addr, true);

      // uint256 vaultBalance = dripToken.balanceOf(dripVaultAddress);
      // if (vaultBalance < to_payout) {
      //   uint256 differenceToMint = to_payout.sub(vaultBalance);
      //   tokenMint.mint(dripVaultAddress, differenceToMint);
      // }

      // dripVault.withdraw(to_payout);

      // uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100); // 10% tax on withdraw
      // require(dripToken.transfer(address(msg.sender), realizedPayout));
    }


    //@dev Claim and deposit;
    function roll() public {
      address _addr = msg.sender; 

      uint256 to_payout = _claim(_addr, false);

      uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding

      //Recycle baby!
      _deposit(_addr, payout_taxed);

      //track rolls for net positive
      users[_addr].rolls += payout_taxed;

    }

    //@dev Claim current payouts
    function _claim(address _addr, bool isClaimedOut) internal returns (uint256) { //~~edit make it internal
      (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
      require(users[_addr].payouts < _max_payout, "Full payouts");

      // Deposit payout
      if(_to_payout > 0) {

        // payout remaining allowable divs if exceeds
        if(users[_addr].payouts + _to_payout > _max_payout) {
          _to_payout = _max_payout.safeSub(users[_addr].payouts);
        }

        users[_addr].payouts += _gross_payout;
        //users[_addr].payouts += _to_payout;  //consider sustainability fee

        if (!isClaimedOut){ // ~~edit when compound
          //Payout referrals
          //uint256 compoundTaxedPayout = _to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
          // _refPayout(_addr, compoundTaxedPayout); 
        }
      }

      require(_to_payout > 0, "Zero payout");

      //Update time!
      users[_addr].deposit_time = block.timestamp;

      return _to_payout;
    }


    function _setUpline(address _addr, address _upline) internal {
      /*
      1) User must not have existing up-line
      2) Up-line argument must not be equal to senders own address
      3) Senders address must not be equal to the owner
      4) Up-lined user must have a existing deposit
      */
      if(users[_addr].upline == address(0) && _upline != _addr ) {
        users[_addr].upline = _upline;
        users[_upline].referrals++;
      }
    }
    //@dev Returns true if the address is net positive
    function isNetPositive(address _addr) public view returns (bool) {

        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

        return _credits > _debits;

    }

    //@dev Returns the total credits and debits for a given address
    function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
        User memory _user = users[_addr];

        _credits = _user.rolls + _user.deposits;
        _debits = _user.payouts;
    }

    //@dev Maxpayout of 3.65 of deposit
    function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
      return _amount * 365 / 100;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {
      //The max_payout is capped so that we can also cap available rewards daily
      max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

      //This can  be 0 - 50 in increments of 5% @bb Whale tax bracket calcs here
      uint256 _fee = sustainabilityFee(_addr);
      uint256 share;

      // @BB: No need for negative fee

      if(users[_addr].payouts < max_payout) {
        //Using 1e18 we capture all significant digits when calculating available divs
        share = users[_addr].deposits.mul(payoutRate * 1e18).div(100e18).div(24 hours); //divide the profit by payout rate and seconds in the day
        payout = share * block.timestamp.safeSub(users[_addr].deposit_time);

        // payout remaining allowable divs if exceeds
        if(users[_addr].payouts + payout > max_payout) {
          payout = max_payout.safeSub(users[_addr].payouts);
        }

        sustainability_fee = payout * _fee / 100;

        net_payout = payout.safeSub(sustainability_fee);
      }
    }

    //@dev Returns the realized sustainability fee of the supplied address
    function sustainabilityFee(address _addr) public view returns (uint256) {
      uint256 _bracket = users[_addr].deposits.div(deposit_bracket_size);
      _bracket = SafeMath.min(_bracket, deposit_bracket_max);
      return _bracket * 5;
    }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /* @dev Subtracts two numbers, else returns zero */
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b > a) {
      return 0;
    } else {
      return a - b;
    }
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}