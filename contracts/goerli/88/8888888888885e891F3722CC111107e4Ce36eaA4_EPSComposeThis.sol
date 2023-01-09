// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

/**
 
@dev EPS Compose this.

EPS Compose this provides both json and image composition services
for blockchain apps.

*/
pragma solidity 0.8.17;
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* ComposeThis Core contract
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEPSComposeThis.sol";
import "../Utils/ENSReverseRegistrar.sol";

contract EPSComposeThis is Ownable, IEPSComposeThis {
  using Strings for uint256;

  string private constant JSON_ADD = "&jsonAdd=";
  string private constant IMG_ADD = "&imgAdd=";
  string private constant CHAIN = "?chain=";
  string private constant CONTRACT = "&contract=";
  string private constant TOKEN_ID = "&tokenId=";

  string private constant EQUALS = "=";
  string constant CONTRACT_TAG = "&c=";
  string constant ID_TAG = "&id=";

  // Strings without escape characters
  string private constant COMMA = "%2C";
  string constant OPEN_TAG_TRAIT_TYPE = "%7B%22trait_type%22%3A%22";
  string constant VALUE = "%22%2C%22value%22%3A%22";
  string constant CLOSE_TAG = "%22%7D";
  string constant AMPERSAND_L = "%26l";

  // Strings with escape characters
  string private constant COMMA_ESCAPE = ",";
  string constant OPEN_TAG_TRAIT_TYPE_ESCAPE = '{"trait_type":"';
  string constant VALUE_ESCAPE = '","value":"';
  string constant CLOSE_TAG_ESCAPE = '"}';
  string constant AMPERSAND_L_ESCAPE = "&l";

  string constant BASE_IMAGE_PARAMETER = "?base=";
  string constant BASE_JSON_PARAMETER = "?jsonBase=";

  uint256 constant SECONDS_IN_A_DAY = 86400;

  ENSReverseRegistrar public ensReverseRegistrar;

  address public appToken;
  uint256 public appTokenBalanceRequired;

  string public jsonComposerService;
  string public imageComposerService;

  constructor() {
    transferOwnership(0x9F0773aF2b1d3f7cC7030304548A823B4E6b13bB);
  }

  //* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  //* ADMIN FUNCTIONS
  //* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  function setENSName(string memory ensName_) external onlyOwner {
    ensReverseRegistrar.setName(ensName_);
  }

  function setENSReverseRegistrar(address ensReverseRegistrar_)
    external
    onlyOwner
  {
    ensReverseRegistrar = ENSReverseRegistrar(ensReverseRegistrar_);
    emit ENSReverseRegistrarSet(ensReverseRegistrar_);
  }

  function updateAppToken(address appToken_) external onlyOwner {
    appToken = appToken_;
  }

  function updateAppTokenBalanceRequired(uint256 appTokenBalanceRequired_)
    external
    onlyOwner
  {
    appTokenBalanceRequired = appTokenBalanceRequired_;
  }

  function updateJSONComposerService(string memory jsonComposerService_)
    external
    onlyOwner
  {
    jsonComposerService = jsonComposerService_;
  }

  function updateImageComposerService(string memory imageComposerService_)
    external
    onlyOwner
  {
    imageComposerService = imageComposerService_;
  }

  //* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  //* COMPOSITION SERVICE
  //* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  function composeURIFromBaseURI(
    string memory baseURI_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_) {
    if (_sufficientHolding(msg.sender)) {
      string memory composedImages;

      if (imageTags_.length > 0) {
        composedImages = _composeImages(
          IMG_ADD,
          startImageTag_,
          imageTags_,
          false
        );
      }

      string memory composedTraits;

      if (addedTraits_.length > 0) {
        composedTraits = _composeTraits(JSON_ADD, addedTraits_, false);
      }

      return (
        string.concat(
          jsonComposerService,
          BASE_JSON_PARAMETER,
          baseURI_,
          composedTraits,
          composedImages
        )
      );
    } else {
      return (baseURI_);
    }
  }

  function composeURIFromLookup(
    uint256 baseURIChain_,
    address baseURIContract_,
    uint256 baseURITokenId_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_) {
    if (_sufficientHolding(msg.sender)) {
      string memory composedImages;

      if (imageTags_.length > 0) {
        composedImages = _composeImages(
          IMG_ADD,
          startImageTag_,
          imageTags_,
          false
        );
      }

      string memory composedTraits;

      if (addedTraits_.length > 0) {
        composedTraits = _composeTraits(JSON_ADD, addedTraits_, false);
      }

      return (
        string.concat(
          jsonComposerService,
          CHAIN,
          baseURIChain_.toString(),
          CONTRACT,
          Strings.toHexString(uint160(baseURIContract_)),
          TOKEN_ID,
          baseURITokenId_.toString(),
          composedTraits,
          composedImages
        )
      );
    } else {
      return ("");
    }
  }

  function composeImageFromBase(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_
  ) public view returns (string memory composedImageURL_) {
    if (_sufficientHolding(msg.sender)) {
      string memory composedImages;
      if (imageTags_.length > 0) {
        composedImages = _composeImages("", startImageTag_, imageTags_, true);
      }

      string memory collectionContract;
      if (contractAddress_ != address(0)) {
        collectionContract = string.concat(
          CONTRACT_TAG,
          Strings.toHexString(uint160(contractAddress_))
        );
      }

      string memory identifier;
      if (id_ != 0) {
        identifier = string.concat(ID_TAG, id_.toString());
      }

      return (
        string.concat(
          imageComposerService,
          BASE_IMAGE_PARAMETER,
          baseImage_,
          collectionContract,
          identifier,
          composedImages
        )
      );
    } else {
      return (baseImage_);
    }
  }

  function composeTraitsFromArray(AddedTrait[] memory addedTraits_)
    public
    view
    returns (string memory composedTraits_)
  {
    if (_sufficientHolding(msg.sender)) {
      return (_composeTraits("", addedTraits_, true));
    } else {
      return ("");
    }
  }

  function composeTraitsAndImage(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_,
    AddedTrait[] memory addedTraits_
  )
    external
    view
    returns (string memory composedTraits_, string memory composedImageURL_)
  {
    if (_sufficientHolding(msg.sender)) {
      return (
        composeTraitsFromArray(addedTraits_),
        composeImageFromBase(
          baseImage_,
          startImageTag_,
          imageTags_,
          contractAddress_,
          id_
        )
      );
    } else {
      return ("", "");
    }
  }

  function triggerMetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  ) external {
    if (_sufficientHolding(msg.sender)) {
      emit MetadataUpdate(chain, tokenContract, tokenId, futureExecutionDate);
    }
  }

  function _composeTraits(
    string memory initialString_,
    AddedTrait[] memory addedTraits_,
    bool escapeChars
  ) internal pure returns (string memory composedTraits_) {
    composedTraits_ = initialString_;

    string memory __comma;
    string memory __openTagTraitType;
    string memory __value;
    string memory __closeTag;

    if (escapeChars) {
      __comma = COMMA_ESCAPE;
      __openTagTraitType = OPEN_TAG_TRAIT_TYPE_ESCAPE;
      __value = VALUE_ESCAPE;
      __closeTag = CLOSE_TAG_ESCAPE;
    } else {
      __comma = COMMA;
      __openTagTraitType = OPEN_TAG_TRAIT_TYPE;
      __value = VALUE;
      __closeTag = CLOSE_TAG;
    }

    for (uint256 i = 0; i < addedTraits_.length; ) {
      composedTraits_ = string.concat(
        composedTraits_,
        __openTagTraitType,
        addedTraits_[i].trait,
        __value
      );
      if (addedTraits_[i].valueType == ValueType.characterString) {
        composedTraits_ = string.concat(
          composedTraits_,
          addedTraits_[i].valueString,
          __closeTag
        );
      } else if (addedTraits_[i].valueType == ValueType.number) {
        composedTraits_ = string.concat(
          composedTraits_,
          addedTraits_[i].valueInteger.toString(),
          __closeTag
        );
      } else if (addedTraits_[i].valueType == ValueType.date) {
        composedTraits_ = string.concat(
          composedTraits_,
          _timestampToDate(addedTraits_[i].valueInteger),
          __closeTag
        );
      } else if (addedTraits_[i].valueType == ValueType.chainAddress) {
        composedTraits_ = string.concat(
          composedTraits_,
          Strings.toHexString(uint160(addedTraits_[i].valueAddress), 20),
          __closeTag
        );
      } else {
        composedTraits_ = string.concat(composedTraits_, "", __closeTag);
      }
      if (i + 1 != addedTraits_.length) {
        composedTraits_ = string.concat(composedTraits_, __comma);
      }

      unchecked {
        i++;
      }
    }
    return (composedTraits_);
  }

  function _composeImages(
    string memory initialString,
    uint256 startImageTag_,
    string[] memory imageTags_,
    bool escapeChars
  ) internal pure returns (string memory composedImages_) {
    composedImages_ = initialString;

    string memory __ampersandL;

    if (escapeChars) {
      __ampersandL = AMPERSAND_L_ESCAPE;
    } else {
      __ampersandL = AMPERSAND_L;
    }

    for (uint256 i = 0; i < imageTags_.length; ) {
      composedImages_ = string.concat(
        composedImages_,
        __ampersandL,
        (startImageTag_ + i).toString(),
        EQUALS,
        imageTags_[i]
      );
      unchecked {
        i++;
      }
    }

    return (composedImages_);
  }

  function _timestampToDate(uint256 timestamp_)
    internal
    pure
    virtual
    returns (string memory)
  {
    (uint256 year, uint256 month, uint256 day) = (
      _daysToDate(timestamp_ / SECONDS_IN_A_DAY)
    );
    return (
      string.concat(
        _monthInWords(month),
        " ",
        day.toString(),
        " ",
        year.toString()
      )
    );
  }

  function _sufficientHolding(address caller_) internal view returns (bool) {
    if (appToken != address(0) && appTokenBalanceRequired != 0) {
      return ((IERC721(appToken).balanceOf(caller_) + 1) >
        appTokenBalanceRequired);
    } else {
      return true;
    }
  }

  function _monthInWords(uint256 month_) internal pure returns (string memory) {
    if (month_ == 1) return "Jan";
    if (month_ == 2) return "Feb";
    if (month_ == 3) return "Mar";
    if (month_ == 4) return "Apr";
    if (month_ == 5) return "May";
    if (month_ == 6) return "Jun";
    if (month_ == 7) return "Jul";
    if (month_ == 8) return "Aug";
    if (month_ == 9) return "Sep";
    if (month_ == 10) return "Oct";
    if (month_ == 11) return "Nov";
    else return "Dec";
  }

  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + 2440588;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

abstract contract ENSReverseRegistrar {
  function setName(string memory name) public virtual returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

/**
 
@dev EPS Compose this.

EPS Compose this provides both json and image composition services
for blockchain apps.

*/
pragma solidity 0.8.17;

enum ValueType {
  none,
  characterString,
  number,
  date,
  chainAddress
}

struct AddedTrait {
  string trait;
  ValueType valueType;
  uint256 valueInteger;
  string valueString;
  address valueAddress;
}

interface IEPSComposeThis {
  event MetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  );

  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  function composeURIFromBaseURI(
    string memory baseString_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeURIFromLookup(
    uint256 baseURIChain_,
    address baseURIContract_,
    uint256 baseURITokenId_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeTraitsFromArray(AddedTrait[] memory addedTraits_)
    external
    view
    returns (string memory composedImageURL_);

  function composeImageFromBase(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress,
    uint256 id
  ) external view returns (string memory composedImageURL_);

  function composeTraitsAndImage(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_,
    AddedTrait[] memory addedTraits_
  )
    external
    view
    returns (string memory composedImageURL_, string memory composedTraits_);

  function triggerMetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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