// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";

import "./CollectionDescriptor.sol";

/*
                                                                    
                  ████    ████        ████    ██████                
                  ████    ████        ████    ██████                
                      ████████████████████████                      
                      ████████████████████████                      
          ██▓▓    ██▓▓████░░░░░░░░░░░░░░░░████▓▓████    ████        
          ██▓▓    ████████░░░░░░░░░░░░░░  ██████████    ████        
          ░░░░▓▓▓▓░░░░░░░░░░░░▓▓▓▓▓▓▓▓░░░░░░░░░░░░▒▒▓▓▓▓░░          
        ░░░░░░████░░░░░░░░░░░░▓▓▓▓▓▓██░░░░░░░░░░░░░░████░░░░░░      
  ████  ░░██▓▓░░░░░░░░    ████░░  ████████    ░░  ░░░░░░████░░  ████
  ████    ██▓▓░░░░░░░░    ██▓▓░░  ████▓▓██    ░░  ░░░░░░████░░  ████
      ████░░░░    ░░  ░░░░██▓▓████████▓▓▓▓░░░░░░  ░░░░  ░░░░████    
      ████░░              ██▓▓████████▓▓██              ░░░░████    
        ░░▓▓▒▒              ░░▓▓▓▓▓▓██                  ████        
          ██▓▓                ▓▓▓▓▓▓██                  ████        
            ░░████                                  ████            
              ████                                  ████            
                  ████████  ░░░░░░░░░░░░░░██████████                
                  ████████░░░░░░░░░░░░░░  ██████████                
                          ████████████████                          
                          ████████████████                          

"Witness The Draft" is an art experiment combining provenance, on-chain dynamic social artwork, and a look into the documentation of the creative process.

In November 2022, I (Simon de la Rouviere) wrote a draft of a novel, called "Witnesses of Gridlock", a sequel to "Hope Runners of Gridlock".
In 30 days, I wrote 51,591 words of the draft.
As part of National Novel Writing Month (NaNoWriMo), for each day of writing, I inserted a daily log of the day's writing into a smart contract (Witness.sol).
You can find Witness.sol here: https://etherscan.io/address/0xfde89d4b870e05187dc9bbfe740686798724f614
Thus, for 30 days, there are 30 inscriptions containing the timestamp, day_nr, the total word count, and a sentence taken from the day's writing.

The NFTs:
The "Witness The Draft" project consumes these 30 days of logs on-chain, directly into a set of 30 dynamic on-chain artworks.

Each of the 30 pieces consists of 2 parts:
Its eyes and the daily log.

Each piece contains eyes in 5x6 grid with one eye open (at the start).
This initial open eye is different from the other eyes (a radiating pupil) and is located in the grid corresponding to the day.
The grid goes as follow in terms of days:
1 2 3 4 5
6 7 8 9 10
11 12 etc ....
The colour of the eyes and the positions of the pupils are all algorithmically generated from seeds that was chosen by me (the artist).

Witnessing:

This work contains a novel social mechanic where an owner can witness other pieces in the collection.
When one witnesses another piece, their piece will open an eye at the index of your piece.
eg, if you hold day 5 and you witness day 7, the 5th eye will open up in the day 7 piece.
In different terms: if you want an eye on your piece to open up (eg, eye #24), you have to ask the owner of that piece (#24) to witness your piece.
Each owner can witness all pieces, including closing the special eye of their own piece (closing your own, special eye does not change its look).
Each owner can also choose to close an eye on other pieces, a process called "unsee".
This opening and closing of eyes can be repeated ad-infinitum.
Transfers do not reset witnesses.

This project was inspired by:
- The Mesh from Takens Theorem, where one's NFT changes depending what NFTs you and other owners hold in the collection.
- Conversations with Mackenzie Davenport and his project, Ensemble, that helps surface the objects used in the creative process.

Where applicable: The art is licensed under CC BY-SA 4.0.
*/


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner; //= 0xaF69610ea9ddc95883f97a6a3171d52165b69B03;

    CollectionDescriptor public descriptor;

    // piece => witnesses_to_piece_from_other_pieces 
    mapping (uint => bool[30]) public witnesses;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address _witnessAddress) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor(_witnessAddress);
        owner = msg.sender;

        // mint 30 pieces
        // seeds are stored in the descriptor
        for(uint i = 0; i<30; i+=1) {
            super._mint(owner, i);
            witnesses[i][i] = true; // own eye is open from start
        }
    }

    // change descriptor
    // only allowed by admin/owner until Jun 01 2023.
    // this is to fix potential issues or upgrade.
    // After Jun 01 2023, it's not possible anymore.
    function changeDescriptor(address _newDescriptor) public {
        require(msg.sender == owner, 'not owner');
        require(block.timestamp < 1685592000, 'cant change descriptor anymore'); // Thu Jun 01 2023 04:00:00 GMT+0000
        descriptor = CollectionDescriptor(_newDescriptor);
    }

    // Note: Out-of-bound calls are possible, but the tx will just normally fail.

    function witnessById(uint toID, uint fromID) public {
        _witness(toID, fromID);
    }

    /* a helper function if id is confusing */
    function witnessByDay(uint toDay, uint fromDay) public {
        _witness(toDay-1, fromDay-1);
    }

    function _witness(uint toID, uint fromID) internal {
        require(msg.sender == ownerOf(fromID), 'not authorised to witness');
        require(witnesses[toID][fromID] == false, 'already witnessed that piece'); // not entirely necessary but saves someone from making a tx
        witnesses[toID][fromID] = true;
    }

    function unseeById(uint toID, uint fromID) public {
        _unsee(toID, fromID);
    }

    function unseeByDay(uint toDay, uint fromDay) public {
        _unsee(toDay-1, fromDay-1);
    }

    function _unsee(uint toID, uint fromID) internal {
        require(msg.sender == ownerOf(fromID), 'not authorised to unsee');
        require(witnesses[toID][fromID] == true, 'eyes already closed'); // not entirely necessary but saves someone from making a tx
        witnesses[toID][fromID] = false;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId); 
        string memory description = descriptor.generateDescription();

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        // also send along witness data
        bool[30] memory wit = witnesses[tokenId];
        return descriptor.generateImage(tokenId, wit);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

import './svg.sol';
import './utils.sol';
import "./Witness.sol";

contract CollectionDescriptor {

    Witness public witness;

    // piece => seed
    mapping(uint => uint) seeds;

    // structs help with packing to avoid local variable stack limit
    struct PupilStorage {
        uint offsetx;
        uint offsety;
        uint r;
        uint xmidPoint;
        uint ymidPoint;
    }

    struct ColourInformation {
        uint currentColour;
        uint colourShift;
        uint backgroundColour;
    }

    constructor(address wAddress) {
        // the witness.sol used during November 2022 for recording the draft each day.
        // You can find Witness.sol here: https://etherscan.io/address/0xfde89d4b870e05187dc9bbfe740686798724f614
        witness = Witness(wAddress); 

        // seeds used with generator for each id.
        // this was chosen one by one to create a varied collection.
        seeds[0] = 80044491973980591444808345409934770915066006939993750435561322058588730240570; // 1
        seeds[1] = 18004466893686479750475846750781066599149533972578027177114034110612094094; // 2
        seeds[2] = 46446408789816314722985168527441250197500521464882862309868837379927497532300; // 3
        seeds[3] = 78243037955834598523754296354330632136231478761149777578091086279129948865705; // 4
        seeds[4] = 38719296808200095583233004137618424690296591149532452788354194921204740345598; // 5
        seeds[5] = 77141802634089181467468603668221328868116219376682981861897821028177395497724; // 6
        seeds[6] = 72240521973445462610965342106016983640932131370665609701456594393275291179136; // 7
        seeds[7] = 5016666528319720015994271893753993707160980119870930048193164266259859124657; // 8
        seeds[8] = 50683257957555221759441885924191778421951004669995229656364770507571699393537; // 9
        seeds[9] = 20485178893473727651555360136417090399213245805450429254690334471105182129070; // 10
        seeds[10] = 12898696858260200341493872813335639159615801200131909000013731746475826312735; // 11
        seeds[11] = 31450826090461710289246588418804345918107614504279013968666658642511836923672; // 12
        seeds[12] = 94397855848486195516281070775395676345526392813158518681787488609733347855048; // 13
        seeds[13] = 98047131257039562884189345037860937953655768579418633991401566747818554076092; // 14
        seeds[14] = 67937897153124172776566621112416148433929625029801518339226115196339591034631; // 15
        seeds[15] = 96513893435222072307039622901872387084010436523105178485723157347629094868909; // 16
        seeds[16] = 109936017627078776323170070668277740871202538860536782716108493139900530289193; // 17
        seeds[17] = 33241366968212039706794958209826905999660298292001238319345056928852181894976; // 18
        seeds[18] = 56866880486253441401961689381106735099610752563121796109237592164452812905961; // 19
        seeds[19] = 55682218754982249538672892917008104370252653468285639152580181875870162766749; // 20
        seeds[20] = 33386271639093271881338818096777559636239584853676765874245542850568381168488; // 21
        seeds[21] = 16979836803601825051267772746902854725526632224683644575787589429367332016344; // 22
        seeds[22] = 37146998103272876516168461399621631436835667105793433232786382939985764792416; // 23
        seeds[23] = 57826396149430866801743976976221609825441772722059613285641233131804547381208; // 24
        seeds[24] = 64014563562513447582805130756543578931712322821465759392667894119375361812007; // 25
        seeds[25] = 61745189215979355044195499951452558027574883951533122692785463552262059243084; // 26
        seeds[26] = 111980497258566850477615869299848135050990077617415938482923331732736978645644; // 27
        seeds[27] = 106241896171550461100197439432765486778276244230634551778639901197856125186644; // 28
        seeds[28] = 11530649775351803752718581600331065550866939730465207956172132102202209430704; // 29
        seeds[29] = 18120611061039310530414837610873998323043825134871278279888729668251509774738; // 30
    }

    /* called from Collection (tokenURI) */

    function generateName(uint tokenId) public view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);
        return string(abi.encodePacked('Day ', d.day, ': ', d.words));
    }

     function generateDescription() public pure returns (string memory) {
        string memory description = "Witness The Draft. An art project that is a fusion of 30-day literature, provenance, creativity, and dynamic social on-chain NFTs. The 30 pieces are able to witness each other, opening the eyes in other pieces.";
        return description;
    }

        function generateImage(uint256 tokenId, bool[30] memory witnesses) public view returns (string memory) {
        return render(tokenId, witnesses);
    } 
    
    function generateTraits(uint256 tokenId) public view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);

        return string(abi.encodePacked('"attributes": [',
            createTrait('logged', utils.uint2str(d.logged)),',',
            createTrait('day', d.day),',',
            createTrait('total words written', d.wordCount),',',
            createTrait('words witnessed', d.words),
            ']'
        ));
    }

    function createTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
        return string.concat(
            '{"trait_type": "',
            traitType,
            '", "value": "',
            traitValue,
            '"}'
        );
    }
    
    /* actual drawing functions */

    /*
    It's slightly janky, using a mix of hotsvg + custom svg in strings.
    */

    function render(uint256 _tokenId, bool[30] memory witnesses) internal view returns (string memory) {
        uint seed = seeds[_tokenId];
        bytes memory hash = abi.encodePacked(bytes32(seed));

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="420" style="background:#000">',
                defins(),
                draw(_tokenId, hash, witnesses),
                distortFilter(),
                text(_tokenId),
                '</svg>'
            );
    }

    function defins() internal pure returns (string memory) {
        string memory d;
        d = string.concat(d, '<clipPath id="keepTop" clipPathUnits="objectBoundingBox"><rect y="-0.1" width="1" height="0.35"/></clipPath>');
        d = string.concat(d, '<clipPath id="keepBottom" clipPathUnits="objectBoundingBox"><rect y="0.75" width="1" height="0.5"/></clipPath>');
        return d;
    }

    function draw(uint256 _tokenId, bytes memory hash, bool[30] memory witnesses) internal pure returns (string memory) {
        ColourInformation memory ci;
        ci.currentColour = utils.getColour(hash);// 0 - 360
        ci.colourShift = utils.getColourShift(hash); // 0 - 255
        string memory c;
        uint i;
        uint j;

        string memory cutout = string.concat('<mask id="eyes',utils.uint2str(_tokenId),'"> <rect width="300" height="360" fill="white" />');
        string memory background = ""; // background rect + pupil

        for(i = 0; i<6; i+=1) { //y (6 slots)
            for(j = 0; j<5; j+=1) { //x (5 slots)
                uint wi = i*5+j;
                bool open; // = false
                bool ownEye; // = false
                if (witnesses[wi] == true) { // if witnessed
                    open = true;

                    if(wi == _tokenId) { // own eye has different features
                        ownEye = true;
                        ci.backgroundColour = ci.currentColour+180; 
                    }
                } 
                
                background = string.concat(background, generateEye(hash, ci.currentColour, i, j, open, ownEye));
                cutout = string.concat(cutout, eyeCutout(i, j, open));

                ci.currentColour+=ci.colourShift;
            }
        }

        cutout = string.concat(cutout, '</mask>');
        c = string.concat(cutout, background, '<rect width="300" height="360" fill="',string.concat('hsl(',utils.uint2str(ci.backgroundColour),',70%,50%)'),'" mask="url(#eyes',utils.uint2str(_tokenId),')"/>');

        return c;
    }

    function generateEye(bytes memory hash, uint colour, uint i, uint j, bool open, bool ownEye) internal pure returns (string memory) {
        PupilStorage memory p;
        p.offsetx = utils.toUint8(hash, (i+1)*(j+1))/16; // 0 - 15
        p.offsety = utils.toUint8(hash, 32-(i+1)*(j+1))/16; // 0 - 15
        p.r = 6+utils.toUint8(hash, i*5+j+1)/64;
        p.xmidPoint = j*60;
        p.ymidPoint = i*60;
       
        string memory background = svg.rect(string.concat(
            svg.prop('width', '60'),
            svg.prop('height', '60'),
            svg.prop('x', utils.uint2str(p.xmidPoint)),
            svg.prop('y', utils.uint2str(p.ymidPoint)),
            svg.prop('fill', string.concat('hsl(',utils.uint2str(colour),',70%,50%)'))
        ));
       
        string memory eye;

        if(open == true) {
            eye = generatePupil(p, colour, ownEye);
        }

        return string.concat(
                background,
                eye,
                borders(i, j)
        );  

    }

    function generatePupil(PupilStorage memory p, uint colour, bool ownEye) internal pure returns (string memory) {
        string memory props = string.concat(
            svg.prop('r', '9'),
            svg.prop('cx',utils.uint2str(23+p.offsetx+p.xmidPoint)),
            svg.prop('cy',utils.uint2str(23+p.offsety+p.ymidPoint)),
            svg.prop('stroke-width', '7'),
            svg.prop('stroke', string.concat('hsl(',utils.uint2str(colour+180),',70%,50%)')),
            svg.prop('fill', 'black')
        );

        if(ownEye) {
            props = string.concat(
                props,
                svg.prop('stroke-dasharray', '1')
            );
        }

        return svg.el('circle', props);
    }

    function borders(uint i, uint j) internal pure returns (string memory) {
        string memory circles;

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(45+i*60)),
                    svg.prop('fill', 'none'),
                    svg.prop('stroke','black'),
                    svg.prop('stroke-width', '5')
                )
            )
        );

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(15+i*60)),
                    svg.prop('fill', 'none'),
                    svg.prop('stroke','black'),
                    svg.prop('stroke-width', '5')
                )
            )   
        );

        return circles;
    }

    function eyeCutout(uint i, uint j, bool open) internal pure returns (string memory) {
        // top circle
        string memory circles;

        string memory topStrokeFill = "none";
        if(open == true) { topStrokeFill = "black"; }

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(45+i*60)),
                    svg.prop('fill', 'black'),
                    svg.prop('clip-path','url(#keepTop)'),
                    svg.prop('stroke', topStrokeFill),
                    svg.prop('stroke-width', '5'),
                    svg.prop('stroke-dashoffset', '1.5'), // not 100% accurate, but close enough
                    svg.prop('stroke-dasharray', '2') // eyelash  
                )
            )
        );

        // bottom circle
        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(15+i*60)),
                    svg.prop('fill', 'black'),
                    svg.prop('clip-path','url(#keepBottom)'),
                    svg.prop('stroke', 'black'),
                    svg.prop('stroke-width', '5'),
                    svg.prop('stroke-dasharray', '2') // eyelash  
                )
            )   
        );

        // add line:
        // there's an odd bug on chrome where it somehow renders a thin border/line to the clip-path.
        // so this basically just lays out a line over this middle and also connects the eyes for a stronger grid-like effect.
        circles = string.concat(circles,
            '<line x1="',utils.uint2str(j*60),'" y1="',utils.uint2str(30+i*60),'" x2="',utils.uint2str(j*60+60),'" y2="',utils.uint2str(30+i*60),'" stroke="black" />'
        );

        return circles;
    }

    function text(uint tokenId) internal view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);
        string memory t = string.concat('<text x="10" y="380" fill="white" font-family="Courier" font-size="8">day ',utils.uint2str(tokenId+1),' (timestamped: ',utils.uint2str(d.logged),')</text><text y="390" x="10" fill="white" font-family="Courier" font-size="8">',d.wordCount,' total words written</text><text y="400" x="10" fill="white" font-family="Courier" font-size="8">');
        t = string.concat(t, d.words, '</text>');
        return t;
    }

    // note: designed originally with help from zond.eth
    function distortFilter() internal pure returns (string memory) {
       return '<filter id="noise-filter" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="linearRGB"><feTurbulence type="fractalNoise" baseFrequency="3" numOctaves="1" seed="1" stitchTiles="stitch" x="0%" y="0%" width="100%" height="100%" result="turbulence"/><feSpecularLighting surfaceScale="5" specularConstant="100" specularExponent="100" lighting-color="#ffffff" x="0%" y="0%" width="100%" height="100%" in="turbulence" result="specularLighting"><feDistantLight azimuth="1" elevation="90"/></feSpecularLighting> </filter><rect width="300" height="360" fill="white" opacity="0.2" filter="url(#noise-filter)"/>';
    }

    /*helper*/
    // via: https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    /*function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC721Metadata.sol";
import "./utils/Address.sol";
// import "../../utils/Context.sol";
import "./utils/Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
     * by default, can be overriden in child contracts.
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

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        // _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // modified from ERC721 template:
    // removed BeforeTokenTransfer
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
WITNESS THE DRAFT.
 __        _____ _____ _   _ _____ ____ ____    _____ _   _ _____   ____  ____      _    _____ _____ 
 \ \      / /_ _|_   _| \ | | ____/ ___/ ___|  |_   _| | | | ____| |  _ \|  _ \    / \  |  ___|_   _|
  \ \ /\ / / | |  | | |  \| |  _| \___ \___ \    | | | |_| |  _|   | | | | |_) |  / _ \ | |_    | |  
   \ V  V /  | |  | | | |\  | |___ ___) |__) |   | | |  _  | |___  | |_| |  _ <  / ___ \|  _|   | |  
    \_/\_/  |___| |_| |_| \_|_____|____/____/    |_| |_| |_|_____| |____/|_| \_\/_/   \_\_|     |_|  
                                                                                                     
Performance art in writing a draft for the book, "Witnesses of Gridlock", the sequel to "Hope Runners of Gridlock".
Each day, the amount of words written + a snippet will be logged.
Thereafter, an NFT (or NFTs) will be created from this data that was logged over the course of 30 days.
Published through Untitled Frontier Labs (https://untitledfrontier.studio). 
By Simon de la Rouviere.
As part of #NaNoWriMo (National Novel Writing Month).

Start: 1667275200 Tue Nov 01 2022 00:00:00 GMT-0400 (Eastern Daylight Time)
End: 1669870800 Thu Dec 01 2022 00:00:00 GMT-0500 (Eastern Standard Time)
*/

/*
MODIFIED for testing purposes from original
*/

contract Witness {
    
    uint256 public start;
    uint256 public end;
    address public owner;
    string public tester;
    Day[] public dayss;

    struct Day {
        uint256 logged;
        string day;
        string wordCount;
        string words;
        string extra;
    }

    //constructor(address _owner, uint256 _start, uint256 _end) {
    constructor() {

        // witness in here. recreate it
        // [1667349683,1,4821,the edge of their known world, ]
        witness('1', '4821', 'the edge of their known world', ' ');
        // [1667433371,2,7807,her dream felt out of focus, ]
        witness('2', '7807', 'her dream felt out of focus', ' ');
        // [1667526563,3,9447,the truth matters, ]
        witness('3', '9447', 'the truth matters', ' ');
        // [1667613227,4,10859,if you did it again, ]
        witness('4', '10859', 'if you did it again', ' ');
        // [1667668607,5,12286,flickering and glitching, ]
        witness('5', '12286', 'flickering and glitching', ' ');
        // [1667783747,6,14109,the bandwidth in your dreams, ]
        witness('6', '14109', 'the bandwidth in your dreams', ' ');
        // [1667873795,7,14665,seemingly at random, ]
        witness('7', '14665', 'seemingly at random', ' ');
        // [1667964863,8,15742,trails shot through the thick glass, ]
        witness('8', '15742', 'trails shot through the thick glass', ' ');
        // [1668047303,9,17401,dating advice, ]
        witness('9', '17401', 'dating advice', ' ');
        // [1668134687,10,18801,marketplace of companions, ]
        witness('10', '18801', 'marketplace of companions', ' ');
        // [1668214703,11,20940,randomly dance in their eyes, ]
        witness('11', '20940', 'randomly dance in their eyes', ' ');
        // [1668308579,12,22690,the current comes and the current goes, ]
        witness('12', '22690', 'the current comes and the current goes', ' ');
        // [1668391715,13,24487,your freedom right now is through the truth, ]
        witness('13', '24487', 'your freedom right now is through the truth', ' ');
        // [1668477863,14,26197,the singularity is coming, ]
        witness('14', '26197', 'he singularity is coming', ' ');
        // [1668569255,15,27899,whiskey against the tank, ]
        witness('15', '27899', 'whiskey against the tank', ' ');
        // [1668653099,16,29739,the obviousness of it, ]
        witness('16', '29739', 'the obviousness of it', ' ');
        // [1668737699,17,32257,an existential war by civilizations, ]
        witness('17', '32257', 'an existential war by civilizations', ' ');
        // [1668807515,18,33666,her mothers bracelet, ]
        witness('18', '33666', 'her mothers bracelet', ' ');
        // [1668914531,19,35338,process has been killed, ]
        witness('19', '35338', 'process has been killed', ' ');
        // [1668996791,20,37531,in the middle of all this, ]
        witness('20', '37531', 'in the middle of all this', ' ');
        // [1669084403,21,40042,she ran, ]
        witness('21', '40042', 'she ran', ' ');
        // [1669170503,22,43152,why am I dead, ]
        witness('22', '43152', 'why am I dead', ' ');
        // [1669257215,23,44610,why am I dead, ]
        witness('23', '44610', 'why am I dead', ' ');
        // [1669343183,24,45665,you dont have a choice i forgive you, ]
        witness('24', '45665', 'you dont have a choice i forgive you', ' ');
        // [1669430891,25,46952,sincerely hopeful, ]
        witness('25', '46952', 'sincerely hopeful', ' ');
        // [1669515395,26,47312,here with me, ]
        witness('26', '47312', 'here with me', ' ');
        // [1669601675,27,49143,humanity for anomaly reintegration and protection, ]
        witness('27', '49143', 'humanity for anomaly reintegration and protection', ' ');
        // [1669690799,28,49799,give me time, ]
        witness('28', '49799', 'give me time', ' ');
        // [1669776995,29,50470,have you or anyone you know, ]
        witness('29', '50470', 'have you or anyone you know', ' ');
        // [1669863455,30,51591,hope is a choice, ]
        witness('30', '51591', 'hope is a choice', ' ');
    }

    function returnDayss() public view returns (Day[] memory) {
        return dayss;
    }

    function witness(string memory _day, string memory _wordCount, string memory _words, string memory _extra) public {
        //require(block.timestamp > start, "not ready for witness");
        //require(block.timestamp < end, "witnessing has ended");
        //require(msg.sender == owner, "not owner");
        Day memory day;

        day.logged = block.timestamp;
        day.day = _day;
        day.wordCount = _wordCount;
        day.words = _words;
        day.extra = _extra;

        dayss.push(day);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.

// modified from original to take away functions that I'm not using

library svg {
    /* MAIN ELEMENTS */

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    
    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal 
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }

    function whiteRect() internal pure returns (string memory) {
        return rect(
            string.concat(
                prop('width','100%'),
                prop('height', '100%'),
                prop('fill', 'white')
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.

// modified from original to take away functions that I'm not using
// also includes the random number parser 
library utils {
    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint; 

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    function getColour(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 2))*360/256;  } // 0 - 360
    function getColourShift(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 3));  } // 0 - 255
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC165.sol";

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

pragma solidity ^0.8.9;

import "./IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.9;

import "./IERC721.sol";

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

pragma solidity ^0.8.9;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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