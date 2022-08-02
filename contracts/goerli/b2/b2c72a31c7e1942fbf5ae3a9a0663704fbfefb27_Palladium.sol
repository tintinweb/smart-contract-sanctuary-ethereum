// SPDX-License-Identifier: CC-BY-ND-4.0

/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@    Palladium                                               @@@@@@@@@@
@@@@@@@@@@    Liquidity                                               @@@@@@@@@@
@@@@@@@@@@    Bootstrapping                                           @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                     %%%%%#.         [email protected]%                    @@@@@@@@@@
@@@@@@@@@@                     @@    &@,       ,@%                    @@@@@@@@@@
@@@@@@@@@@                     @@    (@* [email protected]@@&@@@%                    @@@@@@@@@@
@@@@@@@@@@                     @@@@@@&   &@    ,@#                    @@@@@@@@@@
@@@@@@@@@@                     @@        &@    ,@#                    @@@@@@@@@@
@@@@@@@@@@                     @@         &@@@@[email protected]#                    @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@           Palladium Liquidity Bootstrapping System         @@@@@@@@@@
@@@@@@@@@@           A modern reinterpretation of LBP concepts        @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@                                                            @@@@@@@@@@
@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


*/

pragma solidity ^0.8.15;

//import "./uniswap.sol";
import "./interfaces.sol";
import "./helpers.sol";

contract Palladium is protected {

    // SECTION Configuration

    bool public limited_pairings;
    mapping(address => bool) public is_pairing_allowed;

    event PalladiumCreated(address creator, bytes32 identifier, uint index);

    // !SECTION

    // SECTION Structures 

    struct PalladiumInstance {
        // Static variables
        address owner; // The owner of the instance
        address token; // token address
        address pairing; // Address of pairing token
        uint amount_token; // amount of token in the instance
        uint amount_pairing; // amount of pairing in the instance
        uint starting_time; // Unix timestamp, starting time of the instance
        uint ending_time; // Unix timestamp, ending time of the instance
        bool pullRights; // If true, the owner can pull the palladium
        bool controlRights; // If true, the owner can control the swaps 
        // Dynamic variables
        bool exists; // Whether the instance exists or not
        bool swaps_enabled; // Whether or not swaps are enabled for this instance
        uint pairing_accrued; // Pairing stored in the contract
        uint tokens_accrued; // Tokens emitted and stored
        uint tokens_stored; // Tokens stored in the contract
    }

    mapping (bytes32 => PalladiumInstance) instance;

    PalladiumInstance[] instances;
    mapping(bytes32 => uint) instances_index;
    uint last_index;

    bytes32[] instance_identifiers;
    mapping(bytes32 => uint) instance_identifiers_index;
    uint last_identifier_index;

    struct PalladiumBalances {
        mapping(address => mapping(address => bytes32)) instances;
        mapping(address => uint) fees;
    }

    PalladiumBalances palladium_balances;

    // !SECTION

    // SECTION Constructor

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    // !SECTION

    // SECTION Interactions

    // SECTION Create palladium
    function createPalladium(address token, address pairing,
                             uint amount_token, uint amount_pairing,
                             uint starting_time, uint ending_time,
                             bool pullRights, bool controlRights) public safe 
                             returns(bytes32 identifier, uint index){
        bytes32 derived_hash;
        
        // NOTE check validity
        IERC20 erc_token = IERC20(token);
        IERC20 erc_pairing = IERC20(pairing);
        require(erc_token.balanceOf(msg.sender) >= amount_token, "Not enough token balance");
        require(erc_pairing.balanceOf(msg.sender) >= amount_pairing, "Not enough pairing balance");
        require(starting_time <= ending_time, "Starting time must be before ending time");
        require(starting_time >= block.timestamp, "Starting time must be in the future");
        require(ending_time >= block.timestamp, "Ending time must be in the future");
        require(ending_time - starting_time >= 3600, "Palladium must last at least 1 hour");
        if (limited_pairings) {
            require(is_pairing_allowed[pairing], "Pairing not allowed");
        }
        // NOTE calculate derived hash
        derived_hash = keccak256(abi.encodePacked(token, pairing, amount_token, 
                                                  amount_pairing, starting_time, ending_time, 
                                                  pullRights, controlRights, msg.sender));
        require(!(instance[derived_hash].exists), "Palladium already exists");
        // REVIEW transferFrom tokens
        // NOTE Transferring base tokens
        uint pre_check_balance = erc_token.balanceOf(address(this));
        erc_token.transferFrom(msg.sender, address(this), amount_token);
        uint actual_check_balance = erc_token.balanceOf(address(this)) - pre_check_balance;
        // NOTE Ensuring fees has not messed up
        if(actual_check_balance < amount_token) {
            revert("Not enough token balance transferred");
        }
        // NOTE Transferring pairing tokens
        pre_check_balance = erc_pairing.balanceOf(address(this));
        erc_pairing.transferFrom(msg.sender, address(this), amount_pairing);
        actual_check_balance = erc_pairing.balanceOf(address(this)) - pre_check_balance;
        // NOTE Ensuring fees has not messed up
        if(actual_check_balance < amount_pairing) {
            revert("Not enough pairing balance transferred");
        }

        // TODO auto wrap ETH or use payable
        // NOTE apply existance
        instance[derived_hash].exists = true;
        instance[derived_hash].token = token;
        instance[derived_hash].pairing = pairing;
        instance[derived_hash].amount_token = amount_token;
        instance[derived_hash].amount_pairing = amount_pairing;
        instance[derived_hash].starting_time = starting_time;
        instance[derived_hash].ending_time = ending_time;
        instance[derived_hash].pullRights = pullRights;
        instance[derived_hash].controlRights = controlRights;
        instance[derived_hash].tokens_stored = amount_token;

        instances.push(instance[derived_hash]);
        instances_index[derived_hash] = last_index;
        last_index += 1;

        instance_identifiers.push(derived_hash);
        instance_identifiers_index[derived_hash] = last_identifier_index;
        last_identifier_index += 1;

        emit PalladiumCreated(msg.sender, derived_hash, last_index-1);
        return(derived_hash, last_index-1);
    }
    // !SECTION

    // SECTION Control swaps
    function controlSwaps(bytes32 palladium, bool booly) public safe {
        require(instance[palladium].exists, "Palladium does not exists");
        require(isPalladiumActive(palladium), "Palladium is not active");
        require(msg.sender==instance[palladium].owner, "Unauthorized");
        require(instance[palladium].controlRights, "Palladium is not controllable");
        instance[palladium].swaps_enabled = booly;
    }

    // !SECTION

    // SECTION Pull palladium
    function pullPalladium(bytes32 palladium) public safe {
        require(instance[palladium].exists, "Palladium does not exists");
        require(isPalladiumActive(palladium), "Palladium is not active");
        require(instance[palladium].pullRights, "Palladium is not pullable");
        require(msg.sender==instance[palladium].owner, "Unauthorized");
        // REVIEW Pull operations
        IERC20 token = IERC20(instance[palladium].token);
        // REVIEW subtract given tokens
        uint tokens_to_retrieve = instance[palladium].tokens_stored;
        uint tokens_owned = token.balanceOf(address(this));
        require(tokens_to_retrieve<=tokens_owned, "Not enough tokens owned");
        token.transfer(msg.sender, tokens_to_retrieve);
        IERC20 pairing = IERC20(instance[palladium].pairing);
        // REVIEW subtract pairing tokens
        uint pairing_to_retrieve = instance[palladium].pairing_accrued;
        uint pairing_owned = pairing.balanceOf(address(this));
        require(pairing_to_retrieve<=pairing_owned, "Not enough pairing owned");
        pairing.transfer(msg.sender, pairing_to_retrieve);
        
    }
    // !SECTION

    // SECTION Check palladium active status
    function isPalladiumActive(bytes32 palladium) public view returns (bool) {
        bool isActive = ( 
                        (instance[palladium].exists) && 
                        (instance[palladium].starting_time <= block.timestamp) &&
                        (instance[palladium].ending_time > block.timestamp) 
                        );
        return isActive;
    }
    // !SECTION

    // !SECTION

    // SECTION View all palladiums
    function getAllPalladiums() public view returns (bytes32[] memory) {
        return instance_identifiers;
    }

    function getPalladiumIndex(bytes32 pall_) public view returns (uint) {
        return instance_identifiers_index[pall_];
    }

    function getPalladiumTotalNumber() public view returns (uint) {
        return last_identifier_index;
    }

    // !SECTION

    // SECTION Get owner of instance
    function getPalladiumOwner(bytes32 palladium) public view returns (address) {
        return instance[palladium].owner;
    }
    
    // !SECTION Get owner of instance

    // SECTION Maths and Algos

    // SECTION Emission calculation
    /// @dev Calculates how many tokens will be available in the liquidity pool each block
    // @notice extra tokens are injected at the beginning
    function emission_per_n_blocks(uint total_amount, uint start_time, uint end_time)
                                   public pure returns(uint per_block, uint extra) {
        require(start_time < end_time, "Underflow detected");
        uint seconds_per_block = 12;
        uint seconds_total = end_time - start_time;
        uint block_number = seconds_total / seconds_per_block; 
        uint tokens_per_block = total_amount / block_number;
        uint tokens_per_block_remainder = total_amount % block_number;
        uint starting_block_extra = tokens_per_block_remainder;
        uint total_emission = tokens_per_block*block_number+(starting_block_extra);
        if(total_emission < total_amount) {
            starting_block_extra += (total_amount-total_emission);
        } else if (total_emission > total_amount) {
            starting_block_extra -= (total_emission-total_amount);
        }
        return (tokens_per_block, starting_block_extra);
    }

    // !SECTION

    // SECTION Pool viewer
    /// @dev Returns the current pool taking into account emission, accrued and extra tokens
    // @notice A block is defined as 12 seconds, while could be 12-15 seconds
    function current_pool(bytes32 palladium) 
                          public view returns(uint _tokens, uint _paired, uint _price) {
        require(instance[palladium].exists, "Palladium does not exists");
        require(isPalladiumActive(palladium), "Palladium is not active");
        uint paired_in_pool = (instance[palladium].amount_pairing + 
                                     instance[palladium].pairing_accrued);
        uint seconds_since_beginning = (instance[palladium].ending_time - 
                              instance[palladium].starting_time);
        (uint tokens_per_block, uint extra_tokens) = emission_per_n_blocks(
                                                     instance[palladium].amount_token, 
                                                     instance[palladium].starting_time, 
                                                     instance[palladium].ending_time
                                                     );
        uint tokens_accrued = instance[palladium].tokens_accrued;
        uint tokens_in_pool = (tokens_per_block*(seconds_since_beginning/12))
                               + extra_tokens + tokens_accrued;

        // TODO take in account decimals
        uint price = tokens_in_pool/paired_in_pool;
        return(tokens_in_pool, paired_in_pool, price);
    }

    function palladium_info(bytes32 palladium) 
                            public view returns (uint[2] memory amounts,
                                                 address[2] memory addresses,
                                                 uint[2] memory times,
                                                 bool[2] memory rights ) {
        require(instance[palladium].exists, "Palladium does not exists");
        return(
            [instance[palladium].amount_token,
            instance[palladium].amount_pairing],
            [instance[palladium].token,
            instance[palladium].pairing],
            [instance[palladium].starting_time,
            instance[palladium].ending_time],
            [instance[palladium].controlRights,
            instance[palladium].pullRights]);

     }

    // !SECTION

    // !SECTION

    // SECTION Swap and relative calculations

    // SECTION Swap simulations

    /// @dev Returns the result of a token sell after all the possible checks
    function simulate_swap_token_for_pairing(bytes32 palladium,
                                             uint token_amount,
                                             uint min_pairing_out) 
                                             public view returns(uint out_value_) {
        require(instance[palladium].exists, "Palladium does not exists");
        require(isPalladiumActive(palladium), "Palladium is not active");
        IERC20 token = IERC20(instance[palladium].token);
        require(token.balanceOf(msg.sender) >= token_amount, "Not enough tokens");
        (uint token_liquidity, uint pairing_liquidity, uint price) = current_pool(palladium);
        delete(price);
        uint out_value = get_amount_out(token_amount,
                                        token_liquidity,
                                        pairing_liquidity);
        require(out_value >= min_pairing_out, "PALLADIUM: Insufficient output");   
        return out_value; 
    }

    /// @dev Returns the result of a token buy after all the possible checks
    function simulate_swap_pairing_for_token(bytes32 palladium,
                                             uint pairing_amount,
                                             uint min_token_out) 
                                             public view returns(uint out_value_) {
        require(instance[palladium].exists, "Palladium does not exists");
        require(isPalladiumActive(palladium), "Palladium is not active");
        IERC20 token = IERC20(instance[palladium].pairing);
        require(token.balanceOf(msg.sender) >= pairing_amount, "Not enough tokens");
        (uint token_liquidity, uint pairing_liquidity, uint price) = current_pool(palladium);
        delete(price);
        uint out_value = get_amount_out(pairing_amount,
                                        pairing_liquidity,
                                        token_liquidity);
        require(out_value >= min_token_out, "PALLADIUM: Insufficient output");   
        return out_value; 
    }
    // !SECTION

    // SECTION Swap actuations

    /// @dev Executes a token sell using simulation and actuation
    // @notice Requires approval already settled
    function swap_token_for_pairing(bytes32 palladium,
                                    uint token_amount,
                                    uint min_pairing_out) public safe 
                                    returns (uint _out_) {
        uint out = simulate_swap_token_for_pairing
                   (palladium, token_amount, min_pairing_out);
        require(instance[palladium].swaps_enabled, "Palladium swaps are disabled");
        require(instance[palladium].pairing_accrued + 
                instance[palladium].amount_pairing 
                >= out, "Not enough liquidity");
        // Injecting new tokens in liquidity
        instance[palladium].tokens_accrued += token_amount;
        // Taking out pairing value (first from accrued) in liquidity
        uint pairing_accrued = instance[palladium].pairing_accrued;
        if(pairing_accrued >= out) {
            instance[palladium].pairing_accrued -= out;
        } else {
            uint difference = out - instance[palladium].pairing_accrued;
            instance[palladium].pairing_accrued = 0;
            instance[palladium].amount_pairing -= difference;
        }

        // Take the tokens, give the pairing
        IERC20 token = IERC20(instance[palladium].token);
        IERC20 pairing = IERC20(instance[palladium].pairing);
        require(pairing.balanceOf(address(this)) >= out, "Not enough pairing funds");
        bool success = token.transferFrom(msg.sender, address(this), token_amount);
        require(success, "Cannot transfer tokens: allowance?");
        // NOTE Adjusting tokens stored 
        instance[palladium].tokens_stored += token_amount;
        bool paid = pairing.transfer(msg.sender, out);
        require(paid, "Cannot pay seller");
        // Returns
        return(out);
    }

    /// @dev Executes a token buy using simulation and actuation
    // @notice Requires approval already settled
    function swap_pairing_for_token(bytes32 palladium,
                                    uint pairing_amount,
                                    uint min_token_out) public safe 
                                    returns (uint _out_) {
        uint out = simulate_swap_pairing_for_token
                   (palladium, pairing_amount, min_token_out);
                    
        require(instance[palladium].swaps_enabled, "Palladium swaps are disabled");
        require(instance[palladium].tokens_accrued + 
                instance[palladium].amount_token
                >= out, "Not enough liquidity");
        // Injecting new pairing in liquidity
        instance[palladium].pairing_accrued += pairing_amount;
        // Taking out token value (first from accrued) in liquidity
        uint tokens_accrued = instance[palladium].tokens_accrued;
        if(tokens_accrued >= out) {
            instance[palladium].tokens_accrued -= out;
        } else {
            uint difference = out - instance[palladium].tokens_accrued;
            instance[palladium].tokens_accrued = 0;
            instance[palladium].amount_token -= difference;
        }
        // Take the pairing, give the tokens
        IERC20 token = IERC20(instance[palladium].token);
        IERC20 pairing = IERC20(instance[palladium].pairing);
        require(token.balanceOf(address(this)) >= out, "Not enough token funds");
        bool success = pairing.transferFrom(msg.sender, address(this), pairing_amount);
        require(success, "Cannot transfer pairing: allowance?");
        bool sold = token.transfer(msg.sender, out);
        // NOTE Adjusting tokens stored 
        instance[palladium].tokens_stored -= out;
        require(sold, "Cannot give tokens to seller");
        // Returns
        return(out);
    }
    // !SECTION

    // SECTION Amount out calculator
    /// @dev Calculate the output amount given a swap
    // @param to_deposit Quantity of Token_1 to deposit in pair
    // @param to_deposit_liq Liquidity of Token_1
    // @param to_withdraw_liq Liquidity of Token_2
    function get_amount_out(
        uint256 deposit_amount,
        uint256 deposit_token_liquidity,
        uint256 withdraw_token_liquidity
    ) private pure returns (uint256 out_qty) {
        require(deposit_amount > 0, "PALLADIUM: INSUFFICIENT_INPUT_AMOUNT");
        require(
            deposit_token_liquidity > 0 && withdraw_token_liquidity > 0,
            "PALLADIUM: INSUFFICIENT_LIQUIDITY"
        );
        uint256 to_deposit_with_fee = deposit_amount * (997);
        uint256 numerator = to_deposit_with_fee * (withdraw_token_liquidity);
        uint256 denominator = deposit_token_liquidity * (1000) + (to_deposit_with_fee);
        out_qty = numerator / denominator;
        return out_qty;
    }
    // !SECTION

    // !SECTION


    // SECTION Info & Documentation
    /*****************************************************************

                    Documentation and Informations

    *****************************************************************/ 
    /*

    • You can obtain the price of a pool by calling the current_pool(palladium) method
    • Same can be done for emission per block with 
      emission_per_n_blocks(total_amount, start_time, end_time) method
    • You should pay close attention to tokens with fees as they impact the output amount
      of the various swap functions and could create problems in pulling function too

    */
    // !SECTION 

}