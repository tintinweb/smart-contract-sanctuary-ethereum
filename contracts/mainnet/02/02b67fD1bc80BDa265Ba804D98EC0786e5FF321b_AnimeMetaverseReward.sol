// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

/// @title Anime Metaverse Reward Smart Contract
/// @author LiquidX
/// @notice This smart contract is used for reward on Gachapon event

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./AmvUtils.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();

/// @notice Thrown when given input does not meet with the expected one
error InvalidInput();

/// @notice Thrown when mint amount is more than the maximum limit or equals to zero
error InvalidMintingAmount(uint256 amount);

/// @notice Thrown when address is not included in Burner list
error InvalidBurner();

/// @notice Thrown when address is not included in Minter list
error InvalidMinter();

/// @notice Thrown when token ID is not match with the existing one
error InvalidTokenId();

/// @notice Thrown when token ID is not available for minting
error InvalidMintableTokenId();

/// @notice Thrown when input is equal to zero
error ValueCanNotBeZero();

/// @notice Thrown when token supply already reaches its maximum limit
/// @param range  Amount of token that would be minted
error MintAmountForTokenTypeExceeded(uint256 range);

/// @notice Thrown when address is not allowed to burn the token
error NotAllowedToBurn();

/// @notice Thrown when is not able to mint digital collectible
error ClaimingMerchandiseDeactivated();

contract AnimeMetaverseReward is
    ERC1155,
    Ownable,
    AmvUtils,
    IAnimeMetaverseReward
{
    uint256 public constant GIFT_BOX_TOKEN_TYPE = 1;
    uint256 public constant ARTIFACTS_TOKEN_TYPE = 2;
    uint256 public constant RUNE_CHIP_TOKEN_TYPE = 3;
    uint256 public constant SCROLL_TOKEN_TYPE = 4;
    uint256 public constant COLLECTIBLE__TOKEN_TYPE = 5;
    uint256 public constant DIGITAL_COLLECTIBLE_TOKEN_TYPE = 6;

    uint256 public constant MAX_MINTATBLE_TOKEN_ID = 18;
    uint256 public constant MAX_BURNABLE_COLLECTIBLE = 1;
    uint256 public constant COLLECTIBLE_AND_DIGITAL_COLLECTIBLE_DIFF = 3;
    uint256 public constant MAX_TOKEN_SUPPLY = 5550;

    struct TokenInfo {
        string tokenName;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 tokenType;
    }

    mapping(uint256 => TokenInfo) public tokenCollection;

    /// @notice Total of token ID
    uint256 totalToken = 0;
    uint256 maxMintLimit = 100;

    /// @notice List of address that could mint the token
    /// @dev Use this mapping to set permission on who could mint the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public minterList;

    /// @notice List of address that could burn the token
    /// @dev Use this mapping to set permission on who could force burn the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(uint256 => mapping(address => bool)) public burnerList;

    bool public claimMerchandiseActive = false;

    /// @notice Base URL to store off-chain information
    /// @dev This variable could be used to store URL for the token metadata
    string public baseURI = "";

    /// @notice Check whether address is valid
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check whether token ID exist
    /// @param tokenId token ID
    modifier validTokenId(uint256 tokenId) {
        if (tokenId < 1 || tokenId > totalToken) {
            revert InvalidTokenId();
        }
        _;
    }

    /// @notice Check whether mint amount is more than maximum limit or equals to zero
    /// @param amount Mint amount
    modifier validMintingAmount(uint256 amount) {
        if (amount > maxMintLimit || amount < 1) {
            revert InvalidMintingAmount(amount);
        }
        _;
    }

    modifier validMintableTokenId(uint256 tokenId) {
        if (tokenId < 1 || tokenId > MAX_MINTATBLE_TOKEN_ID) {
            revert InvalidMintableTokenId();
        }
        _;
    }

    /// @notice Check whether an address has permission to mint
    modifier onlyMinter() {
        if (!minterList[msg.sender]) {
            revert InvalidMinter();
        }
        _;
    }

    /// @notice Check whether an address has permission to force burn
    modifier onlyBurner(uint256 id) {
        if (!isValidBurner(id)) {
            revert InvalidBurner();
        }
        _;
    }

    /// @notice There's a batch mint transaction happen
    /// @dev Emit event when calling mintBatch function
    /// @param drawIndex Gachapon draw Index
    /// @param activityId Gachapon activity ID
    /// @param minter Address who calls the function
    /// @param to Address who receives the token
    /// @param ids Item token ID
    /// @param amounts Amount of item that is minted
    event RewardMintBatch(
        uint256 ticket,
        uint256 drawIndex,
        uint256 activityId,
        address minter,
        address to,
        uint256[] ids,
        uint256[] amounts
    );

    /// @notice There's a mint transaction happen
    /// @dev Emit event when calling mint function
    /// @param drawIndex Gachapon draw Index
    /// @param activityId Gachapon activity ID
    /// @param minter Address who calls the function
    /// @param to Address who receives the token
    /// @param id Item token ID
    /// @param amount Amount of item that is minted
    event RewardMint(
        uint256 ticket,
        uint256 drawIndex,
        uint256 activityId,
        address minter,
        address to,
        uint256 id,
        uint256 amount
    );

    /// @notice There's a token being burned
    /// @dev Emits event when forceBurn function is called
    /// @param burner Burner address
    /// @param Owner Token owner
    /// @param tokenId Token ID that is being burned
    /// @param amount Amount of token that is being burned
    event ForceBurn(
        address burner,
        address Owner,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice There's a digital collectible
    /// @dev Emit event when digital merch is minted
    /// @param minter Address who mints digital collectible
    /// @param to Address who receiveses digital collectible
    /// @param id Token ID of the digital collectible
    /// @param amount Amount of the digital collectible that is minted
    event MintDigitalMerch(
        address minter,
        address to,
        uint256 id,
        uint256 amount
    );

    /// @notice Sets token ID, token name, maximum supply and token type for all tokens
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    constructor() ERC1155("") {
        setTokenInfo(1, "Gift of Soul", 170, GIFT_BOX_TOKEN_TYPE);

        setTokenInfo(2, "Sakura", 4, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(3, "Starburst X", 4000, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(4, "Starburst C", 2500, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(5, "Starburst D", 1896, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(6, "Starburst M", 1500, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(7, "Starburst V", 100, ARTIFACTS_TOKEN_TYPE);

        setTokenInfo(8, "God Rune", 450, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(9, "Man Rune", 1500, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(10, "Sun Rune", 3000, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(11, "Fire Rune", 4500, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(12, "Ice Rune", 5550, RUNE_CHIP_TOKEN_TYPE);

        setTokenInfo(13, "Scroll of Desire", 4715, SCROLL_TOKEN_TYPE);
        setTokenInfo(14, "Scroll of Prophecy", 3301, SCROLL_TOKEN_TYPE);
        setTokenInfo(15, "Scroll of Fortitude", 1414, SCROLL_TOKEN_TYPE);

        setTokenInfo(16, "Hoodie", 200, COLLECTIBLE__TOKEN_TYPE);
        setTokenInfo(17, "Tshirt", 400, COLLECTIBLE__TOKEN_TYPE);
        setTokenInfo(18, "Socks", 800, COLLECTIBLE__TOKEN_TYPE);

        setTokenInfo(19, "Digital Hoodie", 200, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
        setTokenInfo(20, "Digital Tshirt", 400, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
        setTokenInfo(21, "Digital Sock", 800, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
    }

    /// @notice Sets information about specific token
    /// @dev It will set token ID, token name, maximum supply, and token type
    /// @param _tokenId ID for specific token
    /// @param _tokenName Name of the token
    /// @param _maximumSupply The maximum supply for the token
    /// @param _tokenType Type of token
    function setTokenInfo(
        uint256 _tokenId,
        string memory _tokenName,
        uint256 _maximumSupply,
        uint256 _tokenType
    ) private {
        totalToken++;
        tokenCollection[_tokenId] = TokenInfo({
            maxSupply: _maximumSupply,
            totalSupply: 0,
            tokenName: _tokenName,
            tokenType: _tokenType
        });
    }

    /// @notice Update token maximum supply
    /// @dev This function can only be executed by the contract owner
    /// @param _id Token ID
    /// @param _maximumSupply Token new maximum supply
    function updateTokenSupply(uint256 _id, uint256 _maximumSupply)
        external
        onlyOwner
        validTokenId(_id)
    {
        if (tokenCollection[_id].totalSupply > _maximumSupply) {
            revert InvalidInput();
        }
        tokenCollection[_id].maxSupply = _maximumSupply;
    }

    /// @notice Set maximum amount to mint token
    /// @dev This function can only be executed by the contract owner
    /// @param _mintLimit Maximum amount to mint
    function setMaxMintLimit(uint256 _mintLimit) external onlyOwner {
        require(_mintLimit >= 1, "Can not set mintLimit less than 1.");
        require(
            _mintLimit <= MAX_TOKEN_SUPPLY,
            "Can not set mintLimit more than 5550."
        );
        maxMintLimit = _mintLimit;
    }

    /// @notice Registers an address and sets a permission to mint
    /// @dev This function can only be executed by the contract owner
    /// @param _minter A valid ethereum address
    /// @param _flag The permission to mint. 'true' means allowed
    function setMinterAddress(address _minter, bool _flag)
        external
        onlyOwner
        validAddress(_minter)
    {
        minterList[_minter] = _flag;
    }

    /// @notice Set claimMerchandiseActive value
    /// @param _flag 'true' to activate claim collectible event, otherwise 'false'
    function toggleMerchandiseClaim(bool _flag) external onlyOwner {
        claimMerchandiseActive = _flag;
    }

    /// @notice Registers an address and sets a permission to force burn specific token
    /// @dev This function can only be executed by the contract owner
    /// @param _id The token id that can be burned by this address
    /// @param _burner A valid ethereum address
    /// @param _flag The permission to force burn. 'true' means allowed
    function setBurnerAddress(
        uint256 _id,
        address _burner,
        bool _flag
    ) external onlyOwner validAddress(_burner) validTokenId(_id) {
        burnerList[_id][_burner] = _flag;
    }

    /// @notice Mint token in batch
    /// @dev This function will increase total supply for the token that
    ///      is minted.
    ///      Only allowed minter address that could run this function
    /// @param _ticket Gachapon ticket counter for a draw
    /// @param _drawIndex Gachapon draw Index
    /// @param _activityId Gachapon activity ID
    /// @param _to The address that will receive the token
    /// @param _ids The token ID that will be minted
    /// @param _amounts Amount of token that will be minted
    /// @param _data _
    function mintBatch(
        uint256 _ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external onlyMinter validAddress(_to) {
        if (_amounts.length != _ids.length) {
            revert InvalidInput();
        }

        for ( uint256 idCounter = 0; idCounter < _ids.length; idCounter = _uncheckedInc(idCounter) ) {
            uint256 _id = _ids[idCounter];

            if (_amounts[idCounter] > maxMintLimit || _amounts[idCounter] < 1) {
                revert InvalidMintingAmount(_amounts[idCounter]);
            }
            if (_id < 1 || _id > MAX_MINTATBLE_TOKEN_ID) {
                revert InvalidMintableTokenId();
            }
            if (
                tokenCollection[_id].totalSupply + _amounts[idCounter] >
                tokenCollection[_id].maxSupply
            ) {
                revert MintAmountForTokenTypeExceeded(_amounts[idCounter]);
            }

            unchecked {
                tokenCollection[_id].totalSupply += _amounts[idCounter];
            }
        }

        _mintBatch(_to, _ids, _amounts, _data);
        emit RewardMintBatch(
            _ticket,
            _drawIndex,
            _activityId,
            msg.sender,
            _to,
            _ids,
            _amounts
        );
    }

    /// @notice Mint token
    /// @dev This function will increase total supply for the token that
    ///      is minted.
    ///      Only allowed minter address that could run this function
    /// @param _ticket Gachapon ticket counter for a draw
    /// @param _drawIndex Gachapon draw Index
    /// @param _activityId Gachapon activity ID
    /// @param _to The address that will receive the token
    /// @param _id The token ID that will be minted
    /// @param _amount Amount of token that will be minted
    /// @param _data _
    function mint(
        uint256 _ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        external
        onlyMinter
        validAddress(_to)
        validMintableTokenId(_id)
        validMintingAmount(_amount)
    {
        if (
            tokenCollection[_id].totalSupply + _amount >
            tokenCollection[_id].maxSupply
        ) {
            revert MintAmountForTokenTypeExceeded(_amount);
        }
        unchecked {
            tokenCollection[_id].totalSupply += _amount;
        }
        _mint(_to, _id, _amount, _data);
        emit RewardMint(
            _ticket,
            _drawIndex,
            _activityId,
            msg.sender,
            _to,
            _id,
            _amount
        );
    }

    /// @notice Burns specific token from other address
    /// @dev Only burners address who are allowed to burn the token.
    ///      These addresses will be set by owner.
    /// @param _account The owner address of the token
    /// @param _id The token ID
    /// @param _amount Amount to burn
    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external validAddress(_account) onlyBurner(_id) validTokenId(_id) {
        _burn(_account, _id, _amount);
        emit ForceBurn(msg.sender, _account, _id, _amount);
    }

    /// @notice Checks whether the caller has the permission to burn this particular token or not
    /// @param _id The token ID to burn
    function isValidBurner(uint256 _id) public view returns (bool) {
        return burnerList[_id][msg.sender];
    }

    /// @notice Set base URL for storing off-chain information
    /// @param newuri A valid URL
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    /// @notice Appends token ID to base URL
    /// @param tokenId The token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, intToString(tokenId)))
                : "";
    }

    /// @notice Get information from specific token ID
    /// @param _id Token ID
    function getTokenInfo(uint256 _id)
        external
        view
        validTokenId(_id)
        returns (TokenInfo memory tokenInfo)
    {
        tokenInfo = tokenCollection[_id];
    }

    /// @notice Mint digital collectible
    /// @param _to Receiver of the digital collectible
    /// @param collectible_id Token ID that's included in COLLECTIBLE_TOKEN_TYPE
    function mintDigitalCollectible(address _to, uint256 collectible_id)
        internal
    {
        uint256 _id = collectible_id + COLLECTIBLE_AND_DIGITAL_COLLECTIBLE_DIFF;
        tokenCollection[_id].totalSupply++;
        _mint(_to, _id, MAX_BURNABLE_COLLECTIBLE, "");
        emit MintDigitalMerch(msg.sender, _to, _id, MAX_BURNABLE_COLLECTIBLE);
    }

    /// @notice Claim collectible with digital collectible
    /// @param _account Owner of the collectible
    /// @param _id Token ID that's included in COLLECTIBLE_TOKEN_TYPE
    function claimMerchandise(address _account, uint256 _id)
        external
        validAddress(_account)
    {
        if (!claimMerchandiseActive) {
            revert ClaimingMerchandiseDeactivated();
        }
        if (tokenCollection[_id].tokenType != COLLECTIBLE__TOKEN_TYPE)
            revert NotAllowedToBurn();
        require(
            _account == _msgSender() ||
                isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(_account, _id, MAX_BURNABLE_COLLECTIBLE);
        mintDigitalCollectible(_account, _id);
    }

    function _uncheckedInc(uint256 val) internal pure returns (uint256) {
        unchecked {
            return val + 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
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
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
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
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
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
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/// @title Utility function for developing smart contract
/// @author LiquidX
/// @notice You could use function in this smart contract as 
///         a helper to do menial task
/// @dev All function in this contract has generic purposes 
///      like converting integer to string, converting an array, etc.

contract AmvUtils {
    /// @dev Convert integer into string
    /// @param value Integer value that would be converted into string
    function intToString(uint256 value) internal pure returns (string memory) {
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

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseReward {
    function mintBatch(
        uint256 ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function mint(
        uint256 ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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