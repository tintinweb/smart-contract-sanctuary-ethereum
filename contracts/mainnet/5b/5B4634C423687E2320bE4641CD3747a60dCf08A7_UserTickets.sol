// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct TicketData {
  uint64 id;
  uint64 round;
  uint64 timestamp;
  uint64 cardinality;
}


library UserTickets {
  function _lowerBound(TicketData[] storage tickets, uint64 round) private view returns (uint64) {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (round > tickets[k].round) {
        i = k + 1;
      } else {
        j = k;
      }
    }
    return i;
  }

  function _upperBound(TicketData[] storage tickets, uint64 round) private view returns (uint64) {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (round < tickets[k].round) {
        j = k;
      } else {
        i = k + 1;
      }
    }
    return j;
  }

  function getTicketIds(TicketData[] storage tickets) public view returns (uint64[] memory ids) {
    ids = new uint64[](tickets.length);
    for (uint64 i = 0; i < tickets.length; i++) {
      ids[i] = tickets[i].id;
    }
  }

  function getTicketIdsForRound(TicketData[] storage tickets, uint64 round)
      public view returns (uint64[] memory ids)
  {
    uint64 min = _lowerBound(tickets, round);
    uint64 max = _upperBound(tickets, round);
    ids = new uint64[](max - min);
    for (uint64 i = min; i < max; i++) {
      ids[i - min] = tickets[i].id;
    }
  }

  function getTicket(TicketData[] storage tickets, uint64 ticketId)
      public view returns (TicketData storage)
  {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (ticketId < tickets[k].id) {
        j = k;
      } else if (ticketId > tickets[k].id) {
        i = k + 1;
      } else {
        return tickets[k];
      }
    }
    revert('invalid ticket ID');
  }
}