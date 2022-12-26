// SPDX-License-Identifier: MIT


/*
   ____  _    _ ______          __ __     __
  / ____| |  | |  _ \ \        / /\\ \   / /
 | (___ | |  | | |_) \ \  /\  / /  \\ \_/ /
  \___ \| |  | |  _ < \ \/  \/ / /\ \\   /
  ____) | |__| | |_) | \  /\  / ____ \| |
 |_____/ \____/|____/_ _\/  \/_/____\_\_|
      | |  ____|/ ____| |  | |/ ____|
      | | |__  | (___ | |  | | (___
  _   | |  __|  \___ \| |  | |\___ \
 | |__| | |____ ____) | |__| |____) |
  \____/|______|_____/_\____/|_____/_      ______ _______ _____
 |  __ \ /\   |  \/  |  __ \| |  | | |    |  ____|__   __/ ____|
 | |__) /  \  | \  / | |__) | |__| | |    | |__     | | | (___
 |  ___/ /\ \ | |\/| |  ___/|  __  | |    |  __|    | |  \___ \
 | |  / ____ \| |  | | |    | |  | | |____| |____   | |  ____) |
 |_| /_/    \_\_|  |_|_|    |_|  |_|______|______|  |_| |_____/

Contract by steviep.eth
absolveSins by julien.eth
*/

import "./Dependencies.sol";
import "./Metadata.sol";
import "./ChurchOfSubwayJesusPamphlets.sol";

pragma solidity ^0.8.11;

interface IOSSharedStorefront {
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

contract SubwayJesusPamphlets is ERC721 {
  uint256 private _totalSupply = 76;
  Metadata private _metadataContract;
  address public church;
  IOSSharedStorefront private _purgatory;


  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 1000;

  constructor(address _os) ERC721("Subway Jesus Pamphlets", 'JESUS') {
    royaltyBenificiary = msg.sender;
    _metadataContract = new Metadata();
    _purgatory = IOSSharedStorefront(_os);
    church = address(new ChurchOfSubwayJesusPamphlets(this, msg.sender));

    // mint tokens 0 - 75
    _mint(msg.sender, 0);

    for (uint256 i = 1; i < 76; i++) {
      _mint(0x6666666666666666666666666666666666666666, i);
    }
  }

  function purgatory() public view returns (address) {
    return address(_purgatory);
  }

  modifier onlyChurch {
    require(church == msg.sender, 'Caller is not the church');
    _;
  }

  function transferChurch(address newChurch) external onlyChurch {
    church = newChurch;
  }

  function absolveSins(uint256 tokenId, address to) internal {
    uint256 originalIndex = tokenId >> 40 & 0x0000000000000000000000000000000000000000FFFFFFFFFFFFFF;

    // Make sure token is from original SJP collection
    if (
      originalIndex == 9  ||
      originalIndex == 10 ||
      originalIndex == 52 ||
      originalIndex == 54 ||
      originalIndex >= 67
    ) {
      require(tokenId >> 96 == 0x0047144372eb383466d18fc91db9cd0396aa6c87a4, 'Not Subway Jesus Pamphlet token');
    } else {
      require(tokenId >> 96 == 0x007C23C1B7E544E3E805BA675C811E287FC9D71949, 'Not Subway Jesus Pamphlet token');
    }

    // Get new token ID
    uint256 newTokenId;
    if (originalIndex <= 65) {
      // Original starts at 2, so subtract by 1 to start them at 1
      newTokenId = originalIndex - 1;
    } else {
      // 66 was skipped, so subtract by 2 for the rest
      newTokenId = originalIndex - 2;
    }

    // Absolution
    _transfer(0x6666666666666666666666666666666666666666, to, newTokenId);
  }

  function onERC1155Received(
    address,
    address from,
    uint256 id,
    uint256 amount,
    bytes calldata
  ) external returns (bytes4) {
    require(msg.sender == address(_purgatory), 'Cannot absolve sins without purgatory');
    require(amount == 1, 'Must absolve a single token');

    absolveSins(id, from);
    _purgatory.safeTransferFrom(address(this), church, id, amount, '');
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata
  ) external returns (bytes4) {
    require(msg.sender == address(_purgatory), 'Cannot absolve sins without purgatory');

    for (uint256 i = 0; i < ids.length; i++) {
      require(amounts[i] == 1, 'Must absolve a single token');
      absolveSins(ids[i], from);
    }
    _purgatory.safeBatchTransferFrom(address(this), church, ids, amounts, '');

    return this.onERC1155BatchReceived.selector;
  }

  function mintBatch(address[] calldata to) external onlyChurch {
    for (uint256 i; i < to.length; i++) {
      _mint(to[i], _totalSupply + i);
    }
    _totalSupply += to.length;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    return _metadataContract.tokenURI(tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981
    return interfaceId == bytes4(0x2a55205a) || super.supportsInterface(interfaceId);
  }

  function metadataContract() external view returns (address) {
    return address(_metadataContract);
  }

  function setMetadataContract(address _addr) external onlyChurch {
    _metadataContract = Metadata(_addr);
  }


  function setRoyaltyInfo(
    address _royaltyBenificiary,
    uint16 _royaltyBasisPoints
  ) external onlyChurch {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }


  event ProjectEvent(
    address indexed poster,
    string indexed eventType,
    string content
  );
  event TokenEvent(
    address indexed poster,
    uint256 indexed tokenId,
    string indexed eventType,
    string content
  );

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyChurch {
    emit ProjectEvent(_msgSender(), eventType, content);
  }

  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      church == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }
}