/**
 *Submitted for verification at Etherscan.io on 2022-04-20
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

  mapping(uint32 => bool) private publishedDocuments;

  struct LineDetail {
      string productReference;
      string productBrand;
      uint32 qty;
      uint8 decimalPlaces;
  }

  struct DeliveryNote {
      uint32 documentId;
      string orderReference;
      LineDetail[] lines;
  }

  event DeliveryNoteAvailable(DeliveryNote deliveryNote);

  function PublishDeliveryNote(DeliveryNote memory deliveryNote) public onlyOwner {
    // caller is the owner if they got this far.

    require(!publishedDocuments[deliveryNote.documentId], "Delivery Note already published.");
    
    publishedDocuments[deliveryNote.documentId] = true;
    emit DeliveryNoteAvailable(deliveryNote);

  }
}