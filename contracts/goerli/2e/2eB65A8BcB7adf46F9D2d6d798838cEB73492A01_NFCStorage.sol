// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CompliancyChecker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFCStorage is Ownable {

    struct Coupon {
        bool added;
        uint256 phase;
        mapping (uint256 => bool) redeemed;
    }
    mapping(address => Coupon) public coupons;
    mapping(address => bool) public whitelistClaimed;

    address[] public ERC721List;
    address[] public ERC721EnumerableList;

    uint256 public phase;
    uint256 public basePrice;
    address public nftAddress;
    bytes32 public merkleRoot; 
    
    bool public emergency = false;
    bool public salesLocked = false;
    bool public merkleRootLocked = false;

    event BackupUploaded(string backupData);

    modifier onlyFromNftContract {
        require(msg.sender == nftAddress, 'Only callable by NFT contract.');
        _;
    }

    constructor(uint256 _phase, uint256 _basePrice, bytes32 _merkleRoot) {
        phase = _phase;
        basePrice = _basePrice;
        merkleRoot = _merkleRoot;
    }

    function updateBasePrice(uint256 _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }
    
    function toggleEmergency() external onlyOwner {
        emergency = !emergency;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(!merkleRootLocked, "Whitelist locked.");
        merkleRoot = _merkleRoot;
    }

    function lockWhitelist() external onlyOwner { //
        merkleRootLocked = true;
    }

    function lockSales() external onlyOwner {
        salesLocked = true;
    }

    function uploadBackup(string calldata backupData) external onlyOwner {
        emit BackupUploaded(backupData);
    }

    function attachNftContract(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }
    
    function updatePhase(uint256 _phase) external onlyOwner {
        require(_phase <= 100, "Phase needs to be below or equal 100.");
        require(phase != 0, "Can't go back to private sales.");
        phase = _phase;
    }

    function append721Coupon(address[] calldata _nft_contracts, uint256[] calldata _phases) external onlyOwner {
        require(_nft_contracts.length == _phases.length, "Contracts and Phases length mismatch");

        for (uint256 i = 0; i < _nft_contracts.length;) {
            if (_phases[i] <= 100 && CompliancyChecker.check721Compliancy(_nft_contracts[i])) {
                if (coupons[_nft_contracts[i]].added == false) {
                    if (CompliancyChecker.check721EnumerableCompliancy(_nft_contracts[i])) {
                        ERC721EnumerableList.push(_nft_contracts[i]);
                    } else {
                        ERC721List.push(_nft_contracts[i]);
                    }
                    coupons[_nft_contracts[i]].added = true;
                }
                coupons[_nft_contracts[i]].phase = _phases[i];
            }
            unchecked{ i++; }
        }
    }

    function getAllEligibles() external view returns (address[] memory) {
        address[] memory eligible_contracts = new address[](1000);
        uint256 k = 0;

        for (uint256 i = 0; i < ERC721List.length;) {
            if (isContractEligible(ERC721List[i]) && k < 1000) {
                eligible_contracts[k] = ERC721List[i];
                unchecked{ k++; }
            }
            unchecked{ i++; }
        }

        for (uint256 i = 0; i < ERC721EnumerableList.length;) {
            if (isContractEligible(ERC721EnumerableList[i]) && k < 1000) {
                eligible_contracts[k] = ERC721EnumerableList[i];
                unchecked{ k++; }
            }
            unchecked{ i++; }
        }

        return eligible_contracts;
    }

    function getRedeemedIdsFromContract(address _nft_contract, uint256 _start, uint256 _end) external view returns (string[] memory) {
        require(_start <= _end, "Start should be below End.");
        require(_end - _start < 1000, "Max range should be < 1000.");
        require(CompliancyChecker.check721Compliancy(_nft_contract), "This is not an ERC721.");

        string[] memory ids = new string[](1000);
        uint256 k = 0;

        for (uint256 i = _start; i <= _end;) {
            uint256 id;
            if (CompliancyChecker.check721EnumerableCompliancy(_nft_contract)) {
                id = IERC721Enumerable(_nft_contract).tokenByIndex(i);
            } else {
                id = i;
            }
            if (getRedeemFromId(_nft_contract, id) && k < 1000) {
                ids[k] = Strings.toString(id);
                unchecked { k++; }
            }
            unchecked { i++; }
        }

        return ids;
    }

    function getRedeemFromId(address _nft_contract, uint256 _nft_id) public view returns (bool) {
        return coupons[_nft_contract].redeemed[_nft_id];
    }

    function isContractEligible(address _nft_contract) public view returns (bool) {
        return (coupons[_nft_contract].phase >= phase && coupons[_nft_contract].added);
    }

    function getEligible721(address _buyer) external view returns (address[] memory) {
        uint256 j = 0;
        address[] memory nft_721_contracts = new address[](1000);

        for (uint256 i = 0; i < ERC721List.length;) {
            if (isContractEligible(ERC721List[i]) &&
                IERC721(ERC721List[i]).balanceOf(_buyer) > 0 &&
                j < 1000) {
                nft_721_contracts[j] = ERC721List[i];
                unchecked{ j++; }
            }
            unchecked{ i++; }
        }

        return nft_721_contracts;
    }

    function getEligibleTokens(address _buyer, address[] calldata _nft_721_contracts, uint256[] calldata _nft_721_ids)
        external view returns (address[] memory, uint256[] memory)
    {
        require(_nft_721_contracts.length == _nft_721_ids.length, "Contracts and Ids length mismatch");

        uint256 k = 0;
        address[] memory eligible_contracts = new address[](1000);
        uint256[] memory eligible_ids = new uint256[](1000);
        
        for (uint256 j = 0; j < _nft_721_contracts.length;) {
            if (isContractEligible(_nft_721_contracts[j])) {
                if (IERC721(_nft_721_contracts[j]).ownerOf(_nft_721_ids[j]) == _buyer &&
                    !getRedeemFromId(_nft_721_contracts[j], _nft_721_ids[j]) && 
                    k < 1000) {
                    eligible_contracts[k] = _nft_721_contracts[j];
                    eligible_ids[k] = _nft_721_ids[j];
                    unchecked{ k++; }
                }
            }
            unchecked{ j++; }
        }

        for (uint256 i = 0; i < ERC721EnumerableList.length;) {
            if (isContractEligible(ERC721EnumerableList[i])) {
                IERC721Enumerable ERC721EnumContract = IERC721Enumerable(ERC721EnumerableList[i]);
                for (uint256 j = 0; j < (ERC721EnumContract.balanceOf(_buyer) % 5);) {
                    uint256 tmp_id = ERC721EnumContract.tokenOfOwnerByIndex(_buyer, j);
                    if (!getRedeemFromId(ERC721EnumerableList[i], tmp_id) && k < 1000) {
                        eligible_contracts[k] = ERC721EnumerableList[i];
                        eligible_ids[k] = tmp_id;
                        unchecked{ k++; }
                    }
                    unchecked{ j++; }
                }
            }
            unchecked{ i++; }
        }

        return (eligible_contracts, eligible_ids);
    }

    function storeWhitelistClaim(address _addr) external onlyFromNftContract {
        whitelistClaimed[_addr] = true;
    }

    function redeem(address _nft_contract, uint256 _nft_id) external onlyFromNftContract {
        coupons[_nft_contract].redeemed[_nft_id] = true;
    }

    function checkEligibility(address _nft_contract, uint256 _nft_id) external view {
        require(phase > 0, "Private sales are closed.");
        require(isContractEligible(_nft_contract), "NFT not eligible.");
        require(!getRedeemFromId(_nft_contract, _nft_id), "NFT already redeemed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

library CompliancyChecker {

    bytes4 public constant _INTERFACE_ID_IERC165 = 0x01ffc9a7;
    bytes4 public constant _INTERFACE_ID_IERC721 = 0x80ac58cd;
    bytes4 public constant _INTERFACE_ID_IERC721ENUMERABLE = 0x780e9d63;
    bytes4 public constant _INTERFACE_ID_IERC1155 = 0xd9b67a26;

    function check165Compliancy(address _contract) public view returns (bool) {
        try IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC165) returns (bool supported)  {
            return supported;
        }  catch {
            return false;
        }
    }

    function check1155Compliancy(address _contract) public view returns (bool) {
        if (check165Compliancy(_contract) == false) {
            return false;
        }
        
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC1155)) {
            try IERC1155(_contract).balanceOf(0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a, 0) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
    }

    function check721Compliancy(address _contract) public view returns (bool) {
        if (check165Compliancy(_contract) == false) {
            return false;
        }

        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC721)) {
            try IERC721(_contract).balanceOf(0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
    }

    function check721EnumerableCompliancy(address _contract) public view returns (bool) {
        address owner_example;

        if (check721Compliancy(_contract) == false) {
            return false;
        }

        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC721ENUMERABLE)) {
            try IERC721Enumerable(_contract).tokenByIndex(0) returns (uint256 _id_example)  {
                owner_example = IERC721Enumerable(_contract).ownerOf(_id_example);
            }  catch {
                return false;
            }

            try IERC721Enumerable(_contract).tokenOfOwnerByIndex(owner_example, 0) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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