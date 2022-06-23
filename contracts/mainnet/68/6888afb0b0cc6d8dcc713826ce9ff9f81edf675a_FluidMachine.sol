// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.14;

import "./LiquidERC20_v2.sol";
import "./LiquidERC721.sol";


contract FluidMachine is protected, Fluid {

    /* -----------------------------------------------------
                              Types
    ----------------------------------------------------- */ 

    struct STAKE_TOKEN_SLOT {
        uint quantity;
        uint starting_time;
        uint lock_end_time;
        bool is_locked;
        bool exists;
    }

    struct USER {
        uint luck;
        uint luck_factor;
        mapping(uint => STAKE_TOKEN_SLOT) staking_slot;
        uint last_stake_slot;
        // Intelligent time tracking to avoid exploitations
        uint last_mint_timestamp;
        uint last_buy_timestamp;
        uint last_sell_timestamp;
        // staking
        uint total_stake;
        bool is_staking;
    }

    mapping(address => USER) public users;
    uint public total_lucks;

    struct NFT_Extended {
        uint rarity;
        bytes32[] attributes;
    }

    mapping(uint => NFT_Extended) public nft_properties;

    uint public rares = 30;
    uint public particulars = 70;
    uint public uncommon = 140;
    uint public common = 760;

    uint cooldown_time = 6 hours;

    /* -----------------------------------------------------
                       Linking to Fluidity
    ----------------------------------------------------- */ 

    address public NFT_Token;
    address public ERC20_Token;
    IERC20 TOKEN;
    IERC721E NFT;

    /* -----------------------------------------------------
                       Linking to Extensions
    ----------------------------------------------------- */ 

    // General extension switch
    bool public are_extensions_enabled = false;
    address public extensions;
    FluidExtension ext;
    

    /* -----------------------------------------------------
                            Constructor
    ----------------------------------------------------- */ 

    constructor(){
        owner = msg.sender;
        is_auth[owner] = true;

    }

    
    function manual_set_TOKEN(address tkn) external onlyAuth {
        ERC20_Token = tkn;
        TOKEN = IERC20(ERC20_Token);
        TOKEN.set_fluid(address(this));

        is_auth[ERC20_Token] = true;
    }

    function manual_set_NFT(address nft) external onlyAuth {
        NFT_Token = nft;
        NFT = IERC721E(nft);
        NFT.set_fluid(address(this));

        is_auth[NFT_Token] = true;
    }

    /* -----------------------------------------------------
                    Fundamental Algohoritms
    ----------------------------------------------------- */ 

    /// @dev Recalculate luck factor based on swapping operations
    function luck_recalculation_from_erc20(address actor) internal {
        // Sell and buy luck refactor logic
        uint player_luck = users[actor].luck;
        if(!(total_lucks==0)) {
            total_lucks -= player_luck;
        }
        player_luck = TOKEN.balanceOf(actor);
        total_lucks += player_luck;
        users[actor].luck = player_luck;
    }

    /// @dev Recalculate the luck factor based on nft movements
    function luck_recalculation_from_erc721(uint8 operation, uint id, address actor) internal {

    }

    /// @dev This function is used to get the rarity of a mint based on luck value and randomness
    // @param actor The actor doing the operation
    function liquid_extractor(address actor) public view override returns(uint rarity){
        // Random calculation as per rarity probabilities
        uint r = randomness(1, 1000);
        uint calculated_rarity;
        if(r < rares) {
            calculated_rarity = 4; // Rares
        } else if((r >= rares) && (r < particulars)) {
            calculated_rarity = 3; // Particulars
        } else if((r >= particulars) && (r < uncommon)) {
            calculated_rarity = 2; // Uncommon
        } else if(r > uncommon) {
            calculated_rarity = 1; // Common
        }
        uint local_luck = users[actor].luck;
        // Staking bonus
        if(users[msg.sender].is_staking) {
            uint total_balance = TOKEN.balanceOf(msg.sender);
            uint total_staked = users[msg.sender].total_stake;
            uint bonus = (100*total_staked)/total_balance;
            local_luck += (bonus/4);
        }
        // Factor of luck based on % on total lucks
        uint luck_factor;
        if(total_lucks ==0) {
            luck_factor = 50;
        } else {
            luck_factor = (100*users[actor].luck)/total_lucks;
        }
        // Random probability of increasing rarity level based on luck factor
        uint rf = randomness(1,100);
        if(rf < luck_factor) {
            calculated_rarity += 1;
        }
        // Can't be more than rare
        if(calculated_rarity > 4) {
            calculated_rarity = 4;
        }
        return calculated_rarity;
    }

    function randomness(uint min, uint max) internal view returns(uint r){
        // Random 1-1000
        uint t_supply = NFT.totalSupply();
        uint seed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, t_supply))) % (max-1);
        uint randomnumber = seed + (min);
        return randomnumber;
    }

    /* -----------------------------------------------------
                         Extensibility
    ----------------------------------------------------- */ 

    /*
        Controls
    */

    function toggle_extensions(bool enabled) public onlyAuth {
        are_extensions_enabled = enabled;
    }

    function set_extensions(address extensions_) public onlyAuth {
        extensions = extensions_;
        ext = FluidExtension(extensions);
    }


    /* -----------------------------------------------------
                         Write Methods
    ----------------------------------------------------- */ 

    function set_cooldown_time(uint cooldown_) public onlyAuth {
        cooldown_time = cooldown_;
    }

    /*
        Staking
    */

    function stake_tokens(uint quantity) public safe override returns(uint slot) {
        require(TOKEN.balanceOf(msg.sender) >= quantity, "404");
        TOKEN.transferFrom(msg.sender, address(this), quantity);
        uint last_stake_slot  = users[msg.sender].last_stake_slot;
        users[msg.sender].staking_slot[last_stake_slot].quantity = quantity;
        users[msg.sender].staking_slot[last_stake_slot].starting_time = block.timestamp;
        users[msg.sender].staking_slot[last_stake_slot].lock_end_time = block.timestamp + 7 days;
        users[msg.sender].staking_slot[last_stake_slot].is_locked = true;
        users[msg.sender].staking_slot[last_stake_slot].exists = true;
        // Staking tracking
        users[msg.sender].total_stake += quantity;
        if(users[msg.sender].total_stake > (10**18)) {
            users[msg.sender].is_staking = true;
        }
        on_stake_tokens(msg.sender, quantity);
        last_stake_slot +=1;
        return last_stake_slot-1;
    }

    function unstake_tokens(uint slot) public safe override {
        STAKE_TOKEN_SLOT memory staking_slot = users[msg.sender].staking_slot[slot];
        require(staking_slot.exists, "404");
        require(staking_slot.lock_end_time <= block.timestamp || (!staking_slot.is_locked), "403");
        require(TOKEN.balanceOf(address(this)) >= staking_slot.quantity, "401");
        TOKEN.transfer(msg.sender, staking_slot.quantity);
        // Staking tracking
        users[msg.sender].total_stake -= staking_slot.quantity;
        if(users[msg.sender].total_stake <= (10**18)) {
            users[msg.sender].is_staking = false;
        }
        on_unstake_tokens(msg.sender, slot);
        delete users[msg.sender].staking_slot[slot];
    }

    /*
        Rarity
    */

    function set_nft_rarity(uint id, uint rarity) public override onlyAuth {
        nft_properties[id].rarity = rarity;
    }


    function set_probabilities(uint _rare, uint _particular, uint _uncommon) public override onlyAuth {
        require(((_rare > _particular) && (_particular > _uncommon)) && 
                ((_rare + _particular + _uncommon) < 999), "500"); 
        rares = _rare;
        particulars = _particular;
        uncommon = _uncommon;
        common = 1000 - (_rare+_particular+_uncommon);
    }

    /*
        On events
    */

    function on_transfer(address _from, address _to, uint quantity, bool is_buy, bool is_sell, bool is_transfer) public override onlyAuth {
        if(are_extensions_enabled) {
            bool skip = ext.delegated_on_transfer( _from,
                                                   _to, 
                                                   quantity, 
                                                   is_buy, 
                                                   is_sell, 
                                                   is_transfer) ;
            if(skip) {
            return;
            }
        }


    }

    function on_nft_transfer(address _from, address _to, uint id) public override onlyAuth {
        if(are_extensions_enabled) {
            bool skip = ext.delegated_on_nft_transfer(_from, _to, id);
            if(skip) {
                return;
            }
        }
    }

    function on_nft_minting(address _from, uint quantity, uint starting_id) public override onlyAuth {
        if(are_extensions_enabled) {
            bool skip = ext.delegated_on_minting(_from, quantity, starting_id);
            if(skip) {
                return;
            }
        }
        if(!(_from==NFT_Token) && !(_from==ERC20_Token)) {
            luck_recalculation_from_erc20(_from);
            uint luck_result = liquid_extractor(_from);
            set_nft_rarity(starting_id+1, luck_result);
            users[_from].last_mint_timestamp = block.timestamp;
        }
    }

    /* -----------------------------------------------------
                     Internal Write Methods
    ----------------------------------------------------- */ 

    function on_stake_tokens(address _from, uint quantity) internal {

    }

    function on_unstake_tokens(address _from, uint slot) internal {

    }

    /* -----------------------------------------------------
                         Read Methods
    ----------------------------------------------------- */ 

    function get_nft_rarity(uint id) public view override returns (uint rarity) {
        return nft_properties[id].rarity;
    }

    function get_nft_onchain_attributes(uint id) public view override returns (bytes32[] memory attributes_) {
        return nft_properties[id].attributes;
    }

    function get_luck(address recipient) public view override returns (uint luck) {
        return users[recipient].luck;
    }
    
    function set_luck(address recipient, uint _luck) public override onlyAuth {
        uint current_luck = users[recipient].luck;
        if(total_lucks >= users[recipient].luck) {
            total_lucks -= current_luck;
        }
        else {
            total_lucks = 0;
        }
        users[recipient].luck = _luck;
        total_lucks += _luck;
    }

    function get_stake_status(address actor) public view override returns (uint total, bool is_it) {
        return(users[actor].total_stake, users[actor].is_staking);
    }

    function get_probabilities() public view override returns (uint rare_, uint particular_, uint uncommon_, uint common_) {
        return(rares,particulars,uncommon,common);
    }


    function get_all_lucks() public view override returns (uint all_lucks) {
        return total_lucks;
    }

}