// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165} from './IERC165.sol';

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override 
        returns (bool) 
    {
        return interfaceId == 0x01ffc9a7;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from './IERC721.sol';
import {ERC165} from './ERC165.sol';
import {Ownable} from './Ownable.sol';
import {IERC721Receiver} from './IERC721Receiver.sol';

abstract contract ERC721 is IERC721, ERC165, Ownable {
    // ===================== Storage Variables =====================

    string private _name;

    string private _symbol;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) internal _tokenApprovals;

    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    mapping(uint256 => uint256) internal _ownedTokensIndex;  

    // =============================================================

    // ======================== Constructor ========================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // =============================================================

    // ========================== ERC165 =========================== 

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC165) 
        returns (bool) 
    {
        return 
            interfaceId == 0x80ac58cd || 
            super.supportsInterface(interfaceId);
    }

    // =============================================================

    // ======================= Read functions ======================

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0))
            revert InvalidInput();

        return _balances[owner];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert InvalidInput();
        }
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert InvalidInput();
        }
        
        return owner;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory);

    function _baseURI() internal view virtual returns (string memory);

    // =============================================================

    // ===================== Approve functions =====================

    function getApproved(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (address) 
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
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

    function _isApprovedOrOwner(
        address spender, 
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (
            spender == owner || 
            isApprovedForAll(owner, spender) || 
            getApproved(tokenId) == spender
        );
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert InvalidInput();
        } 
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerIsNotOwner();
        }
    
        _approve(to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator)
            revert InvalidInput();
        
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // =============================================================

    // ===================== Mint function =========================

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        if (_exists(tokenId)) {
            revert TokenExists();
        }
    
        _beforeTokenTransfer(address(0), to, tokenId);

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // =============================================================

    // ===================== Burn function =========================

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        _balances[owner]--;
        
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // =============================================================

    // =================== Transfer functions =======================

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf(tokenId) != from) {
            revert InvalidInput();
        }
            
        if (to == address(0)) {
            revert ZeroAddress();
        }
        
        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from]--;
            _balances[to]++;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerIsNotOwner();
        }
            
        _transferFrom(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transferFrom(from, to, tokenId);

        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ToNonERC721ReceiverImplementer();
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerIsNotOwner();
        }
            
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // =============================================================

    // ================== Introspection functions ==================

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ToNonERC721ReceiverImplementer();
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

    // =============================================================

    // ==================== Enumerable functions ===================

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (from == address(0)) {
            _addTokenToOwnerEnumeration(to, tokenId);
        } else if (to == address(0)) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    // =============================================================
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract ErrorMessage {
    error Declined();

    error TokenExists();

    error ToNonERC721ReceiverImplementer();

    error InvalidInput();

    error CallerIsNotOwner();

    error ZeroAddress();

    error Paused();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721 {
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
        bool indexed approved
    );

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

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Context} from './Context.sol';
import {ErrorMessage} from './ErrorMessage.sol';

abstract contract Ownable is ErrorMessage, Context {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        if (contractOwner() != _msgSender()) {
            revert CallerIsNotOwner();
        }
    }

    function contractOwner() public view returns (address) {
        return _owner;
    } 

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferOwnership(address newOwner) external onlyOwner {   
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }       
        _transferOwnership(newOwner);
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from './Utils.sol';
import {ERC721} from './ERC721.sol';

/// @title Sandpock Pass
/// @author 0x-ichi.eth

contract SandpockPass is ERC721 {
    using Utils for *;

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    // ===================== Storage Variables =====================

    uint256 public constant MAX_SUPPLY = 3000;
    uint256 private _currentIndex;
    uint private devMintAmount;

    bool private _mintPaused = true;
    bool private _burnPaused; 

    string private baseTokenURI;
    string private URISuffix;

    address private constant sandpockCreator = 0xdC71193655C952D53E3119D3BDECD36447e5D459;

    mapping(address => bool) private _refuseMint;
  
    // ======================== Constructor ========================

    constructor(
        string memory _baseTokenURI, 
        string memory _URISuffix,
        uint256 _devMintAmount
    ) ERC721("Sandpock Pass", "SP") {
        baseTokenURI = _baseTokenURI;
        URISuffix = _URISuffix;
        devMintAmount = _devMintAmount;

        devMint(sandpockCreator, _devMintAmount);
        _currentIndex = _devMintAmount + 1;
    }

    // =============================================================

    // ======================== Modifier ===========================

    modifier callerIsUser() {
        if (_msgSender() != tx.origin) {
            revert Declined();
        }
        _;
    }

    modifier isMintPaused() {
        if (_mintPaused) {
            revert Paused();
        }
        _;
    }

    modifier isBurnPaused() {
        if (_burnPaused) {
            revert Paused();
        }
        _;
    }

    // =============================================================

    // ======================= View Function =======================

    function mintPaused() external view returns (bool) {
        return _mintPaused;
    }

    function burnPaused() external view returns (bool) {
        return _burnPaused;
    }

    function isMinted(address account) external view returns (bool) {
        return _refuseMint[account];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) 
        external 
        view 
        override 
        returns (string memory) 
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return 
            bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), URISuffix)) 
            : "";                                                               
    }               

    function totalSupply() public view returns (uint256) {
        unchecked { 
            return _currentIndex - 1; 
        }
    }

    function tokensOfOwner(address owner) external view returns (uint[] memory) {
        uint length = ERC721.balanceOf(owner);
        uint[] memory tokensList = new uint[](length); 

        for (uint i; i < length;) {
            tokensList[i] = _ownedTokens[owner][i];                       
            unchecked {
                ++i;
            }
        }
        return tokensList;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) 
        external 
        view 
        returns (uint256) 
    {   
        if (index >= ERC721.balanceOf(owner)) {
            revert InvalidInput();
        }
        return _ownedTokens[owner][index];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (tokenId == 0) {
            revert InvalidInput(); 
        }

        address owner = _ownerOf(tokenId);
        if (tokenId >= 1 && tokenId <= devMintAmount && owner == address(0)) {
            return sandpockCreator;
        } else if (owner == address(0)) {
            revert InvalidInput();
        }
        return owner;
    }

    // =============================================================

    // ====================== Write Function =======================

    function burn(uint tokenId) external isBurnPaused {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerIsNotOwner();
        }

        _burn(tokenId);
    }

    function claim() external callerIsUser isMintPaused {
        if (totalSupply() + 1 > MAX_SUPPLY) {
            revert Declined();
        }
        
        if (_refuseMint[_msgSender()]) {
            revert Declined();
        }

        _refuseMint[_msgSender()] = true;

        _mint(_msgSender(), _currentIndex);
        _currentIndex++;
    }

    // =============================================================

    // ==================== onlyOwner Function =====================

    function devMint(address creator, uint256 amount) internal {
        _balances[creator] = amount;
        emit ConsecutiveTransfer(1, amount, address(0), creator);  
    }
    
    function setMintPause() external onlyOwner {
        _mintPaused = !_mintPaused;
    }

    function setBurnPause() external onlyOwner {
        _burnPaused = !_burnPaused;
    }

    function setTokenURI(string calldata _baseTokenURI) external onlyOwner {
        if (bytes(_baseTokenURI).length == 0) {
            revert InvalidInput();
        }
        baseTokenURI = _baseTokenURI;
    }

    function setURISuffix(string calldata _URISuffix) external onlyOwner {
        URISuffix = _URISuffix;
    }

    // =============================================================
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}