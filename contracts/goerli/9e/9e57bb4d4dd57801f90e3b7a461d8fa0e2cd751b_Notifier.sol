/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ownable
 * @dev A contract which has an owner.
 */
contract Ownable {

  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
    _;
  }

  constructor () {
    owner = msg.sender;
  }
}

/**
 * @title Notifier
 * @dev Emits an event
 */
contract Notifier is Ownable {

  event DeliveryNoteAvailable(uint documentId, string documentReference, uint256 documentValue, uint decimalPlaces);

  function PublishDeliveryNote(uint documentId, string memory documentReference, uint256 documentValue, uint decimalPlaces) public onlyOwner {
    // caller is the owner if they got this far.

    emit DeliveryNoteAvailable(documentId, documentReference, documentValue, decimalPlaces);

  }
}