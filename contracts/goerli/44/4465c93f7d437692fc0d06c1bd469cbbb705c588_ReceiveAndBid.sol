/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity ^0.4.26;

contract ReceiveAndBid {
    address owner;
    mapping (address => uint256) balances;

    constructor() public {
        owner = msg.sender;
    }

    function() public payable
    {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "No balance under your address.");
        require(balances[owner] >= balances[msg.sender], "Not enough balance under Dealer.");
        require(address(this).balance > 0, "No balance under this Contract.");
        require(address(this).balance >= balances[msg.sender], "Not enouth balance under this Contract");
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function bid(uint256 amount) public {    

        require(amount <= balances[msg.sender], "No enough balance to bid.");
        require(amount <= balances[owner], "Sorry, Deal don't have enought fund to continue this bid.");

        uint256 randomResult = uint256(keccak256(abi.encodePacked(now, msg.sender))) % 2;

        if (randomResult == 0) {
            balances[msg.sender] -= amount;      
            balances[owner] += amount;
            emit BidFailed(msg.sender, "You Lose", amount, balances[msg.sender]);
        } else {
            uint256 winAmount = amount * 9 / 10;
            balances[msg.sender] += winAmount;      
            balances[owner] -= winAmount;
            emit BidSuccess(msg.sender, "You Win", winAmount, balances[msg.sender]);
        }
    }


    function getBalance() public view returns (uint256) {
        require( balances[msg.sender] > 0, "You have not balance or address was not in the array.");
        return balances[msg.sender];
    }

    event BidSuccess(address indexed bidder, string result, uint256 winAmount, uint256 balances);
    event BidFailed (address indexed bidder, string result, uint256 amount, uint256 balances);
}