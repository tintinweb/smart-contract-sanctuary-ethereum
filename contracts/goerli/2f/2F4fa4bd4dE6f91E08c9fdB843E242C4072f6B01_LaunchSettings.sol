// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ILaunchSettings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
contract LaunchSettings is ILaunchSettings, Ownable, IERC165 {
    
    using ERC165Checker for address;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    uint256 public override maxAuctionLength;
    uint256 public override maxAuctionLengthForNFT;
    
    uint256 public constant maxMaxAuctionLength = 8 weeks;
    uint256 public constant maxMaxAuctionLengthForNFT = 8 weeks;
    
    uint256 public override minAuctionLength;
    uint256 public override minAuctionLengthForNFT;
    
    uint256 public constant minMinAuctionLength = 1 days;
    uint256 public constant minMinAuctionLengthForNFT = 1 days;

    uint256 public override governanceFee;
    uint256 public override governanceFeeForNFT;
 
    uint256 public constant maxGovFee = 200;
    uint256 public constant maxGovFeeForNFT = 200;

    uint256 public override maxCuratorFee;
    uint256 public override maxCuratorFeeForNFT;

    uint256 public override minBidIncrease;
    uint256 public override minBidIncreaseForNFT;
    
    uint256 public constant maxMinBidIncrease = 100;
    uint256 public constant maxMinBidIncreaseForNFT = 100;
 
    uint256 public constant minMinBidIncrease = 10;
    uint256 public constant minMinBidIncreaseForNFT = 10;
  
    uint256 public override minVotePercentage;
    uint256 public override minVotePercentageForNFT;

    uint256 public override maxReserveFactor;
    uint256 public override maxReserveFactorForNFT;

    uint256 public override minReserveFactor;
    uint256 public override minReserveFactorForNFT;
 
    address payable public override feeReceiver;
    address payable public override feeReceiverForNFT;

    event UpdateMaxAuctionLength(uint256 _old, uint256 _new);
    event UpdateMaxAuctionLengthForNFT(uint256 _old, uint256 _new);

    event UpdateMinAuctionLength(uint256 _old, uint256 _new);
    event UpdateMinAuctionLengthForNFT(uint256 _old, uint256 _new);

    event UpdateGovernanceFee(uint256 _old, uint256 _new);
    event UpdateGovernanceFeeForNFT(uint256 _old, uint256 _new);

    event UpdateCuratorFee(uint256 _old, uint256 _new);
    event UpdateCuratorFeeForNFT(uint256 _old, uint256 _new);

    event UpdateMinBidIncrease(uint256 _old, uint256 _new);
    event UpdateMinBidIncreaseForNFT(uint256 _old, uint256 _new);

    event UpdateMinVotePercentage(uint256 _old, uint256 _new);
    event UpdateMinVotePercentageForNFT(uint256 _old, uint256 _new);

    event UpdateMaxReserveFactor(uint256 _old, uint256 _new);
    event UpdateMaxReserveFactorForNFT(uint256 _old, uint256 _new);

    event UpdateMinReserveFactor(uint256 _old, uint256 _new);
    event UpdateMinReserveFactorForNFT(uint256 _old, uint256 _new);

    event UpdateFeeReceiver(address _old, address _new);
    event UpdateFeeReceiverForNFT(address _old, address _new);

    constructor() {
        maxAuctionLength = 2 weeks;
        maxAuctionLengthForNFT = 2 weeks;
        minAuctionLength = 3 days;
        minAuctionLengthForNFT = 3 days;
        feeReceiver = payable(msg.sender);
        feeReceiverForNFT = payable(msg.sender);
        minReserveFactor = 200;  // 20%
        minReserveFactorForNFT = 200;  // 20%
        maxReserveFactor = 5000; // 500%
        maxReserveFactorForNFT = 5000; // 500%
        maxReserveFactor = 5000; // 500%
        maxReserveFactorForNFT = 5000; // 500%
        minBidIncrease = 50;     // 5%
        minBidIncreaseForNFT = 50;     // 5%
        maxCuratorFee = 100; //10%
        maxCuratorFeeForNFT = 100; //10%
        minVotePercentage = 500; // 50%
        minVotePercentageForNFT = 500; // 50%
    }

    function setMaxAuctionLength(uint256 _length) external onlyOwner {
        require(_length <= maxMaxAuctionLength, "max auction length too high");
        require(_length > minAuctionLength, "max auction length too low");

        emit UpdateMaxAuctionLength(maxAuctionLength, _length);

        maxAuctionLength = _length;
    }

    function setMaxAuctionLengthForNFT(uint256 _length) external onlyOwner {
        require(_length <= maxMaxAuctionLengthForNFT, "max auction length too high");
        require(_length > minAuctionLengthForNFT, "max auction length too low");

        emit UpdateMaxAuctionLengthForNFT(maxAuctionLengthForNFT, _length);

        maxAuctionLengthForNFT = _length;
    }

    function setMinAuctionLength(uint256 _length) external onlyOwner {
        require(_length >= minMinAuctionLength, "min auction length too low");
        require(_length < maxAuctionLength, "min auction length too high");

        emit UpdateMinAuctionLength(minAuctionLength, _length);

        minAuctionLength = _length;
    }

    function setMinAuctionLengthForNFT(uint256 _length) external onlyOwner {
        require(_length >= minMinAuctionLengthForNFT, "min auction length too low");
        require(_length < maxAuctionLengthForNFT, "min auction length too high");

        emit UpdateMinAuctionLengthForNFT(minAuctionLengthForNFT, _length);

        minAuctionLengthForNFT = _length;
    }

    function setGovernanceFee(uint256 _fee) external onlyOwner {
        require(_fee <= maxGovFee, "fee too high");

        emit UpdateGovernanceFee(governanceFee, _fee);

        governanceFee = _fee;
    }
    function setGovernanceFeeForNFT(uint256 _fee) external onlyOwner {
        require(_fee <= maxGovFeeForNFT, "fee too high");

        emit UpdateGovernanceFeeForNFT(governanceFeeForNFT, _fee);

        governanceFeeForNFT = _fee;
    }

    function setMaxCuratorFee(uint256 _fee) external onlyOwner {
        emit UpdateCuratorFee(governanceFee, _fee);

        maxCuratorFee = _fee;
    }
    function setMaxCuratorFeeForNFT(uint256 _fee) external onlyOwner {
        emit UpdateCuratorFeeForNFT(governanceFeeForNFT, _fee);

        maxCuratorFeeForNFT = _fee;
    }

    function setMinBidIncrease(uint256 _min) external onlyOwner {
        require(_min <= maxMinBidIncrease, "min bid increase too high");
        require(_min >= minMinBidIncrease, "min bid increase too low");

        emit UpdateMinBidIncrease(minBidIncrease, _min);

        minBidIncrease = _min;
    }
    function setMinBidIncreaseForNFT(uint256 _min) external onlyOwner {
        require(_min <= maxMinBidIncreaseForNFT, "min bid increase too high");
        require(_min >= minMinBidIncreaseForNFT, "min bid increase too low");

        emit UpdateMinBidIncreaseForNFT(minBidIncreaseForNFT, _min);

        minBidIncreaseForNFT = _min;
    }

    function setMinVotePercentage(uint256 _min) external onlyOwner {
        // 1000 is 100%
        require(_min <= 1000, "min vote percentage too high");

        emit UpdateMinVotePercentage(minVotePercentage, _min);

        minVotePercentage = _min;
    }
    function setMinVotePercentageForNFT(uint256 _min) external onlyOwner {
        // 1000 is 100%
        require(_min <= 1000, "min vote percentage too high");

        emit UpdateMinVotePercentageForNFT(minVotePercentageForNFT, _min);

        minVotePercentageForNFT = _min;
    }

    function setMaxReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor > minReserveFactor, "max reserve factor too low");

        emit UpdateMaxReserveFactor(maxReserveFactor, _factor);

        maxReserveFactor = _factor;
    }
    function setMaxReserveFactorForNFT(uint256 _factor) external onlyOwner {
        require(_factor > minReserveFactorForNFT, "max reserve factor too low");

        emit UpdateMaxReserveFactorForNFT(maxReserveFactorForNFT, _factor);

        maxReserveFactorForNFT = _factor;
    }

    function setMinReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor < maxReserveFactor, "min reserve factor too high");

        emit UpdateMinReserveFactor(minReserveFactor, _factor);

        minReserveFactor = _factor;
    }
    function setMinReserveFactorForNFT(uint256 _factor) external onlyOwner {
        require(_factor < maxReserveFactorForNFT, "min reserve factor too high");

        emit UpdateMinReserveFactorForNFT(minReserveFactorForNFT, _factor);

        minReserveFactorForNFT = _factor;
    }

    function setFeeReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiver(feeReceiver, _receiver);

        feeReceiver = _receiver;
    }
    function setFeeReceiverForNFT(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiverForNFT(feeReceiverForNFT, _receiver);

        feeReceiverForNFT = _receiver;
    }

    function isERC721(address nft) external override view returns(bool){
        return nft.supportsInterface(IID_IERC721);
    }
    function isERC1155(address nft) external override view returns(bool){
        return nft.supportsInterface(IID_IERC1155);
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == IID_IERC1155 || interfaceId == IID_IERC721;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
pragma solidity >=0.4.22 <0.9.0;

interface ILaunchSettings {
    function maxAuctionLength() external returns (uint256);
    function maxAuctionLengthForNFT() external returns (uint256);

    function minAuctionLength() external returns (uint256);
    function minAuctionLengthForNFT() external returns (uint256);

    function maxCuratorFee() external returns (uint256);
    function maxCuratorFeeForNFT() external returns (uint256);

    function governanceFee() external returns (uint256);
    function governanceFeeForNFT() external returns (uint256);

    function minBidIncrease() external returns (uint256);
    function minBidIncreaseForNFT() external returns (uint256);

    function minVotePercentage() external returns (uint256);
    function minVotePercentageForNFT() external returns (uint256);

    function maxReserveFactor() external returns (uint256);
    function maxReserveFactorForNFT() external returns (uint256);

    function minReserveFactor() external returns (uint256);
    function minReserveFactorForNFT() external returns (uint256);

    function feeReceiver() external returns (address payable);
    function feeReceiverForNFT() external returns (address payable);

    function isERC1155(address nft) external returns(bool);
    function isERC721(address nft) external returns(bool);
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