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