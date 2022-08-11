/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

abstract contract ERC165 is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
    uint256[50] private __gap;
}

library String {
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

abstract contract Context is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

library Counters {
    struct Counter {
        uint256 _value;
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

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Initializable, Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using String for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

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

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    uint256[44] private __gap;
}

abstract contract ERC721URIStorage is Initializable, ERC721 {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using String for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

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

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

abstract contract ERC721Enumerable is Initializable, ERC721, IERC721Enumerable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
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
    uint256[46] private __gap;
}

abstract contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

interface IERC20Upgradeable {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

abstract contract Pausable is Initializable, Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

abstract contract OwnerRecovery is Ownable {
    function recoverLostETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    uint256[50] private __gap;
}

interface IResource is IERC20 {
    function owner() external view returns (address);

    function swapTokenForUSDT(address account, uint256 amount) external;

    function accountBurn(address account, uint256 amount) external;

    function accountReward(address account, uint256 amount) external;

    function liquidityBurn(uint256 amount) external; 

    function liquidityReward(uint256 amount) external;
}

abstract contract ResourceImplementationPointer is Ownable {
    IResource internal resource;

    event UpdateResource(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyResource() {
        require(
            address(resource) != address(0),
            "ResourceImpl: Resource is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(resource),
            "ResourceImpl: Not Resource"
        );
        _;
    }

    function getResourceImplementation() public view returns (address) {
        return address(resource);
    }

    function changeResourceImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(resource);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "ResourceImpl: You can only set 0x0 or a contract address as a new implementation"
        );
        resource = IResource(newImplementation);
        emit UpdateResource(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

contract CTNC is
    Initializable,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    OwnerRecovery,
    ReentrancyGuard,
    ResourceImplementationPointer
{
    using Counters for Counters.Counter;
    using String for uint256;

    struct NFTEntity {
        uint256 id;
        uint256 lastProcessingTimestamp;
        uint256 amount;
        uint256 giftValue;
        uint256 totalClaimed;
        bool exists;
    }

    struct NFTEntityInfo {
        uint256 id;
        NFTEntity nft;
        uint256 rewardPerDay;
        uint256 rewardGift;
    }

    struct UserInfo {
        uint256 lastProcessingTimestamp;
        uint256 amount;
        uint256 totalClaimed;
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256[]) public nftsOfUser;
    mapping(uint256 => address[]) public usersOfNft;

    Counters.Counter private _nftCounter;
    mapping(uint256 => NFTEntity) private _nfts;

    address treasury;

    uint256 public rewardPerDay;
    uint256 public stakeMinValue;
    uint256 public compoundDelay;

    uint256 public giftFee;
    uint256 public compoundFee;
    uint256 public cashoutFee;

    uint256 private constant ONE_DAY = 86400;
    uint256 public totalValueLocked;
    uint256 public totalClaimed;

    uint256 public mintPrice;
    uint256 public constant maxSupply = 10000;

    string private _baseURIExtended;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public og;

    bool public presaleStarted;
    bool public presaleEnded;

    modifier checkPermissions(uint256 _nftId) {
        address sender = _msgSender();
        require(nftExists(_nftId), "CTNC: This nft doesn't exist");
        require(isOwnerOfNFT(sender, _nftId), "CTNC: You do not control this NFT");
        _;
    }

    modifier resourceSet() {
        require(address(resource) != address(0), "CTNC: Resource is not set");
        _;
    }

    function initialize(address _treasury) external initializer {
        __ERC721_init("CTNC", "TIGER");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        treasury = _treasury;
        
        changeStakeMinValue(10000 * 1e18);
        changeCompoundDelay(86400); // 24h
        changeRewardPerDay(34724);
        changeGiftFee(10);
        changeCompoundFee(10);
        changeCashoutFee(10);
        mintPrice = 1 * 1e17;
        _baseURIExtended = "ipfs://QmcUBHkeyh2SvVgDB3XF8AZBTNPSnw8xPUmFrtTZcMYgED/";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function airdropNFTs(uint256 nftNumber, address to) external nonReentrant whenNotPaused onlyOwner {
        require(nftNumber > 0 && nftNumber <= 1000, "CTNC: NFT Number should set between 1-1000");

        for (uint256 index = 0; index < nftNumber; index++) {
            _nftCounter.increment();
            uint256 newNFTId = _nftCounter.current();

            require(maxSupply >= newNFTId, "CTNC: total supply can never exceed max supply");

            _nfts[newNFTId] = NFTEntity({
                id: newNFTId,
                lastProcessingTimestamp: block.timestamp,
                amount: 0,
                giftValue: 0,
                totalClaimed: 0,
                exists: true
            });

            _mint(to, newNFTId);
        }
    }

    function createNFT(uint256 nftNumber) external payable nonReentrant whenNotPaused {
        address sender = _msgSender();

        require(presaleEnded, "CTNC: Presale hasn't ended yet.");
        require(nftNumber > 0 && nftNumber < 11, "CTNC: NFT Number should set between 1-10");
        require(mintPrice * nftNumber == msg.value, "CTNC: msg.value == mint_price * number");

        uint balance = address(this).balance;
        payable(treasury).transfer(balance);

        for (uint256 index = 0; index < nftNumber; index++) {
            _nftCounter.increment();
            uint256 newNFTId = _nftCounter.current();

            require(maxSupply >= newNFTId, "CTNC: total supply can never exceed max supply");

            _nfts[newNFTId] = NFTEntity({
                id: newNFTId,
                lastProcessingTimestamp: block.timestamp,
                amount: 0,
                giftValue: 0,
                totalClaimed: 0,
                exists: true
            });

            _mint(sender, newNFTId);
        }
    }

    function createNFTWhitelisted(uint256 nftNumber) external payable nonReentrant whenNotPaused {
        address sender = _msgSender();

        require(whitelisted[sender] == true || og[sender] == true, "sender is not whitelisted or og");
        require(presaleStarted, "CTNC: Presale hasn't started yet.");
        require(!presaleEnded, "CTNC: Presale has already ended.");
        require(nftNumber > 0 && nftNumber < 11, "CTNC: NFT Number should set between 1-10");

        uint256 price = 8 * 1e16;
        if (og[sender]) {
            price = 5 * 1e16;
        }

        require(price * nftNumber == msg.value, "CTNC: msg.value == mint_price * number");

        uint balance = address(this).balance;
        payable(treasury).transfer(balance);

        for (uint256 index = 0; index < nftNumber; index++) {
            _nftCounter.increment();
            uint256 newNFTId = _nftCounter.current();

            require(newNFTId <= 2000, "CTNC: presale supply can never exceed 2000");

            _nfts[newNFTId] = NFTEntity({
                id: newNFTId,
                lastProcessingTimestamp: block.timestamp,
                amount: 0,
                giftValue: 0,
                totalClaimed: 0,
                exists: true
            });

            _mint(sender, newNFTId);
        }
    }

    function stakeTokens(uint256 _nftId, uint256 _amount) external nonReentrant whenNotPaused resourceSet {
        address sender = _msgSender();
        require(stakeMinValue <= _amount, "CTNC: too less amount to stake");
        require(resource.balanceOf(sender) >= _amount, "CTNC: Balance too low to stake");

        resource.accountBurn(sender, _amount);

        totalValueLocked += _amount;

        NFTEntity storage nft = _nfts[_nftId];

        UserInfo storage user = userInfo[_nftId][sender];

        require(block.timestamp >= user.lastProcessingTimestamp + compoundDelay, "CTNC: You must wait by next time");

        uint256 lockingValue = _amount;
        uint256 giftValue;

        if (!isOwnerOfNFT(sender, _nftId)) {
            (lockingValue, giftValue) = getProcessingFee(_amount, giftFee);
        }

        nft.amount += _amount;
        nft.giftValue += giftValue;

        if (user.amount == 0) {
            uint256[] storage _nftsOfUser = nftsOfUser[sender];
            _nftsOfUser.push(_nftId);
            address[] storage _usersOfNft = usersOfNft[_nftId];
            _usersOfNft.push(sender);
        }

        user.lastProcessingTimestamp = block.timestamp;
        user.amount += lockingValue;
    }

    function cashoutReward(uint256 _nftId, bool swapping) external nonReentrant whenNotPaused resourceSet {
        address account = _msgSender();
        uint256 reward = _getNFTCashoutRewards(_nftId, account);
        _cashoutReward(reward, swapping);
    }

    function cashoutRewardFromGift(uint256 _nftId, bool swapping) external nonReentrant whenNotPaused resourceSet checkPermissions(_nftId) {
        uint256 reward = _getNFTCashoutRewardsFromGift(_nftId);
        _cashoutReward(reward, swapping);
    }

    function cashoutAll(bool swapping) external nonReentrant whenNotPaused resourceSet {
        address account = _msgSender();
        uint256 rewardsTotal = 0;

        uint256[] memory nfts = nftsOfUser[account];
        for (uint256 i = 0; i < nfts.length; i++) {
            rewardsTotal += _getNFTCashoutRewards(nfts[i], account);
        }
        _cashoutReward(rewardsTotal, swapping);
    }

    function compoundReward(uint256 _nftId) external nonReentrant whenNotPaused resourceSet {
        address account = _msgSender();
        (uint256 amountToCompound, uint256 feeAmount) = _getNFTCompoundRewards(_nftId, account);
        
        require(amountToCompound > 0, "CTNC: You must wait until you can compound again");
        if (feeAmount > 0) {
            resource.liquidityReward(feeAmount);
        }
    }

    function compoundAll() external nonReentrant whenNotPaused resourceSet {
        address account = _msgSender();
        uint256 feesAmount = 0;
        uint256 amountsToCompound = 0;
        uint256[] memory nfts = nftsOfUser[account];

        for (uint256 i = 0; i < nfts.length; i++) {
            (uint256 amountToCompound, uint256 feeAmount) = _getNFTCompoundRewards(nfts[i], account);
            if (amountToCompound > 0) {
                feesAmount += feeAmount;
                amountsToCompound += amountToCompound;
            }
        }

        require(amountsToCompound > 0, "CTNC: No rewards to compound");
        if (feesAmount > 0) {
            resource.liquidityReward(feesAmount);
        }
    }

    function _getNFTCashoutRewards(uint256 _nftId, address account) private returns (uint256) {
        NFTEntity storage nft = _nfts[_nftId];

        UserInfo storage user = userInfo[_nftId][account];

        if (block.timestamp < user.lastProcessingTimestamp + compoundDelay) {
            return 0;
        }

        uint256 reward = _calculateRewardsFromValue(user.amount, block.timestamp - user.lastProcessingTimestamp, rewardPerDay);
        nft.totalClaimed += reward;
        totalClaimed += reward;
        user.totalClaimed += reward;
        user.lastProcessingTimestamp = block.timestamp;

        return reward;
    }

    function _getNFTCashoutRewardsFromGift(uint256 _nftId) private returns (uint256) {
        NFTEntity storage nft = _nfts[_nftId];

        if (block.timestamp < nft.lastProcessingTimestamp + compoundDelay) {
            return 0;
        }

        uint256 reward = _calculateRewardsFromValue(nft.giftValue, block.timestamp - nft.lastProcessingTimestamp, rewardPerDay);
        nft.lastProcessingTimestamp = block.timestamp;
        nft.totalClaimed += reward;
        totalClaimed += reward;

        return reward;
    }

    function _getNFTCompoundRewards(uint256 _nftId, address account) private returns (uint256, uint256) {
        NFTEntity storage nft = _nfts[_nftId];
        UserInfo storage user = userInfo[_nftId][account];

        if (block.timestamp < user.lastProcessingTimestamp + compoundDelay) {
            return (0, 0);
        }

        uint256 reward = _calculateRewardsFromValue(user.amount, block.timestamp - user.lastProcessingTimestamp, rewardPerDay);
        if (reward > 0) {
            (uint256 amountToCompound, uint256 feeAmount) = getProcessingFee(reward, compoundFee);
            totalValueLocked += amountToCompound;

            nft.amount += amountToCompound;
            user.amount += amountToCompound;
            user.lastProcessingTimestamp = block.timestamp;

            return (amountToCompound, feeAmount);
        }

        return (0, 0);
    }

    function _cashoutReward(uint256 amount, bool swapping) private {
        require(amount > 0, "CTNC: You don't have enough reward to cash out");
        address to = _msgSender();
        (uint256 amountToReward, uint256 feeAmount) = getProcessingFee(amount, cashoutFee);
        if (swapping) {
            resource.swapTokenForUSDT(to, amountToReward);
        } else {
            resource.accountReward(to, amountToReward);
        }
        resource.liquidityReward(feeAmount);
    }

    function getProcessingFee(uint256 rewardAmount, uint256 _feeAmount) private pure returns (uint256, uint256) {
        uint256 feeAmount = 0;
        if (_feeAmount > 0) {
            feeAmount = (rewardAmount * _feeAmount) / 100;
        }
        return (rewardAmount - feeAmount, feeAmount);
    }

    function calculatePendingRewards(uint256 _amount, uint256 _lastProcessingTimestampuint256) public view returns (uint256) {
        return _calculateRewardsFromValue(_amount, block.timestamp - _lastProcessingTimestampuint256, rewardPerDay);
    }

    function calculateRewardsPerDay(uint256 _amount) public view returns (uint256) {
        return _calculateRewardsFromValue(_amount, ONE_DAY, rewardPerDay);
    }

    function _calculateRewardsFromValue(uint256 _amount, uint256 _timeRewards, uint256 _rewardPerDay) private pure returns (uint256) {
        uint256 rewards = (_timeRewards * _rewardPerDay) / 1000000;
        return (rewards * _amount) / 100000;
    }

    function currentNftId() public view returns (uint256) {
        return _nftCounter.current();
    }

    function nftExists(uint256 _nftId) public view returns (bool) {
        require(_nftId > 0, "CTNC: Id must be higher than zero");
        NFTEntity memory nft = _nfts[_nftId];
        if (nft.exists) {
            return true;
        }
        return false;
    }

    function isHolder(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function isOwnerOfNFT(address account, uint256 _nftId) public view returns (bool) {
        return ownerOf(_nftId) == account;
    }

    function getOwnedNFTIdsOf(address account) public view returns (uint256[] memory) {
        uint256 numberOfNFTs = balanceOf(account);
        uint256[] memory nftIds = new uint256[](numberOfNFTs);
        for (uint256 i = 0; i < numberOfNFTs; i++) {
            uint256 nftId = tokenOfOwnerByIndex(account, i);
            require(nftExists(nftId), "CTNC: This nft doesn't exist");
            nftIds[i] = nftId;
        }
        return nftIds;
    }

    function getAvailableNFTIdsOf(address account) public view returns (uint256[] memory) {
        uint256[] memory nftIds = nftsOfUser[account];
        return nftIds;
    }

    function getUsersOf(uint256 _nftId) public view returns (address[] memory) {
        address[] memory users = usersOfNft[_nftId];
        return users;
    }

    function getNFTsByIds(uint256[] memory _nftIds) external view returns (NFTEntityInfo[] memory) {
        NFTEntityInfo[] memory nftsInfo = new NFTEntityInfo[](_nftIds.length);

        for (uint256 i = 0; i < _nftIds.length; i++) {
            uint256 nftId = _nftIds[i];
            NFTEntity memory nft = _nfts[nftId];
            nftsInfo[i] = NFTEntityInfo(
                nftId,
                nft,
                _calculateRewardsFromValue(nft.amount, ONE_DAY, rewardPerDay),
                _calculateRewardsFromValue(nft.giftValue, nft.lastProcessingTimestamp, rewardPerDay)
            );
        }
        return nftsInfo;
    }

    function addWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1500, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    function removeWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }

    function addOg(address _address) external onlyOwner {
        og[_address] = true;
    }

    function addMultipleOg(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 500, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            og[_addresses[i]] = true;
        }
    }

    function removeOg(address _address) external onlyOwner {
        og[_address] = false;
    }

    function presaleStart() external onlyOwner {
        require(!presaleStarted, "CTNC: presale has already started");
        presaleStarted = true;
    }

    function presaleEnd() external onlyOwner {
        require(presaleStarted, "CTNC: sale has not started");
        require(!presaleEnded, "CTNC: sale has already ended");
        presaleEnded = true;
    }

    function changeStakeMinValue(uint256 _stakeMinValue) public onlyOwner {
        require(_stakeMinValue > 0, "CTNC: stakeMinValue must be greater than 0");
        stakeMinValue = _stakeMinValue;
    }

    function changeCompoundDelay(uint256 _compoundDelay) public onlyOwner {
        require(_compoundDelay > 0, "CTNC: compoundDelay must be greater than 0");
        compoundDelay = _compoundDelay;
    }

    function changeRewardPerDay(uint256 _rewardPerDay) public onlyOwner {
        require(_rewardPerDay > 0, "CTNC: rewardPerDay must be greater than 0");
        rewardPerDay = _rewardPerDay;
    }

    function changeMintPrice(uint256 _mintPrice) public onlyOwner {
        require(_mintPrice > 0, "CTNC: mintPrice must be greater than 0");
        mintPrice = _mintPrice;
    }

    function changeGiftFee(uint256 _giftFee) public onlyOwner {
        require(_giftFee <= 30, "CTNC:  Fee must be less than 30");
        giftFee = _giftFee;
    }

    function changeCompoundFee(uint256 _compoundFee) public onlyOwner {
        require(_compoundFee <= 30, "CTNC:  Fee must be less than 30");
        compoundFee = _compoundFee;
    }

    function changeCashoutFee(uint256 _cashoutFee) public onlyOwner {
        require(_cashoutFee <= 30, "CTNC:  Fee must be less than 30");
        cashoutFee = _cashoutFee;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 _nftId) external virtual nonReentrant onlyOwner whenNotPaused {
        _burn(_nftId);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        NFTEntity storage nft = _nfts[tokenId];
        nft.exists = false;
        ERC721URIStorage._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}