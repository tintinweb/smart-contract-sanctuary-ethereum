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
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

interface IGoldenPass {
    function burn(address from, uint256 amount) external;
}

contract FoodzParty is ERC721, Ownable {
    using Strings for uint160;
    using Strings for uint256;

    /// @dev 0x843ce46b
    error InvalidClaimAmount();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0x5d25f4ec
    error MaxPerTx();
    /// @dev 0xb36c1284
    error MaxSupply();
    /// @dev 0xb9968551
    error PassSaleOff();
    /// @dev 0xa6802b50
    error PresaleOff();
    /// @dev 0x3afc8ce9
    error SaleOff();
    /// @dev 0xb52aa4c0
    error QueryForNonExistentToken();
    /// @dev 0x750b219c
    error WithdrawFailed();
    /// @dev 0x98d4901c
    error WrongValue();

    // Immutable

    /// @notice the max amount of tokens that can be minted via golden pass
    uint256 public constant GOLDEN_PASS_MAX_SUPPLY = 500;
    /// @notice the starting id for tokens minted via golden pass.
    ///         tokens minted via golden pass have ids from 9451 to 9950
    uint256 internal constant GOLDEN_PASS_START_INDEX = 9451;
    /// @notice the max amount of tokens that can be minted using eth
    uint256 public constant NON_GOLDEN_PASS_MAX_SUPPLY = 9451;
    /// @notice the price to mint each token on presale
    uint256 public constant PRESALE_PRICE = 0.07 ether;
    /// @notice the price to mint 1 token on public sale
    uint256 public constant SALE_SINGLE_PRICE = 0.1 ether;
    /// @notice the price to mint 3 tokens bundle on public sale
    uint256 public constant SALE_TRIPLE_PRICE = 0.24 ether;
    /// @notice the max amount of rare 1:1 tokens.
    uint256 internal constant RARE11_MAX_SUPPLY = 50;
    /// @notice the starting id for the handmade 1:1 tokens.
    uint256 internal constant RARE11_GOLDEN_PASS_START_INDEX = 9951;

    /// @notice the merkle root for the allow-list
    bytes32 internal immutable merkleRoot;
    /// @notice address of the golden pass contract
    IGoldenPass internal immutable goldenPass;
    /// @notice address to send the contract's eth to
    address internal immutable payoutAddress;

    // Mutable

    /// @notice if the presale via allow-list is active
    bool public isPresaleActive = false;
    /// @notice the current amount of tokens minted via golden pass
    uint256 public passSupply;
    /// @notice the current amount of tokens minted via eth
    /// @dev starts with 1 cuz bc mint #0 on constructor
    uint256 public nonpassSupply = 1;
    /// @notice if the public sale is active
    bool public isSaleActive = false;
    /// @notice the base url where the metadata is hosted
    string public baseURI;
    /// @notice if the golden pass sale is active
    bool public isPassSaleActive = false;
    /// @notice the current amount of rare 1:1 tokens minted
    uint256 public rare11Supply;

    /// @notice the amount of tokens a user claimed so far via allow-list.
    /// @dev this is used to prevent wallets that had N spots in the allow-list to mint N + 1
    mapping(address => uint256) public amountClaimedByUser;

    // Constructor

    constructor(
        IGoldenPass goldenPass_,
        string memory baseURI_,
        bytes32 merkleRoot_,
        address payoutAddress_
    ) ERC721("Foodz Party", "FP") {
        goldenPass = goldenPass_;
        baseURI = baseURI_;
        merkleRoot = merkleRoot_;
        // slither-disable-next-line missing-zero-check
        payoutAddress = payoutAddress_;
        _safeMint(0x067423C244442ca0Eb6d6fd6B747c2BD21414107, 0);
    }

    // Owner Only

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setIsPresaleActive(bool newIsPresaleActive) external onlyOwner {
        isPresaleActive = newIsPresaleActive;
    }

    function setIsPassSaleActive(bool newIsPassSaleActive) external onlyOwner {
        isPassSaleActive = newIsPassSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        // slither-disable-next-line low-level-calls missing-zero-check
        (bool payoutSent, ) = payable(payoutAddress).call{ // solhint-disable-line avoid-low-level-calls
            value: contractBalance
        }("");

        if (!payoutSent) revert WithdrawFailed();
    }

    function raremint(address to) external onlyOwner {
        unchecked {
            // slither-disable-next-line events-maths
            uint256 supply = ++rare11Supply;
            if (supply > RARE11_MAX_SUPPLY) revert MaxSupply();
            _safeMint(to, RARE11_GOLDEN_PASS_START_INDEX + supply - 1);
        }
    }

    // User

    function passmint(uint256 amount) external {
        if (!isPassSaleActive) revert PassSaleOff();
        uint256 supply = passSupply;
        unchecked {
            if (passSupply + amount > GOLDEN_PASS_MAX_SUPPLY)
                revert MaxSupply();
            // slither-disable-next-line events-maths
            passSupply += amount;
        }

        goldenPass.burn(msg.sender, amount);

        unchecked {
            uint256 baseIndex = GOLDEN_PASS_START_INDEX + supply;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, baseIndex + i);
            }
        }
    }

    function premint(
        uint256 amount,
        uint256 mintLimit,
        bytes32[] calldata proof
    ) external payable {
        if (!isPresaleActive) revert PresaleOff();
        unchecked {
            if (amountClaimedByUser[msg.sender] + amount > mintLimit)
                revert InvalidClaimAmount();
            if (msg.value != PRESALE_PRICE * amount) revert WrongValue();
            if (nonpassSupply + amount > NON_GOLDEN_PASS_MAX_SUPPLY)
                revert MaxSupply();
        }
        bytes32 leaf = keccak256(
            abi.encodePacked(
                uint160(msg.sender).toHexString(20),
                ":",
                mintLimit.toString()
            )
        );
        bool isProofValid = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isProofValid) revert InvalidMerkleProof();
        unchecked {
            amountClaimedByUser[msg.sender] += amount;
        }

        uint256 supply = nonpassSupply;
        unchecked {
            // slither-disable-next-line events-maths
            nonpassSupply += amount;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, supply + i);
            }
        }
    }

    function mintSingle() external payable {
        if (!isSaleActive) revert SaleOff();
        unchecked {
            // slither-disable-next-line events-maths
            uint256 updatedSupply = ++nonpassSupply;
            if (msg.value != SALE_SINGLE_PRICE) revert WrongValue();
            if (updatedSupply > NON_GOLDEN_PASS_MAX_SUPPLY) revert MaxSupply();
            _safeMint(msg.sender, updatedSupply - 1);
        }
    }

    function mintTriple() external payable {
        if (!isSaleActive) revert SaleOff();
        unchecked {
            if (msg.value != SALE_TRIPLE_PRICE) revert WrongValue();
            // slither-disable-next-line events-maths
            uint256 updatedSupply = (nonpassSupply += 3);
            if (updatedSupply > NON_GOLDEN_PASS_MAX_SUPPLY) revert MaxSupply();
            _safeMint(msg.sender, updatedSupply - 3);
            _safeMint(msg.sender, updatedSupply - 2);
            _safeMint(msg.sender, updatedSupply - 1);
        }
    }

    // View

    function currentSupply() external view returns (uint256) {
        unchecked {
            return passSupply + nonpassSupply + rare11Supply;
        }
    }

    // Overrides

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_ownerOf[id] == address(0)) revert QueryForNonExistentToken();
        return string(abi.encodePacked(baseURI, id.toString()));
    }
}