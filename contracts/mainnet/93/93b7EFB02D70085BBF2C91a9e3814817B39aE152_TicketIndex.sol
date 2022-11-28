//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TicketSet.sol';


library TicketIndex {
  using TicketSet for uint64[];

  function findWinningTickets(uint64[][90] storage ticketsByNumber, uint8[6] storage numbers)
      public view returns (uint64[][5] memory winners)
  {
    winners = [
      new uint64[](0),  // tickets matching exactly 2 numbers
      new uint64[](0),  // tickets matching exactly 3 numbers
      new uint64[](0),  // tickets matching exactly 4 numbers
      new uint64[](0),  // tickets matching exactly 5 numbers
      new uint64[](0)   // tickets matching exactly 6 numbers
    ];
    uint8[6] memory i = [0, 0, 0, 0, 0, 0];
    for (i[0] = 0; i[0] < numbers.length; i[0]++) {
      uint64[] memory tickets0 = ticketsByNumber[numbers[i[0]] - 1];
      if (tickets0.length > 0) {
        for (i[1] = i[0] + 1; i[1] < numbers.length; i[1]++) {
          uint64[] memory tickets1 = tickets0.intersect(
              ticketsByNumber[numbers[i[1]] - 1]);
          if (tickets1.length > 0) {
            tickets0 = tickets0.subtract(tickets1);
            for (i[2] = i[1] + 1; i[2] < numbers.length; i[2]++) {
              uint64[] memory tickets2 = tickets1.intersect(
                  ticketsByNumber[numbers[i[2]] - 1]);
              if (tickets2.length > 0) {
                tickets1 = tickets1.subtract(tickets2);
                for (i[3] = i[2] + 1; i[3] < numbers.length; i[3]++) {
                  uint64[] memory tickets3 = tickets2.intersect(
                      ticketsByNumber[numbers[i[3]] - 1]);
                  if (tickets3.length > 0) {
                    tickets2 = tickets2.subtract(tickets3);
                    for (i[4] = i[3] + 1; i[4] < numbers.length; i[4]++) {
                      uint64[] memory tickets4 = tickets3.intersect(
                          ticketsByNumber[numbers[i[4]] - 1]);
                      if (tickets4.length > 0) {
                        tickets3 = tickets3.subtract(tickets4);
                        for (i[5] = i[4] + 1; i[5] < numbers.length; i[5]++) {
                          uint64[] memory tickets5 = tickets4.intersect(
                              ticketsByNumber[numbers[i[5]] - 1]);
                          if (tickets5.length > 0) {
                            tickets4 = tickets4.subtract(tickets5);
                            winners[4] = winners[4].union(tickets5);
                          }
                          delete tickets5;
                        }
                        winners[3] = winners[3].union(tickets4);
                      }
                      delete tickets4;
                    }
                    winners[2] = winners[2].union(tickets3);
                  }
                  delete tickets3;
                }
                winners[1] = winners[1].union(tickets2);
              }
              delete tickets2;
            }
            winners[0] = winners[0].union(tickets1);
          }
          delete tickets1;
        }
      }
      delete tickets0;
    }
    delete i;
    for (uint j = 0; j < winners.length - 1; j++) {
      for (uint k = j + 1; k < winners.length; k++) {
        winners[j] = winners[j].subtract(winners[k]);
      }
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library TicketSet {
  function contains(uint64[] storage array, uint64 ticketId) public view returns (bool) {
    uint i = 0;
    uint j = array.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (ticketId < array[k]) {
        j = k;
      } else if (ticketId > array[k]) {
        i = k + 1;
      } else {
        return true;
      }
    }
    return false;
  }

  function _advanceTo(uint64[] memory array, uint offset, uint64 minValue)
      private pure returns (uint)
  {
    uint i = 1;
    uint j = 2;
    while (offset + j < array.length && array[offset + j] < minValue) {
      i = j + 1;
      j <<= 1;
    }
    while (i < j) {
      uint k = i + ((j - i) >> 1);
      if (offset + k >= array.length || array[offset + k] > minValue) {
        j = k;
      } else if (array[offset + k] < minValue) {
        i = k + 1;
      } else {
        return offset + k;
      }
    }
    return offset + i;
  }

  function _advanceToStorage(uint64[] storage array, uint offset, uint64 minValue)
      private view returns (uint)
  {
    uint i = 1;
    uint j = 2;
    while (offset + j < array.length && array[offset + j] < minValue) {
      i = j + 1;
      j <<= 1;
    }
    while (i < j) {
      uint k = i + ((j - i) >> 1);
      if (offset + k >= array.length || array[offset + k] > minValue) {
        j = k;
      } else if (array[offset + k] < minValue) {
        i = k + 1;
      } else {
        return offset + k;
      }
    }
    return offset + i;
  }

  function _shrink(uint64[] memory array, uint count)
      private pure returns (uint64[] memory result)
  {
    if (count < array.length) {
      result = new uint64[](count);
      for (uint i = 0; i < result.length; i++) {
        result[i] = array[i];
      }
      delete array;
    } else {
      result = array;
    }
  }

  function intersect(uint64[] memory first, uint64[] storage second)
      public view returns (uint64[] memory result)
  {
    uint capacity = second.length < first.length ? second.length : first.length;
    result = new uint64[](capacity);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < first.length && j < second.length) {
      if (first[i] < second[j]) {
        i = _advanceTo(first, i, second[j]);
      } else if (second[j] < first[i]) {
        j = _advanceToStorage(second, j, first[i]);
      } else {
        result[k++] = first[i];
        i++;
        j++;
      }
    }
    return _shrink(result, k);
  }

  function subtract(uint64[] memory left, uint64[] memory right)
      public pure returns (uint64[] memory)
  {
    if (right.length == 0) {
      return left;
    }
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < left.length && j < right.length) {
      if (left[i] < right[j]) {
        left[k++] = left[i++];
      } else if (left[i] > right[j]) {
        j = _advanceTo(right, j, left[i]);
      } else {
        i++;
        j++;
      }
    }
    while (i < left.length) {
      left[k++] = left[i++];
    }
    return _shrink(left, k);
  }

  function union(uint64[] memory left, uint64[] memory right)
      public pure returns (uint64[] memory result)
  {
    if (right.length == 0) {
      return left;
    }
    result = new uint64[](left.length + right.length);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < left.length && j < right.length) {
      if (left[i] < right[j]) {
        result[k++] = left[i++];
      } else if (left[i] > right[j]) {
        result[k++] = right[j++];
      } else {
        result[k++] = left[i];
        i++;
        j++;
      }
    }
    while (i < left.length) {
      result[k++] = left[i++];
    }
    delete left;
    while (j < right.length) {
      result[k++] = right[j++];
    }
    return _shrink(result, k);
  }
}