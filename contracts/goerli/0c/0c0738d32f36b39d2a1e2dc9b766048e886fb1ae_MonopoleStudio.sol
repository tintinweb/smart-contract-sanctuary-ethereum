/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: GPL-2.0-or-later
// File: interfaces/IMonopoleAllowlist.sol


pragma solidity =0.8.16;

/// @dev Support allowlist.
interface IMonopoleAllowlist {
    function isAllowed(address user) external view returns (bool);
}

// File: interfaces/IERC20.sol


pragma solidity =0.8.16;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: libraries/TransferHelper.sol


pragma solidity =0.8.16;


/// @dev Support ERC20 and !ERC20.
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) public {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper SafeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) public {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper SafeTransferFrom: transfer from failed"
        );
    }
}

// File: libraries/RemovableStringArray.sol


pragma solidity =0.8.16;

/// @dev Array function to delete element at index and re-organize the array.
library RemovableStringArray {
    function remove(string[] storage arr, uint256 index) public {
        require(arr.length > 0, "RemovableStringArray: 0");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}

// File: MonopoleListProject.sol


pragma solidity =0.8.16;


contract MonopoleListProject {
    using RemovableStringArray for string[];

    event AddHistory(string indexed history);
    event ProjectURI(
        string indexed oldProjectURI,
        string indexed newProjectURI
    );
    event Owner(address indexed oldOwner, address indexed newOwner);

    // Studio address
    address private _monopole;

    // Owner
    address private _owner;

    // Token name
    string private _name;

    // Project uri
    string private _projectURI;

    // Project history
    string[] private _history;

    // Deploy timestamp
    uint256 private _startTime;

    // modifier to check if caller is owner
    modifier isOwner() {
        _isOwner();
        _;
    }

    /**
     * @dev Initializes the contract by setting.
     */
    constructor(
        address projectOwner,
        string memory projectName,
        string memory projectExternalURI
    ) {
        require(projectOwner != address(0), "projectOwner: no");
        _monopole = msg.sender;
        _name = projectName;
        _projectURI = projectExternalURI;
        _owner = projectOwner;
        _startTime = block.timestamp;
        emit ProjectURI("", projectExternalURI);
        emit Owner(address(0), projectOwner);
    }

    function _isOwner() private view {
        require(msg.sender == _owner, "isOwner: no");
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function startTime() external view returns (uint256) {
        return _startTime;
    }

    function monopole() external view returns (address) {
        return _monopole;
    }

    function projectURI() external view returns (string memory) {
        return _projectURI;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function historyByIndex(uint256 index)
        external
        view
        returns (string memory)
    {
        return _history[index];
    }

    function historyLength() external view returns (uint256) {
        return _history.length;
    }

    function changeProjectURI(string memory uri) external isOwner {
        _projectURI = uri;
        emit ProjectURI(_projectURI, uri);
    }

    function changeOwner(address newOwner) external isOwner {
        require(newOwner != address(0), "changeOwner: newOwner");
        _owner = newOwner;
        emit Owner(_owner, newOwner);
    }

    function addHistory(string memory uri) external isOwner {
        _history.push(uri);
        emit AddHistory(uri);
    }

    function removeHistory(uint256 index) external isOwner {
        _history.remove(index);
    }
}

// File: libraries/IterableAddressBoolMapping.sol


pragma solidity =0.8.16;

/// @dev Iterable Mapping Address to Bool.
library IterableAddressBoolMapping {
    // Iterable mapping from address to bool;
    struct Map {
        address[] keys;
        mapping(address => bool) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (bool) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        bool val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// File: libraries/IterableAddressUintMapping.sol


pragma solidity =0.8.16;

/// @dev Iterable Mapping Address to Uint.
library IterableAddressUintMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// File: interfaces/IMonopoleStudio.sol


pragma solidity =0.8.16;

/// @dev Support Studio.
interface IMonopoleStudio {
    function allowed(address user) external view returns (bool);
}

// File: interfaces/IERC721Receiver.sol


pragma solidity =0.8.16;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: interfaces/IERC165.sol


pragma solidity =0.8.16;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: interfaces/IERC721.sol


pragma solidity =0.8.16;


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

// File: MonopoleSaleProject.sol


pragma solidity =0.8.16;








contract MonopoleSaleProject is IERC721 {
    using IterableAddressUintMapping for IterableAddressUintMapping.Map;
    using IterableAddressBoolMapping for IterableAddressBoolMapping.Map;
    using RemovableStringArray for string[];

    event Active(bool indexed activeState);
    event Public(bool indexed publicState);
    event Burnable(bool indexed burnableState);
    event AddHistory(string indexed history);
    event AddRewards(address indexed token, uint256 indexed amount);
    event MaxPerUser(
        uint256 indexed oldMaxPerUser,
        uint256 indexed newMaxPerUser
    );
    event ProjectURI(
        string indexed oldProjectURI,
        string indexed newProjectURI
    );
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

    // Sale enable
    bool private _active;

    // Sale is public
    bool private _public;

    // Token is burnable
    bool private _burnable;

    // Max per user
    uint256 private _maxPerUser;

    // Max supply
    uint256 private _maxSupply;

    // Token sale price
    uint256 private _price;

    // Token sale fees
    uint256 private _fees;

    // Deploy timestamp
    uint256 private _startTime;

    // Token sale
    address private _token;

    // Studio address
    address private _studio;

    // Fee receiver
    address private _feesReceiver;

    // Owner
    address private _owner;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Project uri
    string private _projectURI;

    // Project history
    string[] private _history;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping of allowed addresses
    IterableAddressBoolMapping.Map private _allowlist;

    // Mapping from token address to token amount
    IterableAddressUintMapping.Map private _rewards;

    // Mapping from user address to amount
    mapping(address => uint256) private _minted;

    // Mapping from token ID to token address to amount
    mapping(uint256 => mapping(address => uint256)) private _claimed;

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
        _isOwner();
        _;
    }

    // modifier to check if sale is active
    modifier isActive() {
        _isActive();
        _;
    }

    // modifier to check if caller is allowed
    modifier isAllowed() {
        _isAllowed();
        _;
    }

    // modifier to check if address is not 0
    modifier isAddress(address input) {
        _isAddress(input);
        _;
    }

    // modifier to check if caller is allowed on studio
    modifier isStudioAllowed() {
        _isStudioAllowed();
        _;
    }

    // modifier to check if max supply is reached
    modifier isUnderSupply(uint256 amount) {
        _isUnderSupply(amount);
        _;
    }

    // modifier to check if max mint per user is reached
    modifier isLimit(uint256 amount) {
        _isLimit(amount);
        _;
    }

    // modifier to check if token is burnable
    modifier isBurnable() {
        _isBurnable();
        _;
    }

    // modifier to check if caller is owner of tokenId
    modifier isTokenOwner(uint256 tokenId) {
        _isTokenOwner(tokenId);
        _;
    }

    // modifier to check if tokenId exists
    modifier exists(uint256 tokenId) {
        _exists(tokenId);
        _;
    }

    /// @dev Initializes the contract.
    constructor(
        uint256 monopoleFees,
        uint256 salePrice,
        uint256 totalMaxSupply,
        uint256 maxMintPerUser,
        address monopoleFeesReceiver,
        address saleToken,
        address saleOwner,
        string memory projectName,
        string memory projectSymbol,
        string memory projectExternalURI
    )
        isAddress(monopoleFeesReceiver)
        isAddress(saleToken)
        isAddress(saleOwner)
    {
        _public = true;
        _active = false;
        _burnable = false;
        _studio = msg.sender;
        _maxSupply = totalMaxSupply;
        _maxPerUser = maxMintPerUser;
        _fees = monopoleFees;
        _price = salePrice;
        _feesReceiver = monopoleFeesReceiver;
        _token = saleToken;
        _name = projectName;
        _symbol = projectSymbol;
        _projectURI = projectExternalURI;
        _owner = saleOwner;
        _startTime = block.timestamp;
        emit Public(true);
        emit Active(false);
        emit Burnable(false);
        emit MaxPerUser(0, maxMintPerUser);
        emit ProjectURI("", projectExternalURI);
        emit Owner(address(0), saleOwner);
    }

    function _isOwner() private view {
        require(msg.sender == _owner, "isOwner: no");
    }

    function _isActive() private view {
        require(_active, "isActive: no");
    }

    function _isAllowed() private view {
        if (!_public) {
            require(_allowlist.get(msg.sender), "isAllowed: no");
        }
    }

    function _isStudioAllowed() private view {
        require(
            IMonopoleStudio(_studio).allowed(msg.sender),
            "isStudioAllowed: no"
        );
    }

    function _isUnderSupply(uint256 amount) private view {
        require(amount > 0, "isUnderSupply: no");
        require(_allTokens.length + amount <= _maxSupply, "isUnderSupply: no");
    }

    function _isLimit(uint256 amount) private view {
        require(_minted[msg.sender] + amount <= _maxPerUser, "isLimit: no");
    }

    function _isBurnable() private view {
        require(_burnable, "isBurnable: no");
    }

    function _isAddress(address input) private pure {
        require(input != address(0), "isAddress: no");
    }

    function _isTokenOwner(uint256 tokenId) private view {
        require(msg.sender == _ownerOf[tokenId], "isTokenOwner: no");
    }

    function _exists(uint256 tokenId) private view {
        require(_ownerOf[tokenId] != address(0), "exists: no");
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

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function startTime() external view returns (uint256) {
        return _startTime;
    }

    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function maxPerUser() external view returns (uint256) {
        return _maxPerUser;
    }

    function studio() external view returns (address) {
        return _studio;
    }

    function projectURI() external view returns (string memory) {
        return _projectURI;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function activeSale() external view returns (bool) {
        return _active;
    }

    function publicSale() external view returns (bool) {
        return _public;
    }

    function burnable() external view returns (bool) {
        return _burnable;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function fees() external view returns (uint256) {
        return _fees;
    }

    function feesReceiver() external view returns (address) {
        return _feesReceiver;
    }

    function tokenSale() external view returns (address) {
        return _token;
    }

    function minted(address user) external view returns (uint256) {
        return _minted[user];
    }

    function history(uint256 index) external view returns (string memory) {
        return _history[index];
    }

    function historySize() external view returns (uint256) {
        return _history.length;
    }

    function allowed(address user) external view returns (bool) {
        return _allowlist.get(user);
    }

    function allowlistSize() external view returns (uint256) {
        return _allowlist.size();
    }

    function allowlistKeyAtIndex(uint256 index)
        external
        view
        returns (address)
    {
        return _allowlist.getKeyAtIndex(index);
    }

    function rewardsSize() external view returns (uint256) {
        return _rewards.size();
    }

    function rewardsKeyAtIndex(uint256 index) external view returns (address) {
        return _rewards.getKeyAtIndex(index);
    }

    function rewards(address token) external view returns (uint256) {
        return _rewards.get(token);
    }

    function claimable(uint256 tokenId, address token)
        public
        view
        exists(tokenId)
        returns (uint256)
    {
        return ((_rewards.get(token) / _allTokens.length) -
            _claimed[tokenId][token]);
    }

    function claimableUserToken(address user, address token)
        external
        view
        returns (uint256)
    {
        uint256 _balance = _balanceOf[user];
        require(_balance > 0, "claimableUserToken: no");

        uint256 _reward = _rewards.get(token);
        uint256 _supply = _allTokens.length;

        uint256 _claimable = 0;
        for (uint256 i = 0; i < _balance; i++) {
            _claimable += ((_reward / _supply) -
                _claimed[_ownedTokens[user][i]][token]);
        }
        return _claimable;
    }

    function claimableUser(address user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 _balance = _balanceOf[user];
        require(_balance > 0, "claimableUser: no");
        uint256 _shares = _allTokens.length;

        address[] memory _tokens;
        uint256[] memory _amounts;

        for (uint256 i = 0; i < _rewards.size(); i++) {
            address _earnedToken = _rewards.getKeyAtIndex(i);
            uint256 _reward = _rewards.get(_earnedToken);
            uint256 _amount = 0;
            for (uint256 index = 0; index < _balance; index++) {
                _amount += ((_reward / _shares) -
                    _claimed[_ownedTokens[user][index]][_earnedToken]);
            }
            _tokens[i] = _earnedToken;
            _amounts[i] = _amount;
        }
        return (_tokens, _amounts);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        exists(tokenId)
        returns (string memory)
    {
        return _projectURI;
    }

    function ownerOf(uint256 tokenId)
        external
        view
        exists(tokenId)
        returns (address)
    {
        return _ownerOf[tokenId];
    }

    function balanceOf(address user)
        external
        view
        isAddress(user)
        returns (uint256)
    {
        return _balanceOf[user];
    }

    function tokenOfOwnerByIndex(address user, uint256 index)
        external
        view
        isAddress(user)
        returns (uint256)
    {
        require(index < _balanceOf[user], "tokenOfOwnerByIndex: no");
        return _ownedTokens[user][index];
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _allTokens.length, "tokenByIndex: no");
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

    function getApproved(uint256 tokenId)
        external
        view
        exists(tokenId)
        returns (address)
    {
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
    ) public isAddress(to) {
        require(from == _ownerOf[tokenId], "transferFrom: not the owner");

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
            "safeTransferFrom: unsafe"
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
            "safeTransferFrom: unsafe"
        );
    }

    function changeMaxPerUser(uint256 max) external isOwner {
        _maxPerUser = max;
        emit MaxPerUser(_maxPerUser, max);
    }

    function changeProjectURI(string memory uri) external isOwner {
        _projectURI = uri;
        emit ProjectURI(_projectURI, uri);
    }

    function changeOwner(address newOwner)
        external
        isOwner
        isAddress(newOwner)
    {
        _owner = newOwner;
        emit Owner(_owner, newOwner);
    }

    function changeActive() external isOwner {
        _active = !_active;
        emit Active(!_active);
    }

    function changePublic() external isOwner {
        _public = !_public;
        emit Public(!_public);
    }

    function changeBurnable() external isOwner {
        _burnable = !_burnable;
        emit Burnable(!_burnable);
    }

    function addHistory(string memory uri) external isOwner {
        _history.push(uri);
        emit AddHistory(uri);
    }

    function removeHistory(uint256 index) external isOwner {
        _history.remove(index);
    }

    function addAllowlist(address user) external isOwner {
        _allowlist.set(user, true);
    }

    function batchAddAllowlist(address[] memory users) external isOwner {
        for (uint256 i = 0; i < users.length; i++) {
            _allowlist.set(users[i], true);
        }
    }

    function removeAllowlist(address user) external isOwner {
        _allowlist.remove(user);
    }

    function batchRemoveAllowlist(address[] memory users) external isOwner {
        for (uint256 i = 0; i < users.length; i++) {
            _allowlist.remove(users[i]);
        }
    }

    function addRewards(address token, uint256 amount) external isOwner {
        _rewards.set(token, amount + _rewards.get(token));

        emit AddRewards(token, amount);

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    function claimTokenByTokenId(uint256 tokenId, address token)
        external
        isTokenOwner(tokenId)
    {
        uint256 _claimable = claimable(tokenId, token);

        require(_claimable > 0, "claimTokenByTokenId: 0");

        _claimed[tokenId][token] += _claimable;

        TransferHelper.safeTransfer(token, msg.sender, _claimable);
    }

    function claimTokenByAllTokenIds(address token) external {
        uint256 _balance = _balanceOf[msg.sender];
        require(_balance > 0, "claimTokenByAllTokenIds: 0");

        uint256 _claimable = 0;
        for (uint256 i = 0; i < _balance; i++) {
            uint256 tokenId = _ownedTokens[msg.sender][i];

            uint256 _claimableTemp = claimable(tokenId, token);

            _claimed[tokenId][token] += _claimableTemp;

            _claimable += _claimableTemp;
        }

        require(_claimable > 0, "claimTokenByAllTokenIds: 0");

        TransferHelper.safeTransfer(token, msg.sender, _claimable);
    }

    function claimAllByTokenId(uint256 tokenId) external isTokenOwner(tokenId) {
        for (uint256 i = 0; i < _rewards.size(); i++) {
            address _earnedToken = _rewards.getKeyAtIndex(i);

            uint256 _claimable = claimable(tokenId, _earnedToken);

            if (_claimable > 0) {
                _claimed[tokenId][_earnedToken] += _claimable;

                TransferHelper.safeTransfer(
                    _earnedToken,
                    msg.sender,
                    _claimable
                );
            }
        }
    }

    function claim() external {
        uint256 _balance = _balanceOf[msg.sender];
        require(_balance > 0, "claimToken: 0");

        for (uint256 i = 0; i < _rewards.size(); i++) {
            address _earnedToken = _rewards.getKeyAtIndex(i);

            uint256 _claimable = 0;

            for (uint256 index = 0; index < _balance; index++) {
                uint256 _tokenId = _ownedTokens[msg.sender][index];

                uint256 _claimableTemp = claimable(_tokenId, _earnedToken);

                _claimed[_tokenId][_earnedToken] += _claimableTemp;

                _claimable += _claimableTemp;
            }
            if (_claimable > 0) {
                TransferHelper.safeTransfer(
                    _earnedToken,
                    msg.sender,
                    _claimable
                );
            }
        }
    }

    function mint(address to, uint256 amount)
        external
        isActive
        isStudioAllowed
        isAllowed
        isUnderSupply(amount)
        isLimit(amount)
        isAddress(to)
    {
        _minted[msg.sender] += amount;
        uint256 id = 0;
        while (id < amount) {
            uint256 newTokenId = _allTokens.length + 1;

            _beforeTokenTransfer(address(0), to, newTokenId);

            _balanceOf[to]++;
            _ownerOf[newTokenId] = to;

            emit Transfer(address(0), to, newTokenId);

            id++;
        }

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            _feesReceiver,
            _fees * amount
        );

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            _owner,
            _price * amount
        );
    }

    function burn(uint256 tokenId)
        external
        exists(tokenId)
        isBurnable
        isTokenOwner(tokenId)
    {
        _beforeTokenTransfer(msg.sender, address(0), tokenId);

        _balanceOf[msg.sender] -= 1;

        delete _ownerOf[tokenId];
        delete _approvals[tokenId];

        emit Transfer(msg.sender, address(0), tokenId);
    }
}

// File: MonopoleStudio.sol


pragma solidity =0.8.16;





contract MonopoleStudio {
    using IterableAddressBoolMapping for IterableAddressBoolMapping.Map;

    event Owner(address indexed oldOwner, address indexed newOwner);
 
    // Owner
    address private _owner;

    // Fee receiver
    address private _feesReceiver;

    // Allowlist address
    address private _allowlist;

    // Mapping of all projects addresses
    IterableAddressBoolMapping.Map private _projects;

    // Mapping of sale projects addresses
    IterableAddressBoolMapping.Map private _saleProjects;

    // Mapping of listed projects addresses
    IterableAddressBoolMapping.Map private _listProjects;

    // Mapping of trusted projects addresses
    IterableAddressBoolMapping.Map private _trustProjects;

    // modifier to check if address is not 0
    modifier isAddress(address input) {
        _isAddress(input);
        _;
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        _isOwner();
        _;
    }

    /// @dev Initializes the contract by setting.
    constructor(address monopoleFeesReceiver) isAddress(monopoleFeesReceiver) {
        _feesReceiver = monopoleFeesReceiver;
        _owner = msg.sender;
        emit Owner(address(0), msg.sender);
    }

    function _isAddress(address input) private pure {
        require(input != address(0), "isAddress: no");
    }

    function _isOwner() private view {
        require(msg.sender == _owner, "isOwner: no");
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function feesReceiver() external view returns (address) {
        return _feesReceiver;
    }

    function allowed(address user) external view returns (bool) {
        return IMonopoleAllowlist(_allowlist).isAllowed(user);
    }

    function isMonopoleProject(address project) external view returns (bool) {
        return _projects.get(project);
    }

    function isMonopoleSaleProject(address project)
        external
        view
        returns (bool)
    {
        return _saleProjects.get(project);
    }

    function isMonopoleTrustedProject(address project)
        external
        view
        returns (bool)
    {
        return _trustProjects.get(project);
    }

    function isMonopoleListedProject(address project)
        external
        view
        returns (bool)
    {
        return _listProjects.get(project);
    }

    function projectsLength() external view returns (uint256) {
        return _projects.size();
    }

    function projectsSaleLength() external view returns (uint256) {
        return _saleProjects.size();
    }

    function projectsListLength() external view returns (uint256) {
        return _listProjects.size();
    }

    function projectsTrustLength() external view returns (uint256) {
        return _trustProjects.size();
    }

    function projectAddress(uint256 index) external view returns (address) {
        return _projects.getKeyAtIndex(index);
    }

    function projectSaleAddress(uint256 index) external view returns (address) {
        return _saleProjects.getKeyAtIndex(index);
    }

    function projectListAddress(uint256 index) external view returns (address) {
        return _listProjects.getKeyAtIndex(index);
    }

    function projectTrustAddress(uint256 index)
        external
        view
        returns (address)
    {
        return _trustProjects.getKeyAtIndex(index);
    }

    function projectByIndex(uint256 index)
        external
        view
        returns (
            address,
            bool,
            bool,
            bool
        )
    {
        address project = _projects.getKeyAtIndex(index);
        return (
            project,
            _saleProjects.get(project),
            _listProjects.get(project),
            _trustProjects.get(project)
        );
    }

    function projectByAddress(address project)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            _saleProjects.get(project),
            _listProjects.get(project),
            _trustProjects.get(project)
        );
    }

    function changeOwner(address newOwner)
        external
        isOwner
        isAddress(newOwner)
    {
        _owner = newOwner;
        emit Owner(_owner, newOwner);
    }

    function changeFeesReceiver(address newReceiver)
        external
        isOwner
        isAddress(newReceiver)
    {
        _feesReceiver = newReceiver;
    }

    function changeAllowlist(address newAllowlist)
        external
        isOwner
        isAddress(newAllowlist)
    {
        _allowlist = newAllowlist;
    }

    function addSaleProject(address project) external isOwner {
        _saleProjects.set(project, true);
        _projects.set(project, true);
    }

    function addListProject(address project) external isOwner {
        _listProjects.set(project, true);
        _projects.set(project, true);
    }

    function addTrustProject(address project) external isOwner {
        require(
            (_saleProjects.get(project) || _listProjects.get(project)),
            "addTrustProject: is not project"
        );

        _trustProjects.set(project, true);
    }

    function removeSaleProject(address project) external isOwner {
        _saleProjects.remove(project);
        _trustProjects.remove(project);
        _projects.remove(project);
    }

    function removeListProject(address project) external isOwner {
        _listProjects.remove(project);
        _trustProjects.remove(project);
        _projects.remove(project);
    }

    function removeTrustProject(address project) external isOwner {
        _trustProjects.remove(project);
    }

    function createSaleProject(
        bool trusted_,
        uint256 fees_,
        uint256 price_,
        uint256 maxSupply_,
        uint256 maxPerUser_,
        address token_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory projectURI_
    ) external isOwner {
        MonopoleSaleProject _project = new MonopoleSaleProject(
            fees_,
            price_,
            maxSupply_,
            maxPerUser_,
            _feesReceiver,
            token_,
            owner_,
            name_,
            symbol_,
            projectURI_
        );

        _trustProjects.set(address(_project), trusted_);
        _saleProjects.set(address(_project), true);
        _projects.set(address(_project), true);
    }

    function createListProject(
        bool trusted_,
        address owner_,
        string memory name_,
        string memory projectURI_
    ) external isOwner {
        MonopoleListProject _project = new MonopoleListProject(
            owner_,
            name_,
            projectURI_
        );

        _trustProjects.set(address(_project), trusted_);
        _listProjects.set(address(_project), true);
        _projects.set(address(_project), true);
    }
}