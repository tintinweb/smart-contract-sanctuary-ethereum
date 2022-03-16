/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8.12;

contract Lottery {
    address private owner;
    uint256 public minAmount;

    mapping(address => uint256) public amountDonated;
    address[] public contestents;

    constructor(uint256 _minAmount) {
        owner = msg.sender;
        minAmount = _minAmount;
    }

    function donate() public payable {
        require(
            msg.value >= minAmount,
            "Min amount should be greater than the set value!!"
        );
        if (amountDonated[msg.sender] == 0) {
            contestents.push(msg.sender);
        }
        amountDonated[msg.sender] += msg.value;
    }

    function setMinAmount(uint256 _minAmount) public onlyOwner {
        minAmount = _minAmount;
    }

    function electWinner(uint256 _random) public onlyOwner {
        uint256 randInt = (contestents.length % _random);
        randInt = randInt == contestents.length ? --randInt : randInt;
        payable(contestents[randInt]).transfer(address(this).balance);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner required");
        _;
    }

    // for getting money directly to smart contract
    receive() external payable {
        if (amountDonated[msg.sender] == 0) {
            contestents.push(msg.sender);
        }
        amountDonated[msg.sender] += msg.value;
    }
}