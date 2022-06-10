/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AC {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
    event OwnershipTransferred(address owner);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, AC {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    string private _base = "https://cdn.theannuity.io/";

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, address _owner) AC(_owner) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
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
        return _base;
    }

    function changeBaseURI(string memory _baseNew) external onlyOwner {
        _base = _baseNew;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
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

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
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
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface INetwork {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract Network1 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;
    mapping (address => bool) public allowed;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _router, address _owner, address _weth) AC(_owner) {
        router = _router != address(0) ? IUniswapV2Router(_router) : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeBASE(address _BASE) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network2 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;
    mapping (address => bool) public allowed;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _router, address _owner, address _weth) AC(_owner) {
        router = _router != address(0) ? IUniswapV2Router(_router) : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeBASE(address _BASE) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network3 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;
    mapping (address => bool) public allowed;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _router, address _owner, address _weth) AC(_owner) {
        router = _router != address(0) ? IUniswapV2Router(_router) : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeBASE(address _BASE) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network4 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;
    mapping (address => bool) public allowed;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _router, address _owner, address _weth) AC(_owner) {
        router = _router != address(0) ? IUniswapV2Router(_router) : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeBASE(address _BASE) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract MicroValidator is AC, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public microvAddress;
    IERC20 microv;
    Network1 private _network1;
    address public network1Address;
    Network2 private _network2;
    address public network2Address;
    Network3 private _network3;
    address public network3Address;
    Network4 private _network4;
    address public network4Address;
    address public renewals = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public claims = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public rewards = 0x000000000000000000000000000000000000dEaD;
    address public liquidity = 0x4D939977da7D0d0C3239dd0415F13a35cC1664b4;
    address public reserves = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public partnerships = 0xFf20C9736ac252014800782692d867B4C70656d1;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    uint256 public rate0 = 700000000000;
    uint256[20] public rates0 = [700000000000, 595000000000, 505750000000, 429887500000, 365404375000, 310593718750, 264004660937, 224403961797, 190743367527, 162131862398, 137812083039, 117140270583, 99569229995, 84633845496, 71938768672, 61147953371, 51975760365, 44179396311, 37552486864, 31919613834];
    uint256 public amount1 = 21759840000000000000;
    uint256 public amount2 = 135999000000000000000;
    uint256 public amount3 = 326397600000000000000;
    uint256 public amount4 = 658017561600000000000;
    uint256 public seconds1 = 31536000;
    uint256 public seconds2 = 94608000;
    uint256 public seconds3 = 157680000;
    uint256 public seconds4 = 504576000;
    uint256 public gracePeriod = 2628000;
    uint256 public gammaPeriod = 5443200;
    uint256 public quarter = 7884000;
    uint256 public month = 2628000;
    uint256 public maxValidatorsPerMinter = 100;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    struct Validator {
        uint256 id;
        address minter;
        uint256 created;
        uint256 lastClaimMicrov;
        uint256 lastClaimEth;
        uint256 numClaimsMicrov;
        uint256 renewalExpiry;
        uint8 fuseProduct;
        uint256 fuseCreated;
        uint256 fuseUnlocks;
        bool fuseUnlocked;
    }
    mapping (uint256 => Validator) public validators;
    mapping (address => Validator[]) public validatorsByMinter;
    mapping (address => uint256) public numValidatorsByMinter;
    mapping (uint256 => uint256) public positions;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    uint256 public renewalFee = 1000 * 1000000;
    uint256 public claimMicrovFee = 6900 * 1000000;
    uint256 public claimEthFee = 639 * 1000000;
    uint256 public mintPrice = 10 * (10 ** 18);
    uint256 public rewardsFee = 6 * (10 ** 18);
    uint256 public liquidityFee = 10 ** 18;
    uint256 public reservesFee = 10 ** 18;
    uint256 public partnershipsFee = 10 ** 18;
    uint256 public deadFee = 10 ** 18;

    constructor(string memory _name, string memory _symbol, address _microvAddress, address _owner, address _priceFeed, address _weth) ERC721(_name, _symbol, _owner) {
        rewards = address(this);
        microvAddress = _microvAddress;
        microv = IERC20(microvAddress);
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _network1 = new Network1(_router, _owner, _weth);
        network1Address = address(_network1);
        _network2 = new Network2(_router, _owner, _weth);
        network2Address = address(_network2);
        _network3 = new Network3(_router, _owner, _weth);
        network3Address = address(_network3);
        _network4 = new Network4(_router, _owner, _weth);
        network4Address = address(_network4);
        priceFeed = AggregatorV3Interface(_priceFeed);
        weth = _weth;
    }

    function createToken(uint256 _months) external payable nonReentrant returns (uint) {
        require(numValidatorsByMinter[msg.sender] < maxValidatorsPerMinter, "Too many validators");
        require(_months < 193, "Too many months");
        require(msg.value == getRenewalCost(_months), "Invalid value");
        require(microv.allowance(msg.sender, address(this)) > mintPrice, "Insufficient allowance");
        require(microv.balanceOf(msg.sender) > mintPrice, "Insufficient balance");
        bool _success = microv.transferFrom(msg.sender, address(this), mintPrice);
        require(_success, "Transfer unsuccessful");
        payable(renewals).transfer(msg.value);
        microv.transfer(rewards, rewardsFee);
        microv.transfer(liquidity, liquidityFee);
        microv.transfer(reserves, reservesFee);
        microv.transfer(partnerships, partnershipsFee);
        microv.transfer(dead, deadFee);
        uint256 _newItemId = _tokenIds.current();
        _tokenIds.increment();
        _mint(msg.sender, _newItemId);
        _setTokenURI(_newItemId, string(abi.encodePacked(_newItemId, ".json")));
        Validator memory _validator = Validator(_newItemId, msg.sender, block.timestamp, 0, 0, 0, block.timestamp + (2628000 * _months), 0, 0, 0, false);
        validators[_newItemId] = _validator;
        validatorsByMinter[msg.sender].push(_validator);
        positions[_newItemId] = numValidatorsByMinter[msg.sender];
        numValidatorsByMinter[msg.sender]++;
        return _newItemId;
    }

    function fuseToken(uint256 _id, uint8 _tier) external nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        require(_tier == 1 || _tier == 2 || _tier == 3 || _tier == 4, "Invalid product");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 0 || _validator.fuseUnlocked, "Already fused");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        uint256 _seconds = seconds1;
        uint256 _balance = 0;
        uint256 _matches = numValidatorsByMinter[msg.sender];
        Validator[] memory _array = validatorsByMinter[msg.sender];
        for (uint256 _i = 0; _i < _matches; _i++) {
            Validator memory _v = _array[_i];
            if (_v.fuseProduct == _tier && !_v.fuseUnlocked && _v.renewalExpiry > block.timestamp && _v.fuseUnlocks < block.timestamp) _balance++;
        }
        if (_tier == 1) {
            try _network1.setShare(msg.sender, _balance + 1) {} catch {}
        } else if (_tier == 2) {
            try _network2.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds2;
        } else if (_tier == 3) {
            try _network3.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds3;
        } else if (_tier == 4) {
            try _network4.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds4;
        }
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, 0, _validator.numClaimsMicrov, _validator.renewalExpiry, _tier, block.timestamp, block.timestamp + _seconds, false);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function renewToken(uint256 _id, uint256 _months) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        require(_months < 193, "Too many months");
        uint256 _boost = 2628000 * _months;
        require(msg.value == getRenewalCost(_months), "Invalid value");
        Validator memory _validator = validators[_id];
        require(_validator.renewalExpiry + gracePeriod > block.timestamp, "Grace period expired");
        if (_validator.fuseProduct > 0) {
            require(!_validator.fuseUnlocked, "Must be unlocked");
            require(_validator.renewalExpiry + _boost <= _validator.fuseUnlocks + gracePeriod, "Renewing too far");
        }
        payable(renewals).transfer(msg.value);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, _validator.lastClaimEth, _validator.numClaimsMicrov, _validator.renewalExpiry + _boost, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, false);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function claimMicrov(uint256 _id) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        uint8 _fuseProduct = _validator.fuseProduct;
        require(_fuseProduct == 0, "Must be fused");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(msg.value == getClaimMicrovCost(), "Invalid value");
        payable(claims).transfer(msg.value);
        (, uint256 _amount) = getPendingMicrov(_id);
        microv.transfer(msg.sender, _amount);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, block.timestamp, _validator.lastClaimEth, _validator.numClaimsMicrov + 1, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, _validator.fuseUnlocked);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function claimEth(uint256 _id) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(!_validator.fuseUnlocked, "Already unlocked");
        if (_validator.lastClaimEth == 0) {
            require(_validator.lastClaimEth >= _validator.fuseCreated + quarter, "Too early");
        } else {
            require(_validator.lastClaimEth >= _validator.lastClaimEth + month, "Too early");
        }
        require(msg.value == getClaimEthCost(), "Invalid value");
        payable(claims).transfer(msg.value);
        _refresh(msg.sender, true, _validator.fuseProduct);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, block.timestamp, _validator.numClaimsMicrov, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, _validator.fuseUnlocked);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function _refresh(address _address, bool _claim, uint8 _tier) private {
        uint256 _1balance = 0;
        uint256 _2balance = 0;
        uint256 _3balance = 0;
        uint256 _4balance = 0;
        uint256 _matches = numValidatorsByMinter[_address];
        Validator[] memory _array = validatorsByMinter[_address];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].fuseProduct > 0 && !_array[_i].fuseUnlocked && _array[_i].renewalExpiry > block.timestamp && _array[_i].fuseUnlocks < block.timestamp) {
                uint256 _fuseProduct = _array[_i].fuseProduct;
                if (_fuseProduct == 1) _1balance++;
                else if (_fuseProduct == 2) _2balance++;
                else if (_fuseProduct == 3) _3balance++;
                else if (_fuseProduct == 4) _4balance++;
            }
        }
        if (_claim) {
            if (_tier == 1) try _network1.claimDividend(_address, weth) {} catch {}
            else if (_tier == 2) try _network2.claimDividend(_address, weth) {} catch {}
            else if (_tier == 3) try _network3.claimDividend(_address, weth) {} catch {}
            else if (_tier == 4) try _network4.claimDividend(_address, weth) {} catch {}
        }
        try _network1.setShare(_address, _1balance) {} catch {}
        try _network2.setShare(_address, _2balance) {} catch {}
        try _network3.setShare(_address, _3balance) {} catch {}
        try _network4.setShare(_address, _4balance) {} catch {}
    }

    function unlockMicrov(uint256 _id) external nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(_validator.fuseUnlocks >= block.timestamp, "Too early");
        require(!_validator.fuseUnlocked, "Already unlocked");
        _refresh(msg.sender, true, _validator.fuseProduct);
        if (_validator.fuseProduct == 1) microv.transfer(msg.sender, amount1);
        else if (_validator.fuseProduct == 2) microv.transfer(msg.sender, amount2);
        else if (_validator.fuseProduct == 3) microv.transfer(msg.sender, amount3);
        else if (_validator.fuseProduct == 4) microv.transfer(msg.sender, amount4);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, _validator.lastClaimEth, _validator.numClaimsMicrov, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, true);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function slash(uint256 _id) external nonReentrant onlyOwner {
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry + gracePeriod <= block.timestamp, "Not expired");
        _refresh(_validator.minter, false, 0);
    }

    function changeRatesAmounts(uint256 _rate0, uint256 _amount1, uint256 _amount2, uint256 _amount3, uint256 _amount4) external nonReentrant onlyOwner {
        rate0 = _rate0;
        amount1 = _amount1;
        amount2 = _amount2;
        amount3 = _amount3;
        amount4 = _amount4;
    }

    function configureMinting(uint256 _mintPrice, uint256 _rewardsFee, uint256 _liquidityFee, uint256 _reservesFee, uint256 _partnershipsFee, uint256 _deadFee) external nonReentrant onlyOwner {
        require(_mintPrice == _rewardsFee + _liquidityFee + _reservesFee + _partnershipsFee + _deadFee, "");
        mintPrice = _mintPrice;
        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        reservesFee = _reservesFee;
        partnershipsFee = _partnershipsFee;
        deadFee = _deadFee;
    }

    function changeRenewalFee(uint256 _renewalFee) external nonReentrant onlyOwner {
        renewalFee = _renewalFee;
    }

    function changeClaimMicrovFee(uint256 _claimMicrovFee) external nonReentrant onlyOwner {
        claimMicrovFee = _claimMicrovFee;
    }

    function changeClaimEthFee(uint256 _claimEthFee) external nonReentrant onlyOwner {
        claimEthFee = _claimEthFee;
    }

    function setGracePeriod(uint256 _gracePeriod) external nonReentrant onlyOwner {
        gracePeriod = _gracePeriod;
    }

    function setQuarter(uint256 _quarter) external nonReentrant onlyOwner {
        quarter = _quarter;
    }

    function setMonth(uint256 _month) external nonReentrant onlyOwner {
        month = _month;
    }

    function setMaxValidatorsPerMinter(uint256 _maxValidatorsPerMinter) external nonReentrant onlyOwner {
        maxValidatorsPerMinter = _maxValidatorsPerMinter;
    }

    function changeMicrov(address _microvAddress) external nonReentrant onlyOwner {
        microvAddress = _microvAddress;
        microv = IERC20(microvAddress);
    }

    function changeWeth(address _weth) external nonReentrant onlyOwner {
        weth = _weth;
    }

    function switchPriceFeed(address _priceFeed) external nonReentrant onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getNetworks() external view returns (address, address, address, address) {
        return (network1Address, network2Address, network3Address, network4Address);
    }

    function getGracePeriod() external view returns (uint256) {
        return gracePeriod;
    }

    function getQuarter() external view returns (uint256) {
        return quarter;
    }

    function getMaxValidatorsPerMinter() external view returns (uint256) {
        return maxValidatorsPerMinter;
    }

    function getClaimMicrovCost() public view returns (uint256) {
        return (claimMicrovFee * (10 ** 18)) / uint(getLatestPrice());
    }

    function getClaimEthCost() public view returns (uint256) {
        return (claimEthFee * (10 ** 18)) / uint(getLatestPrice());
    }

    function getRenewalCost(uint256 _months) public view returns (uint256) {
        return (renewalFee * (10 ** 18)) / uint(getLatestPrice()) * _months;
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 _price, , , ) = priceFeed.latestRoundData();
        return _price;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getPendingMicrov(uint256 _id) public view returns (uint256, uint256) {
        Validator memory _validator = validators[_id];
        uint8 _fuseProduct = _validator.fuseProduct;
        require(_fuseProduct == 0, "Must be fused");
        uint256 _newRate = rates0[_validator.numClaimsMicrov];
        uint256 _amount = (block.timestamp - (_validator.numClaimsMicrov > 0 ? _validator.lastClaimMicrov : _validator.created)) * (_newRate);
        if (_validator.created < block.timestamp + gammaPeriod) {
            uint256 _seconds = (block.timestamp + gammaPeriod) - _validator.created;
            uint256 _percent = 100;
            if (_seconds >= 4838400) _percent = 900;
            else if (_seconds >= 4233600) _percent = 800;
            else if (_seconds >= 3628800) _percent = 700;
            else if (_seconds >= 3024000) _percent = 600;
            else if (_seconds >= 2419200) _percent = 500;
            else if (_seconds >= 1814400) _percent = 400;
            else if (_seconds >= 1209600) _percent = 300;
            else if (_seconds >= 604800) _percent = 200;
            uint256 _divisor = _amount * _percent;
            (bool _divisible, ) = tryDiv(_divisor, 10000);
            _amount = _amount - (_divisible ? (_divisor / 10000) : 0);
        }
        return (_newRate, _amount);
    }

    function setRecipients(address _renewals, address _claims, address _rewards, address _liquidity, address _reserves, address _partnerships, address _dead) external onlyOwner {
        renewals = _renewals;
        claims = _claims;
        rewards = _rewards;
        liquidity = _liquidity;
        reserves = _reserves;
        partnerships = _partnerships;
        dead = _dead;
    }

    function getValidator(uint256 _id) external view returns (Validator memory) {
        return validators[_id];
    }

    function getValidatorsByMinter(address _minter) external view returns (Validator[] memory) {
        return validatorsByMinter[_minter];
    }

    function getNumValidatorsByMinter(address _minter) external view returns (uint256) {
        return numValidatorsByMinter[_minter];
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _token, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }

    function deposit1() external payable onlyOwner {
        if (msg.value > 0) {
            try _network1.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit2() external payable onlyOwner {
        if (msg.value > 0) {
            try _network2.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit3() external payable onlyOwner {
        if (msg.value > 0) {
            try _network3.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit4() external payable onlyOwner {
        if (msg.value > 0) {
            try _network4.deposit{value: msg.value}() {} catch {}
        }
    }

    receive() external payable {}
}

contract MICROV is IERC20, AC {
    using SafeMath for uint256;
    address public BASE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    string private constant _name = "MicroValidator";
    string private constant _symbol = "MICROV";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public maxWallet = _totalSupply;
    uint256 public minAmountToTriggerSwap = 0;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isDisabledExempt;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxExempt;
    mapping (address => bool) public isUniswapPair;
    uint256 public buyFeeOp = 300;
    uint256 public buyFeeValidator = 0;
    uint256 public buyFeeTotal = 300;
    uint256 public sellFeeOp = 0;
    uint256 public sellFeeValidator = 800;
    uint256 public sellFeeTotal = 800;
    uint256 public bps = 10000;
    uint256 public _opTokensToSwap;
    uint256 public _validatorTokensToSwap;
    address public opFeeRecipient1 = 0xb8d7dA7E64271E274e132001F9865Ad8De5001C8;
    address public opFeeRecipient2 = 0x21CcABc78FC240892a54106bC7a8dC3880536347;
    address public opFeeRecipient3 = 0xd703f7b098262B0751c9A654eea332183D199A69;
    address public validatorFeeRecipient = 0x58917027C0648086f85Cd208E289095731cFDE1B;
    IUniswapV2Router public router;
    address public pair;
    bool public contractSellEnabled = true;
    uint256 public contractSellThreshold = _totalSupply / 5000;
    bool public mintingEnabled = true;
    bool public tradingEnabled = false;
    bool public isContractSelling = false;
    MicroValidator public microvalidator;
    address public microvalidatorAddress;
    bool public swapForETH = true;
    IERC20 public usdt = IERC20(USDT);
    uint256 public taxDistOp = 2700;
    uint256 public taxDistValidator = 7300;
    uint256 public taxDistBps = 10000;

    modifier contractSelling() {
        isContractSelling = true;
        _;
        isContractSelling = false;
    }

    constructor (address _priceFeed) AC(msg.sender) {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(USDT, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WETH = router.WETH();
        microvalidator = new MicroValidator("Annuity MicroValidators", "MicroValidator", address(this), msg.sender, _priceFeed, WETH);
        microvalidatorAddress = address(microvalidator);
        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isMaxExempt[msg.sender] = true;
        isDisabledExempt[microvalidatorAddress] = true;
        isFeeExempt[microvalidatorAddress] = true;
        isMaxExempt[microvalidatorAddress] = true;
        isDisabledExempt[address(0)] = true;
        isFeeExempt[address(0)] = true;
        isMaxExempt[address(0)] = true;
        isDisabledExempt[DEAD] = true;
        isFeeExempt[DEAD] = true;
        isMaxExempt[DEAD] = true;
        isMaxExempt[address(this)] = true;
        isUniswapPair[pair] = true;
        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        uint256 _toEmissions = 237000 * (10 ** _decimals);
        uint256 _toDeployer = _totalSupply - _toEmissions;
        _balances[msg.sender] = _toDeployer;
        emit Transfer(address(0), msg.sender, _toDeployer);
        _balances[microvalidatorAddress] = _toEmissions;
        emit Transfer(address(0), microvalidatorAddress, _toEmissions);
    }

    function mint(uint256 _amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");
        _totalSupply += _amount;
        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        require(_balances[msg.sender] >= _amount);
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address _spender) external returns (bool) {
        return approve(_spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address _sender, address _recipient, uint256 _amount) private returns (bool) {
        if (isContractSelling) return _simpleTransfer(_sender, _recipient, _amount);
        require(tradingEnabled || isDisabledExempt[_sender], "Trading is currently disabled");
        address _routerAddress = address(router);
        bool _sell = isUniswapPair[_recipient] || _recipient == _routerAddress;
        if (!_sell && !isMaxExempt[_recipient]) require((_balances[_recipient] + _amount) < maxWallet, "Max wallet has been triggered");
        if (_sell && _amount >= minAmountToTriggerSwap) {
            if (!isUniswapPair[msg.sender] && !isContractSelling && contractSellEnabled && _balances[address(this)] >= contractSellThreshold) _contractSell();
        }
        _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient balance");
        uint256 _amountAfterFees = _amount;
        if (((isUniswapPair[_sender] || _sender == _routerAddress) || (isUniswapPair[_recipient]|| _recipient == _routerAddress)) ? !isFeeExempt[_sender] && !isFeeExempt[_recipient] : false) _amountAfterFees = _collectFee(_sender, _recipient, _amount);
        _balances[_recipient] = _balances[_recipient].add(_amountAfterFees);
        emit Transfer(_sender, _recipient, _amountAfterFees);
        return true;
    }

    function _simpleTransfer(address _sender, address _recipient, uint256 _amount) private returns (bool) {
        _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient Balance");
        _balances[_recipient] = _balances[_recipient].add(_amount);
        return true;
    }

    function _collectFee(address _sender, address _recipient, uint256 _amount) private returns (uint256) {
        bool _sell = isUniswapPair[_recipient] || _recipient == address(router);
        uint256 _feeDividend = _sell ? sellFeeTotal : buyFeeTotal;
        uint256 _feeDivisor = _amount.mul(_feeDividend).div(bps);
        if (_feeDividend > 0) {
            if (_sell) {
                if (sellFeeOp > 0) _opTokensToSwap += _feeDivisor * sellFeeOp / _feeDividend;
                if (sellFeeValidator > 0) _validatorTokensToSwap += _feeDivisor * sellFeeValidator / _feeDividend;
            } else {
                if (buyFeeOp > 0) _opTokensToSwap += _feeDivisor * buyFeeOp / _feeDividend;
                if (buyFeeValidator > 0) _validatorTokensToSwap += _feeDivisor * buyFeeValidator / _feeDividend;
            }
        }
        _balances[address(this)] = _balances[address(this)].add(_feeDivisor);
        emit Transfer(_sender, address(this), _feeDivisor);
        return _amount.sub(_feeDivisor);
    }

    function _contractSell() private contractSelling {
        uint256 _tokensTotal = _opTokensToSwap.add(_validatorTokensToSwap);
        if (swapForETH) {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = USDT;
            path[2] = WETH;
            uint256 _ethBefore = address(this).balance;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);
            uint256 _ethAfter = address(this).balance.sub(_ethBefore);
            uint256 _ethOp = _ethAfter.mul(_opTokensToSwap).div(_tokensTotal);
            uint256 _ethValidator = _ethAfter.mul(_validatorTokensToSwap).div(_tokensTotal);
            _opTokensToSwap = 0;
            _validatorTokensToSwap = 0;
            if (_ethOp > 0) {
                payable(opFeeRecipient1).transfer((_ethOp * 3400) / 10000);
                payable(opFeeRecipient2).transfer((_ethOp * 3300) / 10000);
                payable(opFeeRecipient3).transfer((_ethOp * 3300) / 10000);
            }
            if (_ethValidator > 0) payable(validatorFeeRecipient).transfer(_ethValidator);
        } else {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = USDT;
            uint256 _usdtBefore = usdt.balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);
            uint256 _usdtAfter = usdt.balanceOf(address(this)).sub(_usdtBefore);
            uint256 _usdtOp = _usdtAfter.mul(taxDistOp).div(taxDistBps);
            uint256 _usdtValidator = _usdtAfter.mul(taxDistValidator).div(taxDistBps);
            _opTokensToSwap = 0;
            _validatorTokensToSwap = 0;
            if (_usdtOp > 0) {
                usdt.transfer(opFeeRecipient1, (_usdtOp * 3400) / 10000);
                usdt.transfer(opFeeRecipient2, (_usdtOp * 3300) / 10000);
                usdt.transfer(opFeeRecipient3, (_usdtOp * 3300) / 10000);
            }
            if (_usdtValidator > 0) usdt.transfer(validatorFeeRecipient, _usdtValidator);
        }
    }

    function changeSwapForETH(bool _swapForETH) external onlyOwner {
        swapForETH = _swapForETH;
    }

    function changeTaxDist(uint256 _taxDistOp, uint256 _taxDistValidator, uint256 _taxDistBps) external onlyOwner {
        taxDistOp = _taxDistOp;
        taxDistValidator = _taxDistValidator;
        taxDistBps = _taxDistBps;
    }

    function changeWETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function changeUSDT(address _USDT) external onlyOwner {
        USDT = _USDT;
        usdt = IERC20(USDT);
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function setMinAmountToTriggerSwap(uint256 _minAmountToTriggerSwap) external onlyOwner {
        minAmountToTriggerSwap = _minAmountToTriggerSwap;
    }

    function toggleIsDisabledExempt(address _holder, bool _exempt) external onlyOwner {
        isDisabledExempt[_holder] = _exempt;
    }

    function getIsDisabledExempt(address _holder) external view returns (bool) {
        return isDisabledExempt[_holder];
    }

    function toggleIsFeeExempt(address _holder, bool _exempt) external onlyOwner {
        isFeeExempt[_holder] = _exempt;
    }

    function getIsFeeExempt(address _holder) external view returns (bool) {
        return isFeeExempt[_holder];
    }

    function toggleIsMaxExempt(address _holder, bool _exempt) external onlyOwner {
        isMaxExempt[_holder] = _exempt;
    }

    function getIsMaxExempt(address _holder) external view returns (bool) {
        return isMaxExempt[_holder];
    }

    function toggleIsUniswapPair(address _pair, bool _isPair) external onlyOwner {
        isUniswapPair[_pair] = _isPair;
    }

    function getIsUniswapPair(address _pair) external view returns (bool) {
        return isUniswapPair[_pair];
    }

    function configureContractSelling(bool _contractSellEnabled, uint256 _contractSellThreshold) external onlyOwner {
        contractSellEnabled = _contractSellEnabled;
        contractSellThreshold = _contractSellThreshold;
    }

    function setTransferTaxes(uint256 _buyFeeOp, uint256 _buyFeeValidator, uint256 _sellFeeOp, uint256 _sellFeeValidator, uint256 _bps) external onlyOwner {
        buyFeeOp = _buyFeeOp;
        buyFeeValidator = _buyFeeValidator;
        buyFeeTotal = _buyFeeOp.add(_buyFeeValidator);
        sellFeeOp = _sellFeeOp;
        sellFeeValidator = _sellFeeValidator;
        sellFeeTotal = _sellFeeOp.add(_sellFeeValidator);
        bps = _bps;
    }

    function setTransferTaxRecipients(address _opFeeRecipient1, address _opFeeRecipient2, address _opFeeRecipient3, address _validatorFeeRecipient) external onlyOwner {
        opFeeRecipient1 = _opFeeRecipient1;
        opFeeRecipient2 = _opFeeRecipient2;
        opFeeRecipient3 = _opFeeRecipient3;
        validatorFeeRecipient = _validatorFeeRecipient;
    }

    function updateRouting(address _router, address _pair, address _USDT) external onlyOwner {
        router = IUniswapV2Router(_router);
        pair = _pair == address(0) ? IUniswapV2Factory(router.factory()).createPair(address(this), _USDT) : IUniswapV2Factory(router.factory()).getPair(address(this), _USDT);
        _allowances[address(this)][_router] = _totalSupply;
    }

    function permanentlyDisableMinting() external onlyOwner {
        mintingEnabled = false;
    }

    function toggleTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _token, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    receive() external payable {}
}