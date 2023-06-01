// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibUtils } from "../libraries/LibUtils.sol";
import { LibERC721 } from "../libraries/LibERC721.sol";
import { LibIdentity, IdentityLayout, ScrollField, Scroll, IdentityExternal, ScrollFieldExternal, ScrollExternal } from "../libraries/LibIdentity.sol";

contract IdentityFacet {
  modifier scrollOwner(uint256 scrollId) {
    require(LibIdentity.getStorage().scrolls[scrollId].owner == LibUtils.msgSender(), "IdentityFacet: Not owner of scroll");
    _;
  }

  function mintScroll(uint256 quantity) public {
    address sender = LibUtils.msgSender();
    require(LibERC721.balanceOf(sender) > 0, "IdentityFacet: No NFT tokens owned");

    LibIdentity.mint(sender, quantity);
  }

  function unlockScrollField(uint256 scrollId) public scrollOwner(scrollId) {
    IdentityLayout storage idStorage = LibIdentity.getStorage();
    Scroll storage currentScroll = idStorage.scrolls[scrollId];

    require(currentScroll.unlockedFields < idStorage.maxFields, "IdentityFacet: Max fields unlocked");

    currentScroll.unlockedFields++;
  }

  function setScrollField(uint256 scrollId, string calldata fieldName, string calldata fieldData) public scrollOwner(scrollId) {
    IdentityLayout storage idStorage = LibIdentity.getStorage();
    Scroll storage currentScroll = idStorage.scrolls[scrollId];

    require(currentScroll.fieldCount < idStorage.maxFields, "IdentityFacet: Max fields used");
    require(currentScroll.fieldCount < currentScroll.unlockedFields, "IdentityFacet: No unlocked fields available");

    currentScroll.fields[currentScroll.fieldCount++] = ScrollField({ name: fieldName, data: fieldData });
  }

  function attachTokenToScroll(uint256 scrollId, uint16 tokenId) public scrollOwner(scrollId) {
    address sender = LibUtils.msgSender();
    require(LibERC721.ownerOf(tokenId) == sender, "IdentityFacet: Not token owner");
    IdentityLayout storage idStorage = LibIdentity.getStorage();
    Scroll storage currentScroll = idStorage.scrolls[scrollId];

    currentScroll.attachedToken = tokenId;
    idStorage.tokenToScroll[tokenId] = scrollId;
  }

  function removeScrollToken(uint256 scrollId) public scrollOwner(scrollId) {
    IdentityLayout storage idStorage = LibIdentity.getStorage();
    Scroll storage currentScroll = idStorage.scrolls[scrollId];

    idStorage.tokenToScroll[currentScroll.attachedToken] = 0;
    LibIdentity.removeToken(scrollId);
  }

  function attachIdentityScroll(uint256 scrollId) public scrollOwner(scrollId) {
    address sender = LibUtils.msgSender();
    require(!LibIdentity.hasIdentity(sender), "IdentityFacet: Identity scroll already attached");

    IdentityLayout storage idStorage = LibIdentity.getStorage();
    idStorage.scrolls[scrollId].isAttached = true;
    idStorage.userData[sender].attachedScroll = scrollId;
    idStorage.identitiesRecorded++;
  }

  function removeIdentity() public {
    address sender = LibUtils.msgSender();
    require(LibIdentity.hasIdentity(sender), "IdentityFacet: Identity doesnt exist");

    LibIdentity.removeIdentity(sender);
  }

  function transferScroll(address from, address to, uint256 scrollId) public {
    require(
      (LibIdentity.getStorage().scrolls[scrollId].owner == from && LibUtils.msgSender() == from) || msg.sender == address(this),
      "IdentityFacet: Not scroll owner"
    );

    require(!LibIdentity.isAttached(scrollId), "IdentityFacet: Cant transfer scroll attached to identity");
    require(LibIdentity.isTransferable(scrollId), "IdentityFacet: Cant transfer scroll with attached token");

    LibIdentity.transfer(from, to, scrollId);
  }

  function scrollBalance(address user) public view returns (uint256) {
    return LibIdentity.getStorage().userData[user].scrollCount;
  }

  function getScroll(uint256 scrollId) public view returns (ScrollExternal memory) {
    IdentityLayout storage idStorage = LibIdentity.getStorage();
    require(scrollId <= idStorage.scrollSupply, "IdentityFacet: Scroll ID out of bounds");

    Scroll storage currentScroll = idStorage.scrolls[scrollId];

    ScrollExternal memory queryScroll = ScrollExternal({
      owner: currentScroll.owner,
      fieldCount: currentScroll.fieldCount,
      unlockedFields: currentScroll.unlockedFields,
      attachedToken: currentScroll.attachedToken,
      isAttached: currentScroll.isAttached,
      fields: new ScrollFieldExternal[](currentScroll.fieldCount)
    });

    if (currentScroll.fieldCount > 0) {
      for (uint8 i = 0; i < currentScroll.fieldCount; i++) {
        queryScroll.fields[i] = ScrollFieldExternal({ id: i, name: currentScroll.fields[i].name, data: currentScroll.fields[i].data });
      }
    }

    return queryScroll;
  }

  function getOwnedScrolls(address user) public view returns (uint256[] memory) {
    IdentityLayout storage idStorage = LibIdentity.getStorage();

    uint256 scrollIdxs = 0;
    uint256 userScrollCount = idStorage.userData[user].scrollCount;
    uint256[] memory ownedScrolls = new uint256[](userScrollCount);

    if (userScrollCount == 0) return ownedScrolls;

    for (uint256 index = 0; index <= idStorage.scrollSupply; index++) {
      if (idStorage.scrolls[index].owner == user) ownedScrolls[scrollIdxs++] = index;
      if (scrollIdxs == userScrollCount) break;
    }

    return ownedScrolls;
  }

  function getIdentity(address user) public view returns (IdentityExternal memory) {
    require(LibIdentity.hasIdentity(user), "IdentityFacet: No identity scroll attached");

    IdentityLayout storage idStorage = LibIdentity.getStorage();
    Scroll storage attachedScroll = idStorage.scrolls[idStorage.userData[user].attachedScroll];

    IdentityExternal memory _identity = IdentityExternal({
      attachedToken: attachedScroll.attachedToken,
      fields: new ScrollFieldExternal[](attachedScroll.fieldCount)
    });

    for (uint8 i = 0; i < attachedScroll.fieldCount; i++) {
      _identity.fields[i] = ScrollFieldExternal({ id: i, name: attachedScroll.fields[i].name, data: attachedScroll.fields[i].data });
    }

    return _identity;
  }

  function totalIdentities() public view returns (uint256) {
    return LibIdentity.getStorage().identitiesRecorded;
  }

  function scrollSupply() public view returns (uint256) {
    return LibIdentity.scrollSupply();
  }

  function maxFields() public view returns (uint256) {
    return LibIdentity.getStorage().maxFields;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { LibUtils } from "./LibUtils.sol";
import { LibIdentity } from "./LibIdentity.sol";
import { LibMarketplace, TokenType } from "./LibMarketplace.sol";

interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

struct TokenApprovalRef {
  address value;
}

struct StorageLayout {
  string name;
  string symbol;
  uint16 maxSupply;
  uint16 creatorSupply;
  uint16 creatorMaxSupply;
  bool burnActive;
  uint256 _currentIndex;
  uint256 _burnCounter;
  mapping(uint256 => uint256) _packedOwnerships;
  mapping(address => uint256) _packedAddressData;
  mapping(uint256 => TokenApprovalRef) _tokenApprovals;
  mapping(address => mapping(address => bool)) _operatorApprovals;
}

//solhint-disable no-inline-assembly, reason-string, no-empty-blocks
library LibERC721 {
  // =============================================================
  //                           CONSTANTS
  // =============================================================

  bytes32 internal constant STORAGE_SLOT = keccak256("ERC721A.contracts.storage.ERC721A");
  uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
  uint256 internal constant _BITMASK_BURNED = 1 << 224;
  uint256 internal constant _BITPOS_NUMBER_BURNED = 128;
  uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
  uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;
  uint256 internal constant _BITPOS_NUMBER_MINTED = 64;
  uint256 internal constant _BITPOS_AUX = 192;
  uint256 internal constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
  uint256 internal constant _BITPOS_START_TIMESTAMP = 160;
  uint256 internal constant _BITPOS_EXTRA_DATA = 232;
  uint256 internal constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;
  uint256 internal constant _startTokenId = 1;

  function getStorage() internal pure returns (StorageLayout storage strg) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  function _mint(address to, uint256 quantity) internal {
    StorageLayout storage ds = getStorage();
    uint256 startTokenId = ds._currentIndex;

    require(quantity > 0, "LibERC721: Cant mint 0 tokens");
    require(totalSupply() + quantity <= ds.maxSupply, "LibERC721: Max supply exceeded");
    bytes32 transferEventSig = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 bitMaskAddress = (1 << 160) - 1;

    unchecked {
      ds._packedAddressData[to] += quantity * ((1 << 64) | 1);
      ds._packedOwnerships[startTokenId] = _packOwnershipData(to, _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0));

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      assembly {
        toMasked := and(to, bitMaskAddress)
        log4(0, 0, transferEventSig, 0, toMasked, startTokenId)
        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          log4(0, 0, transferEventSig, 0, toMasked, tokenId)
        }
      }
      require(toMasked != 0, "LibERC721: Cant mint to zero address");
      ds._currentIndex = end;
    }
  }

  function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
    StorageLayout storage ds = getStorage();
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = ds._currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert("LibERC721: Transfer to non ERC721Receiver");
          }
        } while (index < end);
        // Reentrancy protection.
        // solhint-disable-next-line reason-string
        if (ds._currentIndex != end) revert();
      }
    }
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function _burn(uint256 tokenId, bool approvalCheck) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
    address from = address(uint160(prevOwnershipPacked));
    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
        if (!isApprovedForAll(from, LibUtils.msgSender())) revert("LibERC721: Call not authorized");
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      ds._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;
      ds._packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
      ds._burnCounter++;
    }
  }

  function transferFrom(address from, address to, uint256 tokenId) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    if (address(uint160(prevOwnershipPacked)) != from) revert("LibERC721: Transfer from incorrect owner");

    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
      if (!isApprovedForAll(from, LibUtils.msgSender()) || LibUtils.msgSender() != address(this)) revert("LibERC721: Caller not owner nor approved");

    if (to == address(0)) revert("LibERC721: Transfer to zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      --ds._packedAddressData[from];
      ++ds._packedAddressData[to];

      ds._packedOwnerships[tokenId] = _packOwnershipData(to, _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked));

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert("LibERC721: Transfer to non ERC721 receiver");
      }
  }

  function isApprovedForAll(address owner, address operator) internal view returns (bool) {
    return getStorage()._operatorApprovals[owner][operator];
  }

  function _isSenderApprovedOrOwner(address approvedAddress, address owner, address msgSender) internal pure returns (bool result) {
    assembly {
      owner := and(owner, _BITMASK_ADDRESS)
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    try IERC721Receiver(to).onERC721Received(LibUtils.msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      require(reason.length > 0, "LibERC721: Transfer to non ERC721Receiver");
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal {}

  function _afterTokenTransfers(address from, address, uint256 tokenId, uint256) internal {
    if (from != address(0)) {
      if (balanceOf(from) == 0) {
        if (LibIdentity.hasIdentity(from)) LibIdentity.removeIdentity(from);
      }

      if (LibIdentity.hasScroll(tokenId)) {
        LibIdentity.removeToken(LibIdentity.getStorage().tokenToScroll[tokenId]);
      }

      if (LibMarketplace.isListed(TokenType.NFT, tokenId)) LibMarketplace.cancelListing(TokenType.NFT, tokenId);
    }
  }

  function _nextInitializedFlag(uint256 quantity) internal pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(225, eq(quantity, 1))
    }
  }

  function _nextExtraData(address from, address to, uint256 prevOwnershipPacked) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> 232);
    return uint256(_extraData(from, to, extraData)) << 232;
  }

  function _extraData(address from, address to, uint24 previousExtraData) internal view returns (uint24) {}

  function _packOwnershipData(address owner, uint256 flags) internal view returns (uint256 result) {
    uint256 bitMaskAddress = (1 << 160) - 1;
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, bitMaskAddress)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(160, timestamp()), flags))
    }
  }

  function nextTokenId() internal view returns (uint256) {
    return getStorage()._currentIndex;
  }

  function balanceOf(address owner) internal view returns (uint256) {
    require(owner != address(0), "LibERC721: Invalid address");
    return getStorage()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  function ownerOf(uint256 tokenId) internal view returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  function totalSupply() internal view returns (uint256) {
    StorageLayout storage ds = getStorage();
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId` times.
    unchecked {
      return ds._currentIndex - ds._burnCounter - _startTokenId;
    }
  }

  function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256 packed) {
    StorageLayout storage ds = getStorage();
    if (_startTokenId <= tokenId) {
      packed = ds._packedOwnerships[tokenId];
      if (packed & _BITMASK_BURNED == 0) {
        if (packed == 0) {
          if (tokenId >= ds._currentIndex) revert("LibERC721: Owner query for non existing token");
          for (;;) {
            unchecked {
              packed = ds._packedOwnerships[--tokenId];
            }
            if (packed == 0) continue;
            return packed;
          }
        }
        return packed;
      }
    }
    revert("LibERC721: Owner query for non existing token");
  }

  function _getApprovedSlotAndAddress(uint256 tokenId) internal view returns (uint256 approvedAddressSlot, address approvedAddress) {
    TokenApprovalRef storage tokenApproval = getStorage()._tokenApprovals[tokenId];
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { LibERC721 } from "./LibERC721.sol";

struct IdentityExternal {
  uint16 attachedToken;
  ScrollFieldExternal[] fields;
}

struct ScrollFieldExternal {
  uint256 id;
  string name;
  string data;
}

struct ScrollExternal {
  address owner;
  uint8 fieldCount;
  uint8 unlockedFields;
  uint16 attachedToken;
  bool isAttached;
  ScrollFieldExternal[] fields;
}

struct ScrollField {
  string name;
  string data;
}

struct Scroll {
  address owner;
  uint8 fieldCount;
  uint8 unlockedFields;
  uint16 attachedToken;
  bool isAttached;
  mapping(uint8 => ScrollField) fields;
}

struct UserData {
  uint256 attachedScroll;
  uint256 scrollCount;
}

struct IdentityLayout {
  uint256 maxFields;
  uint256 scrollSupply;
  uint256 identitiesRecorded;
  mapping(uint256 => Scroll) scrolls;
  mapping(address => UserData) userData;
  mapping(uint256 => uint256) tokenToScroll;
}

library LibIdentity {
  bytes32 internal constant IDENTITY_DATA_SLOT = keccak256("user.identity.data.layout");

  function getStorage() internal pure returns (IdentityLayout storage strg) {
    bytes32 slot = IDENTITY_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function mint(address owner, uint256 quantity) internal {
    IdentityLayout storage ids = getStorage();
    if (quantity > 1) {
      for (uint i = 0; i < quantity; i++) {
        ids.scrollSupply++;
        ids.scrolls[ids.scrollSupply].owner = owner;
        ids.userData[owner].scrollCount++;
      }
    } else {
      ids.scrollSupply++;
      ids.scrolls[ids.scrollSupply].owner = owner;

      ids.userData[owner].scrollCount++;
    }
  }

  function transfer(address from, address to, uint256 scrollId) internal {
    IdentityLayout storage ids = getStorage();

    ids.scrolls[scrollId].owner = to;

    ids.userData[from].scrollCount--;
    ids.userData[to].scrollCount++;
  }

  function removeIdentity(address user) internal {
    IdentityLayout storage ids = getStorage();

    ids.scrolls[ids.userData[user].attachedScroll].isAttached = false;
    delete ids.userData[user].attachedScroll;
    ids.identitiesRecorded--;
  }

  function removeToken(uint256 scrollId) internal {
    Scroll storage currentScroll = getStorage().scrolls[scrollId];

    currentScroll.attachedToken = 0;
  }

  function scrollSupply() internal view returns (uint256) {
    return getStorage().scrollSupply;
  }

  function getOwner(uint256 scrollId) internal view returns (address) {
    return getStorage().scrolls[scrollId].owner;
  }

  function isTransferable(uint256 scrollId) internal view returns (bool) {
    return getStorage().scrolls[scrollId].attachedToken == 0;
  }

  function isAttached(uint256 scrollId) internal view returns (bool) {
    return getStorage().scrolls[scrollId].isAttached;
  }

  function hasScroll(uint256 tokenId) internal view returns (bool) {
    return getStorage().tokenToScroll[tokenId] > 0;
  }

  function hasIdentity(address user) internal view returns (bool) {
    return getStorage().userData[user].attachedScroll > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum TokenType {
  NFT,
  Scroll
}

struct Listing {
  uint256 id;
  address seller;
  address sell_to;
  uint256 tokenId;
  TokenType token_type;
  uint256 price;
  uint256 sold_on;
  address sold_to;
  bool cancelled;
  uint256 created_on;
  uint256 modified_on;
}

struct ListingCounters {
  uint256 totalListings;
  uint256 activeListings;
}

struct TokenListingData {
  bool isListed;
  uint256 listingId;
}

struct MarketplaceLayout {
  ListingCounters listingCounts;
  mapping(uint256 => Listing) listings;
  mapping(address => ListingCounters) userCounts;
  mapping(address => uint256[]) userListings;
  mapping(TokenType => mapping(uint256 => TokenListingData)) token;
}

library LibMarketplace {
  bytes32 internal constant MARKETPLACE_DATA_SLOT = keccak256("erc721.marketplace.storage.layout");

  function getStorage() internal pure returns (MarketplaceLayout storage strg) {
    bytes32 slot = MARKETPLACE_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function increaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings += total;
    strg.activeListings += active;
  }

  function decreaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings -= total;
    strg.activeListings -= active;
  }

  function cancelListing(TokenType tokenType, uint256 tokenId) internal {
    MarketplaceLayout storage ls = getStorage();
    TokenListingData storage currentToken = ls.token[tokenType][tokenId];
    Listing storage currentListing = ls.listings[currentToken.listingId];

    currentListing.cancelled = true;
    currentListing.modified_on = block.timestamp;
    ls.token[tokenType][tokenId] = TokenListingData({ isListed: false, listingId: 0 });

    decreaseCounters(ls.listingCounts, 0, 1);
    decreaseCounters(ls.userCounts[currentListing.seller], 0, 1);
  }

  function isListed(TokenType tokenType, uint256 tokenId) internal view returns (bool) {
    return getStorage().token[tokenType][tokenId].isListed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// solhint-disable no-inline-assembly
library LibUtils {
  function msgSender() internal view returns (address sender_) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender_ = msg.sender;
    }
  }

  function numberToString(uint256 value) internal pure returns (string memory str) {
    assembly {
      let m := add(mload(0x40), 0xa0)
      mstore(0x40, m)
      str := sub(m, 0x20)
      mstore(str, 0)

      let end := str

      // prettier-ignore
      // solhint-disable-next-line no-empty-blocks
      for { let temp := value } 1 {} {
        str := sub(str, 1)
        mstore8(str, add(48, mod(temp, 10)))
        temp := div(temp, 10)
        if iszero(temp) { break }
      }

      let length := sub(end, str)
      str := sub(str, 0x20)
      mstore(str, length)
    }
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3 + i * 2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function getMax(uint256[6] memory nums) internal pure returns (uint256 maxNum) {
    maxNum = nums[0];
    for (uint256 i = 1; i < nums.length; i++) {
      if (nums[i] > maxNum) maxNum = nums[i];
    }
  }

  function compareStrings(string memory str1, string memory str2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}