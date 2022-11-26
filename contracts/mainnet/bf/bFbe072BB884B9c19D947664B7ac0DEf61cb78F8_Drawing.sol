// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// DO NOT CHANGE: this is the timestamp of the first Saturday evening in seconds since the Unix
// Epoch. It's used to align the allowed drawing windows with Saturday evenings.
uint constant FIRST_SATURDAY_EVENING = 244800;


struct DrawData {
  uint256 blockNumber;
  uint8[6] numbers;
  uint64[][5] winners;
}

struct PrizeData {
  uint64 ticket;
  uint256 prize;
}


library Drawing {
  function choose(uint n, uint k) public pure returns (uint) {
    if (k > n) {
      return 0;
    } else if (k == 0) {
      return 1;
    } else if (k * 2 > n) {
      return choose(n, n - k);
    } else {
      return n * choose(n - 1, k - 1) / k;
    }
  }

  function getCurrentDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + (block.timestamp - FIRST_SATURDAY_EVENING) / 7 days * 7 days;
  }

  function _ceil(uint time, uint window) private pure returns (uint) {
    return (time + window - 1) / window * window;
  }

  function nextDrawTime() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + _ceil(block.timestamp - FIRST_SATURDAY_EVENING, 7 days);
  }

  function getRandomNumbersWithoutRepetitions(uint256 randomness)
      public pure returns (uint8[6] memory numbers)
  {
    uint8[90] memory source;
    for (uint8 i = 1; i <= 90; i++) {
      source[i - 1] = i;
    }
    for (uint i = 0; i < 6; i++) {
      uint j = i + randomness % (90 - i);
      randomness /= 90;
      numbers[i] = source[j];
      source[j] = source[i];
    }
  }

  function sortNumbersByTicketCount(uint64[][90] storage ticketsByNumber, uint8[6] memory numbers)
      public view returns (uint8[6] memory)
  {
    for (uint i = 0; i < numbers.length - 1; i++) {
      uint j = i;
      for (uint k = j + 1; k < numbers.length; k++) {
        if (ticketsByNumber[numbers[k] - 1].length < ticketsByNumber[numbers[j] - 1].length) {
          j = k;
        }
      }
      if (j != i) {
        uint8 t = numbers[i];
        numbers[i] = numbers[j];
        numbers[j] = t;
      }
    }
    return numbers;
  }
}