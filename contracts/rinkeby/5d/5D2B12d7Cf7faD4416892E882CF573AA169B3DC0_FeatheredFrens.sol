// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package.sol";

/**
 * @title Feathered Frens
 */
contract FeatheredFrens is Package {
    receive() external payable {}
    fallback() external payable {}

    event Withdraw(address operator, address receiver, uint256 value);

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) _mintLimit;

    uint256 private _limit;

    bool private _mintPaused;
    bool private _freeForAllPaused;
    bool private _locked;

    modifier gate() {
        require(_locked == false, "FF: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(address _contractOwner, bytes32 _merkleRoot) Package("Feathered Frens", "FF") {
        _transferOwnership(_contractOwner);
        _mintPaused = true;
        _freeForAllPaused = true;
        _locked == false;
        setMintLimit(10);
        setMerkleRoot(_merkleRoot);
    }

    function mintPause(bool _bool) public ownership {
        _mintPaused = _bool;
    }

    function mintPauseStatus() public view returns (bool) {
        return _mintPaused;
    }

    function freeForAllPause(bool _bool) public ownership {
        _freeForAllPaused = _bool;
    }

    function freeForAllPauseStatus() public view returns (bool) {
        return _freeForAllPaused;
    }

    function setMintLimit(uint256 _amount) public ownership {
        _limit = _amount;
    }

    function mintLimit() public view returns (uint256) {
        return _limit;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public ownership {
        _setMerkleRoot(_merkleRoot);
    }

    function totalMinted(address _account) public view returns (uint256) {
        return _mintLimit[_account];
    }

    function freeForAll(address _to, uint256 _quantity) public gate {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        require(_quantity <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_quantity + _mintLimit[_to] <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_freeForAllPaused != true, "FF: minting is paused");
        _mintLimit[_to] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function mint(address _to, bytes32[] calldata _merkleProof, uint256 _quantity) public gate {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        require(_quantity <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_quantity + _mintLimit[_to] <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_mintPaused != true, "FF: minting is paused");
        _mintLimit[_to] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _whitelistMint(_to, _merkleProof, merkleRoot());
        }
    }

    function airdropBatch(address[] memory _to) public ownership {
        require(_to.length + totalSupply() <= 5555, "FF: maximum tokens minted");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i]);
        }
    }

    function airdrop(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "FF: ether transfer failed");

        emit Withdraw(msg.sender, _account, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC/721/ERC721.sol";
import "./ERC/721/extensions/ERC721Metadata.sol";
import "./ERC/721/receiver/ERC721Receiver.sol";
import "./ERC/173/ERC173.sol";
import "./ERC/165/ERC165.sol";
import "./library/utils.sol";

/**
 * @dev Feathered Frens package
 */
contract Package is ERC721, ERC721Metadata, ERC173, ERC165 {
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownerBalance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;

    bool private _reveal = false;
    bool private _baseSet = false;
    bool private _baseLock = false;
    bool _jsonExtension = false;

    string private _name;
    string private _symbol;
    string private _extendedBaseUri;

    uint256 private _currentId = 0;
    uint256 private _totalSupply = 0;

    address private _ownership;

    bytes32 private root;

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
    
    function _setMerkleRoot(bytes32 _root) internal {
        root = _root;
    }
    
    function merkleRoot() internal view returns (bytes32) {
        return root;
    }

    function _whitelistMint(address _to, bytes32[] calldata _merkleProof, bytes32 _merkleRoot) internal {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(utils.verify(_merkleProof, _merkleRoot, leaf), "FF: invalid merkle proof.");
        require(_currentId < 5555, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;

        emit Transfer(address(0), _to, _currentId);
    }

    function _mint(address _to) internal {
        require(_currentId < 5555, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;

        emit Transfer(address(0), _to, _currentId);
    }

    function reveal() public ownership {
        require(_baseLock == true, "FF: reveal base not locked");
        _reveal = true;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId != 0, "FF: token ID out of range");
        require(_currentId >= _tokenId, "FF: token ID out of range");
        if (_reveal == true) {
            if (_jsonExtension == true) {
                return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId), ".json"));
            } else {
                return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId)));
            }
        } else {
            return string(abi.encodePacked(_ipfs(), "bafybeidvzxfejqzlftewxphrrqvee3r6sxf7mf6etdajcoawpz4sf5hve4/prereveal.json"));
        }
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        require(_baseSet == true, "FF: CID has not been set");
        require(_baseLock == false, "FF: URI has been set");
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId)));
        }
    }

    function _ipfs() internal pure returns (string memory) {
        return "ipfs://";
    }

    function revealBaseLocked() public view returns (bool) {
        return _baseLock;
    }

    function lockRevealBase(bool _lockStatus) public ownership {
        require(_reveal == false, "FF: reveal has already occured");
        require(_baseSet == true, "FF: reveal base not set");
        _baseLock = _lockStatus;
    }

    function setRevealBase(string memory _cid, bool _isExtension) public ownership {
        require(_baseLock == false, "FF: already revealed");
        _extendedBaseUri = _cid;
        _jsonExtension = _isExtension;
        _baseSet = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
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

    function supportsInterface(bytes4 interfaceId) public pure override(ERC165) returns (bool) {
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
 * @dev Interface of the ERC721 standard
 */
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

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
 * @dev Interface of the ERC721Metadata
 */
interface ERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC721Receiver
 */
interface ERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC173 standard
 */
interface ERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard
 */
interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library utils {

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
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

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}