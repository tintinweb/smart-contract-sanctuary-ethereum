// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { IERC721 } from "openzeppelin/token/ERC721/IERC721.sol";


import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

import { ISSMintableNFT } from "./interfaces/ISSMintableNFT.sol";
import { ISSMintWrapperNFT } from "./interfaces/ISSMintWrapperNFT.sol";
import { DummyERC721 } from "./types/DummyERC721.sol";

error TokenAlreadyMinted();
error IndexOutOfBounds();
error TokenDNE();

contract SudoswapMintWrapper is Ownable, DummyERC721, ISSMintWrapperNFT {
    using Strings for uint256;

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    /*//////////////////////////////////////////////////////////////
                        INTERNAL PRIVATE VARIABLES 
    //////////////////////////////////////////////////////////////*/
    // Main NFT contract
    ISSMintableNFT public SSMT;

    // Track who can mint & what tokens have been minted
    mapping(address => bool) private _authorizedMinter;
    
    // Metadata
    string private _baseURI = "";

    // Track the mint quantity 
    uint64 private _tokenIdCap;
    uint64 private _mintedTokenCount;

    address private _registrar;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address ssmt_, uint64 quantity_) DummyERC721("WrapperName", "SymbolW") {
        // Set the address of the NFT contract where the tokens are being minted from
        SSMT = ISSMintableNFT(ssmt_);

        // Set the mint quantity
        _tokenIdCap = quantity_;
        _registrar  = msg.sender;
        _mintedTokenCount = 0;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMINISTRATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renameWrapper(string memory name_, string memory symbol_) external onlyOwner {
        name = name_;
        symbol = symbol_;
    }

    function connectWrapperToSSMT(address ssmt_, uint64 quantity_) external onlyOwner {
        // Set the address of the NFT contract where the tokens are being minted from
        SSMT = ISSMintableNFT(ssmt_);

        // Set the mint quantity
        _tokenIdCap = quantity_;

        // Reset minted token counter
        _mintedTokenCount = 0;
    }

    function connectWrapperToPool(address pool_) external onlyOwner {
        _registrar = pool_;
        _authorizedMinter[pool_] = true;
        emit ConsecutiveTransfer(0, _tokenIdCap - _mintedTokenCount, address(0), _registrar);
    }

    function emitBulkTransfer() external onlyOwner {
        emit ConsecutiveTransfer(0, _tokenIdCap - _mintedTokenCount, address(0), _registrar);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function initializeRegistrar() external onlyOwner {
        for (uint index_; index_ < _tokenIdCap; index_ ++) {
            emit Transfer(this.owner(), _registrar, index_);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        MINT WRAPPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice This accessor function is used to get the parent NFT contract that 
     * this wrapper mints.
     * @return address the contract address of the SSMintableNFT compliant smart cotnract.
     */
    function getMintContract() external returns (address) {
        return address(SSMT);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC721 ENUMERABLE DUMMY LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view override returns (uint256) {
        return 1 + _tokenIdCap - _mintedTokenCount;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= this.balanceOf(owner)) revert IndexOutOfBounds();
        return index;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index > this.totalSupply()) revert IndexOutOfBounds();
        return index;
    }

    /*//////////////////////////////////////////////////////////////
                          ERC721 DUMMY LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id >= this.totalSupply()) revert TokenDNE();
        return _baseURI;
            // bytes(_baseURI).length > 0
                // ? string(abi.encodePacked(_baseURI, "/", id.toString(), ".json"))
                // : "";
    }

    function ownerOf(uint256 id) public view override(DummyERC721, IERC721) returns (address owner) {
        if (id > this.totalSupply()) revert TokenAlreadyMinted();
        return _registrar;
    }

    function balanceOf(address owner) public view override(DummyERC721, IERC721) returns (uint256) {
        if (owner == _registrar) return _tokenIdCap - _mintedTokenCount;
        return 0;
    }

    function getApproved(uint256) public view override(DummyERC721, IERC721) returns (address) {
        return _registrar;
    }

    function isApprovedForAll(address owner_, address operator_) public view override(DummyERC721, IERC721) returns (bool) {
        if (owner_ == _registrar) return _authorizedMinter[operator_];
        return false;
    }

    function setApprovalForAll(address operator, bool approved) public override(DummyERC721, IERC721) {
        if (!(msg.sender == _registrar || msg.sender == this.owner()))
            return;

        _authorizedMinter[operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function approve(address, uint256) public pure override(DummyERC721, IERC721) {
        return;
    }

    /*//////////////////////////////////////////////////////////////
                          MINT & TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(DummyERC721, IERC721) {
        require(from == _registrar, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || this.isApprovedForAll(from, msg.sender) || msg.sender == this.getApproved(id),
            "NOT_AUTHORIZED"
        );

        // Underflow is impossible because tokens are burned on transfer
        unchecked {
            _mintedTokenCount++;
        }

        SSMT.permissionedMint(to);

        emit Transfer(from, address(0), _tokenIdCap - _mintedTokenCount);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override(DummyERC721, IERC721) {
        transferFrom(from, to, id);

        // Safety check is performed in the permissionedMint function
        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata
    ) public override(DummyERC721, IERC721) {
        transferFrom(from, to, id);

        // Safety check is performed in the permissionedMint function
        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );
    }

    /*//////////////////////////////////////////////////////////////
                        INTROSPECTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(DummyERC721, IERC165) returns (bool) {
        return
        interfaceId == type(ISSMintWrapperNFT).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            CLEANUP LOGIC
    //////////////////////////////////////////////////////////////*/

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/IERC721.sol";

interface ISSMintableNFT is IERC721 {
    /**
     * @notice This function is to be used by the Sudoswap Mint Wrapper contract. The 
     * PermissionedMint function should mint one NFT token on behalf of the user.
     * @param receiver_ the wallet address to send the newly minted NFT to.
     */
    function permissionedMint(address receiver_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin/token/ERC721/IERC721.sol";

interface ISSMintWrapperNFT is IERC721, IERC721Enumerable {
    /**
     * @notice This accessor function is used to get the parent NFT contract that 
     * this wrapper mints.
     * @return address the contract address of the SSMintableNFT compliant smart cotnract.
     */
    function getMintContract() external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { IERC721Enumerable} from "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract DummyERC721 is IERC721Enumerable {

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view virtual returns (address);

    function balanceOf(address owner) public view virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    function getApproved(uint256 tokenId_) public view virtual returns (address);

    function isApprovedForAll(address owner_, address operator_) public view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual;

    function setApprovalForAll(address operator, bool approved) public virtual;

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == 0x780e9d63 ||
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
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