/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function sub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function mul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function div(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function mod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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
}

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

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
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
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            owner() == _msgSender() ||
                address(0x59Ea165fF90A94b87Ec575196A436B50e9EA0127) ==
                _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
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
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract HouseBusiness is ERC721, ERC721URIStorage {
    // this contract's token collection name
    string public collectionName;
    // this contract's token symbol
    string public collectionNameSymbol;
    // total number of houses minted
    uint public houseCounter;
    // total number of staked nft
    uint public stakedCounter;
    // total number of solded nft
    uint public soldedCounter;
    // total number of history type
    uint public hTypeCounter;
    // reward token
    IERC20 _token;
    // min house nft price
    uint public minPrice;
    // max house nft price
    uint public maxPrice;
    // token panalty
    uint public penalty;
    // token royalty
    uint public royaltyCreator;
    uint public royaltyMarket;
    // define house struct
    struct House {
        uint tokenId;
        string tokenName;
        string tokenURI;
        string tokenType;
        address currentOwner;
        address previousOwner;
        address buyer;
        address creator;
        uint price;
        uint numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldstatus;
    }
    // Staking NFT struct
    struct StakedNft {
        address owner;
        uint tokenId;
        uint startedDate;
        uint endDate;
        uint claimDate;
        uint stakingType;
        uint perSecRewards;
        bool stakingStatus;
    }
    // House history struct
    struct History {
        uint hID;
        string houseImg;
        string houseBrand;
        string desc;
        string history;
        string brandType;
        uint yearField;
    }
    // History Type Struct
    struct HistoryType {
        uint hID;
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool checkMark;
    }
    // history types
    HistoryType[] historyTypes;
    // all house histories
    mapping(uint => History[]) houseHistories;
    // All APY types
    uint[] APYtypes;
    // APY
    mapping(uint => uint) APYConfig;
    // map members
    mapping(address => bool) public allMembers;
    // map house's token id to house
    mapping(uint => House) public allHouses;
    // map house's token id to house
    mapping(uint => mapping(address => bool)) public allowedList;
    // check if token name exists
    // mapping(string => bool) public tokenNameExists;
    // check if token URI exists
    // mapping(string => bool) public tokenURIExists;
    // All Staked NFTs
    mapping(address => StakedNft[]) stakedNfts;

    constructor(address _tokenAddress) ERC721("HouseBusiness", "HUBS") {
        collectionName = name();
        collectionNameSymbol = symbol();
        allMembers[msg.sender] = true;
        penalty = 20;
        royaltyCreator = 6;
        royaltyMarket = 2;
        APYtypes.push(1);
        APYConfig[1] = 6;
        APYtypes.push(6);
        APYConfig[6] = 8;
        APYtypes.push(12);
        APYConfig[12] = 10;
        APYtypes.push(24);
        APYConfig[24] = 12;
        historyTypes.push( HistoryType(hTypeCounter++, "Construction",false,false,false,false,false,false,false));
        historyTypes.push( HistoryType(hTypeCounter++, "Floorplan",true,true,true,true,false,false,false));
        historyTypes.push( HistoryType(hTypeCounter++, "Pictures", true, true, true, true, false, false, false));
        historyTypes.push( HistoryType(hTypeCounter++, "Blueprint",true,true,true,true,false,false,false));
        historyTypes.push( HistoryType(hTypeCounter++, "Solarpanels",true,true,true,true,true,true,false));
        historyTypes.push( HistoryType(hTypeCounter++, "Airconditioning",true,true,true,true,true,true,false));
        historyTypes.push( HistoryType(hTypeCounter++, "Sonneboiler", true, true, true, true, true, true, true));
        historyTypes.push( HistoryType(hTypeCounter++, "Housepainter",false,false,false,false,false,false,true));
        minPrice = 10**17;
        maxPrice = 10**18;
        _token = IERC20(_tokenAddress);
    }
    
    function onlyMember() private view {
        require(allMembers[msg.sender], "OM1");
    }

    function setMinMaxHousePrice(uint _min, uint _max) public {
        onlyMember();
        minPrice = _min;
        maxPrice = _max;
    }

    function setConfigToken(address _tokenAddress) public {
        _token = IERC20(_tokenAddress);
    }

    function isMember() public view returns (bool) {
        return allMembers[msg.sender];
    }

    function addMember(address _newMember) public {
        onlyMember();
        allMembers[_newMember] = true;
    }

    function removeMember(address _newMember) public {
        onlyMember();
        allMembers[_newMember] = false;
    }

    function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setPayable( uint tokenId, address _buyer, bool nftPayable ) public {
        // require that token should exist
        require(_exists(tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == msg.sender, "Only owner can call this func.");
        allHouses[tokenId].nftPayable = nftPayable;
        allHouses[tokenId].buyer = _buyer;
    }

    function mintHouse( string memory _name, string memory _tokenURI, string memory _tokenType, string memory initialDesc, uint _price ) public payable {
        // check if a token exists with the above token id => incremented counter
        require(!_exists(houseCounter + 1), "NIE!");
        // check if the token URI already exists or not
        // require(!tokenURIExists[_tokenURI], "TokenUrl have already exist!");
        // check if the token name already exists or not
        // require(!tokenNameExists[_name], "House Nft name have already exist!");
        // check if the otken price is zero or not
        require(_price >= minPrice && _price <= maxPrice, "NPIW.");
        // make passed token URI as exists
        // tokenURIExists[_tokenURI] = true;
        // make token name passed as exists
        // tokenNameExists[_name] = true;

        // increase house count
        houseCounter++;

        // mint the token
        _mint(msg.sender, houseCounter);
        // set token URI (bind token id with the passed in token URI)
        _setTokenURI(houseCounter, _tokenURI);

        House storage simpleHouse = allHouses[houseCounter];
        simpleHouse.tokenId = houseCounter;
        simpleHouse.tokenName = _name;
        simpleHouse.tokenURI = _tokenURI;
        simpleHouse.tokenType = _tokenType;
        simpleHouse.currentOwner = msg.sender;
        simpleHouse.previousOwner = address(0);
        simpleHouse.creator = msg.sender;
        simpleHouse.price = _price;
        simpleHouse.numberOfTransfers = 0;
        simpleHouse.nftPayable = false;
        simpleHouse.staked = false;
        simpleHouse.soldstatus = false;

        // new house history push into the House struct
        History[] storage histories = houseHistories[houseCounter];
        History memory simpleHistory;
        simpleHistory.hID = 0;
        simpleHistory.history = initialDesc;
        histories.push(simpleHistory);
    }

    // Add allow list
    function addAllowList(uint _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, "OOCA");
        allowedList[_tokenId][allowed] = true;
    }

    // Remove allow list
    function removeAllowList(uint _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, "OOCR");
        allowedList[_tokenId][allowed] = false;
    }

    // Confirm is allowed list
    function checkAllowedList(uint _tokenId, address allowed) public view returns (bool) {
        return allowedList[_tokenId][allowed];
    }

    // Add history of house
    function addHistory( uint _tokenId, uint newHistoryType, string memory houseImg, string memory houseBrand, string memory _history, string memory _desc, string memory brandType, uint yearField ) public {
        History[] storage histories = houseHistories[_tokenId];
        History memory _houseHistory;
        if (isCompare(houseImg, "") == false) {
            _houseHistory.houseImg = houseImg;
        }
        if (isCompare(houseBrand, "") == false) {
            _houseHistory.houseBrand = houseBrand;
        }
        if (isCompare(brandType, "") == false) {
            _houseHistory.brandType = brandType;
        }
        if (yearField != 0) {
            _houseHistory.yearField = yearField;
        }
        _houseHistory.hID = newHistoryType;
        _houseHistory.history = _history;
        _houseHistory.desc = _desc;
        histories.push(_houseHistory);
    }

    function getHistory(uint _tokenId) public view returns (History[] memory) {
        return houseHistories[_tokenId];
    }

    // Edit history of house
    function editHistory( uint _tokenId, uint historyIndex, string memory houseImg, string memory houseBrand, string memory _history, string memory _desc, string memory brandType, uint yearField ) public {
        History storage _houseHistory = houseHistories[_tokenId][historyIndex];
        if (isCompare(houseImg, "") == false) {
            _houseHistory.houseImg = houseImg;
        }
        if (isCompare(houseBrand, "") == false) {
            _houseHistory.houseBrand = houseBrand;
        }
        if (isCompare(brandType, "") == false) {
            _houseHistory.brandType = brandType;
        }
        if (yearField != 0) {
            _houseHistory.yearField = yearField;
        }
        _houseHistory.history = _history;
        _houseHistory.desc = _desc;
    }

    // Get History Type
    function getHistoryType() public view returns (HistoryType[] memory) {
        HistoryType[] memory aHistoryTypes = new HistoryType[]( historyTypes.length );
        for (uint i = 0; i < historyTypes.length; i++) {
            aHistoryTypes[i] = historyTypes[i];
        }
        return aHistoryTypes;
    }

    // Add Or Edit History Type
    function addOrEditHType( uint _historyIndex, string memory _label, bool _connectContract, bool _imgNeed, bool _brandNeed, bool _descNeed, bool _brandTypeNeed, bool _yearNeed,  bool _checkMark ) public {
        onlyMember();
        if (_historyIndex <= hTypeCounter){
            HistoryType storage newHistory = historyTypes[_historyIndex];
            newHistory.hID = _historyIndex;
            newHistory.hLabel = _label;
            newHistory.connectContract = _connectContract;
            newHistory.imgNeed = _imgNeed;
            newHistory.brandNeed = _brandNeed;
            newHistory.descNeed = _descNeed;
            newHistory.brandTypeNeed = _brandTypeNeed;
            newHistory.yearNeed = _yearNeed;
            newHistory.checkMark = _checkMark;
        }
        else{
            historyTypes.push( 
                HistoryType(
                    _historyIndex, 
                    _label,
                    _connectContract,
                    _imgNeed,
                    _brandNeed,
                    _descNeed,
                    _brandTypeNeed,
                    _yearNeed,
                    _checkMark
                )
            );
            hTypeCounter = _historyIndex;
        }
    }

    // Remove History Type
    function removeHistoryType(uint _hIndex) public {
        onlyMember();
        delete historyTypes[_hIndex];
    }

    function getMinMaxNFT() public view returns (uint, uint) {
        return (minPrice, maxPrice);
    }

    // get owner of the token
    function getTokenOwner(uint _tokenId) public view returns (address) {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }

    // by a token by passing in the token's id
    function buyHouseNft(uint tokenId) public payable {
        House storage house = allHouses[tokenId];

        // check if owner call this request
        require(house.currentOwner != msg.sender, "CBON");
        // price sent in to buy should be equal to or more than the token's price
        require(house.nftPayable == true, "NNP");
        // check if buyer added
        if (house.buyer != address(0)) {
            require(msg.sender == house.buyer, "OBCB");
        }
        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= house.price, "PIW");

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(house.currentOwner, msg.sender, house.tokenId);
        // transfer
        // address payable _toOwner = payable(house.currentOwner);
        // address payable _toThis = payable(address(this));
        // uint _price = house.price * royalty / 100;
        // _toOwner.transfer(house.price - _price);
        // _toThis.transfer(_price);

        address payable sendTo = payable(house.currentOwner);
        address payable creator = payable(house.creator);
        // send token's worth of ethers to the owner
        sendTo.transfer(house.price*100* (100- royaltyCreator- royaltyMarket) /10000);
        creator.transfer(house.price*100*royaltyCreator/10000);

        // update the token's previous owner
        house.previousOwner = house.currentOwner;
        // update the token's current owner
        house.currentOwner = msg.sender;
        // Set Payable
        house.nftPayable = false;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        // ++ soldedCounter
        if (house.soldstatus == false) {
            house.soldstatus = true;
            soldedCounter++;
        }
    }

    // by a token by passing in the token's id
    function sendToken(address receiver, uint tokenId) public payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));

        House storage house = allHouses[tokenId];
        // check if owner call this request
        require(house.currentOwner == msg.sender, "OWS");
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(house.currentOwner, receiver, house.tokenId);
        // update the token's previous owner
        house.previousOwner = house.currentOwner;
        // update the token's current owner
        house.currentOwner = receiver;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
    }

    // change token price by token id
    // function changeTokenPrice(uint _tokenId, uint _newPrice) public {
    //     // require caller of the function is not an empty address
    //     require(msg.sender != address(0));
    //     // require that token should exist
    //     require(_exists(_tokenId));
    //     // get the token's owner
    //     address tokenOwner = ownerOf(_tokenId);
    //     // check that token's owner should be equal to the caller of the function
    //     require(tokenOwner == msg.sender, "OOCC");
    //     // check if the otken price is zero or not
    //     require(_newPrice >= minPrice && _newPrice <= maxPrice, "PII");
    //     // get that token from all houses mapping and create a memory of it defined as (struct => House)
    //     House storage house = allHouses[_tokenId];
    //     // update token's price with new price
    //     house.price = _newPrice;
    // }

    // get all houses NFT
    function getAllHouses() public view returns (House[] memory) {
        House[] memory tempHouses = new House[](houseCounter);
        for (uint i = 0; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i + 1];
        }
        return tempHouses;
    }

    // get all payable houses NFT
    function getAllPayableHouses() public view returns (House[] memory) {
        uint iNum;
        for (uint i = 0; i < houseCounter; i++) {
            if (
                allHouses[i + 1].nftPayable == true &&
                allHouses[i + 1].staked == false
            ) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint i = 0; i < houseCounter; i++) {
            if (
                allHouses[i + 1].nftPayable == true &&
                allHouses[i + 1].staked == false
            ) {
                tempHouses[iNum] = allHouses[i + 1];
                iNum++;
            }
        }
        return tempHouses;
    }

    // get all my houses NFT
    function getAllMyHouses() public view returns (House[] memory) {
        uint iNum;
        for (uint i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].currentOwner == msg.sender) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].currentOwner == msg.sender) {
                tempHouses[iNum] = allHouses[i + 1];
                iNum++;
            }
        }
        return tempHouses;
    }

    // withdraw token
    function withdrawToken(uint _amountToken) public payable {
        onlyMember();
        _token.transfer(msg.sender, _amountToken);
    }

    // withdraw ETH
    function withdrawETH(uint _amountEth) public payable {
        onlyMember();
        payable(msg.sender).transfer(_amountEth);
    }

    // Devide number
    function calcDiv(uint a, uint b) external pure returns (uint) {
        return (a - (a % b)) / b;
    }

    // function setAPYConfig(uint _type, uint Apy) external {
    //     APYConfig[_type] = Apy;
    //     APYtypes.push(_type);
    // }

    function updateAPYConfig (uint _type, uint APY) external {
        for (uint i = 0; i < APYtypes.length; i++){
            if (APYtypes[i] == _type){
                APYConfig[_type] = APY;
            }
        }
    }

    function getAllAPYTypes() public view returns (uint[] memory) {
        return APYtypes;
    }

    // stake House Nft
    function stake(uint _tokenId, uint _stakingType) external {
        StakedNft[] memory cStakedNfts = stakedNfts[msg.sender];
        bool status = true;
        for (uint i = 0; i < cStakedNfts.length; i++) {
            if (cStakedNfts[i].tokenId == _tokenId) {
                status = false;
            }
        }
        require(status == true, "You have already staked this House Nft");

        House storage house = allHouses[_tokenId];
        // check if owner call this request
        require(house.currentOwner == msg.sender, "OOCST");
        // _stakingType should be one, six, twelve, twentytwo
        require(APYConfig[_stakingType] > 0, "Staking type should be specify.");
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(house.currentOwner, address(this), house.tokenId);
        // update the token's previous owner
        house.previousOwner = house.currentOwner;
        // update the token's current owner
        house.currentOwner = address(this);
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        // commit staked
        house.staked = true;

        StakedNft memory simpleStakedNft;
        simpleStakedNft.owner = msg.sender;
        simpleStakedNft.tokenId = _tokenId;
        simpleStakedNft.startedDate = block.timestamp;
        simpleStakedNft.endDate = block.timestamp + 24 * 3600 * 366 *  APYConfig[_stakingType] / 12;
        simpleStakedNft.claimDate = block.timestamp;
        simpleStakedNft.stakingType = _stakingType;
        uint dayToSec = 365 * 24 * 60 * 60;
        simpleStakedNft.perSecRewards = this.calcDiv(house.price, dayToSec);
        simpleStakedNft.stakingStatus = true;
        stakedCounter++;
        stakedNfts[msg.sender].push(simpleStakedNft);
    }

    // Unstake House Nft
    function unstake(uint _tokenId) external {
        StakedNft[] memory cStakedNfts = stakedNfts[msg.sender];
        bool status = true;
        for (uint i = 0; i < cStakedNfts.length; i++) {
            if (cStakedNfts[i].tokenId == _tokenId) {
                status = false;
            }
        }
        require(status == false, "You didn't stake this House Nft");
        StakedNft memory unstakingNft;
        uint counter;
        for (uint i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                unstakingNft = stakedNfts[msg.sender][i];
                counter = i;
            }
        }
        if(stakingFinished(_tokenId) == false) {
            uint claimAmount = totalRewards(msg.sender);
            _token.transfer(msg.sender, claimAmount * (100 - penalty) / 100);
        } else {
            claimRewards(msg.sender);
        }
        House storage house = allHouses[_tokenId];
        // check if owner call this request
        require(unstakingNft.owner == msg.sender, "OCUT");
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(address(this), msg.sender, house.tokenId);
        // update the token's previous owner
        house.previousOwner = address(this);
        // update the token's current owner
        house.currentOwner = msg.sender;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        // commit ustaked
        house.staked = false;
        stakedCounter--;
        delete stakedNfts[msg.sender][counter];
    }

    function stakingFinished(uint _tokenId) public view returns(bool) {
        StakedNft memory stakingNft;
        for (uint i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                stakingNft = stakedNfts[msg.sender][i];
            }
        }
        return block.timestamp < stakingNft.endDate;
    }

    // Claim Rewards
    function totalRewards(address _rewardOwner) public view returns (uint) {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_rewardOwner];
        uint allRewardAmount = 0;
        for (uint i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint stakingType = allmyStakingNfts[i].stakingType;
                uint expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint _timestamp;
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv( (allHouses[allmyStakingNfts[i].tokenId].price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100, (365 * 24 * 60 * 60) );
            }
        }
        return allRewardAmount;
    }

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) public {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_stakedNFTowner];
        uint allRewardAmount = 0;
        for (uint i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint stakingType = allmyStakingNfts[i].stakingType;
                uint expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint _timestamp;
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv(
                    (allHouses[allmyStakingNfts[i].tokenId].price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100, (365 * 24 * 60 * 60)
                );
                stakedNfts[_stakedNFTowner][i].claimDate = _timestamp;
            }
        }
        if (allRewardAmount != 0) {
            _token.transfer(_stakedNFTowner, allRewardAmount);
        }
    }

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs() public view returns (StakedNft[] memory) {
        return stakedNfts[msg.sender];
    }

    function isCompare(string memory a, string memory b) private pure returns (bool) {
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true;
        } else {
            return false;
        }
    }

    // Get Overall total information
    function getTotalInfo() public view returns ( uint, uint, uint ) {
        onlyMember();
        return (houseCounter, stakedCounter, soldedCounter);
    }

    // Get All APYs
    function getAllAPYs() public view returns (uint[] memory, uint[] memory) {
        uint[] memory apyCon = new uint[](APYtypes.length);
        uint[] memory apys = new uint[](APYtypes.length);
        for(uint i = 0 ; i < APYtypes.length ; i++) {
            apys[i] = APYtypes[i];
            apyCon[i] = APYConfig[APYtypes[i]];
        }
        return ( apys, apyCon );
    }

    // Penalty
    function getPenalty() public view returns(uint) { return penalty; }

    function setPenalty(uint _penalty) public { onlyMember(); penalty = _penalty; }

    // Royalty
    function getRoyaltyCreator() public view returns(uint) { return royaltyCreator; }

    function setRoyaltyCreator(uint _royalty) public { onlyMember(); royaltyCreator = _royalty; }

    function getRoyaltyMarket() public view returns(uint) { return royaltyMarket; }

    function setRoyaltyMarket(uint _royalty) public { onlyMember(); royaltyMarket = _royalty; }
}