// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./packages/Bundle.sol";

/**
 * @title The Happy Chemical Club
 */
contract TheHappyChemicalClub is Bundle {
    receive() external payable {}
    fallback() external payable {}

    event Withdraw(address operator, address receiver, uint256 value);

    mapping(address => uint256) private _mintLimit;

    uint256 private _limit;
    uint256 private _price;
    uint256 private _freeTokensLimit;

    bool private _locked;
    bool private _mintPause;

    constructor(uint256 _freeTokens) {
        _limit = 5;
        _price = 10000000000000000;
        _locked = false;
        _mintPause = true;
        _freeTokensLimit = _freeTokens;
    }

    modifier gate() {
        require(_locked == false, "TheHappyChemicalClub: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    function mintPrice(uint256 _quantity) public view returns (uint256) {
        if (_currentTokenId() < _freeTokensLimit) {
            return 0;
        } else {
            return (_price * _quantity);
        }
    }

    function setPrice(uint256 _value) public ownership {
        _price = _value;
    }

    function unpause() public ownership {
        _mintPause = false;
    }

    function pause() public ownership {
        _mintPause = true;
    }

    function paused() public view returns (bool) {
        return _mintPause;
    }

    function setRevealURI(string memory _cid, bool _isExtension) public ownership {
        _setRevealURI(_cid, _isExtension);
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        return _checkURI(_tokenId);
    }

    function reveal() public ownership {
        _reveal();
    }

    function setMintLimit(uint256 _amount) public ownership {
        _limit = _amount;
    }

    function mintLimit() public view returns (uint256) {
        if (_currentTokenId() < _freeTokensLimit) {
            return 1;
        } else {
            return _limit;
        }
    }

    function mint(uint256 _quantity) public payable gate {
        require(msg.value >= mintPrice(_quantity), "TheHappyChemicalClub: not enough funds provided");
        require(_quantity + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        require(_quantity <= mintLimit(), "TheHappyChemicalClub: tokens exceed mint limit");
        require(_quantity + _mintLimit[msg.sender] <= mintLimit(), "TheHappyChemicalClub: tokens exceed mint limit");
        require(_mintPause != true, "TheHappyChemicalClub: minting is paused");
        _mintLimit[msg.sender] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _mint(msg.sender);
        }
    }

    function airdropBatch(address[] memory _to) public ownership {
        require(_to.length + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i]);
        }
    }

    function airdrop(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "TheHappyChemicalClub: ether transfer failed");

        emit Withdraw(msg.sender, _account, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../erc/165/ERC165.sol";
import "./Package_ERC173.sol";
import "./Package_ERC721Metadata.sol";

/**
 * @dev Supports interface bundle
 */
contract Bundle is Package_ERC721Metadata, Package_ERC173, ERC165 {
    constructor() Package_ERC721Metadata("The Happy Chemical Club", "THC", "bafybeif42ii3tgqjjou6ozzs6zc6kdj6ihybijvvnzznpzda7i5aulhjgy/prereveal.json") Package_ERC173(msg.sender) {}

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
 * @title ERC165 standard
 */
interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../erc/173/ERC173.sol";

/**
 * @dev Implementation of the ERC173
 */
contract Package_ERC173 is ERC173 {
    address private _owner;

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    constructor(address owner_) {
        _transferOwnership(owner_);
    }


    function owner() public view override returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = _owner;
        _owner = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package_ERC721.sol";
import "../erc/721/extensions/ERC721Metadata.sol";
import "../library/utils.sol";

/**
 * @dev Implementation of ERC721Metadata
 */
contract Package_ERC721Metadata is Package_ERC721, ERC721Metadata {
    mapping(uint256 => string) private _tokenCid;
    mapping(uint256 => bool) private _overrideCid;

    string private _metadata;
    string private _contractName;
    string private _contractSymbol;
    string private _fallbackCid;

    bool private _isRevealed;
    bool private _setURI;
    bool private _jsonExtension;

    constructor(string memory name_, string memory symbol_, string memory fallbackCid_) {
        _contractName = name_;
        _contractSymbol = symbol_;
        _fallbackCid = fallbackCid_;
        _isRevealed = false;
        _setURI = false;
    }

    function name() public view override returns (string memory) {
        return _contractName;
    }

    function symbol() public view override returns (string memory) {
        return _contractSymbol;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId == 0 || _tokenId > _currentTokenId()) {
            return "Token ID out of range";
        } else if (_overrideCid[_tokenId] == true) {
            return string(abi.encodePacked(_ipfs(), _tokenCid[_tokenId]));
        } else {
            if (_isRevealed == true) {
                return _revealURI(_tokenId);
            } else {
                return string(abi.encodePacked(_ipfs(), _fallbackCid));
            }
        }
    }

    function _revealURI(uint256 _tokenId) internal view returns (string memory) {
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_ipfs(), _metadata, "/", utils.toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_ipfs(), _metadata, "/", utils.toString(_tokenId)));
        }
    }

    function _ipfs() internal pure returns (string memory) {
        return "ipfs://";
    }

    function _overrideTokenURI(uint256 _tokenId, string memory _cid) internal {
        _tokenCid[_tokenId] = _cid;
        _overrideCid[_tokenId] = true;
    }

    function _setRevealURI(string memory _cid, bool _isExtension) internal {
        require(_isRevealed == false, "ERC721: reveal has already occured");
        _metadata = _cid;
        _jsonExtension = _isExtension;
        _setURI = true;
    }

    function _checkURI(uint256 _tokenId) internal view returns (string memory) {
        if (_tokenId == 0 || _tokenId > _currentTokenId()) {
            return "Token ID out of range";
        } else if (_revealed() == true) {
            return "Tokens have been revealed";
        } else {
            return _revealURI(_tokenId);
        }
    }

    function _reveal() internal {
        require(_setURI == true, "ERC721: reveal URI not set");

        _isRevealed = true;
    }

    function _revealed() internal view returns (bool) {
        return _isRevealed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC173 standard
 */
interface ERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../erc/721/ERC721.sol";
import "../erc/721/receiver/ERC721Receiver.sol";
import "../library/utils.sol";

/**
 * @dev Implementation of ERC721
 */
contract Package_ERC721 is ERC721 {
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownerBalance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;

    uint256 private _currentId = 0;
    uint256 private _totalSupply = 0;

    function _mint(address _to) internal {
        require(_to != address(0), "ERC721: cannot mint to the zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;

        emit Transfer(address(0), _to, _currentId);
    }

    function _currentTokenId() internal view returns (uint256) {
        return _currentId;
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
        assembly {size := extcodesize(_to)}
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata standard
 */
interface ERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 standard
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
 * @title ERC721Receiver standard
 */
interface ERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}