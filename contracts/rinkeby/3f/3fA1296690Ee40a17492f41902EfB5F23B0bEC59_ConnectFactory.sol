// SPDX-License-Identifier: MIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                  ___           ___           ___           ___           ___           ___                                    ///
//       ___        /  /\         /  /\         /__/\         /__/\         /  /\         /  /\          ___                    ///
//      /  /\      /  /:/        /  /::\        \  \:\        \  \:\       /  /:/_       /  /:/         /  /\                  ///
//     /  /:/     /  /:/        /  /:/\:\        \  \:\        \  \:\     /  /:/ /\     /  /:/         /  /:/                 ///
//    /  /:/     /  /:/  ___   /  /:/  \:\   _____\__\:\   _____\__\:\   /  /:/ /:/_   /  /:/  ___    /  /:/                 ///
//   /  /::\    /__/:/  /  /\ /__/:/ \__\:\ /__/::::::::\ /__/::::::::\ /__/:/ /:/ /\ /__/:/  /  /\  /  /::\                ///
//  /__/:/\:\   \  \:\ /  /:/ \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\~~\~~\/ \  \:\/:/ /:/ \  \:\ /  /:/ /__/:/\:\              ///
//  \__\/  \:\   \  \:\  /:/   \  \:\  /:/   \  \:\  ~~~   \  \:\  ~~~   \  \::/ /:/   \  \:\  /:/  \__\/  \:\            ///
//       \  \:\   \  \:\/:/     \  \:\/:/     \  \:\        \  \:\        \  \:\/:/     \  \:\/:/        \  \:\          ///
//        \__\/    \  \::/       \  \::/       \  \:\        \  \:\        \  \::/       \  \::/          \__\/         ///
//                  \__\/         \__\/         \__\/         \__\/         \__\/         \__\/                        ///
//                                                                                                                    ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;
import './ConnectFactory.sol';
import './interfaces/IConnectFactory.sol';

/// @title ConnectRegistry - for managing all platform activities
/// @author Andrew Miracle
/// @notice We use this to create wrapped tokens, while keeping track of their paired NFTs

contract ConnectRegistry {
    /// @notice Maintain a mapping of all wrapped contracts to their original
    /// @dev Mapping of the original NFT Address (Factory) to the Wrapped Version
    mapping(address => address) public pairs;

    // Fee to charge for listing NFT on the marketplace
    uint256 public feeForCreation;

    // An array to track all the NFTs we have in the Registry
    address[] public registry;

    // We have successfully wrapped an NFT with a Connect Implemented version and track how many in registry
    event PairCreated(address indexed factory, address indexed deployer, address indexed pair, uint256);

    constructor(uint256 feeForCreation_) {
        feeForCreation = feeForCreation_;
    }

    function createWrappedPair(address factory_) external returns (address pair) {
      
        // Check that this request can pass
        checkCanWrap(factory_, msg.sender);

        // Create the Wrapped NFT and retrieve the address using CREATE2
        bytes memory bytecode = type(ConnectFactory).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(factory_, msg.sender));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(pair)) { revert(0, 0) }
        }

        // IConnectFactory(pair).initialize(token0, token1);
        IConnectFactory(pair).initialize(factory_);

        // Perform state updates
        pairs[factory_] = pair;
        registry.push(pair);


        emit PairCreated(factory_, msg.sender, pair, registry.length);
    }



    //////////////////////////////////////////////////////////////////////////////////
    //// CHECKS AND EFFECTS INTERACTION                                           ////
    //////////////////////////////////////////////////////////////////////////////////

    function checkCanWrap(address factory, address owner) private view {
        require(factory != owner, 'T.C: IDENTICAL_ADDRESSES');
        require(factory != address(0), 'T.C: ZERO_ADDRESS');
        require(pairs[factory] == address(0), 'T.C: PAIR_EXISTS'); // single check is sufficient

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @dev Required IConnectFactory inherits from the interface of an ERC721 compliant contract
 * that includes Metadata without requiring the approve call methods
 */
interface IConnectFactory is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function initialize(address factory) external;

    /**
     * ERC-721 Non-Fungible Token Standard, optional metadata extension
     * @dev See https://eips.ethereum.org/EIPS/eip-721
     */

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                   ___           ___           ___           ___           ___           ___                                   ///
//       ___        /  /\         /  /\         /__/\         /__/\         /  /\         /  /\          ___                    ///
//      /  /\      /  /:/        /  /::\        \  \:\        \  \:\       /  /:/_       /  /:/         /  /\                  ///
//     /  /:/     /  /:/        /  /:/\:\        \  \:\        \  \:\     /  /:/ /\     /  /:/         /  /:/                 ///
//    /  /:/     /  /:/  ___   /  /:/  \:\   _____\__\:\   _____\__\:\   /  /:/ /:/_   /  /:/  ___    /  /:/                 ///
//   /  /::\    /__/:/  /  /\ /__/:/ \__\:\ /__/::::::::\ /__/::::::::\ /__/:/ /:/ /\ /__/:/  /  /\  /  /::\                ///
//  /__/:/\:\   \  \:\ /  /:/ \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\~~\~~\/ \  \:\/:/ /:/ \  \:\ /  /:/ /__/:/\:\              ///
//  \__\/  \:\   \  \:\  /:/   \  \:\  /:/   \  \:\  ~~~   \  \:\  ~~~   \  \::/ /:/   \  \:\  /:/  \__\/  \:\            ///
//       \  \:\   \  \:\/:/     \  \:\/:/     \  \:\        \  \:\        \  \:\/:/     \  \:\/:/        \  \:\          ///
//        \__\/    \  \::/       \  \::/       \  \:\        \  \:\        \  \::/       \  \::/          \__\/         ///
//                  \__\/         \__\/         \__\/         \__\/         \__\/         \__\/                        ///
//                                                                                                                    ///
// The T-connect Factory Contract that acts as a Lien                                                                ///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

// import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/* Internally Inherited Interfaces */
import './interfaces/IConnectFactory.sol';

error BalanceQueryForZeroAddress();
error DeployerNotRegistryContract();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 * @dev https://github.com/kohshiba/ERC-X/blob/master/contracts/ERCX/Contract/ERCX.sol
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ConnectFactory is Context, ERC165, IConnectFactory {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // We list out the NFT standards we intend to support
    enum ContractInterface {
        E721,
        E1155
    }

    // We use this configuration to wrap the Token from the factory
    // Struct includes the parent NFT, the parent TokenID and lendID is the tokenID generated internally
    struct RegisterLendConfig {
        address factory;
        uint256 tokenId;
        uint256 lendId;
    }

    struct CallData {
        uint256 left;
        uint256 right;
        ContractInterface eipInterface;
        address nftAddress;
        uint256 tokenID;
        uint256 lendAmount;
        uint8 maxRentDuration;
        bytes4 dailyRentPrice;
        uint256 lendingID;
        uint256 rentingID;
        uint8 rentDuration;
        uint256 rentAmount;
        address paymentToken;
    }

    struct RentRequest {
        address payable renterAddress;
        uint8 rentDuration;
        uint32 rentedAt;
        uint16 rentAmount;
    }

    struct LendRequest {
        // config
        address lender;
        uint256 tokenId;
        address borrower;
        // state flags
        bool isEscrowed;
        bool isBorrowed;
        // window
        uint256 start;
        uint256 end;
        uint256 periodInSecs;
        uint256 depositInWei;
        // Calldata payload
        uint8 maxRentDuration;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    mapping(uint256 => LendRequest) public tokensAvailableToLoan;

    mapping(address => uint256[]) public lenderToTokenId;

    // So we can enumerate them
    uint256 public totalTokens = 0;
    mapping(uint256 => uint256) public indexToTokenId;

    // Use this mapping to track payment stream when we implement Sablier
    // mapping(uint256 => uint256) public tokenIdToStreamId;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    uint256 private constant SECONDS_IN_DAY = 86400;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // The Parent NFT contract we derived this from
    IERC721Metadata public factory;

    // The Registry Contract is usually the deployer
    address public deployer;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor() //  address factory_
    {
        deployer = msg.sender;
        //     factory = IERC721Metadata(factory_);
        //     _currentIndex = _startTokenId();
    }

    /// Call this only once at time of deployment
    function initialize(address factory_) external override {
        if (msg.sender != deployer) revert DeployerNotRegistryContract();
        factory = IERC721Metadata(factory_);
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    // function registerERC721Token(ERC721Token calldata _erc721token) public returns (uint256 _hash) {
    //     _hash = _tokenHash(_erc721token);
    //     if (address(tokens[_hash].erc721Contract) == address(0)) {
    //         tokens[_hash] = _erc721token;
    //         emit RegisterToken(_erc721token);
    //     }
    // }

    function _tokenHash(address tokenId_) internal virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(factory, tokenId_)));
    }

    /// Enable Token for lending is equivalent to minting a token

    /// TODO create a proxy method to allow call on original NFT by bytecode/method args - dynamic lookup?
    /// @notice Enable a token for lending by creating a wrap on this contract
    /// @dev we verify the user is ownerOf the tokenId then wrap an equivalent in this ERC-721
    function enableTokenForLending(
        uint256 _tokenId,
        uint256 _periodInSecs,
        uint256 _depositInWei
    ) public returns (bool) {
        // Validate input
        require(_depositInWei > 0, 'Must have a deposit');
        require(_periodInSecs > 0, 'Must have a period in secs');

        require(tokensAvailableToLoan[_tokenId].tokenId == 0, 'Token already placed for sale');

        // Validate caller owns it
        require(factory.ownerOf(_tokenId) == msg.sender, 'Caller does not own the NFT');

        // Setup Loan
        tokensAvailableToLoan[_tokenId] = LendRequest({
            tokenId: _tokenId,
            lender: msg.sender,
            borrower: address(0x0),
            isEscrowed: true,
            isBorrowed: false,
            maxRentDuration: 0,
            start: 0,
            end: 0,
            periodInSecs: _periodInSecs,
            depositInWei: _depositInWei
        });

        // Escrow NFT into the Loan Shark Contract
        factory.safeTransferFrom(msg.sender, address(this), _tokenId);
        require(isTokenEscrowed(_tokenId), 'Token not correctly escrowed');

        // Setup simple enumeration
        indexToTokenId[totalTokens] = _tokenId;
        totalTokens = totalTokens + 1;

        // setup simple lender mapping
        lenderToTokenId[msg.sender].push(_tokenId);

        return true;
    }

    /*
     * Close any outstanding un-borrowed NFT loans
     * Send the NFT back to the original lender
     */
    function cancelLoan(uint256 _tokenId) public returns (bool) {
        require(tokensAvailableToLoan[_tokenId].tokenId != 0, 'Token not for sale');

        LendRequest storage loan = tokensAvailableToLoan[_tokenId];
        require(loan.isEscrowed, 'Token not escrowed');
        require(!loan.isBorrowed, 'Token already borrowed');
        require(loan.borrower != address(0), 'Token already got a borrower');

        address originalLender = loan.lender;

        delete tokensAvailableToLoan[_tokenId];

        // Send the loan back to the original lender
        factory.safeTransferFrom(address(this), originalLender, _tokenId);
        require(isTokenOwnedBy(_tokenId, originalLender), 'Token not returned successfully');

        return true;
    }

    function borrowToken(uint256 _tokenId) public returns (bool) {
        require(tokensAvailableToLoan[_tokenId].tokenId != 0, 'Token not for sale');

        LendRequest storage loan = tokensAvailableToLoan[_tokenId];
        require(loan.isEscrowed, 'Token not escrowed');
        require(!loan.isBorrowed, 'Token already borrowed');
        require(loan.borrower == address(0), 'Token already got a borrower');

        // sudo transfer this NFT to the new owner
        loan.borrower = msg.sender;
        loan.isBorrowed = true;

        loan.start = block.timestamp + 60;
        loan.end = loan.start + loan.periodInSecs;

        // deposit here in escrow to set up stream
        // paymentToken.transferFrom(msg.sender, address(this), loan.depositInWei);

        // this will pull the escrowed amount into the stream
        // uint256 streamId = stream.createStream(
        //     loan.lender,
        //     loan.depositInWei,
        //     address(paymentToken),
        //     loan.start,
        //     loan.end
        // );

        // tokenIdToStreamId[_tokenId] = streamId;
        return true;
    }

    function returnBorrowedNft(uint256 _tokenId) public returns (bool) {
        require(tokensAvailableToLoan[_tokenId].tokenId != 0, 'Token not for sale');

        LendRequest storage loan = tokensAvailableToLoan[_tokenId];
        require(loan.isEscrowed, 'Token not escrowed');
        require(loan.isBorrowed, 'Token not borrowed');
        require(loan.borrower == msg.sender, 'Token not borrowed by caller');

        // sudo transfer this NFT back to the escrow
        loan.borrower = address(0);
        loan.isBorrowed = false;

        // stream.cancelStream(tokenIdToStreamId[_tokenId]);

        // delete tokenIdToStreamId[_tokenId];

        return true;
    }

    function clawBackNft(uint256 _tokenId) public view {
        require(tokensAvailableToLoan[_tokenId].tokenId != 0, 'Token not for sale');

        // only allow after loan has expired
        // take back ownership from the borrower
        // reset loan state
        // penalise the borrower in some form?
    }

    /////////////////////
    // Query utilities //
    /////////////////////

    function getLoanDetails(uint256 _tokenId)
        public
        view
        returns (
            address lender,
            address borrower,
            bool isEscrowed,
            bool isBorrowed,
            uint256 start,
            uint256 end,
            uint256 depositInWei
        )
    {
        LendRequest memory loan = tokensAvailableToLoan[_tokenId];
        return (loan.lender, loan.borrower, loan.isEscrowed, loan.isBorrowed, loan.start, loan.end, loan.depositInWei);
    }

    function cancel(uint256 tokenId_) public returns (bool) {
        // uint256 streamId = tokenIdToStreamId[_tokenId];
        // require(streamId > 0, 'Must have a stream');

        LendRequest memory loan = tokensAvailableToLoan[tokenId_];
        require(msg.sender == loan.lender, 'Must be lender');

        // stream.cancelStream(streamId);
        //        safeTransferFrom(loan.borrower, loan.lender, _tokenId);

        // return paymentToken.transfer(loan.borrower, paymentToken.balanceOf(address(this)));
        return true;
    }

    function getRemainingTimeLeftForLoan(uint256 _tokenId) public view returns (uint256) {
        // uint256 streamId = tokenIdToStreamId[_tokenId];
        // require(streamId > 0, 'Must have a stream');

        LendRequest memory loan = tokensAvailableToLoan[_tokenId];

        if (block.timestamp <= loan.start) return loan.end - loan.start;
        if (block.timestamp > loan.end) return 0;

        return 0;

        // return loan.end - stream.deltaOf(streamId);
    }

    function withdraw(uint256 _tokenId) public returns (bool) {
        // uint256 streamId = tokenIdToStreamId[_tokenId];
        // require(streamId > 0, 'Must have a stream');

        LendRequest memory loan = tokensAvailableToLoan[_tokenId];
        require(msg.sender == loan.lender, 'Must be lender');

        clawBackNft(_tokenId);
        // return stream.withdrawFromStream(streamId, stream.balanceOf(streamId, loan.lender));

        return true;
    }

    ////////////////////
    // Internal utils //
    ////////////////////

    function getTokenIdForIndex(uint256 _index) public view returns (uint256) {
        return indexToTokenId[_index];
    }

    function getTokensLenderIsBorrowing(address _lender) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = lenderToTokenId[_lender];
        return tokenIds;
    }

    /// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/utils/ERC721Holder.sol
    /// @dev taking ownership of the NFT via callback confirmation
    /// @return bytes34 of the Callback Selector
    function onERC721Received() public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function isTokenEscrowed(uint256 tokenId_) public view returns (bool) {
        return isTokenOwnedBy(tokenId_, address(this));
    }

    function isTokenOwnedBy(uint256 _tokenId, address _owner) public view returns (bool) {
        return IERC721Metadata(factory).ownerOf(_tokenId) == _owner;
    }

    ////////////////////////////////////////
    // Overridden IERC721Metadata methods //
    ////////////////////////////////////////

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     * We override this and call the parent contract to get name
     */

    function name() public view virtual override returns (string memory) {
        return factory.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     * We override this to get the symbol from the factory
     */
    function symbol() public view virtual override returns (string memory) {
        return factory.symbol();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Override to get token URI from factory
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        if (!_exists(tokenId_)) revert URIQueryForNonexistentToken();
        /// TODO need to unpack byte32 TokenId to retrieve uint tokenId value

        return factory.tokenURI(tokenId_);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        // _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
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
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        // _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    //// CHECKS AND EFFECTS INTERACTION                                           ////
    //////////////////////////////////////////////////////////////////////////////////

    function isPastReturnDate(RentRequest memory renting, uint256 nowTime) private pure returns (bool) {
        require(nowTime > renting.rentedAt, 'ReNFT::now before rented');
        return nowTime - renting.rentedAt > renting.rentDuration * SECONDS_IN_DAY;
    }

    function checkIsNotZeroAddr(address addr) private pure {
        require(addr != address(0), 'T.C::zero address');
    }

    function checkIsLendable(CallData memory cd) private pure {
        require(cd.lendAmount > 0, 'T.C::lend amount is zero');
        require(cd.lendAmount <= type(uint16).max, 'T.C::not uint16');
        require(cd.maxRentDuration > 0, 'T.C::duration is zero');
        require(cd.maxRentDuration <= type(uint8).max, 'T.C::not uint8');
        require(uint32(cd.dailyRentPrice) > 0, 'T.C::rent price is zero');
    }

    function checkIsRentable(
        LendRequest memory lending,
        CallData memory cd,
        address msgSender
    ) private pure {
        require(msgSender != lending.lender, 'T.C::cant rent own nft');
        require(cd.rentDuration <= type(uint8).max, 'T.C::not uint8');
        require(cd.rentDuration > 0, 'T.C::duration is zero');
        require(cd.rentAmount <= type(uint16).max, 'T.C::not uint16');
        require(cd.rentAmount > 0, 'T.C::rentAmount is zero');
        require(cd.rentDuration <= lending.maxRentDuration, 'T.C::rent duration exceeds allowed max');
    }

    function checkIsReturnable(
        RentRequest memory renting,
        address msgSender,
        uint256 blockTimestamp
    ) private pure {
        require(renting.renterAddress == msgSender, 'T.C::not renter');
        require(!isPastReturnDate(renting, blockTimestamp), 'T.C::past return date');
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}