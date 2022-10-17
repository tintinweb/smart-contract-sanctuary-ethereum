// SPDX-License-Identifier: BSD-3-Clause

/// @title The TheFarm DAO executor and treasury

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

// LICENSE
// TheFarmDAOExecutor.sol is a modified version of Compound Lab's Timelock.sol:
// https://github.com/compound-finance/compound-protocol/blob/20abad28055a2f91df48a90f8bb6009279a4cb35/contracts/Timelock.sol
//
// Timelock.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// MODIFICATIONS
// TheFarmDAOExecutor.sol modifies Timelock to use Solidity 0.8.x receive(), fallback(), and built-in over/underflow protection
// This contract acts as executor of TheFarm DAO governance and its treasury, so it has been modified to accept ETH.

pragma solidity ^0.8.17;

contract TheFarmDAOExecutor {
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(address admin_, uint256 delay_) {
    require(delay_ >= MINIMUM_DELAY, 'TheFarmDAOExecutor::constructor: Delay must exceed minimum delay.');
    require(delay_ <= MAXIMUM_DELAY, 'TheFarmDAOExecutor::setDelay: Delay must not exceed maximum delay.');

    admin = admin_;
    delay = delay_;
  }

  function setDelay(uint256 delay_) public {
    require(msg.sender == address(this), 'TheFarmDAOExecutor::setDelay: Call must come from TheFarmDAOExecutor.');
    require(delay_ >= MINIMUM_DELAY, 'TheFarmDAOExecutor::setDelay: Delay must exceed minimum delay.');
    require(delay_ <= MAXIMUM_DELAY, 'TheFarmDAOExecutor::setDelay: Delay must not exceed maximum delay.');
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin, 'TheFarmDAOExecutor::acceptAdmin: Call must come from pendingAdmin.');
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(
      msg.sender == address(this),
      'TheFarmDAOExecutor::setPendingAdmin: Call must come from TheFarmDAOExecutor.'
    );
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes32) {
    require(msg.sender == admin, 'TheFarmDAOExecutor::queueTransaction: Call must come from admin.');
    require(
      eta >= getBlockTimestamp() + delay,
      'TheFarmDAOExecutor::queueTransaction: Estimated execution block must satisfy delay.'
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public {
    require(msg.sender == admin, 'TheFarmDAOExecutor::cancelTransaction: Call must come from admin.');

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes memory) {
    require(msg.sender == admin, 'TheFarmDAOExecutor::executeTransaction: Call must come from admin.');

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "TheFarmDAOExecutor::executeTransaction: Transaction hasn't been queued.");
    require(
      getBlockTimestamp() >= eta,
      "TheFarmDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(getBlockTimestamp() <= eta + GRACE_PERIOD, 'TheFarmDAOExecutor::executeTransaction: Transaction is stale.');

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, 'TheFarmDAOExecutor::executeTransaction: Transaction execution reverted.');

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }

  receive() external payable {}

  fallback() external payable {}
}