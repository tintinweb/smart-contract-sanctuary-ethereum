// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Layer.sol";

contract LayerInstance is Layer {
  constructor(
    string memory _layerName,
    address _composableNFTAddress,
    bool _isDefaultLayer
  ) {
    composableNFTAddress = _composableNFTAddress;
    isDefaultLayer = _isDefaultLayer;

    layerName = _layerName;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Layer is Ownable {
  /// @notice address of the NFT contract that combines all of the individual layers together
  address public composableNFTAddress;

  /// @notice cost to change color - 0.007 ETH
  uint256 public colorChangePrice = 7000000000000000;

  /// @notice a layer can be either a default or optional layer. The former are selected at time of mint. The latter are optional accessories
  bool public isDefaultLayer;

  /// @notice Records the selected layer option for each individual NFT
  mapping (uint256 => OptionSelection) public selectedOption;

  /// @notice array holding all the potential options for an individual layer
  Option[] public layerOptions;

  /// @notice name of this individual layer
  string public layerName;

  /// @notice an NFT's selected option for an individual layer
  struct OptionSelection {
    uint256 optionNumber;
    string color1Hex;
    string color2Hex;
  }

  /// @notice data of each potential optional for an individual layer
  struct Option {
    string svg;
    string value;
    string defaultColor1Hex;
    string defaultColor2Hex;
    uint256 rarityStart;
    uint256 rarityEnd;
  }

  /// @notice bypass block gas limit error for large SVG files by splitting the SVG string into multiple transactions 
  /// @param optionIndex index of the option
  /// @param svgStringToConcatenate svg string to concatenate to the end of the existing SVG string
  function addOptionsByConcatenation (
    uint256 optionIndex,
    string memory svgStringToConcatenate
  ) public onlyOwner
  {
    require(layerOptions.length > optionIndex,"Option Index Undefined");
    layerOptions[optionIndex].svg = string.concat(layerOptions[optionIndex].svg, svgStringToConcatenate);
  }

  /// @notice adds an option for an individual layer
  /// @param option struct corresponding to an layer option
  function addOptions (
    Option memory option
  ) public onlyOwner
  {
    // This ensures that the first option is a null item
    if(layerOptions.length == 0) {
      layerOptions.push(Option({
        svg: "",
        value: "",
        defaultColor1Hex: "",
        defaultColor2Hex: "",
        rarityStart: 1000,
        rarityEnd: 1000
      }));
    }
    layerOptions.push(option);
  }

  /// @notice returns the attributes metadata for this individual layer
  /// @param tokenId the selected NFT
  function getOptionMetadataByTokenId (
    uint256 tokenId
  )
    external
    virtual
    view
    returns (string memory)
  {
    string memory value = layerOptions[selectedOption[tokenId].optionNumber].value;
    if(bytes(value).length == 0) return "";

    return string.concat(
      '{ "trait_type": "',
      layerName,
      '", "value": "',
      value,
      '" }'
    );
  }

  /// @notice returns the SVG image for this individual layer
  /// @param tokenId the selected NFT
  function renderOptionByTokenId(
    uint256 tokenId
  )
    external
    virtual
    view
    returns (string memory)
  {
    string memory svgOption = layerOptions[selectedOption[tokenId].optionNumber].svg;
    if(bytes(svgOption).length == 0) return "";

    string memory color2Hex = selectedOption[tokenId].color2Hex;
    string memory secondColorVar = string.concat(
      '<linearGradient id="',
      layerName,
      '-secondColor',
      '" x1="0" x2="1" y1="0" y2="0"><stop stop-color="',
      color2Hex,
      '" offset="0"></stop><stop stop-color="',
      color2Hex,
      '" offset="1"></stop></linearGradient>'
    );
    
    return string(abi.encodePacked(
      '<g',
      ' id="',
      layerName,
      '"',
      ' color="',
      selectedOption[tokenId].color1Hex,
      '">',
      bytes(color2Hex).length > 1 ? secondColorVar : '',
      svgOption,
      '</g>'
      ));
  }


  /// @notice Selects the layer option for this individual layer
  /// @param tokenID the selected NFT
  /// @param randomNumber used to select the NFT based on rarity
  /// @param forceZeroOption Make this layer empty
  function selectOption ( 
    uint256 tokenID,
    uint256 randomNumber,
    bool forceZeroOption
  ) public
  returns (uint256){
    if(isDefaultLayer){
      require(msg.sender == composableNFTAddress, "Only NFT Contract can select option on Default Layer");
    } else {
      require(IERC721(composableNFTAddress).ownerOf(tokenID) == msg.sender, "Only NFT owner can call");
    }

    // Make sure every layer has a default Zero option that is an empty layer
    // rarityStart & rarityEnd should both be 0, so that is is impossible to be selected unless manually set due to specific if-then logic
    if(forceZeroOption == true){
        selectedOption[tokenID] = OptionSelection({
          optionNumber: 0,
          color1Hex: layerOptions[0].defaultColor1Hex,
          color2Hex: layerOptions[0].defaultColor2Hex
        });
        return 0;
    }

    for(uint256 i = 0; i < layerOptions.length; i++){
      if(
        randomNumber >= layerOptions[i].rarityStart && 
        randomNumber < layerOptions[i].rarityEnd
      ) {
        selectedOption[tokenID] = OptionSelection({
          optionNumber: i,
          color1Hex: layerOptions[i].defaultColor1Hex,
          color2Hex: layerOptions[i].defaultColor2Hex
        });
        return i;
      }
    }
    return 99; // should never reach here
  }

  /// @notice Changes the color of an option for this individual layer
  /// @param tokenId the selected NFT
  /// @param color1Hex Hex String of the 1st color
  /// @param color2Hex Hex String of the 2nd color
  function setColor(
    uint256 tokenId,
    string memory color1Hex,
    string memory color2Hex
  ) public payable
  {
    require(IERC721(composableNFTAddress).ownerOf(tokenId) == msg.sender, "You are not the owner");
    require(msg.value == colorChangePrice);

    if(bytes(color1Hex).length > 1){
      selectedOption[tokenId].color1Hex = color1Hex;
    }

    if(bytes(color2Hex).length > 1){
      selectedOption[tokenId].color2Hex = color2Hex;
    }
  }

  /// @notice Transfers ETH collected from layer color changes
  function collectColorChangeFee()
    public
    onlyOwner
  {
    payable(msg.sender).transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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