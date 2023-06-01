// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/MerkleProof.sol";
import "./CollectionDescriptor.sol";

/*
Daisychains: Life In Every Breath.
A collection from the Logged Univere Story: MS-OS by Andy Tudhope.
https://www.untitledfrontier.studio/blog/logged-universe-5-ms-os

Scattered across that empty street, a ceramic shard came to rest in the storm water drain. 
“Give your time without fear or grief,” it said. “This is grace.”

ooolc:,.                ..........',,..,:;'.      ..';:::::::;;,.                               .;od
''...                   ..,,,,,;;::coxdoddo:.    ..';::::::clodd:::,.           ..               'ld
                         .';::::::lxKNXkddddl,.  .,;:cc::cdOKNNKxddo;.        ....               .;o
                         ..,:::::cxXWMWXOxdddl' .,;:coolokXWMMWKxdddc.     ...,,'..               .,
                          .,;cccclOWMMMWN0xddo;..;:coxxdOWMMMMWKxdddl'   ..',;;;;'..                
                ..'...    .';clood0WMMMMMWKkdo;.':loxOOkXMMMMMWXkdddc. ..,;:::::::;'..              
            ....;looolc;.. .,:ldkxkNMMMMMMWXOd:':dxx0K0XWMMMMMWXkddc'..,;:clc:::::::;,.             
          ..';:lxkxdddddoc'..;ldk0OKMMMMMMWNKxlclxkOK0KWMMMMMMWXkdc'.';clodollodxxxdo:.             
        ..';::ckNNK0Okxdddl,.'cdOK0KWMMMWWNOdllcoxOOkOXNWWWMWWNKkl;,:ldxkkxxOKXWWWWXOoc:'           
  ......',::::lOWMMWWNX0Oxdo;':dk000XNNXKOxocclldxdlloxOOOOOkxdoolcoxO000O0NMMMMMWNOxddo;.          
   ...,,;:::::cxXWMMMMMWWNKOxllldOkdxkkxddoc,;cldolc:cloddolc:cllldk00KKXNMMMMMMWNOxdddl'           
      .',;::ccclkNMMMMMMMMWNOolloxdccclool;..'coxdlcccllc:,.';clodddxOXWMMMMMMMWNOxdddl,            
       ..';:cloddk0NMMMMMMMXdccllldoc:clc;'. .cdkdlccc:;'...,codolccokKNWWMMMMWXOxddoc'      .......
         ..,;:loxOO0XWMMMWXkoo:,:coxdccc:,. .:k0Oxoc:;'.  .;ldxoc:ccldxkOKXNWNXOdoc;'.....'''',,,,..
           ..';coxOKKKNWNKOddl,..,ldkxlc:,..,OWWNOoc;'..'oOOkkdcccccllllooldxkxo:,'.',;;::::::::;'..
   ..',;;;;,...';oxOK0Okkdoooc,. .;x00Oo:,..:XMMMKxl'..lKWMWKdc::;,,'..';:clllllllllooooolcc:::::,..
  'cooddddddol:,';lodOxocccclc;'. .kWWWXkc..oXWWWXKo.,dXMMMNk:;,...  ..,:clodddkO000OOkxdolccc:::;'.
 .,oxxxxxxxxxxxxdooccoddolcccc:;...cKWMMN0l;kNNNNNXkoKNNNWNk;...,;:lccldddoooodk0KKKKK0KKXKK0Oxl::;.
,;cxKXXXXXXNNNNNNKxlclclodxdolc:;'..cKNNNNXOKWMWWNNXNMMWNN0l:cokKNWWKkxxolcc:coOXNWMMMMMMMMMMWNKxl,.
;::oKWMMMMMMMMMMMW0llc;,;cldkOOkdl;..oXNWWWNKKK0OOOO0KKXNNKKXXNWMMWXkolccccclldOXWMMMMMMMMMMWXKOko;.
:::coOXWMMMMMMMMMWKxdo,....;xXWWWNX0xd0WMWKkxxookkkxodxxkKWMWNNWNKxc;;;,;;:ccodxkKWMMMMMWWNKOxdddoc'
:::::cok0XNWWMMMMNKkdoc;'.  'oKWMMWNNNNN0OddkkddkxddxkxddxOKNWXOd:..........',:ood0NWWNX0Oxdddddo:'.
::::cclodxO0KXXNNX0xoolc:;'...':xKXNWWWKxxxddxxdddldxddxkkkx0WNK0Okxdddc;....',:cclxOOkxdddoolc;..  
,;;::ccloxkO00000kdlcccccc:;,,'..:d0NWNkddxxxddollcloddxxxxdkNMWNNWMMMMWKxolllccllccll;,,,''...     
....',,;;:cloxkkOkdolllloooodxxxkOO0XW0xxxddddoc;'';coodxxkkx0WWNNNNXXK0kxxdddooodddodl:;,''.....   
      .....',:lllodoooddxxk0NWWMMWNNWMXxdxxxdddl:;;:loddddddxKWN0dc:;:ccccccccccloxO00Okxolcc::;,,'.
    .';::cccclddlclc:;;,,,:x0XNNNNXNWMWOdxxxxdddoodoodddxkxdOWMWN0d;...',;:cclllok0KKKK0Okxdolcc:::;
 .':loddddxkOKXX0dclc,... ...,;,;:ldOXWXkxxdddxxddkxdxkxodxkXWWNNNNNOl,. .';:lodx0NWWWNXK0Okdl::::::
.:lddddxk0XNWMMMWNOxdoc:,,''.'''';oOXNWWNKkdxkxddkkkddkxdkKNNK0XNWMMMW0l.  .':odxKWMMMMMMMWWXOdc::::
'codxkOKNWMMMMMMMWN0xdoolc::::cokKNWWNNWWWX0OOkxxxxxxkOOKNWWW0l;cxOKXXKkl;'..,looKWMMMMMMMMMMWXkl::;
.,lkKNWMMMMMMMMMMMWXOdlcccclodkKWMMMNKOkdONWWWWNKKKXNWWXXNNNNXk, .;clodxxdoc::cclkNWWWWWWWWWWWWXxc:;
.;cok0XNWWMWWNNXNXK0kocclloxxxxOK0kd:'.'oXWNNWW00NNNWWWOoONWWWWk'..,:ccclodoooolldO0000000OOOOOOd:'.
.,::ccodxxkkkOO00000Oxddooolc;'.......,oKWMWN0d;dNWWNNXd.,dKWMMNd. .,:ccc:cloxxlll::loddddddddddl,. 
..,::::::codxxxxxxxxollllc:,......',;:lOWMMWk;..oXWWMWXc..;lkXXXk' ..;clllloox0Oxd:'.',:lloollc:,.  
..';::::ccccccc:;;;:loollccc:::::::cclk0XWKo'..,l0WWMMK;..,:cdkkd:. .,codxkKK00K0kdc;'.........     
..';;;;;;;,,'....,:ldOK00kxxxdoolccclxkxdl'...,:ck0KXXd. .,:ccoxxo:,.,odx0XWWWNK00Oxlc;,..          
..''......   .':lodxKNWMMWWXKOxoc:cldxo:.  .';:ccdOkxo' ..;ccccldolc:clo0WWMMMMWKOkxdoc:;,..        
..          .:odddkKWMMMMMMMWXOdllodol:,..';:ccccdkkdc. .,:llc::ldollclkNMMMMMMMWN0xolcc::,'.       
           .:odddkKWMMMMMMMWNK0Okxdolc:::cloolc:coxdlc,.,coddoollxkoclokXNWMMMMMMMW0oc:::::;,..     
           ,ldddkKWMMMMMMNK0K00Oxollllloxxxxdolccdxoll::ldxkOKK0kO0xoc:lxk0XNWWMMMMNkl:::::;,''...  
          .,lodkKWMMMMWN0kkOOkdoc:ldk0KXXNXXX0xdxkxdlllldOXNWWWNK0Kkd:.'codxkO0KNWMWOl:::;'.....    
           ..,lk0KKK0Oxdoxxdol;'.;okXWMMMMMMWX000xolcldOXWMMMMMWK00Odc,..:oddddxxOKKxc:;'..         
             .;:cclccc:clocc;'..;odkXWMMMMMMNKKKkxdl;cx0NWMMMMMMXkOkdl:'..':loddddol;,'..           
             ..';::::::cc:;,...;oddkXWMMMMMN0O0kdl:,.;ox0NWMMMMMWOdxdl:;.   .',;::;'                
               ..',;:::;;'..  .ldddkKWMMMMMKxkkdl:,..;odxOXWMMMMW0olllc:,.                          
.                ..,;;,'..    'ldddxKWMMMWXxoddl:,'..,odddkKNWMWNkl::c::,.                          
c'                .',..       .:oddx0WWWXOoccllc;'.. .:odddx0NWN0oc:::::;'.                         
oc.               ...          'coodO0Oxoc:::cc:,..   .;ldddx0Kklc::::;;;,.                       ..
dl,.              ..            ...':c:::::::::,..     .':llc:::;;,,'...''..                 ..,;;:c
do;.    .                          .';;;;::::;;'.        .','..''...........                .:lodddd
*/

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner; // = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03
    address payable public recipient; // in this instance, it will be a 0xSplit on mainnet

    CollectionDescriptor public descriptor;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    uint256 public deluxeBuyableSupply;
    mapping(uint256 => bool) public deluxeIDs;

    // for loyal mints
    mapping (address => bool) public claimed;
    bytes32 public loyaltyRoot;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address payable recipient_, uint256 startDate_, uint256 endDate_, bytes32 root_) ERC721(name_, symbol_) {
        owner = msg.sender;
        descriptor = new CollectionDescriptor();
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        loyaltyRoot = root_;

        // mint #1 to UF to kickstart it. this is from the loyal mint so also set claim to true.
        _createNFT(owner, block.timestamp, true);
        claimed[owner] = true;
    }

    // change descriptor (in case there's issues)
    // only allowed by admin/owner until 1 December 2023.
    // this is to fix potential issues or upgrade.
    // After Dec 01 2023, it's not possible anymore.
    function changeDescriptor(address _newDescriptor) public {
        require(msg.sender == owner, 'not owner');
        require(block.timestamp < 1701406800, 'cant change descriptor anymore'); //Fri Dec 01 2023 05:00:00 GMT+0000
        descriptor = CollectionDescriptor(_newDescriptor);
    }

    /*
    ERC721 code
    */
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateURI(tokenId, deluxe);
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateBase64Image(tokenId, deluxe);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateImage(tokenId, deluxe);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateTraits(tokenId, deluxe);
    }

    /*FOR STATS*/
    function generateFullTraitsFromVM(uint256 _seed, address _minter, bool deluxe) public view returns (string memory) {
        uint256 customTokenId = uint(keccak256(abi.encodePacked(_seed, _minter))); // seed = timestamp
        return descriptor.generateTraits(customTokenId, deluxe);
    }

    /*
    VM Viewers:
    These drawing functions are used inside the browser vm to display the NFT without having to call a live network.
    */

    // Generally used inside the browser VM
    function generateFullImageFromVM(uint256 _seed, address _owner, bool deluxe) public view returns (string memory) {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        return descriptor.generateImage(tokenId, deluxe);
    }

    function generateImageFromTokenIDAndDeluxe(uint256 tokenId, bool deluxe) public view returns (string memory) {
        return descriptor.generateImage(tokenId, deluxe);
    }

    /* PUBLIC MINT OPTIONS */
    function mintDeluxe() public payable {
        deluxeBuyableSupply+=1;
        require(deluxeBuyableSupply <= 96, "ALL DELUXE HAS BEEN SOLD");
        require(msg.value >= 0.055 ether, "MORE ETH NEEDED"); // ~$100 (~1900/ETH)
        _mint(msg.sender, block.timestamp, true);
    }

    function mint() public payable {
        require(msg.value >= 0.016 ether, "MORE ETH NEEDED"); // ~$30 (~1900/ETH)
        _mint(msg.sender, block.timestamp, false);
    }

    function loyalMint(bytes32[] calldata proof) public {
        loyalMintLeaf(proof, msg.sender);
    }

    // anyone can mint for someone in the merkle tree
    // you just need the correct proof
    function loyalMintLeaf(bytes32[] calldata proof, address leaf) public {
        // if one of addresses in the overlap set
        require(claimed[leaf] == false, "Already claimed");
        claimed[leaf] = true;

        bytes32 hashedLeaf = keccak256(abi.encodePacked(leaf));
        require(MerkleProof.verify(proof, loyaltyRoot, hashedLeaf), "Invalid Proof");
        _mint(leaf, block.timestamp, true); // mint a deluxe mint for loyal collector
    }

    /* INTERNAL MINT FUNCTIONS */
    function _mint(address _owner, uint256 _seed, bool _deluxe) internal {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        _createNFT(_owner, _seed, _deluxe);
    }

    function _createNFT(address _owner, uint256 _seed, bool _deluxe) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        if(_deluxe == true) { deluxeIDs[tokenId] = _deluxe; }
        super._mint(_owner, tokenId);
    }

    // WITHDRAWING ETH
    function withdrawETH() public {
        recipient.call{value: address(this).balance}(""); // this *should* be safe because the recipient is known
    }

    /*
    If for some reason, the split/recipient is not allowing one to withdraw, this emergency admin withdraw
    can be used to send any other address.
    If set up correctly, this will do nothing.
    */  
    function emergencyWithdraw(address _newRecipient) public {
        require(msg.sender == owner, "NOT_OWNER");
        (bool success, bytes memory returnData)  = recipient.call{value: address(this).balance}("");
        if(success == false) {
            _newRecipient.call{value: address(this).balance}("");
        } else { revert('emergency not needed'); } // this can't be used if normal withdraw works
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

/*
Partly inspired by Zond's Flowers by onchainCo: https://opensea.io/collection/flowersonchain
*/
import './svg.sol';
import './utils.sol';
import "./utils/Base64.sol";

contract CollectionDescriptor {

    function render(uint256 _tokenId, bool deluxe) internal pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(_tokenId));

        // different petal counts: 8, 12, 20, 24, 36
        uint petalCount = utils.getPetalCount(hash); 
        uint rotation = 360/petalCount;

        string memory style = '<style>'; // note: keeping this separate due to this having global styles in the past.
        string memory animationButtons = "";
        string memory animationSetters = "";

        if(deluxe == true) {
            animationButtons = '<circle class="startButton" cx="150" cy="150" r="50" fill-opacity="0" ><animate dur="0.01s" id="startAnimation" attributeName="r" values="50; 0" fill="freeze" begin="click" /><animate dur="0.01s" attributeName="r" values="0; 50" fill="freeze" begin="stopAnimation.end" /></circle><circle class="button" cx="150" cy="150" r="0" fill-opacity="0" ><animate dur="0.001s" id="stopAnimation" attributeName="r" values="50; 0" fill="freeze" begin="click" /><animate dur="0.001s" attributeName="r" values="0; 50" begin="startAnimation.end" fill="freeze"  /></circle>';
            animationSetters = '<set attributeName="class" to="rotate" begin="startAnimation.begin"/><set attributeName="class" to="notRotate" begin="stopAnimation.begin"/>';
            style = string.concat(style,
                '.startButton { cursor: pointer; } .rotate {transform-origin: 150px 150px;animation: rotate 100s linear infinite; }@keyframes rotate {from {transform: rotate(0deg);}to {transform: rotate(360deg);}}'
            );
        }

        style = string.concat(style,'</style>');

        return string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" version="2.0" style="background:#fff" viewBox="0 0 300 300" width="600" height="600" xmlns:xlink="http://www.w3.org/1999/xlink">',
                style,
                filtersPathsAndMasks(hash),
                reusables(hash, petalCount, rotation),
                '<g id="entire">',
                animationSetters,
                '<use href="#flower" clip-path="url(#halfClip)" transform="rotate(0, 150, 150)"/>',
                '<use href="#flower" clip-path="url(#halfClip)" transform="rotate(180, 150, 150)"/>',
                animationButtons,
                '</g>',
                '</svg>'
            );
    }

    function filtersPathsAndMasks(bytes memory hash) internal pure returns (string memory) {
        string memory patstrMaximal = outerPetalPattern(hash, true);
        string memory patstrMinimal = outerPetalPattern(hash, false);
        uint height = utils.getHeight(hash); //  180 - 52
        string memory adjustment = utils.uint2str(150+height);

        return string.concat('<filter id="blur">',
            patstrMaximal,
            '<feGaussianBlur stdDeviation="1"/>',
            '</filter>',
            '<filter id="sharp">',
            patstrMinimal,
            '</filter>',
            '<clipPath id="blurClip">',
            '<rect x="145" y="145" width="215" height="215"/>',
            '</clipPath>',
            '<clipPath id="patternClip">',
            '<path d="M 145 145 L ',adjustment,' 145 Q ',adjustment,' ',adjustment,' 145 ',adjustment,' Z"/>'
            '</clipPath>',
            '<clipPath id="halfClip">',
            '<rect width="260" height="610" x="-110" y="-110"/>',
            '</clipPath>'
        );
    }

    function outerPetalPattern(bytes memory hash, bool maximalist) internal pure returns (string memory) {
        // latter 0.0 isn't strictly necessary, but keeping it in for vestigial reasons
        string memory oppBF = generateBaseFrequency(hash, ['0.0', '0.00', '0.00'], ['0.0', '0.0', '0.00']);
        string memory oppSeed = utils.uint2str(utils.getSeed(hash)); // 0 - 16581375

        return string.concat(
                svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', oppBF),svg.prop('seed', oppSeed), svg.prop('result', 'turb'))),
                svg.el('feColorMatrix',string.concat(svg.prop('in', 'turb'), svg.prop('values', generateColorMatrix(hash, maximalist)), svg.prop('out', 'turb2')))
        );
    }

    /* 
    Generates the base frequency parameter for the perlin noise.
    */
    function generateBaseFrequency(bytes memory hash, string[3] memory decimalStrings, string[3] memory decimalStrings2) public pure returns (string memory) {
        string memory strNr = utils.uint2str(utils.getBaseFrequencyOne(hash)); // 1 - 997 (ish)
        uint256 dec = utils.getDecimalsOne(hash); // 0 - 2

        string memory strNr2 = utils.uint2str(utils.getBaseFrequencyTwo(hash)); // 1 - 997 (ish)
        uint256 dec2 = utils.getDecimalsTwo(hash); // 0 - 2

        string memory bf = string.concat(decimalStrings[dec], strNr,' ',decimalStrings2[dec2], strNr2);
        return bf;
    }

    /*
    An algorithm to generate the modification of the perlin noise to stronger colours
    */
    function generateColorMatrix(bytes memory hash, bool maximalist) public pure returns (string memory) {
        string memory strMatrix;

        for(uint i = 0; i<20; i+=1) {
            // re-uses entropy
            // note: using i+1 does create *some* default tendency, but shouldn't be significant.
            uint matrixOffset = utils.getMatrixOffset(hash, i); // 0 - 64
            uint negOrPos = utils.getNegOrPos(hash, i+1); // 0 - 255

            if(i == 18) { // Alpha modified by itself. Adds more of everything or less of everything.
                // note: code borrowed from room of infinite paintings
                // in general: higher -> more infill. lower -> less infilling and more transparency.
                // higher was chosen so one can see the blur + higher likelihood of pieces overlapping
                strMatrix = string.concat(strMatrix, '-50 '); 
            } else if(i == 19) { 
                // final channel is the shift of the alpha channel
                // making it mildly brighter ensure *some* color
                strMatrix = string.concat(strMatrix, '1 ');
            } else if(i==4 || i == 9 || i== 14) { 
                // shifts for RGB
                if(maximalist == true) {
                    // shifting makes the entire channel linearly stronger or weaker AFTER it's been modified from its underlying components.
                    // eg modify randomly and THEN add more (or less) of the channel to the pixel in general.
                    // if the shift is zero, it keeps each channel equal essentially. ensures more varied colours.
                    // thus, for background blur, it's better and more maximalist.
                    strMatrix = string.concat(strMatrix, '0 '); // no shifts
                } else {
                    // adding a mild shift causes the entire pixel to add more of that channel
                    // this comes at the expense of the other channels
                    // thus, adding shifts to each channel essentially takes away variedness, making it white.
                    // making it more minimal and sharp. 
                    // too strong a shift makes it too white and thus you can't see the blur.
                    strMatrix = string.concat(strMatrix, '1 '); // shifts 
                }
            } else if(negOrPos < 128) { 
                // random chance of adding or taking away colour (or alpha) from rgba
                strMatrix = string.concat(strMatrix, utils.uint2str(matrixOffset), ' ');
            } else {
                strMatrix = string.concat(strMatrix, '-', utils.uint2str(matrixOffset), ' ');
            }
        }
        return strMatrix;
    }

    function reusables(bytes memory hash, uint petalCount, uint rotation) internal pure returns (string memory) {
        uint midPointReduction = utils.getMidPointReduction(hash);
        uint endPointReduction = midPointReduction*2; // 0 - 36-ish

        string memory petals = generatePetals(hash, petalCount, rotation);

        string memory rs = string.concat('<defs>',
        '<rect id="tap" x="150" y="150" width="200" height="200" filter="url(#sharp)"/>',
        '<rect id="blurtap" x="150" y="150" width="200" height="200" filter="url(#blur)"/>',
        '<path id="ptl" d="M 150 150 Q ',utils.uint2str(150-midPointReduction),' ',utils.uint2str(150-endPointReduction),' 150 ',utils.uint2str(150-endPointReduction),' ',utils.uint2str(150+midPointReduction),' ',utils.uint2str(150-endPointReduction),' 150 150 Z" stroke="black"/>',
        '<g id="flower">', petals, '</g></defs>'
        );

        return rs;
    }

    function generatePetals(bytes memory hash, uint petalCount, uint rotation) internal pure returns (string memory) {
        string memory petals = "";
        string memory backPetals = "";
        string memory frontPetals = "";
        // NOTE: There is some redundancy here.
        for(uint i = 0; i<petalCount; i+=1) {
            if(i < (petalCount/4*3)+2) { // 3/4 of the wheel + 2
                backPetals = string.concat(backPetals, backPetal(rotation*(i)+1));
                frontPetals = string.concat(frontPetals, frontPetal(hash, rotation*(i+1)+90));
            }
        }

        // add final two front petals
        // note: since it's cut off at half-way point, this is simpler than using clips or masks to ensure that petals are behind each other
        frontPetals = string.concat(frontPetals, frontPetal(hash, rotation*(petalCount+1)+90), frontPetal(hash, rotation*(petalCount+2)+90));

        petals = string.concat(backPetals, frontPetals);
        return petals;
    }

    function backPetal(uint rotation) internal pure returns (string memory) {
        return string.concat(
            '<use xlink:href="#blurtap" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" clip-path="url(#blurClip)"/>',
            '<use xlink:href="#tap" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" clip-path="url(#patternClip)"/>'
            );
    }

    function frontPetal(bytes memory hash, uint rotation) internal pure returns (string memory) {
        uint256 c = utils.getFrontPetalColour(hash);
        return string.concat(
            '<use xlink:href="#ptl" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" fill="hsl(',utils.uint2str(c),',100%,50%)" stroke="black"/>'
        );
    }

    function generateURI(uint256 tokenId, bool deluxe) public pure returns (string memory) {
        string memory name = generateName(tokenId, deluxe); 
        string memory description = generateDescription();
        string memory image = generateBase64Image(tokenId, deluxe);
        string memory attributes = generateTraits(tokenId, deluxe);

        string memory animation = "";
        if(deluxe == true) {
            animation = string.concat('", "animation_url": "',
                'data:image/svg+xml;base64,', 
                image
            );
        }

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
                            image,
                            animation,
                            '", ',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId, bool deluxe) public pure returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId, deluxe));
        return Base64.encode(img);
    }

    function generateName(uint nr, bool deluxe) public pure returns (string memory) {
        string memory prefix = "Default";
        if(deluxe == true) {
            prefix = "Deluxe";
        }
        return string(abi.encodePacked(prefix, ' Daisychain #', utils.substring(utils.uint2str(nr),0,8)));
    }

    function generateDescription() public pure returns (string memory) {
        string memory description = "Daisychains. Life In Every Breath. Collectible Onchain SVG Flowers inspired by the journey of Hinata in the Logged Universe story: MS-OS. Deluxe Daisychains can rotate if you click on their centers.";
        return description;
    }
    
    function generateTraits(uint256 tokenId, bool deluxe) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        string memory animatedTrait;
        
        if(deluxe == true) {
            animatedTrait = createTrait("Animated", "True");
        } else {
            animatedTrait = createTrait("Animated", "False");
        }

        uint256 petalCount = utils.getPetalCount(hash);

        string memory petalCountTrait = createTrait("Petal Count", utils.uint2str(petalCount));

        return string(abi.encodePacked(
            '"attributes": [',
            animatedTrait,
            ",",
            petalCountTrait,
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

    function generateImage(uint256 tokenId, bool deluxe) public pure returns (string memory) {
        return render(tokenId, deluxe);
    } 
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
    ) internal view returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            // console.logBytes32(computedHash);
            // console.logBytes32(proofElement);
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                //computedHash = _efficientHash(computedHash, proofElement);
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                // computedHash = _efficientHash(proofElement, computedHash);
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    // entropy carving
    // extrapolated into utils file in order to re-use between drawing + trait generation
    function getPetalCount(bytes memory hash) internal pure returns (uint256) {
        uint8[5] memory petalCounters = [8, 12, 20, 24, 36];
        uint pI = utils.toUint8(hash,0)/52; //0 - 4.9
        uint petalCount = petalCounters[pI]; // 360 + 2
        return petalCount;
    }

    function getHeight(bytes memory hash) internal pure returns (uint256) { return 180-utils.toUint8(hash,1)/2;} // 180 - 52
    function getSeed(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash,2))*uint256(utils.toUint8(hash,3))*uint256(utils.toUint8(hash,4));} // 0 - 16581375

    function getBaseFrequencyOne(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(utils.toUint8(hash,5))*1000/256; }
    function getBaseFrequencyTwo(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(utils.toUint8(hash,6))*1000/256; }
    function getDecimalsOne(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash, 7))*3/256; }
    function getDecimalsTwo(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash, 8))*3/256; }
    function getMatrixOffset(bytes memory hash, uint offset) internal pure returns (uint256) { return uint256(utils.toUint8(hash, offset))/4; } // re-uses entropy 0 - 19
    function getNegOrPos(bytes memory hash, uint offset) internal pure returns (uint256) { return utils.toUint8(hash, offset); } // re-uses entropy 1 - 20
    function getMidPointReduction(bytes memory hash) internal pure returns (uint256) { return 5 + utils.toUint8(hash,9)/13;  } // 0 - 18-ish
    function getFrontPetalColour(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash,10))*360/256;  } // 0 - 360
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