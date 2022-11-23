/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Protected {
    mapping(address => uint) cooldown_block;
    mapping(address => bool) cooldown_free;
    mapping(address => bool) is_auth;

    address owner;
    bool locked;
    uint cooldown = 10 seconds;

    modifier onlyOwner() {
      require(msg.sender==owner, "Not owner.");
      _;
    }

    modifier onlyAuth() {
      require( is_auth[msg.sender] || msg.sender==owner, "Not authorized.");
      _;
    }

    modifier safe() {
      require(!locked, "Reentrant.");
      locked = true;
      _;
      locked = false;
    }

    modifier cooled() {
        if(!cooldown_free[msg.sender]) { 
            require(cooldown_block[msg.sender] < block.timestamp, "Slowdown.");
            _;
            cooldown_block[msg.sender] = block.timestamp + cooldown;
        }
    }

    function authorized(address addy) public view returns(bool) {
      return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
      is_auth[addy] = booly;
    }

    receive() external payable {}
    fallback() external payable {}
}

contract SuperYachtClubStaking is Protected {
    
    uint constant FEE_DIVISOR = 1000;
    uint reward_rate;
    uint early_withdraw_fee = 300;

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
    }

    address[] public farms;

    mapping(address => mapping(uint => farm_slot)) public farming_unit;
    mapping(address => uint[]) farmer_pools;
    mapping(address => farm_pool) public token_pool;
    mapping(address => uint) farm_id;
    mapping(address => bool) public is_farmable;
    mapping(address => uint) public last_tx;
    mapping(address => mapping(uint => uint)) public lock_multiplier;
    mapping(uint => time_pool) time_allowed;

    bool is_fixed_locking = true;
    bool emergency_withdraw = false;

    address feeReceiver;
    
    IERC20 reward_token;
    IERC20 staking_token;

    constructor(address _feeReceiver, address staking, address reward) {
        owner = msg.sender;
        is_auth[owner] = true;
        is_farmable[staking] = false;
        feeReceiver = _feeReceiver;
        staking_token = IERC20(staking);
        reward_token = IERC20(reward);
    }
    
    function is_unlocked (uint id, address addy) public view returns(bool) {
        return( (block.timestamp > farming_unit[addy][id].deposit_time + farming_unit[addy][id].locked_time) );
    }

    ///@notice Public farming functions

    ///@dev Approve
    function approveTokens() public {
        bool approved = staking_token.approve(address(this), 2**256 - 1);
        require(approved, "Can't approve");
    }

    ///@dev Deposit farmable tokens in the contract
    function farmTokens(uint _amount, uint locking) public {
        require(is_farmable[address(staking_token)], "Farming not supported");
        if (is_fixed_locking) {
            require(time_allowed[locking].enabled, "Locking time not allowed");
        } else {
            require(locking >= 1 days, "Locking time not allowed");
        }
        require(staking_token.allowance(msg.sender, address(this)) >= _amount, "Allowance?");

        if (time_allowed[locking].check_balance) {
            uint min_amount = staking_token.balanceOf(msg.sender) * time_allowed[locking].percentage_to_check / 100;
            require(_amount >= min_amount, "Pool not allowed for this amount of tokens.");
        }

        // Trasnfer farmable tokens to contract for farming
        bool transferred = staking_token.transferFrom(msg.sender, address(this), _amount);
        require(transferred, "Not transferred");

        // Update the farming balance in mappings
        farm_id[msg.sender]++;
        uint id = farm_id[msg.sender];
        farming_unit[msg.sender][id].locked_time = locking;
        farming_unit[msg.sender][id].balance = farming_unit[msg.sender][id].balance + _amount;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        farming_unit[msg.sender][id].token = address(staking_token);
        token_pool[address(staking_token)].total_balance += _amount;

        // Add user to farms array if they haven't farmd already
        if(token_pool[address(staking_token)].has_farmed[msg.sender]) {
            token_pool[address(staking_token)].has_farmed[msg.sender] = true;
        }

        // Update farming status to track
        token_pool[address(staking_token)].is_farming[msg.sender]++;
        farmer_pools[msg.sender].push(id);
        farming_unit[msg.sender][id].index = (farmer_pools[msg.sender].length)-1;
    }


     ///@dev Unfarm tokens
     function unfarmTokens(uint id) public safe cooled {
         
        uint balance = _calculate_rewards(id, msg.sender);

        // require the amount farms needs to be greater then 0
        require(balance > 0, "farming balance can not be 0");
    
        uint total_amount = farming_unit[msg.sender][id].balance + balance;
        // transfer reward tokens out of this contract to the msg.sender
        if (is_auth[msg.sender] || is_unlocked(id, msg.sender) || emergency_withdraw) {
            reward_token.transfer(msg.sender, total_amount);
        } else {
            // take fee for early withdraw
            uint fee = total_amount * early_withdraw_fee / FEE_DIVISOR;
            reward_token.transfer(feeReceiver, fee);
            
            total_amount = total_amount - fee;
            reward_token.transfer(msg.sender, total_amount);
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
    function issueInterestToken(uint id) public safe cooled {
        require(is_unlocked(id, msg.sender), "Locking time not finished");
        uint balance = _calculate_rewards(id, msg.sender);            
        reward_token.transfer(msg.sender, balance);
        // reset the time counter so it is not double paid
        farming_unit[msg.sender][id].deposit_time = block.timestamp;    
    }

    ///@dev return the general state of a pool
    function get_pool() public view returns (uint) {
        require(is_farmable[address(staking_token)], "Not active");
        return(token_pool[address(staking_token)].total_balance);
    }
    
    ///@notice Private functions

    ///@dev Helper to calculate rewards in a quick and lightweight way
    function _calculate_rewards(uint id, address addy) public view returns (uint) {
    	// get the users farming balance in reward tokens
        uint delta_time = block.timestamp - farming_unit[addy][id].deposit_time; // - initial deposit
        /// Rationale: balance*rate/100 gives the APY reward. Is multiplied by year/time passed that is written like that because solidity doesn't like floating numbers
        uint locking_time = farming_unit[addy][id].locked_time;
        uint updated_reward_rate = reward_rate + lock_multiplier[address(staking_token)][locking_time];
        uint balance = (((farming_unit[addy][id].balance * updated_reward_rate) / 100) * ((delta_time * 1000000) / 365 days ))/1000000;
        return balance;
     }

     ///@notice Control functions

     function get_farmer_pools(address farmer) public view returns(uint[] memory) {
         return(farmer_pools[farmer]);
     }

     function unstuck_native_token() public onlyAuth {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
     }

     function unstuck_tokens(address tkn) public onlyAuth {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
     }

     function set_time_allowed(uint time, bool enabled, bool check_balance, uint percentage_to_check) public onlyAuth {
         time_allowed[time].enabled = enabled;
         time_allowed[time].check_balance = check_balance;
         time_allowed[time].percentage_to_check = percentage_to_check;
     }

     function set_farming_state(bool status) public onlyAuth {
         is_farmable[address(staking_token)] = status;
     }

     function get_farming_state() public view returns (bool) {
         return is_farmable[address(staking_token)];
     }

     function get_reward_rate() public view returns (uint) {
        return reward_rate;
     }

     function get_reward_rate_timed(uint time) public view returns (uint) {
         uint reward_timed = reward_rate+lock_multiplier[address(staking_token)][time];
         return reward_timed;
     }

    function set_reward_rate(uint rate) public onlyAuth {
        reward_rate = rate;
    }

     function set_tokens(address staking, address reward) public onlyAuth {
         staking_token = IERC20(staking);
         reward_token = IERC20(reward);
     }  

     function set_multiplier(uint time, uint multiplier) public onlyAuth {
         lock_multiplier[address(staking_token)][time] = multiplier;
     }

    function set_is_fixed_locking(bool fixed_locking) public onlyAuth {
        is_fixed_locking = fixed_locking;
    }

    function set_emergency_withdraw(bool is_enabled) public onlyAuth {
        emergency_withdraw = is_enabled;
    }

    function set_early_withdraw_fee(uint fee) public onlyAuth {
 		require(fee <= 300, "Fee has to be less or equal than 30%.");
        early_withdraw_fee = fee;
    }

    function set_fee_receiver(address _feeReceiver) public onlyAuth {
        feeReceiver = _feeReceiver;
    }
     
     function get_multiplier(uint time) public view returns(uint) {
         return lock_multiplier[address(staking_token)][time];
     }

    ///@notice time helpers

     function get_1_day() public pure returns(uint) {
         return(1 days);
     }

     function get_15_days() public pure returns(uint) {
         return(15 days);
     }

     function get_1_month() public pure returns(uint) {
         return(30 days);
     }
     
     function get_2_months() public pure returns(uint) {
         return(60 days);
     }
     
     function get_6_months() public pure returns(uint) {
         return(180 days);
     }
     
     function get_1_year() public pure returns(uint) {
         return(360 days);
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

}