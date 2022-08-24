// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;

import "./uniswap.sol";
import "./protected.sol";

// SECTION Contract BetContract
contract BetContract is protected {

    // ANCHOR Datatypes
    address public router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory_address;
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;

    address public weth_address = 0x0Bb7509324cE409F7bbC4b701f932eAca9736AB7; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public wbtc_address = 0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public usdc_address = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public eth_usd_address;
    address public btc_usd_address;
    IUniswapV2Pair public eth_usd;
    IUniswapV2Pair public btc_usd;

    ERC20 eth;
    ERC20 usdc;

    // NOTE Defining the contracts we will work with
    constructor() {
        router = IUniswapV2Router02(router_address);
        factory_address = router.factory();
        factory = IUniswapV2Factory(factory_address);
        eth_usd_address = factory.getPair(weth_address, usdc_address);
        btc_usd_address = factory.getPair(wbtc_address, usdc_address);
        eth_usd = IUniswapV2Pair(eth_usd_address);
        btc_usd = IUniswapV2Pair(btc_usd_address);
        eth = ERC20(weth_address);
        usdc = ERC20(usdc_address);
        owner = msg.sender;
        is_auth[owner] = true;
    }

    // NOTE Returns usdc per eth (6 decimals)
    function get_eth_usd_price() public view returns (uint) {
        (uint weth_res, uint usdc_res, uint timestamp) = eth_usd.getReserves();
        delete(timestamp);
        uint usdc_per_eth = usdc_res / weth_res;
        return usdc_per_eth;
    }

    // NOTE Returns usdc per btc (6 decimals)
    function get_btc_usd_price() public view returns (uint) {
        (uint wbtc_res, uint usdc_res, uint timestamp) = btc_usd.getReserves();
        delete(timestamp);
        uint usdc_per_btc = usdc_res / wbtc_res;
        return usdc_per_btc;
    }

    // SECTION Betting datatypes
    struct BET {
        bool bullish;
        uint value;
        uint timestamp;
        address actor;
    }

    // Bets are stored in a "iterable" mapping
    mapping(uint => BET) public all_bets;
    uint public all_bets_head;
    mapping(address => uint[]) bets;

    // Tracking bets on a block
    mapping(uint => mapping(address => bool)) public has_bet_in_round; 
    mapping(uint => mapping(address => uint)) public bet_in_round_per_address;
    mapping(address => mapping(uint => bool)) public sideOnRound;

    // Listing all bets in a block
    mapping(uint => uint[]) public bets_in_round; 
    mapping(uint => uint) public round_of_bet;
    // !SECTION Betting datatypes

    // SECTION Round datatypes
    // Rounds
    struct ROUND {
        // General properties
        uint qty;
        uint start_timestamp;
        uint end_timestamp;
        // Prices storage
        uint eth_price_at_start;
        uint btc_price_at_start;
        uint eth_price_at_end;
        uint btc_price_at_end;
        // Bets storage
        uint[] bets;
        mapping(bool => uint) side_jackpot;
        // Actors storage
        mapping(address => uint) already_used;
        mapping(address => uint) balances;
    }
    mapping(uint => ROUND) public rounds;
    uint public current_round;
    uint public min_bets_per_round = 2;
    uint public max_bets_per_round = 40;
    uint public max_round_time = 4 hours;

    // !SECTION Round datatypes

    // SECTION Actor datatypes
    mapping(address => uint[]) actor_bets;
    // !SECTION Actor datatypes

    // SECTION Fees
    uint public fee = 3;
    uint public eth_fee_balance;
    uint public usdc_fee_balance;
    // !SECTION Fees

    // SECTION Betting routine
    // NOTE Betting function is internal as depends on the call from the main token
    function bet_on_market(bool bullish, uint value) public payable safe {
        address from = msg.sender;
        require(!has_bet_in_round[block.timestamp][from], 
                "Already placed a bet in this block");

        // SECTION Betting prerequisites based on side
        // NOTE Balance of side token
        uint fee_value = (value * fee) / 100;
        uint original_value = value;
        value -= fee_value;
        if(bullish) {
            // NOTE Native tokens are already received
            value = msg.value;
            eth_fee_balance += fee_value;
        } else {
            // NOTE transferring needed usdc
            require(usdc.balanceOf(from) >= original_value, 
                    "Not enough balance to bet");
            usdc.transferFrom(from, address(this), original_value);
            usdc_fee_balance += fee_value;
        }
        // !SECTION Betting prerequisites based on side

        // NOTE The reason we copy the variable is to work on a local status (a single
        // SSREAD is cheaper than multiple SSREADs)
        all_bets_head += 1;
        uint this_id = all_bets_head;

        // SECTION Round operations
        // NOTE Checking on round
        // A round is over if is filled or if is expired (and minimum bets is reached)
        bool filled = rounds[current_round].qty >= max_bets_per_round;
        uint time_passed = block.timestamp - rounds[current_round].start_timestamp;
        bool min_reached = rounds[current_round].qty >= min_bets_per_round;
        bool expired = time_passed > max_round_time;
        // If the round is over, we create a new one
        if(filled || (min_reached && expired)) {
            rounds[current_round].end_timestamp = block.timestamp;
            // NOTE Price finalization
            rounds[current_round].eth_price_at_end = get_eth_usd_price();
            rounds[current_round].btc_price_at_end = get_btc_usd_price();
            current_round += 1;
        }
        // NOTE If we are using a blank round, we initialize it
        if(rounds[current_round].start_timestamp==0) {
            rounds[current_round].start_timestamp = block.timestamp;
            // NOTE Price initialization
            rounds[current_round].eth_price_at_start = get_eth_usd_price();
            rounds[current_round].btc_price_at_start = get_btc_usd_price();
        }
        // NOTE Inserting the bet into the round
        rounds[current_round].qty += 1;
        rounds[current_round].bets.push(this_id);
        // NOTE Increasing the jackpot
        rounds[current_round].side_jackpot[bullish] += value;
        rounds[current_round].balances[from] += value;
        // !SECTION Round operations

        // SECTION Bet definition
        // NOTE Setting the bet
        all_bets[this_id].bullish = bullish;
        all_bets[this_id].timestamp = block.timestamp;
        all_bets[this_id].value = value;
        all_bets[this_id].actor = from;
        // NOTE Updating the various control structures
        bets[from].push(this_id);
        has_bet_in_round[block.timestamp][from] = true;
        bet_in_round_per_address[block.timestamp][from] = this_id;
        bets_in_round[current_round].push(this_id);
        sideOnRound[from][this_id] = bullish;
        round_of_bet[this_id] = current_round;
        actor_bets[from].push(this_id);
        // !SECTION Bet definition
    }
    // !SECTION Betting routine

 // ANCHOR The calculation returns the *potential* winnings in case of victory
    function calculateTwinTokenShare(address refers_to, uint round_target) public view returns(uint) {
        bool bullish = sideOnRound[refers_to][round_target];
        // NOTE The accrued balance refers to the opposite side jackpot
        uint opposide_side_accrued_balance = getRoundJackpot(round_target, !bullish);
        // NOTE Taking the balance of this account in this specific round
        uint round_balance_of = getRoundBalance(round_target, refers_to);
        // A minimum is required to avoid dust distribution and relative underflows
        if(opposide_side_accrued_balance < 1000000) {
            return 0;
        }
        if(round_balance_of==0) {
            return 0;
        }

        // NOTE roundSupply is the total bet on our side
        uint roundSupply = getRoundJackpot(round_target, bullish);
    
        // NOTE For both the fractionals, we use 1 million to simulate floating precision
        uint millionthPartOfTwinBalance = opposide_side_accrued_balance/1000000;
        // NOTE Calculation of proportion refers to the partecipation in a round
        uint proportionOnCirculating = (round_balance_of*1000000)/roundSupply;

        uint rawShare = proportionOnCirculating * millionthPartOfTwinBalance;
        // NOTE The raw theoretical share is diminished by the already withdrawn of the round
        uint share = rawShare - alreadyUsed(round_target, refers_to);
        return share;
    }

    // SECTION Withdraw dued twin token balance from available one
    function withdrawTwinToken(uint round_) public safe {
        address refers_to = msg.sender;
        bool bullish = sideOnRound[refers_to][round_];
        // NOTE Available only for closed rounds
        require(round_ < getRound(), "Round does not exists or is not finished");
        // NOTE Require to be on the winning side
        require(getWinner(round_)==bullish, "You have not won this match");
        uint toWithdraw = calculateTwinTokenShare(msg.sender, round_);
        require(toWithdraw >= 0, "Nothing to withdraw");
        // SECTION Withdrawing the jackpot based on side
        if(bullish) {
            require(address(this).balance >= toWithdraw, "Not enough balance to withdraw");
            (bool success,) = refers_to.call{value: toWithdraw}("");
            require(success, "Call to withdraw failed");
        } else {
            require(usdc.balanceOf(address(this)) >= toWithdraw, "Funds not available?");
            usdc.transfer(msg.sender, toWithdraw);
        }
        // !SECTION Withdrawing the jackpot based on side
        // NOTE Adding to the already used amount for the round
        hasWithdrawn(msg.sender, round_, toWithdraw);
    }
    // !SECTION Withdraw dued twin token balance from available one

    // SECTION Fee withdrawal
    function get_eth_fees() public onlyAuth {
        if(!(address(this).balance >= eth_fee_balance)) {
            eth_fee_balance = address(this).balance;
        }
        (bool success,) = msg.sender.call{value: eth_fee_balance}("");
        eth_fee_balance = 0;
        require(success, "Call to withdraw failed");
    }

    function get_usdc_fees() public onlyAuth {
        if(!(usdc.balanceOf(address(this)) >= usdc_fee_balance)) {
            usdc_fee_balance = usdc.balanceOf(address(this));
        }
        usdc.transfer(msg.sender, usdc_fee_balance);
        usdc_fee_balance = 0;
    }
    // !SECTION Fee withdrawal

    function is_bet_open(uint id) public view returns (bool _open) {
        uint round_referring = round_of_bet[id];
        if (round_referring < current_round) {
            return false;
        } else {
            return true;
        }
    }

    // SECTION View Utilities
    function check_bet_status(uint id) public view returns (uint value,
                                                            bool side,
                                                            address actor,
                                                            uint round,
                                                            uint timestamp) {
        return(
            all_bets[id].value,
            all_bets[id].bullish,
            all_bets[id].actor,
            round_of_bet[id],
            all_bets[id].timestamp
        );
    }

    function getRouter() public view returns(IUniswapV2Router02 router_) {
        return router;
    }

    function getFactory() public view returns(IUniswapV2Factory factory_) {
        return factory;
    }

    function getRound() public view returns (uint round_) {
        return current_round;
    }

    function getRoundJackpot(uint b_number, bool bullish) 
                             public view returns (uint jackpot_) {
        return rounds[b_number].side_jackpot[bullish];
    }

    function getRoundBalance(uint b_number, address b_of) public view returns (uint bal) {
        return rounds[b_number].balances[b_of];
    }

    function alreadyUsed(uint round_target, address actor) public view returns (uint used) {
        return rounds[round_target].already_used[actor];
    }

    function getWinner(uint round) public view returns (bool winSide) {
        require(round < current_round, "Round is not finished yet");
        // If price at end is > than price at start, bulls win. Otherwise bears win.
        bool outcome = rounds[round].eth_price_at_end > rounds[round].eth_price_at_start;
        return outcome;
    }

    // NOTE Not yet used but usable
    function getWinnerBTC(uint round) public view returns (bool winSide) {
        require(round < current_round, "Round is not finished yet");
        // If price at end is > than price at start, bulls win. Otherwise bears win.
        bool outcome = rounds[round].btc_price_at_end > rounds[round].btc_price_at_start;
        return outcome;
    }

    function getActorBets(address actor) public view returns(uint[] memory ids) {
        return actor_bets[actor];
    }

    // !SECTION View Utilities

    // SECTION Write Utilities
    function hasWithdrawn(address target, uint round, uint value) internal {
        rounds[round].already_used[target] += value;
    }

    // !SECTION Write Utilities

}
// !SECTION Contract BetContract