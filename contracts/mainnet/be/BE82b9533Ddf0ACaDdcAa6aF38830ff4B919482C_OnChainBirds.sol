// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12 <0.9.0;
import "./ERC721A/ERC721A.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OnChainBirds is ERC721A, Ownable {
    /*
     ____       _______        _      ___  _        __  
    / __ \___  / ___/ /  ___ _(_)__  / _ )(_)______/ /__
    / /_/ / _ \/ /__/ _ \/ _ `/ / _ \/ _  / / __/ _  (_-<
    \____/_//_/\___/_//_/\_,_/_/_//_/____/_/_/  \_,_/___/
    */
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price = 0.006 ether;
    uint256 public constant maxPerTx = 10;
    bool public imageDataLocked;

    bytes32[][16] traitNames;

    // nesting
    mapping(uint256 => uint256) private nestingTotal;
    mapping(uint256 => uint256) private nestingStarted;
    uint256 private nestingTransfer;
    bool public nestingIsOpen;

    // rendering
    uint256 private constant size = 42;
     
    uint256[7][8] private masks; // layer masks
    
    uint256[][][][7] private assets; // stores encoded pixeldata
    uint256[][6][4] private legendarybodies;
    
    mapping (uint256 => uint256) private hashExists;
    mapping (uint256 => DNA) private tokenIdToDNA;
    uint8[2592] private colorPalette;
    uint8[40] private alphaPalette = [0,0,0,77,155,154,134,7,0,0,0,115,0,0,0,26,255,255,255,115,146,235,252,102,135,234,254,38,34,34,34,26,255,255,255,128,0,0,0,38];
    uint256[][] private goldHeadChance = [[4,0,19,0,3,24,0,13,29,14],[0,30,0,23,2,0,0,0,0,0],[11,6,0,26,0,0,0,0,0,0],[21,22,0,36,0,0,0,0,0,0]];
    uint256[25] private rubyHeadChance = [17,20,32,4,0,35,11,2,30,26,14,1,33,23,36,0,19,22,16,15,3,13,0,18,34];
    uint256[][] private goldEWChance = [[0,2,0,12,0,0,0,0,0,0],[0,0,3,0,0,0,0,0,0,0],[0,10,0,0,4,0,0,0,0,0],[0,0,1,8,0,0,0,0,0,0]];
    uint256[85] private roboHeadChance = [21,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36];
    uint256[13] private roboEWChance = [0,0,0,0,0,0,1,9,10,9,10,11,12];
    uint256[11] private skelleEWChance = [0,0,1,3,5,7,9,10,11,12,0];
    uint256[25] private rubyEWChance = [0,0,7,0,10,0,0,0,0,0,0,0,5,0,0,1,0,0,0,9,3,0,0,0,0];

    struct DNA {
        uint16 Background;
        uint16 Beak;
        uint16 Body;
        uint16 Eyes;
        uint16 Eyewear;
        uint16 Feathers;
        uint16 Headwear;
        uint16 Outerwear;
        uint16 EyeColor;
        uint16 BeakColor;
        uint16 LegendaryId;
    }

    struct DecompressionCursor {
        uint256 index;
        uint256 rlength;
        uint256 color;
        uint256 position;
    }

    bool private raffleLocked;
    event FallbackRaffle(
        uint256 tokenId
    );

    constructor() ERC721A("OnChainBirds", "OCBIRD") {}

    function mint(uint256 quantity) external payable {
        unchecked {
            uint256 totalminted = _totalMinted();
            uint256 newSupply = totalminted + quantity;
            require(newSupply <= MAX_SUPPLY, "SoldOut");
            require(quantity <= maxPerTx, "MaxPerTx");
            require(msg.value >= price * quantity);
            _mint(msg.sender, quantity);
            for(; totalminted < newSupply; ++totalminted) {
                createDNA(totalminted);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override (ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "#',
                            _toString(tokenId),
                            '", "image": "data:image/svg+xml;base64,',
                            Base64.encode(
                                bytes(tokenIdToSVG(tokenId))
                            ),
                            '","attributes":',
                            tokenIdToMetadata(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    function createDNA(uint256 tokenId) private {
        unchecked {
        uint256 randinput =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            tokenId,
                            msg.sender
                        )
                    )
                );
        uint256 newDNA;
        uint256 baseDNA;
        uint256 mask = 0xFFFF;
        uint256 Beak;
        uint256 Eyes;
        uint256 Eyewear;
        uint256 rand = randinput & mask;
        // background
        uint256 backgroundId;
        uint256[7] memory background = [uint256(520),11110,10914,10899,10833,10722,10538];
        uint256 bound;
        uint256 lowerbound;
        for (uint256 j; j < background.length; ++j) {
            bound += background[j];
            if ((rand-lowerbound) < (bound-lowerbound)) backgroundId = j;
            lowerbound = bound; 
        }
        newDNA = backgroundId;
        uint256 bgIsNotZero = ((backgroundId | ((backgroundId^type(uint256).max) + 1)) >> 255) & 1;
        uint256 legendcount = tokenIdToDNA[tokenId-1].LegendaryId+(1>>bgIsNotZero);
        newDNA |= legendcount<<160;
        randinput >>= 16;
        rand = randinput & mask;
        // beak
        uint256[4] memory beak = [uint256(0),27675,27244,10617];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < beak.length; ++j) {
            bound += beak[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Beak = j;
            lowerbound = bound;
        }
        randinput >>= 16;
        rand = randinput & mask; 
        // eyes
        uint256[12] memory eyes = [uint256(0),16202,9708,9013,9006,8699,3332,1989,1936,1930,1877,1844];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < eyes.length; ++j) {
            bound += eyes[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Eyes = j;
            lowerbound = bound; 
        }
        baseDNA |= Eyes<<48;
        randinput >>= 16;
        rand = randinput & mask;
        // eyewear
        uint256[13] memory eyewear = [uint256(53738),1317,1226,1140,1121,1121,1055,931,891,878,826,800,492];
        delete bound;
        delete lowerbound;
        for (uint256 j; j < eyewear.length; ++j) {
            bound += eyewear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Eyewear = j;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // feathers
        uint256[10] memory feathers = [uint256(0),12345,9691,8301,7625,7507,7238,6072,3549,3208];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < feathers.length; ++j) {
            bound += feathers[j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= j<<80;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // head
        uint256 resultHead;
        uint256[38] memory headwear = [uint256(19390),2510,2340,2130,1730,1678,1665,1638,1632,1547,1527,1494,1429,1389,1357,1337,1324,1265,1265,1226,1199,1180,1180,1153,1147,1121,1101,970,950,826,819,786,688,662,603,524,380,374];
        delete bound;
        delete lowerbound;
        uint256 bodybound;
        for (uint256 j; j < headwear.length; ++j) {
            bound += headwear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) {resultHead = j; bodybound=lowerbound;}
            lowerbound = bound; 
        }
        // body
        uint256[11][38] memory body = [[uint256(4230),1752,2349,2204,2322,2270,2224,1182,717,94,48],[uint256(1489),952,0,0,0,0,0,0,0,48,21],[uint256(485),271,362,389,0,283,270,112,67,67,34],[uint256(847),495,698,0,0,0,0,0,0,62,28],[uint256(1051),625,0,0,0,0,0,0,0,0,54],[uint256(570),157,282,249,0,282,0,0,33,66,39],[uint256(401),211,309,348,335,0,0,0,0,27,34],[uint256(314),282,223,249,190,0,242,92,46,0,0],[uint256(1599),0,0,0,0,0,0,0,0,0,33],[uint256(563),387,492,0,0,0,0,0,0,66,39],[uint256(248),144,223,197,184,249,197,85,0,0,0],[uint256(348),212,146,205,0,199,198,0,73,73,40],[uint256(551),328,0,0,465,0,0,0,0,46,39],[uint256(792),597,0,0,0,0,0,0,0,0,0],[uint256(263),258,264,251,297,0,0,0,0,15,9],[uint256(467),277,0,447,0,0,0,0,86,0,60],[uint256(736),408,0,0,0,0,0,0,99,47,34],[uint256(288),140,159,140,126,145,152,60,21,0,34],[uint256(493),317,0,342,0,0,0,0,86,0,27],[uint256(1199),0,0,0,0,0,0,0,0,0,27],[uint256(1183),0,0,0,0,0,0,0,0,0,16],[uint256(277),131,216,229,229,0,0,98,0,0,0],[uint256(290),166,153,192,0,199,0,73,40,27,40],[uint256(223),140,153,107,205,204,0,53,34,0,34],[uint256(506),244,389,0,0,0,0,0,0,0,8],[uint256(210),125,144,229,164,164,0,59,0,0,26],[uint256(166),100,146,171,119,132,86,73,53,47,8],[uint256(373),223,308,0,0,0,0,0,0,59,7],[uint256(897),0,0,0,0,0,0,0,0,33,20],[uint256(826),0,0,0,0,0,0,0,0,0,0],[uint256(93),74,113,133,159,126,0,67,14,0,40],[uint256(786),0,0,0,0,0,0,0,0,0,0],[uint256(93),73,99,73,112,67,73,26,13,33,26],[uint256(98),67,93,73,106,73,67,52,0,0,33],[uint256(83),67,67,93,0,60,80,21,20,66,46],[uint256(105),47,67,86,0,73,0,0,21,73,52],[uint256(60),68,74,54,0,0,0,0,15,74,35],[uint256(45),39,59,66,0,66,46,0,7,0,46]];
        bound = bodybound;
        lowerbound = bodybound;
        for (uint256 j; j < 11; ++j) {
            bound += body[resultHead][j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= (j+1)<<32;
            lowerbound = bound; 
        }
        baseDNA |= resultHead<<96;
        randinput >>= 16;
        rand = randinput & mask;
        // outerwear
        uint256[8] memory outerwear = [uint256(54563),2031,1979,1717,1659,1351,1331,905];
        delete bound;
        delete lowerbound;
        for (uint256 j; j < outerwear.length; ++j) {
            bound += outerwear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= j<<112;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // beakcolor
        newDNA|=(rand & 1)<<144;
        randinput >>= 16;
        rand = randinput & mask;
        // eyecolor
        uint256 eyeIsNotColored = Eyes/6;
        uint256 EyeColor = (rand%7+1)*(1>>eyeIsNotColored)+eyeIsNotColored;
        baseDNA |= EyeColor<<128;
        // store dna
        uint256 found;
        randinput >>= 16;
        uint256 baseHash = baseDNA|bgIsNotZero<<192;
        for(uint256 i; i<5; ++i) {
            uint256 isNotLast = 1>>(i>>2);//1>>(i/4);
            uint256 hashedDNA = baseHash|Beak<<16|Eyewear<<64|(((1>>isNotLast)*tokenId)<<212);
            if(hashExists[hashedDNA]+found == 0) {
                newDNA |= (hashedDNA<<64)>>64;
                assembly {
                    mstore(0, tokenId)
                    mstore(32, tokenIdToDNA.slot)
                    let hash := keccak256(0, 64)
                    sstore(hash, newDNA)
                }
                ++hashExists[hashedDNA];
                ++found;
                }
            Beak = Beak%3+1;
            if(i==0) Eyewear = (Eyewear + randinput%8)%13;
            Eyewear = ++Eyewear%13;
        }
        }
    }
    
    function getDNA(uint256 tokenId) public view returns(DNA memory) {
        DNA memory realDNA = tokenIdToDNA[tokenId];
        // legendary id
        if(realDNA.Background == 0) {
            if(realDNA.LegendaryId>74) {
                realDNA.Background = 1;
                delete realDNA.LegendaryId;
            } else {
                uint256 specialType = realDNA.LegendaryId%3;
                uint256 specialIndex = realDNA.LegendaryId/3;
                if(specialType==0) {
                    //legendary (specialIndex starts at 1)
                    delete realDNA.Beak;
                    delete realDNA.Eyes;
                    delete realDNA.Eyewear;
                    delete realDNA.Headwear;
                    delete realDNA.Outerwear;
                    delete realDNA.EyeColor;
                    delete realDNA.BeakColor;
                    uint256 legendmod = (specialIndex-1)%4;
                    uint256 legenddiv = (specialIndex-1)/4;
                    realDNA.Background = uint16(7 + legendmod);
                    realDNA.Body = uint16(legendmod+1);
                    realDNA.Feathers = uint16(legenddiv+1);
                    return realDNA;
                } else if(specialType==1) {
                    //golden (specialIndex starts at 0)
                    realDNA.Body = 12;
                    uint256 feathermod = specialIndex%5;
                    uint256 featherdiv = specialIndex/5;
                    if(feathermod<2) featherdiv=(featherdiv<<1)+feathermod;
                    if(feathermod==0) ++feathermod;
                    realDNA.Feathers=uint16(feathermod);
                    realDNA.Headwear = uint16(goldHeadChance[--feathermod][featherdiv]);
                    realDNA.Background = uint16((specialIndex%6)+1);
                    realDNA.Eyewear = uint16(goldEWChance[feathermod][featherdiv]);
                } else if(specialType==2) {
                    //ruby (specialIndex starts at 0)
                    realDNA.Body = 13;
                    realDNA.Background = uint16((specialIndex%6)+1);
                    realDNA.Headwear = uint16(rubyHeadChance[specialIndex%25]);
                    realDNA.Eyewear = uint16(rubyEWChance[specialIndex%25]);
                }
            }
        } else {
            delete realDNA.LegendaryId;
        }
        // special bodies except robot -> no outerwear
        if(realDNA.Body > 10) {
            delete realDNA.Outerwear;
        }
        // single color eyes
        if(realDNA.Eyes > 5) {
            realDNA.EyeColor = 1;
        }
        // special bodies
        if(realDNA.Body > 9) {
            delete realDNA.BeakColor;
            delete realDNA.EyeColor;
            // golden body
            if(realDNA.Body == 12) {
                if(realDNA.Eyes == 2 || realDNA.Eyes == 9) {
                    realDNA.Eyes = 1;
                } else if(realDNA.Eyes == 7 || realDNA.Eyes == 6) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Eyes == 5) {
                    realDNA.Eyes = 4;
                } else if(realDNA.Eyes == 8 || realDNA.Eyes > 9) {
                    realDNA.Eyes = 5;
                } else {
                    realDNA.Eyes = 3;
                }
            } else {
                realDNA.Feathers = 1;
                // shuffle hash
                uint256 dist = uint256(keccak256(abi.encodePacked(tokenId,realDNA.Eyes)));
                uint256 mask = 0xFFFFFFFFFFFFFFFF;
                if(realDNA.Body == 10) {
                    // robot body
                    realDNA.Outerwear = uint16((dist&mask)%3);
                    realDNA.Eyewear = uint16(roboEWChance[((dist>>64)&mask)%11]);
                    realDNA.Headwear = uint16(roboHeadChance[((dist>>128)&mask)%85]);
                    realDNA.Eyes = uint16((dist>>192)%2+1);
                } else if(realDNA.Body == 11) {
                    // skelleton body
                        realDNA.Eyes = uint16((dist&mask)%6+1);
                        realDNA.Eyewear = uint16(skelleEWChance[(dist>>64)%11]);
                } else {
                    // ruby skelleton
                    realDNA.Beak = 1;
                    if(realDNA.Eyes > 5 && realDNA.Eyes < 9) {
                        realDNA.Eyes = 1;
                    } else if(realDNA.Eyes == 3 || realDNA.Eyes > 8) {
                        realDNA.Eyes = 2;
                    } else if(realDNA.Eyes == 5 || realDNA.Eyes == 1) {
                        realDNA.Eyes = 3;
                    } else {
                        realDNA.Eyes = 4;
                    }
                }
                    
            }
        }
        // hoodie -> raincloud, crescent, no eyewear
        if(realDNA.Outerwear == 3) {
            realDNA.Body = 1;
            delete realDNA.Eyewear;
            if(realDNA.Headwear < 26) {
                delete realDNA.Headwear;
            } else {
                realDNA.Headwear = 5;
            }
        }
        // heros cap -> heros outerwear, no eyewear 
        if(realDNA.Headwear == 31) {
            realDNA.Outerwear = 8;
            delete realDNA.Eyewear;
        }
        // space helmet -> no outerwear
        if(realDNA.Headwear == 6) {
            delete realDNA.Outerwear;
            if(realDNA.Eyewear == 8) {
                delete realDNA.Eyewear;
            }
        }
        // headphones
        if(realDNA.Headwear == 21) {
            // -> job glasses or none
            if(realDNA.Eyewear != 2) delete realDNA.Eyewear;
            // -> diamond necklace or none
            if(realDNA.Outerwear != 6) delete realDNA.Outerwear;
        }
        // aviators cap -> no eyewear, no bomber, jeans and hoodie down outerwear
        if(realDNA.Headwear == 13) {
            delete realDNA.Eyewear;
            if(realDNA.Outerwear % 2 == 1 && realDNA.Outerwear != 3) delete realDNA.Outerwear;
        }
        // beanie -> no sunglasses, rose-colored glasses, aviators, monocle, 3d glasses
        if(realDNA.Headwear == 8) {
            if((realDNA.Eyewear%2 == 1 && realDNA.Eyewear != 1) || realDNA.Eyewear == 8)
                delete realDNA.Eyewear;
        }
        // eyewear -> no eyes except if eyepatch, monocle, half-moon, big tech
        if(realDNA.Eyewear > 1) {
            // monocle -> no side-eyes
            if(realDNA.Eyewear == 8) {
                // no bucket hat combo
                if(realDNA.Headwear == 28) {
                    delete realDNA.Eyewear;
                } else if(realDNA.Eyes == 5 && realDNA.Body != 11)
                    realDNA.Eyes = 1;
            }
            // half-moon spectacles -> open, adorable, fire eyes
            else if(realDNA.Eyewear == 12) {
                if(realDNA.Body == 10) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Body == 11) {
                    if(realDNA.Eyes != 4 && realDNA.Eyes != 5) realDNA.Eyes = 1;
                } else if(realDNA.Body == 12) {
                    realDNA.Eyes = 3;
                } else if(realDNA.Body == 13) {
                    if(realDNA.Eyes != 3) realDNA.Eyes = 1;
                } else if(realDNA.Eyes != 6 && realDNA.Eyes != 9) {
                    realDNA.Eyes = 1;
                }
            }
            // big tech -> open eyes
            else if(realDNA.Eyewear == 10) {
                if(realDNA.Body == 10) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Body == 11) {
                    realDNA.Eyes = 5;
                } else if(realDNA.Body > 11) {
                    realDNA.Eyes = 3;
                } else {
                    realDNA.Eyes = 1;
                }
            } else {
                delete realDNA.Eyes;
                delete realDNA.EyeColor;
            }
        }
        return realDNA;
    }

    function decodeLength(uint256[] memory imgdata, uint256 index) private pure returns (uint256) {
        uint256 bucket = index >> 4;
        uint256 offset = (index & 0xf) << 4;
        uint256 data = imgdata[bucket] >> (250-offset);
        uint256 mask = 0x3F;
        return data & mask;
    }

    function decodeColorIndex(uint256[] memory imgdata, uint256 index) private pure returns (uint256) {
        uint256 bucket = index >> 4;
        uint256 offset = (index & 0xf) << 4;
        uint256 data = imgdata[bucket] >> (240-offset);
        uint256 mask = 0x3FF;
        return data & mask;
    }

    function tokenIdToSVG(uint256 tokenId) private view returns (string memory) {
        // load data
        DNA memory birdDNA = getDNA(tokenId);
        bool trueLegend = birdDNA.Background>6;
        uint256 colorPaletteLength = colorPalette.length/3;
        uint256 lastcolor;
        uint256 lastwidth = 1;
        bool[] memory usedcolors = new bool[](875);
        bytes memory svgString;
        // load pixeldata
        uint256[][7] memory compressedData;
        compressedData[0] = assets[0][birdDNA.Background-1][0];
        // legendary bodies
        if(trueLegend){
            compressedData[1] = legendarybodies[birdDNA.Body-1][birdDNA.Feathers-1];
        } else {
            compressedData[1] = assets[2][birdDNA.Body-1][birdDNA.Feathers-1];
        }
        if(birdDNA.Beak!=0){
            // special bodies -> special beaks
            if(birdDNA.Body>9){
                compressedData[2] = assets[1][birdDNA.Body-7][birdDNA.Beak-1];
            } else {
                compressedData[2] = assets[1][birdDNA.Beak-1][birdDNA.BeakColor];
            }
        } 
        if(birdDNA.Eyes!=0) {
            // special bodies -> special eyes
            if(birdDNA.Body>9){
                compressedData[3] = assets[3][birdDNA.Body+1][birdDNA.Eyes-1];
            } else {
                compressedData[3] = assets[3][birdDNA.Eyes-1][birdDNA.EyeColor-1];
            }
        }
        if(birdDNA.Eyewear!=0) compressedData[4] = assets[4][birdDNA.Eyewear-1][0];
        if(birdDNA.Headwear!=0) compressedData[5] = assets[5][birdDNA.Headwear-1][0];
        if(birdDNA.Outerwear!=0) compressedData[6] = assets[6][birdDNA.Outerwear-1][0];

        DecompressionCursor[7] memory cursors;
        for(uint256 i = 1; i<7; ++i) {
            if(compressedData[i].length != 0) {
            cursors[i]=DecompressionCursor(0,decodeLength(compressedData[i],0),decodeColorIndex(compressedData[i],0),0);
            }
        }
        // masks
        uint256[7][7] memory bitmasks;
        for(uint256 i; i<7; ++i) {
            if(i==1 && trueLegend) {
                bitmasks[i] = masks[7];
            } else {
                bitmasks[i] = masks[i];
            }
        }
        // create SVG
        bytes14 preRect = "<rect class='c";
        for(uint256 y; y < size;++y){
            bytes memory svgBlendString;
            for(uint256 x; x < size;++x){
                bool blendMode;
                uint256 coloridx;
                uint256 index = y*size+x;
                uint256 bucket = index >> 8;
                uint256 mask = 0x8000000000000000000000000000000000000000000000000000000000000000 >> (index & 0xff);
                // pixeldata decoding
                for(uint256 i = 6; i!=0; i--) {
                    if(compressedData[i].length != 0) {
                    if (bitmasks[i][bucket] & mask != 0) {
                        cursors[i].index++;
                        if(cursors[i].color != 0) {
                            if(coloridx == 0) {
                                coloridx = cursors[i].color;
                                if(cursors[i].color>colorPaletteLength) {
                                    blendMode=true;
                                }
                            } else if(blendMode) {
                                svgBlendString = abi.encodePacked(
                                    preRect,
                                    _toString(cursors[i].color),
                                    "' x='",
                                    _toString(x),
                                    "' y='",
                                    _toString(y),
                                    "' width='1'/>",
                                    svgBlendString
                                );
                                if(cursors[i].color<=colorPaletteLength) {
                                    blendMode=false;
                                }
                                usedcolors[cursors[i].color] = true;
                            }
                        }
                        if(cursors[i].index==cursors[i].rlength) {
                            cursors[i].index=0;
                            cursors[i].position++;
                            if(cursors[i].position<compressedData[i].length*16){
                                cursors[i].rlength=decodeLength(compressedData[i],cursors[i].position);
                                cursors[i].color=decodeColorIndex(compressedData[i],cursors[i].position);
                            }
                            
                        }
                    }   
                    }
                }
                // finalize pixel color
                if(coloridx==0 || blendMode) {
                    uint256 bgcolor;
                    if(birdDNA.Background > 6 && birdDNA.Background != 9){
                        bgcolor = decodeColorIndex(compressedData[0],y);
                    } else {
                        bgcolor = decodeColorIndex(compressedData[0],0);
                    }
                    if(coloridx==0) {
                        coloridx=bgcolor;
                    }
                    else if(blendMode){
                        svgBlendString = abi.encodePacked(
                                    preRect,
                                    _toString(bgcolor),
                                    "' x='",
                                    _toString(x),
                                    "' y='",
                                    _toString(y),
                                    "' width='1'/>",
                                    svgBlendString
                                );
                        usedcolors[bgcolor] = true;
                    }
                }
                usedcolors[coloridx] = true;
                if(x == 0) {
                    lastwidth = 1;
                } else if(lastcolor == coloridx) {
                    lastwidth++;
                } else {
                    svgString = abi.encodePacked( 
                        svgString,
                        svgBlendString,
                        preRect,
                        _toString(lastcolor),
                        "' x='",
                        _toString(x-lastwidth),
                        "' y='",
                        _toString(y),
                        "' width='",
                        _toString(lastwidth),
                        "'/>"
                    );
                    svgBlendString = ""; 
                    lastwidth = 1;
                }
                lastcolor = coloridx;
            }
            svgString = abi.encodePacked( 
                        svgString,
                        svgBlendString,
                        preRect,
                        _toString(lastcolor),
                        "' x='",
                        _toString(42-lastwidth),
                        "' y='",
                        _toString(y),
                        "' width='",
                        _toString(lastwidth),
                        "'/>"
                    );
            svgBlendString = "";
        }
        // generate stylesheet
        bytes memory stylesheet;
        for(uint256 i; i<usedcolors.length; ++i) {
           if(usedcolors[i]) {
            bytes memory colorCSS;
            uint256 paletteIdx = (i-1)*3;
            if(paletteIdx>=colorPalette.length) {
                uint256 fixedColorIdx = (i-1)-colorPalette.length/3;
                paletteIdx = fixedColorIdx<<2;
                uint256 dec = uint256(alphaPalette[paletteIdx+3])*100/255;
                colorCSS = abi.encodePacked("rgba(", _toString(uint256(alphaPalette[paletteIdx])), ",", _toString(uint256(alphaPalette[paletteIdx+1])), ",", _toString(uint256(alphaPalette[paletteIdx+2])), ",0.", _toString(dec), ")");
            } else {
                colorCSS = abi.encodePacked("rgb(", _toString(uint256(colorPalette[paletteIdx])), ",", _toString(uint256(colorPalette[paletteIdx+1])), ",", _toString(uint256(colorPalette[paletteIdx+2])), ")");
            }
            stylesheet = abi.encodePacked(stylesheet, ".c", _toString(i), "{fill:", colorCSS, "}");
            }
        }
        // combine full SVG
        svgString =
            abi.encodePacked(
                '<svg id="bird-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 42 42"> ',
                svgString,
                "<style>rect{height:1px;} #bird-svg{shape-rendering: crispedges;} ",
                stylesheet,
                "</style></svg>"
            );

        return string(svgString);
    }
    
    function tokenIdToMetadata(uint256 tokenId) private view returns (string memory) {
        unchecked {
        DNA memory tokenDNA = getDNA(tokenId);
        string memory metadataString;
        for (uint256 i; i < 8; ++i) {
            uint256 traitId;
            uint idx1;
            uint idx2;
            if(i==0) {
                traitId = tokenDNA.Background;
            } else if(i==1) {
                traitId = tokenDNA.Beak;
            } else if(i==2) {
                traitId = tokenDNA.Body;
                if(tokenDNA.Background > 6) {
                    idx1 = 8;
                    idx2 = traitId-1;
                }
            } else if(i==3) {
                traitId = tokenDNA.Eyes;
                if(tokenDNA.Body > 9) {
                    idx1 = tokenDNA.Body;
                    idx2 = traitId-1;
                }
            } else if(i==4) {
                traitId = tokenDNA.Eyewear;
            } else if(i==5) {
                traitId = tokenDNA.Feathers;
                if(tokenDNA.LegendaryId != 0 && tokenDNA.Body != 13) {
                    idx1 = 9;
                    idx2 = traitId-1;
                } else if(tokenDNA.Body > 9) {
                    idx1 = 14;
                    idx2 = tokenDNA.Body-10;
                }
            } else if(i==6) {
                traitId = tokenDNA.Headwear;
            } else if(i==7) {
                traitId = tokenDNA.Outerwear;
            }
            if(traitId == 0) continue;
            string memory traitName;
            if(idx1 == 0) {
                idx1 = i;
                idx2 = traitId-1;
            }
            traitName = bytes32ToString(traitNames[idx1][idx2]);
            
            string memory startline;
            if(i!=0) startline = ",";

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    startline,
                    '{"trait_type":"',
                    bytes32ToString(traitNames[15][i]),
                    '","value":"',
                    traitName,
                    '"}'
                ));
        }
        return string.concat("[", metadataString, "]");
        }
    }
    
    /**
        Nesting Functions
     */
    
    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total) {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    function transferWhileNesting(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        nestingTransfer = 1;
        transferFrom(from, to, tokenId);
        delete nestingTransfer;
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(nestingStarted[tokenId] == 0 || nestingTransfer != 0, "Nesting");
        }
    }

    function toggleNesting(uint256[] calldata tokenIds) external {
        bool nestOpen = nestingIsOpen;
        for (uint256 i; i < tokenIds.length; ++i) {
            require(ownerOf(tokenIds[i]) == msg.sender);
            uint256 start = nestingStarted[tokenIds[i]];
            if (start == 0) {
                require(nestOpen);
                nestingStarted[tokenIds[i]] = block.timestamp;
            } else {
                nestingTotal[tokenIds[i]] += block.timestamp - start;
                nestingStarted[tokenIds[i]] = 0;
            }
        }
    }

    /**
        Admin Functions
     */

    // fallback raffle in case the random generation does result in a few missing special/legendary birds
    function raffleUnmintedSpecials() external onlyOwner {
        uint256 supply = _totalMinted();
        require(!raffleLocked && supply>=MAX_SUPPLY);
        uint256 specialsMinted = tokenIdToDNA[supply-1].LegendaryId;
        while(specialsMinted < 74) {
            uint256 randomId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, specialsMinted))) % supply;
            while(tokenIdToDNA[randomId].Background == 0) {
                randomId = (++randomId)%supply;
            }
            tokenIdToDNA[randomId].LegendaryId = uint16(++specialsMinted);
            delete tokenIdToDNA[randomId].Background;
            emit FallbackRaffle(randomId);
        }
        raffleLocked = true;
    }

    // fallback reroll to prevent clones, is fairly rare, called as fast as possible after mint if detected
    function rerollClone(uint256 tokenId1, uint256 tokenId2) external onlyOwner {
        DNA memory bird = getDNA(tokenId1);
        DNA memory clone = getDNA(tokenId2);
        delete bird.Background;
        delete bird.BeakColor;
        delete clone.Background;
        delete clone.BeakColor;
        require(keccak256(abi.encode(bird)) == keccak256(abi.encode(clone)));
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        tokenIdToDNA[tokenId1].Eyes = uint16((randomHash&0xFFFFFFFF)%11+1);
        randomHash>>=32;
        tokenIdToDNA[tokenId1].Beak = uint16((randomHash&0xFFFFFFFF)%3+1);
        randomHash>>=32;
        tokenIdToDNA[tokenId1].Outerwear = uint16(randomHash%8);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert();
    }

    function expelFromNest(uint256 tokenId) external onlyOwner {
        require(nestingStarted[tokenId] != 0);
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        delete nestingStarted[tokenId];
    }

    function setNestingOpen() external onlyOwner {
        nestingIsOpen = !nestingIsOpen;
    }

    function uploadImages1(uint256[][][][7] calldata defaultdata) external onlyOwner {
        if(imageDataLocked) revert();
        assets = defaultdata;
    }
    function uploadImages2(uint256[][][] calldata bodydata) external onlyOwner {
        if(imageDataLocked) revert();
        assets[2] = bodydata;
    }
    function uploadImages3(uint256[][][4] calldata specialbodydata, uint256[][6][4] calldata legenbodydata, uint8[2592] calldata cpalette, uint256[7][8] calldata _masks, bytes32[][16] calldata _traitnames) external onlyOwner {
        if(imageDataLocked) revert();
        assets[2].push(specialbodydata[0]);
        assets[2].push(specialbodydata[1]);
        assets[2].push(specialbodydata[2]);
        assets[2].push(specialbodydata[3]);
        colorPalette = cpalette;
        masks = _masks;
        traitNames = _traitnames;
        legendarybodies = legenbodydata;
        imageDataLocked=true;
    }

    /**
        Utility Functions
     */

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint256 i;
        while(_bytes32[i] != 0 && i < 32) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < bytesArray.length; ++i) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    // tokensOfOwner function: MIT License
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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