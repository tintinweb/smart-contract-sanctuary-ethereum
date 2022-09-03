// SPDX-License-Identifier: MIT
/**
                                                                                                    
                                            ethkun <3 u                                                  
                                                                                                    
                                                                                                    
                                               ,,,***.                                              
                                               ,,,***.                                              
                                               ,,,***.                                              
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                      ,,,,,,,,,,,,*************                                     
                                      ,,,,,,,,,,,,*************                                     
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                ,,,,,,,,,,,,,,,,,,*******************                               
                                ,,,,,,,,,,,,,,,,,,*******************                               
                            .,,,,,,,,,,,,&&&,,,,,,******&&&*************                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                         ,,,,,,,,,,,,,||||||,,,,,,******|||||||************                         
                         ,,,,,,,,,,,,,,,,,,,,,,,,,***#&&%******************                         
                      ,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&&%*********************.                     
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                      ,,,,,,.      ,,,,,,,,,,,,,,,****************      ******.                     
                         ,,,,,,,,,,      ,,,,,,,,,**********      *********                         
                            .,,,,,,,,,,,,      ,,,***.      ************                            
                                ,,,,,,,,,,,,,,,      ,***************                               
                                ,,,,,,,,,,,,,,,      ,***************                               
                                   ,,,,,,,,,,,,,,,****************                                  
                                      ,,,,,,,,,,,,*************                                     
                                         ,,,,,,,,,**********                                        
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                               ,,,***.                                              
                                                                                                    
                                                                                                    


**/
// by @eddietree and @SecondBestDad

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./IEthKunRenderer.sol";
import "./EthKunRenderer.sol";

/// @title ethkun
/// @author @eddietree
/// @notice ethkun is an 100% on-chain experimental NFT project
contract EthKun is EthKunRenderer, ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 5875;
    uint256 public maxMintsPerPersonPublic = 2;

    // contracts
    IEthKunRenderer public contractRenderer;

    enum MintStatus {
        CLOSED, // 0
        PUBLIC // 1
    }

    MintStatus public mintStatus = MintStatus.CLOSED;
    bool public revealEnabled = true;
    bool public mergeEnabled = true;
    bool public burnSacrificeEnabled = false;
    bool public demoteRerollEnabled = false;

    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public level;
    uint256 public mergeBlockNumber = 0;

    // events
    event EthKunLevelUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel); // emitted when an EthKun gets sacrificed
    event EthKunDied(uint256 indexed tokenIdDied, uint256 level, uint256 indexed tokenMergedInto); // emitted when an EthKun gets sacrificed
    event EthKunSacrificed(uint256 indexed tokenId); // emitted when an EthKun gets sacrificed
    event EthRerolled(uint256 indexed tokenId, uint256 newLevel); // emitted when an EthKun gets rerolled

    constructor() ERC721A("ethkun", "ETHKUN") {
        contractRenderer = IEthKunRenderer(this);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        
        _;
    }

    modifier verifySupply(uint256 numToMint) {
        //require(tx.origin == msg.sender,  "No bots");
        require(numToMint > 0, "Mint at least 1");
        require(_totalMinted() + numToMint <= MAX_TOKEN_SUPPLY, "Exceeds max supply");

        _;
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    /// @notice Burn sacrifice an ethkun to Lord Vitalik
    /// @param tokenId The token ID for the EthKun
    function burnSacrifice(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        //require(msg.sender == ownerOf(tokenId), "Not yours");
        require(burnSacrificeEnabled == true);

        _burn(tokenId);

        emit EthKunSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function _mintEthKuns(address to, uint256 numToMint) private verifySupply(numToMint) {
        uint256 startTokenId = _startTokenId() + _totalMinted();
         for(uint256 tokenId = startTokenId; tokenId < startTokenId+numToMint; tokenId++) {
            _saveSeed(tokenId);
            level[tokenId] = 1;
         }

         _safeMint(to, numToMint);
    }

    function reserveEthKuns(address to, uint256 numToMint) external onlyOwner {
        _mintEthKuns(to, numToMint);
    }

    function reserveEthKunsMany(address[] calldata recipients, uint256 numToMint) external onlyOwner {

        uint256 num = recipients.length;
        require(num > 0);

        for (uint256 i = 0; i < num; ++i) {
            _mintEthKuns(recipients[i], numToMint);    
        }

    }

    /// @notice Mint a single ETH kun into your wallet!
    function mintEthKun() external {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(_numberMinted(msg.sender) + 1 <= maxMintsPerPersonPublic, "Exceeds max mints");

        _mintEthKuns(msg.sender, 1);
    }

    /*function mintEthKuns(uint256 numToMint) external {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(_numberMinted(msg.sender) + numToMint <= maxMintsPerPersonPublic, "Exceeds max mints");

        _mintEthKuns(msg.sender, numToMint);
    }*/

    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxMints(uint256 _maxMintsPublic) external onlyOwner {
        maxMintsPerPersonPublic = _maxMintsPublic;
    }

    function _merge(uint256[] calldata tokenIds) private {
        uint256 num = tokenIds.length;
        require(num > 0);

        // all the levels accumulate to the first token
        uint256 tokenIdChad = tokenIds[0];
        uint256 accumulatedTotalLevel = 0;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            require(_ownershipOf(tokenId).addr == _msgSender(), "Must own");
            require(level[tokenId] != 0, "Dead");

            uint256 tokenLevel = level[tokenId];
            accumulatedTotalLevel += tokenLevel;

            // burn if not main one
            if (i > 0) {
                _burn(tokenId);
                emit EthKunDied(tokenId, tokenLevel, tokenIds[0]);

                // reset
                level[tokenId] = 0;
            }
        }

        uint256 prevLevel = level[tokenIdChad];
        level[tokenIdChad] = accumulatedTotalLevel;

        //_saveSeed(tokenIdChad);
        emit EthKunLevelUp(tokenIdChad, prevLevel, accumulatedTotalLevel);
    }

    /// @notice Merge several ethkuns into one gigachad ethkun, all the levels accumulate into the gigachad ethkun, but the remaining ethkuns are burned, gg
    /// @param tokenIds Array of owned tokenIds. Note that the first tokenId will be the one that remains and accumulates levels of other ethkuns, the other tokens will be BURNT!!
    function merge(uint256[] calldata tokenIds) external {
        require(_isRevealed() && mergeEnabled);
        _merge(tokenIds);
    }

    /// @notice Reroll the visuals/stats of ethkun, but unfortunately demotes them by -1 level :(
    /// @param tokenIds Array of owned tokenIds of ethkuns to demote
    function demoteRerollMany(uint256[] calldata tokenIds) external {
        require(_isRevealed() && demoteRerollEnabled);

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            require(_ownershipOf(tokenId).addr == _msgSender());
            require(level[tokenId] > 1, "At least Lvl 1");
            
            _saveSeed(tokenId); // reroll visuals/stats
            level[tokenId] -= 1; // demote

            // even
            emit EthRerolled(tokenId, level[tokenId]);
        }
    }

    // taken from 'ERC721AQueryable.sol'
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = IEthKunRenderer(newAddress);
    }

    function setRevealed(bool _revealEnabled) external onlyOwner {
        revealEnabled = _revealEnabled;
    }

    function setMergeEnabled(bool _enabled) external onlyOwner {
        mergeEnabled = _enabled;
    }

    function setMergeBlockNumber(uint256 newMergeBlockNumber) external onlyOwner {
        mergeBlockNumber = newMergeBlockNumber;
    }

    function setBurnSacrificeEnabled(bool _enabled) external onlyOwner {
        burnSacrificeEnabled = _enabled;
    }

    function setDemoteRerollEnabled(bool _enabled) external onlyOwner {
        demoteRerollEnabled = _enabled;
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        //string[13] memory lookup = [  '0', '1', '2', '3', '4', '5', '6', '7', '8','9', '10','11', '12'];

        uint256 seed = seeds[tokenId];
        unchecked{ // unchecked so it can run over
            seed += mergeBlockNumber;
        }

        string memory image = contractRenderer.getSVG(seed, level[tokenId]);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain experimental NFT project celebrating the Ethereum Proof-of-Stake merge. by @eddietree and @secondbestdad.",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        //'{"trait_type":"Vibing?", "value":', (vibingStartTimestamp[tokenId] != NULL_VIBING) ? '"Yes"' : '"Nah"', '},',
                        //'{"trait_type":"OG TokenID", "value":', Strings.toString(ogTokenId[tokenId]), '},',
                        '{"trait_type":"Level", "value":',Strings.toString(level[tokenId]),', "max_value":',Strings.toString(MAX_TOKEN_SUPPLY),'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractRenderer.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain experimental NFT project celebrating the Ethereum Proof-of-Stake merge. by @eddietree and @secondbestdad.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _isRevealed() private view returns (bool) {
        return revealEnabled && block.number > mergeBlockNumber;   
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (_isRevealed()) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed) private pure returns (string memory) {
        string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Kimochii", "display_type": "number", "value":', lookup[_randStat(seed, 2, 1, 5)], '},',
          '{"trait_type":"UWU", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Ultrasound Money", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Mergeability", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Sugoiness", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},',
          '{"trait_type":"Days Until Moon", "display_type": "number", "value":', lookup[_randStat(seed, 7, 2, 10)], '},',
          '{"trait_type":"Kawaii", "display_type": "number", "value":', lookup[_randStat(seed, 8, 2, 10)], '},',
          '{"trait_type":"Moisturized", "display_type": "number", "value":', lookup[_randStat(seed, 9, 2, 10)], '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

interface IEthKunRenderer{
  function getSVG(uint256 seed, uint256 level) external view returns (string memory);
  function getUnrevealedSVG(uint256 seed) external view returns (string memory);
  function getTraitsMetadata(uint256 seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';
import "./IEthKunRenderer.sol";
import "./EthKunData.sol";

contract EthKunRenderer is IEthKunRenderer, EthKunData {

  string[] public bgPaletteColors = [
    'ffffff', 'fcf3be', 'fcdebe', 'fcc9be', 
    'fcbedb', 'fcbeec', 'efbefc', 'dabefc', 
    'c5befc', 'bed7fc', 'bef2fc', 'befce5', 
    'befcc1', '122026'
  ];

  string[] public bodyColors = [
    '80b0bb','56b7e9','e1624a','85ae36',
    'e7b509','f6b099','85ae36','de953a',
    '56b7e9','dd5bca','80b0bb','56b7e9',
    'e1624a','85ae36','debb45', 'f6b099'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint eyes;
    uint mouth;
  }

  function getSVG(uint256 seed, uint256 level) external view returns (string memory) {
    return _getSVG(seed, level);
  }

  function _getSVG(uint256 seed, uint256 level) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    // clamp to max
    uint256 levelIndex = level;
    if (levelIndex >= levels.length) 
    {
      levelIndex = levels.length-1;
    }

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      //_renderRects(levels[levelIndex], fullPalettes),
      //_renderRectsSingleColor(levels[levelIndex], bodyColors[data.body]),
      _renderRectsSingleColor(levels[seed % 17], bodyColors[data.body]),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256) internal view returns (string memory) {
    //CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      //'<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      '<rect width="100%" height="100%" fill="#122026"/>',
      _renderRects(misc[0], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getTraitsMetadata(uint256 seed) external view returns (string memory) {
    return _getTraitsMetadata(seed);
  }

  function _getTraitsMetadata(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory metadata = string(abi.encodePacked(
      '{"trait_type":"Background", "value":"', lookup[data.background+1], '"},',
      '{"trait_type":"Body", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '"height="1"x="', lookup[x], '"y="', lookup[y], '"fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _renderRectsSingleColor(bytes memory data, string memory color) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '"height="1"x="', lookup[x], '"y="', lookup[y], '"fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      eyes: eyes_indices[(seed/3) % eyes_indices.length],
      mouth: mouths_indices[(seed/4) % mouths_indices.length]
    });
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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
// AUTOGENERATED FILE by @eddietree on Fri Sep 02 2022 23:46:21 GMT-0700 (Pacific Daylight Time)

pragma solidity ^0.8.0;

contract EthKunData {
	string[] public fullPalettes = ['ff00ff', '000000', 'ffffff', 'ff0000', '00ff00', '0000ff', '1e2528', 'eadece', 'ea6a6a', '80b0bb', '7991a1', '56b7e9', '3a88de', 'e1624a', 'cb4227', 'e7b509', 'da7e0d', '85ae36', '509434', 'f6b099', 'e37d74', 'de953a', 'c36c2d', 'efc567', 'f9dea3', 'e6b64d', '6ddeee', 'fdd3f6', '9ce5de', '276cd7', 'ed8dde', 'be3ccd', 'e56dd3', 'f7baee', 'dd5bca', '9035b4', 'debb45', 'fefefe'];

	///////////////////////////////////////
	// eyes
	bytes[] public eyes = [
		bytes(hex'ff00ff000f00010604000106'),
		bytes(hex'ff00ee00010604000106'),
		bytes(hex'ff008e00010604000106'),
		bytes(hex'ff002f00010602000106'),
		bytes(hex'ff00ce00020602000206'),
		bytes(hex'ff006e00020602000206'),
		bytes(hex'ff00cd000206040002061900020602000206'),
		bytes(hex'ff008d000206040002061900020602000206'),
		bytes(hex'ff00ad0002060400020619000206020002061a00010604000106'),
		bytes(hex'ff00ec0001060200010602000106020001061700020604000206'),
		bytes(hex'ff00cd0002060400020617000106020001060200010602000106'),
		bytes(hex'ff00ce000106040001061b00010602000106'),
		bytes(hex'ff006e000106040001061b00010602000106'),
		bytes(hex'ff00cf000106020001061b00010604000106'),
		bytes(hex'ff004f000106020001061b00010604000106'),
		bytes(hex'ff00ce000106040001061a00010604000106'),
		bytes(hex'ff006e000106040001061a00010604000106'),
		bytes(hex'ff00cd000206040002061900010604000106'),
		bytes(hex'ff00cd000306020003061900010604000106'),
		bytes(hex'ff00ad0003060200030619000206020002063a00020602000206'),
		bytes(hex'ff006d00020604000206180003060200030619000206020002063a00010604000106'),
		bytes(hex'ff00ac00040602000406140003060207040602070306140001060207010602000106020701061700020604000206'),
		bytes(hex'ff00ac0004060200040614000e0614000406020004061700020604000206'),
		bytes(hex'ff008c00030604000306150005060200050614000c0614000506020005061500030604000306'),
		bytes(hex'ff00cd000206040002061700010608000106'),
		bytes(hex'ff008c00020620000206030002061b00060617000206030006061b000206'),
		bytes(hex'ff00ec00010608000106'),
		bytes(hex'ff00ad000206040002061700020601070106020002060107010616000406020004061700020604000206'),
		bytes(hex'ff004d000206040002061700020601070106020002060107010616000406020004061700020604000206'),
		bytes(hex'ff00ad0003060200030638000107010601070200010701060107'),
		bytes(hex'ff004d0003060200030638000107010601070200010701060107'),
		bytes(hex'ff00ad00020604000206190002060200020619000107010601070200010701060107'),
		bytes(hex'ff004d00020604000206190002060200020619000107010601070200010701060107'),
		bytes(hex'ff00ad00020604000206170003070106020001060307160001070206010702000107020601071700020704000207'),
		bytes(hex'ff00ad000207040002071700040702000407160002070106010702000107010602071700020704000207'),
		bytes(hex'ff00cd00020704000207180001070106040001060107'),
		bytes(hex'ff006d00020704000207180001070106040001060107'),
		bytes(hex'ff00cd00030602000306180002070106020001060207180002070106020001060207'),
		bytes(hex'ff008d00030602000306180002070106020001060207180002070106020001060207'),
		bytes(hex'ff00d30002071700040602000107020601071d000207'),
		bytes(hex'ff00ee0001060400010619000208040002081800020804000208'),
		bytes(hex'ff00ac00040602000406140003060207040602070306140001060207010602000106020701061700020604000206160001080100010806000108010001083500010808000108'),
		bytes(hex'ff00ac0003070400030715000107030601070200010703060107140001070306010702000107030601071500030704000307'),
		bytes(hex'ff008e000206020002061900010606000106390001070106020001070106'),
		bytes(hex'ff00ad00030602000306180001070106010702000107010601071900010704000107'),
		bytes(hex'ff00cd00080617000a061800010604000106'),
		bytes(hex'ff004f000106020001061a0002060400020618000207040002071700020702060200020702061600020702060200020702061700020704000207'),
		bytes(hex'ff006d000306020003061700020602070200020702061600010601070206020002060107010615000208010702060200020601070208130004080600040812000408060004081300020808000208'),
		bytes(hex'ff00cd000206040002061700020606000206'),
		bytes(hex'ff008e00020602000206190003060200030618000206040002061a00010602000106')
	];

	string[] public eyes_traits = [
		'Vacant Low',
		'Vacant Medium',
		'Vacant High',
		'Vacant Too High',
		'Sleepy',
		'Sleepy High',
		'Angry',
		'Angry High',
		'Hero',
		'Somber',
		'Happy',
		'Slant',
		'Slant High',
		'Inverse',
		'Inverse High',
		'Cartoon',
		'Cartoon High',
		'Pensive',
		'Judgmental',
		'Dad',
		'Mad Dad',
		'Glasses',
		'Sunglasses',
		'Beeg Sunglasses',
		'Tired',
		'Pirate',
		'Dumb',
		'Animal',
		'Animal High',
		'Unsettling',
		'Unsettling High',
		'Villain',
		'Villain High',
		'Froggish',
		'Wide',
		'Beady',
		'Beady High',
		'JRPG',
		'JRPG High',
		'Wink',
		'Shy',
		'Nerd',
		'Stoned',
		'Sus',
		'Grump',
		'Unibrow',
		'Terrified',
		'Blushing',
		'Ambivalent',
		'Trustworthy'
	];

	uint8[] public eyes_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49];

	///////////////////////////////////////
	// mouths
	bytes[] public mouths = [
		bytes(hex'ff00ff0051000206'),
		bytes(hex'ff00ff0091000206'),
		bytes(hex'ff00ff0050000406'),
		bytes(hex'ff00ff0090000406'),
		bytes(hex'ff00ff0050000106020001061d000206'),
		bytes(hex'ff00ff00510002061d00010602000106'),
		bytes(hex'ff00ff004e0001060600010619000606'),
		bytes(hex'ff00ff004f0006061900010606000106'),
		bytes(hex'ff00ff006e0001060100010601000106010001061a000106010001060100010601000106'),
		bytes(hex'ff00ff00510002061e000206'),
		bytes(hex'ff00ff00910002061e000206'),
		bytes(hex'ff00ff00510002061d0004061c000406'),
		bytes(hex'ff00ff00500004061c0004061d000206'),
		bytes(hex'ff00ff00500004061b0006061a00020602000206'),
		bytes(hex'ff00ff004f000206020002061a0006061b000406'),
		bytes(hex'ff00ff004f0006061b000406'),
		bytes(hex'ff00ff004e0001060100040601000106180008061900020602000206'),
		bytes(hex'ff00ff00500004061b000106040701061a0006061b000406'),
		bytes(hex'ff00ff00530001061c0004061f000106'),
		bytes(hex'ff00ff0050000106020001061c0004061c00010602000106'),
		bytes(hex'ff00ff00540001061a0006061f000106'),
		bytes(hex'ff00ff004f000106040001061a0006061a00010604000106'),
		bytes(hex'ff00ff004f000106050001061a0005061b00010603000106'),
		bytes(hex'ff00ff004f00060619000106030701060207010619000606'),
		bytes(hex'ff00ff00510002061c000206020002061900010606000106'),
		bytes(hex'ff00ff005000010620000206'),
		bytes(hex'ff00ff00530001061d000206'),
		bytes(hex'ff00ff00720001061e000106'),
		bytes(hex'ff00ff00510002061d000106020001061c00010602000106'),
		bytes(hex'ff00ff006d000a06'),
		bytes(hex'ff00ff00510002061c00020602000206'),
		bytes(hex'ff00ff004f00020602000206190001060200020602000106'),
		bytes(hex'ff00ff006c0003060600030617000606'),
		bytes(hex'ff00ff0050000106020001061c000106020001061d000206'),
		bytes(hex'ff00ff006e00010602000206020001061900020602000206'),
		bytes(hex'ff00ff00520003061a00030601070106010701061c000306'),
		bytes(hex'ff00ff006e00020601070206010702061a000406'),
		bytes(hex'ff00ff0070000206010701061d000206'),
		bytes(hex'ff00ff00510002061d0004061c0004061d000206'),
		bytes(hex'ff00ff00300004061b0006061a0006061a0006061b000406'),
		bytes(hex'ff00ff0071000106'),
		bytes(hex'ff00ff0073000106'),
		bytes(hex'ff00ff006f00010620000206'),
		bytes(hex'ff00ff00740002061d000106'),
		bytes(hex'ff00ff00510002061d000106020001061c000106020001061d000206'),
		bytes(hex'ff00ff00700004061b000606'),
		bytes(hex'ff00ff006f00010620000206'),
		bytes(hex'ff00ff004d0001060800010616000a06'),
		bytes(hex'ff00ff0052000106200001061e000106200001061e000106'),
		bytes(hex'ff00ff006f000106040701061b0004061d000207')
	];

	string[] public mouths_traits = [
		'Smol',
		'Smol Low',
		'Normal',
		'Normal Low',
		'Smile',
		'Frown',
		'Wide Smile',
		'Wide Frown',
		'Cursed',
		'Oh',
		'Oh Low',
		'Yell',
		'Announce',
		'Shriek',
		'Address',
		'Naive',
		'Gentleman',
		'Teethy Yell',
		'Acorn',
		'Two Acorns',
		'Chewing',
		'Chomping',
		'Bubblecheeks',
		'Tyson',
		'Froggish',
		'Smirk',
		'Antismirk',
		'Hmm',
		'Unhappy',
		'Mostly Mouth',
		'Chewing Lip',
		'Wavy',
		'Burger',
		'Cute',
		'Cat',
		'Half Shell',
		'Vamp',
		'Scamp',
		'O',
		'OOO',
		'Peck',
		'Dot',
		'Side Smirk',
		'Determined',
		'Outline',
		'Regret',
		'Too Happy',
		'Bracket',
		'Smooch',
		'Car Salesman'
	];

	uint8[] public mouths_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49];

	///////////////////////////////////////
	// bodies
	bytes[] public bodies = [
		bytes(hex'6f000109010a1e000109010a1d000209020a1c000209020a1b000309030a1a000309030a19000409040a18000409040a17000509050a16000509050a15000609060a14000609060a13000709070a12000709070a11000809080a10000809080a0f000909090a10000709070a1000020902000509050a0200020a0f00030902000309030a0200030a1100040902000109010a0200040a130005090200050a15000509050a17000409040a19000309030a1b000209020a1d000109010a'),
		bytes(hex'6f00010b010c1e00010b010c1d00020b020c1c00020b020c1b00030b030c1a00030b030c1900040b040c1800040b040c1700050b050c1600050b050c1500060b060c1400060b060c1300070b070c1200070b070c1100080b080c1000080b080c0f00090b090c1000070b070c1000020b0200050b050c0200020c0f00030b0200030b030c0200030c1100040b0200010b010c0200040c1300050b0200050c1500050b050c1700040b040c1900030b030c1b00020b020c1d00010b010c'),
		bytes(hex'6f00010d010e1e00010d010e1d00020d020e1c00020d020e1b00030d030e1a00030d030e1900040d040e1800040d040e1700050d050e1600050d050e1500060d060e1400060d060e1300070d070e1200070d070e1100080d080e1000080d080e0f00090d090e1000070d070e1000020d0200050d050e0200020e0f00030d0200030d030e0200030e1100040d0200010d010e0200040e1300050d0200050e1500050d050e1700040d040e1900030d030e1b00020d020e1d00010d010e'),
		bytes(hex'6f00011101121e00011101121d00021102121c00021102121b00031103121a00031103121900041104121800041104121700051105121600051105121500061106121400061106121300071107121200071107121100081108121000081108120f000911091210000711071210000211020005110512020002120f00031102000311031202000312110004110200011101120200041213000511020005121500051105121700041104121900031103121b00021102121d0001110112'),
		bytes(hex'6f00010f01101e00010f01101d00020f02101c00020f02101b00030f03101a00030f03101900040f04101800040f04101700050f05101600050f05101500060f06101400060f06101300070f07101200070f07101100080f08101000080f08100f00090f09101000070f07101000020f0200050f0510020002100f00030f0200030f0310020003101100040f0200010f0110020004101300050f020005101500050f05101700040f04101900030f03101b00020f02101d00010f0110'),
		bytes(hex'6f00011301141e00011301141d00021302141c00021302141b00031303141a00031303141900041304141800041304141700051305141600051305141500061306141400061306141300071307141200071307141100081308141000081308140f000913091410000713071410000213020005130514020002140f00031302000313031402000314110004130200011301140200041413000513020005141500051305141700041304141900031303141b00021302141d0001130114'),
		bytes(hex'6f000111010d1e000111010d1d000211020d1c000211020d1b000311030d1a000311030d19000411040d18000411040d17000511050d16000511050d15000611060d14000611060d13000711070d12000711070d11000811080d10000811080d0f000911090d10000711070d1000020c02000511050d020002150f00030c02000311030d020003151100040c02000111010d020004151300050c020005151500050c05151700040c04151900030c03151b00020c02151d00010c0115'),
		bytes(hex'6f0002161e0002161d0001160117011501161c0001160117011501161b0001160217021501161a0001160117021801150116190001160117011502180117011501161800011601170215021701190116170001160117011903150319011616000116011702190315021901161500011601170215021903150219011614000116011703150219031501190116130001160117051502190315011901161200011601170615021903150116110001160117081502190315011610000116011709150219021501160f00011601170b150219021501160e0002160c15021902160e000116011702160a150216011901160f000116021702160615021602190116110001160115021702160215021602190115011613000116021502170216021902150116150001160315021703150116170001160615011619000116041501161b000116021501161d000216'),
		bytes(hex'6f00011a010c1e00011a010c1d00010b011b020c1c00010b011c020c1b00020b011c030c1a00020b011a030c1900030b011a040c1800030b011a040c1700050b050c1600050b050c1500060b060c1400060b060c1300050b010c010b021d050c1200030b030c010b041d030c1100020b050c010b061d020c1000070c010b081d0f00080c010b091d1000060c010b071d1000020c0200040c010b051d0200021d0f00030c0200020c010b031d0200031d1100040c0200010b011d0200041d1300050c0200051d1500040c010b051d1700030c010b041d1900020c010b031d1b00010c010b021d1d00010b011d'),
		bytes(hex'6f00011e011f1e00011e011f1d000120011b021f1c0001200121021f1b0002200121031f1a000220011e031f19000320011e041f180001220220011e041f170003220220051f160004220120051f150005220120061f140005220120061f13000522011f01200223051f12000322031f01200423031f11000222051f01200623021f1000071f012008230f00081f012009231000061f01200723100002220200041f012005230200021f0f0003220200021f012003230200031f110004220200012001230200041f130005220200051f150004220120051f170003220120041f190002220120031f1b0001220120021f1d000120011f'),
		bytes(hex'6f000109010a1e000109010a1d000209020a1c000209020a1b000309030a1a000309030a19000409040a18000409040a17000509050a16000509050a15000609060a14000809040a13000509040a0209030a12000309080a0209010a110002090c0a02091000100a0f00120a10000e0a1000020902000a0a0200020a0f0003090200060a0200030a110004090200020a0200040a130005090200050a15000509050a17000409040a19000309030a1b000209020a1d000109010a'),
		bytes(hex'6f00010b010c1e00010b010c1d00020b020c1c00020b020c1b00030b030c1a00030b030c1900040b040c1800040b040c1700050b050c1600050b050c1500060b060c1400080b040c1300050b040c020b030c1200030b080c020b010c1100020b0c0c020b1000100c0f00120c10000e0c1000020b02000a0c0200020c0f00030b0200060c0200030c1100040b0200020c0200040c1300050b0200050c1500050b050c1700040b040c1900030b030c1b00020b020c1d00010b010c'),
		bytes(hex'6f00010d010e1e00010d010e1d00020d020e1c00020d020e1b00030d030e1a00030d030e1900040d040e1800040d040e1700050d050e1600050d050e1500060d060e1400080d040e1300050d040e020d030e1200030d080e020d010e1100020d0c0e020d1000100e0f00120e10000e0e1000020d02000a0e0200020e0f00030d0200060e0200030e1100040d0200020e0200040e1300050d0200050e1500050d050e1700040d040e1900030d030e1b00020d020e1d00010d010e'),
		bytes(hex'6f00011101121e00011101121d00021102121c00021102121b00031103121a00031103121900041104121800041104121700051105121600051105121500061106121400081104121300051104120211031212000311081202110112110002110c120211100010120f00121210000e121000021102000a12020002120f000311020006120200031211000411020002120200041213000511020005121500051105121700041104121900031103121b00021102121d0001110112'),
		bytes(hex'6f00012401151e00012401151d00022402151c00022402151b00032403151a00032403151900042404151800042404151700052405151600052405151500062406151400082404151300052404150224031512000324081502240115110002240c150224100010150f00121510000e151000022402000a15020002150f000324020006150200031511000424020002150200041513000524020005151500052405151700042404151900032403151b00022402151d0001240115'),
		bytes(hex'6f00011301141e00011301141d00021302141c00021302141b00031303141a00031303141900041304141800041304141700051305141600051305141500061306141400081304141300051304140213031412000313081402130114110002130c140213100010140f00121410000e141000021302000a14020002140f000313020006140200031411000413020002140200041413000513020005141500051305141700041304141900031303141b00021302141d0001130114')
	];

	string[] public bodies_traits = [
		'Dull',
		'Cool',
		'Hot',
		'Envy',
		'Sand',
		'Flesh',
		'Web2',
		'Gold',
		'Sapphire',
		'Amethyst',
		'Duller',
		'Cooler',
		'Hotter',
		'Jealous',
		'Sandier',
		'Fleshier'
	];

	uint8[] public bodies_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];

	///////////////////////////////////////
	// levels
	bytes[] public levels = [
		bytes(hex'2e0004011c000101020001011b000101040001011a000101040001011900010106000101180001010600010117000101080001011600010108000101150001010a000101140001010a000101130001010c000101120001010c000101110001010e000101100001010e0001010f000101100001010e000101100001010d000101120001010c000101120001010b000101140001010a000101140001010a000101140001010b000101120001010d000101100001010f0001010e000101110001010c000101130001010a0001011500010108000101170001010600010119000101040001011b000101020001011d000201'),
		bytes(hex'0e0004011b0006011a00020102000201190002010400020118000201040002011700020106000201160002010600020115000201080002011400020108000201130002010a000201120002010a000201110002010c000201100002010c0002010f0002010e0002010e0002010e0002010d000201100002010c000201100002010b000201120002010a0002011200020109000201140002010800020114000201080002011400020109000201120002010b000201100002010d0002010e0002010f0002010c000201110002010a00020113000201080002011500020106000201170002010400020119000201020002011b000401'),
		bytes(hex'0d000601190008011800030102000301170003010400030116000301040003011500030106000301140003010600030113000301080003011200030108000301110003010a000301100003010a0003010f0003010c0003010e0003010c0003010d0003010e0003010c0003010e0003010b000301100003010a0003011000030109000301120003010800030112000301070003011400030106000301140003010600030114000301070003011200030109000301100003010b0003010e0003010d0003010c0003010f0003010a000301110003010800030113000301060003011500030104000301170003010200030119000601'),
		bytes(hex'0c00080117000a0116000401020004011500040104000401140004010400040113000401060004011200040106000401110004010800040110000401080004010f0004010a0004010e0004010a0004010d0004010c0004010c0004010c0004010b0004010e0004010a0004010e000401090004011000040108000401100004010700040112000401060004011200040105000401140004010400040114000401040004011400040105000401120004010700040110000401090004010e0004010b0004010c0004010d0004010a0004010f0004010800040111000401060004011300040104000401150004010200040117000801'),
		bytes(hex'0b000a0115000c01140005010200050113000501040005011200050104000501110005010600050110000501060005010f000501080005010e000501080005010d0005010a0005010c0005010a0005010b0005010c0005010a0005010c000501090005010e000501080005010e000501070005011000050106000501100005010500050112000501040005011200050103000501140005010200050114000501020005011400050103000501120005010500050110000501070005010e000501090005010c0005010b0005010a0005010d000501080005010f000501060005011100050104000501130005010200050115000a01'),
		bytes(hex'0a000c0113000e011200060102000601110006010400060110000601040006010f000601060006010e000601060006010d000601080006010c000601080006010b0006010a0006010a0006010a000601090006010c000601080006010c000601070006010e000601060006010e00060105000601100006010400060110000601030006011200060102000601120006010100060114000601060114000601060114000601000101000601120006010300060110000601050006010e000601070006010c000601090006010a0006010b000601080006010d000601060006010f00060104000601110006010200060113000c01'),
		bytes(hex'09000e011100100110000701020007010f000701040007010e000701040007010d000701060007010c000701060007010b000701080007010a00070108000701090007010a000701080007010a000701070007010c000701060007010c000701050007010e000701040007010e00070103000701100007010200070110000701010007011200070107011200070106011400060106011400060106011400060107011200070100010100070110000701030007010e000701050007010c000701070007010a00070109000701080007010b000701060007010d000701040007010f0007010200070111000e01'),
		bytes(hex'080010010f0012010e000801020008010d000801040008010c000801040008010b000801060008010a0008010600080109000801080008010800080108000801070008010a000801060008010a000801050008010c000801040008010c000801030008010e000801020008010e00080101000801100008010801100008010701120007010701120007010601140006010601140006010601140006010701120007010801100008010001010008010e000801030008010c000801050008010a000801070008010800080109000801060008010b000801040008010d000801020008010f001001'),
		bytes(hex'070012010d0014010c000901020009010b000901040009010a000901040009010900090106000901080009010600090107000901080009010600090108000901050009010a000901040009010a000901030009010c000901020009010c000901010009010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010001010009010c000901030009010a0009010500090108000901070009010600090109000901040009010b000901020009010d001201'),
		bytes(hex'060014010b0016010a000a0102000a0109000a0104000a0108000a0104000a0107000a0106000a0106000a0106000a0105000a0108000a0104000a0108000a0103000a010a000a0102000a010a000a0101000a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a01000101000a010a000a0103000a0108000a0105000a0106000a0107000a0104000a0109000a0102000a010b001401'),
		bytes(hex'050016010900180108000b0102000b0107000b0104000b0106000b0104000b0105000b0106000b0104000b0106000b0103000b0108000b0102000b0108000b0101000b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b01000101000b0108000b0103000b0106000b0105000b0104000b0107000b0102000b0109001601'),
		bytes(hex'0400180107001a0106000c0102000c0105000c0104000c0104000c0104000c0103000c0106000c0102000c0106000c0101000c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c01000101000c0106000c0103000c0104000c0105000c0102000c0107001801'),
		bytes(hex'03001a0105001c0104000d0102000d0103000d0104000d0102000d0104000d0101000d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d01000101000d0104000d0103000d0102000d0105001a01'),
		bytes(hex'02001c0103001e0102000e0102000e0101000e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e01000101000e0102000e0103001c01'),
		bytes(hex'01001e01010020010f0102000f010e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e010f0102000f01000101001e01'),
		bytes(hex'200120010f0102000f010e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e010f0102000f0120010001'),
		bytes(hex'0e0104000e010d010100040101000d010d01010001010200010101000d010c01010001010400010101000c010c01010001010400010101000c010b01010001010600010101000b010b01010001010600010101000b010a01010001010800010101000a010a01010001010800010101000a010901010001010a000101010009010901010001010a000101010009010801010001010c000101010008010801010001010c000101010008010701010001010e000101010007010701010001010e000101010007010601010001011000010101000601060101000101100001010100060105010100010112000101010005010501010001011200010101000501040101000101140001010100040104010100010114000101010004010401010001011400010101000401050101000101120001010100050106010100010110000101010006010701010001010e000101010007010801010001010c000101010008010901010001010a000101010009010a01010001010800010101000a010b01010001010600010101000b010c01010001010400010101000c010d01010001010200010101000d010e010100020101000e010001'),
		bytes(hex'0c01010001010400010101000c010b0101000101010004010100010101000b010b010100010101000101020001010100010101000b010a010100010101000101040001010100010101000a010a010100010101000101040001010100010101000a0109010100010101000101060001010100010101000901090101000101010001010600010101000101010009010801010001010100010108000101010001010100080108010100010101000101080001010100010101000801070101000101010001010a0001010100010101000701070101000101010001010a0001010100010101000701060101000101010001010c0001010100010101000601060101000101010001010c0001010100010101000601050101000101010001010e0001010100010101000501050101000101010001010e0001010100010101000501040101000101010001011000010101000101010004010401010001010100010110000101010001010100040103010100010101000101120001010100010101000301030101000101010001011200010101000101010003010201010001010100010114000101010001010100020102010100010101000101140001010100010101000201020101000101010001011400010101000101010002010301010001010100010112000101010001010100030104010100010101000101100001010100010101000401050101000101010001010e0001010100010101000501060101000101010001010c0001010100010101000601070101000101010001010a000101010001010100070108010100010101000101080001010100010101000801090101000101010001010600010101000101010009010a010100010101000101040001010100010101000a010b010100010101000101020001010100010101000b010c0101000101010002010100010101000c010001'),
		bytes(hex'0a010100010101000101040001010100010101000a01090101000101010001010100040101000101010001010100090109010100010101000101010001010200010101000101010001010100090108010100010101000101010001010400010101000101010001010100080108010100010101000101010001010400010101000101010001010100080107010100010101000101010001010600010101000101010001010100070107010100010101000101010001010600010101000101010001010100070106010100010101000101010001010800010101000101010001010100060106010100010101000101010001010800010101000101010001010100060105010100010101000101010001010a00010101000101010001010100050105010100010101000101010001010a00010101000101010001010100050104010100010101000101010001010c00010101000101010001010100040104010100010101000101010001010c00010101000101010001010100040103010100010101000101010001010e00010101000101010001010100030103010100010101000101010001010e0001010100010101000101010003010201010001010100010101000101100001010100010101000101010002010201010001010100010101000101100001010100010101000101010002010101010001010100010101000101120001010100010101000101020001010100010101000101010001011200010101000101010001010200000101000101010001010100010114000101010001010100010102000101010001010100010114000101010001010100010102000101010001010100010114000101010001010100010101000101010001010100010101000101120001010100010101000101020002010100010101000101010001011000010101000101010001010100020103010100010101000101010001010e00010101000101010001010100030104010100010101000101010001010c00010101000101010001010100040105010100010101000101010001010a0001010100010101000101010005010601010001010100010101000101080001010100010101000101010006010701010001010100010101000101060001010100010101000101010007010801010001010100010101000101040001010100010101000101010008010901010001010100010101000101020001010100010101000101010009010a01010001010100010101000201010001010100010101000a010001'),
		bytes(hex'0801010001010100010101000101040001010100010101000101010008010701010001010100010101000101010004010100010101000101010001010100070107010100010101000101010001010100010102000101010001010100010101000101010007010601010001010100010101000101010001010400010101000101010001010100010101000601060101000101010001010100010101000101040001010100010101000101010001010100060105010100010101000101010001010100010106000101010001010100010101000101010005010501010001010100010101000101010001010600010101000101010001010100010101000501040101000101010001010100010101000101080001010100010101000101010001010100040104010100010101000101010001010100010108000101010001010100010101000101010004010301010001010100010101000101010001010a000101010001010100010101000101010003010301010001010100010101000101010001010a000101010001010100010101000101010003010201010001010100010101000101010001010c000101010001010100010101000101010002010201010001010100010101000101010001010c000101010001010100010101000101010002010101010001010100010101000101010001010e00010101000101010001010100010102000101010001010100010101000101010001010e00010101000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010102000101010001010100010101000101100001010100010101000101010001010100010101000101010001010100010112000101010001010100010102000101010001010100010101000101120001010100010101000101020000010100010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010100010101000101010001010100010112000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010101000101010001010100010101000101010001010e00010101000101010001010100010102000201010001010100010101000101010001010c000101010001010100010101000101010002010301010001010100010101000101010001010a000101010001010100010101000101010003010401010001010100010101000101010001010800010101000101010001010100010101000401050101000101010001010100010101000101060001010100010101000101010001010100050106010100010101000101010001010100010104000101010001010100010101000101010006010701010001010100010101000101010001010200010101000101010001010100010101000701080101000101010001010100010101000201010001010100010101000101010008010001'),
		bytes(hex'060101000101010001010100010101000101040001010100010101000101010001010100060105010100010101000101010001010100010101000401010001010100010101000101010001010100050105010100010101000101010001010100010101000101020001010100010101000101010001010100010101000501040101000101010001010100010101000101010001010400010101000101010001010100010101000101010004010401010001010100010101000101010001010100010104000101010001010100010101000101010001010100040103010100010101000101010001010100010101000101060001010100010101000101010001010100010101000301030101000101010001010100010101000101010001010600010101000101010001010100010101000101010003010201010001010100010101000101010001010100010108000101010001010100010101000101010001010100020102010100010101000101010001010100010101000101080001010100010101000101010001010100010101000201010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200000101000101010001010100010101000101010001010c0001010100010101000101010001010100010102000101010001010100010101000101010001010c0001010100010101000101010001010100010101000101010001010100010101000101010001010e00010101000101010001010100010102000101010001010100010101000101010001010e00010101000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010102000101010001010100010101000101100001010100010101000101010001010100010101000101010001010100010112000101010001010100010102000101010001010100010101000101120001010100010101000101020000010100010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010100010101000101010001010100010112000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010101000101010001010100010101000101010001010e0001010100010101000101010001010200000101000101010001010100010101000101010001010c000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200020101000101010001010100010101000101010001010800010101000101010001010100010101000101010002010301010001010100010101000101010001010100010106000101010001010100010101000101010001010100030104010100010101000101010001010100010101000101040001010100010101000101010001010100010101000401050101000101010001010100010101000101010001010200010101000101010001010100010101000101010005010601010001010100010101000101010001010100020101000101010001010100010101000101010006010001'),
		bytes(hex'040101000101010001010100010101000101010001010400010101000101010001010100010101000101010004010301010001010100010101000101010001010100010101000401010001010100010101000101010001010100010101000301030101000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000301020101000101010001010100010101000101010001010100010104000101010001010100010101000101010001010100010101000201020101000101010001010100010101000101010001010100010104000101010001010100010101000101010001010100010101000201010101000101010001010100010101000101010001010100010106000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101060001010100010101000101010001010100010101000101020000010100010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200000101000101010001010100010101000101010001010c0001010100010101000101010001010100010102000101010001010100010101000101010001010c0001010100010101000101010001010100010101000101010001010100010101000101010001010e00010101000101010001010100010102000101010001010100010101000101010001010e00010101000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010102000101010001010100010101000101100001010100010101000101010001010100010101000101010001010100010112000101010001010100010102000101010001010100010101000101120001010100010101000101020000010100010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010100010101000101010001010100010112000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010101000101010001010100010101000101010001010e0001010100010101000101010001010200000101000101010001010100010101000101010001010c000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200000101000101010001010100010101000101010001010100010108000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101060001010100010101000101010001010100010101000101020002010100010101000101010001010100010101000101010001010400010101000101010001010100010101000101010001010100020103010100010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010100030104010100010101000101010001010100010101000101010002010100010101000101010001010100010101000101010004010001'),
		bytes(hex'02010100010101000101010001010100010101000101010001010400010101000101010001010100010101000101010001010100020101010100010101000101010001010100010101000101010001010100040101000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010100010102000001010001010100010101000101010001010100010101000101010001010400010101000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101040001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010106000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101060001010100010101000101010001010100010101000101020000010100010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200000101000101010001010100010101000101010001010c0001010100010101000101010001010100010102000101010001010100010101000101010001010c0001010100010101000101010001010100010101000101010001010100010101000101010001010e00010101000101010001010100010102000101010001010100010101000101010001010e00010101000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010102000101010001010100010101000101100001010100010101000101010001010100010101000101010001010100010112000101010001010100010102000101010001010100010101000101120001010100010101000101020000010100010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010100010101000101010001010100010112000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010101000101010001010100010101000101010001010e0001010100010101000101010001010200000101000101010001010100010101000101010001010c000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a0001010100010101000101010001010100010102000001010001010100010101000101010001010100010101000101080001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010600010101000101010001010100010101000101010001010200000101000101010001010100010101000101010001010100010101000101040001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101020001010100010101000101010001010100010101000101010001010200020101000101010001010100010101000101010001010100010101000201010001010100010101000101010001010100010101000101010002010001'),
		bytes(hex'0100010101000101010001010100010101000101010001010100010104000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100040101000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010100010102000001010001010100010101000101010001010100010101000101010001010400010101000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101040001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010106000101010001010100010101000101010001010100010102000101010001010100010101000101010001010100010101000101060001010100010101000101010001010100010101000101020000010100010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200010101000101010001010100010101000101010001010a000101010001010100010101000101010001010200000101000101010001010100010101000101010001010c0001010100010101000101010001010100010102000101010001010100010101000101010001010c0001010100010101000101010001010100010101000101010001010100010101000101010001010e00010101000101010001010100010102000101010001010100010101000101010001010e00010101000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010102000101010001010100010101000101100001010100010101000101010001010100010101000101010001010100010112000101010001010100010102000101010001010100010101000101120001010100010101000101020000010100010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010200010101000101010001011400010101000101010001010100010101000101010001010100010112000101010001010100010102000001010001010100010101000101010001011000010101000101010001010100010101000101010001010100010101000101010001010e0001010100010101000101010001010200000101000101010001010100010101000101010001010c000101010001010100010101000101010001010100010101000101010001010100010101000101010001010a00010101000101010001010100010101000101020000010100010101000101010001010100010101000101010001010800010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010106000101010001010100010101000101010001010100010102000001010001010100010101000101010001010100010101000101010001010400010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010100010101000101010001010200010101000101010001010100010101000101010001010100010102000001010001010100010101000101010001010100010101000101010001010100020101000101010001010100010101000101010001010100010101000101'),
		bytes(hex'0501030003010300040103000301030005010501020004010200060102000401020005010401030003010300020102000201030003010300040104010200040102000201040002010200040102000401030103000301030002010400020103000301030003010301020004010200020106000201020004010200030102010300030103000201060002010300030103000201020102000401020002010800020102000401020002010101030003010300020108000201030003010400010102000401020002010a000201020004010300000103000301030002010a0002010300030105000401020002010c0002010200040104000301030002010c0002010300030103000401020002010e0002010200040102000301030002010e00020103000301010004010200020110000201020004010301030002011000020103000301030102000201120002010200030102010300020112000201030002010201020002011400020102000201010103000201140002010400010103000201140002010400020103000201120002010300020103010300020110000201030003010401030002010e00020103000401000101000401030002010c0002010300040103000401030002010a00020103000401050004010300020108000201030004010300010103000401030002010600020103000401040002010300040103000201040002010300040103000201030103000401030002010200020103000401030003010401030004010300040103000401030004010001')
	];

	string[] public levels_traits = [
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		''
	];

	uint8[] public levels_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];

	///////////////////////////////////////
	// misc
	bytes[] public misc = [
		bytes(hex'6f0002251e0002251d0004251c0004251b0006251a000625190008251800082517000a2516000325040003251500032506000325140003250200022502000325130007250300042512000625030005251100072502000725100010250f0008250200082510000625020006251000022502000a25020002250f0003250200062502000325110004250200022502000425130005250200052515000a2517000825190006251b0004251d000225')
	];

	string[] public misc_traits = [
		''
	];
}