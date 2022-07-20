/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/IERC721Metadata.sol

pragma solidity ^0.8.0;

interface IERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    // function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// File contracts/ERC721Metadata.sol

pragma solidity ^0.8.0;

contract ERC721Metadata is IERC721Metadata {
    string private _name;
    string private _symbol;

    constructor(string memory m_name, string memory m_symbol) {
        _name = m_name;
        _symbol = m_symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }
}

// File contracts/interfaces/IERC721.sol

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    // function approve(address _approved, uint256 _tokenId) external payable;

    // function setApprovalForAll(address _operator, bool _approved) external;

    // function getApproved(uint256 _tokenId) external view returns (address);

    // function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File contracts/ERC721.sol

pragma solidity ^0.8.0;

error ERC721__ADDRESS_ZERO();
error ERC721__ALREADY_MINTED();
error ERC721__INVALID_USER();
error ERC721__NOT_OWNER();
error ERC721__SAME_ADDRESS();

contract ERC721 is IERC721 {
    // STATE VARIABLE

    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownedTokenCount;

    mapping(uint256 => address) private _tokenApproval;

    // FUNCTIONS

    function balanceOf(address _owner) public view override returns (uint256) {
        if (_owner == address(0)) revert ERC721__INVALID_USER();

        return _ownedTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = _tokenOwner[_tokenId];
        if (owner == address(0)) revert ERC721__INVALID_USER();

        return owner;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721__ADDRESS_ZERO();

        if (_tokenOwner[tokenId] != address(0)) {
            revert ERC721__ALREADY_MINTED();
        }

        _tokenOwner[tokenId] = to;
        _ownedTokenCount[to]++;
        emit Transfer(address(0), to, tokenId);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 tokenId
    ) internal {
        if (_to == address(0)) revert ERC721__ADDRESS_ZERO();

        if (_tokenOwner[tokenId] != _from) revert ERC721__NOT_OWNER();

        _ownedTokenCount[_from] -= 1;
        _ownedTokenCount[_to] += 1;

        _tokenOwner[tokenId] = _to;

        emit Transfer(_from, _to, tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 tokenId
    ) public override {
        _transferFrom(_from, _to, tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);

        if (_to == owner) revert ERC721__SAME_ADDRESS();

        if (msg.sender != owner) revert ERC721__NOT_OWNER();

        _tokenApproval[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }
}

// File contracts/interfaces/IERC721Enumerable.sol

pragma solidity ^0.8.0;

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);
}

// File contracts/ERC721Enumerable.sol

pragma solidity ^0.8.0;
error ERC721Enumerable__Index_OutBound();
error ERC721Enumerable__Owner_Index_OutBound();

contract ERC721Enumerable is ERC721, IERC721Enumerable {
    uint256[] private _allTokens;

    // mapping from tokenId to position in _allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // mapping of owner to list of all owner token ids
    mapping(address => uint256[]) private _ownedTokens;

    // mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);
        _addTokensToAllTokenEnumeration(tokenId);
        _addTokensToOwnerEnumeration(to, tokenId);
    }

    // add tokens to the _alltokens array and set the position of the tokens indexes
    function _addTokensToAllTokenEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _addTokensToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        // make sure that the index is not out of bounds of the total supply
        require(index < totalSupply(), "global index is out of bounds!");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "owner index is out of bounds!");
        return _ownedTokens[owner][index];
    }

    // return the total supply of the _allTokens array
    function totalSupply() public view override returns (uint256) {
        return _allTokens.length;
    }
}

// File contracts/interfaces/IERC165.sol

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File contracts/ERC165.sol

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File contracts/ERC721Connector.sol

pragma solidity ^0.8.0;

contract ERC721Connector is ERC721Metadata, ERC721Enumerable, ERC165 {
    constructor(string memory name, string memory symbol)
        ERC721Metadata(name, symbol)
    {}

    // ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// File contracts/Kryptozombie.sol

pragma solidity ^0.8.0;
error Kryptozombie__ALREADY_EXISTS();

contract Kryptozombie is ERC721Connector {
    // VARIABLES
    string[] public kryptoZombie;
    mapping(string => bool) kryptoZombieExists;

    // FUNCTIONS
    function mint(string memory _kryptoZombie) public {
        if (kryptoZombieExists[_kryptoZombie])
            revert Kryptozombie__ALREADY_EXISTS();

        kryptoZombie.push(_kryptoZombie);
        uint256 _id = kryptoZombie.length - 1;

        _mint(msg.sender, _id);
        kryptoZombieExists[_kryptoZombie] = true;
    }

    constructor() ERC721Connector("KryptoZombie", "KPZ") {}
}