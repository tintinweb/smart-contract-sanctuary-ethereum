// SPDX-License-Identifier: MIT
// @author mouradif.eth

pragma solidity 0.8.14;

import "../interfaces/IBlank.sol";
import "./BlankGenesis.sol";

contract Blank is IBlank, BlankGenesis {
// ################################################################ //
//                                                      .           //
//                                          .::=+*##%%%%*.          //
//                                      -=*%@@@@@@@@@@@@=           //
//                                  :=*%@@@@@@@%##%@@@@+.           //
//                               :=#@@@@@@#+-:.  :%@@@*.            //
//                             -*@@@@@#+-.      :%@@@#.             //
//                           -*@@@@@+:         =%@@@*.              //
//                         .*@@@@%=.         =#@@@%-                //
//                        -%@@@@*:        :+%@@@@+:                 //
//                       [email protected]@@@#-       :+#@@@@@@#:                  //
//                      [email protected]@@@+.      .-===++%@@@@%:                 //
//                     [email protected]@@@=              .*@@@@=                  //
//                    [email protected]@@@=              -%@@@@=                   //
//                   [email protected]@@@=             =#@@@@#-                    //
//                  -%@@@*.         :=*%@@@@#=                      //
//                 :#@@@#:  ..:-=*#%@@@@@@*-                        //
//                 [email protected]@@@=-*%%@@@@@@@@@@#+:                          //
//                :%@@@@@@@@@@@@%##+-:.                             //
//                [email protected]@@@@@@@*+-:.                                    //
//               :%@@@@@%+:                                         //
//               [email protected]@@@@#.                                           //
//              .#@@@@#.                                            //
//              -%@@@*.                                             //
//              *@@@@-             Blank.                           //
//                                 Made with <3 by a team of        //
//                                 passionate innovators            //
//             *@@@@@-                                              //
//             *@@@@@-             Smart Contract by:               //
//             +%%%%%-             Mouradif                         //
//                                                                  //
//                                                                  //
// ################################################################ //
/**
 *  Blank Studio Genesis NFT Contracts
 *
 *  Blank.sol: The Blank contract
 *  BlankGenesis.sol: Public mint functions and withdraw
 *  BlankBase.sol: Minting rules, validation functions
 *  ERC721.sol: NFT implementation heavily inspired from the latest ERC721A
 *
 *  The Heart
 *
 *  Blank. is forging a new frontier of innovation and creativity in the rapidly
 *  emerging NFT space.
 *  Blank. will encourage pure expression and provide ways for this expression to
 *  be seen and appreciated.
 *  With our unique curation and innovative style, it is never impossible.
 *
 *  Mutual Trust & Respect
 *
 *  Blank. is built on trust and respect. We know innovation takes time to
 *  understand and adapt. Side by side, we can build and grow the Blank. ecosystem.
 *
 *  Xpression
 *
 *  We welcome every thought and idea from the community that shapes us. Express yourself
 *  without reserve or shame, and show your creativity unapologetically. Blank. is an open
 *  canvas for bringing your Xpression to life.
 *
 *  Degens vs Innovators
 *
 *  There is a fine line between degens and innovators. At Blank. no one is afraid to live
 *  on the apex.
 *  We test the limits and, as the space evolves, need to grow and innovate alongside it.
 *
 **/
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC721A.sol";

interface IBlank is IERC721A {
  // TODO:
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./BlankBase.sol";

contract BlankGenesis is BlankBase {

    /// @notice Free Mint for the devs
    ///         - Only Role Admin (deployer)
    ///         - Can't exceed the genesis supply
    ///         - Can't devMint more than DEV_SUPPLY
    function devMint()
    public
    onlyOwner
    hasSubgroupSupply(DEV_SUPPLY, devMints)
    {
        devMints++;
        _mint(msg.sender);
    }

    /// @notice Free Mint for the project owners
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the freeMints supply
    ///         - Caller address must be signed by the Free Mint Approver
    function freeMint(bytes calldata signature)
    public
    mintHasStarted
    canStillMint
    isMintApproved(freeMintApprover, signature)
    hasSubgroupSupply(FREE_SUPPLY, freeMints)
    {
        freeMints++;
        _mint(msg.sender);
    }

    /// @notice Regular Mint for the blanklisted addresses
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the Genesis supply minus reserved tokens (free and dev mints)
    ///         - Caller address must be signed by the Blank List Approver
    function blankListMint(bytes calldata signature)
    public
    payable
    mintHasStarted
    canStillMint
    isMintApproved(blankApprover, signature)
    hasTokenSupply(GENESIS_SUPPLY - DEV_SUPPLY - FREE_SUPPLY + devMints + freeMints)
    hasTheRightAmount
    {
        _mint(msg.sender);
    }

    /// @notice Regular Mint for the blanklisted addresses
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the Genesis supply minus reserved tokens (free and dev mints)
    ///         - Caller address must be signed by the Reserve List Approver
    function reserveListMint(bytes calldata signature)
    public
    payable
    reserveHasStarted
    canStillMint
    isMintApproved(reserveApprover, signature)
    hasTokenSupply(GENESIS_SUPPLY - DEV_SUPPLY - FREE_SUPPLY + devMints + freeMints)
    hasTheRightAmount
    {
        _mint(msg.sender);
    }

    /// @notice This function will be called by the Gen2 contract to burn 4 32x32 canvases into one 64x64
    ///         All the validation will be made in there (checking that the 4 tokens are in the right spot mainly)
    ///         It will burn the 4 tokens on the Gen2 and mint one here allowing their owner to ascend into genesis
    function burnIntoGenesis(address ascendant)
    public
    onlyGen2Contract
    hasSubgroupSupply(GEN2_SUPPLY, gen2Mints)
    {
        gen2Mints++;
        _mint(ascendant);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BlankBase is ERC721, Ownable {
    /// @dev Addresses that can approve restricted mints
    address internal freeMintApprover = 0xb681cFf9A2Ed00756A7144afd9378455751b0A8e;
    address internal blankApprover = 0x074631a146ABF0103453507094084f29982F7e0e;
    address internal reserveApprover = 0x3a192C386db33C3d65c1a34dBE562860A61BEA4b;

    /// @dev Infos of the Gen2 contract
    address internal gen2Contract;

    /// @notice Mint configuration
    uint256 public constant MINT_PRICE = 0.29 ether;
    uint256 public constant GENESIS_SUPPLY = 400;
    uint256 public constant DEV_SUPPLY = 4;
    uint256 public constant FREE_SUPPLY = 25;
    uint256 public constant GEN2_SUPPLY = 3200; // 12800 divided by 4;

    /// @notice Mint start timestamp
    uint256 public mintStartTimestamp = 1653987600; // May 31st 2022, 10AM BST
    uint256 public whitelistMintDuration = 12 hours;

    /// @notice Mint counters for subgroups with dedicated supply
    uint256 public devMints;
    uint256 public freeMints;
    uint256 public gen2Mints;

    /// @dev Modifier to ensure the message signer is the one expected
    modifier isMintApproved(address approver, bytes calldata signature) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender))
            )
        );
        require(
            ECDSA.recover(hash, signature) == approver,
            "You have not been approved for this mint"
        );
        _;
    }

    /// @dev Modifier to ensure the caller hasn't already minted
    modifier canStillMint() {
        require(!hasMinted(msg.sender), "You can only mint once"); // YOMO: You Only Mint Once
        _;
    }

    /// @dev Modifier to ensure the max supply won't be exceeded by a genesis mint transaction
    modifier hasTokenSupply(uint256 supply) {
        require(_currentIndex < supply, "Mint supply reached");
        _;
    }

    /// @dev Modifier to ensure the max supply won't be exceeded by a genesis mint transaction
    modifier hasSubgroupSupply(uint256 supply, uint256 current) {
        require(current < supply, "Mint supply reached for this category");
        _;
    }

    /// @dev Modifier that checks that the mint has started and that devs have already minted token 0
    modifier mintHasStarted() {
        require(
            block.timestamp >= mintStartTimestamp && _currentIndex > 0,
            "Mint has not started"
        );
        _;
    }

    /// @dev Modifier that checks that the reserve list can mint
    modifier reserveHasStarted() {
        require(
            block.timestamp >= mintStartTimestamp + whitelistMintDuration && _currentIndex > 0,
            "Reserve Mint has not started"
        );
        _;
    }


    /// @dev Modifier to ensure the right amount has been sent (no more, no less)
    modifier hasTheRightAmount() {
        require(msg.value == MINT_PRICE, "You must send the right amount");
        _;
    }

    /// @dev Modifier to ensure the call was made by the Gen2 contract
    modifier onlyGen2Contract() {
        require(msg.sender == gen2Contract, "Caller must be Blank Gen 2");
        _;
    }

    /// @dev Contract constructor. Initializes the base URI that serves Metadata
    constructor() ERC721("Blank.", "BLNK") {
        _baseURI = "https://api.blankstudio.art/metadata/";
    }

    /// @notice Update the base URI that serves the Metadata
    function setBaseURI(string calldata uri) public onlyOwner {
        _baseURI = uri;
    }

    /// @notice Change the Freemint Approver
    function setFreeMintApprover(address approver) public onlyOwner {
        require(approver != freeMintApprover, "Nothing to change");
        freeMintApprover = approver;
    }

    /// @notice Change the BlankList Approver
    function setBlankApprover(address approver) public onlyOwner {
        require(approver != blankApprover, "Nothing to change");
        blankApprover = approver;
    }

    /// @notice Change the Reserve Approver
    function setReserveApprover(address approver) public onlyOwner {
        require(approver != reserveApprover, "Nothing to change");
        reserveApprover = approver;
    }

    /// @notice Updates the mint start timestamp
    function setMintStartTimestamp(uint256 timestamp) public onlyOwner {
        mintStartTimestamp = timestamp;
    }

    /// @notice Sets the address of the Gen2 contract
    function setGen2(address gen2) public onlyOwner
    {
        require(gen2Contract == address(0), "Gen2 was already initialized");
        gen2Contract = gen2;
    }

    /// @notice
    function withdraw()
    public
    onlyOwner
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "I'm Broke!");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Get Blanked!");
    }
}

// SPDX-License-Identifier: MIT
// ERC721 Contract
// Creator: Blank Studio
// Based on ERC721A by Chiru Labs

pragma solidity 0.8.14;

import '../interfaces/IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas.
 *
 * - Each mint is indivitual (no batch mint)
 * - Any given address can only mint once
 * - Tokens are sequentially minted starting at 0
 * - Tokens are not burnable
 */
abstract contract ERC721 is IERC721A {
    // last 12 bits (Where the total balance including Gen2 should fit)
    uint256 private constant BALANCE_BITMASK = 0xfff;

    // 13th bit that will be active if the address already minted
    uint256 private constant ALREADY_MINTED_BITMASK = 0x1000;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Metadata Base URI
    string internal _baseURI;

    // Mapping from token ID to owner's address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to balance
    // Bits Layout:
    // - [0..12]    `balance`
    // - [13]       `alreadyMinted`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BALANCE_BITMASK;
    }

    /**
     * @dev Returns true if an address has already minted
     */
    function hasMinted(address owner) public view returns (bool) {
        return (_packedAddressData[owner] & ALREADY_MINTED_BITMASK) > 0;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        if (to == _owners[tokenId]) revert ApprovalToCurrentOwner();

        if (msg.sender != _owners[tokenId])
            if (!isApprovedForAll(_owners[tokenId], msg.sender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view virtual returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract.json"));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, _toString(tokenId), ".json"));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }


    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex; // If within bounds
    }

    /**
     * @dev Equivalent to `_safeMint(to, '')`.
     */
    function _safeMint(address to) internal {
        _safeMint(to, '');
    }

    /**
     * @dev Safely mints 1 token and transfers it to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        bytes memory _data
    ) internal {
        if (to == address(0)) revert MintToZeroAddress();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - balance++
            // - alreadyMinted = true
            _packedAddressData[to] = (_packedAddressData[to] + 1) | ALREADY_MINTED_BITMASK;

            // Updates:
            // - `address` to the owner.
            _owners[_currentIndex] = to;

            if (to.code.length != 0) {
                emit Transfer(address(0), to, _currentIndex);
                if (!_checkContractOnERC721Received(address(0), to, _currentIndex++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } else {
                emit Transfer(address(0), to, _currentIndex++);
            }
        }
    }

    /**
     * @dev Mints 1 token and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to) internal {
        if (to == address(0)) revert MintToZeroAddress();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
        // Updates:
        // - balance++
        // - alreadyMinted = true
        _packedAddressData[to] = (_packedAddressData[to] + 1) | ALREADY_MINTED_BITMASK;

        // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `nextInitialized` to `quantity == 1`.
            _owners[_currentIndex] = to;

            emit Transfer(address(0), to, _currentIndex++);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (_owners[tokenId] != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        if (
            msg.sender != from &&
            !isApprovedForAll(from, msg.sender) &&
            getApproved(tokenId) != msg.sender
        ) revert TransferCallerNotOwnerNorApproved();

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            _packedAddressData[from]--; // Updates: `balance -= 1`.
            _packedAddressData[to]--; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `nextInitialized` to `true`.
            _owners[tokenId] = to;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit),
        // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
        // We will need 1 32-byte word to store the length,
        // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
        // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

        // Cache the end of the memory to calculate the length later.
            let end := ptr

        // We write the string from the rightmost digit to the leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // Costs a bit more than early returning for the zero case,
        // but cheaper in terms of deployment and overall runtime costs.
            for {
            // Initialize and perform the first pass without check.
                let temp := value
            // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
            // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
        // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
        // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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