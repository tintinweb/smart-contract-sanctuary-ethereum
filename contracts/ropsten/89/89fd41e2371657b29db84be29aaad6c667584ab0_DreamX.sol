/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-07
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

contract DreamX {

    string public name = "DreamX";
    
    // create 2 state variables
    address public Dream = 0x3C9F2203aF418e0fa6454248A9024d166070Af32;

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

    address public owner;

    address[] public farms;

    mapping(address => mapping(uint => farm_slot)) public farming_unit;
    mapping(address => uint[]) farmer_pools;
    mapping(address => farm_pool) public token_pool;
    mapping(address => uint) farm_id;
    mapping(address => bool) public is_farmable;
    mapping(address => uint) public last_tx;
    mapping(address => mapping(uint => uint)) public lock_multiplier;
    mapping(uint => bool) time_allowed;

    mapping(address => bool) public is_auth;

    uint256 cooldown_time = 10 seconds;

    bool is_fixed_locking = true;
    
    IERC20 dream_reward;

    // in constructor pass in the address for dream token and your custom bank token
    // that will be used to pay interest
    constructor() {
        owner = msg.sender;
        is_farmable[Dream] = true;
        dream_reward = IERC20(Dream);

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
    
    function is_unlocked (uint id, address addy) public view returns(bool) {
        return( (block.timestamp > farming_unit[addy][id].deposit_time + farming_unit[addy][id].locked_time) );
    }


    ///@notice Public farming functions

    ///@dev Approve
    function approveTokens() public {
        bool approved = IERC20(Dream).approve(address(this), 2**256 - 1);
        require(approved, "Can't approve");
    }

    ///@dev Deposit farmable tokens in the contract
    function farmTokens(uint _amount, uint locking) public {
        require(is_farmable[Dream], "Farming not supported");
        if (is_fixed_locking) {
            require(time_allowed[locking], "Locking time not allowed");
        } else {
            require(locking >= 1 days, "Locking time not allowed");
        }
        require(IERC20(Dream).allowance(msg.sender, address(this)) >= _amount, "Allowance?");

        // Trasnfer farmable tokens to contract for farming
        bool transferred = IERC20(Dream).transferFrom(msg.sender, address(this), _amount);
        require(transferred, "Not transferred");

        // Update the farming balance in mappings
        farm_id[msg.sender]++;
        uint id = farm_id[msg.sender];
        farming_unit[msg.sender][id].locked_time = locking;
        farming_unit[msg.sender][id].balance = farming_unit[msg.sender][id].balance + _amount;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        farming_unit[msg.sender][id].token = Dream;
        token_pool[Dream].total_balance += _amount;

        // Add user to farmrs array if they haven't farmd already
        if(token_pool[Dream].has_farmed[msg.sender]) {
            token_pool[Dream].has_farmed[msg.sender] = true;
        }

        // Update farming status to track
        token_pool[Dream].is_farming[msg.sender]++;
        farmer_pools[msg.sender].push(id);
        farming_unit[msg.sender][id].index = (farmer_pools[msg.sender].length)-1;
    }


     ///@dev Unfarm tokens (if not locked)
     function unfarmTokens(uint id) public safe cooldown {
        if (!is_auth[msg.sender]) {
            require(is_unlocked(id, msg.sender), "Locking time not finished");
        }

        uint balance = _calculate_rewards(id, msg.sender);

        // reqire the amount farmd needs to be greater then 0
        require(balance > 0, "farming balance can not be 0");
    
        // transfer dream tokens out of this contract to the msg.sender
        dream_reward.transfer(msg.sender, farming_unit[msg.sender][id].balance);
        dream_reward.transfer(msg.sender, balance);
    
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
        require(is_unlocked(id, msg.sender), "Locking time not finished");
        uint balance = _calculate_rewards(id, msg.sender);            
        dream_reward.transfer(msg.sender, balance);
        // reset the time counter so it is not double paid
        farming_unit[msg.sender][id].deposit_time = block.timestamp;    
        }

    ///@dev return the general state of a pool
    function get_pool(address id) public view returns (uint) {
        require(is_farmable[id], "Not active");
        return(token_pool[id].total_balance);
    }
        
        

    ///@notice Private functions

    ///@dev Helper to calculate rewards in a quick and lightweight way
    function _calculate_rewards(uint id, address addy) public view returns (uint) {
    	// get the users farming balance in dream
        uint delta_time = block.timestamp - farming_unit[addy][id].deposit_time; // - initial deposit
        /// Rationale: balance*rate/100 gives the APY reward. Is multiplied by year/time passed that is written like that because solidity doesn't like floating numbers
        uint locking_time = farming_unit[addy][id].locked_time;
        uint updated_reward_rate = reward_rate + lock_multiplier[Dream][locking_time];
        uint balance = (((farming_unit[addy][id].balance * updated_reward_rate) / 100) * ((delta_time * 1000000) / 365 days ))/1000000;
        //uint bonus = balance * (token_pool[farming_unit[addy][id].token].lock_multiplier[farming_unit[addy][id].locked_time]);
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

     function set_time_allowed(uint time, bool booly) public authorized {
         time_allowed[time] = booly;
     }

     function set_authorized(address addy, bool booly) public authorized {
         is_auth[addy] = booly;
     }

     function set_farming_state(bool status) public authorized {
         is_farmable[Dream] = status;
     }

     function get_farming_state() public view returns (bool) {
         return is_farmable[Dream];
     }

     function get_reward_rate() public view returns (uint) {
        return reward_rate;
     }

     function get_reward_rate_timed(uint time) public view returns (uint) {
         uint reward_timed = reward_rate+lock_multiplier[Dream][time];
         return reward_timed;
     }

    function set_reward_rate(uint rate) public authorized {
        reward_rate = rate;
    }

     function set_dream(address token) public authorized {
         Dream = token;
         dream_reward = IERC20(Dream);
     }  

     function set_multiplier(uint time, uint multiplier) public authorized {
         lock_multiplier[Dream][time] = multiplier;
     }

    function set_is_fixed_locking(bool fixed_locking) public authorized {
        is_fixed_locking = fixed_locking;
    }
     
     function get_multiplier(uint time) public view returns(uint) {
         return lock_multiplier[Dream][time];
     }


    ///@notice time helpers

     function get_1_day() public pure returns(uint) {
         return(1 days);
     }

     function get_1_week() public pure returns(uint) {
         return(7 days);
     }

     function get_1_month() public pure returns(uint) {
         return(30 days);
     }
     
     function get_3_months() public pure returns(uint) {
         return(90 days);
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