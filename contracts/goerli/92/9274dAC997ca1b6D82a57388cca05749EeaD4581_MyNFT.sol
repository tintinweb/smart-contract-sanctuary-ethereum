/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
        mapping(address => uint256) bearerIndex;
        address[] addressList;
    }

    function add(Role storage role, address account) internal {
        require(account != address(0), "Roles: account is zero address");
        require(!has(role, account), "Roles: account has role");

        role.bearer[account] = true;
        role.bearerIndex[account] = role.addressList.length;
        role.addressList.push(account);
    }

    function remove(Role storage role, address account) internal {
        require(account != address(0), "Roles: account is zero address");
        require(has(role, account), "Roles: account does not have role");

        role.bearer[account] = false;
        role.addressList[role.bearerIndex[account]] = role.addressList[role.addressList.length - 1];
        role.bearerIndex[role.addressList[role.bearerIndex[account]]] = role.bearerIndex[account];
        role.addressList.pop();
    }

    function getAddressList(Role storage role) internal view returns (address[] memory) {
        return role.addressList;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is zero address");
        return role.bearer[account];
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: newOwner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BusinessRole is Ownable {
    address[] private _businesses;

    modifier onlyManager() {
        require(isOwner() || isBusiness(), "BusinessRole: caller is not business");
        _;
    }

    function isBusiness() public view returns (bool) {
        for (uint256 i = 0; i < _businesses.length; i++) {
            if (_businesses[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function getBusinessAddresses() public view returns (address[] memory) {
        return _businesses;
    }

    function setBusinessAddress(address[] memory businessAddresses) public onlyOwner {
        _businesses = businessAddresses;
    }
}

contract Lockable is Ownable {
    bool private _lockedContract;
    mapping(address => bool) private _userBlocks;

    constructor() {
        _lockedContract = false;
    }

    modifier onlyUnLocked(
        address sender,
        address from,
        address to
    ) {
        require(!isLockedContract(), "Auth: Contract is locked");
        bool isLocked = isLockedUser(sender) || isLockedUser(from) || isLockedUser(to);
        require(!isLocked, "Auth: User is locked");
        _;
    }

    function userBlocks(address account) public view returns (bool) {
        return _userBlocks[account];
    }

    function isLockedUser(address account) public view returns (bool) {
        return _userBlocks[account];
    }

    function isLockedContract() public view returns (bool) {
        return _lockedContract;
    }

    function toggleLock() public onlyOwner {
        _lockedContract = !_lockedContract;
    }

    function setBlockUser(address account, bool status) public onlyOwner {
        _userBlocks[account] = status;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     * type(IERC165).interfaceId == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721, ERC165 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

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
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => Counters.Counter) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner].current();
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = to;
        _balances[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _balances[owner].decrement();
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _balances[from].decrement();
        _balances[to].increment();

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ERC721Metadata is IERC721Metadata, ERC721 {
    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function _burn(address owner, uint256 tokenId) internal virtual override {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC165, ERC721Metadata, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal virtual override {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);

        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
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

contract ERC721Full is ERC721Enumerable {
    constructor(string memory name, string memory symbol) ERC721Metadata(name, symbol) {}
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract ChargeFee {
    IERC20 private _feeToken;
    uint256 private _minFee;
    address private _taker;

    function minFee() public view returns (uint256) {
        return _minFee;
    }

    function feeToken() public view returns (IERC20) {
        return _feeToken;
    }

    function taker() public view returns (address) {
        return _taker;
    }

    function _changeMinFee(uint256 feeAmount) internal {
        _minFee = feeAmount;
    }

    function _changeFeeToken(IERC20 feeToken_) internal {
        _feeToken = feeToken_;
    }

    function _changeTaker(address _newTaker) internal {
        _taker = _newTaker;
    }

    function chargeFee(address account) internal returns (bool) {
        if (_minFee > 0) {
            return _feeToken.transferFrom(account, _taker, _minFee);
        }
        return true;
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function minters() public view returns (address[] memory) {
        return _minters.getAddressList();
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    function addMinters(address[] memory minters_) public onlyMinter {
        for (uint256 i = 0; i < minters_.length; i++) {
            _addMinter(minters_[i]);
        }
    }
}

contract MyNFT is ChargeFee, ERC721Full, BusinessRole, MinterRole, Lockable {
    using Counters for Counters.Counter;

    event UpdateUser(uint256 indexed tokenId, address indexed user);

    struct meta {
        address creator;
    }

    struct UserInfo {
        address user;
        uint256 numberRenter;
    }

    mapping(uint256 => meta) public metadata;
    mapping(uint256 => UserInfo) internal _users;
    address public creator;
    uint256 public limit = 100000;

    constructor(
        string memory name_,
        string memory symbol_,
        address token_,
        address taker_,
        address creator_,
        uint256 limit_
    ) ERC721Full(name_, symbol_) {
        _changeFeeToken(IERC20(token_));
        _changeTaker(taker_);
        creator = creator_;
        _addMinter(creator_);
        limit = limit_;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(_users[tokenId].user == address(0), "NFT: tokenId was rented");
        super._transferFrom(from, to, tokenId);
        delete _users[tokenId];
    }

    function _burn(address owner, uint256 tokenId) internal override {
        require(_users[tokenId].user == address(0), "NFT: tokenId was rented");
        super._burn(owner, tokenId);
        delete _users[tokenId];
    }

    function setFeeToken(IERC20 feeToken) public onlyManager {
        _changeFeeToken(feeToken);
    }

    function setFee(address _newTaker, uint256 _newFeeAmount) public onlyOwner {
        _changeTaker(_newTaker);
        _changeMinFee(_newFeeAmount);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(ownerOf(tokenId), tokenId);
    }

    function mint(address to, uint256 tokenId) public onlyMinter returns (uint256) {
        _mint(to, tokenId);
        metadata[tokenId] = meta(creator);
        return tokenId;
    }

    function safeMint(address to, uint256 tokenId) public onlyMinter {
        _mint(to, tokenId);
        metadata[tokenId] = meta(creator);
    }

    function transfer(address to, uint256 tokenId) public {
        require(isBusiness() || chargeFee(msg.sender), "NFT: Charge fee has error");
        require(!isLockedUser(msg.sender) && !isLockedUser(to), "NFT: User is locked");
        return super.transferFrom(msg.sender, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(isBusiness() || chargeFee(from), "NFT: Charge fee has error");
        require(!isLockedUser(msg.sender) && !isLockedUser(from) && !isLockedUser(to), "NFT: User is locked");
        return super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(isBusiness() || chargeFee(from), "NFT: Charge fee has error");
        require(!isLockedUser(msg.sender) && !isLockedUser(from) && !isLockedUser(to), "NFT: User is locked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        require(isBusiness() || chargeFee(from), "NFT: Charge fee has error");
        require(!isLockedUser(msg.sender) && !isLockedUser(from) && !isLockedUser(to), "NFT: User is locked");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function getUser(uint256 tokenId) public view returns (UserInfo memory) {
        return _users[tokenId];
    }

    function setUser(uint256 tokenId, address user) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        UserInfo storage info = _users[tokenId];
        require(info.numberRenter < limit, "NFT: Exceeded rental limit");
        info.user = user;
        if (user != address(0)) {
            info.numberRenter = info.numberRenter + 1;
        }
        emit UpdateUser(tokenId, user);
    }

    function setLimit(uint256 limit_) public onlyOwner {
        limit = limit_;
    }
}