// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
!!! EARLY PRIVATE ALPHA RELEASE; UNAUDITED; LIMITED TEST CASES WRITTEN; DEPOSIT LIMITS ENFORCED; USE AT YOUR OWN RISK !!!

Bookie Contract for the PvPbet telegram bot. Very bare-bones implementation.
TLDR: This contract allows users to bet against each other on the outcome of a future event.
Depositing money into this contract allows the bookie to make bets on your behalf, so you don't have to sign every bet transaction.
Bets are settled by the bookie, and the winner is paid out automatically.

Trust assumptions:
- The bookie could simply make virtually certain bets against every user, effectively stealing all deposited user funds.
- Bets are settled by the bookie, and the settlement logic is off-chain. The bookie could settle bets in a way that is not in accordance with the terms of the bet.

Mitigations:
- 
- theoretically, the bookie has no interest in the average bet outcome, and has no incentive to incorrectly settle bets.
- if the off-chain settlement engine stops for any reason, bets will expire and users can permissionlessly recall the funds
- 

*/

contract Bookie {
    struct Bet {
        address over;
        address under;
        string symbol;
        uint256 amount;
        uint256 price;
        uint256 exp_blockheight;
        bool active;
    }

    // only bookie role can create/invalidate bets.
    // if bookie role is compromised, presumably the attacker will make virtually certain bets against every user.
    // in this case, so long as the "owner" role remains uncompromised, the bookie role can be changed to a new address,
    // and all the newly created hostile bets can be invalidated, if the attack is detected in BLOCK_SAFETY_MARGIN - 1 blocks.
    address public owner;
    address public current_bookie;
    uint256 public max_bet_size = 1000000000000000000; // 1 ETH
    uint256 public max_account_balance = 1000000000000000000; // 1 ETH

    uint256 public constant BLOCK_SAFETY_MARGIN = 50; // can't make bets that expire within this many blocks (~10 mins)
    uint256 public constant INVALIDATION_WINDOW = 50; // users can reclaim bets that failed to settle after this many blocks
    uint256 public constant RAKE_PERCENTAGE = 2; // 2% rake on the sum total notional value, in ETH, of the wager
    uint256 public constant PERCENTAGE_BASIS = 100;
    uint256 public constant RELEASE_VERSION = 0;

    mapping(address => uint256) private spendable_balance;
    mapping(address => uint256) private locked_balance;
    mapping(uint256 => Bet) private bets;
    uint256 public bet_count;

    //// EVENTS ////
    event Deposit(address indexed _from, uint256 _value);
    event Withdrawal(address indexed _to, uint256 _value);
    event BetMade(
        uint256 _bet_id,
        address indexed _over,
        address indexed _under,
        string _sym,
        uint256 _amt,
        uint256 _price,
        uint256 _exp
    );
    event BetSettled(uint256 indexed _bet_id, bool _over_wins);
    event BetInvalidated(uint256 indexed _bet_id, bool _from_public);

    //// ACCESS CONTROL ////
    constructor() {
        owner = msg.sender;
        current_bookie = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    modifier onlyBookie() {
        require(msg.sender == current_bookie, "Not bookie");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == current_bookie || msg.sender == owner);
        _;
    }

    function changeCurrentBookie(address _newBookie) public onlyOwner {
        current_bookie = _newBookie;
    }

    function changeMaxBetSize(uint256 _newMaxBetSize) public onlyBookie {
        max_bet_size = _newMaxBetSize;
    }

    //// GETTER FUNCTIONS ////
    function getSpendableBalance(address account) public view returns (uint256) {
        return spendable_balance[account];
    }

    function getLockedBalance(address account) public view returns (uint256) {
        return locked_balance[account];
    }

    function getBet(uint256 index) public view returns (Bet memory bet) {
        return bets[index];
    }


    //// DEPOSITS AND WITHDRAWALS ////
    function deposit() public payable {
        require(spendable_balance[msg.sender] + msg.value <= max_account_balance, "Deposited too much");
        require(msg.value > 0, "requires positive value");
        spendable_balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function depositTo(address _to) public payable {
        require(spendable_balance[_to] + msg.value <= max_account_balance, "Deposited too much");
        require(msg.value > 0, "requires positive value");
        spendable_balance[_to] += msg.value;
        emit Deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(spendable_balance[msg.sender] >= amount, "Insufficient balance");

        spendable_balance[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawal(msg.sender, amount);
    }


    //// BET CREATION ////
    function makeBet(address _over, address _under, string calldata _sym, uint256 _amt, uint256 _price, uint256 _exp)
        public
        onlyBookie
    {
        require(block.number + BLOCK_SAFETY_MARGIN <= _exp, "bet expiration too soon");
        require(spendable_balance[_over] >= _amt, "over bettor has insufficient balance");
        require(spendable_balance[_under] >= _amt, "under bettor has insufficient balance");
        require(_amt <= max_bet_size, "bet size too large");
        require(_amt > 0, "bet size must be positive");

        spendable_balance[_over] -= _amt;
        spendable_balance[_under] -= _amt;
        locked_balance[_over] += _amt;
        locked_balance[_under] += _amt;

        Bet memory new_bet = Bet({
            over: _over,
            under: _under,
            symbol: _sym,
            amount: _amt,
            price: _price,
            exp_blockheight: _exp,
            active: true
        });

        uint256 new_bet_id = bet_count++;
        bets[new_bet_id] = new_bet;
        emit BetMade(new_bet_id, _over, _under, _sym, _amt, _price, _exp);
    }

    //// BET SETTLEMENT ////
    function settleBet(uint256 bet_id, bool over_wins) public onlyBookie {
        Bet storage bet = bets[bet_id];
        require(block.number >= bet.exp_blockheight, "cannot settle bet before expiration");
        require(bet.active, "bet has already been settled or invalidated");
        locked_balance[bet.over] -= bet.amount;
        locked_balance[bet.under] -= bet.amount;

        // rake is applied to the sum of the payout, not the one-sided bet amount, hence *2
        uint256 rake_amount = (RAKE_PERCENTAGE * 2 * bet.amount) / PERCENTAGE_BASIS;
        uint256 win_amount = (bet.amount * 2) - rake_amount;
        if (over_wins) {
            spendable_balance[bet.over] += win_amount;
        } else {
            spendable_balance[bet.under] += win_amount;
        }
        spendable_balance[owner] += rake_amount;
        bets[bet_id].active = false;
        emit BetSettled(bet_id, over_wins);
    }

    // if the bet is not settled after INVALIDATION_WINDOW blocks, anyone can invalidate it.
    function invalidateStaleBet(uint256 bet_id) public {
        Bet storage bet = bets[bet_id];
        require(block.number >= bet.exp_blockheight + INVALIDATION_WINDOW, "bet is still within bookie control window");
        require(bet.active, "cannot invalidate inactive bet");

        spendable_balance[bet.over] += bet.amount;
        spendable_balance[bet.under] += bet.amount;
        locked_balance[bet.over] -= bet.amount;
        locked_balance[bet.under] -= bet.amount;
        bets[bet_id].active = false;
        emit BetInvalidated(bet_id, true);
    }
   
    /*
     failsafe mechanism lets bookie or owner return funds to user
     if bookie is compromised, makes certain bets against user,
     then if owner detects breach in time, can invalidate bets and return funds.
     .. if this simply returned funds to available balance, would actually be a far worse
     .. vulnerability since the compromised bookie could also steal funds locked in bets
     */
    function bookieInvalidateBet(uint256 bet_id) public onlyAdmin {
        Bet storage bet = bets[bet_id];
        require(bet.active, "cannot invalidate inactive bet");

        // reduce contract balance by the amount of the bet for each user
        locked_balance[bet.over] -= bet.amount;
        locked_balance[bet.under] -= bet.amount;

        // send contract balance directly back to EOA, NOT back to available balance
        // since an a
        (bool _over_withdraw_success,) = payable(bet.over).call{value: bet.amount}("");
        require(_over_withdraw_success, "Transfer out to over bettor failed");
        (bool _under_withdraw_success,) = payable(bet.under).call{value: bet.amount}("");
        require(_under_withdraw_success, "Transfer out to under bettor failed");

        bets[bet_id].active = false;
        emit Withdrawal(bet.over, bet.amount);
        emit Withdrawal(bet.under, bet.amount);
        emit BetInvalidated(bet_id, false);
    }

}