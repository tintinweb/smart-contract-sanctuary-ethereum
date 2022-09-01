/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
interface IRouter {
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }

    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    
    uint cooldown = 5 seconds;

    mapping(address => uint) cooldown_block;
    mapping(address => bool) cooldown_free;

    modifier cooled() {
        if(!cooldown_free[msg.sender]) { 
            require(cooldown_block[msg.sender] < block.timestamp);
            _;
            cooldown_block[msg.sender] = block.timestamp + cooldown;
        }
    }

    receive() external payable {}
    fallback() external payable {}
}

contract Ak22 is protected {

    event placed_bet(address actor, address token, uint value, uint option, uint timestamp, uint id);
    event won_bet(uint id, uint timestamp, uint jackpot, address actor);
    event won_bet_unpaid(uint id, uint timestamp, address actor, string message);
    event lost_bet(uint id, uint lost, uint timestamp, address actor);
    event draw_bet(uint id, uint timestamp, uint jackpot, address actor);
    event draw_bet_unpaid(uint id, uint timestamp, address actor, string message);

    struct bets {
        address actor;
        bool active;
        bool win;
        uint timestamp;
        uint value;
        uint option;
        address token;
        uint status;
    }

    address public constant Dead = 0x000000000000000000000000000000000000dEaD;


    mapping (uint => bets) bet;
    mapping (uint => bool) bet_value;
    mapping(address => mapping(uint => bool)) bet_value_token;
    mapping(address => bool) token_enabled;
    mapping(uint => uint) option_odds;
    bool all_tokens;

    uint last_id = 1;
    uint bets_treasury;

    uint bet_multiplier = 2;
    uint bet_tax = 3;
    uint infra_cost = 50;
    uint ref = 1;
    address devWallet;
    address play_token;
    address router_address;
    uint minimun_to_play = 150000000000000000;
    bool activate_validation = true;

    function enable_bet_value(uint value, bool booly) public onlyAuth {
        bet_value[value] = booly;
    }

    function enable_bet_value_token(uint value, bool booly, address token) public onlyAuth {
        bet_value_token[token][value] = booly;
    }

    function enable_option_odd(uint option, uint odd) public onlyAuth {
        option_odds[option] = odd;
    }

    function set_bet_multiplier(uint multiplier) public onlyAuth {
        bet_multiplier = multiplier;
    }

    function set_tax(uint tax) public onlyAuth {
        bet_tax = tax;
    }

    function set_infra_cost(uint cost) public onlyAuth {
        infra_cost = cost;
    }

    function set_ref(uint cost) public onlyAuth {
        ref = cost;
    }

    function set_dev_wallet(address _dev) public onlyAuth {
        devWallet = _dev;
    }

    function set_play_token(address _play_token) public onlyAuth {
        play_token = _play_token;
    }

    function set_router_address(address _router_address) public onlyAuth {
        router_address = _router_address;
    }

    function set_minimun_to_play(uint _minimun_to_play) public onlyAuth {
        minimun_to_play = _minimun_to_play;
    }

    function user_can_play(address user) public view returns (bool){
        uint balance = IERC20(play_token).balanceOf(user);
        if (balance == 0) {
        return false;
        }
        address WBNB = IRouter(router_address).WETH();
        address[] memory path = new address[](2);
        path[0] = play_token;
        path[1] = WBNB;
        uint amountOut = IRouter(router_address).getAmountsOut(balance, path)[1];
        return amountOut > minimun_to_play;
    }

    constructor(address d, address _router_address, address _play_token) {
        owner = msg.sender;
        is_auth[owner] = true;
        devWallet = d;
        router_address = _router_address;
        play_token = _play_token;
        // option_odds[1] = 150; // 1.5
        // option_odds[2] = 210; // 2.1
        // option_odds[3] = 800; // 8.0
        // option_odds[4] = 430; // 4.3
        // option_odds[5] = 280; // 2.8
        option_odds[6] = 200; // 2
        bet_value[50000000000000000] = true;
        bet_value[100000000000000000] = true;
        bet_value[200000000000000000] = true;
    }

    function place_bet(uint option) payable public safe {
        bool can_play = user_can_play(msg.sender);
        require(can_play, "User need funds to play");

        require(bet_value[msg.value], "Wrong value, thanks and bye bye");

        uint id = last_id;
        last_id += 1;


        uint divider = 100 * msg.value;
        uint divisor = 100 + bet_tax;
        uint bet_val = divider / divisor;


        bet[id].actor = msg.sender;
        bet[id].active = true;
        bet[id].timestamp = block.timestamp;
        bet[id].value = bet_val;
        bet[id].token = Dead;
        bet[id].option = option;
        uint taxed = (bet_val * bet_tax)/100;
        sendComissions(taxed);

        bets_treasury += bet_val - taxed;


        emit placed_bet(msg.sender, Dead, bet_val, option, block.timestamp, id);
    }

    function place_bet_token(address addy, uint qty, uint option) public safe {
        bool can_play = user_can_play(msg.sender);
        require(can_play, "User need funds to play");
        
        IERC20 tkn = IERC20(addy);
        require(bet_value_token[addy][qty], "Wrong value, thanks and bye bye");
        require(tkn.allowance(msg.sender, address(this)) >= qty, "Allowance needed");
        require(token_enabled[addy] || all_tokens, "Token not enabled");
        require(tkn.balanceOf(address(this)) >= (qty*2), "Payout not assured");
        tkn.transferFrom(msg.sender, address(this), qty);

        uint id = last_id;
        last_id += 1;

        uint bet_val = qty / ((100+bet_tax)/100);

        bet[id].actor = msg.sender;
        bet[id].active = true;
        bet[id].timestamp = block.timestamp;
        bet[id].value = qty;
        bet[id].token = addy;

        uint taxed = (bet_val * bet_tax)/100;
        sendComissions(taxed);

        bets_treasury += bet_val - taxed;

        emit placed_bet(msg.sender, addy, bet_val, option, block.timestamp, id);
    }

    function get_bet_status(uint id) public view returns(uint, uint, address, bool, address, uint) {
        return(
            bet[id].value,
            bet[id].timestamp,
            bet[id].actor,
            bet[id].active,
            bet[id].token,
            bet[id].status
        );
    }

    function sendComissions(uint taxed) internal {
      uint commissionAmount = (taxed * infra_cost)/100;

      (bool sendCommisionCb,) = devWallet.call{value: (commissionAmount)}("");
      require(sendCommisionCb, 'Sent commision failed');
    }

    function win(uint id) public onlyAuth {
        require(bet[id].active, "Nope");
        bet[id].active = false;
        bet[id].status = 1;

        uint256 jackpot = bet[id].value * option_odds[bet[id].option] / 100;

        (bool sent,) =bet[id].actor.call{value: (jackpot)}("");
        if (!sent) {
            emit won_bet_unpaid(id, block.timestamp, bet[id].actor, "withdraw failed");
        } else {
            emit won_bet(id, block.timestamp, jackpot, bet[id].actor);
        }
    }

    function draw(uint id) public onlyAuth {
        require(bet[id].active, "Nope");
        bet[id].active = false;
        bet[id].status = 3;

        uint256 jackpot = bet[id].value;

        (bool sent,) =bet[id].actor.call{value: (jackpot)}("");
        if (!sent) {
            emit draw_bet_unpaid(id, block.timestamp, bet[id].actor, "withdraw failed");
        } else {
            emit draw_bet(id, block.timestamp, jackpot, bet[id].actor);
        }
    }

    function lose(uint id) public onlyAuth {
        require(bet[id].active, "Nope");
        bet[id].active = false;
        bet[id].status = 2;
        emit lost_bet(id, bet[id].value, block.timestamp, bet[id].actor);
    }

    function unstuck_bnb() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function unstuck_tokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

}