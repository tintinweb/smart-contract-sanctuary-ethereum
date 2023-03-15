/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/IERC1155.sol


pragma solidity ^0.8.18;

    /**
        @title ERC-1155 Multi Token Standard
        @dev See https://eips.ethereum.org/EIPS/eip-1155
        Note: The ERC-165 identifier for this interface is 0xd9b67a26.
    */
    interface IERC1155 /* is ERC165 */ {

    /**
    * The max supply value is above the storage limit (2^64 -1).
    */
    error MaxSupplyValueAboveLimit();

    /**
    * Function parameters lengths mismatch.
    */
    error ParamsLengthsMismatch();

    /**
    * The token does not exist.
    */
    error MaxSupplyChangeForNonexistentToken();

    /**
    * Cannot query the balance for the zero address.
    */
    error BalanceQueryForZeroAddress();

    /**
    * Cannot mint to the zero address.
    */
    error MintToZeroAddress();

    /**
    * The quantity of tokens minted must be more than zero.
    */
    error MintZeroQuantity();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC1155TokenReceiver interface.
     */
    error TransferToNonERC1155TokenReceiverImplementer();

    /**
     * Tokens rejected by the remote ERC1155TokenReceiver
     * implementer contract.
     */
    error ERC1155TokenReceiverRejectedTokens();

    /**
     * Insufficient balance.
     */
    error InsufficientBalance();

    /**
     * Mint amount added to current supply exceed max supply.
     */
    error MintAmountExceedsMaxSupply();

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `from` argument MUST be the address of the holder whose balance is decreased.
        The `to` argument MUST be the address of the recipient whose balance is increased.
        The `id` argument MUST be the token type being transferred.
        The `amount` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `from` argument MUST be the address of the holder whose balance is decreased.
        The `to` argument MUST be the address of the recipient whose balance is increased.
        The `ids` argument MUST be the list of tokens being transferred.
        The `amounts` argument MUST be the list of number of tokens (matching the list and order of tokens specified in ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string value, uint256 indexed id);


    /**
        @notice Transfers `amount` amount of an `id` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `amount` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param amount   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external payable;

    /**
        @notice Transfers `amounts` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `amounts`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `amounts` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (ids[0]/amounts[0] before ids[1]/amounts[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match amounts array)
        @param amounts  Transfer amounts per token type (order and length must match ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external payable;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external payable;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

    // ==================================================================
    //                        IERC1155MetadataURI
    //   Note: The ERC-165 identifier for this interface is 0x0e89341c.
    // ==================================================================

    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 id) external view returns (string memory);

}


// File contracts/ERC1155.sol

// ERC1155 Contracts v1.0.0
// Creator: Victor SOUBEYRAN

pragma solidity ^0.8.18;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match values array)
        @param values    An array containing amounts of each token being transferred (order and length must match ids array)
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);       
}

/**
 * @title ERC1155
 *
 * @dev Implementation of the [ERC1155](https://eips.ethereum.org/EIPS/eip-1155)
 * Multi Token Standard, including the MetadataURI extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC1155 is IERC1155 {

    // =============================================================
    //                           EVENTS
    // =============================================================

    /**
        @dev MUST emit when the ownership of the contract is transfered.
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data and token metadata.
    address internal constant _ADDRESS_ZERO = 0x0000000000000000000000000000000000000000;

    // Mask of an entry in packed address data and token metadata.
    uint256 internal constant _BITMASK_DATA_ENTRY = (1 << 64) - 1;

    // Mask of all 256 bits in packed address data except the 64 bits for `maxSupply`.
    uint256 internal constant _BITMASK_MAX_SUPPLY_COMPLEMENT = ~uint256(0) ^ _BITMASK_DATA_ENTRY;

    // The bit position of `numberMinted` in packed address data.
    uint256 internal constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 internal constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 internal constant _BITPOS_AUX = 192;

    // // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    // uint256 internal constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // // The `TransferSingle` event signature is given by:
    // // `keccak256(bytes("TransferSingle(address,address,address,uint256,uint256)"))`.
    // bytes32 private constant _TRANSFER_SINGLE_EVENT_SIGNATURE =
    //     0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;

    // // The `TransferBatch` event signature is given by:
    // // `keccak256(bytes("TransferBatch(address,address,address,uint256[],uint256[])"))`.
    // bytes32 private constant _TRANSFER_BATCH_EVENT_SIGNATURE =
    //     0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;

    // // The `ApprovalForAll` event signature is given by:
    // // `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    // bytes32 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
    //     0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    // // The `URI` event signature is given by:
    // // `keccak256(bytes("URI(string,uint256)"))`.
    // bytes32 private constant _URI_EVENT_SIGNATURE =
    //     0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Token URIs
    string internal _uri;

    // The next token ID to be minted.
    uint256 internal _currentIndex = 1;

    // Mapping from token ID to metadata
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..63]    `maxSupply`
    // - [64..127]  `minted`
    // - [128..191] `burned`
    // - [192..255] `aux`
    mapping(uint256 => uint256) internal _packedTokenMetadata;

    // Mapping owner address to address data mapped by tokenId.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => mapping(uint256 => uint256)) internal _packedAddressData;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    address internal _contractOwner;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "Must be contract owner");
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory uri_, uint256 maxSupplyFirstToken) {
        _contractOwner = msg.sender;
        _uri = uri_;
        if (maxSupplyFirstToken > _BITMASK_DATA_ENTRY) _revert(MaxSupplyValueAboveLimit.selector);
        _packedTokenMetadata[0] = maxSupplyFirstToken & _BITMASK_DATA_ENTRY;
        emit TransferSingle(msg.sender, _ADDRESS_ZERO, _ADDRESS_ZERO, 0, 0);
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {totalMinted}.
     */
    function totalSupply(uint256 tokenId) external view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex` times.
        unchecked {
            uint256 packedMetadata = _packedTokenMetadata[tokenId];
            return  ((packedMetadata >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY) - ((packedMetadata >> _BITPOS_NUMBER_BURNED) & _BITMASK_DATA_ENTRY);
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted(uint256 tokenId) external view virtual returns (uint256) {
        return (_packedTokenMetadata[tokenId] >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY;
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function totalBurned(uint256 tokenId) external view virtual returns (uint256) {
        return (_packedTokenMetadata[tokenId] >> _BITPOS_NUMBER_BURNED) & _BITMASK_DATA_ENTRY;
    }

    // =============================================================
    //                    TOKEN OPERATIONS
    // =============================================================

    /**
     * @dev Create new token.
     */
    function createToken(uint256 maxSupply, bool mint) external payable virtual onlyOwner returns (uint256) {
        if (maxSupply > _BITMASK_DATA_ENTRY) _revert(MaxSupplyValueAboveLimit.selector);
        uint256 idx = _currentIndex;
        if (mint == true) {
            uint256 dataToStore = (maxSupply & _BITMASK_DATA_ENTRY) + (maxSupply << _BITPOS_NUMBER_MINTED);
            _packedAddressData[msg.sender][idx] = dataToStore;
            _packedTokenMetadata[idx] = dataToStore;
            emit TransferSingle(msg.sender, _ADDRESS_ZERO, msg.sender, idx, maxSupply);
        }
        else {
            _packedTokenMetadata[idx] = maxSupply & _BITMASK_DATA_ENTRY;
            emit TransferSingle(msg.sender, _ADDRESS_ZERO, _ADDRESS_ZERO, idx, 0);
        }
        unchecked {
            ++_currentIndex;
        }
        return idx;
    }

    function setMaxSupply(uint256 tokenId, uint256 maxSupply) external payable virtual onlyOwner {
        if (maxSupply > _BITMASK_DATA_ENTRY) _revert(MaxSupplyValueAboveLimit.selector);
        if (tokenId < _currentIndex) {
            _packedTokenMetadata[tokenId] = (_packedTokenMetadata[tokenId] & _BITMASK_MAX_SUPPLY_COMPLEMENT) | maxSupply; 

        } else {
            _revert(MaxSupplyChangeForNonexistentToken.selector);
        }
    }

    function getMaxSupply(uint256 tokenId) external view virtual returns (uint256) {
        return _packedTokenMetadata[tokenId] & _BITMASK_DATA_ENTRY;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    function balanceOf(address owner, uint256 tokenId) external view returns (uint256) {
        if (owner == _ADDRESS_ZERO) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner][tokenId] & _BITMASK_DATA_ENTRY;
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata tokenIds) external view returns (uint256[] memory balances) {
        if (owners.length != tokenIds.length) _revert(ParamsLengthsMismatch.selector);
        
        balances = new uint256[](owners.length);
        uint256 length = owners.length;
        for (uint256 i = 0; i < length; ++i) {
            if (owners[i] == _ADDRESS_ZERO) _revert(BalanceQueryForZeroAddress.selector);
            balances[i] = _packedAddressData[owners[i]][tokenIds[i]] & _BITMASK_DATA_ENTRY;
        }
        return balances;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function numberMinted(address owner, uint256 tokenId) public view returns (uint256) {
        return (_packedAddressData[owner][tokenId] >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function numberBurned(address owner, uint256 tokenId) public view returns (uint256) {
        return (_packedAddressData[owner][tokenId] >> _BITPOS_NUMBER_BURNED) & _BITMASK_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner, uint256 tokenId) internal view returns (uint64) {
        return uint64(_packedAddressData[owner][tokenId] >> _BITPOS_AUX);
    }

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x4e2312e0 || // ERC165 interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 interface ID for ERC1155MetadataURI.
    }

    // =============================================================
    //                        IERC1155MetadataURI
    // =============================================================

    /**
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 id) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
    */
    function setUri(uint256 id, string calldata uri_) external payable virtual onlyOwner {
        _uri = uri_;
        emit URI(uri_, 0);
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external payable virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external payable {
        if (to == _ADDRESS_ZERO) _revert(TransferToZeroAddress.selector);
        
        if (from != msg.sender) {
            if (_operatorApprovals[from][msg.sender] == false) {
                _revert(TransferCallerNotOwnerNorApproved.selector);
            }
        }

        uint256 fromAddressData = _packedAddressData[from][id];
        if ((fromAddressData & _BITMASK_DATA_ENTRY) < amount) _revert(InsufficientBalance.selector);

        unchecked {
            _packedAddressData[from][id] = fromAddressData - amount;
            _packedAddressData[to][id] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (isContract(to)) {
            _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
        }
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external payable {
        if (to == _ADDRESS_ZERO) _revert(TransferToZeroAddress.selector);
        if (ids.length != amounts.length) _revert(ParamsLengthsMismatch.selector);
        if (from != msg.sender) {
            if (_operatorApprovals[from][msg.sender] == false) {
                _revert(TransferCallerNotOwnerNorApproved.selector);
            }
        }

        uint256 id;
        uint256 amount;
        uint256 fromAddressData;
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ++i) {
            id = ids[i];
            amount = amounts[i];
            fromAddressData = _packedAddressData[from][id];

            if ((fromAddressData & _BITMASK_DATA_ENTRY) < amount) _revert(InsufficientBalance.selector);

            unchecked {
                _packedAddressData[from][id] = fromAddressData - amount;
                _packedAddressData[to][id] += amount;
            }
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (isContract(to)) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
        }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155TokenReceiver.onERC1155Received.selector) {
                    _revert(ERC1155TokenReceiverRejectedTokens.selector);
                }
            } 
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    _revert(TransferToNonERC1155TokenReceiverImplementer.selector);
                }
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155TokenReceiver.onERC1155BatchReceived.selector) {
                    _revert(ERC1155TokenReceiverRejectedTokens.selector);
                }
            } 
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    _revert(TransferToNonERC1155TokenReceiverImplementer.selector);
                }
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }            
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if (to == _ADDRESS_ZERO) _revert(MintToZeroAddress.selector);
        uint256 packedMetadata = _packedTokenMetadata[id];
        if ((((packedMetadata >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY) + amount) > (packedMetadata & _BITMASK_DATA_ENTRY)) {
            _revert(MintAmountExceedsMaxSupply.selector);
        }

        unchecked {
            _packedAddressData[to][id] += amount + (amount << _BITPOS_NUMBER_MINTED);
            _packedTokenMetadata[id] = packedMetadata + (amount << _BITPOS_NUMBER_MINTED);
        }
        emit TransferSingle(msg.sender, _ADDRESS_ZERO, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, _ADDRESS_ZERO, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155TokenReceiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == _ADDRESS_ZERO) _revert(MintToZeroAddress.selector);
        if (ids.length != amounts.length) _revert(ParamsLengthsMismatch.selector);

        uint256 id;
        uint256 amount;
        uint256 packedMetadata;
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ++i) {
            id = ids[i];
            amount = amounts[i];
            packedMetadata = _packedTokenMetadata[id];
            if ((((packedMetadata >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY) + amount) > (packedMetadata & _BITMASK_DATA_ENTRY)) {
                _revert(MintAmountExceedsMaxSupply.selector);
            }

            unchecked {
                _packedAddressData[to][id] += amount + (amount << _BITPOS_NUMBER_MINTED);
                _packedTokenMetadata[id] = packedMetadata + (amount << _BITPOS_NUMBER_MINTED);
            }
        }

        emit TransferBatch(msg.sender, _ADDRESS_ZERO, to, ids, amounts);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     */
    function _safeMint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _mint(to, id, amount, data);

        uint256 currentNumberMinted = (_packedTokenMetadata[id] >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY;
        _doSafeTransferAcceptanceCheck(msg.sender, _ADDRESS_ZERO, to, id, amount, data);
        if (((_packedTokenMetadata[id] >> _BITPOS_NUMBER_MINTED) & _BITMASK_DATA_ENTRY) != currentNumberMinted) _revert(bytes4(0));

    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     */
    function _safeMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, _ADDRESS_ZERO, to, ids, amounts, data);
    }


    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(address from, uint256 id, uint256 amount, bool approvalCheck) internal virtual {
        if (approvalCheck == true) {
            if (from != msg.sender) {
                if (_operatorApprovals[from][msg.sender] == false) {
                    _revert(TransferCallerNotOwnerNorApproved.selector);
                }
            }
        }

        uint256 fromAddressData = _packedAddressData[from][id];
        if ((fromAddressData & _BITMASK_DATA_ENTRY) < amount) _revert(InsufficientBalance.selector);

        unchecked {
            _packedAddressData[from][id] = fromAddressData - amount + (amount << _BITPOS_NUMBER_BURNED);
            _packedTokenMetadata[id] += (amount << _BITPOS_NUMBER_BURNED);
        }

        emit TransferSingle(msg.sender, from, _ADDRESS_ZERO, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts, bool approvalCheck) internal virtual {
        if (ids.length != amounts.length) _revert(ParamsLengthsMismatch.selector);
        if (approvalCheck == true) {
            if (from != msg.sender) {
                if (_operatorApprovals[from][msg.sender] == false) {
                    _revert(TransferCallerNotOwnerNorApproved.selector);
                }
            }
        }

        uint256 id;
        uint256 amount;
        uint256 fromAddressData;
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ++i) {
            id = ids[i];
            amount = amounts[i];
            fromAddressData = _packedAddressData[from][id];

            if ((fromAddressData & _BITMASK_DATA_ENTRY) < amount) _revert(InsufficientBalance.selector);

            unchecked {
                _packedAddressData[from][id] = fromAddressData - amount + (amount << _BITPOS_NUMBER_BURNED);
                _packedTokenMetadata[id] += (amount << _BITPOS_NUMBER_BURNED);
            }            
        }

        // MUST emit event
        emit TransferBatch(msg.sender, from, _ADDRESS_ZERO, ids, amounts);
    }

    // =============================================================
    //                       CONTRACT OWNER OPERATIONS
    // =============================================================

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(_contractOwner).call{value: address(this).balance}("");
        require(os);
    }

    function transferOwnership(address newOwner) external payable onlyOwner {
        require(newOwner != _ADDRESS_ZERO, "New owner is the zero address");
        address oldOwner = _contractOwner;
        _contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    function isContract(address _contract) internal view returns (bool) {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        return contractSize > 0;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

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

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}


// File contracts/MULTINFT_METAVERSE_NIGHTS.sol

// Updated to start tokenId from 1

pragma solidity ^0.8.18;

contract MULTINFT_METAVERSE_NIGHTS is ERC1155 {

    // =============================================================
    //                           ERRORS
    // =============================================================

    error NoUndergoinSpecialSale();

    error MintDisabled();

    error NotEnoughEtherForMinting();

    error MintLimitByUserReached();

    event SpecialSaleClaim(address from, uint8 amount, uint8 saleId);


    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of `price` in packed collection metadata.
    uint256 internal constant _BITMASK_PRICE_ENTRY = (1 << 184) - 1;

    // Mask of all 256 bits in packed address data except the 184 bits for `price`.
    uint256 internal constant _BITMASK_PRICE_COMPLEMENT = ~uint256(0) ^ _BITMASK_PRICE_ENTRY;

    // Mask of `userMintLimit` in packed collection metadata.
    uint256 internal constant _BITMASK_USER_MINT_LIMIT_ENTRY = (1 << 64) - 1;

    // Mask of all 256 bits in packed address data except the 64 bits for `userMintLimit`.
    uint256 internal constant _BITMASK_USER_MINT_LIMIT_COMPLEMENT = ~uint256(0) ^ (_BITMASK_USER_MINT_LIMIT_ENTRY << 184);

    // The bit position of `userMintLimit` in packed address data.
    uint256 internal constant _BITPOS_USER_MINT_LIMIT = 184;

    // Mask of `state` in packed collection metadata.
    uint256 internal constant _BITMASK_STATE_ENTRY = (1 << 8) - 1;

    // Mask of all 256 bits in a packed ownership except the 8 bits for `state`.
    uint256 private constant _BITMASK_STATE_COMPLEMENT = (1 << 248) - 1;

    // The bit position of `state` in packed address data.
    uint256 internal constant _BITPOS_STATE = 248;

    // =============================================================
    //                           STORAGE
    // =============================================================

    // Bits Layout:
    // - [0..183]       `price`
    // - [184..247]     `userMintLimit`
    // - [248..255]     `state`
    mapping (uint256 => uint256) private _packedCollectionData; // 0: paused, 1: standard mint, >= 2: special sales

    string public constant name = "Metaverse Nights";

    constructor()
        ERC1155("https://multinft.mypinata.cloud/ipfs/QmVf5RGzQsS3ES4yhLFSpSjWRbpBgJZmWDxYQVUhhYpgHW/{id}.json", 700)
    {
        _packedCollectionData[0] = (0.05 ether) + (10 << _BITPOS_USER_MINT_LIMIT);
    }

    /** 
    @notice Handle specials sales behavior (_state >= 2)
    @param amount Amount to mint.
     */
    function specialSale(uint256 tokenId, uint256 amount) external payable {
        uint256 packedData = _packedCollectionData[tokenId];
        if (((packedData >> _BITPOS_STATE) & _BITMASK_STATE_ENTRY) < 2) _revert(NoUndergoinSpecialSale.selector);
        if (msg.value < (amount * (packedData & _BITMASK_PRICE_ENTRY))) _revert(NotEnoughEtherForMinting.selector);
        if (numberMinted(msg.sender, tokenId) + amount > ((packedData >> _BITPOS_USER_MINT_LIMIT) & _BITMASK_USER_MINT_LIMIT_ENTRY)) _revert(MintLimitByUserReached.selector);
        emit SpecialSaleClaim(msg.sender, uint8(amount), uint8(packedData >> _BITPOS_STATE));
    }

    /** 
    @notice Mint {amount} for recipient account
    @param recipient Recipient account's address.
    @param amount Amount to mint.
     */
    function mintForAddress(address recipient, uint256 tokenId, uint256 amount) external payable onlyOwner {
        _mint(recipient, tokenId, amount, '');
    }

    /** 
    @notice Mint {amount}
    @param amount Amount to mint.
     */
    function mint(uint256 tokenId, uint256 amount) external payable {
        uint256 packedData = _packedCollectionData[tokenId];
        if ((packedData >> _BITPOS_STATE) != 1) _revert(MintDisabled.selector);
        if (numberMinted(msg.sender, tokenId) + amount > ((packedData >> _BITPOS_USER_MINT_LIMIT) & _BITMASK_USER_MINT_LIMIT_ENTRY)) _revert(MintLimitByUserReached.selector);
        if (msg.value < (amount * (packedData & _BITMASK_PRICE_ENTRY))) _revert(NotEnoughEtherForMinting.selector);
        if (!isContract(msg.sender)) {
            _mint(msg.sender, tokenId, amount, '');
        }
        else {
            _safeMint(msg.sender, tokenId, amount, '');
        }
    }

    function setState(uint256 tokenId, uint256 state_) external payable onlyOwner {
        _packedCollectionData[tokenId] = (_packedCollectionData[tokenId] & _BITMASK_STATE_COMPLEMENT) | ((state_ & _BITMASK_STATE_ENTRY) << _BITPOS_STATE);
    }

    function getState(uint256 tokenId) external view returns (uint256) {
        return (_packedCollectionData[tokenId] >> _BITPOS_STATE) & _BITMASK_STATE_ENTRY;
    }

    function setPrice(uint256 tokenId, uint256 price_) external payable onlyOwner {
        _packedCollectionData[tokenId] = (_packedCollectionData[tokenId] & _BITMASK_PRICE_COMPLEMENT) | (price_ & _BITMASK_PRICE_ENTRY);
    }

    function getPrice(uint256 tokenId) external view returns (uint256) {
        return _packedCollectionData[tokenId] & _BITMASK_PRICE_ENTRY;
    }

    function setUserMintLimit(uint256 tokenId, uint256 userMintLimit_) external payable onlyOwner {
        _packedCollectionData[tokenId] = (_packedCollectionData[tokenId] & _BITMASK_USER_MINT_LIMIT_COMPLEMENT) | ((userMintLimit_ & _BITMASK_USER_MINT_LIMIT_ENTRY) << _BITPOS_USER_MINT_LIMIT);
    }

    function getUserMintLimit(uint256 tokenId) external view returns (uint256) {
        return (_packedCollectionData[tokenId] >> _BITPOS_USER_MINT_LIMIT) & _BITMASK_USER_MINT_LIMIT_ENTRY;
    }

    receive() external payable {}

    fallback (bytes calldata _input) external payable returns (bytes memory _output) {}
}