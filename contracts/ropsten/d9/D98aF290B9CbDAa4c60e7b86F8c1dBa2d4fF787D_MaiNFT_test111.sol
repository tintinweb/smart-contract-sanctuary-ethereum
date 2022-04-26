/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.0;

abstract contract AccessControl {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }
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
}

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

}


contract ERC721 {
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    string public _baseTokenURI;

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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function isContract(address _addr) public view returns (bool is_contract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
}

abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

}

contract MaiNFT_test111 is ERC721, AccessControl, Pausable {

    address public contraceAddress = address(this);

    using Counters for Counters.Counter;
    using Strings for *;

    Counters.Counter internal _tokenIdTracker;


    struct TokenItem {
         uint256 tokenId; //token編號
         address owner; //擁有者
         string owner_id; //擁有者帳號
     }

    mapping(uint256 => TokenItem) private idTokenItem; //商品清單

    mapping(string => uint256[]) private userIdTokenItems; //使用者商品清單

    constructor(string memory token_name) ERC721("my test nft", "MNFT"){

        _baseTokenURI = "https://web/pictures/store/0N0qcaaSr0LMdUDlaxWr/token/";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    function assignMinterRole(address to) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721: must have admin role to assign");

        _setupRole(MINTER_ROLE, to);
    }


    function mint(address to, string memory to_id) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC721: must have minter role to mint");

        uint256 tokenId = _tokenIdTracker.current();

        address owner = to;

        _mint(owner, tokenId);
        _tokenIdTracker.increment();

        idTokenItem[tokenId] = TokenItem(
            tokenId,
            payable(owner),
            to_id
        );
        userIdTokenItems[to_id].push(tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mintTokenWithAmount(address to, string memory to_id, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC721: must have minter role to mint");

        for (uint i = 0; i < amount; i++) {
            mint(to, to_id);
        }
    }

    function getUserTokens(string memory user_id) public view returns (uint256[] memory) {
        return userIdTokenItems[user_id];
    }


    function fetchTokenItems() public view returns (TokenItem[] memory) {
        uint _itemCount = totalSupply();

        TokenItem[] memory items = new TokenItem[](_itemCount);
        for (uint i = 0; i < _itemCount; i++) {
            TokenItem storage currentItem = idTokenItem[i];
            items[i] = currentItem;
        }
        return items;
    }

    function TransferTo(address from, address to, uint256 tokenId) public {
        require(!paused(), "token is paused");
        require(_exists(tokenId), "token not exist");
        require(idTokenItem[tokenId].owner == msg.sender, "must owner to execute transaction");

        _transfer(from , to, tokenId);

        idTokenItem[tokenId].owner = to;
    }

    function getTokenItem(uint256 tokenId) public view returns (TokenItem memory){
        require(_exists(tokenId), "TokenItem not exist");
        return idTokenItem[tokenId];
    }


    function Pause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721: must have admin role to pause");
        _pause();
    }

    function UnPause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721: must have admin role to unpause");
        _unpause();
    }
}