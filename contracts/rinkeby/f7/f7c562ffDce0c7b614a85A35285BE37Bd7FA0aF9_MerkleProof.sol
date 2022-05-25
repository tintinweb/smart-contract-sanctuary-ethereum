// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____                _ _                      
 |  __ \                   | |              / _| | | | |           / ____|              (_) |                     
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __ _ __ _| |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| '__| | '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | |  | | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|  |_|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

/// @title Parrots of the Carribean
/// @author rayne & jackparrot

pragma solidity >=0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "./MerkleProof.sol";
import "@openzeppelin/utils/Strings.sol";

/// @notice Thrown when attempting to mint while total supply has been minted.
error MintedOut();
/// @notice Thrown when minter does not have enough ether.
error NotEnoughFunds();
/// @notice Thrown when a public minter / whitelist minter has reached their mint capacity.
error AlreadyClaimed();
/// @notice Thrown when the jam sale is not active.
error JamSaleNotActive();
/// @notice Thrown when the public sale is not active.
error PublicSaleNotActive();
/// @notice Thrown when the msg.sender is not in the jam list.
error NotJamListed();
/// @notice Thrown when a signer is not authorized.
error NotAuthorized();

contract POTC is ERC721, Owned {
    using Strings for uint256;

    /// @notice The total supply of POTC.
    uint256 public constant MAX_SUPPLY = 555;
    /// @notice Mint price.
    uint256 public mintPrice = 0.1 ether;
    /// @notice The current supply starts at 15 due to the team minting from tokenID 0 to 14.
    /// @dev Using total supply as naming to make the pre-reveal easier on amazon S3.
    uint256 public totalSupply = 15;

    /// @notice The base URI.
    string baseURI;

    /// @notice Returns true when the jam list sale is active, false otherwise.
    bool public jamSaleActive;
    /// @notice Returns true when the public sale is active, false otherwise.
    bool public publicSaleActive;

    /// @notice Keeps track of whether jamlist has already minted or not. Max 1 mint.
    mapping(address => bool) public whitelistClaimed;
    /// @notice Keeps track of whether a public minter has already minted or not. Max 1 mint.
    mapping(address => bool) public publicClaimed;

    /// @notice Merkle root hash for whitelist verification.
    /// @dev Set to immutable instead of hard-coded to prevent human-error when deploying.
    bytes32 public immutable merkleRoot;
    /// @notice Address of the signer who is allowed to burn POTC.
    address private potcBurner;

    constructor(string memory _baseURI, bytes32 _merkleRoot)
        ERC721("Parrots of the Carribean", "POTC")
        Owned(msg.sender)
    {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
        _balanceOf[msg.sender] = 15;
        unchecked {
            for (uint256 i = 0; i < 15; ++i) {
                _ownerOf[i] = msg.sender;
                emit Transfer(address(0), msg.sender, i);
            }
        }
    }

    /// @notice Allows the owner to change the base URI of POTC's corresponding metadata.
    /// @param _uri The new URI to set the base URI to.
    function setURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    /// @notice The URI pointing to the metadata of a specific assett.
    /// @param _id The token ID of the requested parrot. Hardcoded .json as suffix.
    /// @return The metadata URI.
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    /// @notice Public POTC mint.
    /// @dev Allows any non-contract signer to mint a single POTC. Capped by 1.
    /// @dev Jamlisted addresses can join mint both one POTC during jam sale & public sale.
    /// @dev Current supply addition can be unchecked, as it cannot overflow.
    /// TODO chain if statements to see if we can save gas?
    function publicMint() public payable {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (publicClaimed[msg.sender]) revert AlreadyClaimed();
        if (totalSupply + 1 > MAX_SUPPLY) revert MintedOut();
        if ((msg.value) < mintPrice) revert NotEnoughFunds();

        unchecked {
            publicClaimed[msg.sender] = true;
            _mint(msg.sender, totalSupply);
            ++totalSupply;
        }
    }

    /// @notice Mints a POTC for a signer on the jamlist. Gets the tokenID correspondign to the current supply.
    /// @dev We do not keep track of the whitelist supply, considering only a total of 444 addresses will be valid in the merkle tree.
    /// @dev This means that the maximum supply including full jamlist mint and team mint can be 459 at most, as each address can mint once.
    /// @dev Current supply addition can be unchecked, as it cannot overflow.
    /// @param _merkleProof The merkle proof based on the address of the signer as input.
    function jamListMint(bytes32[] calldata _merkleProof) public payable {
        if (!jamSaleActive) revert JamSaleNotActive();
        if (whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if ((msg.value) < mintPrice) revert NotEnoughFunds();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert NotJamListed();

        unchecked {
            whitelistClaimed[msg.sender] = true;
            _mint(msg.sender, totalSupply);
            ++totalSupply;
        }
    }

    /// @notice Authorize a specific address to serve as the POTC burner. For future use.
    /// @param _newBurner The address of the new burner.
    function setPOTCBurner(address _newBurner) public onlyOwner {
        potcBurner = _newBurner;
    }

    /// @notice Burn a POTC with a specific token id.
    /// @dev !NOTE: Both publicSale & jamSale should be inactive.
    /// @dev Unlikely that the totalSupply will be below 0. Hence, unchecked.
    /// @param tokenId The token ID of the parrot to burn.
    function burn(uint256 tokenId) public {
        if (msg.sender != potcBurner) revert NotAuthorized();
        unchecked {
            --totalSupply;
        }
        _burn(tokenId);
    }

    /// @notice Flip the jam sale state.
    function flipJamSaleState() public onlyOwner {
        jamSaleActive = !jamSaleActive;
    }

    /// @notice Flip the public sale state.
    function flipPublicSaleState() public onlyOwner {
        jamSaleActive = false;
        publicSaleActive = !publicSaleActive;
    }

    /// @notice Set the price of mint, in case there is no mint out.
    function setPrice(uint256 _targetPrice) public onlyOwner {
        mintPrice = _targetPrice;
    }

    /// @notice Transfer all funds from contract to the contract deployer address.
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
// MODIFIED MerkleProof contracts from OpenZeppelin to use calldata instead of memory for the proofs.
// See https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3200/

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
        bytes32[] calldata proof,
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
    function processProof(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
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