/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

error Event__NotExist();
error Event__NotActive();
error Event__WrongDate();
error Event__Tickets();
error Event__Price();

/**
 * @author Siarhei Hamanovich
 * @title EventContract
 * @dev Create custom event & buy, transfer tickets
 */
contract EventContract {
    struct Event {
        address admin; // author of event
        string name; // how event names
        uint256 date; // when event happens
        uint256 price; // how much cost event in Ether
        uint256 ticketsAmount; // amount of available tickets
        uint256 ticketsRemain; // amount of remained tickets
    }

    mapping(uint256 => Event) private events;
    mapping(address => mapping(uint256 => uint256)) private tickets;
    uint256 private nextId;

    event EventCreated(
        address indexed admin,
        string indexed name,
        uint256 date,
        uint256 price,
        uint256 ticketsAmount
    );

    event TicketBuy(uint256 indexed eventId, uint256 quantity);

    event TicketTransfer(uint256 indexed eventId, uint256 quantity, address to);

    // modifier to check if event is exist
    modifier eventExist(uint256 eventId) {
        if (events[eventId].date == 0) revert Event__NotExist();
        _;
    }

    // modifier to check if event is active
    modifier eventActive(uint256 eventId) {
        if (block.timestamp >= events[eventId].date) revert Event__NotActive();
        _;
    }

    /**
     * @dev Create a new custom event.
     * @param name string of event
     * @param date of upcoming event
     * @param price of event
     * @param ticketsAmount number of available tickets
     */
    function createEvent(
        string calldata name,
        uint256 date,
        uint256 price,
        uint256 ticketsAmount
    ) external {
        if (date <= block.timestamp) revert Event__WrongDate();
        if (ticketsAmount <= 0) revert Event__Tickets();

        events[nextId] = Event(
            msg.sender,
            name,
            date,
            price,
            ticketsAmount,
            ticketsAmount
        );
        nextId++;

        emit EventCreated(msg.sender, name, date, price, ticketsAmount);
    }

    /**
     * @dev Buy tickets for particular event.
     * @param eventId id of event
     * @param quantity number of event tickets to buy
     */
    function buyTicket(uint256 eventId, uint256 quantity)
        external
        payable
        eventExist(eventId)
        eventActive(eventId)
    {
        Event storage currentEvent = events[eventId];
        if (msg.value != (currentEvent.price * quantity)) revert Event__Price();
        if (currentEvent.ticketsRemain < quantity) revert Event__Tickets();

        currentEvent.ticketsRemain -= quantity;
        tickets[msg.sender][eventId] += quantity;

        emit TicketBuy(eventId, quantity);
    }

    /**
     * @dev Transfer tickets to another event.
     * @param eventId id of event
     * @param quantity number of tickets should be transfered
     * @param to address where to transfer tickets
     */
    function transferTicket(
        uint256 eventId,
        uint256 quantity,
        address to
    ) external eventExist(eventId) eventActive(eventId) {
        if (tickets[msg.sender][eventId] < quantity) revert Event__Tickets();
        tickets[msg.sender][eventId] -= quantity;
        tickets[to][eventId] += quantity;

        emit TicketTransfer(eventId, quantity, to);
    }

    /**
     * @dev Get particular event information.
     * @param eventId id of event
     * @return event information
     */
    function getEvent(uint256 eventId) external view returns (Event memory) {
        return events[eventId];
    }
}