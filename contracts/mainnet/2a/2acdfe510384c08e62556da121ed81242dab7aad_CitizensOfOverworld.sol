// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./AnonymiceLibrary.sol";
import "./Utility.sol";

contract CitizensOfOverworld is ERC721A, Ownable {
    /*

    *******************************************************************************************************************
    *                                                                                                                 *
    *   ______   __    __      __                                                           ______                    *
    *  /      \ |  \  |  \    |  \                                                         /      \                   *
    * |  000000\ \00 _| 00_    \00 ________   ______   _______    _______         ______  |  000000\                  *
    * | 00   \00|  \|   00 \  |  \|        \ /      \ |       \  /       \       /      \ | 00_  \00                  *
    * | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\|  0000000      |  000000\| 00 \                      *
    * | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00 \00    \       | 00  | 00| 0000                      *
    * | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00 _\000000\      | 00__/ 00| 00                        *
    *  \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00|       00       \00    00| 00                        *
    *   \000000  \00    \0000  \00 \00000000  \0000000 \00   \00 \0000000         \000000  \00                        *
    *                                                                                                                 *
    *   ______                                                                    __        __         0000000000     *
    *  /      \                                                                  |  \      |  \      00000000000000   *
    * |  000000\ __     __   ______    ______   __   __   __   ______    ______  | 00  ____| 00      00000000000000   *
    * | 00  | 00|  \   /  \ /      \  /      \ |  \ |  \ |  \ /      \  /      \ | 00 /      00      00000000000000   *   
    * | 00  | 00 \00\ /  00|  000000\|  000000\| 00 | 00 | 00|  000000\|  000000\| 00|  0000000        0000000000     *
    * | 00  | 00  \00\  00 | 00    00| 00   \00| 00 | 00 | 00| 00  | 00| 00   \00| 00| 00  | 00       000000000000    *
    * | 00__/ 00   \00 00  | 00000000| 00      | 00_/ 00_/ 00| 00__/ 00| 00      | 00| 00__| 00      01000000000010   *
    *  \00    00    \000    \00     \| 00       \00   00   00 \00    00| 00      | 00 \00    00      01000000000010   *  
    *   \000000      \0      \0000000 \00        \00000\0000   \000000  \00       \00  \0000000        0000  0000     *   
    *                                                                                                                 *
    *                                                                                                                 *
    *  on-chain, animated digital collectibles                                                                        *
    *                                                                                                                 *
    *                                                                                                                 *
    *   created by @0xMongoon ( ＾◡＾)っ ♡                                                                             *                                               
    *                                                                                                                 *
    *   with inspiration from all the devs & collections living on-chain                                              *
    *******************************************************************************************************************
                                                                                            



     __     __                     __            __        __                     
    |  \   |  \                   |  \          |  \      |  \                    
    | 00   | 00 ______    ______   \00  ______  | 00____  | 00  ______    _______ 
    | 00   | 00|      \  /      \ |  \ |      \ | 00    \ | 00 /      \  /       \
     \00\ /  00 \000000\|  000000\| 00  \000000\| 0000000\| 00|  000000\|  0000000
      \00\  00 /      00| 00   \00| 00 /      00| 00  | 00| 00| 00    00 \00    \ 
       \00 00 |  0000000| 00      | 00|  0000000| 00__/ 00| 00| 00000000 _\000000\
        \000   \00    00| 00      | 00 \00    00| 00    00| 00 \00     \|       00
         \0     \0000000 \00       \00  \0000000 \0000000  \00  \0000000 \0000000 
    */

    //  **********  //
    //  * ERC721 *  //
    //  **********  //

    // ERC721A values.
    uint256 public MAX_SUPPLY;
    uint256 public constant MAX_MINT_PER_WALLET = 4;
    uint256 public constant MAX_MINT_OWNER = 30;
    uint256 public constant PRICE_AFTER_FIRST_MINT = 0.005 ether;

    //  ******************************  //
    //  * Mint Tracking & Regulation *  //
    //  ******************************  //

    // Used to start/pause mint
    bool public mintLive = false;

    // Tracks last write and num minted for each address except owner
    // Last write is used to prevent flashbots from reverting their mint after seeing traits they got (courtesy Circolors)
    mapping(address => uint256) public mintedInfo;

    // Tracks how many Citizens the owner has minted
    uint256 public tokensMintedByOwner = 0;

    // Used to add some more variability in pseudo-randomness
    uint256 private seed_nonce;

    //  ***********  //
    //  * Utility *  //
    //  ***********  //

    // Used for converting small uints to strings with low gas
    string[33] private lookup;

    //  ************************************  //
    //  * STORAGE OF COMPRESSED IMAGE DATA *  //
    //  ************************************  //

    // Used to store the compressed trait images as bytes
    bytes[][] private compressedTraitImages;

    // Used to store the compressed trait metadata as bytes32
    bytes20[][] private compressedTraitMetadata;

    // Used to store that background image data as strings
    string[6] private backgrounds;

    // Used to store the animation and gradient data for each legendary trait as bytes
    bytes public legendaryAnimations;

    // Used to store the pixels for each legendary trait as bytes
    bytes private legendaryPixels;

    // Used to store all possible colors as a single bytes object
    bytes private hexColorPalette;

    // Once the owner loads the data, this is set to true, and the data is locked
    bool public compressedDataLoaded;

    //  **************************************  //
    //  * STORAGE OF DECOMPRESSED IMAGE DATA *  //
    //  **************************************  //

    // Used to store the bounds within the SVG coordinate system for each trait
    struct Bounds {
        uint8 minX;
        uint8 maxX;
        uint8 minY;
        uint8 maxY;
    }

    // Used to store the color and length of each pixel of a trait
    struct Pixel {
        uint8 length;
        uint8 colorIndex;
    }

    // Used to store the decompressed trait image
    struct DecompressedTraitImage {
        Bounds bounds;
        Pixel[] draws;
    }

    //  ***************************  //
    //  * RENDERING OF IMAGE DATA *  //
    //  ***************************  //

    // Constant values that will be used to build the SVG
    // Some are only used if the Citizen has a 'rainbow' trait or is legendary
    string private constant _SVG_PRE_STYLE_ATTRIBUTE =
        '<svg xmlns="http://www.w3.org/2000/svg" id="citizen" viewBox="-4.5 -5 42 42" width="640" height="640" style="';
    string private constant _SVG_DEF_TAGS =
        ' shape-rendering: crispedges; image-rendering: -moz-crisp-edges; background-repeat: no-repeat;"><defs><radialGradient id="i"><stop offset="0%" style="stop-color:#000000;stop-opacity:.9"/><stop offset="100%" style="stop-opacity:0"/></radialGradient>';
    string private constant _SVG_RAINBOW_ANIMATION_DEF_IF_RAINBOW =
        '<animate xmlns="http://www.w3.org/2000/svg" href="#r" attributeName="fill" values="red;orange;yellow;green;blue;violet;red;" dur="1s" repeatCount="indefinite"/>';
    string private constant _SVG_CLIP_DEF_IF_LEGENDARY =
        '<clipPath id="c"><rect x="11" y="13" width="11" height="16"/><rect x="10" y="15" width="1" height="14"/><rect x="22" y="15" width="1" height="14"/><rect x="12" y="29" width="4" height="4"/><rect x="17" y="29" width="4" height="4"/><rect x="16" y="29" width="1" height="1"/></clipPath>';
    string private constant _SVG_TAG_PRE_ANIMATION_ID_REF =
        '</defs><ellipse cx="16.5" cy="33" rx="6" ry="2" fill="url(#i)"><animate attributeType="XML" attributeName="rx" dur="1.3s" values="9;7;9" repeatCount="indefinite" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1"/></ellipse><g fill="url(#';
    string private constant _SVG_FINAL_START_TAG =
        ')" clip-path="url(#c)" id="r"><animateTransform attributeType="XML" attributeName="transform" type="translate" values="0,.5;0,-.5;0,.5" repeatCount="indefinite" dur="1.3s" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1"/>';
    string private constant _SVG_END_TAG = "</g></svg>";

    // Used to store the DNA for each Citizen. This DNA is used to determine the traits of each Citizen upon rendering via tokenURI()
    struct DNA {
        uint256 Legendary;
        uint256 Body;
        uint256 Pants;
        uint256 Shirt;
        uint256 Eyes;
        uint256 Hat;
        uint256 Accessory;
        uint256 Mouth;
        uint256 Background;
    }

    // Contains the DNA for every Citizen, keyed by tokenId
    mapping(uint256 => uint256) public tokenIdToSeed;

    //  ******************  //
    //  * TRAIT RARITIES *  //
    //  ******************  //

    uint256[] legendaryRarity = [uint256(9944), 7, 7, 7, 7, 7, 7, 7, 7];

    uint256[] bodyRarity = [uint256(25), 25, 25, 25, 25, 25, 24, 24, 1];

    uint256[] pantsRarity = [uint256(18), 16, 4, 16, 16, 17, 15, 10, 14, 4, 14, 14, 15, 16, 8, 2];

    uint256[] shirtRarity = [uint256(19), 19, 19, 19, 19, 19, 17, 15, 6, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 6, 2];

    uint256[] eyesRarity = [uint256(10), 5, 10, 10, 10, 5, 1, 4, 25, 1, 25, 4, 4, 2, 2, 2, 2, 22, 10, 10, 16, 3, 15, 2];

    uint256[] hatRarity = [uint256(2), 12, 12, 12, 4, 5, 4, 12, 12, 12, 4, 12, 1, 4, 5, 2, 2, 13, 5, 2, 2, 2, 5, 13, 13, 4, 3, 3, 3, 3, 3, 8, 1];

    uint256[] accessoryRarity = [uint256(10), 4, 20, 3, 12, 150, 1];

    uint256[] mouthRarity = [uint256(2), 2, 2, 2, 2, 2, 2, 2, 4, 3, 4, 15, 24, 4, 4, 4, 3, 24, 3, 4, 11, 9, 3, 4, 11, 11, 11, 10, 10, 4, 4];

    uint256[] backgroundRarity = [uint256(30), 30, 30, 30, 30, 30, 3, 3, 3, 3, 4, 4];

    /*
     ________                                 __      __                               
    |        \                               |  \    |  \                              
    | 00000000__    __  _______    _______  _| 00_    \00  ______   _______    _______ 
    | 00__   |  \  |  \|       \  /       \|   00 \  |  \ /      \ |       \  /       \
    | 00  \  | 00  | 00| 0000000\|  0000000 \000000  | 00|  000000\| 0000000\|  0000000
    | 00000  | 00  | 00| 00  | 00| 00        | 00 __ | 00| 00  | 00| 00  | 00 \00    \ 
    | 00     | 00__/ 00| 00  | 00| 00_____   | 00|  \| 00| 00__/ 00| 00  | 00 _\000000\
    | 00      \00    00| 00  | 00 \00     \   \00  00| 00 \00    00| 00  | 00|       00
     \00       \000000  \00   \00  \0000000    \0000  \00  \000000  \00   \00 \0000000 
    
    */

    constructor() ERC721A("Citizens of Overworld", "OVRWRLD") {}

    //  ***********************************  //
    //  * FLASHBOT MINT REVERT PREVENTION *  //
    //  ***********************************  //

    // Prevents someone calling read functions the same block they mint (courtesy of Circolors)
    modifier disallowIfStateIsChanging() {
        require(
            owner() == msg.sender ||
                (mintedInfo[msg.sender] >> 8) < block.number,
            "pwnd"
        );
        _;
    }

    //  *****************  //
    //  * CUSTOM ERRORS *  //
    //  ********/********  //

    error MintNotLive();
    error TooMany();
    error SoldOut();
    error DownOnly();
    error BadPrice();
    error BiggerSupplyPls();

    /*

    __       __  __             __     
   |  \     /  \|  \           |  \                             _   _
   | 00\   /  00 \00 _______  _| 00_                           ((\o/))
   | 000\ /  000|  \|       \|   00 \                     .-----//^\\-----.
   | 0000\  0000| 00| 0000000\\000000                     |    /`| |`\    |
   | 00\00 00 00| 00| 00  | 00 | 00 __                    |      | |      |
   | 00 \000| 00| 00| 00  | 00 | 00|  \                   |      | |      |
   | 00  \0 | 00| 00| 00  | 00  \00  00                   |      | |      |
    \00      \00 \00 \00   \00   \0000       ༼ つ ◕_◕ ༽つ  '------===------'

    */

    function mint(uint256 quantity) external payable {
        if (!mintLive) revert MintNotLive();

        uint256 walletMinted = mintedInfo[msg.sender] & 0xFF;
        uint256 newWalletMinted = walletMinted + quantity;
        if (newWalletMinted > MAX_MINT_PER_WALLET) revert TooMany();

        uint256 totalminted = _totalMinted();
        uint256 newSupply = totalminted + quantity;
        if (newSupply + (MAX_MINT_OWNER - tokensMintedByOwner) > MAX_SUPPLY)
            revert SoldOut();

        uint256 totalFee = (quantity - (mintedInfo[msg.sender] != 0 ? 0 : 1)) *
            PRICE_AFTER_FIRST_MINT;

        if (msg.value != totalFee) revert BadPrice();
        mintedInfo[msg.sender] = (block.number << 8) + newWalletMinted;
        _safeMint(msg.sender, quantity);
        for (; totalminted < newSupply; ++totalminted) {
            uint256 seed = generateSeed(totalminted);
            tokenIdToSeed[totalminted] = seed;
            unchecked {
                seed_nonce += seed;
            }
        }
    }

    /*
       ______   __    __      __                                            
      /      \ |  \  |  \    |  \                                                                       (=(   )=)
     |  000000\ \00 _| 00_    \00 ________   ______   _______                                            `.\ /,'
     | 00   \00|  \|   00 \  |  \|        \ /      \ |       \                                             `\.
     | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\                                          ,'/ \`.
     | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00                                         (=(   )=)
     | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00                                          `.\ /,'
      \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00                                            ,/'
       \000000  \00    \0000  \00 \00000000  \0000000 \00   \00                                          ,'/ \`.
       ______                                                     __      __                            (=(   )=)
      /      \                                                   |  \    |  \                            `.\ /,'
     |  000000\  ______   _______    ______    ______   ______  _| 00_    \00  ______   _______            `\.
     | 00 __\00 /      \ |       \  /      \  /      \ |      \|   00 \  |  \ /      \ |       \         ,'/ \`.
     | 00|    \|  000000\| 0000000\|  000000\|  000000\ \000000\\000000  | 00|  000000\| 0000000\       (=(   )=)
     | 00 \0000| 00    00| 00  | 00| 00    00| 00   \00/      00 | 00 __ | 00| 00  | 00| 00  | 00        `.\ /,'
     | 00__| 00| 00000000| 00  | 00| 00000000| 00     |  0000000 | 00|  \| 00| 00__/ 00| 00  | 00          ,/'
      \00    00 \00     \| 00  | 00 \00     \| 00      \00    00  \00  00| 00 \00    00| 00  | 00        ,'/ \`.
       \000000   \0000000 \00   \00  \0000000 \00       \0000000   \0000  \00  \000000  \00   \00       (=(   )=)
    */

    /**
     * Creates DNA object for Overworld's newest Citizen via pseudorandom trait generation.
     */
    function generateSeed(uint256 tokenId) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        tokenId,
                        msg.sender,
                        block.timestamp,
                        block.difficulty,
                        seed_nonce
                    )
                )
            );
    }

    /**
     * Returns a random number between 0 and 200, weighted by rarity array.
     */
    function getRarity(int256 rand, uint256[] memory rarity)
        private
        pure
        returns (uint256)
    {
        uint256 trait;
        for (uint256 i; i < rarity.length; ++i) {
            if (rand - int256(rarity[i]) < 0) {
                trait = i;
                break;
            }
            rand -= int256(rarity[i]);
        }
        return trait;
    }

    /*
                                                                                                                              ▒▒
                                                                                                                            ▒▒░░▒▒
     ______   __    __      __                                                                                            ▒▒░░░░░░▒▒ 
    /      \ |  \  |  \    |  \                                                                                         ▒▒░░░░░░░░░░▒▒
   |  000000\ \00 _| 00_    \00 ________   ______   _______                                                           ▒▒░░░░░░░░░░░░░░▒▒
   | 00   \00|  \|   00 \  |  \|        \ /      \ |       \                                                        ▒▒░░▒▒░░░░░░░░░░░░░░▒▒ 
   | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\                                                     ░░  ▒▒░░▒▒░░░░░░░░░░░░░░▒▒
   | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00                                                   ░░  ██  ▒▒░░▒▒░░░░░░░░░░▒▒  
   | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00                                                 ░░  ██      ▒▒░░▒▒░░░░░░▒▒    
    \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00                                               ░░  ██      ██  ▒▒░░▒▒░░▒▒  
     \000000  \00    \0000  \00 \00000000  \0000000 \00   \00                                             ░░  ██      ██      ▒▒░░▒▒   
                                                                                                        ░░  ██      ██      ██  ▒▒    
    _______                             __                      __                                    ░░  ██      ██      ██  ░░        
   |       \                           |  \                    |  \                                 ░░  ██      ██      ██  ░░    
   | 0000000\  ______   _______    ____| 00  ______    ______   \00 _______    ______               ▒▒██      ██      ██  ░░  
   | 00__| 00 /      \ |       \  /      00 /      \  /      \ |  \|       \  /      \            ▒▒░░▒▒    ██      ██  ░░ 
   | 00    00|  000000\| 0000000\|  0000000|  000000\|  000000\| 00| 0000000\|  000000\           ▒▒░░░░▒▒██      ██  ░░    
   | 0000000\| 00    00| 00  | 00| 00  | 00| 00    00| 00   \00| 00| 00  | 00| 00  | 00         ▒▒░░░░░░░░▒▒    ██  ░░    
   | 00  | 00| 00000000| 00  | 00| 00__| 00| 00000000| 00      | 00| 00  | 00| 00__| 00         ▒▒░░░░░░░░░░▒▒██  ░░    
   | 00  | 00 \00     \| 00  | 00 \00    00 \00     \| 00      | 00| 00  | 00 \00    00       ▒▒░░░░░░░░░░░░░░▒▒░░        
    \00   \00  \0000000 \00   \00  \0000000  \0000000 \00       \00 \00   \00 _\0000000       ▒▒░░░░░░░░░░▒▒▒▒          
                                                                             |  \__| 00       ████░░░░▒▒▒▒              
                                                                              \00    00     ██████▒▒▒▒     
                                                                              \000000       ████                                  
    */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        disallowIfStateIsChanging
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "Citizen ',
                            _toString(tokenId),
                            '", "image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(tokenIdToSVG(tokenId))),
                            '","attributes":',
                            tokenIdToMetadata(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    /**
     * Given a seed, returns a DNA struct containing all the traits.
     */
    function getDNA(uint256 seed)
        public
        view
        disallowIfStateIsChanging
        returns (DNA memory)
    {
        uint256 extractedRandomNum;
        int256 rand;
        uint256 mask = 0xFFFF;

        uint256 traitLegendary;
        uint256 traitBody;
        uint256 traitPants;
        uint256 traitShirt;
        uint256 traitEyes;
        uint256 traitHat;
        uint256 traitAccessory;
        uint256 traitMouth;
        uint256 traitBackground;

        // Calculate Legendary trait based on seed
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 10000);
        traitLegendary = getRarity(rand, legendaryRarity);

        // Calculate Body trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitBody = getRarity(rand, bodyRarity);

        // Calculate Pants trait based on seed
        seed >>= 1;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitPants = getRarity(rand, pantsRarity);

        // Calculate Shirt trait based on seed
        seed >>= 1;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitShirt = getRarity(rand, shirtRarity);

        // Calculate Eyes trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitEyes = getRarity(rand, eyesRarity);

        // Calculate Hat trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitHat = getRarity(rand, hatRarity);

        // Calculate Accessory trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitAccessory = getRarity(rand, accessoryRarity);

        // Calculate Mouth trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitMouth = getRarity(rand, mouthRarity);

        // Calculate Background trait based on seed
        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        traitBackground = getRarity(rand, backgroundRarity);

        return
            DNA({
                Legendary: traitLegendary,
                Body: traitBody,
                Pants: traitPants,
                Shirt: traitShirt,
                Eyes: traitEyes,
                Hat: traitHat,
                Accessory: traitAccessory,
                Mouth: traitMouth,
                Background: traitBackground
            });
    }

    /**
     * Given a tokenId, returns its SVG.
     */
    function tokenIdToSVG(uint256 tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        // Get the DNA derived from the tokenId's seed
        DNA memory dna = getDNA(tokenIdToSeed[tokenId]);

        // This will hold the SVG pixels (represented as SVG <rect> elements)
        string memory svgRectTags;

        if (dna.Legendary == 0) {
            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[4][dna.Body % 8],
                        dna.Body == 8
                    )
                )
            );

            if (dna.Pants != 14) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[5][dna.Pants % 15],
                            dna.Pants == 15
                        )
                    )
                );
            }

            if (dna.Shirt != 19) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[6][
                                dna.Mouth < 8
                                    ? (dna.Shirt + dna.Pants) % 8
                                    : dna.Shirt % 20
                            ], // If mouth is beard, make shirt solid color
                            dna.Shirt == 20
                        )
                    )
                );
            }

            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[0][dna.Eyes == 23 ? 1 : dna.Eyes],
                        dna.Eyes == 23
                    )
                )
            );

            if (dna.Hat != 31) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[1][
                                dna.Hat == 32
                                    ? (dna.Hat + dna.Shirt + dna.Pants) % 20
                                    : dna.Hat
                            ],
                            dna.Hat == 32
                        )
                    )
                );
            }

            if (dna.Accessory != 5) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[2][dna.Accessory % 6],
                            dna.Accessory == 6
                        )
                    )
                );
            }

            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[3][dna.Mouth],
                        false
                    )
                )
            );
        } else {
            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    parseLegendaryRects(legendaryPixels)
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    _SVG_PRE_STYLE_ATTRIBUTE,
                    getBackgroundStyleFromDnaIndex(
                        dna.Background,
                        dna.Legendary > 0
                    ),
                    _SVG_DEF_TAGS,
                    (dna.Legendary > 0)
                        ? ""
                        : _SVG_RAINBOW_ANIMATION_DEF_IF_RAINBOW,
                    (dna.Legendary > 0) ? _SVG_CLIP_DEF_IF_LEGENDARY : "",
                    (dna.Legendary > 0)
                        ? parseLegendaryAnimations(dna.Legendary)
                        : "",
                    _SVG_TAG_PRE_ANIMATION_ID_REF,
                    AnonymiceLibrary.toString(dna.Legendary),
                    _SVG_FINAL_START_TAG,
                    svgRectTags,
                    _SVG_END_TAG
                )
            );
    }

    function tokenIdToMetadata(uint256 tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        unchecked {
            DNA memory tokenDna = getDNA(tokenIdToSeed[tokenId]);
            string memory metadataString;

            if (tokenDna.Legendary > 0) {
                metadataString = string(
                    abi.encodePacked(
                        '{"trait_type":"',
                        Utility.bytes20ToString(compressedTraitMetadata[8][0]),
                        '","value":"',
                        Utility.bytes20ToString(
                            compressedTraitMetadata[8][tokenDna.Legendary + 1]
                        ),
                        '"}'
                    )
                );
            } else {
                for (uint256 i; i < 9; ++i) {
                    uint256 traitValueIndex;

                    if (i == 0) {
                        traitValueIndex = tokenDna.Eyes;
                    } else if (i == 1) {
                        traitValueIndex = tokenDna.Hat;
                    } else if (i == 2) {
                        traitValueIndex = tokenDna.Accessory;
                    } else if (i == 3) {
                        traitValueIndex = tokenDna.Mouth;
                    } else if (i == 4) {
                        traitValueIndex = tokenDna.Body;
                    } else if (i == 5) {
                        traitValueIndex = tokenDna.Pants;
                    } else if (i == 6) {
                        traitValueIndex = tokenDna.Mouth < 8
                            ? (tokenDna.Shirt + tokenDna.Pants) % 8
                            : tokenDna.Shirt % 20;
                    } else if (i == 7) {
                        traitValueIndex = tokenDna.Background;
                    } else if (i == 8) {
                        traitValueIndex = tokenDna.Legendary;
                    } else {
                        traitValueIndex = uint256(69);
                    }

                    string memory traitName = Utility.bytes20ToString(
                        compressedTraitMetadata[i][0]
                    );
                    string memory traitValue = Utility.bytes20ToString(
                        compressedTraitMetadata[i][traitValueIndex + 1]
                    );

                    string memory startline;
                    if (i != 0) startline = ",";

                    metadataString = string(
                        abi.encodePacked(
                            metadataString,
                            startline,
                            '{"trait_type":"',
                            traitName,
                            '","value":"',
                            traitValue,
                            '"}'
                        )
                    );
                }
            }

            return string.concat("[", metadataString, "]");
        }
    }

    /**
     * Given a Run-Length Encoded image in 'bytes', decompress it into a more workable data structure.
     */
    function decompressTraitImageData(bytes memory image)
        private
        pure
        returns (DecompressedTraitImage memory)
    {
        Bounds memory bounds = Bounds({
            minX: uint8(image[0]),
            maxX: uint8(image[1]),
            minY: uint8(image[2]),
            maxY: uint8(image[3])
        });

        uint256 pixelDataIndex;
        Pixel[] memory draws = new Pixel[]((image.length - 4) / 2);
        for (uint256 i = 4; i < image.length; i += 2) {
            draws[pixelDataIndex] = Pixel({
                length: uint8(image[i]),
                colorIndex: uint8(image[i + 1])
            });
            ++pixelDataIndex;
        }

        return DecompressedTraitImage({bounds: bounds, draws: draws});
    }

    /**
     * Given the compressed image data for a single trait, and whether or not it is of special type,
     * return a string of rects that will be inserted into the final svg rendering.
     */
    function getRectTagsFromCompressedImageData(
        bytes memory compressedImage,
        bool isRainbow
    ) private view returns (string memory) {
        DecompressedTraitImage memory image = decompressTraitImageData(
            compressedImage
        );

        Pixel memory pixel;

        string[] memory cache = new string[](256);

        uint256 currentX = 0;
        uint256 currentY = image.bounds.minY;

        // will hold data for 4 rects
        string[16] memory buffer;

        string memory part;

        string memory rects;

        uint256 cursor;

        for (uint8 i = 0; i < image.draws.length; ++i) {
            pixel = image.draws[i];
            uint8 drawLength = pixel.length;

            uint8 length = getRectLength(currentX, drawLength, 32);

            if (pixel.colorIndex != 0) {
                buffer[cursor] = lookup[length]; // width
                buffer[cursor + 1] = lookup[currentX]; // x
                buffer[cursor + 2] = lookup[currentY]; // y
                buffer[cursor + 3] = getColorFromPalette(
                    hexColorPalette,
                    pixel.colorIndex,
                    cache
                ); // color

                cursor += 4;

                if (cursor > 15) {
                    part = string(
                        abi.encodePacked(
                            part,
                            getChunk(cursor, buffer, isRainbow)
                        )
                    );
                    cursor = 0;
                }
            }

            currentX += length;

            if (currentX > 31) {
                currentX = 0;
                ++currentY;
            }
        }

        if (cursor != 0) {
            part = string(
                abi.encodePacked(part, getChunk(cursor, buffer, isRainbow))
            );
        }

        rects = string(abi.encodePacked(rects, part));

        return rects;
    }

    /**
     * Given an x-coordinate, Pixel length, and right bound, return the Pixel
     * length for a single SVG rectangle.
     */
    function getRectLength(
        uint256 currentX,
        uint8 drawLength,
        uint8 maxX
    ) private pure returns (uint8) {
        uint8 remainingPixelsInLine = maxX - uint8(currentX);
        return
            drawLength <= remainingPixelsInLine
                ? drawLength
                : remainingPixelsInLine;
    }

    /**
     * Get the target hex color code from the cache. Populate the cache if
     * the color code does not yet exist.
     */
    function getColorFromPalette(
        bytes memory palette,
        uint256 index,
        string[] memory cache
    ) private pure returns (string memory) {
        if (bytes(cache[index]).length == 0) {
            uint256 i = index * 3;
            cache[index] = Utility._toHexString(
                abi.encodePacked(palette[i], palette[i + 1], palette[i + 2])
            );
        }
        return cache[index];
    }

    /**
     * Builds up to 4 rects given a buffer (array of strings, each contiguous group of 4 strings belonging to a
     * single rect.
     */
    function getChunk(
        uint256 cursor,
        string[16] memory buffer,
        bool isRainbow
    ) private pure returns (string memory) {
        string memory chunk;

        for (uint256 i = 0; i < cursor; i += 4) {
            bool isRectBlackColor = (keccak256(
                abi.encodePacked((buffer[i + 3]))
            ) == keccak256(abi.encodePacked(("000001"))));
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="',
                    buffer[i],
                    '" height="1" x="',
                    buffer[i + 1],
                    '" y="',
                    buffer[i + 2],
                    isRainbow && !isRectBlackColor ? "" : '" fill="#',
                    isRainbow && !isRectBlackColor ? "" : buffer[i + 3],
                    '"/>'
                )
            );
        }
        return chunk;
    }

    /**
     * Given an index (derived from the Citizen's "background" trait), returns the html-styled background string,
     * which will be inserted into the svg. If the Citizen is legendary, the background will be black & white.
     */
    function getBackgroundStyleFromDnaIndex(uint256 index, bool isLegendary)
        private
        view
        returns (string memory)
    {
        if (isLegendary)
            return "background: radial-gradient(white 0%, black 120%);";
        else if (index > 5)
            return
                string.concat(
                    "background: linear-gradient(to bottom right, ",
                    "#",
                    backgrounds[index % 6],
                    ", #",
                    backgrounds[(index + 1) % 6],
                    ", #",
                    backgrounds[(index + 2) % 6],
                    ", #",
                    backgrounds[(index + 3) % 6],
                    ");"
                );
        else
            return
                string.concat(
                    "background: radial-gradient(antiquewhite 0%, #",
                    backgrounds[index],
                    " 60%);"
                );
    }

    /**
     * Given a legendary trait value (1-8), decodes the bytes at that index of the legendaryAnimations array and returns
     * the SVG <linearGradient> and <animate> tags.
     */
    function parseLegendaryAnimations(uint256 legendaryTraitValue)
        private
        view
        returns (string memory)
    {
        if (legendaryTraitValue == 8) {
            return
                string.concat(
                    '<linearGradient id="8">',
                    _SVG_RAINBOW_ANIMATION_DEF_IF_RAINBOW,
                    "</linearGradient>"
                );
        } else {
            uint256 offset = 7;
            uint256 index = (legendaryTraitValue - 1) * offset;

            string memory color1 = string.concat(
                Utility._toHexString(
                    abi.encodePacked(
                        legendaryAnimations[index + 1],
                        legendaryAnimations[index + 2],
                        legendaryAnimations[index + 3]
                    )
                )
            );
            string memory color2 = string.concat(
                Utility._toHexString(
                    abi.encodePacked(
                        legendaryAnimations[index + 4],
                        legendaryAnimations[index + 5],
                        legendaryAnimations[index + 6]
                    )
                )
            );

            return
                string.concat(
                    '<linearGradient id="',
                    lookup[uint8(legendaryAnimations[index])],
                    '"><stop offset="0%" stop-color="#',
                    color1,
                    '" stop-opacity="1"></stop><stop offset="50%" stop-color="#',
                    color2,
                    '" stop-opacity="1"><animate attributeName="offset" values=".20;.40;.60;.80;.90;.80;.60;.40;.20;" dur="10s" repeatCount="indefinite"></animate></stop><stop offset="100%" stop-color="#',
                    color1,
                    '" stop-opacity="1"></stop></linearGradient>'
                );
        }
    }

    /**
     * Decodes the legendaryPixels array and returns the SVG <rect> tags to render a legendary Citizen.
     */
    function parseLegendaryRects(bytes memory _legendaryRects)
        private
        view
        returns (string memory)
    {
        string memory rects;
        for (uint256 i = 0; i < _legendaryRects.length; i += 5) {
            rects = string(
                abi.encodePacked(
                    rects,
                    string.concat(
                        '<rect x="',
                        lookup[uint8(_legendaryRects[i])],
                        '" y="',
                        lookup[uint8(_legendaryRects[i + 1])],
                        '" width="',
                        lookup[uint8(_legendaryRects[i + 2])],
                        '" height="',
                        lookup[uint8(_legendaryRects[i + 3])],
                        uint8(_legendaryRects[i + 4]) == 0
                            ? '"/>'
                            : '" fill="#000001"/>'
                    )
                )
            );
        }
        return rects;
    }

    /*
     ______         __                __                         ██████       
    /      \       |  \              |  \                      ██      ██   
   |  000000\  ____| 00 ______ ____   \00 _______              ██      ██ 
   | 00__| 00 /      00|      \    \ |  \|       \           ██████████████ 
   | 00    00|  0000000| 000000\0000\| 00| 0000000\        ██              ██
   | 00000000| 00  | 00| 00 | 00 | 00| 00| 00  | 00        ██      ██      ██
   | 00  | 00| 00__| 00| 00 | 00 | 00| 00| 00  | 00        ██      ██      ██
   | 00  | 00 \00    00| 00 | 00 | 00| 00| 00  | 00        ██              ██  
    \00   \00  \0000000 \00  \00  \00 \00 \00   \00          ██████████████  
    
    */

    /**
     * Responsible for loading all of the data required to generate Citizens on-chain.

     * To be used by the owner of the contract upon deployment.

     * This function can only be called once to ensure immutability of the image data and your Citizen.
     */
    function loadCompressedData(
        bytes[][] calldata _inputTraits,
        bytes20[][] calldata _traitMetadata,
        string[6] calldata _backgrounds,
        bytes calldata _legendaryAnimations,
        bytes calldata _legendaryRects,
        bytes calldata _colorHexList,
        string[33] calldata _lookup,
        uint256 _MAX_SUPPLY
    ) external onlyOwner {
        require(!compressedDataLoaded, "Loaded");
        compressedDataLoaded = true;
        compressedTraitImages = _inputTraits;
        compressedTraitMetadata = _traitMetadata;
        backgrounds = _backgrounds;
        legendaryAnimations = _legendaryAnimations;
        legendaryPixels = _legendaryRects;
        hexColorPalette = _colorHexList;
        lookup = _lookup;
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    /**
     * The owner (0xMongoon) is allowed to mint up to 30 custom Citizens.
     * These will be reserved for giveaways || community ideas || memes.
     */
    function ownerMint(uint256[] calldata customSeeds) external onlyOwner {
        uint256 quantity = customSeeds.length;
        uint256 totalminted = _totalMinted();

        unchecked {
            if (tokensMintedByOwner + quantity > MAX_MINT_OWNER)
                revert TooMany();
            _safeMint(msg.sender, quantity);

            for (uint256 i; i < quantity; ++i) {
                tokenIdToSeed[totalminted + i] = customSeeds[i];
            }
            tokensMintedByOwner += quantity;
        }
    }

    function flipMintStatus() external onlyOwner {
        mintLive = !mintLive;
    }

    function cutSupply(uint256 _newSupply) external onlyOwner {
        if (_newSupply >= MAX_SUPPLY) revert DownOnly();
        if (_newSupply < _totalMinted()) revert BiggerSupplyPls();
        MAX_SUPPLY = _newSupply;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 eighty = (address(this).balance / 100) * 80;
        uint256 ten = (address(this).balance / 100) * 10;

        (bool sentM, ) = payable(
            address(0x5B5b71687e7cb013aE35ac9928DbD5393Ea36C63)
        ).call{value: eighty}("");
        require(sentM, "Failed to send");

        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: ten}("");
        require(sentI, "Failed to send");

        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: ten}("");
        require(sentT, "Failed to send");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utility {
    /*                         
                                                                         ▒▒▒▒ 
                                                                       ▒▒░░░░▒▒
    __    __    __      __  __  __    __                             ▒▒░░░░░░░░▒▒                   
    |  \  |  \  |  \    |  \|  \|  \  |  \                         ▒▒░░░░▒▒░░░░░░▒▒                     
    | 00  | 00 _| 00_    \00| 00 \00 _| 00_    __    __              ▒▒░░░░▒▒░░░░░░▒▒                 
    | 00  | 00|   00 \  |  \| 00|  \|   00 \  |  \  |  \               ▒▒░░░░▒▒▒▒░░░░▒▒                 
    | 00  | 00 \000000  | 00| 00| 00 \000000  | 00  | 00                 ▒▒░░▒▒▒▒░░░░░░▒▒               
    | 00  | 00  | 00 __ | 00| 00| 00  | 00 __ | 00  | 00                 ██▒▒░░░░▒▒░░░░░░▒▒            
    | 00__/ 00  | 00|  \| 00| 00| 00  | 00|  \| 00__/ 00               ██▓▓██░░░░░░▒▒░░░░▒▒                 
     \00    00   \00  00| 00| 00| 00   \00  00 \00    00             ██▓▓██  ▒▒░░░░░░▒▒░░▒▒                      
      \000000     \0000  \00 \00 \00    \0000  _\0000000           ██▓▓██      ▒▒░░░░░░▒▒                      
                                              |  \__| 00         ██▓▓██          ▒▒▒▒▒▒                        
                                               \00    00       ██▓▓██                        
                                                \000000      ██▓▓██                                                               
     ________                                 __      __     ██▓██                              
    |        \                               |  \    |  \                             
    | 00000000__    __  _______    _______  _| 00_    \00  ______   _______    _______ 
    | 00__   |  \  |  \|       \  /       \|   00 \  |  \ /      \ |       \  /       \
    | 00  \  | 00  | 00| 0000000\|  0000000 \000000  | 00|  000000\| 0000000\|  0000000
    | 00000  | 00  | 00| 00  | 00| 00        | 00 __ | 00| 00  | 00| 00  | 00 \00    \ 
    | 00     | 00__/ 00| 00  | 00| 00_____   | 00|  \| 00| 00__/ 00| 00  | 00 _\000000\
    | 00      \00    00| 00  | 00 \00     \   \00  00| 00 \00    00| 00  | 00|       00
     \00       \000000  \00   \00  \0000000    \0000  \00  \000000  \00   \00 \0000000 
                                                                                   
    */

    bytes16 private constant HEX_SYMBOLS = "0123456789abcdef";

    /**
     * Converts a bytes object to a 6 character ASCII `string` hexadecimal representation.
     */
    function _toHexString(bytes memory incomingBytes)
        internal
        pure
        returns (string memory)
    {
        uint24 value = uint24(bytes3(incomingBytes));

        bytes memory buffer = new bytes(6);
        buffer[5] = HEX_SYMBOLS[value & 0xf];
        buffer[4] = HEX_SYMBOLS[(value >> 4) & 0xf];
        buffer[3] = HEX_SYMBOLS[(value >> 8) & 0xf];
        buffer[2] = HEX_SYMBOLS[(value >> 12) & 0xf];
        buffer[1] = HEX_SYMBOLS[(value >> 16) & 0xf];
        buffer[0] = HEX_SYMBOLS[(value >> 20) & 0xf];
        return string(buffer);
    }

    /**
     * Converts a bytes20 object into a string.
     */
    function bytes20ToString(bytes20 _bytes20)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 20 && _bytes20[i] != 0) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 20 && _bytes20[i] != 0; ++i) {
            bytesArray[i] = _bytes20[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721A.sol";

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
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
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
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
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
    function _packedOwnershipOf(uint256 tokenId)
        private
        view
        returns (uint256)
    {
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
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        private
        pure
        returns (uint256 result)
    {
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
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
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

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
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
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
        safeTransferFrom(from, to, tokenId, "");
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
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
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
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

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
    function _safeMintImp(
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
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
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
        _safeMintImp(to, quantity, "");
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

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            )
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
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
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    _nextExtraData(from, address(0), prevOwnershipPacked)
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
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << _BITPOS_EXTRA_DATA);
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
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
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