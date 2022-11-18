// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";

/** Controllerable: Dynamic Controller System

    string controllerType is a string version of controllerSlot
    bytes32 controllerSlot is a keccak256(abi.encodePacked("ControllerName"<string>))
        used to store the type of controller type
    address controller is the address of the controller
    bool status is the status of controller (true = is controller, false = is not)

    usage: call isController with string type_ and address of user to receive a boolean
*/

abstract contract Controllerable is Ownable {

    event ControllerSet(string indexed controllerType, bytes32 indexed controllerSlot, 
        address indexed controller, bool status);

    mapping(bytes32 => mapping(address => bool)) internal __controllers;

    function isController(string memory type_, address controller_) public 
    view returns (bool) {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        return __controllers[_slot][controller_];
    }

    function setController(string calldata type_, address controller_, bool bool_) 
    external onlyOwner {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        __controllers[_slot][controller_] = bool_;
        emit ControllerSet(type_, _slot, controller_, bool_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Short and Simple Ownable by 0xInuarashi
// Ownable follows EIP-173 compliant standard

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!"); _; }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ERC721TokenURI {

    string public baseTokenURI;

    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }

    function _toString(uint256 value_) internal pure virtual 
    returns (string memory _str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            _str := sub(m, 0x20)
            mstore(_str, 0)

            let end := _str

            for { let temp := value_ } 1 {} {
                _str := sub(_str, 1)
                mstore8(_str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, _str)
            _str := sub(_str, 0x20)
            mstore(_str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Lightweight & Readable Batch Minting ERC721 by 0xInuarashi
// Library: CypherMate
// Inspirations: ERC721G, ERC721A

/** @dev this contract has not yet been fully tested. */

/** @dev this contract uses batch minting logic which modifies
         _mint to take AMOUNT argument instead of TOKENID argument
*/

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) 
    external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

abstract contract ERC721B {
    
    ///// Events /////
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed spender_, 
        uint256 indexed id_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
        bool approved_);

    ///// Token Data /////
    string public name; 
    string public symbol;

    uint256 public nextTokenId;
    uint256 public totalBurned;
    
    /** @dev change or override this to modify the starting token Id */
    function startTokenId() public pure virtual returns (uint256) {
        return 0;
    }

    /** @dev totalSupply performs arithmetics and then returns */
    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - totalBurned - startTokenId();
    }

    ///// Constructor /////
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        nextTokenId = startTokenId();
    }

    ///// Token Storage /////
    struct TokenData {
        address owner;
        uint40 lastTransfer;
        bool burned; /** @dev burned stores the burn state of token to revert on query */
        bool nextInitialized; /** @dev helps saves 1 SLOAD on bookmark N+1 lookup */
        /** @dev 6 free bytes */
    }
    struct BalanceData {
        uint32 balance;
        uint32 mintedAmount;
        /** @dev 24 free bytes */
    }

    /** @dev these mappings replace ownerOf and balanceOf with structs */
    mapping(uint256 => TokenData) public _tokenData;
    mapping(address => BalanceData) public _balanceData;

    ///// Token Approvals /////
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    ///// ERC721B Batch Logic /////
    /** @dev _getTokenDataOf returns the TokenData struct of the tokenId_ by either 
             returning the initialized TokenData or performing a lookup-trace to the
             bookmarked location
    */
    function _getTokenDataOf(uint256 tokenId_) public view virtual 
    returns (TokenData memory) {
        // Set the starting lookupId to save on gas on operations
        uint256 _lookupId = tokenId_;
        // The tokenId must be above the startTokenId only
        require(_lookupId >= startTokenId(), "_getTokenDataOf _lookupId < startTokenId");
        // Load the TokenData into memory for subsequent operations
        TokenData memory _TokenData = _tokenData[_lookupId];
        // If the TokenData is initialized and not burned, return it to end the flow
        if (_TokenData.owner != address(0) && !_TokenData.burned) return _TokenData;
        // If that's not the case, check if the token is burned. If so, revert
        require(!_TokenData.burned, "_getTokenDataOf burned token!");
        // If it's not initialized, check if it's above nextTokenId
        require(_lookupId < nextTokenId, "_getTokenDataOf _lookupId > _nextTokenId");
        // If it's not initialized and in-bounds, perform a lookup-trace
        /** @dev this part can be optimized */
        /** @dev we don't need to check burn status here because _burn logic does
                 automatic bookmarking making such circumstance impossible */
        unchecked { while(_tokenData[--_lookupId].owner == address(0)) {} }
        return _tokenData[_lookupId];
    }

    /** @dev returns the balance in the stored BalanceData struct of address */
    function balanceOf(address owner_) public virtual view returns (uint256) {
        require(owner_ != address(0), "balanceOf to 0x0");
        return _balanceData[owner_].balance;
    }

    /** @dev _getTokenDataOf reverts on burned tokens and out-of-bounds tokens 
             thus it will always return non-null addresses only
    */
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721 Functions /////
    /** @dev _mint and _burn does not have totalMinted manipulations */
    function _mint(address to_, uint256 amount_) internal virtual { unchecked {
        // We cannot mint to 0x0
        require(to_ != address(0), "_mint to 0x0");
        // We store the _startId from _nextTokenId to use for subsequent operations
        uint256 _startId = nextTokenId;
        uint256 _endId = _startId + amount_;
        // Store the initial TokenData bookmark at _startId
        _tokenData[_startId].owner = to_;
        _tokenData[_startId].lastTransfer = uint40(block.timestamp);
        // Add the balance and mint data to the minter
        _balanceData[to_].balance += uint32(amount_);
        _balanceData[to_].mintedAmount += uint32(amount_);
        // Phantom Mint all the tokens
        do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        // Set the totalMinted as the _endId
        nextTokenId = _endId;
    }}

    /** @dev _mint uses a burn flag instead of deleting token data */
    function _burn(uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        // Load the TokenData into memory
        /** @dev if the token is burned, _getTokenDataOf will revert,
                 so we can assume from here that flow is to an unburned token only.
                 _getTokenDataOf also ensures that the TokenData returned is
                 within valid tokenId bounds */
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        // Special checkApproved_ logical flow to save 1 SLOAD
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_),
                                    "_burn not approved");
        // Delete getApproved to clear any approvals for cleanliness
        delete getApproved[tokenId_];
        // Store the burner data at tokenId_
        _tokenData[tokenId_].owner = _owner;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        // Set the burned flag to true on the token
        _tokenData[tokenId_].burned = true;
        // After a burn, the next token must always be initialized
        _tokenData[tokenId_].nextInitialized = true;

        /** @dev Bookmarking Logic */
        // First, we check if slot N+1 is initialized
        if (!_TokenData.nextInitialized) {
            // Check if the slot at N+1 is actually initialized or not
            // because it is possible that the state above is false but 
            // the token is actually initialized (from mint-state)
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                // If it's not, we see if the tokenId is in-bounds for bookmarking
                if (tokenId_ < nextTokenId - 1) {
                    // If it is, we bookmark the N+1 slot with the current loaded TokenData
                    /** @dev This retains the owner of subsequent tokens
                            and prevents unintended overwriting of owner data */
                    _tokenData[tokenId_ + 1] = _TokenData;
                }
            }
        }
        
        // Update user balances
        _balanceData[_owner].balance--;
        // Emit a Burn Transfer
        emit Transfer(_owner, address(0), tokenId_);
        // Increment Burned Amount
        totalBurned++;
    }}
    // /** @dev _burn using standard arguments */
    // function _burn(uint256 tokenId_) internal virtual {
    //     _burn(tokenId_, false);
    // }

    /** @dev _transfer has a special checkApproved_ argument for gas-efficiency */
    function _transfer(address from_, address to_, uint256 tokenId_, 
    bool checkApproved_) internal virtual { unchecked {
        // We can't transfer to 0x0
        require(to_ != address(0), "_transfer to 0x0");
        // Load the TokenData into memory for further operations
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        // Argument from_ must be the owner
        require(from_ == _owner, "_transfer not from owner");
        // Special checkApproved_ logical flow to save 1 SLOAD
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_),
                               "_transfer not approved");
        // Delete getApproved to clear any approvals on transfer
        delete getApproved[tokenId_];
        // Transfer the token
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        // After a transfer, the next token must always be initialized 
        _tokenData[tokenId_].nextInitialized = true;
        
        /** @dev Bookmarking Logic */
        // First, we check if slot N+1 is initialized from token at N
        if (!_TokenData.nextInitialized) {
            // Check if the slot at N+1 is actually initialized or not
            // because it is possible that the state above is false but 
            // the token is actually initialized (from mint-state)
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                // If it's not, we see if the tokenId is in-bounds for bookmarking
                if (tokenId_ < nextTokenId - 1) {
                    // If it is, we bookmark the N+1 slot with the current loaded TokenData
                    /** @dev This retains the owner of subsequent tokens 
                            and prevents unintended overwriting of owner data */
                    _tokenData[tokenId_ + 1] = _TokenData;
                }
            }
        }

        // Update the balances
        _balanceData[from_].balance--;
        _balanceData[to_].balance++;
        // Emit a Transfer
        emit Transfer(from_, to_, tokenId_);
    }}
    // /** @dev a standard-style transfer mimics ERC721 _transfer behavior with 
    //          no approval checks */
    // function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
    //     _transfer(from_, to_, tokenId_, false);
    // }

    /** @dev transferFrom uses special _transfer with approval check flow
             which saves 1 SLOAD */
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        _transfer(from_, to_, tokenId_, true);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        require(to_.code.length == 0 ||
            ERC721TokenReceiver(to_)
            .onERC721Received(msg.sender, from_, tokenId_, data_) ==
            ERC721TokenReceiver.onERC721Received.selector, 
            "safeTransferFrom to unsafe address");
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    ///// ERC721 Approvals /////
    function approve(address spender_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
                "approve not authorized!");
        getApproved[tokenId_] = spender_;
        emit Approval(_owner, spender_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }
    /** @dev _isApprovedOrOwner has a special owner_ argument for gas-efficiency */
    function _isApprovedOrOwner(address owner_, address spender_, uint256 tokenId_) 
    internal virtual view returns (bool) {
        return (owner_ == spender_ ||
                getApproved[tokenId_] == spender_ ||
                isApprovedForAll[owner_][spender_]);
    }

    ///// ERC165 Interface /////
    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return  iid_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                iid_ == 0x80ac58cd || // ERC165 Interface ID for ERC721
                iid_ == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    /** @dev tokenURI is not implemented */
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules
import {ERC721B} from "cyphersuite/tokens/ERC721/ERC721B.sol";
import {ERC721TokenURI} from "cyphersuite/metadata/ERC721TokenURI.sol";
import {Ownable} from "cyphersuite/access/Ownable.sol";
import {Controllerable} from "cyphersuite/access/Controllerable.sol";

contract Machina is ERC721B("Machina", "MACHINA"), ERC721TokenURI, Ownable,
Controllerable {

    ///// Proxy Initializer /////
    bool public proxyIsInitialized;
    function proxyInitialize(address newOwner_) public {
        require(!proxyIsInitialized, "Proxy already initialized");
        proxyIsInitialized = true;

        // Hardcode
        owner = newOwner_; // Ownable.sol

        name = "Machina"; // ERC721B.sol
        symbol = "MACHINA"; // ERC721B.sol
        nextTokenId = startTokenId(); // ERC721B.sol
    }

    ///// Constructor (For Implementation Contract) /////
    constructor() {
        proxyInitialize(msg.sender);
    }

    ///// Controllerable Config /////
    modifier onlyMinter() {
        require(isController("Minter", msg.sender),
                "Controllerable: Not Minter!");
        _;
    }

    ///// ERC721B Overrides /////
    function startTokenId() public pure virtual override returns (uint256) {
        return 1;
    }

    ///// Ownable Functions /////
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }
    function ownerBurn(uint256[] calldata tokenIds_) external onlyOwner {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            _burn(tokenIds_[i], false);
        } while (++i < l); }
    }

    ///// Controllerable Functions /////
    function mintAsController(address to_, uint256 amount_) external onlyMinter {
        _mint(to_, amount_);
    }

    ///// Metadata Governance /////
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    ///// TokenURI /////
    function tokenURI(uint256 tokenId_) public virtual view override 
    returns (string memory) {
        require(ownerOf(tokenId_) != address(0), "Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_)));
    }
}