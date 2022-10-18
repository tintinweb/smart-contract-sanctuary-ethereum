// SPDX-License-Identifier: MIT

/*

 /$$$$$$$$ /$$$$$$$  /$$$$$$ /$$$$$$$$ /$$$$$$  /$$$$$$  /$$   /$$  /$$$$$$
| $$_____/| $$__  $$|_  $$_/|__  $$__/|_  $$_/ /$$__  $$| $$$ | $$ /$$__  $$
| $$      | $$  \ $$  | $$     | $$     | $$  | $$  \ $$| $$$$| $$| $$  \__/
| $$$$$   | $$  | $$  | $$     | $$     | $$  | $$  | $$| $$ $$ $$|  $$$$$$
| $$__/   | $$  | $$  | $$     | $$     | $$  | $$  | $$| $$  $$$$ \____  $$
| $$      | $$  | $$  | $$     | $$     | $$  | $$  | $$| $$\  $$$ /$$  \ $$
| $$$$$$$$| $$$$$$$/ /$$$$$$   | $$    /$$$$$$|  $$$$$$/| $$ \  $$|  $$$$$$/
|________/|_______/ |______/   |__/   |______/ \______/ |__/  \__/ \______/


- steviep.eth

*/

import "./Dependencies.sol";

pragma solidity ^0.8.11;

interface TokenURI {
  function uri(uint256) external view returns (string memory);
}

contract Editions is ERC1155, Ownable {
  mapping(uint256 => address) public tokenIdToMinter;
  mapping(uint256 => address) public tokenIdToURIContract;
  mapping(uint256 => uint16) public tokenIdToRoyaltyBP;
  mapping(uint256 => address) public tokenIdToRoyaltyBeneficiary;

  string public constant name = 'Editions';
  string public constant symbol = 'EDTN';
  address public defaultURIContract;

  event MetadataUpdate(uint256 _tokenId);
  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  modifier onlyMinter(uint256 id) {
    require(msg.sender == tokenIdToMinter[id], 'Caller is not the minter');
    _;
  }

  function mint(address to, uint256 id, uint256 amount) external onlyMinter(id) {
    _mint(to, id, amount, "");
  }

  function batchMint(address[] calldata recipients, uint256 id, uint256[] calldata amounts) external onlyMinter(id) {
    uint256 recipientCount = recipients.length;
    require(recipientCount == amounts.length, 'Length of recipient and amount arrays mismatched');

    for (uint256 i; i < recipientCount; ++i) {
      _mint(recipients[i], id, amounts[i], "");
    }
  }

  function setMinterForToken(uint256 id, address minter) external onlyOwner {
    tokenIdToMinter[id] = minter;
  }

  function setURIContractForToken(uint256 id, address addr) external onlyOwner {
    tokenIdToURIContract[id] = addr;
    emit MetadataUpdate(id);
  }

  function setDefaultURIContract(address addr) external onlyOwner {
    defaultURIContract = addr;
  }

  function uri(uint256 id) external view returns (string memory) {
    if (tokenIdToURIContract[id] == address(0)) {
      return TokenURI(defaultURIContract).uri(id);
    } else {
      return TokenURI(tokenIdToURIContract[id]).uri(id);
    }
  }


  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == msg.sender || balanceOf(msg.sender, tokenId) > 0,
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(msg.sender, tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(msg.sender, eventType, content);
  }

  // Royalty Info
  function setRoyaltyInfo(
    uint256 tokenId,
    address _royaltyBenificiary,
    uint16 _royaltyBasisPoints
  ) external onlyOwner {
    tokenIdToRoyaltyBP[tokenId] = _royaltyBasisPoints;
    tokenIdToRoyaltyBeneficiary[tokenId] = _royaltyBenificiary;
  }

  function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns (address, uint256) {
    return (tokenIdToRoyaltyBeneficiary[tokenId], _salePrice * tokenIdToRoyaltyBP[tokenId] / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}