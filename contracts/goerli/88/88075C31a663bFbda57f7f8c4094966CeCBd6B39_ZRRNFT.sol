// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721G.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract ZRRNFT is ERC721G, Ownable, ERC721Holder{
    using Strings for uint256;

    bool public isPublic;
    bool public isNotWhite;
    uint256 public maxSupply;
    address public devAddress;
    uint256 public constant WHITE_PRICE = 300000000000000000; //0.3 ETH
    uint256 public constant PRIV_PRICE = 300000000000000000; //0.3 ETH
    uint256 public constant PUB_PRICE = 430000000000000000; //0.43 ETH
    string private _baseTokenURI;
    constructor() ERC721G("Zodiac Rankings Race", "ZRR", 1, 3) {
        maxSupply = 999;
        devAddress = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == devAddress || msg.sender == owner(), "ZRR: Only Governance");
        _;
    }

    function chgToPub() external onlyGovernance {
        isPublic = !isPublic;
    }

    function chgToNotWhite() external onlyGovernance {
        isNotWhite = !isNotWhite;
    }

    function setBaseURI(string calldata baseURI) external onlyGovernance {
        _baseTokenURI = baseURI;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20(_tokenContract).transfer(msg.sender, _amount);
    }
    
    function mint(uint256 _amount) payable external{
        if(!isNotWhite) {
            require(_amount <= 1, "ZRR: Max 1 per mint");
            require(msg.value == WHITE_PRICE * _amount, "ZRR: Priv Insufficient ETH");
            require(_balanceData[msg.sender].mintedAmount < 1, "ZRR: Max 1 mint per address");
            require(_amount + totalSupply() <= 40, "ZRR: End for whitelist sales");
        }
        else {
            require(_amount <= 3, "ZRR: Max 3 per mint");
            require(_balanceData[msg.sender].mintedAmount < 3, "ZRR: Max 3 mint per address");
            if (!isPublic) {
                require(msg.value == PRIV_PRICE * _amount, "ZRR: Insufficient ETH");
                require(_amount + totalSupply() <= 666, "ZRR: End for private sales");

            }
            else {
                require(msg.value == PUB_PRICE * _amount, "ZRR: Insufficient ETH");
                require(_amount + totalSupply() <= maxSupply, "ZRR: All minted");

            }
        }

        _mint(msg.sender, _amount);
    }

    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory) {
        require(tokenId_ > 0, "ZRR: Id starts from 1");
        require(_exists(tokenId_),"ZRR: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0  ? string(abi.encodePacked(baseURI, tokenId_.toString())) : "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//★    _______  _____  _______ ___  _____  ★//
//★   / __/ _ \/ ___/ /_  /_  <  / / ___/  ★//
//★  / _// , _/ /__    / / __// / / (_ /   ★//
//★ /___/_/|_|\___/   /_/____/_/  \___/    ★//
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//  by: 0xInuarashi                         //
//////////////////////////////////////////////
//  Audits: 0xAkihiko, 0xFoobar             //
//////////////////////////////////////////////        
//  Default: Staking Disabled               //
//////////////////////////////////////////////

contract ERC721G {

    // Standard ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved,
        uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator,
        bool approved);
 
    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId
    uint256 public immutable startTokenId; // Bytes Storage for the starting TokenId
    uint256 public immutable maxBatchSize;

    // ERC721G Staking Address Target
    function stakingAddress() public view returns (address) {
        return address(this);
    }

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    constructor(
    string memory name_, string memory symbol_, 
    uint256 startId_, uint256 maxBatchSize_) {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf
        uint32 lastTransfer; // stores the last transfer of the token
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveal

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public virtual view returns (uint256) {
        return tokenIndex - startTokenId;
    }
    function balanceOf(address address_) public virtual view returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////
    
    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     * 
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_) public virtual view
    returns (OwnerStruct memory) {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");
        
        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (_tokenData[tokenId_].owner != address(0)
            || tokenId_ >= tokenIndex) {
            return _tokenData[tokenId_];
        }

        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else { unchecked {
            uint256 _lowerRange = tokenId_;
            while (mintIndex[_lowerRange].owner == address(0)) { _lowerRange--; }
            return mintIndex[_lowerRange];
        }}
    }

    /** @dev explanation: 
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or 
     *  uninitialized pointer. 
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return _OwnerStruct.owner;
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks. 
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_) public virtual view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////
    
    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not. 
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(uint256 tokenId_, OwnerStruct memory _OwnerStruct) 
    internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    ///// ERC721G Range-Based Internal Minting Logic /////
    
    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic. 
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(amount_ <= maxBatchSize, 
            "ERC721G: _mintInternal over maxBatchSize");

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        mintIndex[_startId].owner = to_;

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked { 
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     * 
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *  
     *  this results in INITIALIZATION of the token, if it has not been initialized yet. 
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;

        // update the balance data
        unchecked { 
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally 
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        address _owner = ownerOf(tokenId_);
        return (
            // "i am the owner of the token, and i am transferring it"
            _owner == spender_
            // "the token's approved spender is me"
            || getApproved[tokenId_] == spender_
            // "the owner has approved me to spend all his tokens"
            || isApprovedForAll[_owner][spender_]);
    }
    
    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender 
            // "i am isApprovedForAll, so i can approve this token too."
            || isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized");

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(address owner_, address operator_, bool approved_) 
    internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        // this function can only be used as self-approvalforall for others. 
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal virtual view returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /** @dev description: walletOfOwner to query an array of wallet's
     *  owned tokens. A view-intensive alternative ERC721Enumerable function.
     */
    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) { _tokens[_currentIndex++] = i; }
            unchecked { ++i; }
        }
        return _tokens;
    }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////

    /** @dev requirement: You MUST implement your own tokenURI logic here 
     *  recommended to use through an override function in your main contract.
     */
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}