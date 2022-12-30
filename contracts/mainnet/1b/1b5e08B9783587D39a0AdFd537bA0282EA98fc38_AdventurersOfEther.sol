//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./adventurer/PublicSale.sol";
import "./adventurer/PreSale.sol";
import "./adventurer/WhiteList.sol";
import "./adventurer/Claim.sol";
import "./adventurer/Timelocked.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Kingdoms of Ether is a CC0 & open-sourced franchise inhabited by 3D Knights, Archers & Wizards of Ether.

/// @author Founded by Ludvig Holmen & Janus-Faced.
/// @author Contract developed by @dadogg80, Viken Blockchain Solutions.

/// @notice AdventurersOfEther.sol is the ERC721 standard smart-contract, and it incorperates multiple features and phases like:
/// @notice - Whitelist, PreSale, PublicSale.
/// @notice - Claim feature.
/// @notice - And mint & lock feature.

contract AdventurersOfEther is Timelocked, PublicSale, WhiteList, PreSale, Claim {
    using Strings for uint256;


    /// @notice Emittet when the collection is initiated.
    event Initiated();

    constructor( address payable _royaltyReceiver, uint96 _feePercentInBIPS) {
        _setDefaultRoyalty(_royaltyReceiver, _feePercentInBIPS);
    }
    
    /// @notice Restricted method will initiate the collection.
    /// @dev Restricted with onlyOwner modifier.
    /// @param __contractURI The contractURI.
    /// @param _tierTwoPrice The price of minting a Tier Two timelocked token.
    /// @param tierThreeUnlockTime The unix timestamp to unlock tierThree timelocked tokens.
    /// @param tierTwoUnlockTime The unix timestamp to unlock tierTwo timelocked tokens.
    function initCollection(string memory __contractURI, uint256 _tierTwoPrice, uint256 tierThreeUnlockTime, uint256 tierTwoUnlockTime) external onlyOwner {
        _contractURI = __contractURI;
        tierTwoPrice = _tierTwoPrice;
        mintAndTimelockActive = true;
        _tierThreeUnlockTime = tierThreeUnlockTime;
        _tierTwoUnlockTime = tierTwoUnlockTime;
        
        emit Initiated();
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
    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;

        emit TreasurySet(treasury);
    }

    /// @notice Transfer Funds to the treasury address.
    function transferToTreasury() external {
        if(payable(treasury) == address(0)) revert NoZeroAddress();
        (bool success,) = treasury.call{value: address(this).balance}("");
        if(!success) revert TreasuryError();
    }
    
    /// @dev Method returns the URI with a given token ID's metadata.
    /// @dev Returns the uri for the token ID given, with additional suffix if set.
    /// @param _tokenId The token id to retrieve the metadata of.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return bytes(_baseTokenURI).length != 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), _uriSuffix)) : "";
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../AdventurersStorage.sol";

/// @title Timelocked.sol
/// @author @Dadogg80 - Viken Blockchain Solutions.
/// @notice Timelocked.sol allow any user to mint an NFT for FREE, against timelocking the new token for a pre-set time period.
/// @dev The main methods in this contract are [ mintAndLockToken } and { checkTimeLockedToken }, read more about the methods in their description.


abstract contract Timelocked is AdventurersStorage {

    /// @notice Modifier will preform multiple checks related to the tier. 
    /// @param _tierThree { true } if tierThree, { false } if TierTwo. 
    /// @dev Throws the error { ErrorPrice } if msg.value is to low.
    modifier tierChecks(bool _tierThree) {
        if (!mintAndTimelockActive) revert Deactivated();
        if (_userTimeLocked[_msgSender()][_tierThree]) revert AlreadyLocked(_tierThree);
        if (_tierThree && (_tierThreeSupply + 1) >= TIER_THREE_MAX_SUPPLY) revert ReachedMaxSupply(TIER_THREE_MAX_SUPPLY);
        if (!_tierThree && msg.value != tierTwoPrice) revert ErrorPrice(msg.value, tierTwoPrice);
        _;
    }

    /// @notice Will allow the user to mint and timelock the token in a tier.
    /// @dev Restricted with the { notHoldingTimelocked } modifier.
    /// @param tierThree The tier to timelock the minted token in, true is tier 3, false is tier 2.
    /// @return TimelockedToken The struct with the timelocked data.
    function mintAndLockToken(bool tierThree) 
        public
        payable
        tierChecks(tierThree)
        returns (TimelockedToken memory) 
    {
        (,uint256 _tokenId) = _mint(_msgSender(), 1);

        _timelockedTokens[_tokenId] = TimelockedToken({
            tokenId: _tokenId,
            tierThree: tierThree,
            lockTimestamp: block.timestamp,
            unlockTimestamp: tierThree ? _tierThreeUnlockTime : _tierTwoUnlockTime
        });

        _tierThreeSupply = tierThree ? (_tierThreeSupply += 1) : _tierThreeSupply;

        emit MintedTimelock(_msgSender(), _timelockedTokens[_tokenId].tierThree, _timelockedTokens[_tokenId].unlockTimestamp , _timelockedTokens[_tokenId].tokenId);

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
    /// @param tierThreeUnlockTime The unlock timestamp of tier one.
    /// @param tierTwoUnlockTime The unlock timestamp of tier two.
    function setUnlockTime(uint256 tierThreeUnlockTime, uint256 tierTwoUnlockTime) external onlyOwner {
        _tierThreeUnlockTime = tierThreeUnlockTime;
        _tierTwoUnlockTime = tierTwoUnlockTime;
        emit AdjustedUnlockTimes(tierThreeUnlockTime, tierTwoUnlockTime);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../AdventurersStorage.sol";
import "./Timelocked.sol";

/// @title Claim.sol
/// @notice This Claim contract adds a feature which will allow any account holding a token from the deprecated AOE collection,
///  to claim an amount of tokens from this Adventurers collection. This claim amount is x2 for each deprecated AOE tokens held by an account.
 
/** @dev Example below: 
 *      - Account A holds one token from deprecated AOE collection.
 *          - Account A will receive three new Adventurers tokens when claiming.
 * 
 *      - Account B holds three tokens from deprecated AOE collection.          
 *          - Account B will receive nine new Adventurers tokens when claiming.
*/

abstract contract Claim is AdventurersStorage, Timelocked {
    
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
        uint256 _total = _amount * 2;  

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
    function setOGCollection(ERC721 _collection) external onlyOwner {
        collection = _collection;
        emit CollectionSet(address(_collection));
    }
    
    /// @notice Public function used to get the OLD AOE tokenIds owned by an account.
    /// @param _account The account address of the user to check.
    /// @return _tokenIds Returns an array with the tokenIds owned by the given account.  
    function _mapTokenIds(address _account) public view returns (uint256[] memory _tokenIds) {
        uint256 _tokens = collection.balanceOf(_account);

        _tokenIds = new uint256[](_tokens);

        for (uint256 i = 0; i < _tokens; i++) {
            uint256 _tokenId = collection.tokenOfOwnerByIndex(_account, i);
            if (_tokenId != 0) {
                _tokenIds[i] = _tokenId;
            }
        }

        return _tokenIds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../AdventurersStorage.sol";

/// @title Whitelist.sol
/// @author @Dadogg80 - Viken Blockchain Solutions.
/// @notice Whitelist.sol will allow the "whitelisted accounts to mint their pre-allocated amount of adventurers.
/// @dev The main methods in this contract are [ setMerkleRoot } and { mintSelected }, read more about the methods in their description.

abstract contract WhiteList is AdventurersStorage {

    mapping (address => bool) internal whitelistUsed;
    mapping (address => uint256) internal whitelistRemaining;
    

    bytes32 internal merkleRoot;
    uint256 public maxItemsPerTx = 5;

    /// @notice Allow whitelisted accounts to mint according to the merkletree.
    /// @param amount The amount of nft's to mint.
    /// @param totalAllocation The allocated amount to mint.
    /// @param leaf the leaf node of the three.
    /// @param proof the proof from the merkletree.
    function mintSelected(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external {
        // Create storage element tracking user mints if this is the first mint for them
        if (!whitelistUsed[msg.sender]) {
            // Verify that (msg.sender, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(merkleRoot, leaf, proof), "Not a valid leaf");

            whitelistUsed[msg.sender] = true;
            whitelistRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");
        require(amount <= maxItemsPerTx, "Above MaxItemsPerTx");

        require(whitelistRemaining[msg.sender] >= amount, "more than remaining allocation");
 
        whitelistRemaining[msg.sender] -= amount;
        _mint(msg.sender, amount);
        emit MintSelected(msg.sender, amount);
    }

    /// @notice verify the merkleProof.
    /// @param root the root node in the merkletree.
    /// @param leaf The leaf node in the merkletree.
    /// @param proof The proof in the merkletree.
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintSelectedActive(bool result) external onlyOwner {
        mintSelectedActive = result;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../AdventurersStorage.sol";

/**
 * @notice Presale (Crystal exchange) stage of Adventurers Token workflow
 */
abstract contract PreSale is AdventurersStorage {
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

import "../AdventurersStorage.sol";

/**
 * @notice Public sale stage of Adventurers Token workflow
 */
abstract contract PublicSale is AdventurersStorage {

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./adventurer/ERC721.sol";


abstract contract AdventurersStorage is Ownable, ERC721, ERC2981 {
    /// @notice Address of the receiver of the smart contract funds.
    address payable public treasury;
    
    /// @notice The max supply allocated as tier three tokens.
    uint256 constant public TIER_THREE_MAX_SUPPLY = 1500;
    
    /// @notice The suffix to use at the end of the baseTokenURI. 
    string internal _uriSuffix;
    
    /// @notice The price of minting a locked token in tier two.
    uint256 public tierTwoPrice;

    string internal _contractURI;

    /// @notice The Base uri string for these tokens.
    string internal _baseTokenURI;

    /// @notice The supply of tier three tokens.
    uint256 internal _tierThreeSupply;

    /// @notice The unlock timestamp of tier three tokens.
    uint256 internal _tierThreeUnlockTime;

    /// @notice The unlock timestamp of tier two tokens.
    uint256 internal _tierTwoUnlockTime;

    /// @notice The internal condition is used to validate if the { mintAndTimelock } feature is active.
    bool internal mintAndTimelockActive;

    /// @notice The internal condition is used to validate if the { whitelist } feature is active.
    bool internal mintSelectedActive;

    string internal constant _MerkleLeafMatchError = "Don't match Merkle leaf";
    string internal constant _MerkleLeafValidationError = "Not a valid Merkle Leaf";
    string internal constant _RemainingAllocationError = "Can't mint more than remaining allocation";

    /// @notice Mapping used to check if a tokenId from the deprecated AOE contract is claimed.
    /// @dev uint256 The tokenId of deprecated AOE collection. 
    /// @dev bool Returns true if tokenId is claimed. 
    mapping(uint256 => bool) internal _claimedTokenIds;

    /// @notice Use { _userTimeLocked } to verify if a user has timelocked a token in a given tier.
    /// @dev address The account to check. 
    /// @dev bool True if tierThree token. 
    /// @dev bool Returns true if { timelocked } in tierThree, or { false } if not timelocked in tierThree. 
    mapping (address => mapping (bool => bool)) internal _userTimeLocked;

    /// @notice Thrown by modifier { tierChecks } if the user already has a locked token.
    /// @param tierThree Is true if locked to tier three, false if tier two. 
    error AlreadyLocked(bool tierThree);

    /// @notice Thrown by modifier { tierChecks } if the max supply of tier three has been minted.
    /// @param TIER_THREE_MAX_SUPPLY The maximum supply of tier one tokens allowed. 
    error ReachedMaxSupply(uint256 TIER_THREE_MAX_SUPPLY);

    /// @notice Thrown by modifier { tierChecks } if mint&Timelock period is not active .
    error Deactivated();

    /// @notice Thrown by { authorized } modifier in claim method.
    error NotAuthorizedToClaim();

    /// @notice Thrown by { authorized } modifier if the user has not given { approvalForAll } before claiming.
    error MissingApprovalForAll();

    /// @notice Thrown by { transferToTreasury } method if the treasury address is a zero address.
    error NoZeroAddress();

    error NoZeroValues();

    /// @notice Thrown by { toggleTimelock } method in Timelocked.sol if the lockvalue is the already set.
    error TimeLockError();

    /// @notice Thrown by { transferToTreasury } method if the transaction fails.
    error TreasuryError();

    /// @dev Emitted with a message.
    /// @param message The error message.
    error ErrorMessage(string message);
    
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
    /// @param tierThree Indexed- The tier of the timelocked token. 
    /// @param unlockTimestamp Indexed- The timestamp when the token becomes transferable. 
    /// @param tokenId The tokenId of the timelocked token. 
    event MintedTimelock(
        address indexed account,
        bool indexed tierThree, 
        uint256 indexed unlockTimestamp,
        uint256 tokenId
    );

    /// @notice Emmited when a new whitelisted account mint a new token.
    /// @param account Indexed - The address of the minter. 
    /// @param amount The amount minted. 
    event MintSelected(
        address indexed account,
        uint256 amount
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
    /// @param tierThreeUnlock Indexed- Tier three unlock timestamp. 
    /// @param tierTwoUnlock Indexed- Tier two unlock timestamp.
    event AdjustedUnlockTimes(
        uint256 indexed tierThreeUnlock, 
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

    /// @notice Method is used to adjust the baseTokenURI. 
    /// @param baseTokenURI The new baseTokenUri to use.
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Method is used to adjust the baseTokenURI suffix.
    /// @param suffix The suffix to use at the end of the baseTokenURI. 
    function setSuffix(string memory suffix) external onlyOwner {
        _uriSuffix = suffix;
    }

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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
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
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
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

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
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
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
abstract contract ERC721 is IERC721Enumerable, IERC721Metadata {

    /// @notice TimelockedToken is the struct containing the timelocked token data.
    /// @param tokenId The id of the timelocked token.
    /// @param tierThree Token is a tier three locked token.
    /// @param lockTimestamp The start timestamp of the timelock.   
    /// @param unlockTimestamp The end timestamp of the timelock.   
    struct TimelockedToken {
        uint256 tokenId;
        bool tierThree;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
    }

    /// @notice Used to get the timelocked data of a tokenId.
    /// @dev uint256 The token id to check if is timelocked. 
    /// @dev TimelockedToken This returns the struct with the timelocked data. 
    mapping(uint256 => TimelockedToken) internal _timelockedTokens;

    string public constant NAME = "Adventurers Of Ether";
    string public constant SYMBOL = "KOE";
    uint internal constant MAX_SUPPLY = 6001; // +1 extra 1 for <

    /* state */
    uint256 public maxSupply = 3000;

    /// @notice Amount of minted tokens.
    uint private minted;

    /// @notice Amount of burned tokens.
    uint private burned;

    address[MAX_SUPPLY] private owners;


    /// @notice Minter address to minted tokens amount.
    mapping(address => uint) public minters;


    /// @notice Owner address to token amount. 
    mapping(address => uint) private balances;

    /// @notice tokenId to operator address.
    mapping(uint => address) private operatorApprovals;

    /// @notice Owner address, returns operator address true or false.
    mapping(address => mapping(address => bool)) private forallApprovals;
    
    /// @notice Thrown by { _transfer } method in { ERC721.sol }.
    /// @param unlockTime The unlock timestamp of the token.
    error TimeLockedToken(uint256 unlockTime);
   
    event Minted(uint256 fromTokenId, uint256 toTokenId, address to, uint256 amount);

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

        emit Minted(_oldIndex, _newIndex, _to, _amount);
        
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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