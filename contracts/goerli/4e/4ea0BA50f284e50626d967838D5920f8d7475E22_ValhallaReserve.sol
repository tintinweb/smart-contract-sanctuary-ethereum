// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./token/ERC1155/ERC1155.sol";
import "./utils/ERC2981.sol";
import "./utils/IERC165.sol";
import "./utils/Ownable.sol";
import "./utils/ECDSA.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ██╗░░░██╗░█████╗░██╗░░░░░██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░    //
//    ██║░░░██║██╔══██╗██║░░░░░██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗    //
//    ╚██╗░██╔╝███████║██║░░░░░███████║███████║██║░░░░░██║░░░░░███████║    //
//    ░╚████╔╝░██╔══██║██║░░░░░██╔══██║██╔══██║██║░░░░░██║░░░░░██╔══██║    //
//    ░░╚██╔╝░░██║░░██║███████╗██║░░██║██║░░██║███████╗███████╗██║░░██║    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract ValhallaReserve is ERC1155, Ownable, ERC2981 {
    using ECDSA for bytes32;

    // =============================================================
    //                            STRUCTS
    // =============================================================

    // Compiler will pack this into a 256bit word.
    struct SaleData {
        // unitPrice for each token for the general sale
        uint96 price;
        // Optional value to prevent a transaction from buying too much supply
        uint64 txLimit;
        // startTime for the sale of the tokens
        uint48 startTimestamp;
        // endTime for the sale of the tokens
        uint48 endTimestamp;
    }

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators.
    address public filterRegistrant;

    // Address used for the mintSignature method
    address public signer;
    // Used to quickly invalidate batches of signatures if needed.
    uint256 public signatureVersion;
    // Mapping that shows if a tier is active or not
    mapping(uint256 => mapping(string => bool)) public isTierActive;
    mapping(bytes32 => bool) public signatureUsed;
    
    // For tokens that are open to a general sale.
    mapping(uint256 => SaleData) public generalSaleData;

    // Mapping of owner-approved contracts that can burn the user's tokens during a transaction
    mapping(address => mapping(uint256 => bool)) public approvedBurners;

    // =============================================================
    //                            Events
    // =============================================================

    event MintOpen(
        uint256 indexed tokenId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 price,
        uint256 txLimit
    );
    event MintClosed(uint256 indexed tokenId);

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor () {
        _setName("ValhallaReserve");
        _setSymbol("RSRV");
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows the owner to set a new name for the collection.
     */
    function setName(string memory name) external onlyOwner {
        _setName(name);
    }

    /**
     * @dev Allows the owner to set a new symbol for the collection.
     */
    function setSymbol(string memory symbol) external onlyOwner {
        _setSymbol(symbol);
    }

    /**
     * @dev Allows the owner to add a new tokenId if it does not already exist.
     * 
     * @param tokenId TokenId that will get created
     * @param tokenMintLimit Token Supply for the tokenId. If 0, the supply is capped at uint64 max.
     * @param uri link pointing to the token metadata
     */
    function addTokenId(uint256 tokenId, uint64 tokenMintLimit, string calldata uri) external onlyOwner {
        _addTokenId(tokenId, tokenMintLimit, uri);
    }

    /**
     * @dev Allows the owner to set a new token URI for a single tokenId.
     * 
     * This tokenId must have already been added by `addTokenId`
     */
    function updateTokenURI(uint256 tokenId, string calldata uri) external onlyOwner {
        _updateMetadata(tokenId, uri);
    }

    /**
     * @dev Token supply can be set, but can ONLY BE LOWERED. It also cannot be lower than the current supply.
     *
     * This logic is gauranteed by the {_setTokenMintLimit} method
     */
    function setTokenMintLimit(uint256 tokenId, uint64 tokenMintLimit) external onlyOwner {
        _setTokenMintLimit(tokenId, tokenMintLimit);
    }
 
    // =============================================================
    //                           IERC2981
    // =============================================================

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                 Operator Filter Registry
    // =============================================================

    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        filterRegistrant = newRegistrant;
    }

    // =============================================================
    //                        Token Minting
    // =============================================================

    /**
     * @dev This function does a best effort to Owner mint. If a given tokenId is
     * over the token supply amount, it will mint as many are available and stop at the limit.
     * This is necessary so that a given transaction does not fail if another public mint
     * transaction happens to take place just before this one that would cause the amount of
     * minted tokens to go over a token limit.
     */
    function mintDev(
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (
            receivers.length != tokenIds.length ||
            receivers.length != amounts.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < receivers.length; ) {
            uint256 buyLimit = _remainingSupply(tokenIds[i]);

            if (buyLimit != 0) {
                if (amounts[i] > buyLimit) {
                    _mint(receivers[i], tokenIds[i], buyLimit, "");
                } else {
                    _mint(receivers[i], tokenIds[i], amounts[i], "");
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSignatureVersion(uint256 version) external onlyOwner {
        signatureVersion = version;
    }

    /**
     * @notice Allows owner to sets if a certain tier is active or not.
     */
    function setIsTierActive(
        uint256 tokenId,
        string memory tier,
        bool active
    ) external onlyOwner {
        isTierActive[tokenId][tier] = active;
    }
    
    /**
     * @dev With the correct hash signed by the owner, a wallet can mint at
     * a unit price up to the quantity specified.
     */
    function mintSignature(
        string memory tier,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256 buyAmount,
        bytes memory sig
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (!isTierActive[tokenId][tier]) revert TierNotActive();
        if (buyAmount > amount || buyAmount == 0) revert InvalidSignatureBuyAmount();
        if (version != signatureVersion) revert InvalidSignatureVersion();
        uint256 totalPrice = unitPrice * buyAmount;
        if (msg.value != totalPrice) revert IncorrectMsgValue();

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    tier,
                    address(this),
                    tokenId,
                    unitPrice,
                    version,
                    nonce,
                    amount,
                    msg.sender
                )
            )
        );

        if (signatureUsed[hash]) revert SignatureAlreadyUsed();
        signatureUsed[hash] = true;
        if (hash.recover(sig) != signer) revert InvalidSignature();

        _mint(_msgSender(), tokenId, buyAmount, "");
    }

    /**
     * @dev Allows the owner to open the {mint} method for a certain tokenId
     * this method is to allow buyers to save gas on minting by not requiring a signature.
     */
    function openMint(
        uint256 tokenId,
        uint96 price,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint64 txLimit
    ) external onlyOwner {
        if(!exists(tokenId)) revert NonExistentToken();
        generalSaleData[tokenId].price = price;
        generalSaleData[tokenId].startTimestamp = startTimestamp;
        generalSaleData[tokenId].endTimestamp = endTimestamp;
        generalSaleData[tokenId].txLimit = txLimit;

        emit MintOpen(
            tokenId,
            startTimestamp,
            endTimestamp,
            price,
            txLimit
        );
    }

    /**
     * @dev Allows the owner to close the {generalMint} method to the public for a certain tokenId.
     */
    function closeMint(uint256 tokenId) external onlyOwner {
        delete generalSaleData[tokenId];
        emit MintClosed(tokenId);
    }

    /**
     * @dev Allows any user to buy a certain tokenId. This buy transaction is still limited by the
     * wallet mint limit, token supply limit, and transaction limit set for the tokenId. These are
     * all considered primary sales and will be split according to the withdrawal splits defined in the contract.
     */
    function mint(uint256 tokenId, uint256 buyAmount) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (block.timestamp < generalSaleData[tokenId].startTimestamp) revert MintNotActive();
        if (block.timestamp > generalSaleData[tokenId].endTimestamp) revert MintNotActive();
        if (
            generalSaleData[tokenId].txLimit != 0 &&
            buyAmount > generalSaleData[tokenId].txLimit
        ) {
            revert OverTransactionLimit();
        }

        if (msg.value != generalSaleData[tokenId].price * buyAmount) revert IncorrectMsgValue();
        _mint(_msgSender(), tokenId, buyAmount, "");
    }

    // =============================================================
    //                        Token Burning
    // =============================================================

    /**
     * @dev Owner can allow or pause holders from burning tokens of a certain
     * tokenId on without an intermediary contract.
     */
    function setBurnable(uint256 tokenId, bool burnable) external onlyOwner {
        _setBurnable(tokenId, burnable);
    }

    /**
     * @dev Allows token owners to burn tokens if self-burn is enabled for that token.
     */
    function burn(uint256 tokenId, uint256 amount) external {
        if(!_isSelfBurnable(tokenId)) revert NotSelfBurnable();
        _burn(msg.sender, tokenId, amount);
    }

    /**
     * @dev Owner can allow for certain contract addresses to burn tokens for users.
     * 
     * If this is an EOA, the approvedBurn transaction will revert.
     */
    function setApprovedBurner(
        address burner, 
        uint256 tokenId, 
        bool approved
    ) external onlyOwner {
        approvedBurners[burner][tokenId] = approved;
    }

    /**
     * @dev Allows token owners to burn their tokens through owner-approved burner contracts.
     */
    function approvedBurn(address spender, uint256 tokenId, uint256 amount) external {
        if (!approvedBurners[msg.sender][tokenId]) revert SenderNotApprovedBurner();
        if (tx.origin == msg.sender) revert NotContractAccount();
        _burn(spender, tokenId, amount);
    }

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        unchecked {
            if (amount > address(this).balance) {
                amount = address(this).balance;
            }
        }

        if (!_transferETH(withdrawAddress, amount)) revert WithdrawFailed();
    }

    /**
     * @notice Internal function to transfer ETH to a specified address.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30000 }(new bytes(0));
        return success;
    }
    
    error IncorrectMsgValue();
    error InvalidSignature();
    error InvalidSignatureBuyAmount();
    error InvalidSignatureVersion();
    error MintNotActive();
    error NotContractAccount();
    error NotSelfBurnable();
    error OperatorNotAllowed();
    error OverTransactionLimit();
    error SenderNotApprovedBurner();
    error SignatureAlreadyUsed();
    error TierNotActive();
    error WithdrawFailed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Strings.sol";
import "../../utils/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * There are some modifications compared to the originial OpenZepplin implementation
 * that give the collection owner mint limits for their tokenIds. It also has been
 * adjusted to have a max supply of uint64 of any tokenId for gas optimization.
 *
 * _Available since v3.1._
 */
contract ERC1155 is IERC1155 {
    using Address for address;
    using Strings for uint256;

    // =============================================================
    //                            STRUCTS
    // =============================================================

    // Compiler will pack this into a single 256bit word.
    struct TokenAddressData {
        // Limited to uint64 to save gas fees.
        uint64 balance;
        // Keeps track of mint count for a user of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count for a user of a tokenId.
        uint64 numBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // Compiler will pack this into a single 256bit word.
    struct TokenSupplyData {
        // Keeps track of mint count of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count of a tokenId.
        uint64 numBurned;
        // Keeps track of maximum supply of a tokenId.
        uint64 tokenMintLimit;
        // If the token is self-burnable or not
        bool burnable;
    }

    // =============================================================
    //                            Constants
    // =============================================================

    uint64 public MAX_TOKEN_SUPPLY = (1 << 64) - 1;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Used to enable the uri method
    mapping(uint256 => string) public tokenMetadata;

    // Saves all the token mint/burn data and mint limitations.
    mapping(uint256 => TokenSupplyData) private _tokenData;

    // Mapping from token ID to account balances, mints, and burns
    mapping(uint256 => mapping(address => TokenAddressData)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // =============================================================
    //                            EVENTS
    // =============================================================

    event NewTokenAdded(
        uint256 indexed tokenId,
        uint256 tokenMintLimit,
        string tokenURI
    );
    event TokenURIChanged(uint256 tokenId, string newTokenURI);
    event TokenMintLimitChanged(uint256 tokenId, uint64 newMintLimit);
    event NameChanged(string name);
    event SymbolChanged(string symbol);

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor() {}

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 interface ID for ERC1155MetadatURI.
    }

    // =============================================================
    //                    IERC1155MetadataURI
    // =============================================================

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev updates the name of the collection
     */
    function _setName(string memory _newName) internal {
        _name = _newName;
        emit NameChanged(_newName);
    }

    /**
     * @dev updates the symbol of the collection
     */
    function _setSymbol(string memory _newSymbol) internal {
        _symbol = _newSymbol;
        emit SymbolChanged(_newSymbol);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId) public view returns (string memory) {
        if (!exists(tokenId)) revert NonExistentToken();
        return tokenMetadata[tokenId];
    }

    /**
     * @dev Allows the owner to change the metadata for a tokenId but NOT the mint limits.
     *
     * Requirements:
     *
     * - `tokenId` must have already been added.
     * - `metadata` must not be length 0.
     */
    function _updateMetadata(uint256 tokenId, string calldata metadata)
        internal
    {
        if (!exists(tokenId)) revert NonExistentToken();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;

        emit TokenURIChanged(tokenId, metadata);
    }

    // =============================================================
    //                          IERC1155
    // =============================================================

    /**
     * @dev Returns if a tokenId has been added to the collection yet.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return bytes(tokenMetadata[tokenId]).length > 0;
    }

    /**
     * @dev Allows the owner to add a tokenId to the collection with the specificed
     * metadata and mint limits. MintLimit of 0 will be treated as uint64 max.
     * 
     * NOTE: MINT LIMITS CANNOT BE INCREASED
     *
     * Requirements:
     *
     * - `tokenId` must not have been added yet.
     * - `metadata` must not be length 0.
     *
     * @param tokenId of the new addition to the colleciton
     * @param tokenMintLimit the most amount of tokens that can ever be minted
     * @param metadata for the new collection when calling uri
     */
    function _addTokenId(
        uint256 tokenId,
        uint64 tokenMintLimit,
        string calldata metadata
    ) internal {
        if (exists(tokenId)) revert TokenAlreadyExists();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;
        _tokenData[tokenId].tokenMintLimit = tokenMintLimit;
        if (tokenMintLimit == 0) {
            _tokenData[tokenId].tokenMintLimit = MAX_TOKEN_SUPPLY;
        }
        emit NewTokenAdded(tokenId, tokenMintLimit, metadata);
    }

    /**
     * @dev Token supply can be set, but can ONLY BE LOWERED. Cannot be lower than the current supply.
     */
    function _setTokenMintLimit(
        uint256 tokenId, 
        uint64 tokenMintLimit
    ) internal {
        if (_tokenData[tokenId].numMinted > tokenMintLimit) revert InvalidMintLimit();
        if (tokenMintLimit == 0) revert InvalidMintLimit();
        _tokenData[tokenId].tokenMintLimit = tokenMintLimit;
        emit TokenMintLimitChanged(tokenId, tokenMintLimit);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[id][account].balance;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId are in circulation.
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numMinted - _tokenData[tokenId].numBurned;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId that were ever minted.
     */
    function totalMinted(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numMinted;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId that have gotten burned.
     */
    function totalBurned(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numBurned;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function totalMintedByAddress(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[id][account].numMinted;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function totalBurnedByAddress(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[id][account].numBurned;
    }

    /**
     * @dev Returns how many tokens are still available to mint
     *
     * Requirements:
     *
     * - `tokenId` must already exist.
     */
    function remainingSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _remainingSupply(tokenId);
    }

    /**
     * @dev Returns how many tokens are still available to mint
     */
    function _remainingSupply(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            _tokenData[tokenId].tokenMintLimit - _tokenData[tokenId].numMinted;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert ArrayLengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSenderERC1155(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Verifies if a certain tokenId can still mint `buyAmount` more tokens of a certain id.
     */
    function _verifyTokenMintLimit(uint256 tokenId, uint256 buyAmount)
        internal
        view
    {
        if (
            _tokenData[tokenId].numMinted + buyAmount >
            _tokenData[tokenId].tokenMintLimit
        ) {
            revert OverTokenLimit();
        }
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (from != _msgSenderERC1155() && !isApprovedForAll(from, _msgSenderERC1155())) {
            revert NotOwnerOrApproved();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        if (from != _msgSenderERC1155() && !isApprovedForAll(from, _msgSenderERC1155())) {
            revert NotOwnerOrApproved();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        if (_balances[id][from].balance < amount) {
            revert InsufficientTokenBalance();
        }
        // to balance can never overflow because there is a cap on minting
        unchecked {
            _balances[id][from].balance -= uint64(amount);
            _balances[id][to].balance += uint64(amount);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (_balances[id][from].balance < amount) {
                revert InsufficientTokenBalance();
            }
            // to balance can never overflow because there is a cap on minting
            unchecked {
                _balances[id][from].balance -= uint64(amount);
                _balances[id][to].balance += uint64(amount);
                
                ++i;
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * NOTE: In order to save gas fees when there are many transactions nearing the mint limit of a tokenId,
     * we do NOT call `_verifyTokenMintLimit` and instead leave it to the external method to do this check.
     * This allows the queued transactions that were too late to mint the token to error as cheaply as possible.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (!exists(id)) revert NonExistentToken();

        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        unchecked {
            _tokenData[id].numMinted += uint64(amount);
            _balances[id][to].balance += uint64(amount);
            _balances[id][to].numMinted += uint64(amount);
        }
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ) {
            _verifyTokenMintLimit(ids[i], amounts[i]);
            // The token mint limit verification prevents potential overflow/underflow
            unchecked {
                _tokenData[ids[i]].numMinted += uint64(amounts[i]);
                _balances[ids[i]][to].balance += uint64(amounts[i]);
                _balances[ids[i]][to].numMinted += uint64(amounts[i]);
                
                ++i;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Allow or stop holders from self-burning tokens of a certain tokenId.
     */
    function _setBurnable(uint256 tokenId, bool burnable) internal {
        _tokenData[tokenId].burnable = burnable;
    }

    /**
     * @dev returns if a tokenId is self-burnable.
     */
    function _isSelfBurnable(uint256 tokenId) internal view returns (bool) {
        return _tokenData[tokenId].burnable;
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from` 
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = _balances[id][from].balance;
        if (fromBalance < amount) revert InsufficientTokenBalance();
        unchecked {
            _balances[id][from].numBurned += uint64(amount);
            _balances[id][from].balance = uint64(fromBalance - amount);
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSenderERC1155();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from].balance;
            if (fromBalance < amount) revert InsufficientTokenBalance();
            unchecked {
                _balances[id][from].numBurned += uint64(amount);
                _balances[id][from].balance = uint64(fromBalance - amount);

                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        _beforeApproval(operator);
        if (owner == operator) revert ApprovalToCurrentOwner();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    /**
     * @dev Hook that is called before any approval for a token or wallet
     *      
     * `approvedAddr` - the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address approvedAddr) internal virtual {}
    
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    /**
     * @dev helper method to turn a uint256 variable into a 1-length array we can pass into uint256[] variables
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC1155() internal view virtual returns (address) {
        return msg.sender;
    }

    error ApprovalToCurrentOwner();
    error ArrayLengthMismatch();
    error BalanceQueryForZeroAddress();
    error BurnFromZeroAddress();
    error InsufficientTokenBalance();
    error InvalidMetadata();
    error InvalidMintLimit();
    error MintToZeroAddress();
    error NonExistentToken();
    error NotOwnerOrApproved();
    error OverTokenLimit();
    error TokenAlreadyExists();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
pragma solidity ^0.8.9;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     */

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

error CallerNotOwner();
error OwnerNotZero();

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
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (owner() != _msgSender()) revert CallerNotOwner();
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
        if (newOwner == address(0)) revert OwnerNotZero();
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}