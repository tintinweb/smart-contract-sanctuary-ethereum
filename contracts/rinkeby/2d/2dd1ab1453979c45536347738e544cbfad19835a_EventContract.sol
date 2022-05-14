/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

pragma solidity ^0.5.12;

contract EventContract {
  // Mapping from event id to event
  mapping(bytes32 => Event) public events;
  bytes32[] public event_id_list;
  uint8 constant public max_ticket_types = 100;
  mapping(address => bytes32[]) public participation;

  struct Event { // attempt strict packaging
    address payable owner;
    bytes32 event_id; //unique
    bytes32 title;
    uint index;
    uint64 max_per_customer;
    uint256 funds;
    bool exists;
    bool sale_active;
    bool buyback_active;
    bool per_customer_limit;
    uint256 deadline;
    uint64[] available_tickets;
    uint128[] ticket_prices;
    address[] customers;
    mapping(address => Customer) tickets;
  }

  struct Customer {
    uint index;
    address addr;
    bool exists;
    uint64 total_num_tickets;
    uint128 total_paid;
    uint64[] num_tickets;
  }

  event EventCreated(bytes32 event_id);

  modifier eventExists(bytes32 event_id){
    require(events[event_id].exists, "Event with given ID not found.");
    _;
  }

  modifier onlyHost(bytes32 event_id){
    require(events[event_id].owner == msg.sender, "Sender is not the owner of this event");
    _;
  }

  modifier beforeDeadline(bytes32 event_id){
      require(events[event_id].deadline > block.timestamp, "Event deadline has passed");
      _;
  }

  modifier afterDeadline(bytes32 event_id){
      require(events[event_id].deadline < block.timestamp, "Event deadline has not yet passed");
      _;
  }

// ----- Event host functions -----

  function create_event(bytes32 _event_id,
    bytes32 _title,
    uint64[] calldata num_tickets,
    uint128[] calldata _ticket_prices,
    bool _per_customer_limit,
    uint64 _max_per_customer,
    bool _sale_active,
    bool _buyback_active,
    uint256 _deadline) external {
      require(!events[_event_id].exists, "Given event ID is already in use.");
      require(num_tickets.length == _ticket_prices.length,
        "Different number of ticket types given by price and number available arrays.");
      require(num_tickets.length > 0, "Cannot create event with zero ticket types.");
      require(num_tickets.length <= max_ticket_types, "Maximum number of ticket types exceeded.");
      require(_deadline > block.timestamp, "Deadline cannot be in the past");
      events[_event_id].exists = true;
      events[_event_id].event_id = _event_id;
      events[_event_id].title = _title;
      events[_event_id].available_tickets = num_tickets;
      events[_event_id].ticket_prices = _ticket_prices;
      events[_event_id].max_per_customer = _max_per_customer;
      events[_event_id].per_customer_limit = _per_customer_limit;
      events[_event_id].owner = msg.sender;
      events[_event_id].sale_active = _sale_active;
      events[_event_id].buyback_active = _buyback_active;
      events[_event_id].deadline = _deadline;
      events[_event_id].index = event_id_list.length;
      event_id_list.push(_event_id);
      emit EventCreated(_event_id);
  }

  function withdraw_funds(bytes32 event_id) external eventExists(event_id) onlyHost(event_id) afterDeadline(event_id) {
    events[event_id].buyback_active = false;
    uint256 withdraw_amount = events[event_id].funds;
    events[event_id].funds = 0;

    (bool success, ) = events[event_id].owner.call.value(withdraw_amount)("");
    require(success, "Withdrawal transfer failed.");
  }

  function view_funds(bytes32 event_id) external view eventExists(event_id) onlyHost(event_id) returns (uint256 current_funds){
    return events[event_id].funds;
  }

  function get_tickets(bytes32 event_id, address customer) external view eventExists(event_id)
        returns (uint64[] memory) {
    return events[event_id].tickets[customer].num_tickets;
  }

  function get_customers(bytes32 event_id) external view eventExists(event_id)
        returns (address[] memory) {
    return (events[event_id].customers);
  }

  function stop_sale(bytes32 event_id) external eventExists(event_id) onlyHost(event_id) {
    events[event_id].sale_active = false;
  }

  function continue_sale(bytes32 event_id) external eventExists(event_id) onlyHost(event_id) {
    events[event_id].sale_active = true;
  }

  function add_tickets(bytes32 event_id, uint64[] calldata additional_tickets) external eventExists(event_id) onlyHost(event_id) {
    require(additional_tickets.length == events[event_id].available_tickets.length,
      "List of number of tickets to add must be of same length as existing list of tickets.");

    for(uint64 i = 0; i < events[event_id].available_tickets.length ; i++) {
      // Check for integer overflow
      require(events[event_id].available_tickets[i] + additional_tickets[i] >= events[event_id].available_tickets[i],
              "Cannot exceed 2^64-1 tickets");
      events[event_id].available_tickets[i] += additional_tickets[i];
    }

  }

  function change_ticket_price(bytes32 event_id, uint64 ticket_type, uint128 new_price) external eventExists(event_id) onlyHost(event_id) {
    require(ticket_type < events[event_id].ticket_prices.length, "Ticket type does not exist.");
    events[event_id].ticket_prices[ticket_type] = new_price;
  }

  function delete_event(bytes32 event_id) external eventExists(event_id) onlyHost(event_id) {
    require(events[event_id].funds == 0, "Cannot delete event with positive funds.");
    require(events[event_id].deadline + 604800 < block.timestamp,
      "Cannot delete event before a week has passed since deadline"); //add a week past deadline (604800 seconds)

    uint old_index = events[event_id].index;
    delete events[event_id];
    events[event_id_list[event_id_list.length - 1]].index = old_index;
    event_id_list[old_index] = event_id_list[event_id_list.length - 1];
    delete event_id_list[event_id_list.length - 1];
    event_id_list.length--;
  }

// ----- Customer functions -----

  function buy_tickets(bytes32 event_id, uint64 ticket_type, uint64 requested_num_tickets) external payable beforeDeadline(event_id) {
    require(requested_num_tickets > 0);
    require(ticket_type < events[event_id].available_tickets.length, "Ticket type does not exist.");
    require(events[event_id].sale_active, "Ticket sale is closed by seller.");
    require(requested_num_tickets <= events[event_id].available_tickets[ticket_type],
      "Not enough tickets available.");
    require(!events[event_id].per_customer_limit ||
      (events[event_id].tickets[msg.sender].total_num_tickets + requested_num_tickets <= events[event_id].max_per_customer),
      "Purchase surpasses max per customer.");
    uint128 sum_price = uint128(requested_num_tickets)*uint128(events[event_id].ticket_prices[ticket_type]);
    require(msg.value >= sum_price, "Not enough ether was sent.");

    if(!events[event_id].tickets[msg.sender].exists) {
      events[event_id].tickets[msg.sender].exists = true;
      events[event_id].tickets[msg.sender].addr = msg.sender;
      events[event_id].tickets[msg.sender].index = events[event_id].customers.length;
      events[event_id].customers.push(msg.sender);
      events[event_id].tickets[msg.sender].num_tickets = new uint64[](events[event_id].available_tickets.length);
    }

    events[event_id].tickets[msg.sender].total_num_tickets += requested_num_tickets;
    events[event_id].tickets[msg.sender].num_tickets[ticket_type] += requested_num_tickets;
    events[event_id].tickets[msg.sender].total_paid += sum_price;
    events[event_id].available_tickets[ticket_type] -= requested_num_tickets;
    events[event_id].funds += sum_price;

    add_participation(event_id, msg.sender);

    // Return excessive funds
    if(msg.value > sum_price) {
      (bool success, ) = msg.sender.call.value(msg.value - sum_price)("");
      require(success, "Return of excess funds to sender failed.");
    }
  }

  function return_tickets(bytes32 event_id) external beforeDeadline(event_id) {
    require(events[event_id].tickets[msg.sender].total_num_tickets > 0,
      "User does not own any tickets to this event.");
    require(events[event_id].buyback_active, "Ticket buyback has been deactivated by owner.");
    require(events[event_id].sale_active, "Ticket sale is locked, which disables buyback.");

    uint return_amount = events[event_id].tickets[msg.sender].total_paid;

    for(uint64 i = 0; i < events[event_id].available_tickets.length ; i++) {
      // Check for integer overflow
      require(events[event_id].available_tickets[i] +
        events[event_id].tickets[msg.sender].num_tickets[i] >=
        events[event_id].available_tickets[i],
        "Failed because returned tickets would increase ticket pool past storage limit.");
      events[event_id].available_tickets[i] += events[event_id].tickets[msg.sender].num_tickets[i];
    }

    delete_customer(event_id, msg.sender);
    delete_participation(event_id, msg.sender);

    events[event_id].funds -= return_amount;

    (bool success, ) = msg.sender.call.value(return_amount)("");
    require(success, "Return transfer to customer failed.");
  }

// ----- View functions -----

  function get_event_info(bytes32 event_id) external view eventExists(event_id) returns (
    bytes32 id,
    bytes32 title,
    address owner,
    uint256 deadline,
    uint64[] memory available_tickets,
    uint64 max_per_customer,
    uint128[] memory ticket_price,
    bool sale_active,
    bool buyback_active,
    bool per_customer_limit) {
    Event memory e = events[event_id]; // does this make a deep copy of the struct to memory?
    return (
      e.event_id,
      e.title,
      e.owner,
      e.deadline,
      e.available_tickets,
      e.max_per_customer,
      e.ticket_prices,
      e.sale_active,
      e.buyback_active,
      e.per_customer_limit);
  }

  function get_events() external view returns (bytes32[] memory event_list) {
    return event_id_list;
  }

  function get_participation() external view returns (bytes32[] memory event_participation) {
    require(participation[msg.sender].length > 0, "Sender does not own any tickets.");
    return participation[msg.sender];
  }

// ----- Internal functions -----

  function delete_customer(bytes32 event_id, address customer_addr) internal {
    uint old_index = events[event_id].tickets[customer_addr].index;
    delete events[event_id].tickets[customer_addr];
    events[event_id].tickets[events[event_id].customers[events[event_id].customers.length - 1]].index = old_index;
    events[event_id].customers[old_index] = events[event_id].customers[events[event_id].customers.length - 1];
    delete events[event_id].customers[events[event_id].customers.length - 1];
    events[event_id].customers.length--;
  }

  function add_participation(bytes32 event_id, address customer_addr) internal {
    for(uint64 i = 0; i < participation[customer_addr].length ; i++) {
      if (participation[customer_addr][i] == event_id) {
        return;
      }
    }
    participation[customer_addr].push(event_id);
  }

  function delete_participation(bytes32 event_id, address customer_addr) internal {
    uint len = participation[customer_addr].length;
    for(uint64 i = 0; i < len ; i++) {
      if (participation[customer_addr][i] == event_id) {
        participation[customer_addr][i] = participation[customer_addr][len-1];
        delete participation[customer_addr][len-1];
        participation[customer_addr].length--;
        break;
      }
    }
  }

}