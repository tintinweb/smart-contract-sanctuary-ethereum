// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HRF.sol";
import "./ERC/165/ERC165.sol";

/**
 * @title Happy Robot Friends
 */
contract HappyRobotFriends is HRF, ERC165 {
    receive() external payable {}
    fallback() external payable {}

    event Withdrawal(address operator, address receiver, uint256 value);

    mapping(address => bool) private _preMint;
    mapping(address => uint256) private _whitelist;
    mapping(address => uint256) _mintLimit;
    uint256 private _price;
    bool private _publicMintPaused;
    bool private _preMintPaused;
    bool private _heartTokenMintPaused;

    function _whitelistInit() internal virtual {
        _whitelist[0x9127446C3d69e3B0EBcfd004918FCa6351572f8F] = 2;
        _whitelist[0xe63eA0B43D66a0772ff40cAe9C4506775b2F3445] = 2;
        _whitelist[0x5C6AE017A1811AE67F6AbA6a07009D173CCCcdB7] = 2;
        _whitelist[0x74Dd06Cadb3AC92fb3Da3d25e20f4292A839Fe64] = 1;
        _whitelist[0xd384718162623cCeE4cA922903efEf10FACcd8Cb] = 2;
        _whitelist[0xFEc4213278555d692679C918423816fa99Bb74A8] = 2;
        _whitelist[0x9F198B286FF6890fD38C905495b99CE0d3424CE1] = 1;
        _whitelist[0x131aA683891C534828aE98c4f743ABa334769371] = 2;
        _whitelist[0xbc14EC25110281f0332430943b9A203C65a1B7e8] = 1;
        _whitelist[0xCD04Cc2000C915bdA0F74633D6cc6F65A16EaeB5] = 2;
        _whitelist[0x5735E58bd87EFD49cAD2263B53D79EAAe03AA387] = 1;
        _whitelist[0x5D851D59C9b6632ec1bbc51266eA1c2E52fCEe7c] = 1;
        _whitelist[0xdB756e49D6b9A9285c60583a955CfBE55128c9C2] = 3;
        _whitelist[0xAAACdFD69B7Ca3c1d9c61C78141EB7AC8f357FeE] = 2;
        _whitelist[0xc79a875725D523Fd1C1206cC1D395EEE2Ed168C0] = 2;
        _whitelist[0xF53218f4914D886201a1Ed4e790B952C46DeB8c2] = 2;
        _whitelist[0x949688921c0823aD8adB3442C62250a9b477b804] = 1;
        _whitelist[0x751EC858028F76bebC6e6d11195B6c8a6e00Da55] = 2;
        _whitelist[0xC0594E255e997f27d6FE647C83592ed4cCe6D949] = 2;
        _whitelist[0x74845057b93742daB1e2cB72776eAE0da01Be921] = 1;
        _whitelist[0x63F9e0c0565399700e5459C0CeB5c2CFFaB3c6b1] = 2;
        _whitelist[0xC0594E255e997f27d6FE647C83592ed4cCe6D949] = 2;
        _whitelist[0x74845057b93742daB1e2cB72776eAE0da01Be921] = 1;
        _whitelist[0x63F9e0c0565399700e5459C0CeB5c2CFFaB3c6b1] = 2;
        _whitelist[0xa5620316eC9747a105B41a6a2da57684B5EaaeA0] = 2;
        _whitelist[0x44f52941Be93FDF3462671C1aB2d94e1921edbf1] = 2;
        _whitelist[0xe9A20693dBf263b345474fe4B3b12818FFd08bBA] = 2;
        _whitelist[0x3e9D7dFa8F3AB275afF54499cbc0AA9DC1B7cD0B] = 2;
        _whitelist[0x2D80438A78f34593601086329f5b679721958660] = 2;
        _whitelist[0xAF1f91A49E9cf07BD3C6F83Fe3ce19726b968518] = 2;
        _whitelist[0x005fe151D9185a30A11B3Fc7233ca3b2cfee7EC5] = 1;
        _whitelist[0xDab557046a07a3ed0C0991F5021e29D6b8393704] = 2;
        _whitelist[0xbc94f9739fc7551023a3427e7d0ea652Ed29A6Bf] = 1;
        _whitelist[0x21A083Eae62b87D7cddA93BF34D1bB4d3c468545] = 1;
        _whitelist[0xccfE925789739b4fE832B76B1623aDd09C8dec36] = 2;
        _whitelist[0x6831aEE4258F1AeaaD6Df29874BD5e1A5e39Dfab] = 1;
    }

    constructor(address _contractOwner) HRF("Happy Robot Friends", "HRF") {
        _transferOwnership(_contractOwner);
        _whitelistInit();
        _price = 100000000000000000;
        _publicMintPaused = true;
        _preMintPaused = true;
        _heartTokenMintPaused = true;
        _mint(_contractOwner);
    }

    function addWhitelist(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _preMint[_accounts[i]] = true;
        }
    }

    function whitelisted(address _account) public view returns(bool) {
        return _preMint[_account];
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

    function publicMintPauseStatus() public view returns(bool) {
        return _publicMintPaused;
    }

    function preMintPause(bool _bool) public ownership {
        _preMintPaused = _bool;
    }

    function preMintPauseStatus() public view returns(bool) {
        return _preMintPaused;
    }

    function heartTokenMintPause(bool _bool) public ownership {
        _heartTokenMintPaused = _bool;
    }

    function heartTokenMintPauseStatus() public view returns(bool) {
        return _heartTokenMintPaused;
    }

    function preMint(uint256 _quantity) public payable {
        require(_preMint[msg.sender] == true, "HRF: caller not on the whitelist");
        require(_preMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_mintLimit[msg.sender] <= 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function mint(uint256 _quantity) public payable {
        require(_publicMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_mintLimit[msg.sender] <= 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function whitelistMint(uint256 _quantity) public {
        require(_heartTokenMintPaused != true, "HRF: minting is paused");
        require(_whitelist[msg.sender] >= _quantity, "HRF: not on whitelist");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function ownershipMint(address _to, uint256 _quantity) public ownership {
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

import "./ERC/721/ERC721.sol";
import "./ERC/721/extensions/ERC721Metadata.sol";
import "./ERC/721/receiver/ERC721Receiver.sol";
import "./ERC/173/ERC173.sol";
import "./utils/String.sol";

/**
 * @title HRF Implementation
 */
contract HRF is ERC721, ERC721Metadata, ERC173, String {
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

    function transferOwnership(address _newOwner) public virtual override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal virtual {
        address previousOwner = _ownership;
        _ownership = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    function owner() public view virtual override returns (address) {
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
        _baseLevel[_currentId] = false;
        _level[_tokenId] = _cid;
    }

    function resetLevel(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "HRF: Caller not owner");
        _baseLevel[_currentId] = true;
    }

    /**
     * @dev Metadata functions
     */

    function _mint(address _to) internal virtual {
        require(_currentId < 6667, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to the zero address");

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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function reveal() public ownership {
        require(_baseLock == true, "HRF: Reveal base not locked");
        _reveal = true;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
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
        require(_baseSet == true, "HRF: URI has not been set");
        require(_baseLock == false, "HRF: URI has been set");
        if (_baseLevel[_tokenId] == true) {
            if (_jsonExtension == true) {
                return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId), ".json"));
            } else {
                return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId)));
            }
        } else {
            return string(abi.encodePacked(_baseUri(), _level[_tokenId]));
        }
    }

    function _currentTokenId() internal virtual returns (uint256) {
        return _currentId;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return "ipfs://";
    }

    function revealBaseLocked() public virtual returns (bool) {
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

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev ERC721 functions
     */
    
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return _ownerBalance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        return _tokenOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data)  public virtual override {
        _transfer(_from, _to, _tokenId);
    
        _onERC721Received(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public virtual override {
        require(_tokenOwner[_tokenId] == msg.sender);
        _tokenApproval[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        require(msg.sender != _operator, "ERC721: cannot approve the owner");
        _operatorApproval[msg.sender][_operator] = _approved;
    
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return _tokenApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return _operatorApproval[_owner][_operator];
    }

    /**
     * @dev ERC721 internal transfer function
     */

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
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