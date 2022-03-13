/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);

        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);

        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        return ((a + m - 1) / m) * m;
    }
}

struct Tiers {
    uint256 tier1_stake_tokens_min;
    uint256 tier1_deposit_max_usdt;
    uint256 tier1_deposit_max_eth;
    uint256 tier2_stake_tokens_min;
    uint256 tier2_deposit_max_usdt;
    uint256 tier2_deposit_max_eth;
    uint256 tier3_stake_tokens_min;
    uint256 tier3_deposit_max_usdt;
    uint256 tier3_deposit_max_eth;
    uint256 tier4_stake_tokens_min;
    uint256 tier4_deposit_max_usdt;
    uint256 tier4_deposit_max_eth;
}



//SD Staking-Distribution

contract SD {
    using SafeMath for uint256;

    address payable public owner;

    address public usdt_address = 0x9D3cEa78d1E610fB12955ca7cfe285629cdC180f;

    mapping(address => SDPool) public Pools;


    struct SDPool {
        address staking_token_address;
        address[] stakeholders;
        mapping(address => uint256) deposits_usdt;
        mapping(address => uint256) deposits_eth;
        mapping(address => uint256) staked_tokens;
        mapping(address => uint256) effective_staked_tokens;
        mapping(address => uint256)  txRecord;
        uint256 staking_end_timestamp;
        uint256 deposit_start_timestamp;
        uint256 deposit_end_timestamp;
        Tiers tiers_settings;
        
    }

    constructor() {
        owner = msg.sender;
    }

   modifier checkStaked(address sale_token) {
        bool staked = false;
        SDPool storage pool = Pools[sale_token];
        for(uint256 i = 0; i < pool.stakeholders.length ;i ++){
            if(msg.sender == pool.stakeholders[i]){
                staked = true;
                break;
            }
        }
        
        require(staked == true, "Sorry, You didn't stake yet!");
         _;
   }

    function initPool(
        address sale_token,
        address var_staking_token_address,
        uint256 var_staking_end_timestamp,
        uint256 var_deposit_start_timestamp,
        uint256 var_deposit_end_timestamp,
        uint256[] memory var_tiers
    ) public returns (bool) {
        require(msg.sender == owner, "ERROR!: ONLY OWNER ALLOWED");

        Pools[sale_token].staking_token_address = var_staking_token_address;

        Pools[sale_token].staking_end_timestamp = var_staking_end_timestamp;

        Pools[sale_token].deposit_start_timestamp = var_deposit_start_timestamp;

        Pools[sale_token].deposit_end_timestamp = var_deposit_end_timestamp;

        Pools[sale_token].tiers_settings.tier1_stake_tokens_min = var_tiers[0];

        Pools[sale_token].tiers_settings.tier1_deposit_max_usdt = var_tiers[1];

        Pools[sale_token].tiers_settings.tier1_deposit_max_eth = var_tiers[2];

        Pools[sale_token].tiers_settings.tier2_stake_tokens_min = var_tiers[3];

        Pools[sale_token].tiers_settings.tier2_deposit_max_usdt = var_tiers[4];

        Pools[sale_token].tiers_settings.tier2_deposit_max_eth = var_tiers[5];

        Pools[sale_token].tiers_settings.tier3_stake_tokens_min = var_tiers[6];

        Pools[sale_token].tiers_settings.tier3_deposit_max_usdt = var_tiers[7];

        Pools[sale_token].tiers_settings.tier3_deposit_max_eth = var_tiers[8];

        Pools[sale_token].tiers_settings.tier4_stake_tokens_min = var_tiers[9];

        Pools[sale_token].tiers_settings.tier4_deposit_max_usdt = var_tiers[10];

        Pools[sale_token].tiers_settings.tier4_deposit_max_eth = var_tiers[11];

        return true;
    }

    function getStakeHolders(address sale_token)
        public
        view
        returns (address[] memory)
    {
        return Pools[sale_token].stakeholders;
    }

    function get_staked_tokens(address sale_token, address hodler)
        public
        view
        returns (uint256)
    {
        return Pools[sale_token].staked_tokens[hodler];
    }

    function get_effective_staked_tokens(address sale_token, address hodler)
        public
        view
        returns (uint256)
    {
        return Pools[sale_token].effective_staked_tokens[hodler];
    }

    function get_deposits_eth(address sale_token, address hodler)
        public
        view
        returns (uint256)
    {
        return Pools[sale_token].deposits_eth[hodler];
    }

    function get_deposits_usdt(address sale_token, address hodler)
        public
        view
        returns (uint256)
    {
        return Pools[sale_token].deposits_usdt[hodler];
    }

    function depositETH(address sale_token) public payable checkStaked(sale_token)  returns (bool)  {
        require(
            Pools[sale_token].staking_token_address != address(0),
            "Pool does not exist"
        );

        require(
            Pools[sale_token].staked_tokens[msg.sender] > 0,
            "only stakeholders are allowed to deposit"
        );

        require(
            block.timestamp > Pools[sale_token].deposit_start_timestamp,
            "TOO early, wait for deposit_start_timestamp"
        );

        require(
            block.timestamp < Pools[sale_token].deposit_end_timestamp,
            "TOO late, deposits closed at deposits_end_timestamp"
        );

        Pools[sale_token].deposits_eth[msg.sender] += msg.value;
        Pools[sale_token].txRecord[msg.sender] += 1;


        require(
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
                Pools[sale_token].tiers_settings.tier1_stake_tokens_min,
            "ETH Deposits are not allowed"
        );

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier1_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier2_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier1_deposit_max_eth,
                "Tier 1 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier2_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier2_deposit_max_eth,
                "Tier 2 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier3_deposit_max_eth,
                "Tier 3 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier4_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier4_deposit_max_eth,
                "Tier 4 deposit limit overflow"
            );
        }

        return true;
    }

    function depositUSDT(uint256 amt, address sale_token)
        public
        checkStaked(sale_token)
        returns (bool)
    {
        require(
            Pools[sale_token].staking_token_address != address(0),
            "Pool does not exist"
        );

        require(
            Pools[sale_token].staked_tokens[msg.sender] > 0,
            "only stakeholders are allowed to deposit"
        );

        require(
            block.timestamp > Pools[sale_token].staking_end_timestamp,
            "TOO early, wait for staking_end_timestamp"
        );

        require(
            block.timestamp < Pools[sale_token].deposit_end_timestamp,
            "TOO late, deposits closed at deposits_end_timestamp"
        );

        IERC20 usdt_token_contract = IERC20(usdt_address);

        usdt_token_contract.transferFrom(msg.sender, address(this), amt);

        Pools[sale_token].deposits_usdt[msg.sender] += amt;

        Pools[sale_token].txRecord[msg.sender] += 1;

        require(
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
                Pools[sale_token].tiers_settings.tier1_stake_tokens_min,
            "USDT Deposits are not allowed"
        );

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier1_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier2_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier1_deposit_max_usdt,
                "Tier 1 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier2_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier2_deposit_max_usdt,
                "Tier 2 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min &&
            Pools[sale_token].effective_staked_tokens[msg.sender] <
            Pools[sale_token].tiers_settings.tier3_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier3_deposit_max_usdt,
                "Tier 3 deposit limit overflow"
            );
        }

        if (
            Pools[sale_token].effective_staked_tokens[msg.sender] >=
            Pools[sale_token].tiers_settings.tier4_stake_tokens_min
        ) {
            require(
                Pools[sale_token].deposits_eth[msg.sender] <=
                    Pools[sale_token].tiers_settings.tier4_deposit_max_usdt,
                "Tier 4 deposit limit overflow"
            );
        }

        return true;
    }

    function stake(uint256 amt, address sale_token) public returns (bool) {
        require(
            Pools[sale_token].staking_token_address != address(0),
            "Pool does not exist"
        );

        require(amt > 0, "zero amt not allowed");

        require(
            block.timestamp < Pools[sale_token].staking_end_timestamp,
            "TOO late, staking closed at staking_end_timestamp"
        );

        IERC20 staking_token_contract = IERC20(
            Pools[sale_token].staking_token_address
        );

        if (Pools[sale_token].staked_tokens[msg.sender] == 0) {
            Pools[sale_token].stakeholders.push(msg.sender);
        }

        staking_token_contract.transferFrom(msg.sender, address(this), amt);

        Pools[sale_token].staked_tokens[msg.sender] += amt;

        Pools[sale_token].effective_staked_tokens[msg.sender] += amt;

        require(
            Pools[sale_token].tiers_settings.tier1_stake_tokens_min <=
                Pools[sale_token].effective_staked_tokens[msg.sender],
            "You should stake at least tier1_stake_tokens_min"
        );

        return true;
    }

    function unstake(uint256 amt, address sale_token) public returns (bool) {
        require(amt > 0, "zero amt not allowed");

        require(
            Pools[sale_token].staked_tokens[msg.sender] >= amt,
            "not enough staked tokens"
        );

        if (block.timestamp < Pools[sale_token].deposit_start_timestamp) {
            //affect both

            Pools[sale_token].staked_tokens[msg.sender] -= amt;

            Pools[sale_token].effective_staked_tokens[msg.sender] -= amt;
        } else {
            //keep effective

            Pools[sale_token].staked_tokens[msg.sender] -= amt;
        }

        IERC20 staking_token_contract = IERC20(
             Pools[sale_token].staking_token_address
        );

        staking_token_contract.transfer(msg.sender, amt);

        return true;
    }

    function withdrawETH() public returns (bool) {
        require(msg.sender == owner, "ERROR!: ONLY OWNER ALLOWED");

        owner.transfer(address(this).balance);

        return true;
    }

    function withdrawToken(address token_contract_addr) public returns (bool) {
        require(msg.sender == owner, "ERROR!: ONLY OWNER ALLOWED");

        IERC20 token_contract = IERC20(token_contract_addr);

        uint256 my_token_balance = token_contract.balanceOf(address(this));

        token_contract.transfer(owner, my_token_balance);

        return true;
    }

    function getTransactionRecordNum(address saleToken, address _owner) public view returns  (uint256) {
        return Pools[saleToken].txRecord[_owner];
    }
}