// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAndamanToken {
    function owner() external view returns (address);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Vault {
    struct Ticket {
        bool status;
        uint amount;
    }

    IAndamanToken public andamanToken;
    address public andamanTokenAddress;
    Ticket[] tickets;
    mapping(address => uint[]) ticketsOfUser;

    constructor(address _andamanTokenAddress) {
        andamanToken = IAndamanToken(_andamanTokenAddress);
        andamanTokenAddress = _andamanTokenAddress;
    }

    event AdminTransfer(
        address indexed to,
        address indexed adminAddress,
        uint256 amount
    );
    event HotelTransfer(
        address indexed from,
        uint indexed ticketId,
        uint256 amount
    );
    event BurnToken(
        address indexed from,
        uint indexed ticketId,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(msg.sender == andamanToken.owner());
        _;
    }

    function adminTransfer(address to, uint256 amount) public onlyAdmin {
        andamanToken.transfer(to, amount);
        emit AdminTransfer(to, msg.sender, amount);
    }

    function hotelTransfer(uint256 amount) public {
        andamanToken.transferFrom(msg.sender, address(this), amount);
        uint ticketId = tickets.length;
        Ticket memory ticket;
        ticket.status = false;
        ticket.amount = amount;
        ticketsOfUser[msg.sender].push(ticketId);
        emit HotelTransfer(msg.sender, ticketId, amount);
    }

    function burnToken(uint ticketId) public onlyAdmin {
        andamanToken.burn(tickets[ticketId].amount);
        tickets[ticketId].status = true;
        emit BurnToken(msg.sender, ticketId, tickets[ticketId].amount);
    }
}