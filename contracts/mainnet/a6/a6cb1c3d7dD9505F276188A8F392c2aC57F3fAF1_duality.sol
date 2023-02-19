/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title •duality
/// @author 0xG

contract duality {
  /**
   * @notice Retrieve the token state.
   * Unlocked tokens can be transferred by operators.
   */
  mapping(uint256 => bool) public unlocked;

  uint256 public price = 0.5 ether;
  address _receiver;
  address _creator;

  /**
   * @dev Emitted when `tokenId` is unlocked to enable operator transfers.
   * @param tokenId The unlocked token id.
   * @param owner The unlocked token owner.
   */
  event Unlock(uint256 indexed tokenId, address indexed owner);

  constructor(address creator, address receiver) {
    _creator = creator;
    _receiver = receiver;
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return (
      interfaceId == /* ICreatorExtensionTokenURI */ 0xe9dc6375 ||
      interfaceId == /* IERC721CreatorExtensionApproveTransfer */ 0x45ffcdad ||
      interfaceId == /* IERC165 */ 0x01ffc9a7
    );
  }

  function tokenURI(address creator, uint tokenId) external view returns (string memory) {
    require(creator == _creator, "Invalid Call");

    return string(abi.encodePacked(
      'data:application/json;utf8,',
      '{"name":"',unlocked[tokenId]?'duality%E2%80%A2':'%E2%80%A2duality','",',
      '"created_by":"0xG","description":"art moves freely",',
      '"image":"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiPjxkZWZzPjxsaW5lYXJHcmFkaWVudCBpZD0iZDEiIHgxPSIwJSIgeDI9IjAlIiB5MT0iMCUiIHkyPSIxMDAlIj48c3RvcCBvZmZzZXQ9IjAlIi8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMjIyIi8+PC9saW5lYXJHcmFkaWVudD48ZmlsdGVyIGlkPSJkMiI+PGZlVHVyYnVsZW5jZSBiYXNlRnJlcXVlbmN5PSI1IiBudW1PY3RhdmVzPSIzIiBzdGl0Y2hUaWxlcz0ic3RpdGNoIiB0eXBlPSJmcmFjdGFsTm9pc2UiLz48ZmVDb21wb25lbnRUcmFuc2Zlcj48ZmVGdW5jUiBzbG9wZT0iLjUiIHR5cGU9ImxpbmVhciIvPjxmZUZ1bmNHIHNsb3BlPSIuNSIgdHlwZT0ibGluZWFyIi8+PGZlRnVuY0Igc2xvcGU9Ii41IiB0eXBlPSJsaW5lYXIiLz48L2ZlQ29tcG9uZW50VHJhbnNmZXI+PGZlQmxlbmQgbW9kZT0ic2NyZWVuIi8+PGZlQ29tcG9zaXRlIGluMj0iU291cmNlQWxwaGEiIG9wZXJhdG9yPSJpbiIvPjwvZmlsdGVyPjwvZGVmcz48cGF0aCBmaWxsPSJ1cmwoI2QxKSIgZD0iTTAgMGgxMDAwdjEwMDBIMHoiLz48cmVjdCB3aWR0aD0iNy41IiBoZWlnaHQ9IjM1MCIgeD0iNDgyIiB5PSIzODAiIGZpbGw9IiM0NDQiIHJ4PSIyIi8+PHJlY3Qgd2lkdGg9IjcuNSIgaGVpZ2h0PSIzNTAiIHg9IjQ5Ni4yNSIgeT0iMzUwIiBmaWxsPSIjZWVlIiByeD0iMiIvPjxwYXRoIGQ9Ik0wIDBoMTAwMHYxMDAwSDB6IiBmaWx0ZXI9InVybCgjZDIpIiBvcGFjaXR5PSIuMiIvPjwvc3ZnPg==",',
      '"attributes":[{"trait_type":"Unlocked","value":"',unlocked[tokenId]?'True':'False','"}]',
      '}'
    ));
  }

  /**
   * @dev Owners who have unlocked their tokens can have them managed by an operators (eg. a marketplace).
   * Direct wallet-to-wallet transfers are always allowed.
   */
  function approveTransfer(address operator, address from, address to, uint256 tokenId) external returns (bool) {
    require(msg.sender == _creator, "Invalid Caller");

    if (operator == from || from == address(0) || to == address(0)) {
      return true;
    }

    bool approved = unlocked[tokenId];
    if (approved) { unlocked[tokenId] = false; }
    return approved;
  }

  /**
   * @notice Mint art for free. Available supply is 50.
   */
  function mint() external {
    require(
      IERC721CreatorCore(_creator).mintExtension(msg.sender) <= 50,
      "All tokens have been minted"
    );
  }

  /**
   * @notice Pay to unlock the token and enable transfers via operators (eg. a marketplaces).
   * When a token is transferred by an operator it will be locked again and the new owner needs to unlock.
   *
   * @param tokenId The token id to unlock.
   */
  function unlock(uint256 tokenId) external payable {
    require(msg.value == price, "Invalid Amount");
    require(
      IERC721CreatorCore(_creator).ownerOf(tokenId) == msg.sender,
      "Unauthorized"
    );

    if (msg.value > 0) {
      require(_receiver != address(0), "Invalid receiver");
      (bool sent,) = _receiver.call{value:msg.value}("");
      require(sent, "Failed to transfer to receiver");
    }

    unlocked[tokenId] = true;
    emit Unlock(tokenId, msg.sender);
  }

  /**
   * @dev Update the unlock price.
   * @param newPrice The new price in Wei.
   */
  function setPrice(uint256 newPrice) external {
    require(IERC721CreatorCore(_creator).isAdmin(msg.sender), "Unauthorized");
    price = newPrice;
  }

  /**
   * @dev Update the unlock value receiver.
   * @param newReceiver The new receiver address.
   */
  function setReceiver(address newReceiver) external {
    require(IERC721CreatorCore(_creator).isAdmin(msg.sender), "Unauthorized");
    _receiver = newReceiver;
  }
}

interface IERC721CreatorCore {
  function isAdmin(address sender) external pure returns (bool);
  function mintExtension(address to) external returns (uint256 tokenId);
  function ownerOf(uint256 tokenId) external pure returns (address owner);
}