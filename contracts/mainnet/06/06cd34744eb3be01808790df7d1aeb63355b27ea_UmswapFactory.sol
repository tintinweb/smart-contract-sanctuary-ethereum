/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Umswap v0.8.8 testing
//
// https://github.com/bokkypoobah/Umswap
//
// Deployments:
// - UmswapFactory 0x06cD34744eb3bE01808790Df7D1AeB63355b27Ea
// - Template Umswap 0x057bDb7B37F35fd212547507eEf000A01c6acbff
//
// SPDX-License-Identifier: MIT
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022
// ----------------------------------------------------------------------------

/// @notice https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}
// End CloneFactory.sol


/// @author Alex W.(github.com/nonstopcoderaxw)
/// @title Array utility functions optimized for Nix
library ArrayUtils {
    /// @notice divide-and-conquer check if an targeted item exists in a sorted array
    /// @param self the given sorted array
    /// @param target the targeted item to the array
    /// @return true - if exists, false - not found
    function includes16(uint16[] memory self, uint target) internal pure returns (bool) {
        if (self.length > 0) {
            uint left;
            uint right = self.length - 1;
            uint mid;
            while (left <= right) {
                mid = (left + right) / 2;
                if (uint(self[mid]) < target) {
                    left = mid + 1;
                } else if (uint(self[mid]) > target) {
                    if (mid < 1) {
                        break;
                    }
                    right = mid - 1;
                } else {
                    return true;
                }
            }
        }
        return false;
    }
    function includes32(uint32[] memory self, uint target) internal pure returns (bool) {
        if (self.length > 0) {
            uint left;
            uint right = self.length - 1;
            uint mid;
            while (left <= right) {
                mid = (left + right) / 2;
                if (uint(self[mid]) < target) {
                    left = mid + 1;
                } else if (uint(self[mid]) > target) {
                    if (mid < 1) {
                        break;
                    }
                    right = mid - 1;
                } else {
                    return true;
                }
            }
        }
        return false;
    }
    function includes64(uint64[] memory self, uint target) internal pure returns (bool) {
        if (self.length > 0) {
            uint left;
            uint right = self.length - 1;
            uint mid;
            while (left <= right) {
                mid = (left + right) / 2;
                if (uint(self[mid]) < target) {
                    left = mid + 1;
                } else if (uint(self[mid]) > target) {
                    if (mid < 1) {
                        break;
                    }
                    right = mid - 1;
                } else {
                    return true;
                }
            }
        }
        return false;
    }
    function includes256(uint[] memory self, uint target) internal pure returns (bool) {
        if (self.length > 0) {
            uint left;
            uint right = self.length - 1;
            uint mid;
            while (left <= right) {
                mid = (left + right) / 2;
                if (self[mid] < target) {
                    left = mid + 1;
                } else if (self[mid] > target) {
                    if (mid < 1) {
                        break;
                    }
                    right = mid - 1;
                } else {
                    return true;
                }
            }
        }
        return false;
    }
}


/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Partial is IERC165 {
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external payable;
    function safeTransferFrom(address from, address to, uint tokenId) external payable;
}


function onePlus(uint x) pure returns (uint) {
    unchecked { return 1 + x; }
}


contract ReentrancyGuard {
    uint private _executing;

    error ReentrancyAttempted();

    modifier reentrancyGuard() {
        if (_executing == 1) {
            revert ReentrancyAttempted();
        }
        _executing = 1;
        _;
        _executing = 2;
    }
}


contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed from, address indexed to);

    error AlreadyInitialised();
    error NotOwner();

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function initOwned(address _owner) internal {
        if (initialised) {
            revert AlreadyInitialised();
        }
        owner = address(uint160(_owner));
        initialised = true;
    }

    /// @dev Only owner can transfer ownership to new address
    /// @param newOwner New owner address
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/// @notice Basic token = ERC20 + symbol + name + decimals + mint + ownership
contract BasicToken is IERC20, Owned {

    string _symbol;
    string _name;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function initBasicToken(address factory, string memory __symbol, string memory __name, uint8 __decimals) internal {
        super.initOwned(factory);
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
    }
    function symbol() override external view returns (string memory) {
        return _symbol;
    }
    function name() override external view returns (string memory) {
        return _name;
    }
    function decimals() override external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() override external view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function _mint(address tokenOwner, uint tokens) internal returns (bool success) {
        balances[tokenOwner] += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function _burn(address tokenOwner, uint tokens) internal returns (bool success) {
        balances[tokenOwner] -= tokens;
        _totalSupply -= tokens;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
}


contract TipHandler {
    uint constant INTEGRATORPERCENTAGE = 80;

    event ThankYou(address indexed account, uint indexed timestamp, address indexed integrator, uint integratorTip, uint remainingTip);

    function handleTips(address integrator, address remainder) internal {
        if (msg.value > 0) {
            uint integratorTip;
            if (integrator != address(0) && integrator != remainder) {
                integratorTip = msg.value * INTEGRATORPERCENTAGE / 100;
                if (integratorTip > 0) {
                    payable(integrator).transfer(integratorTip);
                }
            }
            uint remainingTip = msg.value - integratorTip;
            if (remainingTip > 0 && remainder != address(this)) {
                payable(remainder).transfer(remainingTip);
            }
            emit ThankYou(msg.sender, block.timestamp, integrator, integratorTip, remainingTip);
        }
    }
}


/// @title ERC-721 pool
/// @author BokkyPooBah, Bok Consulting Pty Ltd
contract Umswap is BasicToken, TipHandler, ReentrancyGuard {

    enum Stats { SwappedIn, SwappedOut, TotalScores }

    struct Rating {
        address account;
        uint64 score;
    }

    uint8 constant DECIMALS = 18;
    uint constant MAXRATINGSCORE = 10;
    uint constant MAXRATINGTEXTLENGTH = 48;

    address private creator;
    IERC721Partial private collection;
    uint16[] private tokenIds16;
    uint32[] private tokenIds32;
    uint64[] private tokenIds64;
    uint[] private tokenIds256;
    uint64[3] private stats;

    mapping(address => Rating) public ratings;
    address[] public raters;

    event Swapped(address indexed account, uint indexed timestamp, uint[] inTokenIds, uint[] outTokenIds, uint64[3] stats);
    event Rated(address indexed account, uint indexed timestamp, uint score, string text, uint64[3] stats);

    error InsufficientTokensToBurn();
    error InvalidTokenId(uint tokenId);
    error MaxRatingExceeded(uint max);
    error InvalidRatingMessage();

    function initUmswap(address _creator, IERC721Partial _collection, string calldata _symbol, string calldata _name, uint[] calldata tokenIds) public {
        creator = _creator;
        collection = _collection;
        super.initBasicToken(msg.sender, _symbol, _name, DECIMALS);
        uint maxTokenId;
        for (uint i = 0; i < tokenIds.length; i = onePlus(i)) {
            if (tokenIds[i] > maxTokenId) {
                maxTokenId = tokenIds[i];
            }
        }
        if (maxTokenId < 2 ** 16) {
            for (uint i = 0; i < tokenIds.length; i = onePlus(i)) {
                tokenIds16.push(uint16(tokenIds[i]));
            }
        } else if (maxTokenId < 2 ** 32) {
            for (uint i = 0; i < tokenIds.length; i = onePlus(i)) {
                tokenIds32.push(uint32(tokenIds[i]));
            }
        } else if (maxTokenId < 2 ** 64) {
            for (uint i = 0; i < tokenIds.length; i = onePlus(i)) {
                tokenIds64.push(uint64(tokenIds[i]));
            }
        } else {
            tokenIds256 = tokenIds;
        }
    }

    /// @dev Is tokenId valid?
    /// @param tokenId TokenId to check
    /// @return True if valid
    function isValidTokenId(uint tokenId) public view returns (bool) {
        if (tokenIds16.length > 0) {
            return ArrayUtils.includes16(tokenIds16, tokenId);
        } else if (tokenIds32.length > 0) {
            return ArrayUtils.includes32(tokenIds32, tokenId);
        } else if (tokenIds64.length > 0) {
            return ArrayUtils.includes64(tokenIds64, tokenId);
        } else if (tokenIds256.length > 0) {
            return ArrayUtils.includes256(tokenIds256, tokenId);
        } else {
            return true;
        }
    }

    /// @dev Swap tokens into and out of the Umswap, with a optional ETH tip
    /// @param inTokenIds TokenIds to be transferred in
    /// @param outTokenIds TokenIds to be transferred out
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function swap(uint[] calldata inTokenIds, uint[] calldata outTokenIds, address integrator) public payable reentrancyGuard {
        if (outTokenIds.length > inTokenIds.length) {
            uint tokensToBurn = (outTokenIds.length - inTokenIds.length) * 10 ** DECIMALS;
            if (tokensToBurn > this.balanceOf(msg.sender)) {
                revert InsufficientTokensToBurn();
            }
            _burn(msg.sender, tokensToBurn);
        }
        for (uint i = 0; i < inTokenIds.length; i = onePlus(i)) {
            if (!isValidTokenId(inTokenIds[i])) {
                revert InvalidTokenId(inTokenIds[i]);
            }
            collection.transferFrom(msg.sender, address(this), inTokenIds[i]);
        }
        for (uint i = 0; i < outTokenIds.length; i = onePlus(i)) {
            if (!isValidTokenId(outTokenIds[i])) {
                revert InvalidTokenId(outTokenIds[i]);
            }
            collection.transferFrom(address(this), msg.sender, outTokenIds[i]);
        }
        if (outTokenIds.length < inTokenIds.length) {
            _mint(msg.sender, (inTokenIds.length - outTokenIds.length) * 10 ** DECIMALS);
        }
        stats[uint(Stats.SwappedIn)] += uint64(inTokenIds.length);
        stats[uint(Stats.SwappedOut)] += uint64(outTokenIds.length);
        emit Swapped(msg.sender, block.timestamp, inTokenIds, outTokenIds, stats);
        handleTips(integrator, owner);
    }

    /// @dev Rate a Umswap, with a optional ETH tip. Ratings scores can be updated forever
    /// @param score Score between 0 and `MAXRATINGSCORE` inclusive
    /// @param text Length between 1 and `MAXRATINGTEXTLENGTH`
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function rate(uint score, string calldata text, address integrator) public payable reentrancyGuard {
        if (score > MAXRATINGSCORE) {
            revert MaxRatingExceeded(MAXRATINGSCORE);
        }
        bytes memory textBytes = bytes(text);
        if (textBytes.length > MAXRATINGTEXTLENGTH) {
            revert InvalidRatingMessage();
        }
        Rating storage rating = ratings[msg.sender];
        if (rating.account == address(0)) {
            ratings[msg.sender] = Rating(msg.sender, uint64(score));
            raters.push(msg.sender);
        } else {
            stats[uint(Stats.TotalScores)] -= rating.score;
            rating.score = uint64(score);
        }
        stats[uint(Stats.TotalScores)] += uint64(score);
        emit Rated(msg.sender, block.timestamp, score, text, stats);
        handleTips(integrator, owner);
    }

    /// @dev Send an ETH tip
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function tip(address integrator) public payable reentrancyGuard {
        handleTips(integrator, owner);
    }

    /// @dev Get info
    /// @return symbol_ Symbol
    /// @return name_ Name
    /// @return collection_ Collection
    /// @return tokenIds_ TokenIds
    /// @return creator_ Creator
    /// @return stats_ Stats
    function getInfo() public view returns (string memory symbol_, string memory name_, IERC721Partial collection_, uint[] memory tokenIds_, address creator_, uint[] memory stats_) {
        symbol_ = _symbol;
        name_ = _name;
        collection_ = collection;
        if (tokenIds16.length > 0) {
            tokenIds_ = new uint[](tokenIds16.length);
            for (uint i = 0; i < tokenIds16.length; i = onePlus(i)) {
                tokenIds_[i] = tokenIds16[i];
            }
        } else if (tokenIds32.length > 0) {
            tokenIds_ = new uint[](tokenIds32.length);
            for (uint i = 0; i < tokenIds32.length; i = onePlus(i)) {
                tokenIds_[i] = tokenIds32[i];
            }
        } else if (tokenIds64.length > 0) {
            tokenIds_ = new uint[](tokenIds64.length);
            for (uint i = 0; i < tokenIds64.length; i = onePlus(i)) {
                tokenIds_[i] = tokenIds64[i];
            }
        } else if (tokenIds256.length > 0) {
            tokenIds_ = new uint[](tokenIds256.length);
            for (uint i = 0; i < tokenIds256.length; i = onePlus(i)) {
                tokenIds_[i] = tokenIds256[i];
            }
        } else {
            tokenIds_ = new uint[](0);
        }
        creator_ = creator;
        stats_ = new uint[](5);
        stats_[0] = stats[uint(Stats.SwappedIn)];
        stats_[1] = stats[uint(Stats.SwappedOut)];
        stats_[2] = stats[uint(Stats.TotalScores)];
        stats_[3] = _totalSupply;
        stats_[4] = raters.length;
    }

    function getRatings(uint[] memory indices) public view returns (Rating[] memory ratings_) {
        uint length = indices.length;
        ratings_ = new Rating[](length);
        for (uint i = 0; i < length; i = onePlus(i)) {
            address rater = raters[i];
            ratings_[i] = ratings[rater];
        }
    }
}


/// @title Factory to deploy cloned Umswaps instances
/// @author BokkyPooBah, Bok Consulting Pty Ltd
contract UmswapFactory is Owned, TipHandler, ReentrancyGuard, CloneFactory {

    bytes1 constant SPACE = 0x20;
    bytes1 constant ZERO = 0x30;
    bytes1 constant TILDE = 0x7e;
    bytes constant UMSYMBOLPREFIX = "UMS";
    bytes4 constant ERC721_INTERFACE = 0x80ac58cd;
    uint constant MAXNAMELENGTH = 48;
    uint constant MAXTOPICLENGTH = 48;
    uint constant MAXTEXTLENGTH = 280;

    Umswap public template;
    Umswap[] public umswaps;
    mapping(Umswap => bool) umswapExists;
    mapping(bytes32 => bool) setExists;

    error NotERC721();
    error InvalidName();
    error InvalidTopic();
    error InvalidMessage();
    error InvalidUmswap();
    error DuplicateSet();
    error TokenIdsMustBeSortedWithNoDuplicates();

    event NewUmswap(address indexed creator, uint timestamp, Umswap indexed umswap, IERC721Partial indexed collection, string name, uint[] tokenIds);
    event Message(address indexed from, uint timestamp, address indexed to, Umswap indexed umswap, string topic, string message);
    event Withdrawn(address owner, uint timestamp, address indexed token, uint tokens, uint tokenId);

    constructor() {
        super.initOwned(msg.sender);
        template = new Umswap();
    }

    function isERC721(address token) internal view returns (bool b) {
        if (token.code.length > 0) {
            try IERC721Partial(token).supportsInterface(ERC721_INTERFACE) returns (bool _b) {
                b = _b;
            } catch {
            }
        }
    }

    function genSymbol(uint id) internal pure returns (string memory s) {
        bytes memory b = new bytes(8);
        uint i;
        uint j;
        uint num;
        for (i = 0; i < UMSYMBOLPREFIX.length; i = onePlus(i)) {
            b[j++] = UMSYMBOLPREFIX[i];
        }
        i = 5;
        do {
            unchecked {
                i--;
            }
            num = id / 10 ** i;
            b[j++] = bytes1(uint8(num % 10 + uint8(ZERO)));
        } while (i > 0);
        s = string(b);
    }

    /// @dev Is name valid? Length between 1 and `MAXNAMELENGTH`. Characters between SPACE and TILDE inclusive. No leading, trailing or repeating SPACEs
    /// @param str Name to check
    /// @return True if valid
    function isValidName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1 || b.length > MAXNAMELENGTH) {
            return false;
        }
        if (b[0] == SPACE || b[b.length-1] == SPACE) {
            return false;
        }
        bytes1 lastChar = b[0];
        for (uint i; i < b.length; i = onePlus(i)) {
            bytes1 char = b[i];
            if (char == SPACE && lastChar == SPACE) {
                return false;
            }
            if (!(char >= SPACE && char <= TILDE)) {
                return false;
            }
            lastChar = char;
        }
        return true;
    }

    /// @dev Create new Umswap, with a optional ETH tip
    /// @param collection ERC-721 contract address
    /// @param name Name. See `isValidName` for valid names
    /// @param tokenIds List of valid tokenIds in this Umswap. Set to [] for any tokenIds in the collection
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function newUmswap(IERC721Partial collection, string calldata name, uint[] calldata tokenIds, address integrator) public payable reentrancyGuard {
        if (!isERC721(address(collection))) {
            revert NotERC721();
        }
        if (!isValidName(name)) {
            revert InvalidName();
        }
        if (tokenIds.length > 0) {
            for (uint i = 1; i < tokenIds.length; i = onePlus(i)) {
                if (tokenIds[i - 1] >= tokenIds[i]) {
                    revert TokenIdsMustBeSortedWithNoDuplicates();
                }
            }
        }
        bytes32 key = keccak256(abi.encodePacked(collection, name, tokenIds));
        if (setExists[key]) {
            revert DuplicateSet();
        }
        setExists[key] = true;
        Umswap umswap = Umswap(payable(createClone(address(template))));
        umswap.initUmswap(msg.sender, collection, genSymbol(umswaps.length), name, tokenIds);
        umswaps.push(umswap);
        umswapExists[umswap] = true;
        emit NewUmswap(msg.sender, block.timestamp, umswap, collection, name, tokenIds);
        handleTips(integrator, address(this));
    }

    /// @dev Send message, with a optional ETH tip
    /// @param to Destination address, or address(0) for general messages
    /// @param umswap Specific umswap address, or address(0) for general messages
    /// @param topic Message topic. Length between 0 and `MAXTOPICLENGTH`
    /// @param text Message text. Length between 1 and `MAXTEXTLENGTH`
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function sendMessage(address to, Umswap umswap, string calldata topic, string calldata text, address integrator) public payable reentrancyGuard {
        bytes memory topicBytes = bytes(topic);
        if (topicBytes.length > MAXTOPICLENGTH) {
            revert InvalidTopic();
        }
        bytes memory messageBytes = bytes(text);
        if (messageBytes.length < 1 || messageBytes.length > MAXTEXTLENGTH) {
            revert InvalidMessage();
        }
        if (umswap != Umswap(address(0)) && !umswapExists[umswap]) {
            revert InvalidUmswap();
        }
        emit Message(msg.sender, block.timestamp, to, umswap, topic, text);
        handleTips(integrator, address(this));
    }

    /// @dev Send an ETH tip
    /// @param integrator Any sent ETH tip will be split with this address if non-address(0)
    function tip(address integrator) public payable reentrancyGuard {
        handleTips(integrator, address(this));
    }

    /// @dev Receive ETH
    receive() external payable {
    }

    /// @dev Only owner can withdraw ETH tips & other ERC-20/ERC-721 tokens sent to this contract
    /// @param token ERC-20/ERC-721 token contract address. Set to address(0) for ETH withdrawals
    /// @param tokens ETH/ERC-20 tokens to withdraw. Set to 0 for the full balance
    /// @param tokenId ERC-721 tokenId. Set to 0 for ETH/ERC-20 withdrawals
    function withdraw(address token, uint tokens, uint tokenId) public onlyOwner {
        if (token == address(0)) {
            if (tokens == 0) {
                tokens = address(this).balance;
            }
            payable(owner).transfer(tokens);
        } else {
            if (isERC721(token)) {
                IERC721Partial(token).safeTransferFrom(address(this), owner, tokenId);
            } else {
                if (tokens == 0) {
                    tokens = IERC20(token).balanceOf(address(this));
                }
                IERC20(token).transfer(owner, tokens);
            }
        }
        emit Withdrawn(msg.sender, block.timestamp, token, tokens, tokenId);
    }

    function getUmswapsLength() public view returns (uint _length) {
        return umswaps.length;
    }

    function getUmswaps(uint[] memory indices) public view returns (
        Umswap[] memory umswaps_,
        string[] memory symbols,
        string[] memory names,
        IERC721Partial[] memory collections,
        uint[][] memory tokenIds,
        address[] memory creators,
        uint[][] memory stats
    ) {
        uint length = indices.length;
        umswaps_ = new Umswap[](length);
        symbols = new string[](length);
        names = new string[](length);
        collections = new IERC721Partial[](length);
        tokenIds = new uint[][](length);
        creators = new address[](length);
        stats = new uint[][](length);
        for (uint i = 0; i < length; i = onePlus(i)) {
            umswaps_[i] = umswaps[i];
            (symbols[i], names[i], collections[i], tokenIds[i], creators[i], stats[i]) = umswaps[i].getInfo();
        }
    }
}