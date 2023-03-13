// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "solmate/utils/MerkleProofLib.sol";

contract RayTaiNFT is ERC721, Owned {
    bytes32 public _root;
    uint256 immutable public _allowlist_price;
    uint256 immutable public _public_price;
    uint32 public _allowlist_sale_time_start;
    uint32 public _public_sale_time_start;
    uint32 public _public_sale_time_stop;
    address immutable public _withdrawer;
    uint16 immutable public _total_limit;
    uint16 _counter;
    uint8 immutable public _allowlist_per_acc_limit;
    uint8 immutable public _public_per_acc_limit;

    string _baseURI;

    struct MintCounters {
        uint8 minted_from_allow_list;
        uint8 minted_from_public_sale;
    }
    mapping(address => MintCounters) _per_acc_counters;

    constructor(string memory name, string memory symbol, bytes32 merkleroot,
                uint256 allowlist_price, uint256 public_price,
                uint8 allowlist_per_acc_limit, uint8 public_per_acc_limit,
                uint16 total_limit,
                uint32 allowlist_sale_time_start, uint32 public_sale_time_start,
                uint32 public_sale_time_stop, address withdrawer,
                string memory baseURI)
    ERC721(name, symbol)
    Owned(msg.sender)
    {
        require(allowlist_sale_time_start < public_sale_time_start && public_sale_time_start < public_sale_time_stop);
        _root = merkleroot;
        _allowlist_price = allowlist_price;
        _public_price = public_price;
        _allowlist_per_acc_limit = allowlist_per_acc_limit;
        _public_per_acc_limit = public_per_acc_limit;
        _total_limit = total_limit;
        _allowlist_sale_time_start = allowlist_sale_time_start;
        _public_sale_time_start = public_sale_time_start;
        _public_sale_time_stop = public_sale_time_stop;
        _withdrawer = withdrawer;
        _baseURI = baseURI;
    }

    function mint(address account, uint8 amount, bytes32[] calldata proof)
    external payable
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        require(allowlist_sale_is_in_progress(), "Allowlist sale is not now");
        require(msg.value == uint256(amount) * _allowlist_price, "Insufficient ETH provided for AL sale");
        require(255 - amount >= _per_acc_counters[account].minted_from_allow_list, "Overflow on checking the AL limit");
        require(_per_acc_counters[account].minted_from_allow_list + amount <= _allowlist_per_acc_limit, "Over the AL limit");
        unchecked {
            _per_acc_counters[account].minted_from_allow_list += amount;
        }
        _mintImpl(account, amount);
    }

    function mint(address account, uint8 amount)
    public payable
    {
        require(public_sale_is_in_progress(), "Public sale have not started");
        require(msg.value == uint256(amount) * _public_price, "Insufficient ETH provided for public sale");
        require(255 - amount >= _per_acc_counters[account].minted_from_public_sale, "Overflow checking Public Sale Limits");
        require(_per_acc_counters[account].minted_from_public_sale + amount <= _public_per_acc_limit, "Over the Public Sale limit");
        unchecked {
            _per_acc_counters[account].minted_from_public_sale += amount;
        }
        _mintImpl(account, amount);
    }

    function _mintImpl(address account, uint8 amount) internal {
        require(_counter < _total_limit, "No NFTs left");
        uint16 final_index;
        unchecked {
            final_index = _counter + amount;
            if (final_index > _total_limit) {
                final_index = _total_limit;
                (bool returnSent, ) = msg.sender.call{value: msg.value / amount * (_counter + amount - _total_limit)}("");
                require(returnSent);
            }
        }

        for (uint16 index = _counter; index < final_index; ) {
            // Although 721a makes bulk mints cheaper, in a long run, after collection
            // is used for a while, all of it's smartness turns into complications IMO.
            _mint(account, index);
            unchecked { ++index; }
        }

        unchecked {
            _counter = final_index;
        }
    }

    function allowlist_sale_is_in_progress() internal view returns (bool) {
        return block.timestamp >= _allowlist_sale_time_start && block.timestamp <= _public_sale_time_start;
    }

    function public_sale_is_in_progress() internal view returns (bool) {
        return block.timestamp >= _public_sale_time_start && block.timestamp <= _public_sale_time_stop;
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] calldata proof)
    internal view returns (bool)
    {
        return MerkleProofLib.verify(proof, _root, leaf);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, LibString.toString(id), ".json"));
    }

    function setBaseURL(string calldata newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function setRoot(bytes32 newRoot) external onlyOwner {
        _root = newRoot;
    }

    function withdraw() external {
        require(msg.sender == _withdrawer, "You are not an owner");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent);
    }

    function resetTimings(uint32 allowlist_sale_time_start, uint32 public_sale_time_start, uint32 public_sale_time_stop) external onlyOwner {
        require(allowlist_sale_time_start < public_sale_time_start && public_sale_time_start < public_sale_time_stop);
        _allowlist_sale_time_start = allowlist_sale_time_start;
        _public_sale_time_start = public_sale_time_start;
        _public_sale_time_stop = public_sale_time_stop;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solmate/auth/Owned.sol";
import "solmate/utils/MerkleProofLib.sol";

import {RayTaiNFT} from "./RayTaiNFT.sol";

contract RaytaiUnmint is Owned {
    RayTaiNFT immutable _collection;
    uint256 immutable _first_public_sale_token_id;
    bytes32 public _root;
    address immutable public _withdrawer;

    constructor(bytes32 merkleroot, address withdrawer, RayTaiNFT collection, uint256 first_public_sale_token_id) 
    Owned(msg.sender) {
        _collection = collection;
        _first_public_sale_token_id = first_public_sale_token_id;
        _root = merkleroot;
	    _withdrawer = withdrawer;
    }

    //function unmint(uint256 tokenId, bool isAL, bytes32[] calldata proof) external {
        // require(_verify(_leaf(msg.sender, tokenId, isAL), proof), "Invalid merkle proof");
        // _collection.safeTransferFrom(msg.sender, address(this), tokenId);
        // if (tokenId >= _first_public_sale_token_id) {
        //     (bool result, ) = msg.sender.call{value: 33000000 gwei}("");
        //     require(result, "Transfer failed.");
        // } else {
        //     (bool result, ) = msg.sender.call{value: 25000000 gwei}("");
        //     require(result, "Transfer failed.");
        // }
    //}

    // function setRoot(bytes32 newRoot) external onlyOwner {
    //     _root = newRoot;
    // }

    function withdraw() external {
        require(msg.sender == _withdrawer, "You are not an owner");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent);
    }

    // function _leaf(address account, uint256 tokenId, bool isAL)
    // internal pure returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(account, tokenId, isAL));
    // }

    // function _verify(bytes32 leaf, bytes32[] calldata proof)
    // internal view returns (bool)
    // {
    //     return MerkleProofLib.verify(proof, _root, leaf);
    // }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external virtual returns (bytes4) {
        require(msg.sender == address(_collection), "Not from collection");
        if (tokenId >= _first_public_sale_token_id) {
            (bool result, ) = from.call{value: 33000000 gwei}("");
            require(result, "Transfer failed.");
        } else {
            (bool result, ) = from.call{value: 25000000 gwei}("");
            require(result, "Transfer failed.");
        }
        return RaytaiUnmint.onERC721Received.selector;
    }

    receive() external payable {}
}