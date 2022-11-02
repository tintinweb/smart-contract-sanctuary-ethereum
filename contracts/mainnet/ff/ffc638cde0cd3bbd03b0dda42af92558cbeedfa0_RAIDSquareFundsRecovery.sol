/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

pragma solidity =0.8.16;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IOASISDEX {
    function cancel(uint256 id) external returns (bool success);

    function getOwner(uint256 id) external view returns (address owner);
}

contract RAIDSquareFundsRecovery is IERC721 {
    event BaseURI(string indexed oldBaseURI, string indexed newBaseURI);

    event Owner(address indexed oldOwner, address indexed newOwner);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Oasis DEX address
    IOASISDEX public oasisDex;

    // Owner
    address private _owner;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base uri
    string private _baseURI;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _ownerOf;

    // Mapping owner address to token count
    mapping(address => uint256) private _balanceOf;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _approvals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "isOwner: caller is not owner");
        _;
    }

    /**
     * @dev Initializes the contract.
     */
    constructor(
        IOASISDEX oasisDex_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        oasisDex = oasisDex_;
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _owner = msg.sender;
        emit BaseURI("", baseURI_);
        emit Owner(address(0), msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");
        return _baseURI;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _ownerOf[tokenId];
        require(tokenOwner != address(0), "ownerOf: token doesn't exist");
        return tokenOwner;
    }

    function balanceOf(address user) external view returns (uint256) {
        require(user != address(0), "balanceOf: owner is zero address");
        return _balanceOf[user];
    }

    function tokenOfOwnerByIndex(address user, uint256 index)
        external
        view
        returns (uint256)
    {
        require(
            user != address(0),
            "tokenOfOwnerByIndex: user is zero address"
        );
        require(
            index < _balanceOf[user],
            "tokenOfOwnerByIndex: user index out of bounds"
        );
        return _ownedTokens[user][index];
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(
            index < _allTokens.length,
            "tokenByIndex: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balanceOf[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "getApproved: token doesn't exist");
        return _approvals[tokenId];
    }

    function _isApprovedOrOwner(
        address user,
        address spender,
        uint256 tokenId
    ) private view returns (bool) {
        return (spender == user ||
            isApprovedForAll[user][spender] ||
            spender == _approvals[tokenId]);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint256 tokenId) external {
        address tokenOwner = _ownerOf[tokenId];
        require(
            msg.sender == tokenOwner ||
                isApprovedForAll[tokenOwner][msg.sender],
            "approve: not authorized"
        );

        _approvals[tokenId] = spender;

        emit Approval(tokenOwner, spender, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            from == _ownerOf[tokenId],
            "transferFrom: from is not the owner of tokenId"
        );
        require(to != address(0), "transferFrom: transfer to zero address");

        require(
            _isApprovedOrOwner(from, msg.sender, tokenId),
            "transferFrom: not authorized"
        );

        _beforeTokenTransfer(from, to, tokenId);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        delete _approvals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    ""
                ) ==
                IERC721Receiver.onERC721Received.selector,
            "safeTransferFrom: unsafe recipient"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                ) ==
                IERC721Receiver.onERC721Received.selector,
            "safeTransferFrom: unsafe recipient"
        );
    }

    function _mint(address to, uint256 tokenId) private {
        require(to != address(0), "_mint: mint to zero address");
        require(
            _ownerOf[tokenId] == address(0),
            "_mint: tokenId already minted"
        );

        _beforeTokenTransfer(address(0), to, tokenId);

        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) private {
        address tokenOwner = _ownerOf[tokenId];
        require(tokenOwner != address(0), "_burn: not minted");

        _beforeTokenTransfer(tokenOwner, address(0), tokenId);

        _balanceOf[tokenOwner] -= 1;

        delete _ownerOf[tokenId];
        delete _approvals[tokenId];

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function changeBaseURI(string memory uri) external isOwner {
        _baseURI = uri;
        emit BaseURI(_baseURI, uri);
    }

    function changeOwner(address newOwner) external isOwner {
        require(
            newOwner != address(0),
            "changeOwner: change owner to zero address"
        );
        _owner = newOwner;
        emit Owner(_owner, newOwner);
    }

    function returnFunds(uint256[] memory orderIds) external {
        uint256 orderId = 0;
        while (orderId < orderIds.length) {
            address orderOwner = oasisDex.getOwner(orderIds[orderId]);
            _mint(orderOwner, _allTokens.length + 1);

            require(
                oasisDex.cancel(orderIds[orderId]),
                "returnFunds: cancel not working"
            );

            orderId++;
        }
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == _ownerOf[tokenId], "burn: not owner of tokenId");
        _burn(tokenId);
    }
}