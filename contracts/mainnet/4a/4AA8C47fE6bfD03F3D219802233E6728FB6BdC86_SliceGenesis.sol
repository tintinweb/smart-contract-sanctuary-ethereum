// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./extensions/Purchasable/SlicerPurchasable.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./utils/sliceV1/interfaces/IProductsModule.sol";
import "./utils/sliceV1/interfaces/ISliceCore.sol";

/**
 * @title SliceGenesis
 * @author jjranalli
 *
 * @notice ERC721 Implementation that uses SlicerPurchasable extension to handle NFT drop for Slice V1 launch.
 *
 * - Relies on allowlist mechanic for all products except product #4
 * - product #4 is based on quantity of SLX token owned
 *
 * Won't be possible to create new allowlists once contract ownership is renounced.
 */
contract SliceGenesis is ERC721, SlicerPurchasable, Ownable {
    /// ============ Errors ============

    // Thrown when an invalid query is made
    error Invalid();
    // Thrown when max supply set is reached
    error MaxSupply();

    /// ============ Libaries ============

    using Counters for Counters.Counter;
    using Strings for uint256;

    /// ============ Storage ============

    // Token ID counter
    Counters.Counter private _tokenIds;
    // Addresses for initial mint
    address[] private ADDRESSES_TO_MINT = [
        0xff0C998D921394D89c5649712422622E3172480C,
        0xc2cA7A683Db047D221F5F8cF2de34361a399a6d5,
        0xA6FB48C1ab0CB9Ef3015D920fBb15860427008c5,
        0x5d95baEBB8412AD827287240A5c281E3bB30d27E,
        0x5C8e99481e9D02F9efDF45FF73268D7123D2817D,
        0x26FDc242eCCc144971e558FF458a4ec21B75D4E8,
        0x26416423d530b1931A2a7a6b7D435Fac65eED27d,
        0xf0549d13B142B37F0663E6B52CE54BD312A2eDaa
    ];
    // Max token supply
    uint16 private constant MAX_SUPPLY = 4200;
    // Slicer address
    address private _slicerAddress;
    // SLX Address
    address private _slxAddress;
    // Temporary URI
    string private _tempURI;
    // Base URI
    string private _baseURI;
    // SLX
    IERC20 private immutable _slx;
    // Mapping from productIds to Merkle roots
    mapping(uint256 => bytes32) _merkleRoots;

    /// ============ Constructor ============

    constructor(
        string memory name_,
        string memory symbol_,
        address slxAddress_,
        address sliceCoreAddress_,
        address productsModuleAddress_,
        uint256 slicerId_
    ) ERC721(name_, symbol_) SlicerPurchasable(productsModuleAddress_, slicerId_) {
        _slx = IERC20(slxAddress_);
        _slicerAddress = ISliceCore(sliceCoreAddress_).slicers(slicerId_);

        // Mint NFTs to those that already claimed from previous contract
        _initMint(ADDRESSES_TO_MINT);
    }

    /// ============ Functions ============

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory,
        bytes memory buyerCustomData
    ) public view override returns (bool isAllowed) {
        // Check max supply is not exceeded
        if (_tokenIds.current() + quantity > MAX_SUPPLY) revert MaxSupply();

        // For all products except product #4, use allowlists
        if (productId != 4) {
            if (_merkleRoots[productId] != bytes32(0)) {
                // Get Merkle proof from buyerCustomData
                bytes32[] memory proof = abi.decode(buyerCustomData, (bytes32[]));

                // Generate leaf from account address
                bytes32 leaf = keccak256(abi.encodePacked(account));

                // Check if Merkle proof is valid
                isAllowed = MerkleProof.verify(proof, _merkleRoots[productId], leaf);
            } else {
                isAllowed = true;
            }
        } else {
            // Get purchased units
            uint256 purchasedUnits = IProductsModule(_productsModuleAddress).validatePurchaseUnits(
                account,
                slicerId,
                uint32(productId)
            );

            // Calculate total quantity purchased
            /// @dev Quantity is included in purchased units during purchase
            uint256 totalQuantity = msg.sender == _productsModuleAddress
                ? purchasedUnits
                : quantity + purchasedUnits;

            // Check if accounts holds at least (25k * totalQuantity) SLX
            isAllowed = _slx.balanceOf(account) >= totalQuantity * 25 * 10**21;
        }
    }

    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();

        // Mint number of NFTs equal to purchased quantity
        for (uint256 i = 0; i < quantity; ) {
            _mint(account);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns URI of tokenId
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId > _tokenIds.current()) revert Invalid();

        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : _tempURI;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_slicerAddress, salePrice / 10);
    }

    /**
     * Sets _baseURI
     *
     * @dev Only accessible to contract owner
     */
    function _setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * Sets _tempURI
     *
     * @dev Only accessible to contract owner
     */
    function _setTempURI(string memory tempURI_) external onlyOwner {
        _tempURI = tempURI_;
    }

    /**
     * Sets merkleRoot for productId
     *
     * @dev Only accessible to contract owner
     */
    function _setMerkleRoot(uint256 productId, bytes32 merkleRoot) external onlyOwner {
        _merkleRoots[productId] = merkleRoot;
    }

    /**
     * Mints 1 NFT and increases tokenId
     */
    function _mint(address to) private {
        _tokenIds.increment();
        _safeMint(to, _tokenIds.current());
    }

    /**
     * Mints nfts to those who already claimed the previous collection from the allowlist
     *
     * @dev Only called during constructor
     */
    function _initMint(address[] memory addresses) private {
        for (uint256 i = 0; i < addresses.length; ) {
            _mint(addresses[i]);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../interfaces/extensions/Purchasable/ISlicerPurchasable.sol";

/**
 * @title SlicerPurchasable
 * @author jjranalli
 *
 * @notice Extension enabling basic usage of external calls by slicers upon product purchase.
 */
abstract contract SlicerPurchasable is ISlicerPurchasable {
    /// ============ Errors ============

    /// @notice Thrown if not called from the correct slicer
    error WrongSlicer();
    /// @notice Thrown if not called during product purchase
    error NotPurchase();
    /// @notice Thrown when account is not allowed to buy product
    error NotAllowed();
    /// @notice Thrown when a critical request was not successful
    error NotSuccessful();

    /// ============ Storage ============

    /// ProductsModule contract address
    address internal _productsModuleAddress;
    /// Id of the slicer able to call the functions with the `OnlyOnPurchaseFrom` function
    uint256 internal immutable _slicerId;

    /// ============ Constructor ============

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     */
    constructor(address productsModuleAddress_, uint256 slicerId_) {
        _productsModuleAddress = productsModuleAddress_;
        _slicerId = slicerId_;
    }

    /// ============ Modifiers ============

    /**
     * @notice Checks product purchases are accepted only from correct slicer (modifier)
     */
    modifier onlyOnPurchaseFrom(uint256 slicerId) {
        _onlyOnPurchaseFrom(slicerId);
        _;
    }

    /// ============ Functions ============

    /**
     * @notice Checks product purchases are accepted only from correct slicer (function)
     */
    function _onlyOnPurchaseFrom(uint256 slicerId) internal view virtual {
        if (_slicerId != slicerId) revert WrongSlicer();
        if (msg.sender != _productsModuleAddress) revert NotPurchase();
    }

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     */
    function isPurchaseAllowed(
        uint256,
        uint256,
        address,
        uint256,
        bytes memory,
        bytes memory
    ) public view virtual override returns (bool) {
        // Add all requirements related to product purchase here
        // Return true if account is allowed to buy product
        return true;
    }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     *
     * @dev Can be inherited by child contracts to add custom logic on product purchases.
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable virtual override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();

        // Add product purchase logic here
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../structs/Function.sol";
import "../structs/ProductParams.sol";
import "../structs/PurchaseParams.sol";

interface IProductsModule {
    function addProduct(
        uint256 slicerId,
        ProductParams memory params,
        Function memory externalCall_
    ) external;

    function setProductInfo(
        uint256 slicerId,
        uint32 productId,
        uint8 newMaxUnits,
        bool isFree,
        bool isInfinite,
        uint32 newUnits,
        CurrencyPrice[] memory currencyPrices
    ) external;

    function removeProduct(uint256 slicerId, uint32 productId) external;

    function payProducts(address buyer, PurchaseParams[] calldata purchases) external payable;

    function releaseEthToSlicer(uint256 slicerId) external;

    // function _setCategoryAddress(uint256 categoryIndex, address newCategoryAddress) external;

    function ethBalance(uint256 slicerId) external view returns (uint256);

    function productPrice(
        uint256 slicerId,
        uint32 productId,
        address currency
    ) external view returns (uint256 ethPayment, uint256 currencyPayment);

    function validatePurchaseUnits(
        address account,
        uint256 slicerId,
        uint32 productId
    ) external view returns (uint256 purchases);

    function validatePurchase(uint256 slicerId, uint32 productId)
        external
        view
        returns (uint256 purchases, bytes memory purchaseData);

    // function categoryAddress(uint256 categoryIndex) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../structs/Payee.sol";

import "./utils/IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

interface ISliceCore is IOwnable, IERC1155Upgradeable, IERC2981Upgradeable {
    function slice(
        Payee[] calldata payees,
        uint256 minimumShares,
        address[] calldata currencies,
        uint256 releaseTimelock,
        uint40 transferableTimelock,
        bool isImmutable,
        bool isControlled
    ) external;

    function reslice(
        uint256 tokenId,
        address payable[] calldata accounts,
        int32[] calldata tokensDiffs
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override;

    function slicerBatchTransfer(
        address from,
        address[] memory recipients,
        uint256 id,
        uint256[] memory amounts,
        bool release
    ) external;

    function safeTransferFromUnreleased(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setController(uint256 id, address newController) external;

    function setRoyalty(
        uint256 tokenId,
        bool isSlicer,
        bool isActive,
        uint256 royaltyPercentage
    ) external;

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount);

    function slicers(uint256 id) external view returns (address);

    function controller(uint256 id) external view returns (address);

    function totalSupply(uint256 id) external view returns (uint256);

    function supply() external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function _setBasePath(string calldata basePath_) external;

    function _togglePause() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ISlicerPurchasable {
    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external view returns (bool);

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Can be inherited by child contracts to add custom logic on product purchases.
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Function {
    bytes data;
    uint256 value;
    address externalAddress;
    bytes4 checkFunctionSignature;
    bytes4 execFunctionSignature;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubSlicerProduct.sol";
import "./CurrencyPrice.sol";

struct ProductParams {
    SubSlicerProduct[] subSlicerProducts;
    CurrencyPrice[] currencyPrices;
    bytes data;
    bytes purchaseData;
    uint32 availableUnits;
    // uint32 categoryIndex;
    uint8 maxUnitsPerBuyer;
    bool isFree;
    bool isInfinite;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PurchaseParams {
    uint128 slicerId;
    uint32 quantity;
    address currency;
    uint32 productId;
    bytes buyerCustomData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SubSlicerProduct {
    uint128 subSlicerId;
    uint32 subProductId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct CurrencyPrice {
    uint248 value;
    bool dynamicPricing;
    address currency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Payee {
    address account;
    uint32 shares;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
interface IERC165Upgradeable {
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