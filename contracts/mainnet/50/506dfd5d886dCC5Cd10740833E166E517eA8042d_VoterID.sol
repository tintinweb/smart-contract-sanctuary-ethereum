/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IVoterID {
    /**
        @notice Minting function
    */
    function createIdentityFor(address newId, uint tokenId, string calldata uri) external;

    /**
        @notice Who has the authority to override metadata uri
    */
    function owner() external view returns (address);

    /**
        @notice How many of these things exist?
    */
    function totalSupply() external view returns (uint);
}

/// @title A slightly modified enumerable, metadataed NFT contract, compatible with MerkleIdentity contract
/// @author metapriest, adrian.wachel, marek.babiarz, radoslaw.gorecki
/// @dev This contract uses no subclassing to make it easier to read and reason about
/// @dev This contract conforms to ERC721 and ERC165 but not ERC1155 because it's a crappy standard :P
contract VoterID is IVoterID {

    // mapping from tokenId to owner of that tokenId
    mapping (uint => address) public owners;
    // mapping from address to amount of NFTs they own
    mapping (address => uint) public balances;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) public operatorApprovals;
    // weird single-address-per-token-id mapping (why not just use operatorApprovals??)
    mapping (uint => address) public tokenApprovals;

    // forward and backward mappings used for enumerable standard
    // owner -> array of tokens owned...  ownershipMapIndexToToken[owner][index] = tokenNumber
    // owner -> array of tokens owned...  ownershipMapTokenToIndex[owner][tokenNumber] = index
    mapping (address => mapping (uint => uint)) public ownershipMapIndexToToken;
    mapping (address => mapping (uint => uint)) public ownershipMapTokenToIndex;

    // array-like map of all tokens in existence #enumeration
    mapping (uint => uint) public allTokens;

    // tokenId -> uri ... typically ipfs://...
    mapping (uint => string) public uriMap;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    string _name;
    string _symbol;

    // count the number of NFTs minted
    uint public numIdentities;

    // owner is a special name in the OpenZeppelin standard that opensea annoyingly expects for their management page
    address public _owner_;
    // minter has the sole, permanent authority to mint identities, in practice this will be a contract
    address public _minter;

    event OwnerUpdated(address oldOwner, address newOwner);
    event IdentityCreated(address indexed owner, uint indexed token);


    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    error TokenAlreadyExists(uint tokenId);
    error OnlyMinter(address notMinter);
    error OnlyOwner(address notOwner);
    error InvalidToken(uint tokenId);
    error InvalidIndex(uint tokenIndex);
    error ZeroAddress();
    error TokenOwnershipRequired(uint tokenId, address notOwner);
    error UnauthorizedApproval(uint tokenId, address unauthorized);
    error SelfApproval(uint tokenId, address owner);
    error NFTUnreceivable(address receiver);
    error UnapprovedTransfer(uint tokenId, address notApproved);

    /// @notice Whoever deploys the contract determines the name, symbol and owner. Minter should be MerkleIdentity contract
    /// @dev names are misspelled on purpose because we already have owners and _owner_ and _name and...
    /// @param ooner the owner of this contract
    /// @param minter address (MerkleIdentity contract) that can mint NFTs in this series
    /// @param nomen name of the NFT series
    /// @param symbowl symbol for the NFT series
    constructor(address ooner, address minter, string memory nomen, string memory symbowl) {
        _owner_ = ooner;
        // we set it here with no resetting allowed so we cannot commit to NFTs and then reset
        _minter = minter;
        _name = nomen;
        _symbol = symbowl;
    }

    /// @notice Create a new NFT in this series, with the given tokenId and uri
    /// @dev All permissions around minting should be done thru MerkleIdentity and it's associate gates
    /// @dev Only the minter contract can call this, and duplicate tokenIds are not allowed
    /// @param thisOwner the owner of this particular NFT, not the owner of the contract
    /// @param thisToken the tokenId that the newly NFT will have
    /// @param uri the metadata string that this NFT will have
    function createIdentityFor(address thisOwner, uint thisToken, string calldata uri) external override {
        if (msg.sender != _minter) {
            revert OnlyMinter(msg.sender);
        }
        if (owners[thisToken] != address(0)) {
            revert TokenAlreadyExists(thisToken);
        }

        // for getTokenByIndex below, 0 based index so we do it before incrementing numIdentities
        allTokens[numIdentities++] = thisToken;

        // two way mapping for enumeration
        ownershipMapIndexToToken[thisOwner][balances[thisOwner]] = thisToken;
        ownershipMapTokenToIndex[thisOwner][thisToken] = balances[thisOwner];


        // set owner of new token
        owners[thisToken] = thisOwner;
        // increment balances for owner
        ++balances[thisOwner];
        uriMap[thisToken] = uri;
        emit Transfer(address(0), thisOwner, thisToken);
        emit IdentityCreated(thisOwner, thisToken);
    }

    /// ================= SETTERS =======================================

    /// @notice Changing the owner key
    /// @dev Only current owner may do this
    /// @param newOwner the new address that will be owner, old address is no longer owner
    function setOwner(address newOwner) external {
        if (msg.sender != _owner_) {
            revert OnlyOwner(msg.sender);
        }

        address oldOwner = _owner_;
        _owner_ = newOwner;
        emit OwnerUpdated(oldOwner, newOwner);
    }

    // manually set the token URI
    /// @notice Manually set the token URI
    /// @dev This is just a backup in case some metadata goes wrong, this is basically the only thing the owner can do
    /// @param token tokenId that we are setting metadata for
    /// @param uri metadata that will be associated to this token
    function setTokenURI(uint token, string calldata uri) external {
        if (msg.sender != _owner_) {
            revert OnlyOwner(msg.sender);
        }

        uriMap[token] = uri;
    }

    function endMinting() external {
        if (msg.sender != _owner_) {
            revert OnlyOwner(msg.sender);
        }

        _minter = address(0);
    }

    /// ================= ERC 721 FUNCTIONS =============================================

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _address An address for whom to query the balance
    /// @return The number of NFTs owned by `owner`, possibly zero
    function balanceOf(address _address) external view returns (uint256) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        return balances[_address];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address)  {
        address ooner = owners[tokenId];
        if (ooner == address(0)) {
            revert InvalidToken(tokenId);
        }
        return ooner;
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (isApproved(msg.sender, tokenId) == false) {
            revert UnapprovedTransfer(tokenId, msg.sender);
        }
        transfer(from, to, tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        if (checkOnERC721Received(from, to, tokenId, data) == false) {
            revert NFTUnreceivable(to);
        }
        transferFrom(from, to, tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, '');
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param approved The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(address approved, uint256 tokenId) public {
        address holder = owners[tokenId];
        if (isApproved(msg.sender, tokenId) == false) {
            revert UnauthorizedApproval(tokenId, msg.sender);
        }
        if (holder == approved) {
            revert SelfApproval(tokenId, holder);
        }
        tokenApprovals[tokenId] = approved;
        emit Approval(holder, approved, tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 tokenId) external view returns (address) {
        address holder = owners[tokenId];
        if (holder == address(0)) {
            revert InvalidToken(tokenId);
        }
        return tokenApprovals[tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _address The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address _address, address operator) public view returns (bool) {
        return operatorApprovals[_address][operator];
    }

    /// ================ UTILS =========================

    /// @notice Look thru all 3 (???) notions of approval for one that matches
    /// @dev There was a bug in this part of the contract when it was originally forked from OpenZeppelin
    /// @param operator the address whose approval we are querying
    /// @param tokenId the specific NFT about which we are querying approval
    /// @return approval is the operator approved to transfer this tokenId?
    function isApproved(address operator, uint tokenId) public view returns (bool) {
        address holder = owners[tokenId];
        return (
            operator == holder ||
            operatorApprovals[holder][operator] ||
            tokenApprovals[tokenId] == operator
        );
    }

    /**
     * @notice Standard NFT transfer logic
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     * @param from current owner of the NFT
     * @param to new owner of the NFT
     * @param tokenId which NFT is getting transferred
     */
    function transfer(address from, address to, uint256 tokenId) internal {
        if (owners[tokenId] != from) {
            revert TokenOwnershipRequired(tokenId, from);
        }
        if (to == address(0)) {
            revert ZeroAddress();
        }

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        owners[tokenId] = to;

        // update balances
        balances[from] -= 1;


        // zero out two way mapping
        uint ownershipIndex = ownershipMapTokenToIndex[from][tokenId];
        ownershipMapTokenToIndex[from][tokenId] = 0;
        if (ownershipIndex != balances[from]) {
            uint reslottedToken = ownershipMapIndexToToken[from][balances[from]];
            ownershipMapIndexToToken[from][ownershipIndex] = reslottedToken;
            ownershipMapIndexToToken[from][balances[from]] = 0;
            ownershipMapTokenToIndex[from][reslottedToken] = ownershipIndex;
        } else {
            ownershipMapIndexToToken[from][ownershipIndex] = 0;
        }

        // set two way mapping
        ownershipMapIndexToToken[to][balances[to]] = tokenId;
        ownershipMapTokenToIndex[to][tokenId] = balances[to];

        balances[to] += 1;


        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (to.code.length == 0) {
            return true;
        }
        IERC721Receiver target = IERC721Receiver(to);
        bytes4 retval = target.onERC721Received(from, to, tokenId, data);
        return ERC721_RECEIVED == retval;
    }

    /**
     * @notice ERC165 function to tell other contracts which interfaces we support
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     * @dev This whole interface thing is a little pointless, because contracts can lie or mis-implement the interface
     * @dev so you might as well just use a try catch
     * @param interfaceId the first four bytes of the hash of the signatures of the functions of the interface in question
     * @return supports true if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (
            interfaceId == INTERFACE_ID_ERC721 ||
            interfaceId == INTERFACE_ID_ERC165 ||
            interfaceId == INTERFACE_ID_ERC721_ENUMERABLE ||
            interfaceId == INTERFACE_ID_ERC721_METADATA
        );
    }

    /// ================= ERC721Metadata FUNCTIONS =============================================

    /// @notice A descriptive name for a collection of NFTs in this contract
    /// @return name the intended name
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    /// @return symbol the intended ticker symbol
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    /// @return uri the tokenUri for a specific tokenId
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        if (owners[_tokenId] == address(0)) {
            revert InvalidToken(_tokenId);
        }
        return uriMap[_tokenId];
    }

    /// @notice The address that can set the tokenUri for tokens
    /// @return The address that can set the tokenUri for tokens
    function owner() public view override returns (address) {
        return _owner_;
    }

    /// ================= ERC721Enumerable FUNCTIONS =============================================


    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view override returns (uint256) {
        return numIdentities;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        if (_index >= numIdentities) {
            revert InvalidIndex(_index);
        }
        return allTokens[_index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner_)` or if
    ///  `_owner_` is the zero address, representing invalid NFTs.
    /// @param _address An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner_)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner_`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _address, uint256 _index) external view returns (uint256) {
        if (_index >= balances[_address]) {
            revert InvalidIndex(_index);
        }
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        return ownershipMapIndexToToken[_address][_index];
    }


}