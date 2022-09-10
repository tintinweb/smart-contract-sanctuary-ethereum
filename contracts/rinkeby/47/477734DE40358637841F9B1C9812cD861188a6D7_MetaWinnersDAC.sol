// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./base/MetawinERC721Extensions/MetawinERC721Vault.sol";

/** @dev Contract defining "MetaWinners DAC" NFT collection
    Full feature list in the base contract MetawinERC721.sol
    Aditional features:
        -Royalty fees: 5%
        -The Vault (soft staking)
*/
contract MetaWinnersDAC is MetawinERC721Vault {

    // CONSTRUCTOR //

    constructor(uint256 _maxSupply) MetawinERC721(_maxSupply, "MetaWinnersDAC", "MWDAC", 500){  // 500 basis points (5%) royalty fees
        setUri("contract", "ipfs://bafybeiefyxm3wuvp5avjng5trxy2e734dfjvw22xg76cmcnclx274fuwfi/contractmetadata");// Set contract URI
        setUri("unrevealed", "ipfs://bafybeig2evl7ycjuncp647bawmqi3bvi5zp3knjgsqquq3ginw3bsk47gi/unrevealed");    // Set unrevealed URI
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/**
 * @dev Interface of the AddressList contract, which provides an address
 * whitelisting functionality
 */
interface IAddressList {

    /**
     * @dev Emitted when a new address is added to the list.
     */
    event AddeedToList(address indexed entity);

    /**
     * @dev Returns True if the queried address is in the list.
     */
    function isInList(address entity) external view returns(bool);

    /**
     * @dev Adds a new address to the list.
     */
    function addToList(address entity) external;
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/** @dev Base contract providing a flexible and human-friendly way to store multiple types
 *  of URI as a mapping
*/
abstract contract uriStorage {

    mapping (bytes32 => string) private uri;
    mapping (bytes32 => bool) private uri_frozen;

    /**
     * @dev Stores the given URI as the given type
     * @param _uriKeyword Type of URI being stored (e.g. "base", "unrevealed"...)
     * @param _uri URI string being stored
     */
    function setUri(string memory _uriKeyword, string memory _uri) internal {
        uri[bytes32(abi.encodePacked(_uriKeyword))] = _uri;
    }

    /**
     * @dev Returns the requested URI type
     * @param _uriKeyword Type of the previously stored URI (e.g. "base", "unrevealed"...)
     */
    function getUri(string memory _uriKeyword) internal view returns (string memory) {
        return uri[bytes32(abi.encodePacked(_uriKeyword))];
    }

    /**
     * @dev Enables the frozen (permanently locked) state for the given URI
     * @param _uriKeyword Type of URI being flagged (e.g. "base", "unrevealed"...)
     */
    function freezeUri(string memory _uriKeyword) internal {
        uri_frozen[bytes32(abi.encodePacked(_uriKeyword))] = true;
    }

    /**
     * @dev Returns the frozen state of the requested URI type
     * @param _uriKeyword Type of URI (e.g. "base", "unrevealed"...)
     */
    function isUriFrozen(string memory _uriKeyword) internal view returns (bool) {
        return uri_frozen[bytes32(abi.encodePacked(_uriKeyword))];
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/** @dev Library providing pseudo-random functions (deterministic but hard to guess)
*/
library Random {

    /**
    * @dev Get a random number
    */
    function rand() internal view returns (uint256){
        return uint256(keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit + 
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number
                )));
    }

    /**
    * @dev Get a random number from 0 to _maxValue
    * @param _max Maximum value
    */
    function randMax(uint256 _max) internal view returns (uint256){
        return rand() % _max;
    }

    /**
    * @dev Get a random number within the given range
    * @param _min Minimum value
    * @param _max Maximum value
    */
    function randRange(uint256 _min, uint256 _max) internal view returns (uint256){
        return (rand() % (_max-_min) ) + _min;
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./Random.sol";

/** @dev More complex version of SimpleReveal.sol
 *  Allows the same NFT reveal approach, however it can be used on a chunk of the collection even before the
 *  minting ends. By specifying the maximum ID, all IDs up to that number are revealed.
 *  WARNING: In order to have this working properly, tokenIds must be minted in sequential order.
*/
abstract contract BatchReveal {

    using Random for uint256;

    mapping(uint256 => uint256) public revealOffset; // BatchID => Offset - Used for token reveals: its value
                                                     // is generated randomly and used as offset of the token Id
                                                     // to generate the final Id.
    uint256[] maxRevealedId;

    /**
    * @dev [View][Public] Return the total supply
    */
    function totalSupply() public view virtual returns(uint256){}

    /**
    * @dev [Pure][Private] Subtraction clamping to zero instead of throwing error
    * @param a Operand A
    * @param b Operand B
    */
    function clampSub(uint256 a, uint256 b) private pure returns(uint256){
        return a>b ? a-b : 0;
    }

    /**
    * @dev [View][Public] Check if a tokenId is revealed
    * @param _tokenId Token ID to query
    */
    function revealed(uint256 _tokenId) view public returns(bool){
        return maxRevealedId.length == 0 ?
            false :
            _tokenId <= maxRevealedId[maxRevealedId.length-1];
    }

    /**
    * @dev [View][Public] Returns the maximum revealed token ID
    */
    function revealedMax() view public returns(uint256){
        return maxRevealedId.length == 0 ?
            0 :
            maxRevealedId[maxRevealedId.length-1];
    }

    /**
    * @dev [Tx][Internal] Reveal all token up to the specified ID - WARNING: access must be restricted when exposing
    * @param _maxId Maximum token ID to be revealed
    */
    function _reveal(uint256 _maxId) internal virtual {
        require((maxRevealedId.length == 0 || _maxId > maxRevealedId[clampSub(maxRevealedId.length,1)]) 
            && _maxId < totalSupply(), "Out of revealable range");
        uint256 divisor = clampSub(_maxId-revealedMax(), 1);
        divisor = divisor == 0 ? 1 : divisor;                                   // Prevent division by zero
        uint256 newRand = Random.rand()%divisor;                                // Assign a random value to ID offset
        if (newRand==0) newRand+=1;                                             // ID offset cannot be zero
        revealOffset[maxRevealedId.length] = newRand;
        maxRevealedId.push(_maxId);
    }

    /**
    * @dev [View][Public] Return a token's revealed ID
    * @param _tokenId Original token ID
    */
    function revealedId(uint256 _tokenId) view public virtual returns(uint256){
        require(revealed(_tokenId), "Token not revealed");
        uint256 index = 0;
        while(_tokenId > maxRevealedId[index]) index+=1;
        uint256 rangeMax = maxRevealedId[index];
        uint256 rangeMin = index < 1 ? 0 : maxRevealedId[index-1]+1;
        uint256 offset = revealOffset[index];
        return ((_tokenId + offset - rangeMin) % (rangeMax-rangeMin+1)) + rangeMin;
    }

    /**
    * @notice [View][Public] Return tokenId by specifying its revealedId
    * @param _revealedId Revealed token ID
    */
    function tokenId_fromRevealedId(uint256 _revealedId) view public virtual returns(uint256){
        require(_revealedId <= revealedMax(), "Token not revealed");
        uint256 index = 0;
        while(_revealedId > maxRevealedId[index]) index+=1;
        uint256 rangeMax = maxRevealedId[index];
        uint256 rangeMin = index < 1 ? 0 : maxRevealedId[index-1]+1;
        uint256 offset = revealOffset[index];
        uint256 actualOffset = offset % (rangeMax-rangeMin+1);
        if((_revealedId-rangeMin)>=(actualOffset)) return _revealedId - actualOffset;
        else return rangeMax - (actualOffset-(_revealedId-rangeMin)) +1;
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "../MetawinERC721.sol";

/** @dev Base contract adding "The Vault" (soft staking) to MetawinERC721
*/
abstract contract MetawinERC721Vault is MetawinERC721 {

    // CONTRACT VARIABLES //

    /**
    * @notice Whether staking is currently allowed.
    * @dev If false, token owners are unable to stake
    */
    bool public vault_stakingAllowed = false;
    /**
    * @notice Whether unstaking is currently allowed.
    * @dev If false, token owners are unable to unstake
    */
    bool public vault_unstakingAllowed = false;
    /**
    * @notice Global switch variable to enable/disable the function "vault_transferWhileInVault"
    */
    bool public vault_transfersAllowed = false;
    /**
    * @dev This is an internal variable, only meant to be temporarily activated
    * by the function safeTransferWhileInVault.
    */
    bool private vaultTransfer_tempAllowed = false;
    /**
    * @dev tokenId to staking start time, in Unix timestamp (0 = not staking).
    */
    mapping (uint256 => uint256) private activationTime;
    /**
    * @dev Cumulative per-token staking, excluding the current period.
    */
    mapping(uint256 => uint256) private timeTotal;
    /**
    * @dev Flag preventing expelled tokens to be restaked
    */
    mapping(uint256 => bool) private banned;


    // EVENTS //
    
    /**
    * @dev Emitted when a token is staked
    */
    event Vault_Locked(uint256 indexed tokenId);
    /**
    * @dev Emitted when a token is unstaked
    */
    event Vault_Unlocked(uint256 indexed tokenId);
    /**
    * @dev Emitted when a token is removed from staking by admin due to user's bad behaviour
    */
    event Vault_Expelled(uint256 indexed tokenId);


    // FUNCTIONS //

    /**
    * @notice Global switch to enable/disable vault staking.
    * @dev [Tx][External][Owner] Restricted to admin.
    */
    function vault_stakingGlobalToggle() external onlyOwner {
        vault_stakingAllowed ? vault_stakingAllowed=false : vault_stakingAllowed=true;
    }

    /**
    * @notice Global switch to enable unstaking (once enabled, it cannot be disabled).
    * @dev [Tx][External][Owner] Restricted to admin.
    */
    function vault_unstakingGlobalEnable() external onlyOwner {
        vault_unstakingAllowed = true;
    }

    /**
    * @notice Returns Vault staking info of a token
    * @dev [View][Public] All times are represented in seconds (Unix timestamp)
    * @return active Whether the NFT is currently in the Vault.
    * @return startTime Timestamp of when the NFT was locked in the Vault, zero if not staked.
    * @return current Zero if not currently in the Vault, otherwise the length of time
    * since the staking begun.
    * @return total Total period of time for which the NFT has been staked across
    * its life, including the current period.
    */
    function vault_tokenInfo(uint256 tokenId) public view
        returns (bool active, uint256 startTime, uint256 current, uint256 total) {
        startTime = activationTime[tokenId];
        if (startTime != 0) {
            active = true;
            current = block.timestamp - startTime;
        }
        total = current + timeTotal[tokenId];
    }

    /**
    * @notice Return cumulative Vault info of a user
    * @dev [View][External] Check the method "vault_tokenInfo" for more info.
    * @param user User's address
    * @return amountInVault Number of owned tokens locked in the Vault
    * @return currentCumulative Combined current staking time of all tokens owned by the user
    * @return totalCumulative Combined total staking time of all tokens owned by the user
    */
    function vault_userInfo(address user) external view
        returns (uint256 amountInVault, uint256 currentCumulative, uint256 totalCumulative) {
        uint256 bal = balanceOf(user);                         // Check number of tokens in user's wallet
        for (uint256 i = 0; i < bal; ++i) {                    // For each token held,
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            (bool active, , uint256 current, uint256 total) = vault_tokenInfo(tokenId);
            if(active){                                        // if the token is in the vault,
                amountInVault++;                               // add it to the count
                currentCumulative+=current;                    // add its staking time to the cumulative count
                totalCumulative+=total;                        // add its total time to the cumulative count
            }
        }
    }

    /**
    * @notice Get the lists of active (in Vault) and inactive (not in Vault) tokens owned by a user
    * @dev [View][External]
    * @param user User's address
    * @return active Array of staked tokenIds owned by the user
    * @return inactive Array of non-staked tokenIds owned by the user
    */
    function vault_tokensOfUser(address user) external view
        returns (uint256[] memory, uint256[] memory){
        uint256 bal = balanceOf(user);
        uint256[] memory active = new uint256[](bal);
        uint256 activeCount;
        uint256[] memory inactive = new uint256[](bal);
        uint256 inactiveCount;
        for (uint256 i = 0; i < bal; ++i) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            if(activationTime[tokenId]!=0) {
                active[activeCount] = tokenId;
                activeCount++;
            }
            else {
                inactive[inactiveCount] = tokenId;
                inactiveCount++;
            }
        }
        uint256[] memory activeTrimmed = new uint256[](activeCount);
        uint256[] memory inactiveTrimmed = new uint256[](inactiveCount);
        for(uint256 j = 0; j<activeCount; ++j) activeTrimmed[j] = active[j];
        for(uint256 k = 0; k<inactiveCount; ++k) inactiveTrimmed[k] = inactive[k];
        return (activeTrimmed, inactiveTrimmed);
    }

    /**
    * @dev [Tx][Internal] Block transfers while staking in the Vault
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            activationTime[tokenId] == 0 || vaultTransfer_tempAllowed == true,
            "Metawin Vault: Locked"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
    * @notice Global switch to enable/disable the function "vault_transferWhileInVault"
    * @dev [Tx][External][Owner] Restricted to admin.
    */
    function vault_toggleVaultTransfers() external onlyOwner {
        vault_transfersAllowed ? vault_transfersAllowed=false : vault_transfersAllowed=true;
    }

    /**
    * @notice Transfer a token between addresses while keeping in the Vault
    * thus not resetting the current time counter.
    * @dev The require statement prevent using it for secondary markets sales
    */
    function vault_transferWhileInVault(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(vault_transfersAllowed, "Metawin Vault: Transfers disabled");
        require(ownerOf(tokenId) == _msgSender(), "Metawin: Only token owner");
        vaultTransfer_tempAllowed = true;
        safeTransferFrom(from, to, tokenId);
        vaultTransfer_tempAllowed = false;
    }

    /**
    * @notice [Tx][Internal] Toggle the token's staking status
    */
    function vault_toggleStaking(uint256 tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        uint256 start = activationTime[tokenId];
        if (start == 0) {
            require(vault_stakingAllowed, "Staking disabled");
            require(!banned[tokenId], "Token banned from staking");
            activationTime[tokenId] = block.timestamp;
            emit Vault_Locked(tokenId);
        } else {
            require(vault_unstakingAllowed, "Unstaking denied");
            timeTotal[tokenId] += block.timestamp - start;
            activationTime[tokenId] = 0;
            emit Vault_Unlocked(tokenId);
        }
    }

    /**
    * @notice [Tx][External] Toggle the staking status of the input tokens
    */
    function vault_toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            vault_toggleStaking(tokenIds[i]);
        }
    }

    /**
    * @notice Admin-only function to remove a token from the Vault.
    * @dev [Tx][External][Owner] This representes an emergency measure
    * to be used only when a user exploits the Vault locking functionality
    * to harm the community, for example by undercutting the token's floor
    * price in the knowledge that it is locked and cannot be sold.
    */
    function vault_banToken(uint256 tokenId) external onlyOwner {
        require(activationTime[tokenId] != 0, "Vault: token not in stake");
        timeTotal[tokenId] += block.timestamp - activationTime[tokenId];
        activationTime[tokenId] = 0;
        banned[tokenId] = true;
        emit Vault_Unlocked(tokenId);
        emit Vault_Expelled(tokenId);
    }

    /**
    * @notice [Tx][External][Owner] Unban tokens from the Vault
    * @param tokenIds List of token ids to unban
    */
    function vault_unbanTokens(uint256[] calldata tokenIds) external onlyOwner {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            delete banned[tokenIds[i]];
        }
    }

    /**
    * @notice [View][External] Check if a token is banned from the Vault
    */
    function vault_isTokenBanned(uint256 tokenId) external view returns (bool) {
        return banned[tokenId];
    }

    /**
    * @dev [Tx][External][Restricted] Mint method override to stake upon minting
    * @param to Receiver's address
    * @param tokenId ID of the new token
    */
    function mint(address to, uint256 tokenId) external virtual override mintRequirements(tokenId) {
        super._safeMint(to, tokenId);
        activationTime[tokenId] = block.timestamp;
        emit Vault_Locked(tokenId);
    }

    /**
    * @dev [Tx][External][Restricted] Mint method override to stake upon minting (overloaded to mint IDs in ascending order)
    * @param to Receiver's address
    */
    function mint(address to) external virtual override mintRequirements(0) {
        uint256 newId = totalSupply();
        super._safeMint(to, newId);
        activationTime[newId] = block.timestamp;
        emit Vault_Locked(newId);
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./ERC721Extensions/ERC721RestrictedApprovals.sol";     // ERC721Enumerable + timestamps, whitelist approvals
import "./utils/URIstorage.sol";                               // URI dictionary
import "./utils/BatchReveal.sol";                              // Token reveal
import "@openzeppelin/contracts/token/common/ERC2981.sol";     // Royalties
import "@openzeppelin/contracts/access/Ownable.sol";           // Admin
import "@openzeppelin/contracts/utils/Strings.sol";            // Used to convert token id to string in URI functions

/** @dev Base contract defining Metawin NFT collections
  * Features:
  *     Capped supply: yes, defined via constructor, immutable afterwards
  *     Enumerable: yes
  *     Mintable: yes, only one chosen wallet/contract has permissions
  *     Burnable: no
  *     Revealable: yes
  *     Royalties: yes, basis points must be specified via constructor (immutable)
  *     Provenance: yes, the record becomes immutable once set
  *     Notes:
  *         - Also tracks time held - each NFT's counter resets if the token is transferred
  *         - Double-baseURI system (IPFS + Metawin Server) with safety toggle (restricted to admin)
  *         - Transfer approvals restricted to whitelisted addresses (aka soles can occur only on whitelisted markeplaces)
*/
contract MetawinERC721 is Ownable, ERC721RestrictedApprovals, uriStorage, BatchReveal, ERC2981 {

    using Strings for uint256;           // Enables uint to string conversion

    // CONTRACT VARIABLES //

    bool public mintable = true;         // Global switch to disable minting permanently (admin)
    bool internal useMetawinUri = true;  // Use Metawin alternative URI as main token URI
    address public minter;               // Address with minting permissions
    address public metadataProvider;     // Address with permissions to provide metadata info (URI reveal etc.)
    uint96 immutable royaltyFraction;    // Royalty fees
    uint256 public immutable MAX_SUPPLY; // Supply cap
    string public PROVENANCE;            // Final provenance hash

    // CONSTRUCTOR //

    /**
    * @param _maxSupply Token supply cap
    * @param _name Collection name
    * @param _symbol Collection ticker
    * @param _royaltyBPS Royalty basis points
    */
    constructor (uint256 _maxSupply, string memory _name, string memory _symbol, uint96 _royaltyBPS) 
        ERC721(_name, _symbol) {
        minter = msg.sender;            // Default minter address is deployer; owner can re-assign the role later on
        metadataProvider = msg.sender;  // Default metadata provider address is deployer; owner can re-assign the role later on
        MAX_SUPPLY = _maxSupply;        // Set maximum supply - WARNING: IMMUTABLE
        royaltyFraction = _royaltyBPS;  // 100 basis points is 1%, and so on
        _setDefaultRoyalty(msg.sender, royaltyFraction); // Default payee is owner
    }

    // MODIFIERS //

    modifier onlyMetadataProvider{
        require(msg.sender == metadataProvider, "Permission denied");
        _;
    }

    /**
    * @dev Defines all the requirements to perform a minting - can be overridden in derived contracts
    */
    modifier mintRequirements(uint256 _tokenId) virtual {
        require(mintable, "Minting renounced");                                             // Minting is allowed
        require(totalSupply() < MAX_SUPPLY && _tokenId < MAX_SUPPLY, "Max supply reached"); // Cap to max supply
        require(msg.sender == minter, "Called by non-minter addr");                         // Minter role required
        _;
    }


    // SETUP FUNCTIONS //

    /**
    * @dev [Tx][External][Owner] Set minter address
    * @param newMinter Address of the new minter role
    */
    function setMinter(address newMinter) external onlyOwner {
        require(minter != newMinter, "Input is already minter");
        minter = newMinter;
    }

    /**
    * @dev [Tx][External][Owner] Set metadata provider address
    * @param newProvider Address of the new provider role
    */
    function setMetadataProvider(address newProvider) external onlyOwner {
        require(metadataProvider != newProvider, "Input is already metadata provider");
        metadataProvider = newProvider;
    }

    /**
    * @dev [Tx][External][Restricted] Set contract metadata URI
    * @param _uri Address of the contract metadata
    */
    function setContractURI(string calldata _uri) external onlyMetadataProvider {
        string memory uri_key = "contract";
        setUri(uri_key, _uri);
    }

    /**
    * @dev [Tx][External][Restricted] Set unrevealed tokens URI
    * @param _uri Address of the unrevealed URI
    */
    function setUnrevealedURI(string calldata _uri) external onlyMetadataProvider {
        string memory uri_key = "unrevealed";
        setUri(uri_key, _uri);
    }

    /**
    * @dev [Tx][External][Restricted] Set base URI (used as prefix for final URI)
    * @param _uri Address of the base URI
    */
    function setBaseURI(string calldata _uri) external onlyMetadataProvider {
        string memory uri_key = "base";
        require(!isUriFrozen(uri_key), "BaseURI is frozen");
        setUri(uri_key, _uri);
    }

    /**
    * @dev [Tx][External][Owner] Freeze (permanently lock) the base URI
    */
    function freezeBaseURI() external onlyOwner {
        require(!isUriFrozen("base"), "BaseURI already frozen");
        freezeUri("base");
    }

    /**
    * @dev [Tx][External][Restricted] Set alternative Metawin base URI
    * @param _uri Address of the base URI
    */
    function setMetawinBaseURI(string calldata _uri) external onlyMetadataProvider {
        string memory uri_key = "baseMW";
        setUri(uri_key, _uri);
    }

    /**
    * @dev [Tx][External][Owner] Swap tokenURI() and tokenURI_alternative() return values
    */
    function toggleMetawinURI() external onlyOwner {
        useMetawinUri ? useMetawinUri = false : useMetawinUri = true;
    }

    /**
    * @dev [Tx][External][Owner] Set royalty receiver
    * @param receiver Address of the royalty fee payee
    */
    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    /**
    * @dev [Tx][External][Owner] Disable minting forever
    */
    function renounceMinting() external onlyOwner {
        require(mintable == true, "Minting already disabled");
        mintable = false;
    }


    // PROVENANCE FUNCTIONS //

    /**
    * @dev [Tx][External][Restricted] Set final provenance record
    * @param _hash Provenance hash
    */
    function setProvenance(string calldata _hash) external onlyMetadataProvider {
        require(bytes(PROVENANCE).length == 0, "Override not allowed");
        require(bytes(_hash).length > 0, "Empty provenance not allowed");
        PROVENANCE = _hash;
    }


    // MINTING FUNCTIONS //

    /**
    * @dev [Tx][External][Restricted] Exposed mint function (restrictions are defined by the "mintRequirements" modifier)
    * @param to Receiver's address
    * @param tokenId ID of the new token
    */
    function mint(address to, uint256 tokenId) external virtual mintRequirements(tokenId) {
        super._safeMint(to, tokenId);
    }

    /**
    * @dev [Tx][External][Restricted] Overloaded mint function, mints in sequential order with no second argument
    * @param to Receiver's address
    */
    function mint(address to) external virtual mintRequirements(0) {
        super._safeMint(to, totalSupply());
    }


    // REVEAL FUNCTIONS //

    /**
    * @dev [Tx][External][Restricted] Token reveal
    */
    function reveal(uint256 _maxId) external virtual onlyMetadataProvider {
        super._reveal(_maxId);
    }


    // URI FUNCTIONS //

    /**
    * @dev [View][Public] Return True if the base URI is frozen (locked forever)
    */
    function baseURI_frozen() public view returns(bool) {
        return(isUriFrozen("base"));
    }

    /**
    * @dev [View][Public] Return the contract URI
    */
    function contractURI() public view returns (string memory) {
        return getUri("contract");
    }

    /**
    * @dev [View][Private] Assemble token URI
    * @param _tokenId Token ID
    */
    function getTokenURI(string memory _base, uint256 _tokenId) private view returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token"); // Make sure that the token exists
        string memory unrevealedURI = getUri("unrevealed");
        return revealed(_tokenId) ? 
            string(abi.encodePacked(_base, (revealedId(_tokenId)).toString())):        // Return revealed URI (base_uri + id),
            unrevealedURI;                                                             // otherwise the unrevealed URI
    }

    /**
    * @dev [View][Public] Return the token URI
    * @param _tokenId Token ID
    */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        string memory baseURI = useMetawinUri ? getUri("baseMW") : getUri("base");
        return getTokenURI(baseURI, _tokenId);
    }

    /**
    * @dev [View][Public] Return the alternative token URI
    * @param _tokenId Token ID
    */
    function tokenURI_alternative(uint256 _tokenId) public view virtual returns (string memory){
        string memory baseURI = useMetawinUri ? getUri("base") : getUri("baseMW");
        return getTokenURI(baseURI, _tokenId);
    }


    // UTILS //

    /**
    * @dev [View][Internal] Max supply implementation, called by token reveal base contract
    */
    function maxSupply() internal view returns(uint256){
        return MAX_SUPPLY;
    }

    /**
    * @dev [View][Public] Total supply override, required due to token reveal base contract
    */
    function totalSupply() public view virtual override(BatchReveal, MetawinERC721Enumerable) returns (uint256){
        return MetawinERC721Enumerable.totalSupply();
    }

    /**
    * @dev [View][Public] Override required for ERC2981 support
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli*

// *Source: OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Simplified version of Openzeppelin's ERC721Enumerable, stripped of all the unneeded features
 * in order to reduce gas usage.
 * Note: As this implementation is not fully compliant to the ERC721Enumerable standard, it is NOT set to
 * be recognized as ERC721Enumerable by ERC-165 supportsInterface()
 */

abstract contract MetawinERC721Enumerable is ERC721 {

    // Total amount of tokens stored by the contract.
    uint256 private _totalSupply;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Returns a token ID owned by "owner" at a given "index" of its token list.
     * Use along with {balanceOf} to enumerate all of "owner"'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "MetawinERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to) {
            if (from != address(0)) _removeTokenFromOwnerEnumeration(from, tokenId);
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        if (from == address(0)) _totalSupply++;
        //else if (to == address(0)) _totalSupply--;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./MetawinERC721Enumerable.sol";

/**
 * @dev This implements an optional functionality to ERC721Enumerable to store the last transfer
 * timestamp of each token and query how long the current holder has held it
 */
abstract contract ERC721Timestamp is MetawinERC721Enumerable{

    mapping(uint256 => uint256) private lastTransferTimestamp; // Token ID => Last transfer timestamp

    /**
    * @dev [Tx][Internal] Timestamping, called before token transfers
    * @param from Origin address
    * @param to Destination address
    * @param tokenId Token ID
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);         // Run base contract's beforeTokenTransfer function
        lastTransferTimestamp[tokenId] = block.timestamp;      // Override the last transfer timestamp with the current time
    }

    /**
    * @dev [View][Public] Check how long a token has been held by the current holder
    * @param user Holder's address
    * @param _tokenId Token ID
    */
    function timeHeldByIndex(address user, uint256 _tokenId) public view returns (uint256 _timeHeld) {
        bool isOwner = ownerOf(_tokenId) == user;
        _timeHeld = isOwner ? block.timestamp - lastTransferTimestamp[_tokenId] : 0;
    }

    /**
    * @dev [View][External] Return how long the account has held his current tokens, cumulatively
    * @param user Holder's address
    */
    function timeHeldCumulative(address user) external view returns (uint256 _cumulativeHODL) {
        uint256 bal = balanceOf(user);                         // Check number of tokens in user's wallet
        for (uint256 i = 0; i < bal; i++) {                    // For each token held,
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            _cumulativeHODL += timeHeldByIndex(user, tokenId); // add time held to cumulative count
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./ERC721Timestamp.sol";
import "../../utils/IAddressList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This restricts ERC721's {approve} and {setApprovalForAll} to be used only under certain conditions,
 * thus preventing token holders to sell their NFTs on non-trusted marketplaces.
 * In this implementation, it must be used in conjunction with another smart-contract that handles the address list.
 */
abstract contract ERC721RestrictedApprovals is ERC721Timestamp, Ownable {

    // Failsafe state variable to bypass all restrictions.
    bool private _bypassAllRestrictions;

    // If true, "approveeListAddress" can no longer be amended.
    bool public approveeListAddressFrozen;
    
    // Address of the contract handling the list of allowed approvees.
    address public approveeListAddress;

    /**
     * @dev Modifier handling the restriction rules; used in {approve} and {setApprovalForAll} overrides.
     */
    modifier approvalRestrictions(address approvee) virtual {
        require(
            IAddressList(approveeListAddress).isInList(approvee) // Primary condition: "approvee" is in the whitelist
            || _bypassAllRestrictions // Failsafe: restrictions bypass enabled
            , "ERC721RestrictedApproval: Approvee not in whitelist");
        _;
    }

    /**
     * @dev Allows to disable/enable the approval restrictions
     */
    function toggleApprovalRestrictions() external virtual onlyOwner {
        _bypassAllRestrictions ? _bypassAllRestrictions = false : _bypassAllRestrictions = true;
    }

    /**
     * @dev Sets the address of the contract handling the list of allowed approvees
     */
    function setApproveeWhitelistAddress(address contractAddress) external virtual onlyOwner {
        require(!approveeListAddressFrozen, "Whitelist address frozen");
        approveeListAddress = contractAddress;
    }

    /**
     * @dev Makes "approveeListAddress" immutable
     */
    function freezeApproveeWhitelistAddress() external virtual onlyOwner {
        require(!approveeListAddressFrozen, "Already frozen");
        approveeListAddressFrozen = true;
    }

    /**
     * @dev Adds the {approvalRestrictions} modifier to {ERC721-approve}
     */
    function approve(address to, uint256 tokenId) public virtual override approvalRestrictions(to) {
        super.approve(to, tokenId);
    }

    /**
     * @dev Adds the {approvalRestrictions} modifier to {ERC721-setApprovalForAll}
     */
    function setApprovalForAll(address operator, bool approved) public virtual override approvalRestrictions(operator) {
        super.setApprovalForAll(operator, approved);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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