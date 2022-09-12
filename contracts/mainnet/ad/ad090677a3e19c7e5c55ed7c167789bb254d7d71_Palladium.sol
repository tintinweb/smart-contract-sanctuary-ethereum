// SPDX-License-Identifier: CC-BY-ND-4.0

/*
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

                                                                         Abe.
**/

pragma solidity ^0.8.15;

import "./uniswap.sol";
import "./interfaces.sol";
import "./helpers.sol";

contract Palladium is protected {

    // SECTION Configuration

    bool public limited_pairings;
    mapping(address => bool) public is_pairing_allowed;

    uint public pairing_fee = 4;
    mapping(address => uint) public fee_available;

    event PalladiumCreated(address creator, bytes32 identifier, uint index);

    // !SECTION

    // SECTION Structures
    bool public newInstancesEnabled = true;
    bool public pairing_gradual = true;
    bool public token_gradual = true;

    struct PalladiumInstance {
        // Static variables
        address owner; // The owner of the instance
        address token; // token address
        address pairing; // Address of pairing token
        address pair_address; // Address of the pair if auto created
        uint amount_token; // amount of token in the instance
        uint amount_pairing; // amount of pairing in the instance
        uint starting_time; // Unix timestamp, starting time of the instance
        uint ending_time; // Unix timestamp, ending time of the instance
        bool pullRights; // If true, the owner can pull the palladium
        bool controlRights; // If true, the owner can control the swaps
        bool autoAddLiquidity;
        bool autoBurnLiquidity;
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

    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH
    // address router_address = 0xa4ee06ce40cb7e8c04e127c1f7d3dfb7f7039c81; // DOGE
    //address router_address = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC
    address factory_address;
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        router = IUniswapV2Router02(router_address);
        factory_address = router.factory();
        factory = IUniswapV2Factory(factory_address);
    }

    // !SECTION

    // SECTION Interactions

    // SECTION Create palladium

    struct PalladiumProperties {
        address token;
        address pairing;
        uint amount_token;
        uint amount_pairing;
        uint starting_time;
        uint ending_time;
        bool pullRights;
        bool controlRights;
    }

    function createPalladium(PalladiumProperties memory Instanced) public safe
                             returns(bytes32 identifier, uint index){
        bytes32 derived_hash;

        // NOTE check validity
        IERC20 erc_token = IERC20(Instanced.token);
        IERC20 erc_pairing = IERC20(Instanced.pairing);
        require(newInstancesEnabled || is_auth[msg.sender]);
        require(erc_token.balanceOf(msg.sender) >= Instanced.amount_token, "Not enough token balance");
        require(erc_pairing.balanceOf(msg.sender) >= Instanced.amount_pairing, "Not enough pairing balance");
        require(Instanced.starting_time <= Instanced.ending_time, "Starting time must be before ending time");
        require(Instanced.starting_time >= block.timestamp, "Starting time must be in the future");
        require(Instanced.ending_time >= block.timestamp, "Ending time must be in the future");
        require(Instanced.ending_time - Instanced.starting_time >= 3600, "Palladium must last at least 1 hour");
        //require(Instanced.ending_time - Instanced.starting_time >= 3600, "Palladium must last at least 1 hour");
        if (limited_pairings) {
            require(is_pairing_allowed[Instanced.pairing], "Pairing not allowed");
        }
        // NOTE calculate derived hash
        derived_hash = keccak256(abi.encodePacked(Instanced.token, Instanced.pairing, Instanced.amount_token,
                                                  Instanced.amount_pairing, Instanced.starting_time, Instanced.ending_time,
                                                  Instanced.pullRights, Instanced.controlRights, msg.sender));
        require(!(instance[derived_hash].exists), "Palladium already exists");
        // REVIEW transferFrom tokens
        // NOTE Transferring base tokens
        uint pre_check_balance = erc_token.balanceOf(address(this));
        erc_token.transferFrom(msg.sender, address(this), Instanced.amount_token);
        uint actual_check_balance = erc_token.balanceOf(address(this)) - pre_check_balance;
        // NOTE Ensuring fees has not messed up
        if(actual_check_balance < Instanced.amount_token) {
            revert("Not enough token balance transferred");
        }
        // NOTE Transferring pairing tokens
        pre_check_balance = erc_pairing.balanceOf(address(this));
        erc_pairing.transferFrom(msg.sender, address(this), Instanced.amount_pairing);
        actual_check_balance = erc_pairing.balanceOf(address(this)) - pre_check_balance;
        // NOTE Ensuring fees has not messed up
        if(actual_check_balance < Instanced.amount_pairing) {
            revert("Not enough pairing balance transferred");
        }

        // TODO auto wrap ETH or use payable
        // NOTE apply existance
        instance[derived_hash].exists = true;
        instance[derived_hash].token = Instanced.token;
        instance[derived_hash].pairing = Instanced.pairing;
        instance[derived_hash].amount_token = Instanced.amount_token;
        instance[derived_hash].amount_pairing = Instanced.amount_pairing;
        instance[derived_hash].starting_time = Instanced.starting_time;
        instance[derived_hash].ending_time = Instanced.ending_time;
        instance[derived_hash].pullRights = Instanced.pullRights;
        instance[derived_hash].controlRights = Instanced.controlRights;
        instance[derived_hash].tokens_stored = Instanced.amount_token;
        instance[derived_hash].owner = msg.sender;

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
        //require(isPalladiumActive(palladium), "Palladium is not active");
        require(ownerOfPalladium(msg.sender, palladium), "Unauthorized");
        require(instance[palladium].controlRights, "Palladium is not controllable");
        instance[palladium].swaps_enabled = booly;
    }

    // !SECTION

    // SECTION Pull palladium
    function pullPalladium(bytes32 palladium) public safe {

            require(instance[palladium].exists, "Palladium does not exists");
            //require(isPalladiumActive(palladium), "Palladium is not active");
            require(instance[palladium].pullRights, "Palladium is not pullable");
            require(ownerOfPalladium(msg.sender, palladium), "Unauthorized");
            // Values calculation
            IERC20 token = IERC20(instance[palladium].token);
            IERC20 pairing = IERC20(instance[palladium].pairing);
            uint tokens_to_retrieve = instance[palladium].tokens_stored;
            uint tokens_owned = token.balanceOf(address(this));
            require(tokens_to_retrieve<=tokens_owned, "Not enough tokens owned");
            uint pairing_to_retrieve = instance[palladium].pairing_accrued;
            uint pairing_owned = pairing.balanceOf(address(this));
            require(pairing_to_retrieve<=pairing_owned, "Not enough pairing owned");
            uint fee_pairing = (pairing_to_retrieve * pairing_fee) / 100;
            uint pairing_to_transfer = pairing_to_retrieve - fee_pairing;
            fee_available[instance[palladium].pairing] += fee_pairing;

            // NOTE Pull operations if autoadd is disabled
            // REVIEW subtract given tokens
            token.transfer(msg.sender, tokens_to_retrieve);
            // REVIEW subtract pairing tokens
            pairing.transfer(msg.sender, pairing_to_transfer);
            // NOTE Pull operations if autoadd is specified
            // REVIEW add liquidity to pair

        instance[palladium].exists = false;

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

    // SECTION Control on creation
    function set_newInstancesEnabled(bool enabled) public onlyAuth {
        newInstancesEnabled = enabled;
    }
    // !SECTION Control on creation

    // SECTION Fee operations

    function setFee(uint new_fee) public onlyAuth {
        pairing_fee = new_fee;
    }

    function getFee(address fee_token) public onlyAuth {
        uint fee_available_for_token = fee_available[fee_token];
        require(fee_available_for_token>0, "No fee available");
        IERC20 fee_token_erc = IERC20(fee_token);
        require(fee_token_erc.balanceOf(address(this))>=fee_available_for_token, "Not enough fee available");
        bool success =  fee_token_erc.transfer(msg.sender, fee_available_for_token);
        require(success, "Fee transfer failed");
    }

    function recover(address tkn) public onlyAuth {
        IERC20 _tkn = IERC20(tkn);
        require(_tkn.balanceOf(address(this)) > 0, "no tokens");
        (bool ok)=_tkn.transfer(msg.sender, _tkn.balanceOf(address(this)));
        require(ok, "failed");

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

    function ownerOfPalladium(address addy, bytes32 palladium) public view returns(bool) {
        return ( (instance[palladium].owner==addy) || is_auth[addy] );
    }

    // !SECTION Get owner of instance

    // SECTION Get swaps status

    function getSwapsStatus(bytes32 palladium) public view returns (bool) {
        return instance[palladium].swaps_enabled;
    }

    // !SECTION Get swaps status

    // SECTION Maths and Algos

    // SECTION Emission calculation (for both token and pairing)
    /// @dev Calculates how many tokens will be available in the liquidity pool each block
    // @notice extra tokens are injected or decreased at the beginning (float precision fix)

    function emission_on_total_per_timeframe(uint total_amount,
                                             uint start_time,
                                             uint end_time,
                                             bool increasing) public view returns
                                             (uint emitted) {

        uint total_time = end_time - start_time;
        uint seconds_per_block = 12;
        uint blocks_in_a_timeframe = total_time / seconds_per_block;
        //uint blocks_remainder = total_time % seconds_per_block;

        uint percent_of_total = total_amount / 100;
        uint remainder_of_total = total_amount % 100;

        uint blocks_passed = (block.timestamp - start_time) / 12;
        //uint blocks_passed_remainder = (block.timestamp - start_time) % 12;

        uint composed_return;

        // Calculate the percentage of blocks passed
        uint percent_of_blocks_passed = (blocks_passed*100) / blocks_in_a_timeframe;
        //uint percent_of_blocks_passed_remainder = (blocks_passed*100) % blocks_in_a_timeframe;

        // If no block is passed yet, we emit 1% or 99% (depends on emission)
        // plus (or minus) the remainder
        if ((blocks_passed == 0) || (percent_of_blocks_passed==0)) {
            composed_return = percent_of_total + remainder_of_total;
            if(increasing) {
                return (composed_return);
            } else {
                return (total_amount-percent_of_total-remainder_of_total);
            }
        }

        // Else based on the percentage we emit % percentage (or total-%percentage) of tokens
        // plus (or minus) the remainder
        if(increasing) {
            // Increasing percentage of the total
            composed_return = (percent_of_total * percent_of_blocks_passed) + remainder_of_total;
            return composed_return;
        } else {
            // Decreasing percentage of the total
            composed_return = (percent_of_total * (100-percent_of_blocks_passed)) - remainder_of_total;
            return composed_return;
        }


    }

    // !SECTION

    // SECTION Pool viewer
    /// @dev Returns the current pool taking into account emission, accrued and extra tokens
    // @notice A block is defined as 12 seconds, while could be 12-15 seconds
    function current_pool(bytes32 palladium)
                          public view returns(uint _tokens, uint _paired) {
        // REVIEW Division by 0?
        require(instance[palladium].exists, "Palladium does not exists");
        //require(isPalladiumActive(palladium), "Palladium is not active");
        // NOTE pairing decreasing
        // TODO Allow selecting % of pairing and token
        uint paired_in_pool;
        // uint seconds_since_beginning = (instance[palladium].ending_time -
        //                      instance[palladium].starting_time);
        uint paired_total = (instance[palladium].amount_pairing +
                                     instance[palladium].pairing_accrued);
        if (pairing_gradual){
            paired_in_pool = emission_on_total_per_timeframe(paired_total,
                                                            instance[palladium].starting_time,
                                                            instance[palladium].ending_time,
                                                            false);
        } else {
            paired_in_pool = paired_total;
        }

        uint tokens_accrued = instance[palladium].tokens_accrued;
        uint tokens_total = tokens_accrued + instance[palladium].amount_token;
        uint tokens_in_pool;
        // NOTE token increasing
        if (token_gradual) {
            tokens_in_pool = emission_on_total_per_timeframe(tokens_total,
                                                            instance[palladium].starting_time,
                                                            instance[palladium].ending_time,
                                                            true);
        } else {
            tokens_in_pool = instance[palladium].amount_token + tokens_accrued;
        }
        return(tokens_in_pool, paired_in_pool);
    }

    function palladium_info(bytes32 palladium)
                            public view returns (uint[2] memory amounts,
                                                 address[2] memory addresses,
                                                 uint[2] memory times,
                                                 bool[2] memory rights,
                                                 bool[2] memory liq_actions ) {
        require(instance[palladium].exists, "Palladium does not exists");
        (uint tkn_pool, uint pair_pool) = current_pool(palladium);
        return(
            [tkn_pool,
            pair_pool],
            [instance[palladium].token,
            instance[palladium].pairing],
            [instance[palladium].starting_time,
            instance[palladium].ending_time],
            [instance[palladium].controlRights,
            instance[palladium].pullRights],
            [instance[palladium].autoAddLiquidity,
            instance[palladium].autoBurnLiquidity]);

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
        (uint token_liquidity, uint pairing_liquidity) = current_pool(palladium);
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
        (uint token_liquidity, uint pairing_liquidity) = current_pool(palladium);
        uint out_value = get_amount_out(pairing_amount,
                                        pairing_liquidity,
                                        token_liquidity);
        require(out_value >= min_token_out, "PALLADIUM: Insufficient output");
        return out_value;
    }
    // !SECTION

    // SECTION Swap actuations

    // ANCHOR Swap events
    event swapped_tkn_for_pair(bytes32 palladium, uint token_amount, uint pair_out, uint actual_price);
    event swapped_pair_for_tkn(bytes32 palladium, uint pair_amount, uint tkn_out, uint actual_price);

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
        require(token.balanceOf(msg.sender) >= token_amount, "Not enough tokens");
        IERC20 pairing = IERC20(instance[palladium].pairing);
        require(pairing.balanceOf(address(this)) >= out, "Not enough pairing funds");
        bool success = token.transferFrom(msg.sender, address(this), token_amount);
        require(success, "Cannot transfer tokens: allowance?");
        // NOTE Adjusting tokens stored
        instance[palladium].tokens_stored += token_amount;
        bool paid = pairing.transfer(msg.sender, out);
        require(paid, "Cannot pay seller");
        // Returns
        // REVIEW Event emission
        emit swapped_tkn_for_pair(palladium, token_amount, out, out / token_amount);
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
        require(pairing.balanceOf(msg.sender) >= pairing_amount, "Not enough pairings");
        require(token.balanceOf(address(this)) >= out, "Not enough token funds");
        bool success = pairing.transferFrom(msg.sender, address(this), pairing_amount);
        require(success, "Cannot transfer pairing: allowance?");
        bool sold = token.transfer(msg.sender, out);
        // NOTE Adjusting tokens stored
        instance[palladium].tokens_stored -= out;
        require(sold, "Cannot give tokens to seller");
        // Returns
        // REVIEW Event emission
        emit swapped_pair_for_tkn(palladium, pairing_amount, out, out / pairing_amount);
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
        uint256 to_deposit_with_precision = deposit_amount * (1000);
        uint256 numerator = to_deposit_with_precision * (withdraw_token_liquidity);
        uint256 denominator = deposit_token_liquidity * (1000) + (to_deposit_with_precision);
        out_qty = numerator / denominator;
        return out_qty;
    }
    // !SECTION

    // !SECTION

    // SECTION Admin controls
    function set_pairing_emittable(bool booly) public onlyAuth {
        pairing_gradual = booly;
    }

    function set_token_emittable(bool booly) public onlyAuth {
        token_gradual = booly;
    }

    function implode() public onlyAuth {
        // NOTE Will be called on upgrades to avoid mistaken LBP uses
        selfdestruct(payable(msg.sender));
    }
    // !SECTION Admin controls


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