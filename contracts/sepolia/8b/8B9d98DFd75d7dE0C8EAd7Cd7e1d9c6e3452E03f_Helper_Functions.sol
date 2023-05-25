// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {

    // ------- Addresses -------

    // USDT address
    address internal constant usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT

    // USDC address
    address internal constant usdc_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    // Founder Wallets
    address internal constant founder_0 = 0x1FBBdc4b9c8CB458deb9305b0884c64D5DD7DBee; // S
    address internal constant founder_1 = 0xb96ddd73895FF973c85A0dcd882627c994d179C4; // P
    address internal constant founder_2 = 0x3e34a7014751dff1B5fE1aa340c35E8aa00C555E; // A
    address internal constant founder_3 = 0x7D3e5A497a03d294F17650c298F53Fb916421522; // F

    // Company
    address internal constant company_wallet = 0xfe7474462F0d520B3A41bBE3813dd9aE6B5190B8; // Owner

    // Price signing
    address internal constant pricing_authority = 0x83258645a1E202ED1EAA70cAA015DCfaD8557b3b; // Signer

    // ------- Values -------

    // Standard amount of decimals we usually use
    uint128 internal constant decimals = 10 ** 18; // Same as Ethereum

    // Token supply
    uint128 internal constant founder_reward = 50 * 10**9 * decimals; // 4x 50 Billion
    uint128 internal constant company_reward = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant max_presale_quantity = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant maximum_subsidy = 400 * 10**9 * decimals; // 400 Billion

    // Fees and taxes these are in x100 for some precision
    uint128 internal constant ministerial_fee = 100;
    uint128 internal constant finders_fee = 100;
    uint128 internal constant minimum_tax_rate = 50;
    uint128 internal constant maximum_tax_rate = 500;
    uint128 internal constant tax_rate_range = maximum_tax_rate - minimum_tax_rate;
    uint16 internal constant maximum_royalties = 2500;
    
    // Values for subsidy
    uint128 internal constant subsidy_duration = 946080000; // 30 years
    uint128 internal constant max_subsidy_rate = 3 * maximum_subsidy / subsidy_duration;


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Data_Structures {

    struct Split {
        uint128 staker;
        uint128 tax;
        uint128 ministerial;
        uint128 creator;
        uint128 total;
    }

    struct Stake {

        // Used in calculating the finders fees owed to a user
        uint160 multiple;

        // The historic level of the reward units at the last claim...
        uint160 historic_reward_units;

        // Amount user has comitted to this stake
        uint128 amount_staked;

        // Amount user sent to stake, needed for fees calculation
        uint128 amount_staked_raw;

        // Address of the staker
        address staker_address;

        // The address of the contract corresponding to this stake
        uint64 contract_index;

        // The amount of time you need to wait for your first claim. Basically the waiting list time
        uint32 delay_nerf;

        // Stake init time
        uint32 init_time;

        // If the stake has been nerfed with regards to thr waitlist
        bool has_been_delay_nerfed;
        
    }


    struct Contract {

        // The total amount of units so we can know how much a token staked is worth
        // calculated as incoming rewards * 1-royalty / total staked
        uint160 reward_units;

        // Used in calculating staker finder fees
        uint160 total_multiple;

        // The total amount of staked comitted to this contract
        uint128 total_staked;

        // Rewards allocated for the creator of this stake, still unclaimed
        uint128 unclaimed_creator_rewards;

        // The contract address of this stake
        address contract_address;
        
        // The assigned address of the creator
        address owner_address;

        // The rate of the royalties configured by the creator
        uint16 royalties;
        
    }

    struct Global {

        // Used as a source of randomness
        uint256 random_seed;

        // The total amount staked globally
        uint128 total_staked;

        // The total amount of ApeMax minted
        uint128 total_minted;

        // Unclaimed amount of ministerial rewards
        uint128 unclaimed_ministerial_rewards;

        // Extra subsidy lost to mint nerf. In case we want to do something with it later
        uint128 nerfed_subsidy;

        // The number of contracts
        uint64 contract_count;

        // The time at which this is initialized
        uint32 init_time;

        // The last time we has to issue a tax, used for subsidy range calulcation
        uint32 last_subsidy_update_time;

        // The last time a token was minted
        uint32 last_minted_time;

    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Data_Structures.sol";
import "./Constants.sol";

library Helper_Functions {

    // ------- Basic -------

    /*
        Adjust a value so it stays within a range
    */
    function fix_for_range(
        uint128 variable,
        uint128 min,
        uint128 max
        )
        public pure
        returns(uint128)

    {

        variable = variable < min ? min : variable;
        variable = variable > max ? max : variable;
        return variable;

    }

    /* 
        Adjust time to reference contract creation time and maximum time
        For cases where there is no maximum it can be used simply by passing max_time = current_time
    */
    function normalize_time(
        uint32 current_time,
        uint32 init_time,
        uint32 max_time
        )
        public pure
        returns (uint32)
    {   
        current_time = current_time < init_time ? init_time : current_time;
        uint32 relative_time = current_time - init_time;
        relative_time = relative_time > max_time ? max_time : relative_time;
        return relative_time;
    }

    // ------- Subsidy -------
    /*
        Calculates the integral of the subsidy, basically:
        ∫ C(t) dt = (A * t) + ((A * t^3) / (3 T^2)) - ((A * t^2)/T)
    */
    function subsidy_integral(
        uint32 time,
        uint32 init_time
        )
        public pure
        returns(uint256)
    {
        // Cast up then down
        uint256 normalized_time = uint256(normalize_time(time, init_time, uint32(Constants.subsidy_duration)));
        uint256 max_subsidy_rate = uint256(Constants.max_subsidy_rate);
        uint256 subsidy_duration = uint256(Constants.subsidy_duration);

        uint256 integral =
            (max_subsidy_rate * normalized_time) +
            ((max_subsidy_rate * normalized_time ** 3) / (3 * subsidy_duration ** 2)) -
            ((max_subsidy_rate * normalized_time ** 2) / subsidy_duration);
        
        return integral;
    }

    /*
        Returns the total subsidy to be distributed in a range of time
    */
    function calculate_subsidy_for_range(
        uint32 start_time,
        uint32 end_time,
        uint32 init_time // Time the contract was initialized
        )
        public pure
        returns(uint128)
    {
        uint256 integral_range =  
            subsidy_integral(end_time, init_time) -
            subsidy_integral(start_time, init_time);

        return uint128(integral_range);
    }

    // ------- Fees -------
    /*
        Returns percentage tax at current time
        Tax ranges from 1% to 5%
        In 100x denomination
    */
    function calculate_tax(
        uint128 total_staked
        )
        public pure
        returns(uint128)
    {

        if (total_staked >= Constants.maximum_subsidy) {
            return Constants.maximum_tax_rate;
        }

        return
            Constants.minimum_tax_rate +
            Constants.tax_rate_range *
            total_staked /
            Constants.maximum_subsidy;

    }

    /*
        Calculates fees to be shared amongst all parties when a new stake comes in
    */
    function calculate_inbound_fees(
        uint128 amount_staked,
        uint16 royalties,
        uint128 total_staked
        )
        public pure
        returns(Data_Structures.Split memory)
    {
        Data_Structures.Split memory inbound_fees;
        
        inbound_fees.staker = Constants.finders_fee * amount_staked / 10000;
        inbound_fees.ministerial = Constants.ministerial_fee * amount_staked / 10000;
        inbound_fees.tax = amount_staked * calculate_tax(total_staked) / 10000;
        inbound_fees.creator = amount_staked * royalties / 1000000;
        
        inbound_fees.total =
            inbound_fees.staker +
            inbound_fees.ministerial + 
            inbound_fees.tax +
            inbound_fees.creator;

        return inbound_fees;
    }

    /*
        Fixes the royalties values if needed
    */
    function fix_royalties(
        uint16 royalties
        )
        public pure
        returns (uint16)
    {
        return royalties > Constants.maximum_royalties ? Constants.maximum_royalties : royalties;
    }

    // ------- Delay -------
    /*
        Determins the amount of delay received
        It is here with the share since the calculation are inherently linked
        More share = more delay...

        switched to -->
        f(a, t, n) = (315,360,000 * (a/t)^3) * (n/10000)
    */
    function delay_function(
        uint128 amount_staked,
        uint128 total_staked,
        uint64 number_of_staking_contracts
        )
        public pure
        returns(uint32)
    {
        uint256 decimals = 10**18;
        uint256 a = uint256(amount_staked);
        uint256 t = uint256(total_staked);
        uint256 n = uint256(number_of_staking_contracts);

        uint256 delay =
            315360000 *
            (decimals * a / t)**3 *
            n /
            10000 /
            (decimals**3);
        
        if (delay > uint256(type(uint32).max)) {
            return type(uint32).max;
        }

        return uint32(delay);


    }

    // ------- Presale -------
    function verify_minting_authorization(
        uint128 total_minted,
        uint256 block_time,
        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        uint8 currency_index,
        uint8 v, bytes32 r, bytes32 s
        )
        public pure
    {
        // Sanity checks
        require(total_minted + quantity < Constants.max_presale_quantity, "Exceeds maximum total supply");
        require(timestamp + 60 * 60 * 24 > block_time, "Pricing has expired");

        // Verify signature
        require(ecrecover(keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(amount_payable, quantity, timestamp, currency_index))
        )), v, r, s) == Constants.pricing_authority, "Invalid signature");
    }

}