// SPDX-License-Identifier: mit
pragma solidity ^0.8.8;

contract EventContract {
    struct Event {
        address admin;
        string name;
        uint256 date;
        uint256 price;
        uint256 ticketCount;
        uint256 ticketRemaining;
    }

    mapping(uint256 => Event) public events;
    mapping(address => mapping(uint256 => uint256)) public tickets;
    uint256 public nextId;
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function createEvent(
        string calldata name,
        uint256 date,
        uint256 price,
        uint256 ticketCount
    ) external {
        require(
            block.timestamp + date > block.timestamp,
            "event can only organize in the future"
        );
        require(
            ticketCount > 0,
            "can only create event with at least one ticket available"
        );
        events[nextId] = Event(
            msg.sender,
            name,
            date,
            price,
            ticketCount,
            ticketCount
        );
        nextId++;
    }

    function buyTicket(uint256 id, uint256 quantity)
        external
        payable
        eventExist(id)
        eventActive(id)
    {
        Event storage _event = events[id];

        require(
            msg.value == (_event.price * quantity),
            "not enough ether sent"
        );
        require(_event.ticketRemaining >= quantity, "not enough ticket left");
        _event.ticketRemaining -= quantity;
        tickets[msg.sender][id] += quantity;
    }

    function ticketTransfer(
        uint256 eventId,
        uint256 quantity,
        address to
    ) external eventExist(eventId) eventActive(eventId) {
        require(tickets[msg.sender][eventId] >= quantity, "not enough tickets");
        tickets[msg.sender][eventId] -= quantity;
        tickets[to][eventId] += quantity;
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    modifier eventExist(uint256 id) {
        require(events[id].date != 0, "this event does not exist");
        _;
    }
    modifier eventActive(uint256 id) {
        require(
            block.timestamp < events[id].date,
            "this event is not active anymore"
        );
        _;
    }
}

// contract StateMachine {
//     enum State {
//         PENDING,
//         ACTIVE,
//         CLOSED
//     }
//     State public state = State.PENDING;
//     uint256 public amount;
//     uint256 public interest;
//     uint256 public end;
//     address payable public borrower;
//     address payable public lender;

//     constructor(
//         uint256 _amount,
//         uint256 _interest,
//         uint256 _duration,
//         address payable _borrower,
//         address payable _lender
//     ) {
//         amount = _amount;
//         interest = _interest;
//         end = block.timestamp + _duration;
//         borrower = _borrower;
//         lender = _lender;
//     }

//     function fund() external payable {
//         require(msg.sender == lender, "only lender can lend");
//         require(address(this).balance == amount, "can only lend exact amount");
//         borrower.transfer(amount);
//     }

//     function reimburse() external payable {
//         require(msg.sender == borrower, "only borrowr can reimburse");
//         require(
//             msg.value == amount + interest,
//             "borrower need to reimburse amount + interest"
//         );
//         lender.transfer(amount + interest);
//     }
// }