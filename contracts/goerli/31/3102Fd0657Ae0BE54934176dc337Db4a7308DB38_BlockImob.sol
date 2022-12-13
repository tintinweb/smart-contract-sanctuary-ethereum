// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC4907.sol";
import "./interfaces/IBlockImob.sol";

contract BlockImob is ERC4907, IBlockImob {
    mapping(address => bool) public allowed;
    mapping(uint256 => string) public tokenIdToURI;
    mapping(uint256 => Deal) public tokenIdToDeal;
    mapping(string => mapping(uint256 => uint256)) public queryToTokenId;
    mapping(uint256 => Query) public tokenIdToQuery;
    string public baseURI;
    uint256 public nextTokenId = 1; // 0 for token no longer active

    constructor(string memory _name, string memory _symbol)
        ERC4907(_name, _symbol)
    {
        allowed[msg.sender] = true;
    }

    modifier onlyAllowed() {
        require(allowed[msg.sender], "BlockImob: Not allowed");
        _;
    }

    modifier validateTokenId(uint256 _tokenId) {
        require(_tokenId < nextTokenId, "BlockImob: Invalid tokenId");
        _;
    }

    modifier validateURI(string memory _uri) {
        require(bytes(_uri).length > 0, "BlockImob: No URI given");
        _;
    }

    function mint(
        address _owner,
        string memory _uri,
        string memory _district,
        uint256 _registry
    ) external virtual onlyAllowed validateURI(_uri) {
        require(bytes(_district).length > 0, "BlockImob: No district given");
        require(_registry > 0, "BlockImob: Invalid registry given");
        uint256 tokenId = nextTokenId;

        unchecked {
            nextTokenId++;
        }

        tokenIdToURI[tokenId] = _uri;
        queryToTokenId[_district][_registry] = tokenId;
        tokenIdToQuery[tokenId] = Query(_district, _registry);

        _safeMint(_owner, tokenId);
    }

    function burn(uint256 _tokenId)
        external
        onlyAllowed
        validateTokenId(_tokenId)
    {
        delete tokenIdToURI[_tokenId];
        Query memory query = tokenIdToQuery[_tokenId];
        delete queryToTokenId[query.district][query.registry];
        delete tokenIdToQuery[_tokenId];
        delete tokenIdToDeal[_tokenId];

        _burn(_tokenId);
    }

    function setOperator(address _operator, bool _approved)
        external
        onlyAllowed
    {
        require(_operator != address(0), "BlockImob: Invalid operator");
        setApprovalForAll(_operator, _approved);
    }

    function updateTokenDeal(
        uint256 _tokenId,
        DealType _dealType,
        address _dealAddress,
        address _fiiAddress
    ) external override onlyAllowed validateTokenId(_tokenId) {
        tokenIdToDeal[_tokenId].dealType = _dealType;
        tokenIdToDeal[_tokenId].dealAddress = _dealAddress;
        tokenIdToDeal[_tokenId].fiiAddress = _dealType == DealType.SELL
            ? address(0)
            : _fiiAddress;

        emit UpdatedTokenDeal(_tokenId, _dealType, _dealAddress, _fiiAddress);
    }

    function setBaseURI(string memory _newBaseURI) external onlyAllowed {
        baseURI = _newBaseURI;
        emit UpdatedBaseURI(_newBaseURI, _newBaseURI);
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _uri,
        string memory _newValue
    ) external onlyAllowed validateTokenId(_tokenId) validateURI(_uri) {
        require(
            bytes(_newValue).length > 0,
            "BlockImob: No value added/updated"
        );
        tokenIdToURI[_tokenId] = _uri;
        emit UpdatedTokenURI(_tokenId, _uri, _uri, _newValue);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        validateTokenId(_tokenId)
        returns (string memory)
    {
        return (
            bytes(baseURI).length == 0
                ? tokenIdToURI[_tokenId]
                : string(abi.encodePacked(baseURI, _tokenId, ".json"))
        );
    }

    function uriFromQuery(string memory _district, uint256 _registry)
        external
        view
        returns(string memory)
    {
        return tokenURI(queryToTokenId[_district][_registry]);
    }

    // function tokenIdFromQuery(string memory _district, uint256 _registry)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     return queryToTokenId[_district][_registry];
    // }

    function queryFromTokenId(uint256 _tokenId)
        external
        view
        validateTokenId(_tokenId)
        returns (Query memory)
    {
        return tokenIdToQuery[_tokenId];
    }


    function returnFiiAddress(uint256 _tokenId) external view returns(address){
        return tokenIdToDeal[_tokenId].fiiAddress;
    }


    function returnAllowed(address _party) external view returns (bool){
        return allowed[_party];
    }

    function changeAllow(address _addr, bool _state) onlyAllowed external {
        allowed[_addr] = _state;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IERC4907.sol";

interface IBlockImob is IERC4907 {
    enum DealType {
        RENT,
        SELL
    }

    struct Deal {
        DealType dealType;
        address dealAddress;
        address fiiAddress;
    }

    struct Query {
        string district;
        uint256 registry;
    }

    event UpdatedTokenURI(
        uint256 indexed tokenId,
        string indexed newURI,
        string newURIText,
        string newValue
    );
    event UpdatedBaseURI(string indexed newBaseURI, string newBaseURIText);
    event UpdatedTokenDeal(
        uint256 indexed tokenId,
        DealType dealType,
        address indexed dealAddress,
        address indexed fiiAddress
    );

    function returnAllowed(address _party) external view returns (bool);

    function nextTokenId() external view returns (uint256);

    function updateTokenDeal(
        uint256 _tokenId,
        DealType _dealType,
        address _dealAddress,
        address _fiiAddress
    ) external;

    function returnFiiAddress(uint256 _tokenId) external view returns(address);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./interfaces/IERC4907.sol";

abstract contract ERC4907 is ERC721, IERC4907 {
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.15;

import "./ReentrancyGuard.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
    ) public virtual nonReentrant {
        require(from == _ownerOf[id], "WRONG_FROM");

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

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual nonReentrant {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual nonReentrant {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
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

    function _safeMint(address to, uint256 id) internal virtual nonReentrant {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual nonReentrant {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll[owner][spender] ||
            getApproved[tokenId] == spender);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}