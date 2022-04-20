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
      string orderReference;
      string productReference;
      string productBrand;
      uint32 qty3d;
  }

  event ProductShipped(string orderReference, string productReference, string productBrand, uint32 qty3d);

  function PublishDeliveryNote(uint32 deliveryNoteId, LineDetail[] calldata lines) public onlyOwner {
    // caller is the owner if they got this far.

    require(!publishedDocuments[deliveryNoteId], "Delivery Note already published.");
    
    publishedDocuments[deliveryNoteId] = true;
    
    for (uint i=0; i < lines.length; i++) {
            emit ProductShipped(lines[i].orderReference, lines[i].productReference, lines[i].productBrand, lines[i].qty3d);
        }
  }
}