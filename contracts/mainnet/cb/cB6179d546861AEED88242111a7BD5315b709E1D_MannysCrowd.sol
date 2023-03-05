// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
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

        if (to.code.length != 0)
            require(
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

        if (to.code.length != 0)
            require(
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

        if (to.code.length != 0)
            require(
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

        if (to.code.length != 0)
            require(
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient bitmap library for mapping integers to single bit booleans.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibBitmap.sol)
library LibBitmap {
    struct Bitmap {
        mapping(uint256 => uint256) map;
    }

    function get(Bitmap storage bitmap, uint256 index) internal view returns (bool isSet) {
        uint256 value = bitmap.map[index >> 8] & (1 << (index & 0xff));

        assembly {
            isSet := value // Assign isSet to whether the value is non zero.
        }
    }

    function set(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    function unset(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }

    function setTo(
        Bitmap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        uint256 value = bitmap.map[index >> 8];

        assembly {
            // The following sets the bit at `shift` without branching.
            let shift := and(index, 0xff)
            // Isolate the bit at `shift`.
            let x := and(shr(shift, value), 1)
            // Xor it with `shouldSet`. Results in 1 if both are different, else 0.
            x := xor(x, shouldSet)
            // Shifts the bit back. Then, xor with value.
            // Only the bit at `shift` will be flipped if they differ.
            // Every other bit will stay the same, as they are xor'ed with zeroes.
            value := xor(value, shl(shift, x))
        }
        bitmap.map[index >> 8] = value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0"; // Otherwise it'd output an empty string for 0.

        assembly {
            let k := 78 // Start with the max length a uint256 string could be.

            // We'll store our string at the first chunk of free memory.
            str := mload(0x40)

            // The length of our string will start off at the max of 78.
            mstore(str, k)

            // Update the free memory pointer to prevent overriding our string.
            // Add 128 to the str pointer instead of 78 because we want to maintain
            // the Solidity convention of keeping the free memory pointer word aligned.
            mstore(0x40, add(str, 128))

            // We'll populate the string from right to left.
            // prettier-ignore
            for {} n {} {
                // The ASCII digit offset for '0' is 48.
                let char := add(48, mod(n, 10))

                // Write the current character into str.
                mstore(add(str, k), char)

                k := sub(k, 1)
                n := div(n, 10)
            }

            // Shift the pointer to the start of the string.
            str := add(str, k)

            // Set the length of the string to the correct value.
            mstore(str, sub(78, k))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {LibBitmap} from "solmate/utils/LibBitmap.sol";

interface MannysGame {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokensByOwner(address _owner)
        external
        view
        returns (uint16[] memory);
}

contract MannysCrowd is ERC721, Owned {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    MannysGame private constant MANNYS_GAME =
        MannysGame(0x2bd58A19C7E4AbF17638c5eE6fA96EE5EB53aed9);
    address private constant MANNY_DAO =
        0xd0fA4e10b39f3aC9c95deA8151F90b20c497d187;
    uint256 public constant PUBLIC_MINT_PRICE = 0.0404 ether;
    uint256 public immutable PUBLIC_MINT_ENABLED_AFTER;

    /* -------------------------------------------------------------------------- */
    /*                                    DATA                                    */
    /* -------------------------------------------------------------------------- */
    using LibBitmap for LibBitmap.Bitmap;
    LibBitmap.Bitmap private mints;
    string private _baseURI = "https://mannys-crowd.32swords.com/token/";
    bool public MERGING_ENABLED = false;
    mapping(uint256 => uint256[]) public merged;

    /* -------------------------------------------------------------------------- */
    /*                               EVENTS & ERRORS                              */
    /* -------------------------------------------------------------------------- */
    event CrowdsMerged(uint256 tokenIdBase, uint256 tokenIdMerge);
    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    error AlreadyMinted(uint256 tokenId);
    error NothingToMint(address owner);
    error NotOwner(uint256 tokenId);
    error MintingNotOpen();
    error InvalidMintFee();
    error OwnerMintClosed();
    error MergingNotOpen();

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */
    constructor() ERC721("Manny Crowds", "MC") Owned(msg.sender) {
        PUBLIC_MINT_ENABLED_AFTER = block.timestamp + 4.04 days;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MINTING                                  */
    /* -------------------------------------------------------------------------- */
    function mintOne(uint256 tokenId) external payable {
        // If caller is not owner of token, require public minting to be open & fee to be paid
        if (MANNYS_GAME.ownerOf(tokenId) != msg.sender) {
            if (block.timestamp < PUBLIC_MINT_ENABLED_AFTER)
                revert MintingNotOpen();
            if (msg.value != PUBLIC_MINT_PRICE) revert InvalidMintFee();
        } else if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER) {
            // If caller is owner of token and public minting has started, require fee to be paid
            if (msg.value != PUBLIC_MINT_PRICE) revert InvalidMintFee();
        }

        // Mint token if not already minted
        if (mints.get(tokenId)) revert AlreadyMinted(tokenId);
        mints.set(tokenId);
        _mint(msg.sender, tokenId);
    }

    function mintSomeOwned(uint16[] calldata tokenIds) external {
        // Don't allow batch free minting after public minting opens
        if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER)
            revert OwnerMintClosed();

        if (tokenIds.length == 0) revert NothingToMint(msg.sender);

        // Loop through all included Mannys
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Check ownership of each token
            if (MANNYS_GAME.ownerOf(tokenIds[i]) != msg.sender)
                revert NotOwner(tokenIds[i]);
            // Mint crowd if not already minted. Otherwise just skip to next token
            if (!mints.get(tokenIds[i])) {
                mints.set(tokenIds[i]);
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    function mintAllOwned() external {
        // Don't allow batch free minting after public minting opens
        if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER)
            revert OwnerMintClosed();

        // Get all Mannys owned by sender
        uint16[] memory tokenIds = MANNYS_GAME.tokensByOwner(msg.sender);
        if (tokenIds.length == 0) revert NothingToMint(msg.sender);

        // Loop through all owned Mannys
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Mint crowd if not already minted. Otherwise just skip to next token
            if (!mints.get(tokenIds[i])) {
                mints.set(tokenIds[i]);
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MERGING                                  */
    /* -------------------------------------------------------------------------- */
    function merge(uint256 tokenIdToKeep, uint256 tokenIdToBurn) external {
        if (!MERGING_ENABLED) revert MergingNotOpen();

        // Verify ownership of both tokens
        if (ownerOf(tokenIdToKeep) != msg.sender)
            revert NotOwner(tokenIdToKeep);
        if (ownerOf(tokenIdToBurn) != msg.sender)
            revert NotOwner(tokenIdToBurn);

        // Add burn token to base token's merge list
        merged[tokenIdToKeep].push(tokenIdToBurn);

        // If the token to burn already has others merged into it, move those to the token to keep
        if (merged[tokenIdToBurn].length > 0) {
            for (uint256 i = 0; i < merged[tokenIdToBurn].length; i++) {
                merged[tokenIdToKeep].push(merged[tokenIdToBurn][i]);
            }
        }
        delete merged[tokenIdToBurn];

        // Burn the token
        _burn(tokenIdToBurn);

        // Emit event to trigger new rendering job
        emit CrowdsMerged(tokenIdToKeep, tokenIdToBurn);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string.concat(_baseURI, LibString.toString(tokenId));
    }

    function refreshMetadata(uint256 tokenId) external {
        emit MetadataUpdate(tokenId);
    }

    function refreshMetadataBatch(uint256 fromTokenId, uint256 toTokenId)
        external
    {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function refreshMetadataAll() external {
        emit BatchMetadataUpdate(0, 1616);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MANNYDAO                                  */
    /* -------------------------------------------------------------------------- */
    function withdraw() external {
        (bool sent, ) = MANNY_DAO.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external {
        ERC20(tokenAddress).transfer(MANNY_DAO, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */
    function setMergingEnabled(bool status) external onlyOwner {
        MERGING_ENABLED = status;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseURI = baseURI;
    }
}