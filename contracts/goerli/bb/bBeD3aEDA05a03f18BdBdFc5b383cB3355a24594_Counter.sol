// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/FrensRG/ERC721U/blob/master/src/ERC721U.sol";


contract Counter is Ownable, ERC721U {
    /*/////////////////////////////
        Variables
    /*////////////////////////d/////
    bool public isWhiteListMintActive;
    bool public isPublicMintActive;

    uint256 public maxSupply;

    constructor() payable ERC721U("BordersOfVariety", "BOV") {
        isWhiteListMintActive = false;
        isPublicMintActive = false;

        maxSupply = 555;
    }

    receive() external payable {}

    /*/////////////////////////////
        Setters
    /*/////////////////////////////
    function setIsWhitelistMintActive(bool _active) external onlyOwner {
        isWhiteListMintActive = _active;
    }

    function setIsPublicMintActive(bool _active) external onlyOwner {
        isPublicMintActive = _active;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /*/////////////////////////////
        Mint Functions
    /*/////////////////////////////
    function whitelistMint() external payable {
        if(!isWhiteListMintActive) revert("Whitelist mint is not active");

        // bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        // require(MerkleProof.verify(_));

        // onwhitelist

        internalMint();
    }

    function publicMint(uint256 _amount) external payable {
        if(!isPublicMintActive) revert("Public mint is not active");
        require(msg.value >= 0.1 ether, "Not enought funds");
        internalMint();
    }

    function internalMint() internal {
        if(totalSupply() >= maxSupply) revert("We are sold out");
        _mint(msg.sender);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721U.sol";

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

contract ERC721U is IERC721U {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Struct used in ownerOf mapping to keep track of ownership and minted balance
     * This way we can do just one SSTORE to save gas on mint
     */
    struct GenesisOwner {
        //Token owner
        address owner;
        //when the ownership started
        uint64 startTimestamp;
        //Balance after minting which will always be 1
        uint16 mintedBalance;
        //If the token is burned
        bool burned;
    }

    /**
     * @dev Struct used in balanceOf mapping to keep track of ownership and minted balance
     * This way we can do just one SSTORE to save gas on mint
     */
    struct GenesisBalance {
        //Number of owned tokens. This will update  on first transfer to another EOA or ERC721Receiver
        uint64 balance;
        //Number of tokens burned
        uint16 numberBurned;
        //If the mapping is initialized
        bool initialized;
    }

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    // Mapping from token ID to ownership details
    mapping(uint256 => GenesisOwner) private _ownerOf;

    // Mapping owner address to balance data
    mapping(address => GenesisBalance) private _balanceOf;

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startCounter();
    }

    /*//////////////////////////////////////////////////////////////
                            IERC721 METADATA
    //////////////////////////////////////////////////////////////*/

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "NON_EXISTENT_TOKEN");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, toString(tokenId)))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN COUNTING OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Start counter to keep track of total supply and minted supply.
     * Starts at 1 because it saves gas for first minter
     * Override this method if you which to change this behavior
     */
    function _startCounter() internal view virtual returns (uint256) {
        return 1;
    }

    function totalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startCounter();
        }
    }

    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startCounter();
        }
    }

    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    /*//////////////////////////////////////////////////////////////
                        ADDRESS DATA OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        //Overflow is incredibly unrealistic
        unchecked {
            //Adds both values to reveal real balance in cases the genesis minter still has the token but acquired more tokens.
            return
                _balanceOf[owner].balance +
                _ownerOf[uint160(owner)].mintedBalance;
        }
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        return _balanceOf[owner].numberBurned;
    }

    function _isBurned(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId].burned;
    }

    function _startTimestamp(uint256 tokenId) internal view returns (uint256) {
        return _ownerOf[tokenId].startTimestamp;
    }

    /**
     * @dev Checks ownership of the tokendId provided
     * Token cannot be burned or owned by address 0
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner)
    {
        require(
            (owner = _ownerOf[tokenId].owner) != address(0) &&
                !_ownerOf[tokenId].burned,
            "NOT_EXISTANT_TOKEN"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _ownerOf[tokenId].owner != address(0) && // If within bounds,
            !_ownerOf[tokenId].burned; // and not burned.
    }

    function approve(address spender, uint256 id) public payable virtual {
        address owner = _ownerOf[id].owner;

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
        uint256 tokenId
    ) public payable virtual {
        require(from == _ownerOf[tokenId].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[tokenId],
            "NOT_AUTHORIZED"
        );
        //Check if the balance mapping has been initialized.
        if (_balanceOf[to].initialized) {
            //Updates the mapping and updates the owner.
            unchecked {
                --_balanceOf[from].balance;
                ++_balanceOf[to].balance;
            }

            _ownerOf[tokenId].owner = to;
            _ownerOf[tokenId].startTimestamp = uint64(block.timestamp);

            delete getApproved[tokenId];

            emit Transfer(from, to, tokenId);
        } else {
            // Means the person transfering is one of the genesis minters.
            //Initializes the mapping and cleans the minted balance and updates the owner.
            GenesisBalance memory genesisBalance = _balanceOf[to];
            unchecked {
                _balanceOf[to] = GenesisBalance(
                    genesisBalance.balance + _ownerOf[tokenId].mintedBalance,
                    genesisBalance.numberBurned,
                    true
                );

                _ownerOf[tokenId].owner = to;
                _ownerOf[tokenId].startTimestamp = uint64(block.timestamp);
                _ownerOf[tokenId].mintedBalance = 0;
            }

            delete getApproved[tokenId];

            emit Transfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public payable virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");
        uint256 tokenId = uint160(to);

        require(_ownerOf[tokenId].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        // No need to initialized the burned false since the default is false.
        unchecked {
            _ownerOf[tokenId].owner = to;
            _ownerOf[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerOf[tokenId].mintedBalance = 1;

            ++_currentIndex;
        }

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        GenesisOwner memory genesisOwner = _ownerOf[tokenId];

        require(!genesisOwner.burned, "BURNED");
        require(genesisOwner.owner != address(0), "NOT_MINTED");

        if (_balanceOf[genesisOwner.owner].initialized) {
            unchecked {
                --_balanceOf[genesisOwner.owner].balance;
                ++_balanceOf[genesisOwner.owner].numberBurned;
            }

            _ownerOf[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerOf[tokenId].burned = true;

            delete getApproved[tokenId];
            emit Transfer(genesisOwner.owner, address(0), tokenId);
        } else {
            // Means the person burning is one of the genesis minters.
            // Initializes the mapping and cleans the minted balance and updates the token to a burned one.
            unchecked {
                --_ownerOf[tokenId].mintedBalance;
                ++_balanceOf[genesisOwner.owner].numberBurned;
            }
            _ownerOf[tokenId].burned = true;

            delete getApproved[tokenId];
            emit Transfer(genesisOwner.owner, address(0), tokenId);
        }

        unchecked {
            ++_burnCounter;
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to) internal virtual {
        _mint(to);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    uint160(to),
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, bytes memory data) internal virtual {
        _mint(to);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    uint160(to),
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              OTHER LOGIC
    //////////////////////////////////////////////////////////////*/

    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
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
// Creator: 0xRaiden

pragma solidity ^0.8.4;

interface IERC721U {
    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}