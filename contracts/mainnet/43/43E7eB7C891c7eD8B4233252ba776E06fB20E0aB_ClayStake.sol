// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ClayLibrary.sol";
import "./ClayGen.sol";

interface IClayStorage {  
  function setStorage(uint256 id, uint128 key, uint256 value) external;
  function getStorage(uint256 id, uint128 key) external view returns (uint256);
}

interface IMudToken {  
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

interface IClayTraitModifier {
  function renderAttributes(uint256 _t) external view returns (string memory);
}

contract ClayStake is Ownable, ReentrancyGuard, IClayTraitModifier  {
  IClayStorage internal storageContract;
  IERC721 internal nftContract;
  IMudToken internal tokenContract;

  uint256 internal immutable startCountTime;

  uint128 public constant LAST_MUD_WITHDRAWAL = 1;

  constructor() {
    startCountTime = block.timestamp;
  }

  function setStorageContract(address _storageContract) public onlyOwner {
    storageContract = IClayStorage(_storageContract);
  }

  function setNFTContract(address _nftContract) public onlyOwner {
    nftContract = IERC721(_nftContract);
  }

  function setTokenContract(address _tokenContract) public onlyOwner {
    tokenContract = IMudToken(_tokenContract);
  } 

  function getWithdrawAmountWithTimestamp(uint256 _t, uint256 lastMudWithdrawal) internal view returns (uint256) {
    ClayLibrary.Traits memory traits = ClayLibrary.getTraits(_t);

    uint256 largeOre = traits.largeOre == 1 ? 2 : 1;

    uint256 withdrawAmount = (ClayLibrary.getBaseMultiplier(traits.base) * 
      ClayLibrary.getOreMultiplier(traits.ore) * largeOre) / 1000 * 1 ether;

    uint256 stakeStartTime = lastMudWithdrawal;
    uint256 firstTimeBonus = 0;
    if(lastMudWithdrawal == 0) {
      stakeStartTime = startCountTime;
      firstTimeBonus = 100 * 1 ether;
    }

    uint256 stakingTime = block.timestamp - stakeStartTime;
    withdrawAmount *= stakingTime;
    withdrawAmount /= 1 days;
    withdrawAmount += firstTimeBonus;
    return withdrawAmount;
  }

  function getWithdrawAmount(uint256 _t) public view returns (uint256) {
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, LAST_MUD_WITHDRAWAL);
    return getWithdrawAmountWithTimestamp(_t, lastMudWithdrawal);
  }

  function getWithdrawTotal(uint256[] calldata ids) public view returns (uint256) {
    uint256 accum = 0;
    for(uint256 i = 0;i < ids.length;i++) {
      accum += getWithdrawAmount(ids[i]);
    }

    return accum;
  }

  function withdraw(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not NFT owner");
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, LAST_MUD_WITHDRAWAL);
    storageContract.setStorage(_t, LAST_MUD_WITHDRAWAL, block.timestamp);
    uint256 withdrawAmount = getWithdrawAmountWithTimestamp(_t, lastMudWithdrawal);
    tokenContract.mint(msg.sender, withdrawAmount);
  }

  function withdrawAll(uint256[] calldata ids) public {
    for(uint256 i = 0;i < ids.length;i++) {
      withdraw(ids[i]);
    }
  }

  function renderAttributes(uint256 _t) external view returns (string memory) {
    string memory metadataString = ClayGen.renderAttributes(_t);
    uint256 mud = getWithdrawAmount(_t);
    metadataString = string(
      abi.encodePacked(
        metadataString,
        ',{"trait_type":"Mud","value":',
        ClayLibrary.toString(mud / 1 ether),
        '}'
      )
    );

    return string(abi.encodePacked("[", metadataString, "]"));
  } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library ClayLibrary {
  uint256 public constant SEED = 144261992486;
  
  struct Traits {
    uint8 base;
    uint8 ore;
    uint8 largeOre;
  }

  function getTiers() internal pure returns (uint16[][3] memory) {
    uint16[][3] memory TIERS = [
      new uint16[](4),
      new uint16[](9),
      new uint16[](2)      
    ];

    //Base
    TIERS[0][0] = 4000;
    TIERS[0][1] = 3000;
    TIERS[0][2] = 2000;
    TIERS[0][3] = 1000;

    //Ore
    TIERS[1][0] = 5000;
    TIERS[1][1] = 1500;
    TIERS[1][2] = 1500;
    TIERS[1][3] = 750;
    TIERS[1][4] = 750;
    TIERS[1][5] = 200;
    TIERS[1][6] = 200;
    TIERS[1][7] = 90;
    TIERS[1][8] = 10;

    //LargeOre
    TIERS[2][0] = 7500;
    TIERS[2][1] = 2500;

    return TIERS;
  }

  function getBaseMultiplier(uint index) internal pure returns (uint256) {
    uint8[4] memory baseTiers = [
      10,
      20,
      30,
      40
    ];

    return uint256(baseTiers[index]);
  }

  function getOreMultiplier(uint index) internal pure returns (uint256) {
     uint16[9] memory oreTiers = [
      1000,
      2500,
      3000,
      3500,
      4000,
      1500,
      2000,
      6000,
      10000
    ];

    return uint256(oreTiers[index]);
  }

  function getTraitIndex(string memory _hash, uint index) internal pure returns (uint8) {
    return parseInt(substring(_hash, index, index + 1));
  }

  function getTraits(uint256 _t) internal pure returns (Traits memory) {
    string memory _hash = generateMetadataHash(_t);
    uint8 baseIndex = getTraitIndex(_hash, 0);
    uint8 oreIndex = getTraitIndex(_hash, 1);
    uint8 largeOreIndex = getTraitIndex(_hash, 2);
    return Traits(baseIndex, oreIndex, largeOreIndex);
  }

    function generateMetadataHash(uint256 _t)
        internal
        pure
        returns (string memory)
    {
      string memory currentHash = "";
      for (uint8 i = 0; i < 3; i++) {
          uint16 _randinput = uint16(
              uint256(keccak256(abi.encodePacked(_t, SEED))) % 10000
          );

          currentHash = string(
              abi.encodePacked(currentHash, rarityGen(_randinput, i))
          );
      }

      return currentHash;
    }

    function rarityGen(
        uint256 _randinput,
        uint8 _rarityTier
    ) internal pure returns (string memory) {
      uint16[][3] memory TIERS = getTiers();
      uint16 currentLowerBound = 0;
      for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
          uint16 thisPercentage = TIERS[_rarityTier][i];
          if (
              _randinput >= currentLowerBound &&
              _randinput < currentLowerBound + thisPercentage
          ) return toString(i);
          currentLowerBound = currentLowerBound + thisPercentage;
      }

      revert();
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function stringLength(
        string memory str
    ) internal pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        return strBytes.length;
    }

    function isNotEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ClayLibrary.sol";

library ClayGen {  
  struct Trait {
    string traitType;
    string traitName;
  }

  function getTiers() internal pure returns (uint16[][6] memory) {
    uint16[][6] memory TIERS = [
      new uint16[](4),
      new uint16[](9),
      new uint16[](2),
      new uint16[](2),
      new uint16[](6),
      new uint16[](2)      
    ];

    //Base
    TIERS[0][0] = 4000;
    TIERS[0][1] = 3000;
    TIERS[0][2] = 2000;
    TIERS[0][3] = 1000;

    //Ore
    TIERS[1][0] = 5000;
    TIERS[1][1] = 1500;
    TIERS[1][2] = 1500;
    TIERS[1][3] = 750;
    TIERS[1][4] = 750;
    TIERS[1][5] = 200;
    TIERS[1][6] = 200;
    TIERS[1][7] = 90;
    TIERS[1][8] = 10;
    
    //HasEyes
    TIERS[2][0] = 8000; 
    TIERS[2][1] = 2000;

    //HasMouth
    TIERS[3][0] = 9000;
    TIERS[3][1] = 1000;

    //BgColor
    TIERS[4][0] = 2000;
    TIERS[4][1] = 2000;
    TIERS[4][2] = 1500;
    TIERS[4][3] = 1500;
    TIERS[4][4] = 1500;
    TIERS[4][5] = 1500;

    //LargeOre
    TIERS[5][0] = 7500;
    TIERS[5][1] = 2500;

    return TIERS;
  }

  function getTraitTypes() internal pure returns (Trait[][6] memory) {
    Trait[][6] memory TIERS = [
      new Trait[](4),
      new Trait[](9),
      new Trait[](2),
      new Trait[](2),
      new Trait[](6),
      new Trait[](2)      
    ];

    //Base
    TIERS[0][0] = Trait('Base', 'Clay');
    TIERS[0][1] = Trait('Base', 'Stone');
    TIERS[0][2] = Trait('Base', 'Metal');
    TIERS[0][3] = Trait('Base', 'Obsidian');

    //Ore
    TIERS[1][0] = Trait('Ore', 'None');
    TIERS[1][1] = Trait('Ore', 'Grass');
    TIERS[1][2] = Trait('Ore', 'Bronze');
    TIERS[1][3] = Trait('Ore', 'Jade');
    TIERS[1][4] = Trait('Ore', 'Gold');
    TIERS[1][5] = Trait('Ore', 'Ruby');
    TIERS[1][6] = Trait('Ore', 'Sapphire');
    TIERS[1][7] = Trait('Ore', 'Amethyst');
    TIERS[1][8] = Trait('Ore', 'Diamond');
    
    //HasEyes
    TIERS[2][0] = Trait('HasEyes', 'No'); 
    TIERS[2][1] = Trait('HasEyes', 'Yes');

    //HasMouth
    TIERS[3][0] = Trait('HasMouth', 'No');
    TIERS[3][1] = Trait('HasMouth', 'Yes');

    //BgColor
    TIERS[4][0] = Trait('BgColor', 'Forest');
    TIERS[4][1] = Trait('BgColor', 'Mountain');
    TIERS[4][2] = Trait('BgColor', 'River');
    TIERS[4][3] = Trait('BgColor', 'Field');
    TIERS[4][4] = Trait('BgColor', 'Cave');
    TIERS[4][5] = Trait('BgColor', 'Clouds');

    //LargeOre
    TIERS[5][0] = Trait('LargeOre', 'No');
    TIERS[5][1] = Trait('LargeOre', 'Yes');

    return TIERS;
  }

    function generateMetadataHash(uint256 _t, uint256 _c)
        internal
        pure
        returns (string memory)
    {
        string memory currentHash = "";
        for (uint8 i = 0; i < 6; i++) {
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(_t, _c))) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        return currentHash;
    }

    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        pure
        returns (string memory)
    {
      uint16[][6] memory TIERS = getTiers();
      uint16 currentLowerBound = 0;
      for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
          uint16 thisPercentage = TIERS[_rarityTier][i];
          if (
              _randinput >= currentLowerBound &&
              _randinput < currentLowerBound + thisPercentage
          ) return ClayLibrary.toString(i);
          currentLowerBound = currentLowerBound + thisPercentage;
      }

      revert();
    }

    function renderAttributesFromHash(string memory _hash, uint256 _t) internal pure returns (string memory) {
      uint256 seed = uint256(keccak256(abi.encodePacked(_t, ClayLibrary.SEED))) % 100000;
      Trait[][6] memory traitTypes = getTraitTypes();
      string memory metadataString;
      for (uint8 i = 0; i < 6; i++) {
          uint8 thisTraitIndex = ClayLibrary.parseInt(ClayLibrary.substring(_hash, i, i + 1));
          Trait memory trait = traitTypes[i][thisTraitIndex];
          metadataString = string(
              abi.encodePacked(
                  metadataString,
                  '{"trait_type":"',
                  trait.traitType,
                  '","value":"',
                  trait.traitName,
                  '"}'
              )
          );

          metadataString = string(abi.encodePacked(metadataString, ","));
      }

      metadataString = string(
          abi.encodePacked(
              metadataString,
              '{"trait_type":"Seed","value":"',
              ClayLibrary.toString(seed),
              '"}'
          )
      );

      return metadataString;
    }

    function renderAttributes(uint256 _t) internal pure returns (string memory) {
      string memory _hash = generateMetadataHash(_t, ClayLibrary.SEED);
      return renderAttributesFromHash(_hash, _t);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}