// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { MapPurchase, Utilities } from "./Libs.sol";
import { BaseControl } from "./BaseControl.sol";

contract MIFE is BaseControl {
  using MapPurchase for MapPurchase.Purchase;
  using MapPurchase for MapPurchase.Record;

  // constants
  // variables
  uint256 public quantityReleased;
  MapPurchase.Record purchases;

  // verified
  constructor() {}

  /** Public */
  function privateSale() external payable {
    uint16 rate = 12000;
    require(tx.origin == msg.sender, "Not allowed");
    require(privateSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 2 ether && msg.value <= 20 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, 18, Utilities.getPrivateBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 150000000 * (10 ** 18), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, 18, Utilities.getPrivateBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  function publicSale() external payable {
    uint16 rate = 10000;
    require(tx.origin == msg.sender, "Not allowed");
    require(publicSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 0.5 ether && msg.value <= 8 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, 18, Utilities.getPublicBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 450000000 * (10 ** 18), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, 18, Utilities.getPublicBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  /** Admin */
  function issueBonus(uint256 _start, uint256 _end) external onlyOwner {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.tokenAmount == 0 && record.bonusAmount > 0) {
        IERC20(tokenAddress).transfer(record.account, record.bonusAmount);
        record.bonusAmount = 0;
      }
    }
  }

  function issueTokens(uint256 _start, uint256 _end, uint8 _issueTh) external onlyOwner {
    require(_issueTh >= 1, "Incorrect Input");

    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.divisor + _issueTh > 12) {
        uint256 amount = record.tokenAmount / record.divisor;
        record.tokenAmount -= amount;

        if (record.divisor > 1) {
          record.divisor -= 1;
        }
        IERC20(tokenAddress).transfer(record.account, amount);
      }
    }
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 balanceA = balance * 85 / 100;

    uint256 balanceB = balance - balanceA;
    payable(0x95a881D2636a279B0F51a2849844b999E0E52fa8).transfer(balanceA);
    payable(0x0dF5121b523aaB2b238f5f03094f831348e6b5C3).transfer(balanceB);
  }

  function withdrawMIFE() external onlyOwner {
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).transfer(msg.sender, balance);
  }

  /** View */
  function getPurchasersSize() public view returns (uint256) {
    return purchases.values.length;
  }

  function getPurchaserAt(uint256 _index) public view returns (MapPurchase.Purchase memory) {
    return purchases.values[_index];
  }

  function getPurchasers(uint256 _start, uint256 _end) public view returns (MapPurchase.Purchase[] memory) {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    MapPurchase.Purchase[] memory records = new MapPurchase.Purchase[](_end - _start);
    for (uint256 i = _start; i < _end; i++) {
      records[i - _start] = purchases.values[i];
    }
    return records;
  }

  function getPersonaAllocated(address _account) public view returns (uint8) {
    MapPurchase.Purchase memory purchase = purchases.getValue(_account);
    return purchase.personaAmount;
  }

  function getPurchasedByAccount(address _account) public view returns (MapPurchase.Purchase memory) {
    return purchases.getValue(_account);
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library MapPurchase {
  struct Purchase {
    uint8 divisor;
    uint8 personaAmount;
    uint256 tokenAmount;
    uint256 bonusAmount;
    address account;
    uint256 purchasedAmount;
  }

  struct Record {
    Purchase[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function addValue(
    Record storage _record,
    address _purchaser,
    uint256 _purchased,
    uint16 _unit,
    uint8 _decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  ) internal {
    if (containsValue(_record, _purchaser)) return; // exist
    (uint256 tokenAmount, uint256 bonusAmount, uint8 personaAmount) = Utilities.computeReward(_purchased, _unit, _decimals, getRate);
    Purchase memory _value = Purchase({ divisor: 12, personaAmount: personaAmount, tokenAmount: tokenAmount, bonusAmount: bonusAmount, account: _purchaser, purchasedAmount: _purchased });
    _record.values.push(_value);
    _record.indexes[_purchaser] = _record.values.length;
  }

  function removeValue(Record storage _record, Purchase memory _value) internal {
    uint256 valueIndex = _record.indexes[_value.account];
    if (valueIndex == 0) return;
    uint256 toDeleteIndex = valueIndex - 1;
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      Purchase memory lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue.account] = valueIndex;
    }
    _record.values.pop();
    _record.indexes[_value.account] = 0;
  }

  function containsValue(Record storage _record, address _account) internal view returns (bool) {
    return _record.indexes[_account] != 0;
  }

  function getValue(Record storage _record, address _account) internal view returns (Purchase memory) {
    if (!containsValue(_record, _account)) {
      return Purchase({ divisor: 12, personaAmount: 0, tokenAmount: 0, bonusAmount: 0, account: _account, purchasedAmount: 0 });
    }
    uint256 valueIndex = _record.indexes[_account];
    return _record.values[valueIndex - 1];
  }
}

library Utilities {
  function computeReward(
    uint256 purchased,
    uint16 unit,
    uint8 decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  )
    internal
    pure
    returns (
      uint256,
      uint256,
      uint8
    )
  {
    uint256 tokenAmount = uint256((purchased * unit) / 1 ether) * (10 ** decimals);

    (uint16 rate, uint8 persona) = getRate(purchased, unit);
    uint256 bonusAmount = uint256((purchased * rate) / 1 ether) * (10 ** decimals);

    return (tokenAmount, bonusAmount, persona);
  }

  function getPrivateBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 2 ether && purchased < 4 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 4 ether && purchased < 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    if (purchased >= 6 ether && purchased < 9 ether) {
      return ((unit / 100) * 25, 25);
    }

    if (purchased >= 9 ether && purchased < 15 ether) {
      return ((unit / 100) * 30, 35);
    }

    if (purchased >= 15 ether && purchased < 19 ether) {
      return ((unit / 100) * 35, 45);
    }

    if (purchased >= 19 ether) {
      return ((unit / 100) * 50, 88);
    }

    return (0, 0);
  }

  function getPublicBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 0.5 ether && purchased < 1 ether) {
      return ((unit / 100) * 2, 2);
    }

    if (purchased >= 1 ether && purchased < 3 ether) {
      return ((unit / 100) * 5, 5);
    }

    if (purchased >= 3 ether && purchased < 6 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseControl is Ownable {
  // variables
  bool public privateSaleActive;
  bool public publicSaleActive;
  address public tokenAddress = 0x8e7BaBf9EaC40fCd054ACaD1078a898Bd17B529a;

  function togglePrivateSale(bool _status) external onlyOwner {
    privateSaleActive = _status;
  }

  function togglePublicSale(bool _status) external onlyOwner {
    publicSaleActive = _status;
  }

  function setTokenAddress(address _address) external onlyOwner {
    tokenAddress = _address;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}