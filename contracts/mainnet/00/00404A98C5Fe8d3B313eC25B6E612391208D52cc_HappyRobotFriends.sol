// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package.sol";

/**
 * @title Happy Robot Friends
 */
contract HappyRobotFriends is Package {
    receive() external payable {}
    fallback() external payable {}

    event Withdrawal(address operator, address receiver, uint256 value);

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _claimer;
    mapping(address => uint256) _mintLimit;
    mapping(address => uint256) _preMintLimit;

    uint256 private _price;

    bool private _publicMintPaused;
    bool private _preMintPaused;
    bool private _freeMintPaused;

    bool private _locked;

    modifier gate() {
        require(_locked == false, "HRF: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(address _contractOwner) Package("Happy Robot Friends", "HRF") {
        _transferOwnership(_contractOwner);
        _price = 100000000000000000;
        _publicMintPaused = true;
        _preMintPaused = true;
        _freeMintPaused = true;
        _locked == false;
    }

    function addClaimers(address[] memory _accounts, uint256 _quantity) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _claimer[_accounts[i]] = _quantity;
        }
    }

    function revokeClaimers(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _claimer[_accounts[i]] = 0;
        }
    }

    function claimable(address _account) public view returns (uint256) {
        return _claimer[_account];
    }

    function addWhitelist(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _whitelist[_accounts[i]] = true;
        }
    }

    function revokeWhitelist(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _whitelist[_accounts[i]] = false;
        }
    }

    function whitelisted(address _account) public view returns (bool) {
        return _whitelist[_account];
    }

    function mintPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 _value) public ownership {
        _price = _value;
    }

    function publicMintPause(bool _bool) public ownership {
        _publicMintPaused = _bool;
    }

    function publicMintPauseStatus() public view returns (bool) {
        return _publicMintPaused;
    }

    function preMintPause(bool _bool) public ownership {
        _preMintPaused = _bool;
    }

    function preMintPauseStatus() public view returns (bool) {
        return _preMintPaused;
    }

    function freeMintPause(bool _bool) public ownership {
        _freeMintPaused = _bool;
    }

    function freeMintPauseStatus() public view returns (bool) {
        return _freeMintPaused;
    }

    function publicMint(uint256 _quantity) public payable gate {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_publicMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_mintLimit[msg.sender] < 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function preMint(uint256 _quantity) public payable gate {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_whitelist[msg.sender] == true, "HRF: caller not on the whitelist");
        require(_preMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_preMintLimit[msg.sender] < 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _preMintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function freeMint() public gate {
        require(_claimer[msg.sender] + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_freeMintPaused != true, "HRF: minting is paused");
        require(_claimer[msg.sender] >= 1, "HRF: not a claimer or already claimed");
        uint256 _totalAmount = _claimer[msg.sender];
        for (uint256 i=0; i < _totalAmount; i++) {
            _claimer[msg.sender] -= 1;
            _mint(msg.sender);
        }
    }

    function ownershipMint(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "HRF: ether transfer failed");

        emit Withdrawal(msg.sender, _account, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC/721/ERC721.sol";
import "./ERC/721/extensions/ERC721Metadata.sol";
import "./ERC/721/receiver/ERC721Receiver.sol";
import "./ERC/173/ERC173.sol";
import "./ERC/165/ERC165.sol";
import "./utils/String.sol";

/**
 * @dev Happy Robot Friends package
 */
contract Package is ERC721, ERC721Metadata, ERC173, ERC165, String {
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownerBalance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;
    mapping(uint256 => bool) private _baseLevel;
    mapping(uint256 => string) private _level;

    string private _name;
    string private _symbol;
    string private _extendedBaseUri;

    uint256 private _currentId = 0;
    uint256 private _totalSupply = 0;

    address private _ownership;
    address private GameContract = address(0);

    bool private _reveal = false;
    bool private _baseSet = false;
    bool private _baseLock = false;
    bool _jsonExtension = false;

    /**
     * @dev Ownership functions
     */

    function transferOwnership(address _newOwner) public override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = _ownership;
        _ownership = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    function owner() public view override returns (address) {
        return _ownership;
    }

    /**
     * @dev Game functions
     */

    function setGameContract(address _gameContract) public ownership {
        GameContract = _gameContract;
    }

    function levelUp(uint256 _tokenId, string memory _cid) public {
        require(msg.sender == GameContract, "HRF: Caller not game");
        _baseLevel[_tokenId] = false;
        _level[_tokenId] = _cid;
    }

    function resetLevel(uint256 _tokenId) public {
        require(msg.sender == GameContract, "HRF: Caller not game");
        _baseLevel[_tokenId] = true;
    }

    /**
     * @dev Metadata functions
     */

    function _mint(address _to) internal {
        require(_currentId < 3333, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;
        _baseLevel[_currentId] = true;

        emit Transfer(address(0), _to, _currentId);
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function reveal() public ownership {
        require(_baseLock == true, "HRF: Reveal base not locked");
        _reveal = true;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId != 0, "HRF: Token ID out of range");
        require(_currentId >= _tokenId, "HRF: Token ID out of range");
        if (_reveal == true) {
            if (_baseLevel[_tokenId] == true) {
                if (_jsonExtension == true) {
                    return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId), ".json"));
                } else {
                    return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId)));
                }
            } else {
                return string(abi.encodePacked(_baseUri(), _level[_tokenId]));
            }
        } else {
            return string(abi.encodePacked(_baseUri(), "bafybeifupt34zaycketp6khwmwusssksupv245g43xl3yriumgeqbjo7n4/prereveal.json"));
        }
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        require(_baseSet == true, "HRF: CID has not been set");
        require(_baseLock == false, "HRF: URI has been set");
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId)));
        }
    }

    function _baseUri() internal pure returns (string memory) {
        return "ipfs://";
    }

    function revealBaseLocked() public view returns (bool) {
        return _baseLock;
    }

    function lockRevealBase(bool _lockStatus) public ownership {
        require(_reveal == false, "HRF: Reveal has already occured");
        require(_baseSet == true, "HRF: Reveal base not set");
        _baseLock = _lockStatus;
    }

    function setRevealBase(string memory _cid, bool _isExtension) public ownership {
        require(_baseLock == false, "HRF: Already revealed");
        _extendedBaseUri = _cid;
        _jsonExtension = _isExtension;
        _baseSet = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev ERC721 functions
     */
    
    function balanceOf(address _owner) public view override returns (uint256) {
        return _ownerBalance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return _tokenOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        _transfer(_from, _to, _tokenId);
    
        _onERC721Received(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public override {
        require(_tokenOwner[_tokenId] == msg.sender);
        _tokenApproval[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "ERC721: cannot approve the owner");
        _operatorApproval[msg.sender][_operator] = _approved;
    
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return _tokenApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return _operatorApproval[_owner][_operator];
    }

    /**
     * @dev ERC721 internal transfer function
     */

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: from address is not owner of token");
        require(_tokenOwner[_tokenId] == msg.sender || _tokenApproval[_tokenId] == msg.sender || _operatorApproval[_from][msg.sender] == true, "ERC721: unauthorized transfer");
        require(_to != address(0), "ERC721: cannot transfer to the zero address");
        _ownerBalance[_from] -= 1;
        _tokenOwner[_tokenId] = _to;
        _tokenApproval[_tokenId] = address(0);
        _ownerBalance[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev ERC721Received private function
     */

    function _onERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            try ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != ERC721Receiver.onERC721Received.selector) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }
    }

    /**
     * @dev ERC165 function
     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(ERC173).interfaceId ||
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC721Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 Interface
 *
 * @dev Interface of the ERC721 standard according to the EIP
 */
interface ERC721 {
    /**
     * @dev ERC721 standard events
     */

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev ERC721 standard functions
     */

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata Interface
 *
 * @dev Interface of the ERC721Metadata according to the EIP
 */
interface ERC721Metadata {
    /**
     * @dev ERC721 token metadata functions
     */

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Receiver Interface
 *
 * @dev Interface of the ERC721Receiver according to the EIP
 */
interface ERC721Receiver {
    /**
     * @dev ERC721Receiver standard functions
     */

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC173 Interface
 *
 * @dev Interface of the ERC173 standard according to the EIP
 */
interface ERC173 {
    /**
     * @dev ERC173 standard events
     */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ERC173 standard functions
     */

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 Interface
 *
 * @dev Interface of the ERC165 standard according to the EIP
 */
interface ERC165 {
    /**
     * @dev ERC165 standard functions
     */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract String {
    /**
     * @dev Converts integer to string
     */

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
}