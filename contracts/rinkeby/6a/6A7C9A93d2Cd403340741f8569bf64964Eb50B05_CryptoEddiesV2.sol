// SPDX-License-Identifier: MIT

/*
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  CRYPTO EDDIES  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   by @eddietree  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  (LET TRY THIS AGAIN SHALL WE?) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'....................................:0WWWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNo.                                    ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWWNd'..;looooooooooooooooooooooooooooooooooooc,..;OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNWNl   ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.  .kWNNNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNd,',:llldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxollc;'';OWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ,kOOOOOOOOOOO0000000KKKKKKKKKKKKKKKKK00000000Kx.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKOl;;ckKKKKKKKKKKKKKKKKkc;;lOXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKk'  .oKKKKKKKKKKKKKKKXo.  .xXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNNNXxllc.   ;kOOOOOO0KKKKKKK0occc::::cxKKKKKKKkc:::cccoOKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWMMX;       ;kOOOOOO0KKKKKKKKKKXO,    cKKKKKKKl   'OXXXKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXNNNKxoolc:::::::okOOOOOO0KKKKKKK0occc:::::xKKKKKKKxc:::cccoOKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKK0OOOOOOO0KKKKKKXk'  .oKKKKKKKKKKKKKKXKo.  .xKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKK000OOOO0KKKKKKKOl;;:kKKKKKKKKK0000KKKkc;;lOKKOl;;:lddd0NNNXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKK0kkkOKKKKKKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXNWWKo;;:coooooookKKKK0000KKKKKKKKKKK0xooookKKKxc::d0KKOdood0KKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWWMX;       :0KKKKKKKKKKKKKKKKKXO,    cKKKc   ;0KXo.  .xKKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXo,,,,,,,coodkKKKKKKKKKKKKKKK0c''',codo:''':oddc,'':kXKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNl   ;0KKKKKKKKKKKKKKKKKKKO;   :0K0l.  ,kKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNx,'':dddkKKKKKKKKKKKKKKKX0l..'oKKKd'..:OXKKKKK0kddo:'',xWWWNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNd.  ,OXKKKKKKKKKKKKKKKK000KKKKK0000KKKKKKKk,  .dNNNNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXNXK000o'..;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..,kWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWMWo...;k0Ol.                                    'xXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXKK0l...c0KKd'............................     ...,OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNl...:kOO0KKX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.  .xKKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0c...cKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKK0OOOl.  '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXc..'cxkk0KKKo...:OKKKKKKKOkkO0KKKK0kkO0KKKo'...   '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   lKKKKKKKl.  ,x000KKKKOkkk0KKKKOkkk0KKKl       ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   cKKKKKKK0xxxl'..;kXKKK000KKKKKK000KKKKl   .oxxo,'.:OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;  .c000KKKKKKKKo.  .xKKKKKKKKKKKKKKKKKKKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXNNX0kkkc'''oKKKKKKKo.  .xKK0dlloxkkkkkkkk0KKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMNc   :0KKKKKKo.  .xKKOl:::oxxxxxxxxOKKKl   'kKKd.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNNNX0xxxc,,,,,,,;loox0KKOl:::oxxxxxxxxOKKKl    ',,:oxxkKNNNXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNMMWl       'kXKKKKKOl;::oxxxxxxxxOKKKl       '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNNN0ddd;   'OXXkc,,;;:::oxxxxxxxxOKKKl   .lddkKNNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OXXd.   ':::oxxxxxxxxOKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKXx.  .lOOO0KKK0o,,,oKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKKd.  .kMMMMMMMNc   :0XKl   ,KMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'..:OXXk;..;OWWWWWWWNo...lKKKd'..cKWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoDeddies.sol";
import "./CryptoEddies.sol"; // OG

/// @title CryptoEddies
/// @author Eddie Lee
/// @notice CryptoEddies is an 100% on-chain experimental NFT character project.
contract CryptoEddiesV2 is ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 3500;
    uint public constant MAX_HP = 5;

    CryptoDeddies public contractGhost;
    CryptoEddies public contractEddieOG;

    address public contractGarbage;

    bool public revealed = false;

    mapping(uint256 => uint256) public ogTokenId; // tokenId=>ogTokenId (From original contract)
    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public hp; // health power

    // events
    event EddieDied(uint256 indexed tokenId); // emitted when an HP goes to zero
    event EddieRerolled(uint256 indexed tokenId); // emitted when an Eddie gets re-rolled
    event EddieSacrificed(uint256 indexed tokenId); // emitted when an Eddie gets sacrificed

    constructor(address _contractEddieOG) ERC721A("CryptoEddiesV2", "EDDIEV2") {
        contractEddieOG = CryptoEddies(_contractEddieOG);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function claimMany(uint256[] calldata tokenIds) external {
        // clamp the total minted
        require(_totalMinted() + tokenIds.length <= MAX_TOKEN_SUPPLY );

        uint256 num = tokenIds.length;
        uint256 startTokenId = _startTokenId() + _totalMinted();

        for (uint256 i = 0; i < num; ++i) {
            uint256 originalTokenId = tokenIds[i];
            uint256 newTokenId = startTokenId + i;

            // check ownership
            require(msg.sender == contractEddieOG.ownerOf(originalTokenId), "Not yours");
            require(ogTokenId[newTokenId] == 0, "Claimed");

            // transfer each token to garbage contract
            contractEddieOG.transferFrom(msg.sender, contractGarbage, originalTokenId);
            //contractEddieOG.burnSacrifice(originalTokenId);

            // save data on new token
            ogTokenId[newTokenId] = originalTokenId;
            hp[newTokenId] = MAX_HP;
            _saveSeed(newTokenId);
        }

        // mint
        _safeMint(msg.sender, tokenIds.length);
    }

    function _rerollEddie(uint256 tokenId) verifyTokenId(tokenId) private {
        require(revealed == true, "Not revealed");
        require(hp[tokenId] > 0, "No HP");
        require(msg.sender == ownerOf(tokenId), "Not yours");

        _saveSeed(tokenId);   
        _takeDamageHP(tokenId, msg.sender);

        emit EddieRerolled(tokenId);
    }

    /// @notice Rerolls the visuals and stats of one CryptoEddie, deals -1 HP damage!
    /// @param tokenId The token ID for the CryptoEddie to reroll
    function rerollEddie(uint256 tokenId) external {
        _rerollEddie(tokenId);
    }

    function rerollEddieMany(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _rerollEddie(tokenId);
        }
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    // @notice Destroys your CryptoEddie, spawning a ghost
    /// @param tokenId The token ID for the CryptoEddie
    function burnSacrifice(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not yours");
        _burn(tokenId);

        // if not already dead, force kill and spawn ghost
        if (hp[tokenId] > 0) {
            hp[tokenId] = 0;
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(msg.sender, tokenId, seeds[tokenId]);
            }
        }

        emit EddieSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
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

    function setContractGarbage(address newAddress) external onlyOwner {
        contractGarbage = newAddress;
    }

    function setContractEddieOG(address newAddress) external onlyOwner {
        contractEddieOG = CryptoEddies(newAddress);
    }

    function setContractGhost(address newAddress) external onlyOwner {
        contractGhost = CryptoDeddies(newAddress);
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // props to @cygaar_dev
    error SteveAokiNotAllowed();
    address public constant STEVE_AOKI_ADDRESS = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        if (to == STEVE_AOKI_ADDRESS) { // sorry Mr. Aoki
            revert SteveAokiNotAllowed();
        }

        if (from == address(0) || to == address(0))  // bypass for minting and burning
            return;

        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
            //require(hp[tokenId] > 0, "No more HP"); // soulbound?

            // transfers reduces HP
            _takeDamageHP(tokenId, from);
        }
    }

    function _takeDamageHP(uint256 tokenId, address mintGhostTo) private verifyTokenId(tokenId){
        if (hp[tokenId] == 0) // to make sure it doesn't wrap around
            return;

        hp[tokenId] -= 1;

        if (hp[tokenId] == 0) {
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(mintGhostTo, tokenId, seeds[tokenId]);
            }
        }
    }

    function rewardHP(uint256 tokenId, uint hpRewarded) external onlyOwner verifyTokenId(tokenId) {
        require(hp[tokenId] > 0, "Already dead");
        hp[tokenId] += hpRewarded;

        if (hp[tokenId] > MAX_HP) 
            hp[tokenId] = MAX_HP;
    }

    function rewardManyHP(uint256[] calldata tokenIds, uint hpRewarded) onlyOwner external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            if (hp[tokenId] > 0 ) { // not dead
                hp[tokenId] += hpRewarded;

                if (hp[tokenId] > MAX_HP) 
                    hp[tokenId] = MAX_HP;
            }
        }
    }

    /// @notice Retrieves the HP
    /// @param tokenId The token ID for the CryptoEddie
    /// @return hp the amount of HP for the CryptoEddie
    function getHP(uint256 tokenId) external view verifyTokenId(tokenId) returns(uint){
        return hp[tokenId];
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string[6] memory lookup = [  '0', '1', '2', '3', '4', '5'];
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(ogTokenId[tokenId]),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental NFT character project with unique functionality, inspired by retro Japanese RPGs.",',
                    '"attributes":[',
                        contractEddieOG.getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        '{"trait_type":"HP", "value":',lookup[hp[tokenId]],', "max_value":',lookup[MAX_HP],'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(ogTokenId[tokenId]),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental character art project, chillin on the Ethereum blockchain.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (revealed) 
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
          '{"trait_type":"Determination", "display_type": "number", "value":', lookup[_randStat(seed, 2, 2, 10)], '},',
          '{"trait_type":"Love", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Cringe", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Bonk", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Magic Defense", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},'
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

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';

import "./EddieData.sol";

contract EddieRenderer is EddieData {

  string[] public bgPaletteColors = [
    'b5eaea', 'b5c7ea', 'eab6b5', 'c3eab5', 'eab5d9',
    'fafc51', '3a89ff', '5eff8f', 'ff6efa', 'a1a1a1'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint head;
    uint eyes;
    uint mouth;
    uint hair;
  }

  function getSVG(uint256 seed) external view returns (string memory) {
    return _getSVG(seed);
  }

  function _getSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(heads[data.head], fullPalettes),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getGhostSVG(uint256 seed) external view returns (string memory) {
    return _getGhostSVG(seed);
  }

  function _getGhostSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#3b89ff"/>',
      //_renderRects(bodies[data.body], fullPalettes),
      //_renderRects(heads[data.head], fullPalettes),
      _renderRects(misc[0], fullPalettes), // ghost body
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(misc[1], fullPalettes), // ghost body
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
      '{"trait_type":"Outfit", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Class", "value":"', heads_traits[data.head], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},',
      '{"trait_type":"Head", "value":"', hair_traits[data.hair], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        uint8 y = uint8(drawIndex / 24);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      head: heads_indices[(seed/3) % heads_indices.length],
      eyes: eyes_indices[(seed/4) % eyes_indices.length],
      mouth: mouths_indices[(seed/5) % mouths_indices.length],
      hair: hair_indices[(seed/6) % hair_indices.length]
    });
  }
}

// SPDX-License-Identifier: MIT

/*
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000  CRYPTO EDDIE GHOST 0000000000000000000000000000000000000
000000000000000000000000000000000000000000    by @eddietree    0000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK000000000000000000000000000
00000000000000000000000000000000KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK000000000000000000000000000
00000000000000000000000000000KXXKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0XXKK00000000000000000000000
0000000000000000000000000000KNWMK;                                     .kMMWX00000000000000000000000
000000000000000000000000KKKKKOOOxc''''''''''''''''''''''''''''''''''''';dOOO0KKKK0000000000000000000
000000000000000000000000XWWW0,  .xNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO,  .dWWWX0000000000000000000
000000000000000000000KKKK000x;..,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..'o000KKKKK000000000000000
00000000000000000000XWWWk'..,kXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXX0c...oNWWXK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWMMMMWWWWWWWWWWWK:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMWKkxxxxxxxxxxxxxxxxKWMWKkxxxxxxxxxxdc,,;xNMMNK00000000000000
00000000000000000000XWMWx.  .OMMMMMMMMMWWOlccccccccccccccclkNWW0lcccccccccccccclkNMMNK00000000000000
0000000000000000KNNXkc::'   .lkkkkkkkkkkxdlccokO0xl;..';cccoxkxdlccok00x;..';cclkNMMNK00000000000000
0000000000000000NWMWo       .;cccccccccccccccxXWM0o'   ,cccccccccccdXWM0,   ,cclkNMMNK00000000000000
000000000000KXXXxlclloolollodkOOOOOOOOOOOdlccxXWM0o'   ,ccldkOOxlccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNWMNc   cNMMMMMMMMMMMMMMMMMMWOlccxXWM0o'   ,cclONWW0lccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMWOlccokOOxl;..';cclONMW0lccokOOx;..';cccloookKXXK00000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMW0lccccccccccccccclONWW0lccccccccccccccc'   ;XMMNK0000000000
00000000000KXNNXd:;:ldxxxxxxONMMMMMMMMMMWKkxxo;,,;coxxxxxxkKWMWXkxxxxxxxxxxxxxxx;   ;XMMNK0000000000
000000000000000KXWWNo.      'OMMMMMMMMMMMMWWWx.  .cOWWWWWWWWMMMMWWWWWWWWWWWWWWWNl   ;XMMNK0000000000
0000000000000000XNNNx;,,,,,,:dkkOXMMMMMMMMMMM0:,,:ldkkkO000O000Okkk0WMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNNNNNNNO'  .kWMMMMMMMMMMWWNNOo,  .',,,,;,,'.  ;KMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNWWWWWW0:..,d000XMMMMMMMMMMMKxc..'',,,,,,,''..cKMMMMMMWX00Ol'..lKWWNK0000000000
0000000000000000000000KKK0K0KXXX0:. .dWMMMMMMMMMMWWNXX0l,,,,,,,l0XXNWMMMMMMXc...lKNXXK0K000000000000
0000000000000000000000000KKKKKKKO:...l0KKKKKKKKKKKKKKKOc'''''''cOKKKKKKKKKKOc...oNWWXK00000000000000
000000000000000000000000KNWW0;..'dKK0l.................         ...........'oKKKKKKK0000000000000000
00000000000000000000000KKXXXk,..'kWMNo..       ... .. .............      . .xWWWX0000000000000000000
00000000000000000000XNWNk;..;x00KNMMWX00000000000000000000000000000o.  .o0000KKKK0000000000000000000
00000000000000000000XNNNx.  '0MMMWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMWWNNk.  .kMMWX00000000000000000000000
0000000000000000XNNNx;,,cxkk0NMMXo,,;kWMMMMMMMMMMMMMMMMMMMMMMMWO:,,.   .kMMWX00000000000000000000000
000000000000000KNWMWo   ;KMMMMMMK;   oNWWMMMMMMMMMMMMMMMMMMMMMWd.      .kWWWX00000000000000000000000
0000000KXNNNNNNNWMMWo   ,KMMMMMMW0xddl:;:xNMMMMMMMMMMMMMMMMMMMWd.  .lxddc;;ckXNNK0000000000000000000
0000000KWMMMMMMMMMMWo   ;KMMMMMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
000KXNN0occccccl0WMWKdoolcccdXMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0'  .dWMWX0000000000000000000
000XWMMO.       oWMMMMMMx.  .OMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
XXXOollllllllllllllllllllllllllllllllllllkWMMMMMMMMMMMMMMMMMMMWd.  .:lllllloOXXXK0000000000000000000
MMWx.  '0MMMMMMNc       ;KMMO'       oWMMMMMMMMMMMMMMMMMMMMMMMWd.      .kMMWX00000000000000000000000
NNNOl::coddxXMMWkc::::::dNMMXo::::::cOWMMMMMMMMMMMMMMMMMMMMMMMWd.  .,::l0NNXK00000000000000000000000
000XWWWO.  .kWMMMWWMMWMMMMMMMWWWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.  ,0WWNK000000000000000000000000000
000KNNN0c,,:oxxkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkxo;,;lKNNXK000000000000000000000000000
0000000KNWW0;  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.  :KWWNK0000000000000000000000000000000
0000000KWMMK,   oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   :XMMNK0000000000000000000000000000000
*/
// thx CB1 for the name

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";

contract CryptoDeddies is ERC721A, Ownable {
    struct GhostData {
        uint256 eddieTokenId;
        uint256 eddieTokenSeed;
    }

    EddieRenderer public contractRenderer;

    mapping(uint256 => GhostData) public ghostData; // tokenid => ghost data
    error EddieGhostIsSoulbound();
    event EddieGhostSpawned(uint256 indexed tokenId, uint256 indexed eddieTokenId, uint256 indexed eddieTokenSeed); // emitted when an HP goes to zero

    constructor(address _contractRenderer) ERC721A("CryptoDeddies", "DEDDIE") {
        contractRenderer = EddieRenderer(_contractRenderer);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function spawnGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external {
        require(msg.sender == address(contractRenderer), "Only callable from contract");
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function spawnGhostAdmin(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external onlyOwner {
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function _mintGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) private {
        _safeMint(to, 1);

        // save ghost data
        uint256 tokenId = _totalMinted();
        ghostData[tokenId] = GhostData({
            eddieTokenId: eddieTokenId,
            eddieTokenSeed: eddieTokenSeed
        });

        emit EddieGhostSpawned(tokenId, eddieTokenId, eddieTokenSeed);
    }

    // block transfers (soulbound)
    function _beforeTokenTransfers(address from, address, uint256, uint256) internal pure override {
        //if (from != address(0) && to != address(0)) {
        if (from != address(0)) { // not burnable
            revert EddieGhostIsSoulbound();
        }
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = EddieRenderer(newAddress);
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        GhostData memory ghost = ghostData[tokenId];
        uint256 eddieTokenId = ghost.eddieTokenId;
        uint256 seed = ghost.eddieTokenSeed;

        string memory image = contractRenderer.getGhostSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoDeddie Ghost #', Strings.toString(eddieTokenId),'",',
                    '"description": "CryptoDeddie Ghost is a memorialized ghost of your original CryptoEddie, forever soulbound to your wallet.",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        '{"trait_type":"Dead", "value":"True"}, {"trait_type":"Soulbound", "value":"True"}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

/*
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  CRYPTO EDDIES  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   by @eddietree  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'....................................:0WWWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNo.                                    ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWWNd'..;looooooooooooooooooooooooooooooooooooc,..;OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNWNl   ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.  .kWNNNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNd,',:llldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxollc;'';OWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ,kOOOOOOOOOOO0000000KKKKKKKKKKKKKKKKK00000000Kx.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKOl;;ckKKKKKKKKKKKKKKKKkc;;lOXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKk'  .oKKKKKKKKKKKKKKKXo.  .xXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNNNXxllc.   ;kOOOOOO0KKKKKKK0occc::::cxKKKKKKKkc:::cccoOKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWMMX;       ;kOOOOOO0KKKKKKKKKKXO,    cKKKKKKKl   'OXXXKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXNNNKxoolc:::::::okOOOOOO0KKKKKKK0occc:::::xKKKKKKKxc:::cccoOKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKK0OOOOOOO0KKKKKKXk'  .oKKKKKKKKKKKKKKXKo.  .xKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKK000OOOO0KKKKKKKOl;;:kKKKKKKKKK0000KKKkc;;lOKKOl;;:lddd0NNNXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKK0kkkOKKKKKKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXNWWKo;;:coooooookKKKK0000KKKKKKKKKKK0xooookKKKxc::d0KKOdood0KKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWWMX;       :0KKKKKKKKKKKKKKKKKXO,    cKKKc   ;0KXo.  .xKKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXo,,,,,,,coodkKKKKKKKKKKKKKKK0c''',codo:''':oddc,'':kXKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNl   ;0KKKKKKKKKKKKKKKKKKKO;   :0K0l.  ,kKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNx,'':dddkKKKKKKKKKKKKKKKX0l..'oKKKd'..:OXKKKKK0kddo:'',xWWWNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNd.  ,OXKKKKKKKKKKKKKKKK000KKKKK0000KKKKKKKk,  .dNNNNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXNXK000o'..;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..,kWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWMWo...;k0Ol.                                    'xXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXKK0l...c0KKd'............................     ...,OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNl...:kOO0KKX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.  .xKKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0c...cKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKK0OOOl.  '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXc..'cxkk0KKKo...:OKKKKKKKOkkO0KKKK0kkO0KKKo'...   '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   lKKKKKKKl.  ,x000KKKKOkkk0KKKKOkkk0KKKl       ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   cKKKKKKK0xxxl'..;kXKKK000KKKKKK000KKKKl   .oxxo,'.:OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;  .c000KKKKKKKKo.  .xKKKKKKKKKKKKKKKKKKKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXNNX0kkkc'''oKKKKKKKo.  .xKK0dlloxkkkkkkkk0KKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMNc   :0KKKKKKo.  .xKKOl:::oxxxxxxxxOKKKl   'kKKd.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNNNX0xxxc,,,,,,,;loox0KKOl:::oxxxxxxxxOKKKl    ',,:oxxkKNNNXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNMMWl       'kXKKKKKOl;::oxxxxxxxxOKKKl       '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNNN0ddd;   'OXXkc,,;;:::oxxxxxxxxOKKKl   .lddkKNNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OXXd.   ':::oxxxxxxxxOKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKXx.  .lOOO0KKK0o,,,oKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKKd.  .kMMMMMMMNc   :0XKl   ,KMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'..:OXXk;..;OWWWWWWWNo...lKKKd'..cKWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoDeddies.sol";

/// @title CryptoEddies
/// @author Eddie Lee
/// @notice CryptoEddies is an 100% on-chain experimental NFT character project.
contract CryptoEddies is EddieRenderer, ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 3500;

    // 3 pricing tiers
    uint256 public tier0_price = 0.01 ether;
    uint256 public tier1_price = 0.015 ether;
    uint256 public tier2_price = 0.02 ether;
    uint256 public tier0_supply = 2000;
    uint256 public tier1_supply = 1000;

    uint256 public maxMintsPerPersonPublic = 150;
    uint256 public maxMintsPerPersonWhitelist = 1;
    uint public constant MAX_HP = 5;

    CryptoDeddies public contractGhost;

    enum MintStatus {
        CLOSED, // 0
        WHITELIST, // 1
        PUBLIC // 2
    }

    MintStatus public mintStatus = MintStatus.CLOSED;
    bool public revealed = false;

    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public hp; // health power

    // events
    event EddieDied(uint256 indexed tokenId); // emitted when an HP goes to zero
    event EddieRerolled(uint256 indexed tokenId); // emitted when an Eddie gets re-rolled
    event EddieSacrificed(uint256 indexed tokenId); // emitted when an Eddie gets sacrificed

    constructor() ERC721A("CryptoEddies", "EDDIE") {
    }

    modifier verifySupply(uint256 numEddiesToMint) {
        //require(tx.origin == msg.sender,  "No bots");
        require(numEddiesToMint > 0, "Mint at least 1");
        require(_totalMinted() + numEddiesToMint <= MAX_TOKEN_SUPPLY, "Exceeds max supply");

        _;
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function _mintEddies(address to, uint256 numEddiesToMint) private verifySupply(numEddiesToMint) {
        uint256 startTokenId = _startTokenId() + _totalMinted();
         for(uint256 tokenId = startTokenId; tokenId < startTokenId+numEddiesToMint; tokenId++) {
            _saveSeed(tokenId);
            hp[tokenId] = MAX_HP;
         }

         _safeMint(to, numEddiesToMint);
    }

    function reserveEddies(address to, uint256 numEddiesToMint) external onlyOwner {
        _mintEddies(to, numEddiesToMint);
    }

    function reserveEddiesToManyFolk(address[] calldata addresses, uint256 numEddiesToMint) external {
        uint256 num = addresses.length;
        for (uint256 i = 0; i < num; ++i) {
            address to = addresses[i];
            _mintEddies(to, numEddiesToMint);
        }
    }

    /// @notice Mints CryptoEddies into your wallet! payableAmount is the total amount of ETH to mint all numEddiesToMint (costPerCryptoEddie * numEddiesToMint)
    /// @param numEddiesToMint The number of CryptoEddies you want to mint
    function mintEddies(uint256 numEddiesToMint) external payable {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(msg.value >= _getPrice(numEddiesToMint), "Incorrect ether" );
        require(_numberMinted(msg.sender) + numEddiesToMint <= maxMintsPerPersonPublic, "Exceeds max mints");

        _mintEddies(msg.sender, numEddiesToMint);
    }

    function _rerollEddie(uint256 tokenId) verifyTokenId(tokenId) private {
        require(revealed == true, "Not revealed");
        require(hp[tokenId] > 0, "No HP");
        require(msg.sender == ownerOf(tokenId), "Not yours");

        _saveSeed(tokenId);   
        _takeDamageHP(tokenId, msg.sender);

        emit EddieRerolled(tokenId);
    }

    /// @notice Rerolls the visuals and stats of one CryptoEddie, deals -1 HP damage!
    /// @param tokenId The token ID for the CryptoEddie to reroll
    function rerollEddie(uint256 tokenId) external {
        _rerollEddie(tokenId);
    }

    function rerollEddieMany(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _rerollEddie(tokenId);
        }
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    // @notice Destroys your CryptoEddie, spawning a ghost
    /// @param tokenId The token ID for the CryptoEddie
    function burnSacrifice(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not yours");
        _burn(tokenId);

        // if not already dead, force kill and spawn ghost
        if (hp[tokenId] > 0) {
            hp[tokenId] = 0;
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(msg.sender, tokenId, seeds[tokenId]);
            }
        }

        emit EddieSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
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

    function _getPrice(uint256 numPayable) private view returns (uint256) {
        uint256 numMintedAlready = _totalMinted();

        return numPayable 
            * (numMintedAlready < tier0_supply ? 
                tier0_price 
                : ( (numMintedAlready < (tier0_supply+tier1_supply)) ? tier1_price : tier2_price));
    }

    function setPricing(uint256[] calldata pricingData) external onlyOwner {
        tier0_supply = pricingData[0];
        tier0_price = pricingData[1];

        tier1_supply = pricingData[2];
        tier1_price = pricingData[3];

        tier2_price = pricingData[4];

        require(tier0_supply + tier1_supply <= MAX_TOKEN_SUPPLY);
    }

    function setPublicMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxMints(uint256 _maxMintsPublic, uint256 _maxMintsWhitelist) external onlyOwner {
        maxMintsPerPersonPublic = _maxMintsPublic;
        maxMintsPerPersonWhitelist = _maxMintsWhitelist;
    }

    function setContractGhost(address newAddress) external onlyOwner {
        contractGhost = CryptoDeddies(newAddress);
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // props to @cygaar_dev
    error SteveAokiNotAllowed();
    address public constant STEVE_AOKI_ADDRESS = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        if (to == STEVE_AOKI_ADDRESS) { // sorry Mr. Aoki
            revert SteveAokiNotAllowed();
        }

        if (from == address(0) || to == address(0))  // bypass for minting and burning
            return;

        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
            //require(hp[tokenId] > 0, "No more HP"); // soulbound?

            // transfers reduces HP
            _takeDamageHP(tokenId, from);
        }
    }

    function _takeDamageHP(uint256 tokenId, address mintGhostTo) private verifyTokenId(tokenId){
        if (hp[tokenId] == 0) // to make sure it doesn't wrap around
            return;

        hp[tokenId] -= 1;

        if (hp[tokenId] == 0) {
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(mintGhostTo, tokenId, seeds[tokenId]);
            }
        }
    }

    function rewardHP(uint256 tokenId, uint hpRewarded) external onlyOwner verifyTokenId(tokenId) {
        require(hp[tokenId] > 0, "Already dead");
        hp[tokenId] += hpRewarded;

        if (hp[tokenId] > MAX_HP) 
            hp[tokenId] = MAX_HP;
    }

    function rewardManyHP(uint256[] calldata tokenIds, uint hpRewarded) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            if (hp[tokenId] > 0 ) { // not dead
                hp[tokenId] += hpRewarded;

                if (hp[tokenId] > MAX_HP) 
                    hp[tokenId] = MAX_HP;
            }
        }
    }

    /// @notice Retrieves the HP
    /// @param tokenId The token ID for the CryptoEddie
    /// @return hp the amount of HP for the CryptoEddie
    function getHP(uint256 tokenId) external view verifyTokenId(tokenId) returns(uint){
        return hp[tokenId];
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- MERKLE NERD STUFF --
    ///////////////////////////
    bytes32 public merkleRoot = 0x0;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool) {
        return _verifyMerkle(_proof, _leaf);
    }

    function verifyMerkleAddress(bytes32[] calldata _proof, address from) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return _verifyMerkle(_proof, leaf);
    }

    function mintEddiesMerkle(bytes32[] calldata _merkleProof, uint256 numEddiesToMint) external payable {
        require(mintStatus == MintStatus.WHITELIST || mintStatus == MintStatus.PUBLIC, "Merkle mint closed");
        
        uint256 numMintedAlready = _numberMinted(msg.sender);
        require(numMintedAlready + numEddiesToMint <= maxMintsPerPersonPublic, "Exceeds max mints");

        // calculate how much you need to pay beyond whitelisted amount
        uint256 numToMintFromWhitelist = 0;
        if (numMintedAlready < maxMintsPerPersonWhitelist) {
            numToMintFromWhitelist = (maxMintsPerPersonWhitelist - numMintedAlready);
        }

        // num to actually buy
        uint256 numToMintPayable = numEddiesToMint - numToMintFromWhitelist;
        require(msg.value >= _getPrice(numToMintPayable), "Incorrect ether sent" );
    
        // verify merkle        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyMerkle(_merkleProof, leaf), "Invalid proof");

        _mintEddies(msg.sender, numEddiesToMint);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string[6] memory lookup = [  '0', '1', '2', '3', '4', '5'];
        uint256 seed = seeds[tokenId];
        string memory image = _getSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental NFT character project with unique functionality, inspired by retro Japanese RPGs.",',
                    '"attributes":[',
                        _getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        '{"trait_type":"HP", "value":',lookup[hp[tokenId]],', "max_value":',lookup[MAX_HP],'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = _getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental character art project, chillin on the Ethereum blockchain.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (revealed) 
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
          '{"trait_type":"Determination", "display_type": "number", "value":', lookup[_randStat(seed, 2, 2, 10)], '},',
          '{"trait_type":"Love", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Cringe", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Bonk", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Magic Defense", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},'
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
// AUTOGENERATED FILE by @eddietree on Thu Aug 18 2022 01:31:47 GMT-0700 (Pacific Daylight Time)

pragma solidity ^0.8.0;

contract EddieData {
	string[] public fullPalettes = ['ff00ff', '000000', 'ffffff', 'ff0000', '00ff00', '0000ff', '65656e', '212124', '343438', '212123', 'f83a00', 'fff200', 'ff5900', '0096ff', '2e07f2', '1f1f21', '858ac7', 'e31e27', '7e00de', 'f200ff', '292929', 'f5368f', 'ffff00', 'ff8282', '599cff', 'b2e1f8', 'ff9696', 'ff4747', '919191', 'b8b8b8', 'ff5e00', 'ff995e', 'ff3300', 'd32027', 'f3e106', 'd46a6d', '172f3b', '163545', 'f73b3b', '2c7899', '3fabd9', '2e81a5', '2f82a6', '44b0de', '237843', '47a66b', 'f3f700', 'ba6047', 'a85740', '592f23', '44c3c9', 'ede068', 'ffed4f', '68b84d', '599e42', '038604', '9c9083', '7a7166', '696158', '7ddcff', '00bbff', '009bd4', '5ed4ff', 'edda9d', 'eda200', '004f24', '00c458', '00a44b', '00ad4e', 'ff9500', 'f7ff0f', 'eaf041', 'cfd60d', 'faf5aa', 'ced439', 'b5b535', 'ffa3a3', 'a37b46', '966930', '579aff', '217aff', '4eff00', 'fffc00', 'ffff26', '007dfc', '0067cf', 'fcca97', '8a633c', 'cb8d52', 'fcf0c6', '180d1f', 'a16010', 'e5a925', '3a3a3a', '2057a8', 'b82323', 'ff3030', '3c3c3c', '0004fa', '2b2b2b', 'ff0009', '3150d6', '7c541a', 'ba2b00', 'bfb731', '505050', '729144', '9aa6c1', '3f3556', 'd246e8', 'e74dff', '00974c', '9ec45c', '20d47a', 'eded61', '78573e', 'b89174', '2b478f', '0024ff', '363b3c', '202324', '3587ab', '0044ff', '0145fd', 'b4633b', 'b5643b', '40b2e6', '83c6e5', '115c52', 'ffcc99', '64c0e8', '3a8228', 'fcd502', '165c58', 'f7c328', '8a1212', '008787', '2c3aa8', '8a3c3c', 'e8fd4d', '439958', '5e83ec', '00a800', '006600', '404040', 'c5b2a0', 'fd8c69', 'f7e83e', 'f75a3e', 'fccf03', '68d4cc', 'be8ade', 'b778de', '568746', '67ab50', 'fce2a9', '6edbb7', 'fcb39d', '79dbba', 'c74832', '40cfbc', '7dd8ff', 'dbf4ff', '9ce1ff', 'fbdd97', 'f9de9a', 'f9de9b', 'fade9a', 'f9df9b', 'fadf9b', 'fade9b', 'f8dfa0', 'f8e0a0', 'f7e0a0', 'f5e1a6', 'f4e2a6', 'f5e2a6', 'f4e2a7', 'f5e2a7', 'f2e4ad', 'f3e4ad', 'f2e3ad', 'efe6b5', 'efe5b4', 'f0e5b5', 'efe6b4', 'efe5b5', 'ece8bc', 'ece9bd', 'ece8bd', 'ece9bc', 'e9ebc5', 'e8ebc5', 'e9eac5', 'e9ebc4', 'e6edcd', 'e5eecd', 'e5eece', 'e6eecd', 'e5edcd', 'e5edce', 'e2f0d5', 'e2efd6', 'e2f0d6', 'e2efd5', 'dff2de', 'dcf4e5', 'dcf4e4', 'dcf5e5', 'dbf4e5', 'dcf5e4', 'd9f7ec', 'd9f6ec', 'd7f9f2', 'd7f8f2', 'd6f8f2', 'd4f9f7', 'd4faf7', 'd3fbfb', 'b7c6e8', 'e5edff', 'fae848', 'fae248'];

	///////////////////////////////////////
	// eyes
	bytes[] public eyes = [
		bytes(hex'840003061700020616000206040001020d000106090701020a00040604070108040701020a0004060307010801070108030701020d0001060907010217000102'),
		bytes(hex'c400010201090100010113000102010903020200040a03000101090001020101010201090302010a010b020a0100020101020b000102010901020200030a0300010101020b0003021700010117000101'),
		bytes(hex'e300020e0300020e0d00040e0202030e0202010e0f00010e0202010e0100010e0202010e1000020e0300020e'),
		bytes(hex'd300010101020d00040201000402010101020a0004020205030202030102010101020d000102020501020100010202030102010101020d000402010004020101'),
		bytes(hex'e200040d0100040d0c00040d01020101030d01020101010d0f00010d01020101010d0100010d01020101010d0f00040d0100040d'),
		bytes(hex'e200040c0100040c0c00040c01020101030c01020101010c0f00010c01020101010c0100010c01020101010c0f00040c0100040c'),
		bytes(hex'e30001010400010113000101020001011300010104000101'),
		bytes(hex'df000b011000030102000102010111000301'),
		bytes(hex'df00050f0210020f0210010f0f00010f0210020f0210010f11000110020f01000110020f'),
		bytes(hex'df0003110212021302120213100001120213021202130112110001130212010001130212'),
		bytes(hex'e2000101010001010200010101000101110001010400010111000101010001010200010101000101'),
		bytes(hex'e200040101000301100001020201020001020201'),
		bytes(hex'e30001010400010111000101010001010200010101000101'),
		bytes(hex'e200030102000301110001020101020001020101'),
		bytes(hex'9c00070110000101060201010f0001010802010101020d00010102020101030201010102010101020a000401040201030302010101020d00010102020101030201010102010101020d00010103020301020201010f0001010602010111000601'),
		bytes(hex'9c00070110000101060201010f0001010802010101020d00010101020117010101170102011701010117010101020a00040102020118030201180102010101020d0001010202011801010102010101180102010101020d000101020201180102010101020118010201010f0001010102011803020118010111000601'),
		bytes(hex'9b000801010001020d0001010816010101020c00010108160101010001020c0001010216010103160101011601010e000101081601010e0001010216010103160101011601010e00010103160301021601010f000101081610000801'),
		bytes(hex'e200031402000314100001140115011402000114011501141000031402000314'),
		bytes(hex'e2000302020003021000020201010200010102021000030202000302'),
		bytes(hex'e200030202000302100001020101010202000102010101021000030202000302'),
		bytes(hex'e300030101000301110001020101020001020101120001020101020001020101'),
		bytes(hex'cc0001160300011613000b0301030a0001160103010203160102061601160c000b0301030c00011603000116'),
		bytes(hex'e200030102000301110001020101020001020101120001020101020001020101'),
		bytes(hex'cc000101030001011100020105000101110001020101030001010102110001020101030001010102'),
		bytes(hex'b2000319140005191300011903010119030001010f00011901010103010101190100020101020f000119030101190200010101020f0005191200041914000219'),
		bytes(hex'e200030102000301110001020101020001020101120001010102020001010102'),
		bytes(hex'e3000301010003011100011a0101011a0100011a0101011a1100031a0100031a'),
		bytes(hex'e2000301020003011100010201010200010201011200020202000202'),
		bytes(hex'e900010110000401010002010102110001020101030001010102'),
		bytes(hex'e200020117000102020101000301110001020101030001010102'),
		bytes(hex'e200020105000101110001020201010002010102110001020101030001010102'),
		bytes(hex'e200030102000301290001010102030001010102')
	];

	string[] public eyes_traits = [
		'Virtual Reality',
		'Scouter',
		'Glasses',
		'3D Glasses',
		'Big Blue Glasses',
		'Big Red Glasses',
		'Shut',
		'Pirate',
		'Future Too Bright',
		'Stunners',
		'RIP',
		'Smug',
		'Overjoyed',
		'Sus',
		'Good Face',
		'Sad Face',
		'Happy Note',
		'Corrupted',
		'Dizzy',
		'Low Key Shook',
		'Optimistic',
		'Maximalist',
		'Watchful',
		'Worried',
		'Terminatooor',
		'Senpai',
		'Stoney Baloney',
		'Skyward',
		'Raised Left',
		'Raise Right',
		'U Mad Bro',
		'Naughty'
	];

	uint8[] public eyes_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];

	///////////////////////////////////////
	// mouths
	bytes[] public mouths = [
		bytes(hex'ff004400010118000301'),
		bytes(hex'ff004500010101000101010001011400010101000101'),
		bytes(hex'ff00450001010300010114000301'),
		bytes(hex'ff004400010118000101021b010115000203'),
		bytes(hex'ff001000010117000c010d0001010a1c0e000101021c011d031c011d021c0f000101071c11000101021c011d021c13000101031c15000101011c010116000101'),
		bytes(hex'ff001000010117000c010d0001010a030e0001010203021e0103021e02030f0001010703110001010103021e0203130001010303150001010103010116000101'),
		bytes(hex'2d000102300001022e0001021700010248000102170001022f00010229000101011f0202012015000201'),
		bytes(hex'ff005c000201'),
		bytes(hex'ff004300010f0600010f1100060f'),
		bytes(hex'ff005c0002010102010101020201'),
		bytes(hex'ff00460003011500010101000101'),
		bytes(hex'ff00460003011400010103000101'),
		bytes(hex'ff005e000301'),
		bytes(hex'ff005c000601')
	];

	string[] public mouths_traits = [
		'Smirk',
		'Uwu',
		'Smile',
		'Silly',
		'Grey Bandana',
		'Red Bandana',
		'Smoking',
		'Hmmm',
		'Big Honkin Smile',
		'Buck',
		'Micro Sad',
		'Sad',
		'Blah',
		'Unsatisfied'
	];

	uint8[] public mouths_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13];

	///////////////////////////////////////
	// hair
	bytes[] public hair = [
		bytes(hex'200009020e000102090101020c000102010103240625010101020a000102010102240925010101020500050201010124062502000225010101020500010205010124052504000125010101020500010201010424062504260125010106000202030114000302'),
		bytes(hex'200009020e000102090101020c00010201010921010101020a0001020101042101220121012201210122022101010102090001020101042105220221010101020a0001010b210101010001020900010101210b23020101020b000c230101010214000201010216000102'),
		bytes(hex'200009020e000102090103020a00010201010129022a022b07010102080001020101022a022b0201072a01010102070001020101012a022b0101092a0101010208000101012a012b01010a2a0101010208000101012a01010a2a01010102'),
		bytes(hex'200009020e000102090101020c000102010103270628010101020a000102010102270928010101020500050201010127062802000228010101020500010205010127052804000128010101020500010201010427062804260128010106000202030114000302'),
		bytes(hex'200009020e000102090101020c0001020101032c062d010101020a0001020101022c092d01010102050005020101012c062d0201022d01010102050001020501012c052d0401012d01010102050001020101042c062d042e012d010106000202030114000302'),
		bytes(hex'0b00010201010202130001020101012f02010102110001020101012f0130022f010101020f0001020101033102300131010101020d0001020101012f0630012f010101020b0001020101012f01300731010101020b000102010101310730022f010101020c000a31'),
		bytes(hex'200009020e00020204010102030101020c0002020101043501010335010101020b0001020101013501360137010201010236010201010135010101020a0001020101013509360101010209000102010101350a3601010102090001020101013502360300023603000101010209000102010102360900010101020b0002360900010101020b0002360900010101020b0002360900010101020c000136'),
		bytes(hex'3a00050211000202050102020e00010202010532020101020c00010201010932010101020a000102010101330a34010101020b0001330a34'),
		bytes(hex'2800010216000102010101020e00070201010102010101020c00010207010202010101020b00010201010a02010101020900010201010b020101010209000102010103020300020203000101010209000102010102020900010101020b0002020900010101020b0002020900010101020b0002020900010101020c000102'),
		bytes(hex'2100020201000202010002020f0001020201010202010102020102020c000102010102380101023801010238020101020a000102010102380139013802390138013903380101010209000102010101380a390138010108000102010101380c39010108000102010103390300023903000201010208000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'090007020e00030204010102020102020b0001020301043b0101023b02010102090001020101043b033c013b023c023b01010102070001020101023b0b3c01010102060001020101023b043c023d013c023d013c013d013c013b01010102050001020101013b033c0a3d023c01010102040001020101013b013c013d013c033d0600023d013c01010102040001020101013b013c033d0900013d013c01010102040002020101023c023d0900023d01010102040001020101023c033d0900013d01010102050001020101023c033d0900013d01010102060001020101013c0200013d130001020101013d17000101013d160001020101'),
		bytes(hex'090007020f000202070102020c00010202010738020101020a000102010103380139013802390138013902380101010208000102010102380a3901380101010206000102010102380439013a0339013a0339010101020600010201010539073a03390101010204000102010102380239023a0700023a01390101010204000102010101380239023a0900023a0101010204000102010101380139013a0139013a0900023a01010102040001020101013a0139033a0900013a0101010206000102010101390100023a0b00010206000102010101390200013a130001020101013a160001020101013a160001020101'),
		bytes(hex'200009020e000102090101020c00010201010938010101020a0001020101023809390101010209000102010101380a39010101020900010201010b3901010102090001020101033908000101010209000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'390008020e000202080101020c0001020201083e010101020a0001020101023e093c01010102080001020101023e0a3c01010102080001020101013e073c0100033c01010102080001020101043c080001010102080001020101033c0900010101020b00023c0900010101020b00023c0900010101020c00013c2b0001020101013c150001020101023c14000202'),
		bytes(hex'2800010216000102010101020e0007020101013f010101020c0001020701013f0140010101020b00010201010a40010101020900010201010b400101010209000102010103400300024003000101010209000102010102400900010101020b0002400900010101020b0002400900010101020b0002400900010101020c000140'),
		bytes(hex'2800010216000102010101020e00070201010138010101020c000102070101380139010101020b00010201010a39010101020900010201010b390101010209000102010103390300023903000101010209000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'2100010205000102100001020101010203000102010101020e00010201010103010101020100010201010103010101020d00010201010203010101000101020301010102'),
		bytes(hex'0a0001020141010215000202014103021100010206410102100001410342014101430142014101020e00014104440142014101440142014101020e00014107440141100003410344024113000341'),
		bytes(hex'0b00010203010102110002020101014501010145010101020f00010204010145030101020d00010201010846010101020b00010201010346010201010146010201010246010102020800010201010b460301010209000346014709450101010209000246014702000745010101020a000246014715000146014716000146014716000247170001471700014717000148'),
		bytes(hex'080001020201010203000102010101020d000102010102490101030201010149010101020c00010201010149014602010102010101490146010101020c000102010103460101010001010246010101020e0001010246010102000146020001020d000249064601490e0001490246074a01460d0001490146014a0700014a0d000146014a16000146014a16000146014a16000146014a1700014a'),
		bytes(hex'2100010205000102100001020101010203000102010101020e00010201010102010101020100010201010102010101020d00010201010202010101000101020201010102'),
		bytes(hex'08000b020c00020203010302030102020b000102010103020101010201010302010101020b00010201010102014c01020101010001010102014c0102010101020b00010201000102014c0102010102000102014c0102010101020c000a02010101020b00020216000102170001021700010217000102'),
		bytes(hex'05000402020003020200040209000102020104020101040202010102090001020101014b0101020201010116010102020101011601010102090001020101014b0116020103160201021601010102090001020101024b091601010102090001020101024b011601030216010302160103011601010102090001020101034b081601010b000101'),
		bytes(hex'ff00'),
		bytes(hex'090004021300020203010302100001020101034d0301010211000201014e034d010101020d000102020101000101044e014d010101020b0001020101094e014d010101020900010201010b4e01010102090001020101034e0300024e030001010102090001020101024e0900010101020b00024e0900010101020b00024e0900010101020b00024e0900010101020c00014e'),
		bytes(hex'1d0003021400010203010102120001020101034f0101120001020101014f025003011000010202010b500b00010202000b500a000102020003501500025016000250160002501600025017000150'),
		bytes(hex'1d000302140001020301010212000102010103530101120001020101035303011000010202010b530b00010202000b530a000102020003531500025316000253160002531600025317000153'),
		bytes(hex'800001510152015101520151015203510e0003510152015101520151015203510d0003511500025116000251160002511600025117000151'),
		bytes(hex'63000254170002541700015401550b5401550800025402550b54015507000254'),
		bytes(hex'6300025a1700025a17000e5a0800105a0700025a')
	];

	string[] public hair_traits = [
		'Black Hat',
		'Bear Market Hat',
		'Cap Front',
		'Topo Hat',
		'Chill Green Hat',
		'Poop',
		'Froggy',
		'Eric',
		'Old But Still Cool',
		'Straight Bussin',
		'Clowin',
		'Success Perm',
		'Poppin',
		'Neetori',
		'Blonde',
		'Cool Guy',
		'Devil Horns',
		'Leaf',
		'Ducky',
		'Pipichu',
		'Catbot',
		'Easter',
		'King',
		'Bald',
		'90s',
		'3000',
		'Sun Bun',
		'Too Cool',
		'Blue Bandana',
		'Black Bandana'
	];

	uint8[] public hair_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,23,24,25,26,27,28,29];

	///////////////////////////////////////
	// bodies
	bytes[] public bodies = [
		bytes(hex'ff006e000102010101561400010201010356010112000102010104560157015804560101010209000102010103560159015701580659010101020800010201010256025901570158035901580259010101020800010201010256015901570158075901010102080001020101025601590157015802590158045901010102080001020101025601590157015805590158015901010102080001020101025601590157015801590158055901010102'),
		bytes(hex'ff006e0001020101015b140001020101035b01011200010201010a5b01010102090001020101065b065c01010102080001020101025b025c045b045c01010102080001020101035b055c045b01010102080001020101045b085c01010102080001020101025b015c035b065c01010102080001020101025b035c035b045c01010102'),
		bytes(hex'ff006e0001020101015f140001020101035f01011200010201010a5f01010102090001020101035f096001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102'),
		bytes(hex'ff006d0001020101025d140001020201025d0101120002020101045d0101015d0101025d0c0001020101025d0101025d0101015d0101015d0d0001020101015d02000101055d120006011200065e1200015e0400015e1200015e0400015e'),
		bytes(hex'ff00eb000561120006612a00010304000103'),
		bytes(hex'ff00eb00050214000302'),
		bytes(hex'ff008800010101631600046301010100010102630e00026301000363010102630f0001630300016301010363130005641200066312000163040001631200016304000163'),
		bytes(hex'ff00890001651600046501010100010102650e00026501000365010102650f000165030001650101036513000366010301661200066512000165040001651200016504000165'),
		bytes(hex'ff00b800010316000303070001030e0002030100050201000103100006621200016204000162'),
		bytes(hex'ff008900016f1600096f0e00026f0100026f0370016f0f00016f02710100016f017001720170016f010001710e0002710100016f0370016f010001711000066f1200016f0400016f1200016f0400016f'),
		bytes(hex'ff008900016a1600046a0101016b0101026a0e00026a0100026a0101016c0101016a0f00016a0300016a0101016b0101016a13000268010102681200066912000169040001691200016904000169'),
		bytes(hex'ff00890001021600040201010167010102020e000202010002020101010a010101020f000102030001020101010a0101010213000268010102681200066912000169040001691200016904000169'),
		bytes(hex'ff00890001021600040201010100010102020e00020201000302010102020f00010203000502130005681200060212000102040001021200010204000102'),
		bytes(hex'ff00eb00056d1300046e'),
		bytes(hex'ff00ff00030006761200017604000176'),
		bytes(hex'ff00890001731600027301740173017401730174017301740e00027301000173017401730174017301740f000173030001730174017301740173130005731200067512000175040001751200017504000175'),
		bytes(hex'ff0089000177160009770e000277010006770f00017703000577130005781200067912000179040001791200017904000179'),
		bytes(hex'ff008900017e1600017e017f017e017f018001000180017f017e0e0002810100017f017e017f0180017f017e0f0001810300017f017e017f017e017f1300017e017f017e017f017e1200017e017f017e017f017e017f1200017e0400017e'),
		bytes(hex'ff008900017a1600097a0e00017b017a0100067a0f00017a0300057a1300057a1200017c047d017c1200017c0400017c'),
		bytes(hex'ff0089000182160009820e0002820100028201160182011601820f000182030001820316018213000582120006161200011604000116'),
		bytes(hex'ff00a3000583120003830184028313000183018401830184018313000583120006851200018504000185'),
		bytes(hex'ff00a300010203000102120006021300050213000502120006881200018804000188'),
		bytes(hex'ff0089000189160009890e00028901000389020101890f0001890300018902010289130005891200068a1200018a0400018a'),
		bytes(hex'ff0089000186160009860e00028601000286012b0186012b01860f00018603000286012b0286130005861200068712000187040001871200018704000187'),
		bytes(hex'ff008900018b1600098b0e00028b0100038b018c028b0f00018b0300018b038c018b1300058b1200068d1200018d0400018d1200018d0400018d'),
		bytes(hex'ff00a300019001000190010001901200019001000190010001901400019001000190010001901400019001000190140001900100019001000190'),
		bytes(hex'ff00ed00018e1600038e1500018e018f018e')
	];

	string[] public bodies_traits = [
		'Burrito',
		'Monk',
		'Comfy',
		'Hoodie',
		'Astro',
		'Underwear',
		'Ninja',
		'Jiu Jitsu Gi Blue',
		'Boxer',
		'Andy',
		'Myles',
		'Business Time',
		'Freddie',
		'Hot Speedo',
		'Swimmer',
		'Argyle',
		'Steve',
		'Romphim',
		'Meme Frog',
		'Go Bruins',
		'Staying Fit',
		'LA Summer',
		'Bicyclist',
		'Funktronic',
		'Ganja Shirt From College',
		'Net',
		'Leaf'
	];

	uint8[] public bodies_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26];

	///////////////////////////////////////
	// heads
	bytes[] public heads = [
		bytes(hex'500009020e000102090101020c00010201010991010101020a00010201010b910101010209000102010103910881010101020900010201010291098101010102090001020101029109810101010208000102020102910981010101020700010201010281029109810101010207000102010103810191058101920481010101020700010202010c81010101020800020201010b81010101020a00010201010981010101020a00010201010181090101020a00010201010981010101020a00010201010281010102810192018101920181020101020a000102010103810101058101010181010101020a000102010102810101058101010181010101020b00010202010681020101020d0001020101018104010181010101020e00010201010181010102020101018101010102'),
		bytes(hex'500009020e000102090101020c00010201010993010101020a00010201010b930101010209000102010103930894010101020900010201010293099401010102090001020101029309940101010208000102020102930994010101020700010201010294029309940101010207000102010103940193059401950494010101020700010202010c94010101020800020201010b94010101020a00010201010994010101020a00010201010194090101020a00010201010994010101020a00010201010294010102940195019401950194020101020a000102010103940101059401010194010101020a000102010102940101059401010194010101020b00010202010694020101020d0001020101019404010194010101020e00010201010194010102020101019401010102'),
		bytes(hex'500009020e000102090101020c00010201010999010101020a00010201010b99010101020900010201010399089a010101020900010201010299099a010101020900010201010299099a010101020800010202010299099a01010102070001020101029a0299099a01010102070001020101039a0199059a0192049a010101020700010202010c9a010101020800020201010b9a010101020a0001020101099a010101020a00010201010136090101020a0001020101099a010101020a0001020101029a01010136059a020101020a0001020101039a01010136049a0101019a010101020a0001020101029a01010136049a0101019a010101020b0001020201069a020101020d0001020101019a0401019a010101020e0001020101019a010102020101019a01010102'),
		bytes(hex'500009020e000102090101020c0001020101099b010101020a00010201010b9b01010102090001020101039b089c01010102090001020101029b099c01010102090001020101029b099c01010102080001020201029b099c01010102070001020101029c029b099c01010102070001020101039c019b059c019d049c010101020700010202010c9c010101020800020201010b9c010101020a0001020101099c010101020a0001020101019e090101020a0001020101099e010101020a0001020101029e0101029e019f019e019f019e020101020a0001020101039e0101059e010101a0010101020a0001020101029e0101059e010101a0010101020b0001020201069e020101020d0001020101019e0401019e010101020e0001020101019e010102020101019e01010102'),
		bytes(hex'500009020e000102090101020c00010201010996010101020a00010201010b960101010209000102010103960897010101020900010201010296099701010102090001020101029609970101010208000102020102960997010101020700010201010297029609970101010207000102010103970196059701920497010101020700010202010c97010101020800020201010b97010101020a00010201010997010101020a00010201010198090101020a00010201010998010101020a00010201010298010102980192019801920198020101020a000102010103980101059801010198010101020a000102010102980101059801010198010101020b00010202010698020101020d0001020101019804010198010101020e00010201010198010102020101019801010102'),
		bytes(hex'500009020e000102090101020c00010201010902010101020a00010201010b02010101020900010201010b02010101020900010201010b02010101020900010201010b02010101020800010202010b02010101020700010201010d0201010102070001020101090201920402010101020700010202010c02010101020800020201010b02010101020a00010201010902010101020a00010201010102090101020a00010201010902010101020a00010201010202010102020192010201920102020101020a000102010103020101050201010102010101020a000102010102020101050201010102010101020b00010202010602020101020d0001020101010204010102010101020e00010201010102010102020101010201010102'),
		bytes(hex'500009020e000102090101020c000102010109a1010101020a00010201010ba10101010209000102010103a108a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a105a2019204a20101010208000102010102a10aa20101010209000102010101a10aa2010101020a000102010109a2010101020a000102010101a3090101020a000102010108a201a3010101020a000102010102a2010101a305a2020101020a000102010103a2010101a304a2010101a2010101020a000102010102a2010101a304a2010101a2010101020b000102020106a2020101020d000102010101a2040101a2010101020e000102010101a201010202010101a201010102'),
		bytes(hex'500009020e000102090101020c000102010109a4010101020a00010201010ba40101010209000102010101a505a601a701a801a901a601aa0101010209000102010101ab01ac01ad01ac01ad01ac01ad01ac03ad0101010209000102010101ae01af01b001b102b001b201ae01b001ae01b00101010208000102020102b301b402b301b401b501b401b501b301b40101010207000102010101b601b701b601b801b901b701ba02b604b90101010207000102010101bb01bc01bd01be01bd02bb03bd01bb01be01bc01bd0101010207000102020102bf01c001c101c202c002bf01c001bf01c00101010208000202010101c301c401c501c401c601c402c702c801c3010101020a000102010101c901ca01c902cb01cc01cb01c901cb010101020a000102010101cd090101020a000102010101ce01cf02ce02d001d101d001d2010101020a000102010101d301d4010102d404d3020101020a000102010101d501d601d7010102d601d702d5010101d6010101020a000102010101d801d9010101d804d9010101d9010101020b000102020106da020101020d000102010101da040101da010101020e000102010101da01010202010101da01010102'),
		bytes(hex'500009020e000102090101020c000102010109dd010101020a000102010102dd070202dd0101010209000102010101dd010209dd0101010209000102010101dd010209dd0101010209000102010101dd010209dd010101020800010202010bdd0101010207000102010102020bdd0101010207000102010103dd010205dd019203dd0102010101020700010202010cdd010101020800020201010bdd010101020a000102010109dd010101020a000102010101de090101020a000102010101dd010207dd010101020a000102010101dd0102010102dd019f01dd019f01dd020101020a000102010102dd0102010105dd01010102010101020a000102010102dd010101dd020202dd010101dd010101020b000102020106dd020101020d000102010101dd040101dd010101020e000102010101dd01010202010101dd01010102')
	];

	string[] public heads_traits = [
		'Human',
		'Tengu',
		'Meme Frog',
		'Orc',
		'Night Elf',
		'Spoopy',
		'AI Bot',
		'Prismatic',
		'Golden Boy'
	];

	uint8[] public heads_indices = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,5,6,6,7,8];

	///////////////////////////////////////
	// misc
	bytes[] public misc = [
		bytes(hex'500009020e000102090101020c000102010109db010101020a000102010103db08dc0101010209000102010102db09dc0101010209000102010102db09dc0101010209000102010102db09dc0101010208000102020102db09dc0101010207000102010104db09dc0101010207000102010103db03dc029203dc029201dc010101020700010202010cdc010101020800020201010bdc010101020a000102010109dc010101020a000102010101db090101020a000102010104db05dc010101020a000102010102db010106dc0201010208000302010101db02dc010105dc010101dc010101020600010202010202010102dc010105dc010101dc0101010205000102010102db020101db020106dc0201010207000102010104db08dc0101010209000102010103db07dc01010102'),
		bytes(hex'500009020e000102090101020c0001020b0101020a0001020d0101020900010205010302050101020900010204010502040101020900010203010202030102020301010208000102040102020301020203010102070001020a010202030101020700010209010202050101020700010207010202060101020800020205010202060101020a0001020b0101020a00010205010202040101020a00010206010202030101020a0001020c0101020a0001020d0101020a0001020c0101020b0001020a0101020d000102080101020e0001020301020203010102')
	];

	string[] public misc_traits = [
		'Ghost',
		'Mystery'
	];
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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