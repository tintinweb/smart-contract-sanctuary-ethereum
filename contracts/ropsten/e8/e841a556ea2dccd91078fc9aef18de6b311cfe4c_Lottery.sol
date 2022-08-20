/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Lottery {
    enum Status {
        Pending,
        Open,
        Close,
        Claimeable
    }

    struct Ticket {
        address payable owner;
        uint16 position;
        uint256 reward;
        bool paid;

    }
    uint24 private constant MAX_VALUE = 99999;
    uint24 private constant MIN_VALUE = 0;
    
    address payable public ownerAddress;
    uint256 public ticketPrice = 25000000000000000;
    uint256 public amountCollected;
    uint256 public ticketsSold;
    uint24[] finalNumbers;
    mapping(uint24 => Ticket) private tickets;
    mapping(address => uint24[]) private ticketsByUser;
    Status lotteryStatus;

    constructor() {
        ownerAddress = payable(msg.sender);
    }

    function openLottery() public onlyOwner {
        lotteryStatus = Status.Open;
    }

    function closeLottery() public onlyOwner {
        lotteryStatus = Status.Close;
    }

    function getTicketPrice() public view returns(uint256) {
        return ticketPrice;
    }

    function setTicketPrice(uint256 _price) public onlyOwner {
        require(_price > 0, "Price must be grater than 0");

        ticketPrice = _price; 
    }

    function getWinner(uint24[] memory _numbers) public {
        //require(_numbers.length == 500, "Length must be 10");

        finalNumbers = _numbers;
        uint16 i;
        uint256 amount;

        amount = amountCollected / 100;
        amount *= 20;

        for(i = 0; i < _numbers.length; i++) {
            if (tickets[_numbers[i]].owner == address(0)) continue;

            tickets[_numbers[i]].position = i + 1;

            if (tickets[_numbers[i]].position == 1) {
                tickets[finalNumbers[i]].reward = amount;

            } else if (tickets[_numbers[i]].position <= 5) {
                tickets[finalNumbers[i]].reward = amount / 5;

            } else if (tickets[_numbers[i]].position <= 10) {
                tickets[finalNumbers[i]].reward = amount / 4;

            } else if (tickets[_numbers[i]].position <= 20) {
                tickets[finalNumbers[i]].reward = amount / 10;

            } else {
                tickets[finalNumbers[i]].reward = amount / 480;

            }
        }

        lotteryStatus = Status.Claimeable;
    }

    function payReward() public onlyOwner {
        require(lotteryStatus == Status.Claimeable, "Lottery isn't claimeable");

        for(uint16 i = 0; i < finalNumbers.length; i++) {
            if (tickets[finalNumbers[i]].owner == address(0)) continue;
            if (tickets[finalNumbers[i]].paid) continue;

            tickets[finalNumbers[i]].owner.transfer(tickets[finalNumbers[i]].reward);
            tickets[finalNumbers[i]].paid = true;
        }
    }

    function buyTicket(uint24 number) public payable {
        require(lotteryStatus == Status.Open, "Lottery isn't open");
        require(tickets[number].owner == address(0), "Number has been taken by another user");
        require(msg.value == ticketPrice, "Price invalid");
        require(number >= MIN_VALUE && number <= MAX_VALUE, "Out of range");
        
        tickets[number].owner = payable(msg.sender);
        ticketsByUser[msg.sender].push(number);

        ticketsSold += 1;
        ownerAddress.transfer(msg.value / 100);
    }

    function viewTicketsByUsers(address user) public view returns(uint24[] memory) {
        return ticketsByUser[user];
    }

    function viewTicket(uint24 numero) public view returns(Ticket memory) {
        return tickets[numero];
    }

    function getFinalNumbers() public view returns(uint24[] memory) {
        return finalNumbers;
    }
    function getAllBalance() public onlyOwner {
        ownerAddress.transfer(address(this).balance);
    }
    
    modifier onlyOwner {
        require(
            msg.sender == ownerAddress,
            "Not owner");
        _;
    }
}