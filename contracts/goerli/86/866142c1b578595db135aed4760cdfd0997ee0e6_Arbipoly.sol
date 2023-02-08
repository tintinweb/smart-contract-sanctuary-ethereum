/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.11;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
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

pragma solidity ^0.8.11;

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

pragma solidity ^0.8.11;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.11;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.11;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.11;

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

pragma solidity ^0.8.11;

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

pragma solidity ^0.8.11;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.11;

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.11;

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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

pragma solidity ^0.8.11;

pragma solidity ^0.8.11;

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.11;

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
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
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

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

    function mint(address tokenOwner, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PolyNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseTokenURI;

    IERC20 public polyToken;
    // Case & Family
    enum TokenType {
        None,
        RugcityCase, //------    Case    --------//
        HoneypotCase,
        StExitscamCase,
        DevisCase,
        SoftrugCase,
        ShitcoinCase,
        WhitelistedCase,
        PonziCase,
        DegenCase,
        ApeCase,
        IcoCase,
        DinocoinsCase,
        MoonshotCase,
        LiquidationCase,
        GemesCase,
        AlphasCase, //------    Family------------//
        RedactedCase,
        BrownFamily,
        GreyFamily,
        PurpleFamily,
        OrangeFamily,
        RedFamily,
        YellowFamily,
        BlueFamily
    }
    // tokenId => case type
    mapping(uint256 => TokenType) public _tokenTypes;
    // amount of token for each type
    mapping(TokenType => uint256) public _tokenCounts;
    // user's amoount of token for each type
    mapping(address => mapping(TokenType => uint256)) public _tokenCountsOfUser;
    // price[type] $POLY
    uint256[] public _prices = [
        0 ether, //None
        35000 ether, //Rugcity
        40000 ether, //Honeypot Land
        60000 ether, //St Exitscam
        65000 ether, //Devis Asleep
        70000 ether, //Softrug Boulevard
        80000 ether, //Shitcoin Paradise
        90000 ether, //Whitelisted
        100000 ether, //Ponzi Farm
        120000 ether, //Degen Area
        140000 ether, //Ape Territory
        180000 ether, //ICO Graveyard
        200000 ether, //Dinocoins City
        220000 ether, //Moonshot Street
        260000 ether, //Liquidation Park
        300000 ether, //Gems Kingdom
        360000 ether, //Alphas Heaven
        400000 ether //[Redacted]
    ];
    uint256 public upgradePrice = 5000 ether; // POLY
    // nft's position
    mapping(uint256 => TokenType) public casePositions;
    Arbipoly public arbipoly;

    // For test
    bool public mintFree = false;

    constructor(string memory baseURI, IERC20 tokenAddr)
        ERC721("ArbipolyNFT", "ARBPOL")
    {
        setBaseURI(baseURI);
        polyToken = tokenAddr;
        initState();
    }

    function initState() internal {
        casePositions[1] = TokenType.RugcityCase;
        casePositions[3] = TokenType.HoneypotCase;
        casePositions[4] = TokenType.StExitscamCase;
        casePositions[5] = TokenType.DevisCase;
        casePositions[6] = TokenType.SoftrugCase;
        casePositions[8] = TokenType.ShitcoinCase;
        casePositions[9] = TokenType.WhitelistedCase;
        casePositions[10] = TokenType.PonziCase;
        casePositions[11] = TokenType.DegenCase;
        casePositions[12] = TokenType.ApeCase;
        casePositions[14] = TokenType.IcoCase;
        casePositions[15] = TokenType.DinocoinsCase;
        casePositions[16] = TokenType.MoonshotCase;
        casePositions[18] = TokenType.LiquidationCase;
        casePositions[20] = TokenType.GemesCase;
        casePositions[22] = TokenType.AlphasCase;
        casePositions[23] = TokenType.RedactedCase;
    }

    function setArbipoly(Arbipoly _arbipoly) public onlyOwner {
        arbipoly = _arbipoly;
    }

    function setPolyToken(IERC20 _polyToken) public onlyOwner {
        polyToken = _polyToken;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

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
                ? string(
                    abi.encodePacked(
                        baseURI,
                        uint256(_tokenTypes[tokenId]).toString()
                    )
                )
                : ".json";
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // function mintNFTs(uint256 _count, TokenType tokenType) public payable {
    //     uint256 totalMinted = _tokenIds.current();
    //     require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs!");
    //     // require(
    //     //     _count > 0 && _count <= MAX_PER_MINT,
    //     //     "Cannot mint specified number of NFTs."
    //     // );
    //     // uint256 totalPrice = _prices[uint(tokenType)].mul(_count);
    //     // if(totalPrice > 0){
    //     //     require(
    //     //         polyToken.balanceOf(msg.sender) >= totalPrice,
    //     //         "Not enough $POLY to purchase NFTs."
    //     //     );
    //     //     require(
    //     //         polyToken.allowance(msg.sender, address(this)) >= totalPrice,
    //     //         "Allowance isn't enough"
    //     //     );
    //     //     polyToken.transferFrom(msg.sender, owner(), totalPrice);
    //     // }
    //     for (uint256 i = 0; i < _count; i++) {
    //         _mintSingleNFT(tokenType);
    //     }
    // }

    function mintNFT() public {
        // uint256 totalMinted = _tokenIds.current();
        // require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs!");
        (uint256 curPos, bool minted) = arbipoly.getPlayerPosMinted(msg.sender);
        TokenType tokenType = casePositions[curPos];
        require(
            tokenType != TokenType.None && !minted,
            "You didn't landed on NFT case or minted already"
        );
        if (!mintFree) {
            uint256 totalPrice = _prices[uint256(tokenType)];
            if (totalPrice > 0) {
                require(
                    polyToken.balanceOf(msg.sender) >= totalPrice,
                    "Not enough $POLY to purchase NFTs."
                );
                require(
                    polyToken.allowance(msg.sender, address(this)) >=
                        totalPrice,
                    "Allowance isn't enough"
                );
                polyToken.transferFrom(msg.sender, address(0), totalPrice);
            }
        }
        _mintSingleNFT(tokenType);
        arbipoly.setMinted(msg.sender);
        arbipoly.updateDailyRewards(msg.sender);
    }

    function _mintSingleNFT(TokenType tokenType) private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
        _tokenTypes[newTokenID] = tokenType;
        _tokenCounts[tokenType] = _tokenCounts[tokenType].add(1);
        _tokenCountsOfUser[msg.sender][tokenType] = _tokenCountsOfUser[
            msg.sender
        ][tokenType].add(1);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
        TokenType tokenType = getTypeOf(tokenId);
        _tokenCountsOfUser[from][tokenType] = _tokenCountsOfUser[from][
            tokenType
        ].sub(1);
        _tokenCountsOfUser[to][tokenType] = _tokenCountsOfUser[to][tokenType]
            .add(1);
        arbipoly.updateDailyRewards(from);
        arbipoly.updateDailyRewards(to);
    }

    function upgrade(address addr, TokenType tokenType) external {
        require(
            polyToken.balanceOf(msg.sender) >= upgradePrice,
            "Not enough $POLY to purchase NFTs."
        );
        require(
            polyToken.allowance(msg.sender, address(this)) >= upgradePrice,
            "Allowance isn't enough"
        );
        polyToken.transferFrom(msg.sender, address(0), upgradePrice);

        uint256[] memory tokenIdsInFamily = getTokenIdsInFamily(
            addr,
            tokenType
        );
        uint256 upgradableCount = getUpgradableCount(addr, tokenType);
        require(upgradableCount > 0, "There is no upgradable cases");
        uint256[] memory burnCounts = new uint256[](18);
        for (uint256 i = 0; i < tokenIdsInFamily.length; i++) {
            if (
                burnCounts[uint256(_tokenTypes[tokenIdsInFamily[i]])] <
                upgradableCount
            ) {
                _burn(tokenIdsInFamily[i]);
                burnCounts[uint256(_tokenTypes[tokenIdsInFamily[i]])]++;
            }
        }
        /// decrease burnt token from total counts
        if (tokenType == TokenType.BrownFamily) {
            _tokenCounts[TokenType.RugcityCase] = _tokenCounts[
                TokenType.RugcityCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.HoneypotCase] = _tokenCounts[
                TokenType.HoneypotCase
            ].sub(upgradableCount);
        } else if (tokenType == TokenType.GreyFamily) {
            _tokenCounts[TokenType.StExitscamCase] = _tokenCounts[
                TokenType.StExitscamCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.DevisCase] = _tokenCounts[
                TokenType.DevisCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.SoftrugCase] = _tokenCounts[
                TokenType.SoftrugCase
            ].sub(upgradableCount);
        } else if (tokenType == TokenType.PurpleFamily) {
            _tokenCounts[TokenType.ShitcoinCase] = _tokenCounts[
                TokenType.ShitcoinCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.WhitelistedCase] = _tokenCounts[
                TokenType.WhitelistedCase
            ].sub(upgradableCount);
        } else if (tokenType == TokenType.OrangeFamily) {
            _tokenCounts[TokenType.PonziCase] = _tokenCounts[
                TokenType.PonziCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.DegenCase] = _tokenCounts[
                TokenType.DegenCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.ApeCase] = _tokenCounts[TokenType.ApeCase]
                .sub(upgradableCount);
        } else if (tokenType == TokenType.RedFamily) {
            _tokenCounts[TokenType.IcoCase] = _tokenCounts[TokenType.IcoCase]
                .sub(upgradableCount);
            _tokenCounts[TokenType.DinocoinsCase] = _tokenCounts[
                TokenType.DinocoinsCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.MoonshotCase] = _tokenCounts[
                TokenType.MoonshotCase
            ].sub(upgradableCount);
        } else if (tokenType == TokenType.YellowFamily) {
            _tokenCounts[TokenType.LiquidationCase] = _tokenCounts[
                TokenType.LiquidationCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.GemesCase] = _tokenCounts[
                TokenType.GemesCase
            ].sub(upgradableCount);
        } else if (tokenType == TokenType.BlueFamily) {
            _tokenCounts[TokenType.AlphasCase] = _tokenCounts[
                TokenType.AlphasCase
            ].sub(upgradableCount);
            _tokenCounts[TokenType.RedactedCase] = _tokenCounts[
                TokenType.RedactedCase
            ].sub(upgradableCount);
        }

        /// decrease burnt token counts from user
        if (tokenType == TokenType.BrownFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.RugcityCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.RugcityCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.HoneypotCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.HoneypotCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.GreyFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.StExitscamCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.StExitscamCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.DevisCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.DevisCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.SoftrugCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.SoftrugCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.PurpleFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.ShitcoinCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.ShitcoinCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.WhitelistedCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.WhitelistedCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.OrangeFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.PonziCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.PonziCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.DegenCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.DegenCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.ApeCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.ApeCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.RedFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.IcoCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.IcoCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.DinocoinsCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.DinocoinsCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.MoonshotCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.MoonshotCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.YellowFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.LiquidationCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.LiquidationCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.GemesCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.GemesCase].sub(
                upgradableCount
            );
        } else if (tokenType == TokenType.BlueFamily) {
            _tokenCountsOfUser[msg.sender][
                TokenType.AlphasCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.AlphasCase].sub(
                upgradableCount
            );
            _tokenCountsOfUser[msg.sender][
                TokenType.RedactedCase
            ] = _tokenCountsOfUser[msg.sender][TokenType.RedactedCase].sub(
                upgradableCount
            );
        }
        for (uint256 i = 0; i < upgradableCount; i++) {
            _mintSingleNFT(tokenType);
        }
        arbipoly.updateDailyRewards(msg.sender);
    }

    // get all token Ids in family
    function getTokenIdsInFamily(address addr, TokenType tokenType)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = tokensOfOwner(addr);

        uint256 counter = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenType == TokenType.BrownFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.RugcityCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.HoneypotCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.GreyFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.StExitscamCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DevisCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.SoftrugCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.PurpleFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.ShitcoinCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.WhitelistedCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.OrangeFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.PonziCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DegenCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.ApeCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.RedFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.IcoCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DinocoinsCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.MoonshotCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.YellowFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.LiquidationCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.GemesCase
                ) {
                    counter++;
                }
            } else if (tokenType == TokenType.BlueFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.AlphasCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.RedactedCase
                ) {
                    counter++;
                }
            }
        }
        uint256[] memory tokenIdsInFamily = new uint256[](counter);
        counter = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenType == TokenType.BrownFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.RugcityCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.HoneypotCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.GreyFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.StExitscamCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DevisCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.SoftrugCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.PurpleFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.ShitcoinCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.WhitelistedCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.OrangeFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.PonziCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DegenCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.ApeCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.RedFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.IcoCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.DinocoinsCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.MoonshotCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.YellowFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.LiquidationCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.GemesCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            } else if (tokenType == TokenType.BlueFamily) {
                if (
                    _tokenTypes[tokenIds[i]] == TokenType.AlphasCase ||
                    _tokenTypes[tokenIds[i]] == TokenType.RedactedCase
                ) {
                    tokenIdsInFamily[counter] = tokenIds[i];
                    counter++;
                }
            }
        }
        return tokenIdsInFamily;
    }

    //  get counts of being upgradable to family
    function getUpgradableCount(address addr, TokenType tokenType)
        public
        view
        returns (uint256 upgradable)
    {
        if (tokenType == TokenType.BrownFamily) {
            uint256[] memory counts = new uint256[](2);
            counts[0] = _tokenCountsOfUser[addr][TokenType.RugcityCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.HoneypotCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.GreyFamily) {
            uint256[] memory counts = new uint256[](3);
            counts[0] = _tokenCountsOfUser[addr][TokenType.StExitscamCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.DevisCase];
            counts[2] = _tokenCountsOfUser[addr][TokenType.SoftrugCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.PurpleFamily) {
            uint256[] memory counts = new uint256[](2);
            counts[0] = _tokenCountsOfUser[addr][TokenType.ShitcoinCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.WhitelistedCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.OrangeFamily) {
            uint256[] memory counts = new uint256[](3);
            counts[0] = _tokenCountsOfUser[addr][TokenType.PonziCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.DegenCase];
            counts[2] = _tokenCountsOfUser[addr][TokenType.ApeCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.RedFamily) {
            uint256[] memory counts = new uint256[](3);
            counts[0] = _tokenCountsOfUser[addr][TokenType.IcoCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.DinocoinsCase];
            counts[2] = _tokenCountsOfUser[addr][TokenType.MoonshotCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.YellowFamily) {
            uint256[] memory counts = new uint256[](2);
            counts[0] = _tokenCountsOfUser[addr][TokenType.LiquidationCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.GemesCase];
            return getMinValue(counts);
        } else if (tokenType == TokenType.BlueFamily) {
            uint256[] memory counts = new uint256[](2);
            counts[0] = _tokenCountsOfUser[addr][TokenType.AlphasCase];
            counts[1] = _tokenCountsOfUser[addr][TokenType.RedactedCase];
            return getMinValue(counts);
        }
    }

    function getMinValue(uint256[] memory arr) internal pure returns (uint256) {
        uint256 min = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] < min) {
                min = arr[i];
            }
        }
        return min;
    }

    function getCountsOf(TokenType tokenType) public view returns (uint256) {
        return _tokenCounts[tokenType];
    }

    function getCountsOfTypeOf(address owner, TokenType tokenType)
        public
        view
        returns (uint256)
    {
        return _tokenCountsOfUser[owner][tokenType];
    }

    function getTypeOf(uint256 tokenId) public view returns (TokenType) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenTypes[tokenId];
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    ///// Test
    function setMintFree(bool free) public onlyOwner {
        mintFree = free;
    }
}

contract Arbipoly is Ownable {
    using SafeMath for uint256;
    IERC20 public polyToken;
    PolyNFT public polyNFT;

    uint256 public rollFee = 5000 ether; // POLY
    uint256 public rollDuration = 10 seconds;

    uint256 public CASE_COUNT = 24;
    enum CaseType {
        NFT,
        Start,
        Farming,
        Rewards120,
        Rewards150,
        DisableRewards,
        Rewards180
    }
    // position => case type, i.e 0: start
    mapping(uint256 => CaseType) public casePositions;
    // property of case, i.e start => 110(x1.1)
    // mapping(CaseType => uint256) public caseProperties;
    uint256 public divider = 100;
    // Rewards rate
    uint256 public startRate = 10; // x1.1 rewards bonus
    uint256 public bullishRate = 5; // in farming x1.05 rewards bonus
    uint256 public rewards120Rate = 20; //% of origin
    uint256 public rewards150Rate = 50;
    uint256 public rewards180Rate = 80;
    uint256 public boostDuration = 24 hours;
    uint256 public farmingRewardsRate = 5;
    uint256 public rewardDuration = 10 minutes; // 24 hours;
    // Family NFT rewards rate
    uint256 public brownRate = 150;
    uint256 public greyRate = 175;
    uint256 public purpleRate = 200;
    uint256 public orangeRate = 225;
    uint256 public redRate = 250;
    uint256 public yellowRate = 275;
    uint256 public blueRate = 300;
    // Disable duration
    uint256 public disableTimeCase = 12 hours;
    // daily rewards of NFT
    mapping(PolyNFT.TokenType => uint256) public nftRewards;
    // BostReward struct
    struct BoostReward {
        CaseType caseType; //Boost Type
        uint256 startTime; //start time of reward
        uint256 originReward; //orginal staking
        uint256 remainTime; //remain time of reward
    }
    // DailyRewards struct
    struct DailyReward {
        uint256 startTime; // time to start new daily rewards
        uint256 rewards; // daily rewards = dailyRewards + dailyBonus
    }
    //  Player info
    struct Player {
        uint256 lastRollTime;
        uint256 dice;
        uint256 curPos;
        uint256 lastRewardTime;
        uint256 rewardClaimed;
        uint256 startBonusCounts;
        uint256 bullishBonusCounts;
        uint256 disableStartTime;
        uint256 disableRemainTime;
        bool minted; // true if mint when land on NFT case,
        uint256 farming;
        // rewards type => start boost time
        BoostReward[3] boostRewards;
        // daily rewards history that will be claimed
        DailyReward[] dailyRewards;
    }

    mapping(address => Player) public players;
    bool public claimable = true;

    /*---------     Events      -----------*/
    event RolledDice(
        address indexed player,
        uint256 dice,
        uint256 pos,
        uint256 data
    );
    event RewardClaimed(address indexed player, uint256 rewards);
    event MoveTo(address indexed player, uint256 pos);

    /////       Test
    bool public rollFree = false;
    bool public forceFarm = false;

    constructor(IERC20 _polyToken, PolyNFT _polyNFT) {
        polyToken = _polyToken;
        polyNFT = _polyNFT;
        initState();
    }

    function initState() internal {
        //------    init casePositions
        casePositions[0] = CaseType.Start;
        casePositions[2] = CaseType.Farming;
        casePositions[7] = CaseType.Rewards120;
        casePositions[13] = CaseType.Farming;
        casePositions[17] = CaseType.Rewards150;
        casePositions[19] = CaseType.DisableRewards;
        casePositions[21] = CaseType.Rewards180;
        //------    init daily case NFT rewards
        nftRewards[PolyNFT.TokenType.RugcityCase] = 175000 ether;
        nftRewards[PolyNFT.TokenType.HoneypotCase] = 200000 ether;
        nftRewards[PolyNFT.TokenType.StExitscamCase] = 300000 ether;
        nftRewards[PolyNFT.TokenType.DevisCase] = 325000 ether;
        nftRewards[PolyNFT.TokenType.SoftrugCase] = 375000 ether;
        nftRewards[PolyNFT.TokenType.ShitcoinCase] = 400000 ether;
        nftRewards[PolyNFT.TokenType.WhitelistedCase] = 450000 ether;
        nftRewards[PolyNFT.TokenType.PonziCase] = 500000 ether;
        nftRewards[PolyNFT.TokenType.DegenCase] = 600000 ether;
        nftRewards[PolyNFT.TokenType.ApeCase] = 700000 ether;
        nftRewards[PolyNFT.TokenType.IcoCase] = 900000 ether;
        nftRewards[PolyNFT.TokenType.DinocoinsCase] = 1000000 ether;
        nftRewards[PolyNFT.TokenType.MoonshotCase] = 1100000 ether;
        nftRewards[PolyNFT.TokenType.LiquidationCase] = 1300000 ether;
        nftRewards[PolyNFT.TokenType.GemesCase] = 1500000 ether;
        nftRewards[PolyNFT.TokenType.AlphasCase] = 1800000 ether;
        nftRewards[PolyNFT.TokenType.RedactedCase] = 2000000 ether;
        //--------      init daily family NFT rewards
        nftRewards[PolyNFT.TokenType.BrownFamily] = nftRewards[
            PolyNFT.TokenType.RugcityCase
        ].add(nftRewards[PolyNFT.TokenType.HoneypotCase]).mul(brownRate).div(
                divider
            );
        nftRewards[PolyNFT.TokenType.GreyFamily] = nftRewards[
            PolyNFT.TokenType.StExitscamCase
        ]
            .add(nftRewards[PolyNFT.TokenType.DevisCase])
            .add(nftRewards[PolyNFT.TokenType.SoftrugCase])
            .mul(greyRate)
            .div(divider);
        nftRewards[PolyNFT.TokenType.PurpleFamily] = nftRewards[
            PolyNFT.TokenType.ShitcoinCase
        ]
            .add(nftRewards[PolyNFT.TokenType.WhitelistedCase])
            .mul(purpleRate)
            .div(divider);
        nftRewards[PolyNFT.TokenType.OrangeFamily] = nftRewards[
            PolyNFT.TokenType.PonziCase
        ]
            .add(nftRewards[PolyNFT.TokenType.DegenCase])
            .add(nftRewards[PolyNFT.TokenType.ApeCase])
            .mul(orangeRate)
            .div(divider);
        nftRewards[PolyNFT.TokenType.RedFamily] = nftRewards[
            PolyNFT.TokenType.IcoCase
        ]
            .add(nftRewards[PolyNFT.TokenType.DinocoinsCase])
            .add(nftRewards[PolyNFT.TokenType.MoonshotCase])
            .mul(redRate)
            .div(divider);
        nftRewards[PolyNFT.TokenType.YellowFamily] = nftRewards[
            PolyNFT.TokenType.LiquidationCase
        ].add(nftRewards[PolyNFT.TokenType.GemesCase]).mul(yellowRate).div(
                divider
            );
        nftRewards[PolyNFT.TokenType.BlueFamily] = nftRewards[
            PolyNFT.TokenType.AlphasCase
        ].add(nftRewards[PolyNFT.TokenType.RedactedCase]).mul(blueRate).div(
                divider
            );
    }

    function setRewardToken(IERC20 _polyToken) external onlyOwner {
        polyToken = _polyToken;
    }

    function setPolyNFT(PolyNFT _polyNFT) external onlyOwner {
        polyNFT = _polyNFT;
    }

    function setRollDuration(uint256 duration) external onlyOwner {
        rollDuration = duration;
    }

    function setRollFee(uint256 fee) external onlyOwner {
        rollFee = fee;
    }

    function rollDice() external {
        if (!rollFree) {
            require(
                polyToken.balanceOf(msg.sender) >= rollFee,
                "Not enough $POLY to purchase NFTs."
            );
            require(
                polyToken.allowance(msg.sender, address(this)) >= rollFee,
                "Allowance isn't enough"
            );
            polyToken.transferFrom(msg.sender, address(0), rollFee);
            // polyToken.burn(rollFee); // burn POLY
        }
        Player storage player = players[msg.sender];
        // starter player set now to lastRewardTime for calc elapsed of first claiming
        if (player.lastRewardTime == 0) {
            player.lastRewardTime = block.timestamp;
            updateDailyRewards(msg.sender);
        }
        if (!rollFree) {
            require(
                block.timestamp.sub(players[msg.sender].lastRollTime) >
                    rollDuration,
                "It's not time for rolling"
            );
        }
        player.lastRollTime = block.timestamp;
        uint256 dice = random().mod(6).add(1);
        player.dice = dice;
        uint256 oldPosition = player.curPos;
        // For test
        if (forceFarm) {
            player.curPos = 2; //force landing on farm
        } else {
            player.curPos = player.curPos.add(dice).mod(CASE_COUNT);
        }
        // uint curPos = (uint)casePositions[player.curPos];
        // if user passed Start case
        if (player.curPos < oldPosition) {
            player.startBonusCounts = player.startBonusCounts.add(1);
            updateDailyRewards(msg.sender);
        }
        // if user lands Rewards Boost case
        uint256 dailyRewards = getLastDailyRewards(msg.sender);
        if (casePositions[player.curPos] == CaseType.Rewards120) {
            BoostReward storage boostReward = player.boostRewards[0];
            boostReward.originReward = dailyRewards.mul(rewards120Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        if (casePositions[player.curPos] == CaseType.Rewards150) {
            BoostReward storage boostReward = player.boostRewards[1];
            boostReward.originReward = dailyRewards.mul(rewards150Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        if (casePositions[player.curPos] == CaseType.Rewards180) {
            BoostReward storage boostReward = player.boostRewards[2];
            boostReward.originReward = dailyRewards.mul(rewards180Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        // if user lands disable rewards 24h
        if (casePositions[player.curPos] == CaseType.DisableRewards) {
            if (player.disableStartTime == 0) {
                player.disableStartTime = block.timestamp;
            }
            player.disableRemainTime = disableTimeCase;
        }
        // if user lands farming
        if (casePositions[player.curPos] == CaseType.Farming) {
            uint256 rand = random().mod(100);
            if (rand >= 0 && rand <= 39) {
                // rewards bonus x1.05
                player.bullishBonusCounts = player.bullishBonusCounts.add(1);
                player.farming = 0;
                updateDailyRewards(msg.sender);
            } else if (rand >= 40 && rand <= 69) {
                // Remove disable rewards
                player.disableStartTime = 0;
                player.disableRemainTime = 0;
                player.farming = 2;
            } else if (rand >= 70 && rand <= 89) {
                // Move the case you want
                player.farming = 1;
            } else {
                player.farming = 3;
            }
        }
        if (casePositions[player.curPos] == CaseType.NFT) {
            player.minted = false;
        }
        emit RolledDice(msg.sender, dice, player.curPos, player.farming);

        // uint256 balance = address(this).balance;
        // require(balance > 0, "No ether left to withdraw");
        // (bool success, ) = owner().call{value: balance}("");
        // require(success, "Transfer failed.");
    }

    function moveTo(uint256 pos) external {
        require(pos < CASE_COUNT, "You chose out of pos");
        Player storage player = players[msg.sender];
        require(
            casePositions[player.curPos] == CaseType.Farming &&
                player.farming == 1,
            "You can't move"
        );
        // starter player set now to lastRewardTime for calc elapsed of first claiming
        if (player.lastRewardTime == 0) {
            player.lastRewardTime = block.timestamp;
            updateDailyRewards(msg.sender);
        }

        uint256 oldPosition = player.curPos;
        player.curPos = pos;
        // uint curPos = (uint)casePositions[player.curPos];
        // if user passed Start case
        if (player.curPos < oldPosition) {
            player.startBonusCounts = player.startBonusCounts.add(1);
            updateDailyRewards(msg.sender);
        }
        uint256 dailyRewards = getLastDailyRewards(msg.sender);
        // if user lands Rewards Boost case
        if (casePositions[player.curPos] == CaseType.Rewards120) {
            BoostReward storage boostReward = player.boostRewards[0];
            boostReward.originReward = dailyRewards.mul(rewards120Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        if (casePositions[player.curPos] == CaseType.Rewards150) {
            BoostReward storage boostReward = player.boostRewards[1];
            boostReward.originReward = dailyRewards.mul(rewards150Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        if (casePositions[player.curPos] == CaseType.Rewards180) {
            BoostReward storage boostReward = player.boostRewards[2];
            boostReward.originReward = dailyRewards.mul(rewards180Rate).div(
                divider
            );
            if (boostReward.startTime == 0) {
                boostReward.startTime = block.timestamp;
            }
            boostReward.remainTime = boostDuration;
        }
        // if user lands disable rewards 24h
        if (casePositions[player.curPos] == CaseType.DisableRewards) {
            if (player.disableStartTime == 0) {
                player.disableStartTime = block.timestamp;
            }
            player.disableRemainTime = disableTimeCase;
        }
        // if user lands farming
        if (casePositions[player.curPos] == CaseType.Farming) {
            uint256 rand = random().mod(100);
            if (rand >= 0 && rand <= 24) {
                // rewards bonus x1.05
                player.bullishBonusCounts = player.bullishBonusCounts.add(1);
                player.farming = 0;
                updateDailyRewards(msg.sender);
            } else if (rand >= 25 && rand <= 49) {
                // Move the case you want
                player.farming = 1;
            } else if (rand >= 50 && rand <= 74) {
                // Remove disable rewards
                player.disableStartTime = 0;
                player.disableRemainTime = 0;
                player.farming = 2;
            } else {
                player.farming = 3;
            }
        }
        if (casePositions[player.curPos] == CaseType.NFT) {
            player.minted = false;
        }

        emit MoveTo(msg.sender, pos);
    }

    function calcDailyRewards(address addr) public view returns (uint256) {
        uint256[] memory tokenIds = polyNFT.tokensOfOwner(addr);
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            PolyNFT.TokenType tokenType = polyNFT.getTypeOf(tokenIds[i]);
            rewards = rewards.add(
                nftRewards[tokenType]
                    .mul(polyNFT.getCountsOfTypeOf(addr, tokenType))
                    .div(polyNFT.getCountsOf(tokenType))
            );
        }
        return rewards;
    }

    function calcDailyBonus(address addr) public view returns (uint256) {
        uint256 dailyRewards = calcDailyRewards(addr);
        uint256 startBonusCounts = players[addr].startBonusCounts;
        uint256 bullishBonusCounts = players[addr].bullishBonusCounts;
        uint256 bonus;
        uint256 startBonus = dailyRewards;
        uint256 bullishBonus = dailyRewards;
        for (uint256 i = 0; i < startBonusCounts; i++) {
            startBonus = startBonus.mul(divider + startRate).div(divider);
        }
        for (uint256 i = 0; i < bullishBonusCounts; i++) {
            bullishBonus = bullishBonus.mul(divider + bullishRate).div(divider);
        }
        if (startBonusCounts > 0) {
            bonus = bonus.add(startBonus - dailyRewards);
        }
        if (bullishBonusCounts > 0) {
            bonus = bonus.add(bullishBonus - dailyRewards);
        }
        return bonus;
    }

    function updateDailyRewards(address addr) public {
        Player storage player = players[addr];
        DailyReward memory dailyReward = DailyReward(
            block.timestamp,
            calcDailyRewards(addr).add(calcDailyBonus(addr))
        );
        player.dailyRewards.push(dailyReward);
    }

    function getLastDailyRewards(address addr) public view returns (uint256) {
        if (players[addr].dailyRewards.length > 0) {
            return players[addr]
                    .dailyRewards[players[addr].dailyRewards.length - 1]
                    .rewards;
        }else{
            return 0;
        }
        // require(players[addr].dailyRewards.length > 0, "DailyRewards is empty");
    }

    function random() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return seed;
    }

    function setMinted(address addr) public {
        require(PolyNFT(msg.sender) == polyNFT, "Caller isn't PolyNFT");
        require(players[addr].lastRollTime > 0, "You are not player");
        players[addr].minted = true;
    }

    function claim() external {
        require(claimable, "claim not available");
        Player storage player = players[msg.sender];
        require(player.lastRollTime > 0, "You don't have rewards");
        uint256 totalRewards = 0;
        // uint dailyRewards = calcDailyRewards(msg.sender);
        uint256 elapsed = block.timestamp - player.lastRewardTime;
        require(
            !(player.lastRewardTime == player.disableStartTime &&
                elapsed <= player.disableRemainTime),
            "You are disabled to reward now"
        );
        if (player.disableStartTime > 0) {
            ////    calculate boost rewards
            for (uint256 i = 0; i < player.boostRewards.length; i++) {
                BoostReward storage boostReward = player.boostRewards[i];
                if (boostReward.startTime == 0) {
                    continue;
                }
                //  boostReward is started before disableReward
                if (boostReward.startTime < player.disableStartTime) {
                    // boost ends before disableReward
                    if (
                        boostReward.startTime + boostReward.remainTime <=
                        player.disableStartTime
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(boostReward.remainTime)
                                .div(boostDuration)
                        );
                        boostReward.startTime = 0;
                        //  boost ends while disableReward
                    } else if (
                        boostReward.startTime + boostReward.remainTime <=
                        player.disableStartTime + player.disableRemainTime
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(
                                    boostReward.startTime +
                                        boostReward.remainTime -
                                        player.disableStartTime
                                )
                                .div(boostDuration)
                        );
                        boostReward.startTime = 0;
                    }
                    //  boostReward is started while disableReward
                } else if (
                    boostReward.startTime >= player.disableStartTime &&
                    boostReward.startTime <
                    player.disableStartTime + player.disableRemainTime
                ) {
                    // boostReward ends while disableReward
                    if (
                        boostReward.startTime + boostReward.remainTime <=
                        player.disableStartTime + player.disableRemainTime
                    ) {
                        boostReward.startTime = 0;
                    } else {
                        // boostReward ended before claiming
                        if (
                            boostReward.startTime + boostReward.remainTime <=
                            block.timestamp
                        ) {
                            totalRewards = totalRewards.add(
                                boostReward
                                    .originReward
                                    .mul(
                                        boostReward.startTime +
                                            boostReward.remainTime -
                                            player.disableStartTime -
                                            player.disableRemainTime
                                    )
                                    .div(boostDuration)
                            );
                            boostReward.startTime = 0;
                            // boostReward doesn't end before claiming
                        } else {
                            // disableReward ended before claiming
                            if (
                                player.disableStartTime +
                                    player.disableRemainTime <
                                block.timestamp
                            ) {
                                totalRewards = totalRewards.add(
                                    boostReward
                                        .originReward
                                        .mul(
                                            block.timestamp -
                                                player.disableStartTime -
                                                player.disableRemainTime
                                        )
                                        .div(boostDuration)
                                );
                                boostReward.remainTime = boostReward
                                    .remainTime
                                    .sub(
                                        block.timestamp - boostReward.startTime
                                    );
                                boostReward.startTime = block.timestamp;
                                // disableReward not end before claiming
                            } else {
                                boostReward.remainTime = boostReward
                                    .remainTime
                                    .sub(
                                        block.timestamp - boostReward.startTime
                                    );
                                boostReward.startTime = block.timestamp;
                            }
                        }
                    }
                    //  boostReward started after disableReward
                } else {
                    // boostReward ended before claiming
                    if (
                        boostReward.startTime + boostReward.remainTime <=
                        block.timestamp
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(boostReward.remainTime)
                                .div(boostDuration)
                        );
                        boostReward.startTime = 0;
                        // boostReward not ended before claiming
                    } else {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(block.timestamp - boostReward.startTime)
                                .div(boostDuration)
                        );
                        boostReward.remainTime = boostReward.remainTime.sub(
                            block.timestamp - boostReward.startTime
                        );
                        boostReward.startTime = block.timestamp;
                    }
                }
            }
            ////    calculate daily rewards
            for (uint256 i = 0; i < player.dailyRewards.length; i++) {
                uint256 startTime = player.dailyRewards[i].startTime;
                uint256 duration;
                uint256 dailyRewards = player.dailyRewards[i].rewards;
                if (i < player.dailyRewards.length - 1) {
                    duration = player.dailyRewards[i + 1].startTime.sub(
                        player.dailyRewards[i].startTime
                    );
                } else {
                    duration =
                        block.timestamp -
                        player.dailyRewards[i].startTime;
                }
                // rewards start and ends before disable or rewards start after disable
                if (
                    startTime + duration <= player.disableStartTime ||
                    startTime >=
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards.mul(duration).div(rewardDuration)
                    );
                    // rewards start before disable and ends while disable
                } else if (
                    startTime < player.disableStartTime &&
                    startTime + duration <=
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(player.disableStartTime - startTime)
                            .div(rewardDuration)
                    );
                    // rewards start before disable and ends after disable
                } else if (
                    startTime < player.disableStartTime &&
                    startTime + duration >
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(duration - player.disableRemainTime)
                            .div(rewardDuration)
                    );
                    // rewards start while disable and ends after disable
                } else if (
                    startTime >= player.disableStartTime &&
                    startTime + duration >
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(
                                startTime +
                                    duration -
                                    player.disableStartTime -
                                    player.disableRemainTime
                            )
                            .div(rewardDuration)
                    );
                }
            }
            /// update disableStartTime and remainTime
            if (
                block.timestamp >
                player.disableStartTime + player.disableRemainTime
            ) {
                player.disableStartTime = 0;
                player.disableRemainTime = 0;
            } else {
                player.disableRemainTime = player.disableRemainTime.sub(
                    block.timestamp - player.disableStartTime
                );
                player.disableStartTime = block.timestamp;
            }
            // no disableReward
        } else {
            //calculate boost rewards
            for (uint256 i = 0; i < player.boostRewards.length; i++) {
                BoostReward storage boostReward = player.boostRewards[i];
                if (boostReward.startTime == 0) {
                    continue;
                }
                // claim after boostReward
                if (
                    boostReward.startTime + boostReward.remainTime <=
                    block.timestamp
                ) {
                    totalRewards = totalRewards.add(
                        boostReward
                            .originReward
                            .mul(boostReward.remainTime)
                            .div(boostDuration)
                    );
                    boostReward.startTime = 0;
                    // claim while boostReward
                } else {
                    totalRewards = totalRewards.add(
                        boostReward
                            .originReward
                            .mul(block.timestamp - boostReward.startTime)
                            .div(boostDuration)
                    );
                    boostReward.remainTime = boostReward.remainTime.sub(
                        block.timestamp - boostReward.startTime
                    );
                    boostReward.startTime = block.timestamp;
                }
            }
            //  calculate daily rewards
            for (uint256 i = 0; i < player.dailyRewards.length; i++) {
                uint256 duration;
                uint256 dailyRewards = player.dailyRewards[i].rewards;
                if (i < player.dailyRewards.length - 1) {
                    duration = player.dailyRewards[i + 1].startTime.sub(
                        player.dailyRewards[i].startTime
                    );
                } else {
                    duration =
                        block.timestamp -
                        player.dailyRewards[i].startTime;
                }
                totalRewards = totalRewards.add(
                    dailyRewards.mul(duration).div(rewardDuration)
                );
            }
        }
        require(polyToken.mint(msg.sender, totalRewards), "mint token failed");
        player.lastRewardTime = block.timestamp;
        player.rewardClaimed = player.rewardClaimed.add(totalRewards);
        delete player.dailyRewards;
        updateDailyRewards(msg.sender);
        emit RewardClaimed(msg.sender, totalRewards);
    }

    // calcualte claimable rewards
    function calcClaimableRewards(address addr) public view returns (uint256) {
        Player memory player = players[addr];
        uint256 totalRewards = 0;
        uint256 elapsed = block.timestamp - player.lastRewardTime;
        if (
            player.lastRewardTime == player.disableStartTime &&
            elapsed <= player.disableRemainTime
        ) {
            return 0;
        }
        if (player.lastRollTime == 0) {
            return 0;
        }
        if (player.disableStartTime > 0) {
            ////    calculate boost rewards
            for (uint256 i = 0; i < player.boostRewards.length; i++) {
                BoostReward memory boostReward = player.boostRewards[i];
                //  boostReward is started before disableReward
                if (boostReward.startTime < player.disableStartTime) {
                    // boost ends before disableReward
                    if (
                        boostReward.startTime + boostReward.remainTime <=
                        player.disableStartTime
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(boostReward.remainTime)
                                .div(boostDuration)
                        );
                        //  boost ends while disableReward
                    } else if (
                        boostReward.startTime + boostReward.remainTime <=
                        player.disableStartTime + player.disableRemainTime
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(
                                    boostReward.startTime +
                                        boostReward.remainTime -
                                        player.disableStartTime
                                )
                                .div(boostDuration)
                        );
                    }
                    //  boostReward is started while disableReward
                } else if (
                    boostReward.startTime >= player.disableStartTime &&
                    boostReward.startTime <
                    player.disableStartTime + player.disableRemainTime
                ) {
                    // boostReward ends while disableReward
                    if (
                        boostReward.startTime + boostReward.remainTime >
                        player.disableStartTime + player.disableRemainTime
                    ) {
                        // boostReward ended before claiming
                        if (
                            boostReward.startTime + boostReward.remainTime <=
                            block.timestamp
                        ) {
                            totalRewards = totalRewards.add(
                                boostReward
                                    .originReward
                                    .mul(
                                        boostReward.startTime +
                                            boostReward.remainTime -
                                            player.disableStartTime -
                                            player.disableRemainTime
                                    )
                                    .div(boostDuration)
                            );
                            // boostReward doesn't end before claiming
                        } else {
                            // disableReward ended before claiming
                            if (
                                player.disableStartTime +
                                    player.disableRemainTime <
                                block.timestamp
                            ) {
                                totalRewards = totalRewards.add(
                                    boostReward
                                        .originReward
                                        .mul(
                                            block.timestamp -
                                                player.disableStartTime -
                                                player.disableRemainTime
                                        )
                                        .div(boostDuration)
                                );
                                // disableReward not end before claiming
                            }
                        }
                    }
                    //  boostReward started after disableReward
                } else {
                    // boostReward ended before claiming
                    if (
                        boostReward.startTime + boostReward.remainTime <=
                        block.timestamp
                    ) {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(boostReward.remainTime)
                                .div(boostDuration)
                        );
                        // boostReward not ended before claiming
                    } else {
                        totalRewards = totalRewards.add(
                            boostReward
                                .originReward
                                .mul(block.timestamp - boostReward.startTime)
                                .div(boostDuration)
                        );
                    }
                }
            }
            ////    calculate daily rewards
            //  claim while disalbeRewards and disableReward started after lastReward
            for (uint256 i = 0; i < player.dailyRewards.length; i++) {
                uint256 startTime = player.dailyRewards[i].startTime;
                uint256 duration;
                uint256 dailyRewards = player.dailyRewards[i].rewards;
                if (i < player.dailyRewards.length - 1) {
                    duration = player.dailyRewards[i + 1].startTime.sub(
                        player.dailyRewards[i].startTime
                    );
                } else {
                    duration =
                        block.timestamp -
                        player.dailyRewards[i].startTime;
                }
                // rewards start and ends before disable or rewards start after disable
                if (
                    startTime + duration <= player.disableStartTime ||
                    startTime >=
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards.mul(duration).div(rewardDuration)
                    );
                    // rewards start before disable and ends while disable
                } else if (
                    startTime < player.disableStartTime &&
                    startTime + duration <=
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(player.disableStartTime - startTime)
                            .div(rewardDuration)
                    );
                    // rewards start before disable and ends after disable
                } else if (
                    startTime < player.disableStartTime &&
                    startTime + duration >
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(duration - player.disableRemainTime)
                            .div(rewardDuration)
                    );
                    // rewards start while disable and ends after disable
                } else if (
                    startTime >= player.disableStartTime &&
                    startTime + duration >
                    player.disableStartTime + player.disableRemainTime
                ) {
                    totalRewards = totalRewards.add(
                        dailyRewards
                            .mul(
                                startTime +
                                    duration -
                                    player.disableStartTime -
                                    player.disableRemainTime
                            )
                            .div(rewardDuration)
                    );
                }
            }
            // no disableReward
        } else {
            //calculate boost rewards
            for (uint256 i = 0; i < player.boostRewards.length; i++) {
                BoostReward memory boostReward = player.boostRewards[i];
                // claim after boostReward
                if (
                    boostReward.startTime + boostReward.remainTime <=
                    block.timestamp
                ) {
                    totalRewards = totalRewards.add(
                        boostReward
                            .originReward
                            .mul(boostReward.remainTime)
                            .div(boostDuration)
                    );
                    // claim while boostReward
                } else {
                    totalRewards = totalRewards.add(
                        boostReward
                            .originReward
                            .mul(block.timestamp - boostReward.startTime)
                            .div(boostDuration)
                    );
                }
            }
            //  calculate daily rewards
            for (uint256 i = 0; i < player.dailyRewards.length; i++) {
                uint256 duration;
                uint256 dailyRewards = player.dailyRewards[i].rewards;
                if (i < player.dailyRewards.length - 1) {
                    duration = player.dailyRewards[i + 1].startTime.sub(
                        player.dailyRewards[i].startTime
                    );
                } else {
                    duration =
                        block.timestamp -
                        player.dailyRewards[i].startTime;
                }
                totalRewards = totalRewards.add(
                    dailyRewards.mul(duration).div(rewardDuration)
                );
            }
        }
        return totalRewards;
    }

    //// get player info
    function getPlayerInfo(address addr)
        public
        view
        returns (
            uint256 lastRollTime,
            uint256 dice,
            uint256 curPos,
            uint256 lastRewardTime,
            uint256 rewardClaimed,
            uint256 startBonusCounts,
            uint256 bullishBonusCounts,
            uint256 disableStartTime,
            uint256 disableRemainTime,
            bool minted,
            uint256 farming,
            uint256[] memory boostRewards
        )
    {
        Player memory player = players[addr];
        lastRollTime = player.lastRollTime;
        dice = player.dice;
        curPos = player.curPos;
        lastRewardTime = player.lastRewardTime;
        rewardClaimed = player.rewardClaimed;
        startBonusCounts = player.startBonusCounts;
        bullishBonusCounts = player.bullishBonusCounts;
        disableStartTime = player.disableStartTime;
        disableRemainTime = player.disableRemainTime;
        minted = player.minted;
        farming = player.farming;
        uint256[] memory boosts = new uint256[](player.boostRewards.length * 3);
        for (uint256 i = 0; i < player.boostRewards.length; i++) {
            boosts[i * 3] = (uint256)(player.boostRewards[i].caseType);
            boosts[i * 3 + 1] = player.boostRewards[i].startTime;
            boosts[i * 3 + 2] = player.boostRewards[i].remainTime;
        }
        boostRewards = boosts;
    }

    function getPlayerPosMinted(address addr)
        public
        view
        returns (uint256, bool)
    {
        return (players[addr].curPos, players[addr].minted);
    }

    //////      Test
    function setRollFree(bool free) public onlyOwner {
        rollFree = free;
    }

    function removeDisableReward(address addr) public onlyOwner {
        players[addr].disableStartTime = 0;
        players[addr].disableRemainTime = 0;
    }

    function setRewardDuration(uint256 duration) public onlyOwner {
        rewardDuration = duration;
    }

    function setForceFarm(bool force) public onlyOwner {
        forceFarm = force;
    }
}