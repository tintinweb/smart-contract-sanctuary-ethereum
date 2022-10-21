//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./adventurer/PublicSale.sol";
import "./adventurer/PreSale.sol";
import "./adventurer/Reveal.sol";
import "./adventurer/WhiteList.sol";
import "./adventurer/Claim.sol";
import "./adventurer/Timelocked.sol";


/// @title AdventurersOfEther.sol
/// @notice Adventurers of ether is an NFT project based on the the ERC721 standard, 
///         and it incorperates multiple features and phases like:
/// @notice - Whitelist, PreSale, PublicSale and Reveal.
/// @notice - Claim feature.
/// @notice - And mint & lock feature.

contract AdventurersOfEther is PublicSale, WhiteList, PreSale, Reveal, Claim, Timelocked {
    
    constructor(string memory __contractURI, address payable _royalty, uint96 _feePercentInBIPS, uint256 _tierTwoPrice) {
        _contractURI = __contractURI;
        tierTwoPrice = _tierTwoPrice; 
        _setDefaultRoyalty(_royalty, _feePercentInBIPS);
        mintAndTimelockActive = true;
        _tierOneUnlockTime = block.timestamp + 4 weeks;
        _tierTwoUnlockTime = block.timestamp + 2 weeks;
    }

    /// @notice Mint a batch of nfts to multiple addresses.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _to Array of addresses to receive the nfts.
    /// @param _amount Array of amounts correlating with the _to addresses.
    /// @return oldIndex The start index.
    /// @return newIndex The last index.
    function mintBatch(address[] memory _to, uint256[] memory _amount)
        external 
        onlyOwner 
        returns (uint256 oldIndex, uint256 newIndex)
    {
        return _mintBatch(_to, _amount);
    }

    /// @notice Used to burn multiple nft´s in one transaction.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _tokenIds An array of tokenIds to burn.
    function burn(uint256[] calldata _tokenIds) external onlyOwner {
        _burn(_tokenIds);
    }

    /// @notice Used to set a new treasury address.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _treasury The contract address of the treasury contract.
    function setTreasury(ITreasury _treasury) external onlyOwner {
        treasury = _treasury;

        emit TreasurySet(address(treasury));
    }

    /// @notice poll payment to treasury contract.
    function transferToTreasury() external {
        if(payable(treasury) == address(0)) revert NoZeroAddress();
        treasury.primarySale{value: address(this).balance}();
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";

/**
 * @notice Public sale stage of Adventurers Token workflow
 */
abstract contract PublicSale is ERC721 {

    /// @notice PublicSaleConfig struct.
    /// @param price The PublicSale price.
    /// @param tokensPerTransaction The amount of tokens per tx.
    struct PublicSaleConfig {
        uint128 price;
        uint32 tokensPerTransaction;
    }

    /// @notice Returns the publicSaleConfig.
    PublicSaleConfig public publicSaleConfig = PublicSaleConfig({
        price: 0.145 ether,
        tokensPerTransaction: 0 // 10 + extra 1 for <
    });

    /// @notice Used to mint in the public mint phase.
    /// @param _count The amount of tokens to mint.
    function mintPublic(uint256 _count) external payable returns (uint256 oldIndex, uint256 newIndex) {
        PublicSaleConfig memory _cfg = publicSaleConfig;
        require(_cfg.tokensPerTransaction > 0, "publicsale: disabled");
        require(msg.value == _cfg.price * _count, "publicsale: payment amount");
        require(_count < _cfg.tokensPerTransaction, "publicsale: invalid count");
        
        return _mint(msg.sender, _count);
    }

    /// @notice Used to adjust the publicsale config values.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _price The publicSale mint price.
    /// @param _tokensPerTransaction The amount of tokens allowed per tx.
    function setPublicSaleConfig(uint128 _price, uint32 _tokensPerTransaction) external onlyOwner {
        uint32 _perTx = _tokensPerTransaction += 1;

        publicSaleConfig = PublicSaleConfig({
            price: _price,
            tokensPerTransaction: _perTx
        });
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @notice Presale (Crystal exchange) stage of Adventurers Token workflow
 */
abstract contract PreSale is ERC721 {
    using ERC165Checker for address;

    string constant internal invalidPayment = "presale: invalid payment amount";
    string constant internal invalidCount = "presale: invalid count";
    string constant internal invalid1155 = "presale: 0 or valid IERC1155";

    
    /// @notice PreSaleConfig struct.
    /// @param price The PreSale price.
    /// @param tokensPerCrystal The amount of tokens per crystal.
    struct PresaleConfig {
        uint128 price;
        uint32 tokensPerCrystal;
    }

    /// @notice Address to the crystal smart contract. 
    address public crystal;

    /// @notice Returns the preSaleConfig.
    PresaleConfig public presaleConfig = PresaleConfig({
        price: 0.095 ether,
        tokensPerCrystal: 4 // 3 + extra 1 for <
    });

    modifier cost(uint _count) {
        PresaleConfig memory _cfg = presaleConfig;
        if (msg.value != _cfg.price * _count) revert ErrorMessage(invalidPayment);
        _;
    }

    /// @dev Emittet if the presale is disabled.
    error PresaleDisabled();

    /// @dev Emitted with a message.
    /// @param message The error message.
    error ErrorMessage(string message);


    event PreSaleConfigSet(
        uint128 indexed price,
        uint32 indexed tokensPerCrystal
    );

    event CrystalSet(address indexed value);

    /// @notice Used by the crystal holders to mint from the presale.
    /// @dev Transfers the crytstal nft from the msg.sender to this contract.
    /// @param _count The amount of tokens to mint. 
    /// @param _id The tokenId of the crystal held by the msg.sender.
    function mintCrystalHolders(uint _count, uint _id) 
        external 
        payable 
        cost(_count) 
        returns (uint oldIndex, uint newIndex) 
    {
        if(crystal == address(0)) revert PresaleDisabled();
        PresaleConfig memory _cfg = presaleConfig;
        if (_count <= 0 && _count > _cfg.tokensPerCrystal) revert ErrorMessage(invalidCount);

        IERC1155(crystal).safeTransferFrom(msg.sender, address(this), _id, 1, "");
        
        return _mint(msg.sender, _count);
    } 
    
    /// @notice Used to adjust the presale config values.
    /// @dev Restricted with onlyOwner modifier. 
    /// @param _price The presale mint price.
    /// @param _tokensPerCrystal The tokens required per crystal.
    function setPresaleConfig(uint128 _price, uint32 _tokensPerCrystal) external onlyOwner {
        presaleConfig = PresaleConfig({
            price: _price,
            tokensPerCrystal: _tokensPerCrystal + 1
        });
        emit PreSaleConfigSet(_price, _tokensPerCrystal +1);
    }

    /// @notice Used to set the Crystal contract address.
    /// @dev Restricted to onlyOwner modifier.
    /// @param _value The Crystal contract address
    function setCrystal(address _value) external onlyOwner {
        require(_value == address(0) 
            || _value.supportsInterface(type(IERC1155).interfaceId),
            invalid1155);

        crystal = _value;
        
        if (_value != address(0)) {
            IERC1155(_value).setApprovalForAll(owner(), true); // we want to regift crystals
        }
        emit CrystalSet(_value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice EIP-721 reveal logic
 */
abstract contract Reveal is ERC721 {
    struct RevealGroup {
        uint64 startIndex;
        uint64 lastIndex;
    }

    /* state */
    uint[] private groupHashes;
    RevealGroup[] public revealGroups;
    string public unrevealedBaseUri = "";

    function revealHash(uint _tokenIndex) public view returns (uint) {
        for (uint _groupIndex = 0; _groupIndex < revealGroups.length; _groupIndex++) {
            RevealGroup memory _revealGroup = revealGroups[_groupIndex];
            if (_tokenIndex > _revealGroup.startIndex && _tokenIndex < _revealGroup.lastIndex) {
                return groupHashes[_groupIndex];
            }
        }
        return 0;
    }

    /**
     * @dev IERC721Metadata Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint _tokenId) external virtual override(IERC721Metadata) view returns (string memory) {
        require(exists(_tokenId), "erc721: nonexistent token");
        uint _groupHash = revealHash(_tokenId);
        if (_groupHash > 0) {
            return string(abi.encodePacked(
                _groupURI(_groupHash),
                Strings.toString(_tokenId),
                ".json"
            ));
        }
        return string(abi.encodePacked(
            unrevealedBaseUri,
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    function _groupURI(uint _groupId) internal pure returns (string memory) {
        string memory _uri = "ipfs://f01701220";
        bytes32 value = bytes32(_groupId);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            bytes1 ix1 = value[i] >> 4;
            str[i*2] = alphabet[uint8(ix1)];
            bytes1 ix2 = value[i] & 0x0f;
            str[1+i*2] = alphabet[uint8(ix2)];
        }
        return string(abi.encodePacked(_uri, string(str), "/"));
    }

    function setRevealHash(uint _groupIndex, uint _revealHash) external onlyOwner {
        groupHashes[_groupIndex] = _revealHash;
    }

    function setUnrevealedBaseUri(string memory _unrevealedBaseUri) external onlyOwner {
        unrevealedBaseUri = _unrevealedBaseUri;
    }

    function reveal(uint16 _tokensCount, uint _revealHash) external onlyOwner {
        uint _groupIndex = revealGroups.length;
        RevealGroup memory _prev;
        if (_groupIndex > 0) {
            _prev = revealGroups[_groupIndex - 1];
        } else {
            _prev = RevealGroup({
                startIndex: 0,
                lastIndex: 1
            });
        }
        revealGroups.push(RevealGroup({
            startIndex: _prev.lastIndex - 1,
            lastIndex: _prev.lastIndex + _tokensCount
        }));
        groupHashes.push(_revealHash);
    }

    
    function undoReveal() external onlyOwner() {
        revealGroups.pop();
        groupHashes.pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Whitelist stage of Adventurers Token workflow
 */
abstract contract WhiteList is ERC721, EIP712 {
    string public constant EIP712_VERSION = "1.0.0";

    /* state */
    address public signer;
    mapping(address /* minter */ => /* minted */ uint) public whitelistMinters;

    constructor() EIP712(NAME, EIP712_VERSION) {
        signer = msg.sender;
    }

    /* eip-712 */
    bytes32 private constant PASS_TYPEHASH = keccak256("MintPass(address wallet,uint256 count)");

    /* change eip-712 signer address, set 0 to disable WL */
    function setSigner(address _value) external onlyOwner {
        signer = _value;
    }

    function mintSelected(uint _count, uint _signatureCount, bytes memory _signature)
        external 
        returns (uint from, uint to)
    {
        require(signer != address(0), "eip-712: whitelist mint disabled");

        bytes32 _digest = _hashTypedDataV4(
            keccak256(abi.encode(PASS_TYPEHASH, msg.sender, _signatureCount))
        );
        require(ECDSA.recover(_digest, _signature) == signer, "eip-712: invalid signature");
        uint _maxCount = _signatureCount + 1 - whitelistMinters[msg.sender];
        require(_count < _maxCount, "eip-712: invalid count");
        whitelistMinters[msg.sender] += _count;

        return _mint(msg.sender, _count);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";

/// @title Timelocked.sol
/// @author @Dadogg80 - Viken Blockchain Solutions.
/// @notice Timelocked.sol allow any user to mint an NFT for FREE, against timelocking the new token for a pre-set time period.
/// @dev The main methods in this contract are [ mintAndLockToken } and { checkTimeLockedToken }, read more about the methods in their description.


abstract contract Timelocked is ERC721 {

    /// @notice Modifier will preform multiple checks related to the tier. 
    /// @param _tierOne { true } if tierOne, { false } if TierTwo. 
    /// @dev Throws the error { ErrorPrice } if msg.value is to low.
    modifier tierChecks(bool _tierOne) {
        if (!mintAndTimelockActive) revert Deactivated();
        if (_userTimeLocked[_msgSender()][_tierOne]) revert AlreadyLocked(_tierOne);
        if (_tierOne && (_tierOneSupply + 1) >= tierOneMaxSupply) revert ReachedMaxSupply(tierOneMaxSupply);
        if (!_tierOne && msg.value != tierTwoPrice) revert ErrorPrice(msg.value, tierTwoPrice);
        _;
    }

    /// @notice Will allow the user to mint and timelock the token in a tier.
    /// @dev Restricted with the { notHoldingTimelocked } modifier.
    /// @param tierOne The tier to timelock the minted token in, true is tier 1, false is tier 2.
    /// @return TimelockedToken The struct with the timelocked data.
    function mintAndLockToken(bool tierOne) 
        external
        payable
        tierChecks(tierOne)
        returns (TimelockedToken memory) 
    {
        (,uint256 _tokenId) = _mint(_msgSender(), 1);

        _timelockedTokens[_tokenId] = TimelockedToken({
            tokenId: _tokenId,
            tierOne: tierOne,
            lockTimestamp: block.timestamp,
            unlockTimestamp: tierOne ? _tierOneUnlockTime : _tierTwoUnlockTime
        });

        _tierOneSupply = tierOne ? (_tierOneSupply += 1) : _tierOneSupply;

        emit MintedTimelock(_msgSender(), _timelockedTokens[_tokenId].tierOne, _timelockedTokens[_tokenId].unlockTimestamp , _timelockedTokens[_tokenId].tokenId);

        return (_timelockedTokens[_tokenId]);
    }

    /// @notice Will return true and the unlocktime if a tokenId is locked.
    /// @param tokenId The token id to check.
    /// @return TimelockedToken The struct with the timelocked data.
    function checkTimelockedToken(uint256 tokenId) external view returns (TimelockedToken memory) {
        return _timelockedTokens[tokenId];
    } 
    
    /// @notice Restricted method is used to toggle the active status of the timelock feature. 
    /// @param toggle The bool condition to pass.
    function toggleTimelock(bool toggle) external onlyOwner {
        if (toggle == mintAndTimelockActive) revert TimeLockError();
        mintAndTimelockActive = toggle;
        emit AdjustedTimelock(toggle);
    }

    /// @notice Restricted method is used to adjust the unlock timestimp for each tier.
    /// @param tierOneUnlockTime The unlock timestamp of tier one.
    /// @param tierTwoUnlockTime The unlock timestamp of tier two.
    function setUnlockTime(uint256 tierOneUnlockTime, uint256 tierTwoUnlockTime) external onlyOwner {
        _tierOneUnlockTime = tierOneUnlockTime;
        _tierTwoUnlockTime = tierTwoUnlockTime;
        emit AdjustedUnlockTimes(tierOneUnlockTime, tierTwoUnlockTime);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";

/// @title Claim.sol
/// @notice This Claim contract adds a feature which will allow any account holding a token from the deprecated AOE collection,
///  to claim an amount of tokens from this Advenuters collection.This claim amount is x3 for each deprecated AOE tokens held by an account.
 
/** @dev Example below: 
 *      - Account A holds one token from deprecated AOE collection.
 *          - Account A will receive three new Adventurers tokens when claiming.
 * 
 *      - Account B holds three tokens from deprecated AOE collection.          
 *          - Account B will receive nine new Adventurers tokens when claiming.
*/

abstract contract Claim is ERC721 {
    
    /// @notice Contract address of the deprecated AOE collection to claim from.
    /// @notice This variable is Used in { claim } method in Claim.sol.
    /// @return The contract address of the collection. 
    ERC721 public collection;

    /// @dev Modifier checks if the account has any OLD AOE collection tokens.
    modifier authorized() {
        if (collection.balanceOf(_msgSender()) == 0) revert NotAuthorizedToClaim();
        if (!collection.isApprovedForAll(_msgSender(), address(this))) revert MissingApprovalForAll();
        _;
    }

    /// @notice Will allow the authorized accounts to claim x3 their deprecated AOE nfts.
    /// @notice This method requires { approvalForAll } before executed. 
    /// @dev Restricted with the authorized modifier.
    function claim() external authorized() {
        uint256[] memory _tokenIds = _mapTokenIds(_msgSender());
        uint256 _amount = _tokenIds.length;
        uint256 _total = _amount * 3;  

        for (uint256 i = 0; i < _amount; i++) {
            collection.safeTransferFrom(_msgSender(), address(this), _tokenIds[i], "");
            _claimedTokenIds[_tokenIds[i]] = true;
        }
        
        _mint(_msgSender(), _total);
        emit Claimed(_msgSender(), _tokenIds, _total);
    }

    /// @notice Used to check if a tokenId from deprecated AOE collection is claimed.
    /// @param tokenId The token to check if claimed.
    /// @return bool Returns true or false if a tokenId is claimed.
    function checkClaimed(uint256 tokenId) external view returns (bool) {
        return _claimedTokenIds[tokenId];
    }

    /// @notice Restricted function used to set the AOE collection contract address.
    /// @param _collection The contract address of the AOE collection.
    function setCollection(ERC721 _collection) external onlyOwner {
        collection = _collection;
        emit CollectionSet(address(_collection));
    }
    
    /// @notice Internal function used to get the OLD AOE tokenIds owned by an account.
    /// @param _account The account address of the user to check.
    /// @return _tokenIds Returns an array with the tokenIds owned by the given account.  
    function _mapTokenIds(address _account) internal view returns (uint256[] memory _tokenIds) {
        uint256 _tokens = collection.balanceOf(_account);

        _tokenIds = new uint256[](_tokens);
        for (uint256 i = 0; i < _tokens; i++) {
           uint256 _tokenId = collection.tokenOfOwnerByIndex(_account, i);
           _tokenIds[i] = _tokenId;
        }  
        return _tokenIds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../AdventurersStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @notice EIP-721 implementation of Adventurers Token
 */
abstract contract ERC721 is IERC721Enumerable, IERC721Metadata, AdventurersStorage {

    string public constant NAME = "Adventurers Of Ether";
    string public constant SYMBOL = "KOE";
    uint private constant MAX_SUPPLY = 6001; // +1 extra 1 for <

    /* state */
    uint256 public maxSupply = 3000;

    /// @notice Amount of minted tokens.
    uint private minted;

    /// @notice Amount of burned tokens.
    uint private burned;

    /// @notice Minter address to minted tokens amount.
    mapping(address => uint) public minters;

    address[MAX_SUPPLY] private owners;

    /// @notice Owner address to token amount. 
    mapping(address => uint) private balances;

    /// @notice tokenId to operator address.
    mapping(uint => address) private operatorApprovals;

    /// @notice Owner address, returns operator address true or false.
    mapping(address => mapping(address => bool)) private forallApprovals;

    /// @notice Function is used to adjust the maxSupply variable.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _maxSupply The new max supply amount.
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "max supply exceeded");
        maxSupply = _maxSupply;

        emit SetMaxSupply(maxSupply);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(ERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        return minted - burned;
    }

    function _mint(address _to, uint256 _amount)
        internal 
        returns (uint256 _oldIndex, uint256 _newIndex)
    {
        uint256 _minted = minted;
        require(_minted + _amount - 1 < maxSupply, "tokens are over");

        for (uint256 i = 0; i < _amount; i++){
            _minted++;
            owners[_minted] = _to;
            emit Transfer(address(0), _to, _minted);
        }

        minters[_to] += _amount;
        balances[_to] += _amount;
        minted = _minted;
        return (_minted - _amount, _minted);
    }

    function _mintBatch(address[] memory _to, uint[] memory _amounts)
        internal returns (uint256 _oldIndex, uint256 _newIndex)
    {
        require(_to.length == _amounts.length, "array lengths mismatch");
        uint256 _minted = minted;
        uint256 _total = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            uint256 _amount = _amounts[i];
            address _addr = _to[i];

            _total += _amount;
            //minters[_addr] += _amount;
            balances[_addr] += _amount;
            for (uint256 j = 0; j < _amount; j++){
                _minted++;
                owners[_minted] = _addr;
                emit Transfer(address(0), _addr, _minted);
            }
        }

        require(_minted + _total < maxSupply, "tokens are over");
        minted = _minted;
        return (_minted - _total, _minted);
    }

    /// @notice Used to burn multiple nft´s in one transaction.
    /// @param _tokens An array of tokenIds to burn.
    /// @dev Internal method.
    function _burn(uint256[] calldata _tokens) internal {
        uint256 _burned;
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _tokenId = _tokens[i];
            address _owner = owners[_tokenId];
            if (_owner != address(0)) {
                _burned ++;
                balances[_owner] -= 1;
                owners[_tokenId] = address(0);
                emit Transfer(_owner, address(0), _tokenId);
            }
        }
        burned += _burned;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return ((minted + 1) > _tokenId) && (_tokenId > 0) && owners[_tokenId] != address(0);
    }
    
    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint256 _ix = 0;
        for (uint256 _tokenId = 1; _tokenId < minted; _tokenId += 1) {
            if (owners[_tokenId] == _owner) {
                if (_ix == _index) {
                    return _tokenId;
                } else {
                    _ix += 1;
                }
            }
        }
        return 0;
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 _index) external pure returns (uint256) {
        return _index;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        _balance = balances[_owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        require(exists(_tokenId), "erc-721: nonexistent token");
        _owner = owners[_tokenId];
    }

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
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        _transfer(_from, _to, _tokenId, _data);
    }

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
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        _transfer(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address _from, address _to, uint256 _tokenId, bytes memory) internal {
        uint256 _unlockTime = _timelockedTokens[_tokenId].unlockTimestamp;
        if (_unlockTime > block.timestamp) revert TimeLockedToken(_unlockTime); 

        address _owner = ownerOf(_tokenId);
        require(msg.sender == _owner
            || getApproved(_tokenId) == msg.sender
            || isApprovedForAll(_owner, msg.sender),
            "erc-721: not owner nor approved");
        require(_owner == _from, "erc-721: not owner");
        require(_to != address(0), "zero address");
        operatorApprovals[_tokenId] = address(0);

        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

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
    function approve(address _to, uint256 _tokenId) external {
        address _owner = ownerOf(_tokenId);
        require(exists(_tokenId), "erc-721: nonexistent token");
        require(_owner != _to, "erc-721: approve to caller");
        require(
            msg.sender == _owner || isApprovedForAll(_owner, msg.sender),
            "erc-721: not owner nor approved"
        );
        operatorApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 _tokenId) public view returns (address _operator) {
        require(exists(_tokenId), "erc-721: nonexistent token");
        _operator = operatorApprovals[_tokenId];
    }

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
    function setApprovalForAll(address _operator, bool _approved) external {
        require(msg.sender != _operator, "erc-721: approve to caller");
        forallApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return forallApprovals[_owner][_operator];
    }

    /**
     * @dev IERC721Metadata Returns the token collection name.
     */
    function name() external pure returns (string memory) {
        return NAME;
    }

    /**
     * @dev IERC721Metadata Returns the token collection symbol.
     */
    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./interfaces/ITreasury.sol";


contract AdventurersStorage is Ownable, ERC2981 {
    
    /// @notice TimelockedToken is the struct containing the timelocked token data.
    /// @param tokenId The id of the timelocked token.
    /// @param tierOne Token is a tierOne locked token.
    /// @param lockTimestamp The start timestamp of the timelock.   
    /// @param unlockTimestamp The end timestamp of the timelock.   
    struct TimelockedToken {
        uint256 tokenId;
        bool tierOne;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
    }

    /// @notice ITreasury is a Treasury smart contract used to hold the Treasury amount.
    ITreasury public treasury;
    
    /// @notice The max supply allocated as tier one tokens.
    uint256 constant public tierOneMaxSupply = 1500;
    
    /// @notice The price of minting a locked token in tier two.
    uint256 public tierTwoPrice;

    string internal _contractURI;

    /// @notice The supply of tier one tokens.
    uint256 internal _tierOneSupply;

    /// @notice The unlock timestamp of tier one tokens.
    uint256 internal _tierOneUnlockTime;

    /// @notice The unlock timestamp of tier two tokens.
    uint256 internal _tierTwoUnlockTime;

    /// @notice The internal condition is used to validate if the { mintAndTimelock } feature is active.
    bool internal mintAndTimelockActive;


    /// @notice Mapping used to check if a tokenId from the deprecated AOE contract is claimed.
    /// @dev uint256 The tokenId of deprecated AOE collection. 
    /// @dev bool Returns true if tokenId is claimed. 
    mapping(uint256 => bool) internal _claimedTokenIds;

    /// @notice Use { _userTimeLocked } to verify if a user has timelocked a token in a given tier.
    /// @dev address The account to check. 
    /// @dev bool True if tierOne token. 
    /// @dev bool Returns true if { timelocked } in tierOne, or { false } if not timelocked in tierOne. 
    mapping (address => mapping (bool => bool)) internal _userTimeLocked;
    
    /// @notice Used to get the timelocked data of a tokenId.
    /// @dev uint256 The token id to check if is timelocked. 
    /// @dev TimelockedToken This returns the struct with the timelocked data. 
    mapping(uint256 => TimelockedToken) internal _timelockedTokens;

    /// @notice Thrown by modifier { tierChecks } if the user already has a locked token.
    /// @param tierOne Is true if locked to tier one, false if tier two. 
    error AlreadyLocked(bool tierOne);

    /// @notice Thrown by modifier { tierChecks } if the max supply of tier one has been minted.
    /// @param tierOneMaxSupply The maximum supply of tier one tokens allowed. 
    error ReachedMaxSupply(uint256 tierOneMaxSupply);

    /// @notice Thrown by modifier { tierChecks } if mint&Timelock period is not active .
    error Deactivated();

    /// @notice Thrown by { _transfer } method in { ERC721.sol }.
    /// @param unlockTime The unlock timestamp of the token.
    error TimeLockedToken(uint256 unlockTime);

    /// @notice Thrown by { authorized } modifier in claim method.
    error NotAuthorizedToClaim();

    /// @notice Thrown by { authorized } modifier if the user has not given { approvalForAll } before claiming.
    error MissingApprovalForAll();

    /// @notice Thrown by { transferToTreasury } method if the treasury address is a zero address.
    error NoZeroAddress();

    /// @notice Thrown by { toggleTimelock } method in Timelocked.sol if the lockvalue is the already set.
    error TimeLockError();

    /// @notice Thrown by { tierChecks } modifier if the msg.value is to low.
    /// @param sent Is the transacted value.
    /// @param expected Is the expected value.
    error ErrorPrice(
        uint256 sent, 
        uint256 expected
    );

    /// @notice Emitted when the MaxSupply has been adjusted.
    /// @param maxSupply The new maxSupply set for this contract. 
    event SetMaxSupply(uint256 maxSupply);

    /// @notice Emitted when the Treasury address has been adjusted.
    /// @param treasury The new Treasury address. 
    event TreasurySet(address treasury);

    /// @notice Emitted when the timelock activation has been toggeled.
    /// @param TimelockActivated The new condition of the timelock feature. 
    event AdjustedTimelock(bool TimelockActivated);

    /// @notice Emitted when the default royalty data has been adjusted.
    /// @param receiver The new Royalty receiver address. 
    /// @param feeNumerator The new Royalty amount. Example: 750 is equal to 7.5% 
    event UpdatedDefaultRoyalty(
        address indexed receiver,
        uint96 indexed feeNumerator
    );

    /// @notice Emitted when the royalty data of a given token has been adjusted.
    /// @param tokenId The tokenId of the token. 
    /// @param receiver The new Royalty receiver address. 
    /// @param feeNumerator The new Royalty amount. Example: 750 is equal to 7.5% 
    event UpdatedTokenRoyalty(
        uint256 indexed tokenId, 
        address indexed receiver,
        uint96 indexed feeNumerator
    );

    /// @notice Emmited when a new timelocked token is minted.
    /// @param account Indexed- The address of the minter. 
    /// @param tierOne Indexed- The tier of the timelocked token. 
    /// @param unlockTimestamp Indexed- The timestamp when the token becomes transferable. 
    /// @param tokenId The tokenId of the timelocked token. 
    event MintedTimelock(
        address indexed account,
        bool indexed tierOne, 
        uint256 indexed unlockTimestamp,
        uint256 tokenId
    );

    /// @notice Emittet when a new collection address is set.
    /// @param collection The address of the set collection.
    event CollectionSet(address collection);

    /// @notice Emmited when a new Adventurer has been minted and claimed.
    /// @param account Indexed- The address of the minter. 
    /// @param claimed Indexed- An array with the claimed tokenId from the deprecated AOE collection. 
    /// @param amount Indexed- The amount of new Adventurers minted. 
    event Claimed(
        address indexed account, 
        uint256[] indexed claimed,
        uint256 indexed amount
    );

    /// @notice Emmited when the unlocktimes of the tiers is adjusted.
    /// @param tierOneUnlock Indexed- Tier one unlock timestamp. 
    /// @param tierTwoUnlock Indexed- Tier two unlock timestamp.
    event AdjustedUnlockTimes(
        uint256 indexed tierOneUnlock, 
        uint256 indexed tierTwoUnlock
    );

    /* ------------------------------------------------------------  ADMIN ROYALTY FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the royalty data of a given token id {will override default royalty for this contact}.
    /// @dev Restricted to onlyOwner.
    /// @param tokenId The id of the token.
    /// @param receiver The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setTokenRoyalty(uint256 tokenId, address payable receiver, uint96 feeNumerator) 
        external
        onlyOwner 
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);

        emit UpdatedTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Adjust the current default royalty data.
    /// @dev Restricted to onlyOwner.
    /// @param receiver The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setDefaultRoyalty(address payable receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit UpdatedDefaultRoyalty(receiver, feeNumerator);
    }

    
    /// @notice Method is used by openSea to read contract information. 
    /// @dev Go to { https://docs.opensea.io/docs/contract-level-metadata } to learn more about this method.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITreasury {
    /**
     * @notice primary sale (invoked by nft contract on mint)
     */
    function primarySale() external payable;

    /**
     * @notice secondary sale (invoked by ERC-2981)
     */
    receive() external payable;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}