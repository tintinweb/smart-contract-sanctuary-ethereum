// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Context.sol';

contract NectarVault is Context {
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _deposits;

  event Withdrawal(address recipient, uint256 amount);

  constructor() {}

  function balanceOf(address recipient) external view returns (uint256) {
    return _balances[recipient];
  }

  function totalDepositsFor(address recipient) external view returns (uint256) {
    return _deposits[recipient];
  }

  function deposit(address[] memory recipients_, uint256[] memory amounts_) public payable {
    require(recipients_.length > 0, 'Recipients array is empty');
    require(recipients_.length == amounts_.length, 'Recipients and amounts arrays are not of equal length');

    uint256 depositTotal = 0;

    for (uint256 i = 0; i < recipients_.length; i++) {
      _balances[recipients_[i]] = _balances[recipients_[i]] + amounts_[i];
      _deposits[recipients_[i]] = _deposits[recipients_[i]] + amounts_[i];
      depositTotal += amounts_[i];
    }

    require(msg.value == depositTotal, 'Value not equal to total deposits');
  }

  function withdraw() public {
    address recipient = _msgSender();
    require(_balances[recipient] > 0, 'No funds to withdraw');

    uint256 withdrawal = _balances[recipient];
    _balances[recipient] = 0;

    (bool success, ) = recipient.call{value: withdrawal}('');
    require(success, 'Address: unable to send value, recipient may have reverted');

    emit Withdrawal(recipient, withdrawal);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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