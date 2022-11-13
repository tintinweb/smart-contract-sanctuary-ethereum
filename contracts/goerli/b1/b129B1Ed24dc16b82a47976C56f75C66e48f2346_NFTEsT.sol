// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {LibString} from "../utils/LibString.sol";
import "../tokens/ERC721Limited.sol";
import "../access/OperatorFilterer.sol";
import "../access/Paid.sol";

contract NFTEsT is ERC721Limited, OpenSeaDefaultOperatorFilterer, Paid {
    modifier onlyOwnerOrAllowedOperator() {
        address __msgSender = _msgSender();
        if(owner() != __msgSender) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), __msgSender)) {
                revert OperatorNotAllowed(__msgSender);
            }
        }
        _;
    }

    modifier onlyPaidOrOwnerOperator(uint price) {
        address __msgSender = _msgSender();
        address _owner = owner();
        uint tokenId = nextTokenId();
        if(__msgSender != _owner) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), __msgSender)) {                
                if(msg.value < price) {
                    revert OperatorNotAllowed(__msgSender);
                }
            }   
            if(payLock_ == PayLock.Disabled) {
                payLock_ = PayLock.Enabled;
            } else {
                revert ReentryLocked();
            }         
        }
        _;
        if(__msgSender != _owner) {                        
            if(payLock_ == PayLock.Enabled) {
                payLock_ = PayLock.Disabled;
            } else {
                revert ReentryLocked();
            }
            _lastPaid[tokenId] = msg.value;
            _cloneTimer[tokenId] = 
                block.number + MAX_DELAY_TO_CLONE - (((msg.value - price) * 860) / price);
        }
    }

    error BlocknumberNotReached(uint current, uint target);

    uint public constant OPEN_MINT_PRICE = 0.0005 ether;
    uint public constant MAX_DELAY_TO_CLONE = 86000;
    mapping(uint => uint) internal _cloneTimer;
    mapping(uint => uint) internal _lastPaid;

    constructor()
        ERC721Limited("NFT EsTest", "NFTEsT", "ipfs://bafybeie5zkvb77u63zfxlxtdeu4gkqdzywbeb277zuunzxu6slt2jqhj3i/", 1211)
    {}
    
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function mintTo(address to_) 
    external payable onlyPaidOrOwnerOperator(OPEN_MINT_PRICE)  {
        _mintTo(to_);
    }

    function mint(
        address to_
    ) external payable onlyPaidOrOwnerOperator(OPEN_MINT_PRICE) {
        _mintTo(to_);
    }

    function safeMint(
        address to_
    ) external payable onlyPaidOrOwnerOperator(OPEN_MINT_PRICE) {
        _mintTo(to_);
    }

    function safeMint(
        address to_,
        bytes memory data_
    ) external payable onlyPaidOrOwnerOperator(OPEN_MINT_PRICE) {
        _mintTo(to_, data_);
    }

    function batchMint(
        address to_, 
        uint amount_
    ) external onlyOwnerOrAllowedOperator {
        _batchMint(to_, amount_);
    }

    function cloneMint(uint tokenId_) external payable {
        address msgSender = _msgSender();
        if(!isApprovedOrOwner(msgSender, tokenId_)) 
            revert NotAuthorized();
        uint timer = _cloneTimer[tokenId_];    
        if(timer > block.number)
            revert BlocknumberNotReached(block.number, timer);
        uint __supplyCap = _supplyCap;
        // initial mint is gen 1, division rounds down
        uint generation = 1 + (tokenId_ / __supplyCap);
        uint id = tokenId_ + __supplyCap;

        _cloneMint(msgSender, id);

        unchecked {
            // SAFE: BlocknumberNotReached check ensures 
            //       block.number > timer
            uint remainder = block.number - timer;
            
            // SAFE: first tokenID must be baseTokenId+1
            _expand(tokenId_-1, __supplyCap, generation, remainder, msgSender);        
            // SAFE: last tokenID can at most be baseToken+(supplyCap*generation)
            //       generation only increments when baseToken+(supplyCap*generation) is safe 
            //       for initial value without generation check,
            //       baseToken and supplyCap can at most be uint128 max - 2
            _expand(tokenId_+1, __supplyCap, generation, remainder, msgSender);        

            // SAFE: _totalSupply >= balanceOf
            uint price = _lastPaid[tokenId_];
            // scaled price must be at least 0.00001 ETH to effect delay
            if (msg.value > price && price > 10e12) {
                // SAFE: Except for very low block numbers, outside range of test/main net
                _cloneTimer[id] = 
                    block.number + MAX_DELAY_TO_CLONE - (((msg.value - price) * 860) / price);
            } else {            
                // SAFE: Except very far into the future
                _cloneTimer[id] = block.number + MAX_DELAY_TO_CLONE;
            }
        }
        _lastPaid[id] = msg.value;
    }

    function _expand(
        uint tokenId_,
        uint supplyCap_, 
        uint generation_, 
        uint remainder_, 
        address msgSender_
    ) internal {
        // SAFE: As long as supplyCap > 1
        if (1 + (tokenId_ / supplyCap_) == generation_) {
            uint timer = _cloneTimer[tokenId_];
            if(timer > block.number) {             
                // SAFE: remainder is < block.number
                if(block.number > timer - remainder_) {
                    // SAFE: Other than last possible generation maybe
                    uint id = tokenId_ + supplyCap_;
                    if(_ownerOf[id] == address(0)) {
                        // pwn
                        _cloneMint(msgSender_, id);
                    }
                }
            }
        }
    }

    function _cloneMint(address to_, uint id_) internal returns(uint) {
        // first come first serve
        cantExist(id_);

        _ownerOf[id_] = to_;
        
        unchecked {
            // SAFE: Total supply can't be above max
            ++_balanceOf[to_];
        }

        emit Transfer(address(0), to_, id_);

        return id_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../interfaces/IOperatorFilterRegistry.sol";

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(
                    operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                        && operatorFilterRegistry.isOperatorAllowed(address(this), from)
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

abstract contract OpenSeaDefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import {LibString} from "../utils/LibString.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Limited.sol";
import "../access/Ownable.sol";
import "../access/Context.sol";
import "../access/Address.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721Limited is IERC721, IERC721Limited, IERC721Metadata, Ownable, Context {
    using Address for address;  // for isContract
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/    
    error AllMinted();
    error AlreadyMinted(uint tokenId);    

    error NotMinted(uint tokenId);
    error NotAuthorized();
    error NotApproved();

    error UnsafeTransaction();
    error UnsafeRecipient(address recipient);
    error UnsafeValues();
    
    error InvalidFrom(address from);
    error InvalidTo(address to);
    error InvalidRecipient(address recipient);
    error InvalidAddress(address);
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event BaseURIChange(string olduRI, string newURI);
    
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;
    
    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    
    /**
     * Prevents minting after the nextTokenId counter has been incremented
     * this many times. Will take into consideration startTokenId and
     * together they define the range of TokenIDs that will be produced.
     */
    uint128 immutable internal _supplyCap;

    string internal _baseURI;

    /**
     * Points to an online resource that serves the json metadata based on
     * only the tokenId. TokenId is constructed as:
     *          _baseURI + tokenId + ".json"
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }
    function setBaseURI(string memory uri) public virtual onlyOwner {
        emit BaseURIChange(_baseURI, uri);
        _baseURI = uri;
    }
    
    function startTokenId() public view virtual override returns(uint256) {
        return 1;
    }

    function nextTokenId() public view virtual override returns(uint256) {
        return _nextTokenId.current();
    }

    function endTokenId() public view virtual override returns(uint256) {
        return uint256(_supplyCap);
    }

    function supplyCap() public view virtual returns(uint256) {
        return uint256(_supplyCap);
    }
    /**
     * @dev Returns the total tokens minted so far.
     * 1 is always subtracted from the Counter since it tracks the next available tokenId.
    */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }
    function remainingSupply() public view returns (uint256) {
        unchecked {
            // SAFE: Counter is incremented once in constructor, underflow avoided
            return _supplyCap - (_nextTokenId.current() - 1);
        }
    }

    function isNextMintValid() public view returns (bool) {
        return _supplyCap != _nextTokenId.current() && 
            _ownerOf[_nextTokenId.current()] == address(0);
    }
    
    
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     * @return URI string
     */
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        mustExist(tokenId_);
        
        string memory __baseURI = _baseURI;

        return bytes(__baseURI).length == 0 ?
            "" :
            string(abi.encodePacked(__baseURI, LibString.toString(tokenId_), ".json"));
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner_) {
        if((owner_ = _ownerOf[id]) == address(0)) revert NotMinted(id);
    }

    function balanceOf(address owner_) public view virtual returns (uint256) {
        if(owner_ == address(0)) revert InvalidAddress(owner_);

        return _balanceOf[owner_];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public _getApproved;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev WARNING: startTokenId_ and supplyCap_ should NOT both be 
     *               max value to prevent overflow. This is enforced
     *               with the error `UnsafeValues`.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint128 supplyCap_        
    ) {
        name = name_;
        symbol = symbol_;

        _baseURI = baseURI_;

        // to prevent potential overflow issues elsewhere            
        if(supplyCap_+2 > type(uint128).max)
            revert UnsafeValues();
        
        _supplyCap = supplyCap_;
        
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment(); 
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/
    function approve(address spender, uint256 id) public virtual {
        address owner__ = _ownerOf[id];
        address msg_sender = _msgSender();

        if(spender == owner__) revert InvalidAddress(spender);
        if(msg_sender != owner__ && !_isApprovedForAll[owner__][msg_sender]) 
            revert NotAuthorized();

        _getApproved[id] = spender;

        emit Approval(owner__, spender, id);
    }
    
    function getApproved(uint id) public view returns (address) {
        if(_ownerOf[id] == address(0)) revert NotMinted(id);

        return _getApproved[id];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        address msg_sender = _msgSender();
        if(msg_sender == operator) revert InvalidAddress(operator);

        _isApprovedForAll[msg_sender][operator] = approved;

        emit ApprovalForAll(msg_sender, operator, approved);
    }

    function isApprovedForAll(
        address owner_, 
        address operator_
    ) public view virtual returns (bool) {
        if(owner_ == address(0)) revert InvalidAddress(owner_);

        return _isApprovedForAll[owner_][operator_];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {     
        if(!isApprovedOrOwner(_msgSender(), id)) revert NotApproved();        
        
        _transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        if(!isApprovedOrOwner(_msgSender(), id)) revert NotApproved(); 

        _safeTransfer(from, to, id, data);
    }    

    function burn(uint id) public virtual {
        if(!isApprovedOrOwner(_msgSender(), id)) revert NotApproved(); 

        _burn(id);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function _safeTransfer(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, id);
        _checkOnERC721Received(from, to, id, data);
    }

    function _transfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {
        if(from != _ownerOf[id]) revert InvalidFrom(from);
        if(to == address(0)) revert InvalidTo(to);  

        unchecked {
            // SAFE: InvalidFrom check ensures from owns at least this one, 
            //       thus no underflow
            --_balanceOf[from];
            // SAFE: Overflow impossible with supply cap
            ++_balanceOf[to];
        }

        _ownerOf[id] = to;

        delete _getApproved[id];

        emit Transfer(from, to, id);
    }

    function _mintTo(address to_) internal virtual {
        _mintTo(to_, "");
    }

    function _mintTo(address to_, bytes memory data) internal virtual {
        uint __nextTokenId = _nextTokenId.current();
        
        if(__nextTokenId > _supplyCap) 
            revert AllMinted();       

        _nextTokenId.increment();             

        _safeMint(to_, __nextTokenId, data);             
    }
    
    function _safeMint(address to, uint256 id) internal virtual {
        _safeMint(to, id, "");
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);
        _checkOnERC721Received(address(0), to, id, data);
    }

    function _batchMint(address to_, uint amount_) internal virtual {
        for (
            uint i;
            i < amount_;
        ) {
            _mintTo(to_);
            unchecked {
                ++i;
            }
        }
    }
    
    function _mint(address to, uint256 id) internal virtual {        
        if(to == address(0)) revert InvalidRecipient(to);
        if(_ownerOf[id] != address(0)) revert AlreadyMinted(id);

        unchecked {
            // SAFE: total supply must be less than uint128 max
            ++_balanceOf[to];
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner__ = _ownerOf[id];

        if(owner__ == address(0)) revert NotMinted(id);

        unchecked {
            // SAFE: NotMinted ownership check ensures no underflow
            --_balanceOf[owner__];
        }

        delete _ownerOf[id];

        delete _getApproved[id];

        emit Transfer(owner__, address(0), id);
    }

    

    /*//////////////////////////////////////////////////////////////
                INTERNAL VIRTUAL ACCESSORS for PRIVATE
    //////////////////////////////////////////////////////////////*/
    function isApprovedOrOwner(address spender_, uint256 tokenId_) 
        internal 
        view 
        virtual 
        returns (bool) 
    {
        address owner__ = _ownerOf[tokenId_];
        return (
            spender_ == owner__ || 
            _isApprovedForAll[owner__][spender_] || 
            getApproved(tokenId_) == spender_
        );
    }

    function mustExist(uint id) internal virtual view {
        if(_ownerOf[id] == address(0)) revert NotMinted(id);
    }
    
    function cantExist(uint id) internal virtual view {
        if(_ownerOf[id] != address(0)) revert AlreadyMinted(id);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE
    //////////////////////////////////////////////////////////////*/
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private  {
        if (to.isContract() && 
            ERC721TokenReceiver(to)
                .onERC721Received(_msgSender(), from, tokenId, data) 
                 != ERC721TokenReceiver.onERC721Received.selector)
                    revert UnsafeRecipient(to);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

abstract contract Paid {
    enum PayLock {
        Enabled,
        Disabled
    }

    modifier onlyPaid(uint price) {
        if(msg.value != price) {
            revert IncorrectPayment(msg.value, price);
        } else {
            if(payLock_ == PayLock.Disabled) {
                payLock_ = PayLock.Enabled;
            } else {
                revert ReentryLocked();
            }
        }
        _;
        if(payLock_ == PayLock.Enabled) {
            payLock_ = PayLock.Disabled;
        } else {
            revert ReentryLocked();
        }
    }

    error ReentryLocked();
    error IncorrectPayment(uint paid, uint price);

    PayLock payLock_ = PayLock.Disabled;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721 compliant contract with a limited mint.
 */
interface IERC721Limited {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/    
    error MintLimitExceeded();
    error OutOfRangeTokenID(uint id, uint min, uint max);
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/  
    event MintLimitReached();
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEWS
    //////////////////////////////////////////////////////////////*/      
    function supplyCap() external view returns (uint256);
    function isNextMintValid() external view returns (bool);
    function totalSupply() external view returns (uint256);
    function remainingSupply() external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function startTokenId() external view returns (uint256);
    function endTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

abstract contract Ownable {
    address internal _owner_;

    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner_ = msg.sender;
        emit OwnershipTransferred(address(0), _owner_);
    }

    function owner() public view returns (address) {
        return _owner_;
    }

    modifier onlyOwner() {
        if(_owner_ != msg.sender) revert NotOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner_, address(0));
        _owner_ = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0) || newOwner == _owner_) 
            revert InvalidOwner();
        emit OwnershipTransferred(_owner_, newOwner);
        _owner_ = newOwner;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >0.7.4;

/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Address.sol";

contract $Address {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $ACCOUNT_HASH() external pure returns (bytes32) {
        return Address.ACCOUNT_HASH;
    }

    function $isContract(address _address) external view returns (bool) {
        return Address.isContract(_address);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Context.sol";

contract $Context is Context {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/OperatorFilterer.sol";
import "../../contracts/interfaces/IOperatorFilterRegistry.sol";

contract $OperatorFilterer is OperatorFilterer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) OperatorFilterer(subscriptionOrRegistrantToCopy, subscribe) {}

    function $operatorFilterRegistry() external pure returns (IOperatorFilterRegistry) {
        return operatorFilterRegistry;
    }

    receive() external payable {}
}

contract $OpenSeaDefaultOperatorFilterer is OpenSeaDefaultOperatorFilterer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $DEFAULT_SUBSCRIPTION() external pure returns (address) {
        return DEFAULT_SUBSCRIPTION;
    }

    function $operatorFilterRegistry() external pure returns (IOperatorFilterRegistry) {
        return operatorFilterRegistry;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Ownable.sol";

contract $Ownable is Ownable {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_owner_() external view returns (address) {
        return _owner_;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Paid.sol";

contract $Paid is Paid {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $payLock_() external view returns (Paid.PayLock) {
        return payLock_;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC165.sol";

abstract contract $IERC165 is IERC165 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC721.sol";

abstract contract $IERC721 is IERC721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC721Limited.sol";

abstract contract $IERC721Limited is IERC721Limited {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC721Metadata.sol";

abstract contract $IERC721Metadata is IERC721Metadata {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOperatorFilterRegistry.sol";

abstract contract $IOperatorFilterRegistry is IOperatorFilterRegistry {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/ozzi-yees/NFTEsT.sol";
import "../../contracts/utils/LibString.sol";

contract $NFTEsT is NFTEsT {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_cloneMint_Returned(uint256 arg0);

    constructor() {}

    function $_cloneTimer(uint256 arg0) external view returns (uint256) {
        return _cloneTimer[arg0];
    }

    function $_lastPaid(uint256 arg0) external view returns (uint256) {
        return _lastPaid[arg0];
    }

    function $payLock_() external view returns (Paid.PayLock) {
        return payLock_;
    }

    function $DEFAULT_SUBSCRIPTION() external pure returns (address) {
        return DEFAULT_SUBSCRIPTION;
    }

    function $operatorFilterRegistry() external pure returns (IOperatorFilterRegistry) {
        return operatorFilterRegistry;
    }

    function $_supplyCap() external view returns (uint128) {
        return _supplyCap;
    }

    function $_baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function $_ownerOf(uint256 arg0) external view returns (address) {
        return _ownerOf[arg0];
    }

    function $_balanceOf(address arg0) external view returns (uint256) {
        return _balanceOf[arg0];
    }

    function $_owner_() external view returns (address) {
        return _owner_;
    }

    function $_expand(uint256 tokenId_,uint256 supplyCap_,uint256 generation_,uint256 remainder_,address msgSender_) external {
        return super._expand(tokenId_,supplyCap_,generation_,remainder_,msgSender_);
    }

    function $_cloneMint(address to_,uint256 id_) external returns (uint256) {
        (uint256 ret0) = super._cloneMint(to_,id_);
        emit $_cloneMint_Returned(ret0);
        return (ret0);
    }

    function $_safeTransfer(address from,address to,uint256 id,bytes calldata data) external {
        return super._safeTransfer(from,to,id,data);
    }

    function $_transfer(address from,address to,uint256 id) external {
        return super._transfer(from,to,id);
    }

    function $_mintTo(address to_) external {
        return super._mintTo(to_);
    }

    function $_mintTo(address to_,bytes calldata data) external {
        return super._mintTo(to_,data);
    }

    function $_safeMint(address to,uint256 id) external {
        return super._safeMint(to,id);
    }

    function $_safeMint(address to,uint256 id,bytes calldata data) external {
        return super._safeMint(to,id,data);
    }

    function $_batchMint(address to_,uint256 amount_) external {
        return super._batchMint(to_,amount_);
    }

    function $_mint(address to,uint256 id) external {
        return super._mint(to,id);
    }

    function $_burn(uint256 id) external {
        return super._burn(id);
    }

    function $isApprovedOrOwner(address spender_,uint256 tokenId_) external view returns (bool) {
        return super.isApprovedOrOwner(spender_,tokenId_);
    }

    function $mustExist(uint256 id) external view {
        return super.mustExist(id);
    }

    function $cantExist(uint256 id) external view {
        return super.cantExist(id);
    }

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/tokens/ERC721Limited.sol";
import "../../contracts/utils/LibString.sol";

contract $ERC721Limited is ERC721Limited {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint128 supplyCap_) ERC721Limited(name_, symbol_, baseURI_, supplyCap_) {}

    function $_supplyCap() external view returns (uint128) {
        return _supplyCap;
    }

    function $_baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function $_ownerOf(uint256 arg0) external view returns (address) {
        return _ownerOf[arg0];
    }

    function $_balanceOf(address arg0) external view returns (uint256) {
        return _balanceOf[arg0];
    }

    function $_owner_() external view returns (address) {
        return _owner_;
    }

    function $_safeTransfer(address from,address to,uint256 id,bytes calldata data) external {
        return super._safeTransfer(from,to,id,data);
    }

    function $_transfer(address from,address to,uint256 id) external {
        return super._transfer(from,to,id);
    }

    function $_mintTo(address to_) external {
        return super._mintTo(to_);
    }

    function $_mintTo(address to_,bytes calldata data) external {
        return super._mintTo(to_,data);
    }

    function $_safeMint(address to,uint256 id) external {
        return super._safeMint(to,id);
    }

    function $_safeMint(address to,uint256 id,bytes calldata data) external {
        return super._safeMint(to,id,data);
    }

    function $_batchMint(address to_,uint256 amount_) external {
        return super._batchMint(to_,amount_);
    }

    function $_mint(address to,uint256 id) external {
        return super._mint(to,id);
    }

    function $_burn(uint256 id) external {
        return super._burn(id);
    }

    function $isApprovedOrOwner(address spender_,uint256 tokenId_) external view returns (bool) {
        return super.isApprovedOrOwner(spender_,tokenId_);
    }

    function $mustExist(uint256 id) external view {
        return super.mustExist(id);
    }

    function $cantExist(uint256 id) external view {
        return super.cantExist(id);
    }

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    receive() external payable {}
}

contract $ERC721TokenReceiver is ERC721TokenReceiver {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/utils/LibString.sol";

contract $LibString {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $toString(uint256 value) external pure returns (string memory) {
        return LibString.toString(value);
    }

    receive() external payable {}
}