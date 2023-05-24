//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./interfaces/ERC721A/IERC721A.sol";
import "./interfaces/ERC721A/ERC721A.sol";
import "./libraries/Counters.sol";
import "./libraries/ECDSA.sol";
import "./libraries/Context.sol";
import "./libraries/Ownable.sol";
import "./mocks/NFTBetting.sol";


contract LibesBetting is Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    event CreateTournament(uint256 indexed _TournamentId, string indexed _Name);
    event Betting(
        uint256 indexed _BetId,
        uint256 indexed _TournamentId,
        address indexed _Owner,
        uint256[] _TokenId
    );

    event Cancel(
        uint256 _tournamentId,
        uint256[] _tokenId
    );

    event EndTournament(uint256 _TournamentId);
    Counters.Counter private _TournamentIdCounter;
    Counters.Counter private _BetIdCounter;
    struct Tournament {
        uint256 TournamentId;
        string TournamentName;
        bool status;
    }
    struct Bet {
        uint256 _TournamentId;
        uint256[] TokenId;
        address Owner;
    }
    struct Winner {
        address winnerAddress;
        uint256[] tokenId;
    }

    address payable public NFTBettingAddress;

    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => Bet[]) betters;
    mapping(uint256 => Bet) better;
    mapping(uint256 => bool) History;
    mapping(address => mapping(uint256 => bool)) seenNonces;

    constructor() {}

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Not Admin");
        _;
    }

    modifier verifySignature(
        uint256 nonce,
        uint256 tournamentId, 
        bytes memory signature
    ) {
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                nonce,
                tournamentId
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        // Verify that the message's signer is the owner of the order
        require(messageHash.recover(signature) == owner(), "Invalid signature");
        require(!seenNonces[msg.sender][nonce], "Used nonce");
        seenNonces[msg.sender][nonce] = true;
        _;
    }


    function setNFTBettingAddress(address payable _NFTBettingAddress) external onlyAdmin {
        require(_NFTBettingAddress != address(0), "INVALID NFT BETTING ADDRESS.");
        NFTBettingAddress = _NFTBettingAddress;
    }

    function createTournament(
        string memory _tournamentName
    ) external onlyAdmin returns (uint256 _tournamentId) {
        _TournamentIdCounter.increment();
        _tournamentId = _TournamentIdCounter.current();
        bool _status = false;
        Tournament memory tournament = Tournament(
            _tournamentId,
            _tournamentName,
            _status
        );
        tournaments[_tournamentId] = tournament;
        emit CreateTournament(_tournamentId, _tournamentName);
    }

    function betting(
        uint256 _tournamentId,
        uint256[] memory _tokenId,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _tournamentId, signature) returns (uint256 _betId) {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            require(
                tournaments[_tournamentId].status != true,
                "The tournament is over"
            );
            require(
                IERC721A(NFTBettingAddress).ownerOf(_tokenId[i]) == msg.sender,
                "You are not the owner of NFT"
            );
            require(
                History[_tokenId[i]] != true,
                "This Token have been Betted!"
            );
        }
        NFTBetting(NFTBettingAddress).lockToken(_tokenId);
        _BetIdCounter.increment();
        _betId = _BetIdCounter.current();
        Bet memory bet = Bet(_tournamentId, _tokenId, msg.sender);
        betters[_tournamentId].push(bet);
        better[_betId] = bet;
        addHistory(_tokenId);
        emit Betting(_betId, _tournamentId, msg.sender, _tokenId);
    }

    function addHistory(uint256[] memory _tokenId) private returns (bool) {
        
        for (uint256 i = 0; i < _tokenId.length; i++) {
            History[_tokenId[i]] = true;
        }
        for (uint256 i = 0; i < _tokenId.length; i++) {
            return History[_tokenId[i]];
        }
    }

    function checkHistory(uint256 _tokenId) public view returns (bool) {
        return History[_tokenId];
    }

    function cancel(uint256 _betId) external {
        require(better[_betId].Owner == msg.sender, "You are not the better");
        require(
            tournaments[better[_betId]._TournamentId].status != true,
            "The tournament is finished yet"
        );
        
        for (
            uint256 i = 0;
            i < betters[better[_betId]._TournamentId].length;
            i++
        ) {

             NFTBetting(NFTBettingAddress).unlockToken(
                betters[better[_betId]._TournamentId][i].TokenId
            );
            for (
                uint256 j = 0;
                j < betters[better[_betId]._TournamentId][i].TokenId.length;
                j++
            ) {
                History[
                    betters[better[_betId]._TournamentId][i].TokenId[j]
                ] = false;
            }
        }

        delete better[_betId];

        emit Cancel(_betId, better[_betId].TokenId);
    }

    // function sendBetWinner(
    //     Winner[] memory winners,
    //     address _tokenAddress
    // ) external onlyAdmin {
    //     for (uint256 i = 0; i < winners.length; i++) {
    //         for (uint256 j = 0; j < winners[i].tokenId.length; j++)
    //             IERC721A(_tokenAddress).safeTransferFrom(
    //                 msg.sender,
    //                 winners[i].winnerAddress,
    //                 winners[i].tokenId[j]
    //             );
    //     }
    // }

    function endTournament(
        uint256 _tournamentId
    ) external onlyAdmin {
        require(
            tournaments[_tournamentId].status != true,
            "The tournament is finished yet"
        );
        tournaments[_tournamentId].status = true;
        for (uint256 i = 0; i < betters[_tournamentId].length; i++) {
             NFTBetting(NFTBettingAddress).unlockToken(
                betters[_tournamentId][i].TokenId
            );
        }
        emit EndTournament(_tournamentId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
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
   * Cannot safely transfer to a contract that does not implement the
   * ERC721Receiver interface.
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

  /**
   * The `quantity` minted with ERC2309 exceeds the safety limit.
   */
  error MintERC2309QuantityExceedsLimit();

  /**
   * The `extraData` cannot be set on an unintialized ownership slot.
   */
  error OwnershipNotInitializedForExtraData();

  // =============================================================
  //                            STRUCTS
  // =============================================================

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  // function _lockToken(uint256[] memory tokenid) internal returns (bool);
  // function _unlockToken(uint256[] memory tokenid) internal returns (bool);

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
  ) external;

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

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
  ) external;

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
  function approve(address to, uint256 tokenId) external;

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

  // =============================================================
  //                           IERC2309
  // =============================================================

  /**
   * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
   * (inclusive) is transferred from `from` to `to`, as defined in the
   * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
   *
   * See {_mintERC2309} for more details.
   */
  event ConsecutiveTransfer(
    uint256 indexed fromTokenId,
    uint256 toTokenId,
    address indexed from,
    address indexed to
  );
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
pragma solidity ^0.8.4;

import "./IERC721A.sol";

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
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
contract ERC721A is IERC721A {
  // Reference type for token approval.

  struct TokenApprovalRef {
    address value;
  }

  // =============================================================
  //                           CONSTANTS
  // =============================================================

  // Mask of an entry in packed address data.
  uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

  // The bit position of `numberMinted` in packed address data.
  uint256 private constant _BITPOS_NUMBER_MINTED = 64;

  // The bit position of `numberBurned` in packed address data.
  uint256 private constant _BITPOS_NUMBER_BURNED = 128;

  // The bit position of `aux` in packed address data.
  uint256 private constant _BITPOS_AUX = 192;

  // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
  uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

  // The bit position of `startTimestamp` in packed ownership.
  uint256 private constant _BITPOS_START_TIMESTAMP = 160;

  // The bit mask of the `burned` bit in packed ownership.
  uint256 private constant _BITMASK_BURNED = 1 << 224;

  // The bit position of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

  // The bit mask of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

  // The bit position of `extraData` in packed ownership.
  uint256 private constant _BITPOS_EXTRA_DATA = 232;

  // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
  uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

  // The mask of the lower 160 bits for addresses.
  uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

  // The maximum `quantity` that can be minted with {_mintERC2309}.
  // This limit is to prevent overflows on the address data entries.
  // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
  // is required to cause an overflow, which is unrealistic.
  uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

  // The `Transfer` event signature is given by:
  // `keccak256(bytes("Transfer(address,address,uint256)"))`.
  bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

  // =============================================================
  //                            STORAGE
  // =============================================================

  // The next token ID to be minted.
  uint256 internal _currentIndex;

  // The number of tokens burned.
  uint256 private _burnCounter;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned.
  // See {_packedOwnershipOf} implementation for details.
  //
  // Bits Layout:
  // - [0..159]   `addr`
  // - [160..223] `startTimestamp`
  // - [224]      `burned`
  // - [225]      `nextInitialized`
  // - [232..255] `extraData`
  mapping(uint256 => uint256) internal _packedOwnerships;

  // Mapping owner address to address data.
  //
  // Bits Layout:
  // - [0..63]    `balance`
  // - [64..127]  `numberMinted`
  // - [128..191] `numberBurned`
  // - [192..255] `aux`
  mapping(address => uint256) internal _packedAddressData;

  // Mapping from token ID to approved address.
  mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  mapping(uint256 => bool) public lock;

  // =============================================================
  //                          CONSTRUCTOR
  // =============================================================

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _currentIndex = _startTokenId();
  }

  // =============================================================
  //                   TOKEN COUNTING OPERATIONS
  // =============================================================

  /**
   * @dev Returns the starting token ID.
   * To change the starting token ID, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev Returns the next token ID to be minted.
   */
  function _nextTokenId() internal view virtual returns (uint256) {
    return _currentIndex;
  }

  function _lockToken(uint256[] memory tokenid)
    internal
    virtual
    returns (bool)
  {
  
    for (uint256 i = 0; i < tokenid.length; i++) {
      lock[tokenid[i]] = true;
    }
    for (uint256 i = 0; i < tokenid.length; i++) {
      return lock[tokenid[i]];
    }
  }

  function _unlockToken(uint256[] memory tokenid)
    internal
    virtual
    returns (bool)
  {
    for (uint256 i = 0; i < tokenid.length; i++) {
      lock[tokenid[i]] = false;
    }
    for (uint256 i = 0; i < tokenid.length; i++) {
      return lock[tokenid[i]];
    }
  }

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId()` times.
    unchecked {
      return _currentIndex - _burnCounter - _startTokenId();
    }
  }

  /**
   * @dev Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view virtual returns (uint256) {
    // Counter underflow is impossible as `_currentIndex` does not decrement,
    // and it is initialized to `_startTokenId()`.
    unchecked {
      return _currentIndex - _startTokenId();
    }
  }

  /**
   * @dev Returns the total number of tokens burned.
   */
  function _totalBurned() internal view virtual returns (uint256) {
    return _burnCounter;
  }

  // =============================================================
  //                    ADDRESS DATA OPERATIONS
  // =============================================================

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    return
      (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
      _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    return
      (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
      _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
  }

  /**
   * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal virtual {
    uint256 packed = _packedAddressData[owner];
    uint256 auxCasted;
    // Cast `aux` with assembly to avoid redundant masking.
    assembly {
      auxCasted := aux
    }
    packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
    _packedAddressData[owner] = packed;
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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId)))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, it can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev Casts the address to uint256 without masking.
   */
  function _addressToUint256(address value)
    private
    pure
    returns (uint256 result)
  {
    assembly {
      result := value
    }
  }

  /**
   * @dev Casts the boolean to uint256 without branching.
   */
  function _boolToUint256(bool value) private pure returns (uint256 result) {
    assembly {
      result := value
    }
  }

  // =============================================================
  //                     OWNERSHIPS OPERATIONS
  // =============================================================

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  /**
   * @dev Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around over time.
   */
  function _ownershipOf(uint256 tokenId)
    internal
    view
    virtual
    returns (TokenOwnership memory)
  {
    return _unpackedOwnership(_packedOwnershipOf(tokenId));
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct at `index`.
   */
  function _ownershipAt(uint256 index)
    internal
    view
    virtual
    returns (TokenOwnership memory)
  {
    return _unpackedOwnership(_packedOwnerships[index]);
  }

  /**
   * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
   */
  function _initializeOwnershipAt(uint256 index) internal virtual {
    if (_packedOwnerships[index] == 0) {
      _packedOwnerships[index] = _packedOwnershipOf(index);
    }
  }

  /**
   * Returns the packed ownership data of `tokenId`.
   */
  function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256) {
    uint256 curr = tokenId;

    unchecked {
      if (_startTokenId() <= curr)
        if (curr < _currentIndex) {
          uint256 packed = _packedOwnerships[curr];
          // If not burned.
          if (packed & _BITMASK_BURNED == 0) {
            // Invariant:
            // There will always be an initialized ownership slot
            // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
            // before an unintialized ownership slot
            // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
            // Hence, `curr` will not underflow.
            //
            // We can directly compare the packed value.
            // If the address is zero, packed will be zero.
            while (packed == 0) {
              packed = _packedOwnerships[--curr];
            }
            return packed;
          }
        }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
   */
  function _unpackedOwnership(uint256 packed)
    private
    pure
    returns (TokenOwnership memory ownership)
  {
    ownership.addr = address(uint160(packed));
    ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    ownership.burned = packed & _BITMASK_BURNED != 0;
    ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
  }

  /**
   * @dev Packs ownership data into a single uint256.
   */
  function _packOwnershipData(address owner, uint256 flags)
    internal
    view
    returns (uint256 result)
  {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
    }
  }

  /**
   * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
   */
  function _nextInitializedFlag(uint256 quantity)
    private
    pure
    returns (uint256 result)
  {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
    }
  }

  // =============================================================
  //                      APPROVAL OPERATIONS
  // =============================================================

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
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);

    if (_msgSenderERC721A() != owner)
      if (!isApprovedForAll(owner, _msgSenderERC721A())) {
        revert ApprovalCallerNotOwnerNorApproved();
      }

    _tokenApprovals[tokenId].value = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId].value;
  }

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
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    if (operator == _msgSenderERC721A()) revert ApproveToCaller();

    _operatorApprovals[_msgSenderERC721A()][operator] = approved;
    emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted. See {_mint}.
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return
      _startTokenId() <= tokenId &&
      tokenId < _currentIndex && // If within bounds,
      _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
  }

  /**
   * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
   */
  function _isSenderApprovedOrOwner(
    address approvedAddress,
    address owner,
    address msgSender
  ) internal pure returns (bool result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      // `msgSender == owner || msgSender == approvedAddress`.
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  /**
   * @dev Returns the storage slot and value for the approved address of `tokenId`.
   */
  function _getApprovedSlotAndAddress(uint256 tokenId)
    internal
    view
    returns (uint256 approvedAddressSlot, address approvedAddress)
  {
    TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
    // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }

  // =============================================================
  //                      TRANSFER OPERATIONS
  // =============================================================

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) public virtual override {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
    require(lock[tokenId] != true, "token have been locked!");

    if (address(uint160(prevOwnershipPacked)) != from)
      revert TransferFromIncorrectOwner();

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    // The nested ifs save around 20+ gas over a compound boolean condition.
    if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
      if (!isApprovedForAll(from, _msgSenderERC721A()))
        revert TransferCallerNotOwnerNorApproved();

    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly increment and decrement the balances.
      --_packedAddressData[from]; // Updates: `balance -= 1`.
      ++_packedAddressData[to]; // Updates: `balance += 1`.

      // Updates:
      // - `address` to the next owner.
      // - `startTimestamp` to the timestamp of transfering.
      // - `burned` to `false`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        to,
        _BITMASK_NEXT_INITIALIZED |
          _nextExtraData(from, to, prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != _currentIndex) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    require(lock[tokenId] != true, "token have been locked!");
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(lock[tokenId] != true, "token have been locked!");
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert TransferToNonERC721ReceiverImplementer();
      }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token IDs
   * are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token IDs
   * have been transferred. This includes minting.
   * And also called after one token has been burned.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * `from` - Previous owner of the given token ID.
   * `to` - Target address that will receive the token.
   * `tokenId` - Token ID to be transferred.
   * `_data` - Optional data to send along with the call.
   *
   * Returns whether the call correctly returned the expected magic value.
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try
      ERC721A__IERC721Receiver(to).onERC721Received(
        _msgSenderERC721A(),
        from,
        tokenId,
        _data
      )
    returns (bytes4 retval) {
      return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
  function _mint(address to, uint256 quantity) internal virtual {
    uint256 startTokenId = _currentIndex;
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // `balance` and `numberMinted` have a maximum limit of 2**64.
    // `tokenId` has a maximum limit of 2**256.
    unchecked {
      // Updates:
      // - `balance += quantity`.
      // - `numberMinted += quantity`.
      //
      // We can directly add to the `balance` and `numberMinted`.
      _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      _packedOwnerships[startTokenId] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      // Use assembly to loop and emit the `Transfer` event for gas savings.
      // The duplicated `log4` removes an extra check and reduces stack juggling.
      // The assembly, together with the surrounding Solidity code, have been
      // delicately arranged to nudge the compiler into producing optimized opcodes.
      assembly {
        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        toMasked := and(to, _BITMASK_ADDRESS)
        // Emit the `Transfer` event.
        log4(
          0, // Start of data (0, since no data).
          0, // End of data (0, since no data).
          _TRANSFER_EVENT_SIGNATURE, // Signature.
          0, // `address(0)`.
          toMasked, // `to`.
          startTokenId // `tokenId`.
        )

        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          // Emit the `Transfer` event. Similar to above.
          log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
        }
      }
      if (toMasked == 0) revert MintToZeroAddress();

      _currentIndex = end;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * This function is intended for efficient minting only during contract creation.
   *
   * It emits only one {ConsecutiveTransfer} as defined in
   * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
   * instead of a sequence of {Transfer} event(s).
   *
   * Calling this function outside of contract creation WILL make your contract
   * non-compliant with the ERC721 standard.
   * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
   * {ConsecutiveTransfer} event is only permissible during contract creation.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {ConsecutiveTransfer} event.
   */
  function _mintERC2309(address to, uint256 quantity) internal virtual {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();
    if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
      revert MintERC2309QuantityExceedsLimit();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
    unchecked {
      // Updates:
      // - `balance += quantity`.
      // - `numberMinted += quantity`.
      //
      // We can directly add to the `balance` and `numberMinted`.
      _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      _packedOwnerships[startTokenId] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      emit ConsecutiveTransfer(
        startTokenId,
        startTokenId + quantity - 1,
        address(0),
        to
      );

      _currentIndex = startTokenId + quantity;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * See {_mint}.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal virtual {
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = _currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
          }
        } while (index < end);
        // Reentrancy protection.
        if (_currentIndex != end) revert();
      }
    }
  }

  /**
   * @dev Equivalent to `_safeMint(to, quantity, '')`.
   */
  function _safeMint(address to, uint256 quantity) internal virtual {
    _safeMint(to, quantity, "");
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  /**
   * @dev Equivalent to `_burn(tokenId, false)`.
   */
  function _burn(uint256 tokenId) internal virtual {
    _burn(tokenId, false);
  }

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
  function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    address from = address(uint160(prevOwnershipPacked));

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      // The nested ifs save around 20+ gas over a compound boolean condition.
      if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
        if (!isApprovedForAll(from, _msgSenderERC721A()))
          revert TransferCallerNotOwnerNorApproved();
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // Updates:
      // - `balance -= 1`.
      // - `numberBurned += 1`.
      //
      // We can directly decrement the balance, and increment the number burned.
      // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
      _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

      // Updates:
      // - `address` to the last owner.
      // - `startTimestamp` to the timestamp of burning.
      // - `burned` to `true`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
          _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != _currentIndex) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
  }

  // =============================================================
  //                     EXTRA DATA OPERATIONS
  // =============================================================

  /**
   * @dev Directly sets the extra data for the ownership data `index`.
   */
  function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
    uint256 packed = _packedOwnerships[index];
    if (packed == 0) revert OwnershipNotInitializedForExtraData();
    uint256 extraDataCasted;
    // Cast `extraData` with assembly to avoid redundant masking.
    assembly {
      extraDataCasted := extraData
    }
    packed =
      (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
      (extraDataCasted << _BITPOS_EXTRA_DATA);
    _packedOwnerships[index] = packed;
  }

  /**
   * @dev Called during each token transfer to set the 24bit `extraData` field.
   * Intended to be overridden by the cosumer contract.
   *
   * `previousExtraData` - the value of `extraData` before transfer.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _extraData(
    address from,
    address to,
    uint24 previousExtraData
  ) internal view virtual returns (uint24) {}

  /**
   * @dev Returns the next extra data for the packed ownership data.
   * The returned result is shifted into position.
   */
  function _nextExtraData(
    address from,
    address to,
    uint256 prevOwnershipPacked
  ) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
    return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
  }

  // =============================================================
  //                       OTHER OPERATIONS
  // =============================================================

  /**
   * @dev Returns the message sender (defaults to `msg.sender`).
   *
   * If you are writing GSN compatible contracts, you need to override this function.
   */
  function _msgSenderERC721A() internal view virtual returns (address) {
    return msg.sender;
  }

  /**
   * @dev Converts a uint256 to its ASCII string decimal representation.
   */
  function _toString(uint256 value)
    internal
    pure
    virtual
    returns (string memory str)
  {
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
pragma solidity ^0.8.4;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity ^0.8.4;

//import "./GokuMock.sol";
import "../libraries/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/ECDSA.sol";
import "../libraries/Context.sol";
import "../libraries/Counters.sol";
import "../interfaces/ERC721A/ERC721A.sol";
import "../interfaces/ERC721A/IERC721A.sol";
import "../interfaces/ERC721A/ERC721ABurnable.sol";
import "../interfaces/ERC721A/ERC721AQueryable.sol";

contract NFTBetting is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable {
  constructor() ERC721A("NFT_BETTING", "BET") {}
  using ECDSA for bytes32;
  receive() external payable {}

  string private _baseURIExtended;
  uint256 public price;
  address public bettingAddress;
  uint256 public quantityUserMinted = 0;
  uint256[] Tokens;
  uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

  mapping(address => mapping(uint256 => bool)) seenNonces;
  mapping(uint256 => uint256) prices;
  mapping(uint256 => uint256[]) public orders;

  event AdminMint(address caller, uint256 quantity, uint256 totalSupply);
  event UserMint(address caller, uint256 quantity, uint256 orderId, uint256[] tokenId);
  event Withdraw(address caller, uint256 amount);

  modifier verifySignature(
    uint256 nonce,
    uint256 orderId,
    uint256 timestamp,
    uint256 quantity,
    bytes memory signature
  ) {

    bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                nonce,
                orderId,
                quantity
            )
        );
    // This recreates the message hash that was signed on the client.
    bytes32 messageHash = hash.toEthSignedMessageHash();
    // Verify that the message's signer is the owner of the order
    require(messageHash.recover(signature) == owner(), "Invalid signature");
    require(!seenNonces[msg.sender][nonce], "Used nonce");
    require(timestamp >= block.timestamp, "signature expired");
    seenNonces[msg.sender][nonce] = true;
    _;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function setPrice(uint256 _price) public onlyOwner {
    require(_price > 0, "PRICE MUST BE GREATER THAN 0");
    price = _price;
  }

  function getOwnershipAt(uint256 index)
    public
    view
    returns (TokenOwnership memory)
  {
    return _ownershipAt(index);
  }

  function totalMinted() public view onlyOwner returns (uint256) {
    return _totalMinted();
  }

  function totalBurned() public view onlyOwner returns (uint256) {
    return _totalBurned();
  }

  function numberBurned(address owner) public view onlyOwner returns (uint256) {
    return _numberBurned(owner);
  }

  function numberMinted(address owner) public view onlyOwner returns (uint256) {
    return _numberMinted(owner);
  }

  function nextTokenId() public view returns (uint256) {
    return _nextTokenId();
  }

  // function getAux(address owner) public view onlyOwner returns (uint64) {
  //   return _getAux(owner);
  // }

  // function setAux(address owner, uint64 aux) public onlyOwner {
  //   _setAux(owner, aux);
  // }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function setBettingAddress(address _bettingAddress) public onlyOwner {
    require(_bettingAddress != address(0), "INVALID BETTING ADDRESS.");
    bettingAddress = _bettingAddress;
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  function userMint(uint256 quantity, uint256 nonce, uint256 timestamp, uint256 orderId, bytes memory signature) 
  verifySignature(nonce, orderId, timestamp, quantity, signature) 
  public payable {
    require(quantity > 0, "QUANTITY MUST BE GREATER THAN 0");
    require(price > 0, "ADMIN NOT SET PRICE YET");
    require(balanceOf(address(this)) >= quantity, "QUANTITY IS MORE THAN POOL");
    require(
      msg.value >= quantity * price * (10**13),
      "BALANCE TO MINT INSUFFICIENT"
    );
    TransferHelper.safeTransferETH(
      address(this),
      quantity * (price / 100000) * (10**18)
    );

    for (
      uint256 i = quantityUserMinted;
      i < (quantityUserMinted + quantity);
      i++
    ) {
      transferToken(address(this), msg.sender, i);
      orders[orderId].push(i);
    }

    quantityUserMinted += quantity;
    emit UserMint(msg.sender, quantity, orderId, orders[orderId]);

   
  }

   function getOrder(uint256 _orderId) public view returns(uint256[] memory) {
  
    return orders[_orderId];
    
  }  

  // function userMint(uint256 quantity, uint256 price) public payable {
  //     require(
  //         price == 1000 || price == 3000 || price == 5000,
  //         "INVALID PRICE"
  //     );
  //     require(
  //         msg.value >= quantity * price * (10 ** 13),
  //         "BALANCE TO MINT INSUFFICIENT"
  //     );
  //     TransferHelper.safeTransferETH(
  //         address(this),
  //         quantity * price * (10 ** 13)
  //     );
  //     for (uint256 i = nextTokenId(); i < (nextTokenId() + quantity); i++) {
  //         prices[i] = price;
  //     }
  //     _safeMint(msg.sender, quantity);
  // }

  // function mint(address to, uint256 quantity) private {
  //     _mint(to, quantity);
  // }

  function mint(uint256 quantity) public onlyOwner {
    for (uint256 i = nextTokenId(); i < (nextTokenId() + quantity); i++) {
      prices[i] = price;
    }
    _mint(address(this), quantity);
    uint256 totalSupply = totalSupply(); 
    emit AdminMint(msg.sender, quantity, totalSupply);
  
  }

  function safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) public onlyOwner {
    _safeMint(to, quantity, _data);
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount > 0, "Amount must be greater than 0");

    address _owner = owner();
    (bool sent, ) = _owner.call{ value: amount }("");
    require(sent, "Failed to send Ether");
    emit Withdraw(msg.sender, amount);
  }

  function safeMint(address to, uint256 quantity) public onlyOwner {
    _safeMint(to, quantity);
  }

  function lockToken(uint256[] memory tokenid) public {
    require(msg.sender == bettingAddress, "You not allowed to lock token");
    _lockToken(tokenid);
  }

  function unlockToken(uint256[] memory tokenid) public {
    require(msg.sender == bettingAddress, "You not allowed to lock token");
    _unlockToken(tokenid);
  }

  function getPriceOfToken(uint256 tokenId) public view returns (uint256) {
    return prices[tokenId];
  }

  function burn(uint256 tokenId, bool approvalCheck) public onlyOwner {
    _burn(tokenId, approvalCheck);
  }

  function toString(uint256 x) public pure returns (string memory) {
    return _toString(x);
  }

  function getOwnershipOf(uint256 index)
    public
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(index);
  }

  function initializeOwnershipAt(uint256 index) public onlyOwner {
    _initializeOwnershipAt(index);
  }

  function random(uint256 number) public view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
        )
      ) % number;
  }

  function transferToken(
    address from,
    address to,
    uint256 tokenId
  ) private {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
    require(lock[tokenId] != true, "token have been locked!");

    if (address(uint160(prevOwnershipPacked)) != from)
      revert TransferFromIncorrectOwner();

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly increment and decrement the balances.
      --_packedAddressData[from]; // Updates: `balance -= 1`.
      ++_packedAddressData[to]; // Updates: `balance += 1`.

      // Updates:
      // - `address` to the next owner.
      // - `startTimestamp` to the timestamp of transfering.
      // - `burned` to `false`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        to,
        _BITMASK_NEXT_INITIALIZED |
          _nextExtraData(from, to, prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != _currentIndex) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: APPROVE_FAILED"
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: TRANSFER_FAILED"
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: TRANSFER_FROM_FAILED"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721ABurnable.sol";
/**
 * @title ERC721A Burnable Token
 * @dev ERC721A Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721AQueryable.sol";
/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721A.sol";
/**
 * @dev Interface of an ERC721ABurnable compliant contract.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721A.sol";
/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}