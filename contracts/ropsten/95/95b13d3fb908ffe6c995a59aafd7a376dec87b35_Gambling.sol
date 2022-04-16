/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity ^0.8.0;

contract Gambling {

    mapping(address => uint256) public token_balances;

    uint256 public wei_pot;
    uint256 public max_wei_bet;
    uint256 public total_token_supply;

    address private owner;
    address payable winner;

    constructor () public payable {
        owner = msg.sender;
        wei_pot = msg.value;
        max_wei_bet = 1000000000000000000;
    }

    function mint() public returns (bool success) {
        token_balances[msg.sender] += 1000;
        total_token_supply += 1000;
        return true;
    }

    function check_token_balance(address interest) public returns (uint256 token_balance) {
        return token_balances[interest];
    }

    function token_gamble(uint256 bet) public returns (string memory) {

        require(token_balances[msg.sender] >= bet, "Get your tokens up"); 

        uint256 heads_tails = uint256(keccak256(abi.encodePacked(block.timestamp))) % 2;

        if (heads_tails == 1) {
            token_balances[msg.sender] += bet;
            return "You made tokens!";
        }
        else {
            token_balances[msg.sender] -= bet;
            return "You lost tokens!";
        }
    }
    
    function contract_balance() public returns (uint256 contract_pot) {
        return address(this).balance;
    }

    function deposit() public payable returns (string memory) {
        wei_pot += msg.value;
        return "thank you for the free wei, this is the wei!";
    }

    function wei_gamble() public payable returns (string memory) {

        require (address(this).balance >= msg.value, "We need more funds before the high rollers gamble with us!");

        uint256 heads_tails = uint256(keccak256(abi.encodePacked(block.timestamp))) % 2;

        if (heads_tails == 1) {
            winner = payable(msg.sender);
            winner.transfer(msg.value * 2);
            wei_pot -= msg.value;
            return "You made wei!";
        }
        else {
            wei_pot += msg.value;
            return "You lost wei!";
        }
    }
}