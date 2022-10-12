// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "fount-contracts/auth/Auth.sol";
import "fount-contracts/tokens/ERC721Premint.sol";
import "fount-contracts/extensions/BatchedReleaseOperatorExtension.sol";
import "fount-contracts/extensions/SwappableMetadata.sol";
import "fount-contracts/utils/Royalties.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "./interfaces/IOperatorCollectable.sol";
import "./interfaces/IMetadata.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  ERC721 batched pre-minting example
 * @notice Features:
 *           - ERC-721 pre-minting upon deployment
 *           - Batched releases
 *           - Operator contracts for minting which allows for custom logic per batch
 *           - Swappable metadata contract
 *           - On-chain royalties standard (EIP-2981)
 */
contract ExampleBatchedPremint is
    ERC721Premint,
    IOperatorCollectable,
    BatchedReleaseOperatorExtension,
    SwappableMetadata,
    Royalties,
    Auth,
    ReentrancyGuard
{
    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param premintTo_ The address to pre-mint the max supply of tokens to
     * @param maxTokenId_ Used for batched releases to determine the max supply
     * @param batchSize_ The size of each batch to release at a time
     * @param metadata_ The initial metadata contract address
     */
    constructor(
        address owner_,
        address admin_,
        address premintTo_,
        uint256 maxTokenId_,
        uint256 batchSize_,
        address metadata_
    )
        ERC721Premint("Example NFT", "ENFT", premintTo_, maxTokenId_)
        BatchedReleaseOperatorExtension(maxTokenId_, batchSize_)
        SwappableMetadata(metadata_)
        Royalties(owner_, 0)
        Auth(owner_, admin_)
    {
        minter = premintTo_;
    }

    /* ------------------------------------------------------------------------
                            C O L L E C T   T O K E N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Collect a specific token from an operator contract
     * @dev Reverts if:
     *   - `id` has already been collected
     *   - `id` is not a token from the current `activeBatch`
     *   - caller is not approved for the current `activeBatch`
     * @param id The token id to collect
     * @param to The address to transfer the token to
     */
    function collect(uint256 id, address to)
        public
        override
        onlyWhenTokenIsInActiveBatch(id)
        onlyWhenOperatorForActiveBatch
        nonReentrant
    {
        // Transfer the token from the current owner to the new owner
        transferFrom(ownerOf(id), to, id);

        // Mark the token as collected
        _collectToken(id);
    }

    /**
     * @notice Mark a specific token id as collected by an operator contract
     * @dev Reverts if:
     *   - `id` has already been collected
     *   - `id` is not a token from the current `activeBatch`
     *   - caller is not approved for the current `activeBatch`
     * @param id The token id that was collected
     */
    function markAsCollected(uint256 id)
        public
        override
        onlyWhenTokenIsInActiveBatch(id)
        onlyWhenOperatorForActiveBatch
        nonReentrant
    {
        // Mark the token as collected
        _collectToken(id);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set an operator for a specific batch
     * @dev Allows the operator to collect/transfer tokens for a specific batch.
     * Also sets {isApprovedForAll} so it can transfer tokens.
     * Reverts if the batch number is invalid
     * @param batch The batch to set the operator for
     * @param operator The operator contract that get's approval to all the minters tokens
     */
    function setBatchOperator(uint256 batch, address operator) public override onlyAdmin {
        // Remove approvals for the previous operator contract
        isApprovedForAll[minter][operatorForBatch[batch]] = false;

        // Automatically approve the new operator contract
        isApprovedForAll[minter][operator] = true;

        // Set the new operator
        _setBatchOperator(batch, operator);
    }

    /**
     * @notice Admin function to advance the active batch based on the number of tokens sold
     * @dev Reverts if the current batch hasn't sold out yet
     */
    function goToNextBatch() public override onlyAdmin {
        _goToNextBatch();
    }

    /**
     * @notice Admin function to set the metadata contract address
     * @param metadata_ The new metadata contract address
     */
    function setMetadataAddress(address metadata_) public override onlyAdmin {
        _setMetadataAddress(metadata_);
    }

    /**
     * @notice Admin function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyAdmin {
        _setRoyaltyInfo(receiver, amount);
    }

    /* ------------------------------------------------------------------------
                                    E R C 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the token metadata
     * @return id The token id to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return IMetadata(metadata).tokenURI(id);
    }

    /**
     * @notice Add on-chain royalty standard
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == ROYALTY_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Burn a token. You can only burn tokens you own.
     * @param id The token id to burn
     */
    function burn(uint256 id) external {
        require(ownerOf(id) == msg.sender, "NOT_OWNER");
        _burn(id);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     * @param admin_ An initial admin of the contract
     */
    constructor(address owner_, address admin_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);

        admins[admin_] = true;
        emit AdminAdded(address(0), admin_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(address(0), newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(address(0), prevAdmin);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "solmate/tokens/ERC721.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title ERC721 Premint
 * @notice Extension of solmate/ERC721.sol to include preminting the total supply
 * to an address upon deployment in a gas efficient way.
 */
abstract contract ERC721Premint is ERC721 {
    /// @dev Max number of tokens that were preminted
    uint256 internal _maxTokenId;

    /// @dev Current total supply (set to _maxTokenId on init)
    uint256 internal _totalSupply;

    /// @notice The account where tokens are preminted to
    address public minter;

    /// @dev Keep track of burned token IDs
    mapping(uint256 => bool) internal _burnedTokenIds;

    /* EIP-2309 EVENTS ----------------------------------------------------- */

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    /**
     * @dev Initializes the contract
     * @param name_ The ERC-721 name of the contract
     * @param symbol_ The ERC-721 symbol of the contract
     * @param premintTo_ Account to premint the total supply to
     * @param maxSupply_ The max supply of tokens to premint
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address premintTo_,
        uint256 maxSupply_
    ) ERC721(name_, symbol_) {
        minter = premintTo_;
        _maxTokenId = maxSupply_;
        _totalSupply = maxSupply_;

        // Premit tokens to owner
        _balanceOf[premintTo_] = maxSupply_;
        emit ConsecutiveTransfer(1, maxSupply_, address(0), premintTo_);
    }

    /**
     * @return totalSupply The current total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev {ERC721-ownerOf}.
     * - Reverts if non-existent token.
     * - Falls back to the premint account if the token has never been transferred for
     *   gas efficient preminting.
     * @param id The token id to query
     * @return owner The owner of the token id
     */
    function ownerOf(uint256 id) public view override returns (address) {
        // Token id must be within range
        require(id > 0 && id <= _maxTokenId, "NOT_MINTED");
        // Token id must not be burned
        require(!_burnedTokenIds[id], "NOT_MINTED");

        address owner = _ownerOf[id];
        return owner == address(0) ? minter : owner;
    }

    /**
     * @dev Gives permission to `spender` to transfer `id` token to another account.
     * The approval is cleared when the token is transferred. Only a single account can be
     * approved at a time, so approving the zero address clears previous approvals.
     * Reverts if the caller is not the owner or is not an approved operator for the owner.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 id) public override {
        address owner = ownerOf(id);
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    /**
     * @dev Transfers `id` token from `from` to `to`. Clears `approved` on successful transfer.
     * Reverts if:
     * - `from` is not the current owner
     * - `to` is not the zero address
     * - the caller is not `from` or approved via {getApproved} or {isApprovedForAll}.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == ownerOf(id), "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
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

    /**
     * @dev Burns `id` token. Clears ownership data and {getApproved}. Reduces {totalSupply}
     * by one. Reverts if id is out of range or it's already been burned.
     * Emits a {Transfer} event.
     */
    function _burn(uint256 id) internal override {
        address owner = ownerOf(id);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
            _totalSupply--;
        }

        _ownerOf[id] = address(0);
        _burnedTokenIds[id] = true;

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./BatchedReleaseExtension.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Batched release operator extension
 * @notice Allows tokens to be released in equal sized batches. To be used by contracts that use
 * the operator pattern for collecting tokens e.g. a separate contract handles collecting tokens.
 */
abstract contract BatchedReleaseOperatorExtension is BatchedReleaseExtension {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /**
     * @notice Contracts that have approval to operate for a given batch
     * @dev Batch number => operator contract address
     */
    mapping(uint256 => address) public operatorForBatch;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error NotOperatorForBatch();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When an operator is set for a batch
     * @param batch The batch number that an operator was set for
     * @param operator The operator address for the batch
     */
    event BatchOperatorSet(uint256 indexed batch, address indexed operator);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Modifier that only allows the operator for the currently active batch
     */
    modifier onlyWhenOperatorForActiveBatch() {
        if (operatorForBatch[activeBatch] != msg.sender) revert NotOperatorForBatch();
        _;
    }

    /**
     * @dev Modifier that only allows the operator for a specific batch
     */
    modifier onlyWhenOperatorForBatch(uint256 batch) {
        if (operatorForBatch[batch] != msg.sender) revert NotOperatorForBatch();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */
    /**
     * @param totalTokens The total number of tokens to be released
     * @param batchSize The number of equal batches to be released
     */
    constructor(uint256 totalTokens, uint256 batchSize)
        BatchedReleaseExtension(totalTokens, batchSize)
    {}

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Adds an operator for a specific batch
     * @dev Allows the use of the `onlyOperatorForBatch()` modifier.
     * Reverts if the batch isn't between 1-`_numOfBatches`.
     * @param batch The batch to set the operator for
     * @param operator The operator contract that get's approval to all the minters tokens
     */
    function _setBatchOperator(uint256 batch, address operator) internal {
        if (batch > (_totalTokens / _batchSize) || batch < 1) revert InvalidBatch();
        operatorForBatch[batch] = operator;
        emit BatchOperatorSet(batch, operator);
    }

    /**
     * @dev Force implementation of `setBatchOperator`.
     * Can be overriden to pre-approve token transfers using `isApprovedForAll` for example.
     */
    function setBatchOperator(uint256 batch, address operator) public virtual;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Swappable metadata module
 * @notice Allows the use of a separate and swappable metadata contract
 */
abstract contract SwappableMetadata {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Address of metadata contract
    address public metadata;

    /// @notice Flag for whether the metadata address can be updated or not
    bool public isMetadataLocked;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error MetadataLocked();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When the metadata contract has been set
     * @param metadataContract The new metadata contract address
     */
    event MetadataContractSet(address indexed metadataContract);

    /**
     * @dev When the metadata contract has been locked and is no longer swappable
     * @param metadataContract The final locked metadata contract address
     */
    event MetadataContractLocked(address indexed metadataContract);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param metadata_ The address of the initial metadata contract
     */
    constructor(address metadata_) {
        metadata = metadata_;
        emit MetadataContractSet(metadata_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Sets the metadata address
     * @param metadata_ The new address of the metadata contract
     */
    function _setMetadataAddress(address metadata_) internal {
        if (isMetadataLocked) revert MetadataLocked();
        metadata = metadata_;
        emit MetadataContractSet(metadata_);
    }

    /**
     * @notice Sets the metadata address
     * @param metadata The new address of the metadata contract
     */
    function setMetadataAddress(address metadata) public virtual;

    /**
     * @dev Locks the metadata address preventing further updates
     */
    function _lockMetadata() internal {
        isMetadataLocked = true;
        emit MetadataContractLocked(metadata);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/interfaces/IERC2981.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Royalty payments
 * @notice Support for the royalty standard (ERC-2981)
 */
abstract contract Royalties is IERC2981 {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Store information about token royalties
    struct RoyaltyInfo {
        address receiver;
        uint96 amount;
    }

    /// @dev The current royalty information
    RoyaltyInfo private _royaltyInfo;

    /// @dev Interface id for the royalty information standard
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 internal constant ROYALTY_INTERFACE_ID = 0x2a55205a;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error MoreThanOneHundredPercentRoyalty();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event RoyaltyInfoSet(address indexed receiver, uint256 indexed amount);
    event RoyaltyInfoUpdated(address indexed receiver, uint256 indexed amount);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param royaltiesReceiver The receiver of royalty payments
     * @param royaltiesAmount The royalty percentage with two decimals (10,000 = 100%)
     */
    constructor(address royaltiesReceiver, uint256 royaltiesAmount) {
        _royaltyInfo = RoyaltyInfo(royaltiesReceiver, uint96(royaltiesAmount));
        emit RoyaltyInfoSet(royaltiesReceiver, royaltiesAmount);
    }

    /* ------------------------------------------------------------------------
                                  E R C 2 9 8 1
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 100_00;
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @dev Internal function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function _setRoyaltyInfo(address receiver, uint256 amount) internal {
        if (amount > 100_00) revert MoreThanOneHundredPercentRoyalty();
        _royaltyInfo = RoyaltyInfo(receiver, uint24(amount));
        emit RoyaltyInfoUpdated(receiver, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IOperatorCollectable {
    function collect(uint256 id, address to) external;

    function markAsCollected(uint256 id) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Batched release extension
 * @notice Allows tokens to be released in equal sized batches
 */
abstract contract BatchedReleaseExtension {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    uint256 internal _totalTokens;
    uint256 internal _batchSize;

    /// @dev Tracker for the collected amount count. Init to 1 to save gas on updating
    uint256 internal _collectedCount = 1;

    /// @dev Tracker for collected token ids to prevent collecting the same token more than once
    mapping(uint256 => bool) internal _collectedTokenIds;

    /**
     * @notice The current active batch number
     * @dev Batch numbers are 0-`_batchSize` where 0 is "off"
     */
    uint256 public activeBatch;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error InvalidBatch();
    error NotActiveBatch();
    error TokenNotInBatch();
    error TokenNotInActiveBatch();
    error CannotGoToNextBatch();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When the current active batch is updated
     * @param batch The batch number that is now active
     * @param forced If the batch was forcefully set by an admin
     */
    event ActiveBatchSet(uint256 indexed batch, bool forced);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Modifier that reverts if the batch specified is not active
     */
    modifier onlyWhenActiveBatchIs(uint256 batch) {
        if (activeBatch != batch) revert NotActiveBatch();
        _;
    }

    /**
     * @dev Modifier that reverts if the token is not in the specified batch
     */
    modifier onlyWhenTokenIsInBatch(uint256 id, uint256 batch) {
        if (_getBatchFromId(id) != batch) revert TokenNotInBatch();
        _;
    }

    /**
     * @dev Modifier that reverts if the token is not in the active batch
     */
    modifier onlyWhenTokenIsInActiveBatch(uint256 id) {
        if (_getBatchFromId(id) != activeBatch) revert TokenNotInActiveBatch();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Requires `totalTokens` to be divisible by `batchSize` othewise you will
     * not be able to move to the final batch, for example:
     * If `totalTokens` = 12 and `batchSize` = 5 then tokens 11 and 12 will never be reachable.
     * This is because the function to move to the next batch calculates the total number of
     * batches, in this case there would be 2 batches. 12/5 = 2.4 which gets rounded down to 2.
     * You will not be able to move to batch 3 to collect tokens 11 and 12.
     *
     * @param totalTokens The total number of tokens to be released
     * @param batchSize The size of an individual batch
     */
    constructor(uint256 totalTokens, uint256 batchSize) {
        _totalTokens = totalTokens;
        _batchSize = batchSize;
    }

    /* ------------------------------------------------------------------------
                            C O L L E C T   T O K E N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Mark a specific token as collected and increment the count of tokens collected
     * @dev This enables moving to the next batch once the threshold has been hit. To prevent
     * ids being collected more than once, you'll have to add your own checks when collecting.
     * @param id The token id that was collected
     */
    function _collectToken(uint256 id) internal {
        _collectedTokenIds[id] = true;

        unchecked {
            _collectedCount++;
        }
    }

    /**
     * @notice Mark specific tokens as collected and increment the count of tokens collected
     * @dev This enables moving to the next batch once the threshold has been hit. To prevent
     * ids being collected more than once, you'll have to add your own checks when collecting.
     * @param ids The token ids that were collected
     */
    function _collectTokens(uint256[] calldata ids) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            _collectedTokenIds[ids[i]] = true;
        }

        unchecked {
            _collectedCount += ids.length;
        }
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Advances the active batch based on the number of tokens sold in the current batch
     * @dev Reverts if the current batch hasn't sold out yet.
     */
    function _goToNextBatch() internal {
        uint256 nextBatch = (totalCollected() / _batchSize) + 1;

        // Check if the batch can be advanced
        if (activeBatch >= nextBatch || nextBatch > (_totalTokens / _batchSize)) {
            revert CannotGoToNextBatch();
        }

        // Increment to go to the next batch
        unchecked {
            ++activeBatch;
        }

        // Emit a batch updated event
        emit ActiveBatchSet(activeBatch, false);
    }

    /// @dev Force implementation of `goToNextBatch`
    function goToNextBatch() public virtual;

    /**
     * @notice Admin function to force the active batch
     * @dev Bypasses checking if an entire batch is sold out. To be used in situations
     * where the state needs to be fixed for whatever reason. Can be set to zero to
     * effectively pause any sales relying on the current batch being set.
     * @param batch The batch number to activate
     */
    function _forcefullySetBatch(uint256 batch) internal {
        // Limit the batch number to only be in the valid range.
        // 0 is valid which would effectively pause any sales.
        if (batch > (_totalTokens / _batchSize)) revert InvalidBatch();

        // Set the active branch to the one specified
        activeBatch = batch;

        // Emit a batch updated event
        emit ActiveBatchSet(activeBatch, true);
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the total number of tokens collected
     * @return count The number of tokens collected
     */
    function totalCollected() public view virtual returns (uint256) {
        // Subtract the 1 that `_collectedCount` was initialised with
        return _collectedCount - 1;
    }

    // Get the batch from the non-zero-indexed token id
    function _getBatchFromId(uint256 id) internal view returns (uint256) {
        if (id == 0 || id > _totalTokens) return 0;
        return ((id - 1) / _batchSize) + 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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