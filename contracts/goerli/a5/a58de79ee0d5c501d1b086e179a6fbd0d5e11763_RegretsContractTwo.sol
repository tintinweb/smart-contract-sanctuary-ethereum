/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract  RegretsContractTwo {
    address payable public casino_bank_address;
    uint public bank_balance; 
    uint public max_lay;
    uint public min_lay; 
    uint public max_payout;
    bool locked;
    
    struct Player_game_details {
        uint level;
        uint lay_amount;
        uint card_choice_one;
        uint card_choice_two;
        string last_game_status;
    }

    mapping (address => Player_game_details) public player_progress;
    
    mapping(address => bool) white_list_mapping;
    
    constructor () payable {
        casino_bank_address = payable(msg.sender);
        white_list_mapping[msg.sender] = true;
        require(msg.value > 0, "bank can not start empty.");
        bank_balance = msg.value;
        adjust_table_rates();
        show_min_max_lays();
    }

    function load_game() public view returns(uint, uint, uint, uint, string memory) {
        return (player_progress[msg.sender].lay_amount, player_progress[msg.sender].level, player_progress[msg.sender].card_choice_one, player_progress[msg.sender].card_choice_two, player_progress[msg.sender].last_game_status);
    }

    function progress_game(uint _input_choice) stopRecursion public payable returns(string memory, uint256) {
        require(validate_choice(_input_choice), "incorrect input for this round");
        if(player_progress[msg.sender].level == 0) {
            require(msg.value >= min_lay && msg.value <= max_lay, "bet is out of bounds");
            player_progress[msg.sender].lay_amount = msg.value;
            bank_balance += msg.value;
        }
        else {
            require(msg.value == 0 , "betting is for first round only");
        }
        uint generated_random_int = generateRandomNumber(_input_choice +1);
        if(generated_random_int == _input_choice) {
            if(player_progress[msg.sender].level == 2) {
                settle_bet(true, msg.sender);
                return("You won the jackpot!", generated_random_int);
            }
            if(player_progress[msg.sender].level == 1) {
                player_progress[msg.sender].card_choice_two = _input_choice;
                player_progress[msg.sender].level++;
                player_progress[msg.sender].last_game_status = "LEVEL 2";
                return("You are through to round 3", generated_random_int);
            }
            if(player_progress[msg.sender].level == 0) {
                player_progress[msg.sender].card_choice_one = _input_choice;
                player_progress[msg.sender].level++;
                player_progress[msg.sender].last_game_status = "LEVEL 1";
                return("You are through to round 2", generated_random_int);
            }        
        } 
        else {
            settle_bet(false, msg.sender);
            return("you lost", generated_random_int);            
        }
    }

    function settle_bet(bool _player_wins, address _winner_address) private {
        if(_player_wins) {
            payable(_winner_address).transfer(player_progress[_winner_address].lay_amount * 24);
            bank_balance -= player_progress[_winner_address].lay_amount * 24;
            player_progress[_winner_address].last_game_status = "WIN";
        }
        else {
            player_progress[_winner_address].last_game_status = "REKT";
        }
        player_progress[_winner_address].level = 0;
        player_progress[_winner_address].lay_amount = 0;
        adjust_table_rates();
    }

    function validate_choice(uint _choice) internal view returns(bool) {
        if(player_progress[msg.sender].level == 0) {
            assert(_choice > 0 || _choice < 3);
        }
        if(player_progress[msg.sender].level == 1) {
            assert(_choice > 0 || _choice < 4);
        }
        if(player_progress[msg.sender].level == 2) {
            assert(_choice > 0 || _choice < 5);
        }
        return true;         
    }

    modifier stopRecursion {
        require(locked == false, "No recursive calls.");
        locked = true;
        _;
        locked = false;
    }

    function show_min_max_lays() public view returns(string memory, uint, string memory, uint) {
        return("min lay: ",min_lay, " max lay : ", max_lay);
    }

    function adjust_table_rates() internal {
        max_lay = (bank_balance / 24) / 24;
        min_lay = max_lay / 10;
        max_payout = bank_balance / 24; 
    }

    function top_up_bank() public payable stopRecursion {
        require(check_sender_on_whitelist(msg.sender), "not authorised to top up bank");
        bank_balance += msg.value;
    }
 
    function bank_withdraw(uint _withdraw_amount) public stopRecursion{
        require(check_sender_on_whitelist(msg.sender), "not authorised to top up bank");
        require(_withdraw_amount < bank_balance, "Insufficient funds.");
        payable(msg.sender).transfer(_withdraw_amount);
        bank_balance -= _withdraw_amount;
        adjust_table_rates();
    }

    function show_bank_balance() public view returns(uint) {
        return bank_balance;
    }
    
    function generateRandomNumber(uint _range_upper) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % _range_upper;
    }
    
    function add_to_whitelist(address payable _new_whitelist_member) public returns(string memory){
        require(check_sender_on_whitelist(msg.sender), "Sender not authorised to add to whitelist.");
        require(check_sender_on_whitelist(_new_whitelist_member) == false, "Member already on whitelist.");        
        white_list_mapping[_new_whitelist_member] = true;
        return("new member successsfully added to white list");
    }

    function check_sender_on_whitelist(address _address_to_check) internal view returns(bool) {
        if(white_list_mapping[_address_to_check] == true) {
            return true;
        }
        else {
            return false;
        }
    }

}