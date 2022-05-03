/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

/// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.7;

interface c_fang {
        function setFarmer(address addy) external; 
        function mint_rewards(uint qty, address receiver) external; 
}

interface c_earn {
    function get_reward_on_pool(address actor, uint96 pool, bool yearly)
        external
        view
        returns (uint reward);

    function get_single_pool(address actor, uint96 pool)
        external
        view
        returns (
            uint256 quantity,
            uint256 unlock_block,
            uint256 start_block);

    function get_stake_pool(address stakeholder, uint96 pool) external view returns (bool status,
                                                                     address[2] memory tokens,
                                                                     uint[6] memory stats);
        /*
            staker[stakeholder].stake[pool].active,
            [staker[stakeholder].stake[pool].token_staked,
            staker[stakeholder].stake[pool].token_reward],
            [staker[stakeholder].stake[pool].quantity,
            staker[stakeholder].stake[pool].start_time,
            staker[stakeholder].stake[pool].total_earned,
            staker[stakeholder].stake[pool].total_withdraw,
            staker[stakeholder].stake[pool].unlock_time,
            staker[stakeholder].stake[pool].time_period]
        */


    function ADMIN_control_pool(address addy, uint96 id,
                            bool active, address token_staked, address token_reward,
                            uint quantity, uint start_time, uint last_retrieved, uint total_earned,
                            uint total_withdraw, uint unlock_time, uint time_period)  external;
        
}


contract fang_helper {

    address kaiba=0xF2210f65235c2FB391aB8650520237E6378e5C5A;
    address fang=0x988FC5E37281F6c165886Db96B3FdD2f61E6Bb3F;
    address earn=0x783C8935F77C97FA0fB67664A4695BeA3fe6162c;

    address owner;
    mapping(address => bool) is_auth;
    
    modifier only_auth () {
        require(msg.sender == owner || is_auth[msg.sender]);
        _;
    }

    function set_auth(address addy, bool booly) public only_auth {
        is_auth[addy] = booly;
    }

    bool locked;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}
    fallback() external {}

    function get_unlocked_pool(address addy, uint96 pool_id) public {
        require(!locked, "reentrant");
        locked = true;

        c_fang local_fang = c_fang(fang);
        c_earn local_earn = c_earn(earn);
        
        uint rewarded = local_earn.get_reward_on_pool(addy, pool_id, false);
        require(rewarded > 1000000000000000, "Useless quantity");

        local_fang.setFarmer(address(this));
        local_fang.mint_rewards(rewarded, addy);

        bool status;
        address[2] memory token;
        uint[6] memory stats;

        (status, token, stats) = local_earn.get_stake_pool(addy, pool_id);
        local_earn.ADMIN_control_pool(addy, pool_id, status, token[0], token[1], stats[0], stats[1], 
                                      block.timestamp, stats[2], stats[3] += rewarded, stats[4], stats[5]);

        local_fang.setFarmer(earn);

        locked = false;
    }

    function set_kaiba(address addy) public only_auth {
        kaiba = addy;
    }


    function set_earn(address addy) public only_auth {
        earn = addy;
    }


    function set_fang(address addy) public only_auth {
        fang = addy;
    }

}