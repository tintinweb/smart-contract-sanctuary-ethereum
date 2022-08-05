// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "./token/ERC721Optimized.sol";

contract GOTM is ERC721Optimized {
    constructor(string memory baseURI_, MintConfig memory privateMintConfig_, MintConfig memory publicMintConfig_, address erc721FactoryAddress_, address proxyRegistryAddress_) ERC721Optimized(
        "GOATs of the Metaverse",
        "GOTM",
        baseURI_,
        privateMintConfig_,
        publicMintConfig_,
        erc721FactoryAddress_,
        proxyRegistryAddress_
    ) {}
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "../access/SharedOwnable.sol";
import "../interfaces/IERC721Optimized.sol";
import "../opensea/IERC721Factory.sol";
import "../opensea/ProxyRegistry.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Optimized is Context, SharedOwnable, IERC721, IERC721Metadata, IERC721Enumerable, IERC721Optimized {
    using Address for address;
    using Strings for uint256;

    struct AddressData {
        uint128 balance;  
        uint128 privateMintCount;
    }

    struct TokenData {
        address owner;
        uint96 owningStartTimestamp;
    }

    uint constant private MAX_TOTAL_SUPPLY = 10000;
    uint constant private MAX_TEAM_MINTS = 100;

    string private _name;
    string private _symbol;
    string private _baseURI;
    MintConfig private _privateMintConfig;
    mapping(uint64 => uint128) private _privateMintDiscountPerMintAmount;
    MintConfig private _publicMintConfig;
    mapping(uint64 => uint128) private _publicMintDiscountPerMintAmount;
    address private _erc721FactoryAddress;
    address private _proxyRegistryAddress;

    uint256 private _totalSupply;
    mapping(address => uint256) private _privateMintWhitelist;

    uint256 private _teamMintedCount;
    uint256 private _privateMintedCount;
    uint256 private _publicMintedCount;
    uint256 private _airdroppedToOwnersCount;
    uint256 private _raffledToOwnersCount;
    mapping(uint256 => uint256) private _raffleToOwnersHelper;

    mapping(address => AddressData) private _addresses;
    mapping(address => mapping(address => uint256)) private _operatorApprovals;
    mapping(uint256 => TokenData) private _tokens;
    mapping(uint256 => address) private _tokenApprovals;

    mapping(uint256 => bool) private _isTeamMintedToken;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, MintConfig memory privateMintConfig_, MintConfig memory publicMintConfig_, address erc721FactoryAddress_, address proxyRegistryAddress_) {
        require(bytes(name_).length > 0, "ERC721Optimized: name can't be empty");
        require(bytes(symbol_).length > 0, "ERC721Optimized: symbol can't be empty");
        require(bytes(baseURI_).length > 0, "ERC721Optimized: baseURI can't be empty");
        require(privateMintConfig_.maxMintAmountPerAddress <= privateMintConfig_.maxTotalMintAmount, "ERC721Optimized: maximum mint amount per address can't exceed the maximum total mint amount");
        require(privateMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(privateMintConfig_.discountPerMintAmountKeys.length == privateMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        require(publicMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(publicMintConfig_.discountPerMintAmountKeys.length == publicMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        if (erc721FactoryAddress_ != address(0))
            IERC721Factory(erc721FactoryAddress_).supportsFactoryInterface();
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());

        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _privateMintConfig = privateMintConfig_;
        for (uint256 index = 0; index < privateMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(privateMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _privateMintDiscountPerMintAmount[privateMintConfig_.discountPerMintAmountKeys[index]] = privateMintConfig_.discountPerMintAmountValues[index];
        }
        _publicMintConfig = publicMintConfig_;
        for (uint256 index = 0; index < publicMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(publicMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _publicMintDiscountPerMintAmount[publicMintConfig_.discountPerMintAmountKeys[index]] = publicMintConfig_.discountPerMintAmountValues[index];
        }
        _erc721FactoryAddress = erc721FactoryAddress_;
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    modifier onlyERC721Factory() {
        require(_erc721FactoryAddress == msg.sender, "ERC721Optimized: caller is not the erc 721 factory");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC721Enumerable).interfaceId || interfaceId == type(IERC721Optimized).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function privateMintConfig() external view returns (MintConfig memory) {
        return _privateMintConfig;
    }

    function publicMintConfig() external view returns (MintConfig memory) {
        return _publicMintConfig;
    }

    function erc721FactoryAddress() external view returns (address) {
        return _erc721FactoryAddress;
    }

    function proxyRegistryAddress() external view returns (address) {
        return _proxyRegistryAddress;
    }

    function setBaseURI(string calldata baseURI_) external onlySharedOwners {
        require(bytes(baseURI_).length > 0, "ERC721Optimized: baseURI can't be empty");
        _baseURI = baseURI_;
    }

    function setPrivateMintConfig(MintConfig calldata privateMintConfig_) external onlySharedOwners {
        require(privateMintConfig_.maxMintAmountPerAddress <= privateMintConfig_.maxTotalMintAmount, "ERC721Optimized: maximum mint amount per address can't exceed the maximum total mint amount");
        require(privateMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(privateMintConfig_.discountPerMintAmountKeys.length == privateMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        for (uint256 index = 0; index < _privateMintConfig.discountPerMintAmountKeys.length; index++)
            delete _privateMintDiscountPerMintAmount[_privateMintConfig.discountPerMintAmountKeys[index]];
        _privateMintConfig = privateMintConfig_;
        for (uint256 index = 0; index < privateMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(privateMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _privateMintDiscountPerMintAmount[privateMintConfig_.discountPerMintAmountKeys[index]] = privateMintConfig_.discountPerMintAmountValues[index];
        }
    }

    function setPublicMintConfig(MintConfig calldata publicMintConfig_) external onlySharedOwners {
        require(publicMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(publicMintConfig_.discountPerMintAmountKeys.length == publicMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        for (uint256 index = 0; index < _publicMintConfig.discountPerMintAmountKeys.length; index++)
            delete _publicMintDiscountPerMintAmount[_publicMintConfig.discountPerMintAmountKeys[index]];
        _publicMintConfig = publicMintConfig_;
        for (uint256 index = 0; index < publicMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(publicMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _publicMintDiscountPerMintAmount[publicMintConfig_.discountPerMintAmountKeys[index]] = publicMintConfig_.discountPerMintAmountValues[index];
        }
    }

    function setERC721FactoryAddress(address erc721FactoryAddress_) external onlySharedOwners {
        if (erc721FactoryAddress_ != address(0))
            IERC721Factory(erc721FactoryAddress_).supportsFactoryInterface();
        _erc721FactoryAddress = erc721FactoryAddress_;
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) external onlySharedOwners {
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalMinted() external view returns (uint256) {
        return _privateMintedCount + _publicMintedCount;
    }

    function isPrivateMintWhitelisted(address account) external view returns (bool) {
        return _privateMintWhitelist[account] > 0;
    }

    function updatePrivateMintWhitelisted(address[] calldata addresses, uint256[] calldata values) external onlySharedOwners {
        require(addresses.length == values.length, "ERC721Optimized: array mismatch");
        for (uint256 index = 0; index < addresses.length; index++)
            _privateMintWhitelist[addresses[index]] = values[index];
    }

    function teamMintedCount() external view returns (uint256) {
        return _teamMintedCount;
    }

    function privateMintedCount() external view returns (uint256) {
        return _privateMintedCount;
    }

    function publicMintedCount() external view returns (uint256) {
        return _publicMintedCount;
    }

    function airdroppedToOwnersCount() external view returns (uint256) {
        return _airdroppedToOwnersCount;
    }

    function raffledToOwnersCount() external view returns (uint256) {
        return _raffledToOwnersCount;
    }

    function isTeamMintedToken(uint256 tokenId) external view returns (bool) {
        require(tokenId < _totalSupply, "ERC721Optimized: Nonexistent tokenId operation");
        return _isTeamMintedToken[tokenId];
    }

    function withdraw(address payable recipient) external onlyOwner {
        (bool success, ) = recipient.call{ value: address(this).balance }("");
        require(success, "ERC721Optimized: Transfer failed.");
    }

    function addressData(address owner) external view returns (AddressData memory) {
        return _addresses[owner];
    }

    function tokenData(uint256 tokenId) external view returns (TokenData memory) {
        return _tokens[tokenId];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](_addresses[owner].balance);

        uint256 currentIndex;
        address currentOwner;
        address ownerAtIndex;
        for (uint256 tokenId = 0; tokenId < _totalSupply; tokenId++) {
            ownerAtIndex = _tokens[tokenId].owner;
            if (ownerAtIndex != address(0))
                currentOwner = ownerAtIndex;

            if (currentOwner == owner) {
                tokenIds[currentIndex++] = tokenId;
                if (currentIndex == tokenIds.length)
                    break;
            }
        }

        require(currentIndex == tokenIds.length, "ERC721Optimized: not all tokens found");
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract"));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId) {
        require(index < _addresses[owner].balance, "ERC721Optimized: Nonexistent index operation");
        
        uint256 currentIndex;
        address currentOwner;
        address ownerAtIndex;
        for (; tokenId < _totalSupply; tokenId++) {
            ownerAtIndex = _tokens[tokenId].owner;
            if (ownerAtIndex != address(0))
                currentOwner = ownerAtIndex;

            if (currentOwner == owner) {
                if (currentIndex == index)
                    return tokenId;

                currentIndex++;
            }
        }

        revert("ERC721Optimized: no token found");
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _totalSupply, "ERC721Optimized: Nonexistent index operation");
        return index;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = _addresses[owner].balance;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        owner = _tokens[tokenId].owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        address msgSender = _msgSender();
        _transfer(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(msgSender, from, to, tokenId, ""), "ERC721Optimized: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(_msgSender(), from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        address owner = _tokens[tokenId].owner;

        address msgSender = _msgSender();
        require(msgSender == owner || (_operatorApprovals[owner][msgSender] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner)) == msgSender)), "ERC721Optimized: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address operator) {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        operator = _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) external {
        address msgSender = _msgSender();
        require(msgSender != operator, "ERC721Optimized: approve to caller");
        _operatorApprovals[msgSender][operator] = _approved ? 1 : 0;

        emit ApprovalForAll(msgSender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner)) == operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        address msgSender = _msgSender();
        _transfer(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(msgSender, from, to, tokenId, data), "ERC721Optimized: transfer to non ERC721Receiver implementer");
    }

    function transferWithData(address to, uint256 tokenId) external {
        address msgSender = _msgSender();
        uint96 tokenOwningStartTimestamp = _tokens[tokenId].owningStartTimestamp;
        _transfer(msgSender, msgSender, to, tokenId);
        _tokens[tokenId].owningStartTimestamp = tokenOwningStartTimestamp;
    }

    function privateMint(uint64 quantity) external payable {
        require(block.timestamp >= _privateMintConfig.mintStartTimestamp, "ERC721Optimized: private mint has not yet started");
        require(block.timestamp < _privateMintConfig.mintEndTimestamp, "ERC721Optimized: private mint has ended");
        address msgSender = _msgSender();

        require(_privateMintWhitelist[msgSender] > 0, "ERC721Optimized: not whitelisted for the private mint");
        require(_privateMintedCount + _publicMintedCount + quantity <= _privateMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        require(_addresses[msgSender].privateMintCount + quantity <= _privateMintConfig.maxMintAmountPerAddress, "ERC721Optimized: exceeds mint maximum");
        uint128 discount = _privateMintDiscountPerMintAmount[quantity];
        uint256 discountedPrice = ((quantity * _privateMintConfig.pricePerMint) * (100 - discount)) / 100;
        require(msg.value >= discountedPrice, "ERC721Optimized: missing funds");
        _safeMint(msgSender, msgSender, quantity);
        _addresses[msgSender].privateMintCount += quantity;
        _privateMintedCount += quantity;
    }

    function publicMint(uint64 quantity) external payable {
        require(block.timestamp >= _publicMintConfig.mintStartTimestamp, "ERC721Optimized: public mint has not yet started");
        require(block.timestamp < _publicMintConfig.mintEndTimestamp, "ERC721Optimized: public mint has ended");
        address msgSender = _msgSender();

        require(_privateMintedCount + _publicMintedCount + quantity <= _publicMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        uint128 discount = _publicMintDiscountPerMintAmount[quantity];
        uint256 discountedPrice = ((quantity * _publicMintConfig.pricePerMint) * (100 - discount)) / 100;
        require(msg.value >= discountedPrice, "ERC721Optimized: missing funds");
        _safeMint(msgSender, msgSender, quantity);
        _publicMintedCount += quantity;
    }

    function publicMint(address to, uint64 quantity) external onlyERC721Factory {
        require(block.timestamp >= _publicMintConfig.mintStartTimestamp, "ERC721Optimized: public mint has not yet started");
        require(block.timestamp < _publicMintConfig.mintEndTimestamp, "ERC721Optimized: public mint has not yet started");
        
        require(_privateMintedCount + _publicMintedCount + quantity <= _publicMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        _safeMint(_msgSender(), to, quantity);
        _publicMintedCount += quantity;
    }

    function teamMint(address[] calldata addresses, uint128[] calldata quantities) external onlySharedOwners {
        require(quantities.length == addresses.length, "ERC721Optimized: array size mismatch");

        uint256 j;
        uint128 quantity;
        for (uint256 index = 0; index < addresses.length; index++) {
            quantity = quantities[index];
            for (j = 0; j < quantity; j++)
                _isTeamMintedToken[_totalSupply + j] = true;
            _safeMint(_msgSender(), addresses[index], quantity);
            _teamMintedCount += quantity;
        }

        require(_teamMintedCount <= MAX_TEAM_MINTS, "ERC721Optimized: exceeds maximum team mint count");
    }

    function airdropToOwners(uint256 airdropQuantity, uint256 startTokenId) external onlySharedOwners {
        uint256 _existingTotalSupply = _totalSupply;
        require(startTokenId + airdropQuantity <= _existingTotalSupply, "ERC721Optimized: not enough tokens");

        uint256 _airdroppedTokens = 0;
        for (uint256 tokenId = startTokenId; tokenId < _existingTotalSupply && _airdroppedTokens < airdropQuantity; tokenId++) {
            if (!_isTeamMintedToken[tokenId]) {
                _safeMint(_msgSender(), _tokens[tokenId].owner, 1);
                _airdroppedTokens++;
            }
        }

        require(_airdroppedTokens == airdropQuantity, "ERC721Optimized: didn't minted all tokens");
        _airdroppedToOwnersCount += _airdroppedTokens;
    }

    function resetRaffleToOwnersHelper() external onlySharedOwners {
        for (uint256 tokenId = 0; tokenId < _totalSupply; tokenId++)
            if (_raffleToOwnersHelper[tokenId] != 0)
                _raffleToOwnersHelper[tokenId] = 0;
    }

    function raffleToOwners(uint256 minimumOwningDuration, uint256 tokensToRaffle, uint256 maxIterations) external onlySharedOwners {
        address[] memory owners = new address[](tokensToRaffle);
        uint256 ownersFound = 0;
        uint256 tokensIterated = 0;
        uint256 iterations = 0;

        uint256 tokenId;
        TokenData memory token;
        while (ownersFound < tokensToRaffle && _totalSupply - tokensIterated > tokensToRaffle - ownersFound && iterations < maxIterations) {
            tokenId = _getRandomExistingTokenId(iterations++);
            if (_raffleToOwnersHelper[tokenId] == 0) {
                token = _tokens[tokenId];
                if (block.timestamp - token.owningStartTimestamp >= minimumOwningDuration)
                    owners[ownersFound++] = token.owner;
                tokensIterated++;
                _raffleToOwnersHelper[tokenId] = 1;
            }
        }

        require(ownersFound == tokensToRaffle, "ERC721Optimized: didn't found all owners");
        for (uint256 index = 0; index < ownersFound; index++)
            _safeMint(_msgSender(), owners[index], 1);

        _raffledToOwnersCount += tokensToRaffle;
    }

    function _safeMint(address operator, address to, uint128 quantity) internal {
        require(to != address(0), "ERC721Optimized: mint to the zero address");
        require(_totalSupply + quantity <= MAX_TOTAL_SUPPLY, "ERC721Optimized: mint exceeds max total supply");

        uint256 tokenId = _totalSupply;
        for (uint256 index = 0; index < quantity; index++) {
            _tokens[tokenId].owner = to;
            _tokens[tokenId].owningStartTimestamp = uint96(block.timestamp);

            emit Transfer(address(0), to, tokenId);
            require(_checkOnERC721Received(operator, address(0), to, tokenId++, ""), "ERC721Optimized: transfer to non ERC721Receiver implementer");
        }
        require(tokenId == _totalSupply + quantity, "ERC721Optimized: Reentrancy detected");

        _totalSupply = tokenId;
        _addresses[to].balance += quantity;
    }

    function _transfer(address operator, address from, address to, uint256 tokenId) private {
        require(from != address(0), "ERC721Optimized: transfer from the zero address");
        require(to != address(0), "ERC721Optimized: transfer to the zero address");
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        require(_tokens[tokenId].owner == from, "ERC721Optimized: transfer from incorrect owner");
        require(from == operator || _tokenApprovals[tokenId] == operator || (_operatorApprovals[from][operator] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(from)) == operator)), "ERC721Optimized: transfer caller is not owner nor approved");
        require(from != to, "ERC721Optimized: transfer to the same address");
        require(!_isTeamMintedToken[tokenId] || block.timestamp >= _publicMintConfig.mintStartTimestamp,  "ERC721Optimized: transfer of team minted token prior to public mint");

        _tokenApprovals[tokenId] = address(0);
        emit Approval(from, address(0), tokenId);

        _addresses[from].balance -= 1;
        _addresses[to].balance += 1;
        _tokens[tokenId].owner = to;
        _tokens[tokenId].owningStartTimestamp = uint96(block.timestamp);
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract())
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert("ERC721Optimized: transfer to non ERC721Receiver implementer");
                else
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else
            return true;
    }
    
    function _getRandomExistingTokenId(uint256 nonce) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(nonce + block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number + nonce)));
        return seed - ((seed / _totalSupply) * _totalSupply);
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.13;

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.13;

contract OwnableDelegateProxy {}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

interface IERC721Factory {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function canMint(uint256 _optionId) external view returns (bool);

    function tokenURI(uint256 _optionId) external view returns (string memory);

    function supportsFactoryInterface() external view returns (bool);

    function mint(uint256 _optionId, address _toAddress) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

interface IERC721Optimized {
    struct MintConfig {
        uint64 maxTotalMintAmount;
        uint64 maxMintAmountPerAddress;
        uint128 pricePerMint;
        uint256 mintStartTimestamp;
        uint256 mintEndTimestamp;
        uint64[] discountPerMintAmountKeys;
        uint128[] discountPerMintAmountValues;
    }

    function publicMintConfig() external view returns (MintConfig memory);

    function totalMinted() external view returns (uint256);

    function publicMint(address to, uint64 amount) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SharedOwnable is Ownable {
    address private _creator;
    mapping(address => bool) private _sharedOwners;

    event SharedOwnershipAdded(address indexed sharedOwner);
    event SharedOwnershipRemoved(address indexed sharedOwner);

    constructor() Ownable() {
        _creator = msg.sender;
        _setSharedOwner(msg.sender, true);
    }

    modifier onlyCreator() {
        require(_creator == msg.sender, "SharedOwnable: caller is not the creator");
        _;
    }

    modifier onlySharedOwners() {
        require(owner() == msg.sender || _sharedOwners[msg.sender], "SharedOwnable: caller is not a shared owner");
        _;
    }

    function getCreator() external view returns (address) {
        return _creator;
    }

    function isSharedOwner(address account) external view returns (bool) {
        return _sharedOwners[account];
    }

    function setSharedOwner(address account, bool sharedOwner) external onlyCreator {
        _setSharedOwner(account, sharedOwner);
    }

    function _setSharedOwner(address account, bool sharedOwner) private {
        _sharedOwners[account] = sharedOwner;
        if (sharedOwner)
            emit SharedOwnershipAdded(account);
        else
            emit SharedOwnershipRemoved(account);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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