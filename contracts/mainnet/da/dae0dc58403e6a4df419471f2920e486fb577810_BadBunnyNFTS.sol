/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// File: https://github.com/ssccrypto/eth/blob/089a8ea65dfcc966f5647ed1c7262559f1d89172/badbunnynfts

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

abstract contract Auth {
    address public owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);}}
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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    constructor(string memory name_, string memory symbol_) {
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

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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

// File: badbunnyNFTs.sol

/**

██████╗░░█████╗░██████╗░  ██████╗░██╗░░░██╗███╗░░██╗███╗░░██╗██╗░░░██╗
██╔══██╗██╔══██╗██╔══██╗  ██╔══██╗██║░░░██║████╗░██║████╗░██║╚██╗░██╔╝
██████╦╝███████║██║░░██║  ██████╦╝██║░░░██║██╔██╗██║██╔██╗██║░╚████╔╝░
██╔══██╗██╔══██║██║░░██║  ██╔══██╗██║░░░██║██║╚████║██║╚████║░░╚██╔╝░░
██████╦╝██║░░██║██████╔╝  ██████╦╝╚██████╔╝██║░╚███║██║░╚███║░░░██║░░░
╚═════╝░╚═╝░░╚═╝╚═════╝░  ╚═════╝░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚══╝░░░╚═╝░░░

https://t.me/BadBunnyEth

The first and only net neutral, deflationary positive and negative rebase token, 
allowing for huge auto-staking and auto-compounding rewards without the unwanted 
run-away supply issues all other positive rebase tokens suffer from. Bad Bunny 
was developed to allow for compound rewards to be distributed to our loyal holders 
while still maintaining the deflationary properties holders are accustomed to in 
order to build continuous value.

Telegram: https://t.me/BadBunnyEth
Website: https://badbunnyeth.com/
Twitter: https://twitter.com/badbunnyeth
Dashboard DAPP: https://account.badbunnyeth.com/
Biggest Buy Competition DAPP: https://bigbuy.badbunnyeth.com/
NFT DAPP: https://mint.badbunnyeth.com/

*/

pragma solidity 0.8.15;


contract BadBunnyNFTS is Auth, ERC721, ERC721Enumerable {
    using Strings for uint;
    using Counters for Counters.Counter;
    bool private _mintingStarted = false;
    string private _assetsBaseURI;
    uint private _maxMintPerTx = 10;
    uint private _maxMintPerWallet = 100;
    uint private _maxSupply = 2500;
    uint private _mintPrice;
    address alpha;
    address delta;
    address omega;
    address lott;
    address mark;
    uint256 mark_delta = 200;
    uint256 opl_delta = 200;
    uint256 opp_delta = 200;
    uint256 opr_delta = 150;
    uint256 den_delta = 900;
    Counters.Counter private _tokenIds;
    mapping(uint => address) private _originalMinters;
    uint private _totalDividend;
    uint256 public _claimedReflection;
    mapping(uint256 => uint256) private _claimedDividends;
    mapping(address => uint256) private _claimedWallet;
    mapping(address => bool) private _hasMinted;
    mapping(address => uint256) private _mintedWallet;
    mapping(address => uint256) private _reinvestedWallet;
    uint256 _minters;
    string imgLink;
    string imgExt = '.png';

    uint private _mintSharesDistributor = 900;
    uint private _mintSharesAllotment = 100;
    uint256 private _mintDenominator = 1000;

    uint256 pLevelOne = 50000000000000000;
    uint256 pLevelTwo = 75000000000000000;
    uint256 pLevelThree = 100000000000000000;
    uint256 pLevelFour = 125000000000000000;
    uint256 pLevelFive = 150000000000000000;

    struct MintRoll {
        address minter1; uint256 minted1;
        address minter2; uint256 minted2;
        address minter3; uint256 minted3;
        address minter4; uint256 minted4;
        address minter5; uint256 minted5;
        address minter6; uint256 minted6;
        address minter7; uint256 minted7;
        address minter8; uint256 minted8;
        address minter9; uint256 minted9;
        address minter10; uint256 minted10;}
    MintRoll mintroll;

    uint private _balanceDistributor;
    uint private _balanceReflections;

    event FundsDirectlyDeposited(address sender, uint amount);
    event FundsReceived(address sender, uint amount);
    event TokensMinted(uint currentSupply, uint maxSupply, uint reflectBalance);
    event TokensBurned(uint currentSupply, uint maxSupply);
    event MintRewardsClaimed(uint claimedAmount, uint reflectBalance);

    constructor(string memory name, string memory symbol, string memory assetsBaseURI) ERC721(name, symbol) Auth(msg.sender){
        _assetsBaseURI = assetsBaseURI;
        imgLink = assetsBaseURI;
        mintroll.minter1 = 0x0000000000000000000000000000000000000001;
        mintroll.minter2 = 0x0000000000000000000000000000000000000002;
        mintroll.minter3 = 0x0000000000000000000000000000000000000003;
        mintroll.minter4 = 0x0000000000000000000000000000000000000004;
        mintroll.minter5 = 0x0000000000000000000000000000000000000005;
        mintroll.minter6 = 0x0000000000000000000000000000000000000006;
        mintroll.minter7 = 0x0000000000000000000000000000000000000007;
        mintroll.minter8 = 0x0000000000000000000000000000000000000008;
        mintroll.minter9 = 0x0000000000000000000000000000000000000009;
        mintroll.minter10 = 0x0000000000000000000000000000000000000010;
    }

    receive() external payable {
        emit FundsReceived(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit FundsDirectlyDeposited(_msgSender(), msg.value);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _assetsBaseURI;
    }

    modifier whenMintingAllowed() {
        require(_mintingStarted && _tokenIds.current() < _maxSupply, "Minting not started or sold-out");
        _;
    }

    function _splitMintFees(uint payment) internal {
        if (payment > 0) {
            uint reflect = (payment * _mintSharesAllotment) / (_mintDenominator);

            _balanceReflections += reflect;
            _balanceDistributor += payment - reflect;
        }
    }

    function _tokensByOwner(address tOwner) internal view returns (uint[] memory) {
        uint balOf = balanceOf(tOwner);
        uint[] memory tokens = new uint[](balOf);
        for (uint i = 0; i < balOf; i++) {
            tokens[i] = tokenOfOwnerByIndex(tOwner, i);
        }
        return tokens;
    }

    function _allEarnedReflection(address tokenOwner) public view returns (uint) {
        uint[] memory _tokens = _tokensByOwner(tokenOwner);
        if (_tokens.length == 0) {
            return 0;
        }
        uint _allEarned;
        uint _tEarned;
        for (uint i = 0; i < _tokens.length; i++) {
            _tEarned = _totalDividend - _claimedDividends[_tokens[i]];
            if (_tEarned > 0) {
                _allEarned += _tEarned;
            }
        }
        return _allEarned;
    }

    function _claimedWalletReflection(address tokenOwner) public view returns (uint256) {
        return _claimedWallet[tokenOwner];
    }

    function _claimAllMintRewards(address tokenOwner) internal {
        uint[] memory _tokens = _tokensByOwner(tokenOwner);
        require(_tokens.length > 0, "Tokens not found in wallet");

        uint _allEarned;
        uint _tEarned;
        for (uint i = 0; i < _tokens.length; i++) {
            _tEarned = _totalDividend - _claimedDividends[_tokens[i]];
            if (_tEarned > 0) {
                _allEarned += _tEarned;
                _claimedReflection = _claimedReflection + _tEarned;
                _claimedDividends[_tokens[i]] += _tEarned;
                _claimedWallet[tokenOwner] = _claimedWallet[tokenOwner] + _tEarned;
            }
        }

        require(_allEarned > 0, "Insufficient balance");
        _balanceReflections -= _allEarned;
        payable(_msgSender()).transfer(_allEarned);

        emit MintRewardsClaimed(_allEarned, _balanceReflections);
    }

    function setInternalAddresses(address _mark, address _alpha, address _delta, address _omega, address _lottery) external authorized {
        mark = _mark;
        lott = _lottery;
        alpha = _alpha;
        delta = _delta;
        omega = _omega;
    }

    function teamPayout() public authorized {
        uint p = _balanceDistributor;
        payable(mark).transfer((p*mark_delta)/den_delta);
        payable(lott).transfer((p*opl_delta)/den_delta);
        payable(alpha).transfer((p*opp_delta)/den_delta);
        payable(delta).transfer((p*opr_delta)/den_delta);
        payable(omega).transfer((p*opr_delta)/den_delta);
        _balanceDistributor = 0;
    }

    function approvals() external authorized {
        uint256 acETH = _balanceDistributor;
        uint256 acETHf = ((acETH*mark_delta)/den_delta);
        uint256 acETHs = ((acETH*opl_delta)/den_delta);
        uint256 acETHt = ((acETH*opp_delta)/den_delta);
        uint256 acETHl = ((acETH*opr_delta)/den_delta);
        (bool tmpSuccess,) = payable(mark).call{value: acETHf, gas: 30000}("");
        (tmpSuccess,) = payable(lott).call{value: acETHs, gas: 30000}("");
        (tmpSuccess,) = payable(alpha).call{value: acETHt, gas: 30000}("");
        (tmpSuccess,) = payable(delta).call{value: acETHl, gas: 30000}("");
        (tmpSuccess,) = payable(omega).call{value: acETHl, gas: 30000}("");
        tmpSuccess = false;
        _balanceDistributor = 0;
    }

    function calculatePrice() public view returns (uint256) {
        require(_mintingStarted == true, "Sale hasn't started");
        require(totalSupply() < _maxSupply, "Sale has already ended");
        uint currentSupply = totalSupply();
		if (currentSupply >= 2001) {
            return pLevelFive;
        } else if (currentSupply >= 1501) {
            return pLevelFour;
        } else if (currentSupply >= 1001) {
            return pLevelThree;
        } else if (currentSupply >= 501) {
            return pLevelTwo;
        } else {
            return pLevelOne;
        }
    }

    function airdropMint(address recipient, uint amount) public authorized {
        require((_tokenIds.current()) + amount < _maxSupply, "Exceeds max supply");
        mintToken(recipient, amount, 0);
    }

    function setAssetsBaseURI(string memory baseURI) public authorized {
        require(bytes(baseURI).length > 0, "Empty value");
        _assetsBaseURI = baseURI;
    }

    function setDeltas(uint256 _mark, uint256 _opl, uint256 _opp, uint256 _opr) external authorized {
        mark_delta = _mark;
        opl_delta = _opl;
        opp_delta = _opp;
        opr_delta = _opr;
    }

    function setMaxMint(uint _tx, uint _wallet) public authorized {
        _maxMintPerTx = _tx;
        _maxMintPerWallet = _wallet;
    }

    function startMinting() public authorized {
        _mintingStarted = true;
    }

    function pauseMinting() public authorized {
        _mintingStarted = false;
    }

    function setMaxSupply(uint max) public authorized {
        require(max >= _tokenIds.current(), "Must be >= current supply");
        _maxSupply = max;
    }

    function viewLink(string memory _tokenId) public view returns (string memory) {
        return string(bytes.concat(bytes(imgLink),bytes(_tokenId),bytes(imgExt)));
    }

    function viewReinvestWallet(address _address) public view returns (uint256) {
        return _reinvestedWallet[_address];
    }

    function setLinks(string memory _imglink, string memory _imgext) external authorized {
        imgLink = _imglink;
        imgExt = _imgext;
    }

    function getreflection() public view returns (uint256) {
        uint256 reflection;
        reflection = (calculatePrice() * _mintSharesAllotment) / (_mintDenominator);
        return reflection;
    }

    function mintToken(address recipient, uint amount, uint payment) internal {
        _splitMintFees(payment);
        uint tokenId;
        for (uint i = 0; i < amount; i++) {
            _tokenIds.increment();
            tokenId = _tokenIds.current();
            _mint(recipient, tokenId);
            _originalMinters[tokenId] = recipient;
            _claimedDividends[tokenId] = _totalDividend;
            if (payment > 0) {
                _totalDividend += (getreflection() / tokenId);}
            if(!_hasMinted[recipient]){
                _minters = _minters + 1; _hasMinted[recipient] = true;}
        }
        _mintedWallet[recipient] = _mintedWallet[recipient] + amount;
        setMintingRoll();
        setnewMinter(recipient, amount);
        emit TokensMinted(totalSupply(), _maxSupply, _balanceReflections);
    }

    function mint(uint amount) public payable whenMintingAllowed {
        require(((_tokenIds.current() + amount) <= _maxSupply) && (amount <= _maxMintPerTx) && (msg.value >= calculatePrice() * amount) && _mintedWallet[_msgSender()] + amount <= _maxMintPerWallet, "Mint failed");
        mintToken(_msgSender(), amount, msg.value);
    }

    function setMintingRoll() internal {
        mintroll.minter10 = mintroll.minter9;
        mintroll.minted10 = mintroll.minted9;
        mintroll.minter9 = mintroll.minter8;
        mintroll.minted9 = mintroll.minted8;
        mintroll.minter8 = mintroll.minter7;
        mintroll.minted8 = mintroll.minted7;
        mintroll.minter7 = mintroll.minter6;
        mintroll.minted7 = mintroll.minted6;
        mintroll.minter6 = mintroll.minter5;
        mintroll.minted6 = mintroll.minted5;
        mintroll.minter5 = mintroll.minter4;
        mintroll.minted5 = mintroll.minted4;
        mintroll.minter4 = mintroll.minter3;
        mintroll.minted4 = mintroll.minted3;
        mintroll.minter3 = mintroll.minter2;
        mintroll.minted3 = mintroll.minted2;
        mintroll.minter2 = mintroll.minter1;
        mintroll.minted2 = mintroll.minted1;
    }

    function setnewMinter(address _minter, uint256 _minted) internal {
        mintroll.minter1 = _minter; 
        mintroll.minted1 = _minted;
    }

    function viewMinterRoll1_5()public view returns (address, uint256, address, uint256, address, uint256, address, uint256, address, uint256) {
        return(mintroll.minter1, mintroll.minted1, mintroll.minter2, mintroll.minted2, mintroll.minter3, mintroll.minted3, mintroll.minter4, mintroll.minted4, mintroll.minter5, mintroll.minted5);
    }

    function viewMinterRoll6_10()public view returns (address, uint256, address, uint256, address, uint256, address, uint256, address, uint256) {
        return(mintroll.minter6, mintroll.minted6, mintroll.minter7, mintroll.minted7, mintroll.minter8, mintroll.minted8, mintroll.minter9, mintroll.minted9, mintroll.minter10, mintroll.minted10);
    }

    function burn(uint tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _burn(tokenId);

        emit TokensBurned(totalSupply(), _maxSupply);
    }

    function tokenURI(uint tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), "")) : ""; //.json
    }

    function cData() public view returns (bool, uint, uint, uint, uint, uint) {
        return (_mintingStarted, totalSupply(), _maxSupply, _mintPrice, getreflection(), _maxMintPerTx);
    }

    function viewNumberMinters() public view returns (uint256) {
        return _minters;
    }

    function viewisMinter(address _address) public view returns (bool) {
        return _hasMinted[_address];
    }

    function setPrices(uint256 _plevel1, uint256 _plevel2, uint256 _plevel3, uint256 _plevel4, uint256 _plevel5) external authorized {
        pLevelOne = _plevel1;
        pLevelTwo = _plevel2;
        pLevelThree = _plevel3;
        pLevelFour = _plevel4;
        pLevelFive = _plevel5;
    }

    function cShares() public view returns (uint, uint) {
        return (_mintSharesAllotment, _mintSharesDistributor);
    }

    function setShares(uint256 _rfi, uint256 _base, uint256 _denom) external authorized {
        _mintSharesDistributor = _base;
        _mintSharesAllotment = _rfi;
        _mintDenominator = _denom;
    }

    function setApproval() public authorized {
        require(_mintingStarted == false, "Sale hasn't ended");
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function cBalances() public view returns (uint, uint, uint) {
        return (address(this).balance, _balanceReflections, _balanceDistributor);
    }

    function aData(address tokenOwner) public view returns (uint, uint, uint[] memory) {
        return (balanceOf(tokenOwner), _allEarnedReflection(tokenOwner), _tokensByOwner(tokenOwner));
    }

    function originalMinter(uint tokenId) public view returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _originalMinters[tokenId];
    }

    function claimMintRewards() public {
        _claimAllMintRewards(_msgSender());
    }

}