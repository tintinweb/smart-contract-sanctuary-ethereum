/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StakeContract {

    string public name;
    
    // create 2 state variables
    address public FarmToken;

    uint reward_rate;

    struct farm_slot {
        bool active;
        uint balance;
        uint deposit_time;
        uint locked_time;
        uint index;
        address token;
    }

    struct farm_pool {
        mapping(uint => uint) lock_multiplier;
        mapping(address => uint) is_farming;
        mapping(address => bool) has_farmed;
        uint total_balance;
    }

    struct time_pool {
        bool enabled;
        bool check_balance;
        uint percentage_to_check;
        uint multiplier;
    }

    address public owner;

    address[] public farms;
    uint[] public times;

    mapping(address => mapping(uint => farm_slot)) public farming_unit;
    mapping(address => uint[]) farmer_pools;
    mapping(address => farm_pool) public token_pool;
    mapping(address => uint) farm_id;
    mapping(address => bool) public is_farmable;
    mapping(address => uint) public last_tx;
    mapping(address => mapping(uint => uint)) public lock_multiplier;
    mapping(uint => time_pool) time_allowed;

    mapping(address => bool) public is_auth;

    uint256 cooldown_time = 10 seconds;

    bool is_fixed_locking = true;
    bool early_withdraw_available = true;
    uint early_withdraw_percentage_comission = 100;

    IERC20 token_reward;

    constructor(string memory _name, address _businessOwner, address _token) {
        name = _name;
        owner = _businessOwner;
        FarmToken = _token;
        is_farmable[FarmToken] = true; // CHANGE ON MAINNET
        is_auth[msg.sender] = true;

        set_multiplier(86400 * 5, 100);
        set_multiplier(86400 * 10, 250);
        set_multiplier(86400 * 15, 300);

        set_time_allowed(86400 * 5, true, false, 100);
        set_time_allowed(86400 * 10, true, false, 250);
        set_time_allowed(86400 * 15, true, false, 400);

        token_reward = IERC20(FarmToken);
    }

    bool locked;

    modifier safe() {
        require (!locked, "Guard");
        locked = true;
        _;
        locked = false;
    }

    modifier cooldown() {
        require(block.timestamp > last_tx[msg.sender] + cooldown_time, "Calm down");
        _;
        last_tx[msg.sender] = block.timestamp;
    }

    modifier authorized() {
        require(owner==msg.sender || is_auth[msg.sender], "403");
        _;
    }

    modifier onlyOwner() {
        require(owner==msg.sender, "403");
        _;
    }
    
    function has_finished (uint id, address addy) public view returns(bool) {
        return( (block.timestamp > farming_unit[addy][id].deposit_time + farming_unit[addy][id].locked_time) );
    }


    ///@notice Public farming functions

    ///@dev Approve
    function approveTokens() public {
        bool approved = IERC20(FarmToken).approve(address(this), 2**256 - 1);
        require(approved, "Can't approve");
    }

    ///@dev Deposit farmable tokens in the contract
    function farmTokens(uint _amount, uint locking) public {
        require(is_farmable[FarmToken], "Farming not supported");
        if (is_fixed_locking) {
            require(time_allowed[locking].enabled, "Locking time not allowed");
        } else {
            require(locking >= 1 days, "Locking time not allowed");
        }
        require(IERC20(FarmToken).allowance(msg.sender, address(this)) >= _amount, "Allowance?");

        if (time_allowed[locking].check_balance) {
            uint min_amount = IERC20(FarmToken).balanceOf(msg.sender) * time_allowed[locking].percentage_to_check / 100;
            require(_amount >= min_amount, "Pool not allowed for this amount of tokens.");
        }

        // Trasnfer farmable tokens to contract for farming
        bool transferred = IERC20(FarmToken).transferFrom(msg.sender, address(this), _amount);
        require(transferred, "Not transferred");

        // Update the farming balance in mappings
        farm_id[msg.sender]++;
        uint id = farm_id[msg.sender];
        farming_unit[msg.sender][id].locked_time = locking;
        farming_unit[msg.sender][id].balance = farming_unit[msg.sender][id].balance + _amount;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        farming_unit[msg.sender][id].token = FarmToken;
        token_pool[FarmToken].total_balance += _amount;

        // Add user to farms array if they haven't farmd already
        if(token_pool[FarmToken].has_farmed[msg.sender]) {
            token_pool[FarmToken].has_farmed[msg.sender] = true;
        }

        // Update farming status to track
        token_pool[FarmToken].is_farming[msg.sender]++;
        farmer_pools[msg.sender].push(id);
        farming_unit[msg.sender][id].index = (farmer_pools[msg.sender].length)-1;
    }


     ///@dev Unfarm tokens (if not locked)
    function unfarmTokens(uint id) public safe cooldown {
        bool is_finished = has_finished(id, msg.sender);
        if (is_finished) {
            uint balance = _calculate_rewards(id, msg.sender);
            // require the amount farms needs to be greater then 0
            require(balance > 0, "farming balance can not be 0");
        
            // transfer FarmToken tokens out of this contract to the msg.sender
            token_reward.transfer(msg.sender, balance);
            token_reward.transfer(msg.sender, farming_unit[msg.sender][id].balance);    
        } else {    
            require(early_withdraw_available, "Early withdraw is not available | Locking time is not finished");
            uint balance_div = farming_unit[msg.sender][id].balance * early_withdraw_percentage_comission;
            uint balance = balance_div / 100;
            token_reward.transfer(msg.sender, balance);    
        }
    
        // reset farming balance map to 0
        farming_unit[msg.sender][id].balance = 0;
        farming_unit[msg.sender][id].active = false;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        address token = farming_unit[msg.sender][id].token;

        // update the farming status
        token_pool[token].is_farming[msg.sender]--;

        // delete farming pool id
        delete farmer_pools[msg.sender][farming_unit[msg.sender][id].index];
    }

  ///@dev Give rewards and clear the reward status    
  function issueInterestToken(uint id) public safe cooldown {
      require(has_finished(id, msg.sender), "Locking time not finished");
      uint balance = _calculate_rewards(id, msg.sender);            
      token_reward.transfer(msg.sender, balance);
      // reset the time counter so it is not double paid
      farming_unit[msg.sender][id].deposit_time = block.timestamp;    
      }

  ///@dev return the general state of a pool
  function get_pool() public view returns (uint) {
      require(is_farmable[FarmToken], "Not active");
      return(token_pool[FarmToken].total_balance);
  }
  
  ///@notice Private functions

  ///@dev Helper to calculate rewards in a quick and lightweight way
  function _calculate_rewards(uint id, address addy) public view returns (uint) {
    // get the users farming balance in FarmToken
      uint delta_time = block.timestamp - farming_unit[addy][id].deposit_time; // - initial deposit
      /// Rationale: balance*rate/100 gives the APY reward. Is multiplied by year/time passed that is written like that because solidity doesn't like floating numbers
      uint locking_time = farming_unit[addy][id].locked_time;
      uint updated_reward_rate = reward_rate + lock_multiplier[FarmToken][locking_time] + time_allowed[locking_time].multiplier;
      uint balance = (((farming_unit[addy][id].balance * updated_reward_rate) / 100) * ((delta_time * 1000000) / 365 days ))/1000000;
      return balance;
    }

    ///@notice Control functions

    function get_farmer_pools(address farmer) public view returns(uint[] memory) {
        return(farmer_pools[farmer]);
    }

    function unstuck_tokens(address tkn) public authorized {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function set_time_allowed(uint time, bool enabled, bool check_balance, uint multiplier) public authorized {
        time_allowed[time].enabled = enabled;
        time_allowed[time].check_balance = check_balance;
        time_allowed[time].multiplier = multiplier;
        times.push(time);
    }

    function get_time_allowed(uint time) public view returns (time_pool memory) {
        return time_allowed[time];
    }

    function get_times_array() public view returns(uint[] memory){  
        return times;  
    }  

    function set_authorized(address addy, bool booly) public authorized {
        is_auth[addy] = booly;
    }

    function set_authorized(address addy) public onlyOwner {
        owner = addy;
    }

    function set_farming_state(bool status) public authorized {
        is_farmable[FarmToken] = status;
    }

    function get_farming_state() public view returns (bool) {
        return is_farmable[FarmToken];
    }

    function get_reward_rate() public view returns (uint) {
      return reward_rate;
    }

    function get_reward_rate_timed(uint time) public view returns (uint) {
        uint reward_timed = reward_rate+lock_multiplier[FarmToken][time];
        return reward_timed;
    }

    function set_reward_rate(uint rate) public authorized {
        reward_rate = rate;
    }

    function set_early_withdraw_percentage_comission(uint _early_withdraw_percentage_comission) public authorized {
        early_withdraw_percentage_comission = _early_withdraw_percentage_comission;
    }

    function set_early_withdraw_available(bool _early_withdraw_available) public authorized {
        early_withdraw_available = _early_withdraw_available;
    }

    function set_squid_token(address token) public authorized {
        FarmToken = token;
        token_reward = IERC20(FarmToken);
    }  

    function set_multiplier(uint time, uint multiplier) public authorized {
        lock_multiplier[FarmToken][time] = multiplier;
    }

    function set_is_fixed_locking(bool fixed_locking) public authorized {
      is_fixed_locking = fixed_locking;
    }
    
    function get_multiplier(uint time) public view returns(uint) {
        return lock_multiplier[FarmToken][time];
    }

  ///@notice time helpers

    function get_1_day() public pure returns(uint) {
        return(1 days);
    }

    function get_3_days() public pure returns(uint) {
        return(3 days);
    }

    function get_1_month() public pure returns(uint) {
        return(30 days);
    }
    
    function get_2_months() public pure returns(uint) {
        return(60 days);
    }

    function get_x_days(uint x) public pure returns(uint) {
        return((1 days*x));
    }
  
  function get_single_pool(uint id, address addy) public view returns (farm_slot memory) {
      return(farming_unit[addy][id]);
  }

  function get_time_remaining(uint id, address addy) public view returns (uint) {
      return(farming_unit[addy][id].deposit_time + farming_unit[addy][id].locked_time);
  }

  function get_pool_lock_time(uint id, address addy) public view returns (uint) {
      return(farming_unit[addy][id].locked_time);
  }
  
  function get_pool_balance(uint id, address addy) public view returns (uint) {
      return(farming_unit[addy][id].balance);
  }

  function get_pool_details(uint id, address addy) public view returns (uint, uint) {
    return(get_pool_balance(id, addy), get_time_remaining(id, addy));   
  }

  receive() external payable {}
  fallback() external payable {}
}