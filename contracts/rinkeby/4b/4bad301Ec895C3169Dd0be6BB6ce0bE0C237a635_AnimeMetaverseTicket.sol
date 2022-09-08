//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

/// @title Anime Metaverse Ticket Smart Contract
/// @author LiquidX
/// @notice This contract is used to mint free ticket and premium ticket

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnimeMetaverseTicket.sol";
import "./AmvUtils.sol";

/// @notice Thrown when free ticket it's not able to be minted
error FreeTicketMintingNotActive();
/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();
/// @notice Thrown when burning less than 1 ticket
error InvalidBurnAmount();
/// @notice Thrown when max supply is less than total supply
error InvalidMaxSupply();
/// @notice Thrown when current token ID is already used by other token
error InvalidTokenId();
/// @notice Thrown when minting ticket more than its limit
error MaximumLimitToMintTicketExceeded();
/// @notice Thrown when the address is not allowed/exist in the burner list
error NotAllowedToBurn();
/// @notice Thrown when premium ticket it's not able to be minted
error PremiumTicketMintingNotActive();
/// @notice Thrown when inputting 0 as value
error ValueCanNotBeZero();
/// @notice Thrown when the length of array does not match with other array
error InvalidArrayLength();
/// @notice Thrown when an address is already whitelisted
error AlreadyWhiteListed(address wlAddress);
/// @notice Thrown when an address is not whitelisted
error NotWhiteListed(address wlAddress);

contract AnimeMetaverseTicket is
    Ownable,
    ERC1155,
    AmvUtils,
    IAnimeMetaverseTicket
{
    /// @dev Address who can withdraw the balance
    address payable withdrawalWallet;

    uint256 constant FREE_TICKET_TOKEN_ID = 1;
    uint256 constant PREMIUM_TICKET_TOKEN_ID = 2;
    /// @notice Initial premium ticket price when the contract was deployed
    uint256 public constant DEFAULT_PREMIUM_TICKET_PRICE = 0.06 ether;

    /// @dev State that decides whether user can mint free ticket or not
    bool public freeTicketMintingActive = false;
    /// @dev State that decides whether user can mint premium ticket or not
    bool public premiumTicketMintingActive = false;

    /// @notice Maximum free ticket supply
    /// @dev The maximum limit should not be less than total supply
    uint256 public freeTicketMaxSupply = 16000;
    /// @notice Maximum premium ticket supply
    /// @dev The maximum limit should not be less than total supply
    uint256 public premiumTicketMaxSupply = 20000;

    /// @notice Total free ticket that has been minted
    /// @dev The number will increase everytime there is a mint transaction
    uint256 public freeTicketTotalSupply = 0;
    /// @notice Total premium ticket that has been minted
    /// @dev The number will increase everytime there is a mint transaction
    uint256 public premiumTicketTotalSupply = 0;

    /// @notice Maximum limit for minting premium ticket in one transaction
    uint256 public maxPremiumTicketMintLimit = 100;

    /// @notice Current premium ticket price
    /// @dev This variable value can change since it's
    ///      storing the default price only for the first time
    uint256 public premiumTicketPrice = DEFAULT_PREMIUM_TICKET_PRICE;

    /// @notice Storing base URL for ticket metadata
    string public baseURI = "";

    /// @notice Store detail information related to whitelisted address
    /// @dev Whitelisted user are those who can mint free ticket
    /// @param maxAllowedToMint maximum free ticket user can mint
    /// @param alreadyMinted amount of free ticket that is already minted by user
    struct WhiteListedUser {
        uint256 maxAllowedToMint;
        uint256 alreadyMinted;
    }

    /// @notice List of whitelisted address and their eligible free ticket amount
    /// @dev Every address will contain information in the WhiteListedUser struct
    mapping(address => WhiteListedUser) public whiteListedUsersInfo;
    /// @notice List of address who's allowed to burn the ticket
    /// @dev The burner address list can only be set by the contract owner
    ///      and the value will be boolean. 'true' means allowed, otherwise
    ///      it's not.
    mapping(address => bool) public burnerList;

    /// @notice Check whether the address is a wallet address
    /// @dev Check if address is not 0x0 or contract address
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check whether current token ID is either free ticket or premium ticket ID
    /// @param _tokenId Any unsigned integer number
    modifier validTokenId(uint256 _tokenId) {
        if (
            _tokenId != FREE_TICKET_TOKEN_ID &&
            _tokenId != PREMIUM_TICKET_TOKEN_ID
        ) {
            revert InvalidTokenId();
        }
        _;
    }

    /// @notice Check whether the length of 2 lists are same.
    /// @dev Check whether the length of 2 arrays of unsigned integer are same.
    /// @param _length1 First array
    /// @param _length2 Second array
    modifier validInputArrayLength(uint256 _length1, uint256 _length2) {
        if (_length1 != _length2) {
            revert InvalidArrayLength();
        }
        _;
    }

    /// @notice Check whether the input is zero
    /// @param amount Any unsigned integer number
    modifier NotZero(uint256 amount) {
        if (amount == 0) {
            revert ValueCanNotBeZero();
        }
        _;
    }

    /// @notice Whether there is a mint transaction for free ticket
    /// @dev This event can also be used to audit the total supply of free ticket
    /// @param _receiver Address who mint the ticket
    /// @param _mintAmount How many ticket is minted in the transaction
    /// @param _tokenId The ticket token ID
    event MintFreeTicket(
        address _receiver,
        uint256 _mintAmount,
        uint256 _tokenId
    );
    /// @notice Whether there is a mint transaction for premium ticket
    /// @dev This event can also be used to audit the total supply of premium ticket
    /// @param _receiver Address who mint the ticket
    /// @param _mintAmount How many ticket is minted in the transaction
    /// @param _tokenId The ticket token ID
    event MintPremiumTicket(
        address _receiver,
        uint256 _mintAmount,
        uint256 _tokenId
    );
    /// @notice Emit whenever a ticket is burned
    /// @dev This event can also be used to audit the total of burned ticket
    /// @param _ticketOwner Owner of the ticket
    /// @param _burnAmount How many ticket is burned
    /// @param _tokenId The ticket token ID
    event BurnTicket(
        address _ticketOwner,
        uint256 _burnAmount,
        uint256 _tokenId
    );

    /// @notice Set initial address who can withdraw the balance in this contract
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    constructor() ERC1155("") {
        withdrawalWallet = payable(msg.sender);
    }

    /// @notice Add address to whitelist and set their free ticket quota
    /// @param _accounts list of address that will be added to whitelist
    /// @param _ticketAmounts amount of free ticket each user can mint
    function addToWhitelistBatch(
        address[] memory _accounts,
        uint256[] memory _ticketAmounts
    )
        public
        onlyOwner
        validInputArrayLength(_accounts.length, _ticketAmounts.length)
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_accounts[i] == address(0) || _accounts[i] == address(this)) {
                revert InvalidAddress();
            }
            if (whiteListedUsersInfo[_accounts[i]].maxAllowedToMint != 0) {
                revert AlreadyWhiteListed(_accounts[i]);
            }
            if (_ticketAmounts[i] < 1) {
                revert ValueCanNotBeZero();
            }
            whiteListedUsersInfo[_accounts[i]] = WhiteListedUser({
                maxAllowedToMint: _ticketAmounts[i],
                alreadyMinted: 0
            });
        }
    }
    
    /// @notice updates whitelistedusers for free minting
    /// @dev This function can be used to override maximum quota of
    ///      the free ticket that user can mint
    /// @param _accounts list of address that will be updated
    /// @param _ticketAmounts amount of free ticket each user can mint
    function updateWhitelistBatch(
        address[] memory _accounts,
        uint256[] memory _ticketAmounts
    )
        public
        onlyOwner
        validInputArrayLength(_accounts.length, _ticketAmounts.length)
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_accounts[i] == address(0) || _accounts[i] == address(this)) {
                revert InvalidAddress();
            }
            if (whiteListedUsersInfo[_accounts[i]].maxAllowedToMint == 0) {
                revert NotWhiteListed(_accounts[i]);
            }
            require(
                _ticketAmounts[i] >=
                    whiteListedUsersInfo[_accounts[i]].alreadyMinted,
                "max allowed to mint ticket needs to be greate or equal than already minted ticket for this address."
            );
            whiteListedUsersInfo[_accounts[i]]
                .maxAllowedToMint = _ticketAmounts[i];
        }
    }

    /// @notice Mint free ticket that only available for whitelisted address
    /// @dev Use _mint method from ERC1155 function which derived from Open Zeppelin ERC1155 library. It will increase alreadyMinted value based on amount of minted ticket
    /// @param _mintAmount How many free ticket to mint
    function mintFreeTicket(uint256 _mintAmount) external NotZero(_mintAmount) {
        if (!freeTicketMintingActive) {
            revert FreeTicketMintingNotActive();
        }
        require(
            freeTicketTotalSupply + _mintAmount <= freeTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );

        require(
            IsMintRequestValid(msg.sender, _mintAmount),
            "you are not whitelisted or already exceeded maximum limit to mint Free Ticket."
        );
        _mint(msg.sender, FREE_TICKET_TOKEN_ID, _mintAmount, "");
        freeTicketTotalSupply += _mintAmount;
        whiteListedUsersInfo[msg.sender].alreadyMinted += _mintAmount;
        emit MintFreeTicket(msg.sender, _mintAmount, FREE_TICKET_TOKEN_ID);
    }

    /// @notice Mint permium ticket that available for any address
    /// @dev Whitelisted address can also mint premium ticket and doesn't
    ///      increase the alreadyMinted value
    /// @param _mintAmount How many premium ticket to mint
    function mintPremiumTicket(uint256 _mintAmount)
        external
        payable
        NotZero(_mintAmount)
    {
        if (!premiumTicketMintingActive) {
            revert PremiumTicketMintingNotActive();
        }
        if (_mintAmount > maxPremiumTicketMintLimit) {
            revert MaximumLimitToMintTicketExceeded();
        }
        require(
            msg.value >= premiumTicketPrice * _mintAmount,
            "insufficient ETH provided."
        );
        require(
            premiumTicketTotalSupply + _mintAmount <= premiumTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );
        _mint(msg.sender, PREMIUM_TICKET_TOKEN_ID, _mintAmount, "");
        premiumTicketTotalSupply += _mintAmount;
        emit MintPremiumTicket(
            msg.sender,
            _mintAmount,
            PREMIUM_TICKET_TOKEN_ID
        );
    }

    /// @notice this is an owner function which airdrops permium tickets
    /// @param _addresses these will get airdropped premium tickets.
    /// @param _amounts number of premium tickets to be airdropped.
    function airDropPremiumTicket(
        address[] memory _addresses,
        uint256[] memory _amounts
    )
        external
        onlyOwner
        validInputArrayLength(_addresses.length, _amounts.length)
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            amount += _amounts[i];
        }
        require(
            premiumTicketTotalSupply + amount <= premiumTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], PREMIUM_TICKET_TOKEN_ID, _amounts[i], "");
        }
        premiumTicketTotalSupply += amount;
    }

    /// @notice Check whether the whitelisted address still eligible to
    ///         mint free ticket
    /// @dev It will calculate the alreadyMinted value + the _mintAmount
    ///      and the value should be less than equal to maxAllowedToMint
    /// @param _walletAddress Any valid wallet address
    /// @param _mintAmount How many free tickets to mint
    function IsMintRequestValid(address _walletAddress, uint256 _mintAmount)
        public
        view
        returns (bool)
    {
        if (
            whiteListedUsersInfo[_walletAddress].alreadyMinted + _mintAmount <=
            whiteListedUsersInfo[_walletAddress].maxAllowedToMint
        ) return true;
        else return false;
    }

    /// @notice Burn ticket
    /// @dev It will use _burn method from Open Zeppelin ERC1155 library
    /// @param tokenId Ticket token ID
    /// @param _account Address who burn the ticket
    /// @param _numberofTickets How many tickets to burn
    function burn(
        uint256 tokenId,
        address _account,
        uint256 _numberofTickets
    ) public validTokenId(tokenId) {
        if (!burnerList[msg.sender]) {
            revert NotAllowedToBurn();
        }
        if (_numberofTickets < 1) {
            revert InvalidBurnAmount();
        }
        _burn(_account, tokenId, _numberofTickets);
        emit BurnTicket(_account, _numberofTickets, tokenId);
    }

    /// @notice Update max supply for premium ticket
    /// @dev Max supply should not be less than the premium ticket total supply
    /// @param _newMaxSupply New maximum supply for premium ticket
    function updateMaxSupplyForPremiumTicket(uint256 _newMaxSupply)
        external
        onlyOwner
    {
        if (_newMaxSupply < premiumTicketTotalSupply) {
            revert InvalidMaxSupply();
        }
        premiumTicketMaxSupply = _newMaxSupply;
    }

    /// @notice Update max supply for free ticket
    /// @dev Max supply should not be less than the free ticket total supply
    /// @param _newMaxSupply New maximum supply for free ticket
    function updateMaxSupplyForFreeTicket(uint256 _newMaxSupply)
        external
        onlyOwner
    {
        if (_newMaxSupply < freeTicketTotalSupply) {
            revert InvalidMaxSupply();
        }
        freeTicketMaxSupply = _newMaxSupply;
    }

    /// @notice Set wallet address that can withdraw the balance
    /// @dev Only owner of the contract can execute this function.
    ///      The address should not be 0x0 or contract address
    /// @param _wallet Any valid address
    function setWithdrawWallet(address _wallet)
        external
        onlyOwner
        validAddress(_wallet)
    {
        withdrawalWallet = payable(_wallet);
    }

    /// @notice Set address that can burn ticket
    /// @dev Only owner of the contract can execute this function.
    ///      The address should not be 0x0 or contract address
    /// @param _burner The address that will be registered in burner list
    /// @param _flag Whether the address can burn the ticket or not
    function setBurnerAddress(address _burner, bool _flag)
        external
        onlyOwner
        validAddress(_burner)
    {
        burnerList[_burner] = _flag;
    }

    /// @notice Transfer balance on this contract to withdrawal address
    function withdrawETH() external onlyOwner {
        withdrawalWallet.transfer(address(this).balance);
    }

    /// @notice Update premium ticket price
    function updateMintPrice(uint256 _newPrice) external onlyOwner {
        premiumTicketPrice = _newPrice;
    }

    /// @notice Reset premium ticket price to default price
    /// @dev The default price is the value of DEFAULT_PREMIUM_TICKET_PRICE variable
    function resetMintPrice() external onlyOwner {
        premiumTicketPrice = DEFAULT_PREMIUM_TICKET_PRICE;
    }

    /// @notice Set base URL for metadata
    /// @param _newuri URL for metadata
    function setURI(string memory _newuri) public onlyOwner {
        baseURI = _newuri;
    }

    /// @notice Set maximum limit for minting premium ticket in one transaction
    /// @dev The limit should not be more than the difference of maximum
    ///      premium ticket supply and premium ticket total supply
    /// @param _maxLimit New maximum limit for minting premium ticket
    function updateMaxMintLimitForPremiumTicket(uint256 _maxLimit)
        external
        onlyOwner
        NotZero(_maxLimit)
    {
        if (_maxLimit > (premiumTicketMaxSupply - premiumTicketTotalSupply)) {
            revert();
        }
        maxPremiumTicketMintLimit = _maxLimit;
    }

    /// @notice Activate free ticket mint functionality
    /// @dev This will either prevent/allow minting transaction in this contract
    /// @param _flag Whether to enable or disable the minting functionality
    function ActivateFreeTicketMinting(bool _flag) external onlyOwner {
        freeTicketMintingActive = _flag;
    }

    /// @notice Activate premium ticket mint functionality
    /// @dev This will either prevent/allow minting transaction in this contract
    /// @param _flag Whether to enable or disable the minting functionality
    function ActivatePremiumTicketMinting(bool _flag) external onlyOwner {
        premiumTicketMintingActive = _flag;
    }

    /// @notice Append token ID to base URL
    /// @param _tokenId Ticket token ID
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, intToString(_tokenId)))
                : "";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseTicket {
    function burn(
        uint256 tokenId,
        address _account,
        uint256 _numberofTickets
    ) external;

    function mintFreeTicket(uint256 _mintAmount) external;

    function mintPremiumTicket(uint256 _mintAmount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract AmvUtils {
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

    function singletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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