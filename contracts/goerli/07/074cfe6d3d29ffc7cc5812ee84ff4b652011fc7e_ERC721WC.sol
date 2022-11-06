/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

contract ERC721WC is ERC721 {
    address payable public owner;

    uint256 public immutable mintCost; // in wei
    uint256 public immutable maxSupply;  // total number of NFTs
    uint256 public immutable numInitialTeams;  // 32 for WC
    uint256 public immutable maxMintPerAddress;  // max amount each wallet can mint

    uint256 public numMinted;  // number of items already minted
    uint256 public numQualifiedWithdraw;  // current number of qualified items to withdraw
    mapping (address => uint256) public addressNumMinted;  // amount already minted in each wallet
    mapping (uint256 => bool) public qualifiedTeams;  // which teams are still qualified
    mapping (uint256 => uint256) public numTradableItems;  // number of qualified items in each team

    bool public mintEnded;  // cannot mint after teams are assigned
    bool public locked;  // contract locked (can not withdraw) during game
    bool public finalized;  // contract finalized (can not change qualification) end of the championship

    error NotOwner();
    error NotHolder();
    error IncorrectPayment(uint256 expected, uint256 amount);
    error InsufficientBalance(uint256 amount);
    error TransferFailed();
    error mintingEnded();
    error Unqualified();
    error AlreadyLocked();
    error AlreadyUnlocked();
    error AlreadyFinalized();
    error ReentryAttackDefender();
    error MaxSupplyReached();
    error MaxMintAmountReached();

    constructor(
        uint256 _mintCost,
        uint256 _numInitialTeams,
        uint256 _maxSupply,
        uint256 _maxMintPerAddress
    ) ERC721(name, symbol) {
        owner = payable(msg.sender);

        name = string("Hologram WC 2022 Jersey");
        symbol = string("HWC");

        mintCost = _mintCost;
        maxSupply = _maxSupply;
        numInitialTeams = _numInitialTeams;
        maxMintPerAddress = _maxMintPerAddress;

        numMinted = 0;
        numQualifiedWithdraw = 0;

        for (uint256 i = 0; i < numInitialTeams; i++) {
            qualifiedTeams[i] = true;  // initially all teams are qualified
            numTradableItems[i] = 0;  // no items in the market before minting
        }

        mintEnded = false;
        locked = false;
        finalized = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function lockContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        locked = true;
    }

    function unlockContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        locked = false;
    }

    function finalizeContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        finalized = true;
    }

    function endMinting() public onlyOwner {
        if (mintEnded) revert mintingEnded();
        mintEnded = true;
    }

    function updateQualification(uint256 _teamId, bool _qualified) public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        if (!locked) revert AlreadyUnlocked();

        if (qualifiedTeams[_teamId] == true && _qualified == false) {
            // normal advance of tournament
            numQualifiedWithdraw -= numTradableItems[_teamId];
            qualifiedTeams[_teamId] = false;
        } else if (qualifiedTeams[_teamId] == false && _qualified == true) {
            // in case admin messes up
            numQualifiedWithdraw += numTradableItems[_teamId];
            qualifiedTeams[_teamId] = true;
        }
    }

    function withdraw(uint256 _tokenId) public {
        if (locked) revert AlreadyLocked();  // cannot withdraw during game

        if (msg.sender != _ownerOf[_tokenId]) revert NotHolder();

        uint256 teamId = _tokenId % numInitialTeams;
        if (!qualifiedTeams[teamId]) revert Unqualified();

        uint256 amount = address(this).balance / numQualifiedWithdraw;  // built in floor operation on floats
        if (address(this).balance < amount) revert InsufficientBalance(amount);

        (bool success, ) = _ownerOf[_tokenId].call{value: amount}("");
        if (!success) revert TransferFailed();

        numQualifiedWithdraw -= 1;
        numTradableItems[teamId] -= 1;

        // burn the actual token
        _burn(_tokenId);
    }

    function batchWithdraw(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            withdraw(_tokenIds[i]);
        }
    }

    // TODO: Currently placeholder
    function tokenURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return "";
    }

    function getMintedAmount(address _addr) public view returns(uint256) {
        return addressNumMinted[_addr];
    }

    function mint() public payable {
        if (mintEnded) revert mintingEnded();
        if (numMinted == maxSupply) revert MaxSupplyReached();
        if (msg.value != mintCost) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] == maxMintPerAddress) revert MaxMintAmountReached();
        
        _mint(to, numMinted);
        
        uint256 teamId = numMinted % numInitialTeams;
        numQualifiedWithdraw += 1;
        numTradableItems[teamId] += 1;

        addressNumMinted[to] += 1;
        numMinted += 1;
    }

    function batchMint(uint256 numToMint) public payable {
        if (mintEnded) revert mintingEnded();
        if (numMinted + numToMint > maxSupply) revert MaxSupplyReached();
        if (msg.value != mintCost * numToMint) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] + numToMint > maxMintPerAddress) revert MaxMintAmountReached();

        for (uint256 i = numMinted; i < numMinted + numToMint; i ++) {
            _mint(to, i);
            uint256 teamId = numMinted % numInitialTeams;
            numTradableItems[teamId] += 1;
        }

        numQualifiedWithdraw += numToMint;
        addressNumMinted[to] += numToMint;
        numMinted += numToMint;
    }
}