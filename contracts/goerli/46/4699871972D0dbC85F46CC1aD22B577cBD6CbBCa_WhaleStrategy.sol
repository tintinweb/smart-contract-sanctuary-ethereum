/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Global Constants
uint256 constant PERCENTAGE_MARKETPLACE_FEE = 10;

contract WhaleStrategy {
  address public immutable CREATOR_ADDRESS;
  address public immutable APP_ADDRESS;
  uint256 public whaleLimit;
  uint256 public initialLairEntry;

  bool public lairFull;

  Whale[] public whaleArr;
  mapping(address => bool) public isWhale;
  mapping(address => uint256) public refundWhaleAmount;

  struct Whale {
    address addr;
    uint256 grant;
  }

  event LogNewWhale(uint256 indexed amount, address indexed newWhale, address oldWhale);

  constructor(
    address _appAddress,
    uint256 _whaleLimit,
    uint256 _initialLairEntry
  ) {
    CREATOR_ADDRESS = msg.sender;
    APP_ADDRESS = _appAddress;
    whaleLimit = _whaleLimit;
    initialLairEntry = _initialLairEntry;
  }

  function enterLair() external payable checkEtherGuard(msg.value) {
    if (lairFull == false) {
      _accomodateWhaleWithoutDethrone(msg.value, msg.sender);
      // Calculate Mktplace fee
      uint256 marketPlaceFee = _calculateAppFee(msg.value);
      // Distribute ether
      payable(APP_ADDRESS).transfer(marketPlaceFee);
      payable(CREATOR_ADDRESS).transfer(msg.value - marketPlaceFee);
      return;
    }
    // LAIR IS FULL

    Whale memory whaleToDethrone = whaleArr[whaleArr.length - 1];
    _accomodateWhaleAndDethrone(msg.value, msg.sender);
    // Refund old whale
    refundWhaleAmount[whaleToDethrone.addr] = whaleToDethrone.grant;
    // Distribute the profits
    uint256 profit = msg.value - whaleToDethrone.grant;
    uint256 appProfit = _calculateAppFee(profit);
    payable(APP_ADDRESS).transfer(appProfit);
    payable(CREATOR_ADDRESS).transfer(profit - appProfit);
  }

  function withdraw() public {
    require(refundWhaleAmount[msg.sender] > 0, 'No Owed Amount.');
    refundWhaleAmount[msg.sender] = 0;
    payable(msg.sender).transfer(refundWhaleAmount[msg.sender]);
  }

  function _accomodateWhaleWithoutDethrone(uint256 moneyPaid, address newWhaleWallet) private {
    // Include new whale in mapping and array
    whaleArr.push(Whale(newWhaleWallet, moneyPaid));
    isWhale[newWhaleWallet] = true;

    emit LogNewWhale(moneyPaid, newWhaleWallet, address(0));

    if (whaleArr.length >= whaleLimit) {
      sort();
      lairFull = true;
    }
  }

  function _accomodateWhaleAndDethrone(uint256 newMoney, address newAddr) private {
    Whale memory dethronedWhale = whaleArr[whaleArr.length - 1];
    // Remove last element from array since it is sorted
    whaleArr.pop();
    // Remove whale from mapping
    delete isWhale[dethronedWhale.addr];
    emit LogNewWhale(newMoney, newAddr, dethronedWhale.addr);
    // Include new whale in mapping and array
    whaleArr.push(Whale(newAddr, newMoney));
    isWhale[newAddr] = true;
    // This step can be optimized by finding the
    // pertaining location and moving the whales in
    // the array
    sort();
  }

  function _calculateAppFee(uint256 amount) private pure returns (uint256) {
    return (amount * PERCENTAGE_MARKETPLACE_FEE) / 100;
  }

  function sort() internal {
    _quickSort(whaleArr, int256(0), int256(whaleArr.length - 1));
  }

  function _quickSort(
    Whale[] storage arr,
    int256 left,
    int256 right
  ) private {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)].grant;
    while (i <= j) {
      while (arr[uint256(i)].grant > pivot) i++;
      while (pivot > arr[uint256(j)].grant) j--;
      if (i <= j) {
        Whale memory temp = arr[uint256(i)];
        arr[uint256(i)] = arr[uint256(j)];
        arr[uint256(j)] = temp;
        i++;
        j--;
      }
    }
    if (left < j) _quickSort(arr, left, j);
    if (i < right) _quickSort(arr, i, right);
  }

  modifier checkEtherGuard(uint256 amount) {
    if (lairFull == false) {
      require(amount >= initialLairEntry, 'Not enough money.');
      _;
      return;
    }
    if (lairFull == true) {
      require(amount > whaleArr[whaleLimit - 1].grant, 'Not enough to dethrone whale.');
      _;
      return;
    }
  }
}