// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity ^0.8.0;

import "./ToString.sol";
import "./Base64.sol";
import "./TerraformsDataInterfaces.sol";
import "./TerraformsDataStorage.sol";
import "./openzeppelin/contracts/access/Ownable.sol";

/// @author xaltgeist
/// @title Token data and tokenURI generation for the Terraforms contract
/// @dev Terraforms data is generated on-demand; Terraforms are not stored
contract TerraformsData is TerraformsDataStorage, Ownable {

    /// @dev Parameters used to generate tokenURI
    struct tokenURIContext {
        ITerraformsSVG.SVGParams p; // Parameters for SVG contract
        ITerraformsSVG.AnimParams a; // Parameters to generate CSS animation
        string name;
        string svgMain; // Main body of the tokenURI SVG
        string animations; // SVG animation keyframes
        string script; // SVG javascript
        string imageURI; // "image" attribute source 
        string animationURI; // "animation_url" source
        string activation; // Token activation
        string mode; // Terrain, Daydream, Terraform
    }

    /// @dev A token's status
    enum Status {
        Terrain, 
        Daydream, 
        Terraformed, 
        OriginDaydream, 
        OriginTerraformed
    }

    // Interfaces
    ITerraformsSVG terraformsSVG;
    ITerraformsZones terraformsZones;
    ITerraformsCharacters terraformsCharacters;
    IPerlinNoise perlinNoise;
    ITerraformsResource resource;
    uint immutable INIT_TIME;
    uint constant MAX_SUPPLY = 11_104;
    uint constant MAX_LEVEL_DIMS = 48;
    uint public constant TOKEN_DIMS = 32;
    int public constant STEP = 6619;
    string animationURL = 'https://tokens.mathcastles.xyz/terraforms/token-html/';
    string imageURL;
    string public resourceName;
    address public resourceAddress;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * CONSTRUCTOR, FALLBACKS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    constructor (
        address _terraformsSVGAddress, // Assembles SVG
        address _perlinNoiseAddress, // Generates terrain
        address _terraformsZonesAddress, // Manages zone info
        address _terraformsCharsAddress // Manages character info
    ) 
    Ownable()
    {
        terraformsSVG = ITerraformsSVG(_terraformsSVGAddress); 
        perlinNoise = IPerlinNoise(_perlinNoiseAddress); 
        terraformsZones = ITerraformsZones(_terraformsZonesAddress);
        terraformsCharacters = ITerraformsCharacters(_terraformsCharsAddress);
        INIT_TIME = block.timestamp; // Baseline for structure movement
        resourceName = "???"; // Initial resource name
    }

    // SVG returned by TokenURI prior to token reveal
    string public prerevealSVG = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg shape-rendering="crispEdges" viewBox="0 0 280 280" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><rect class="bg" fill="#161616" x="0" y="0" width="280" height="280"/><path class="y" stroke="#fff" d="m 132.5,126.5 h 2 m 2,0 h 1 m -8,1 h 1 m 3,0 h 1 m 3,0 h 1 m 7,0 h 1 m 3,0 h 2 m -25,1 h 2 m 1,0 h 1 m 3,0 h 1 m 14,0 h 2 m -23,1 h 1 m 2,0 h 1 m 3,0 h 1 m 1,0 h 4 m 1,0 h 4 m 2,0 h 2 m -21,1 h 1 m 3,0 h 2 m 17,0 h 1 m -26,1 h 1 m 4,0 h 1 m 14,0 h 1 m 3,0 h 2 m -22,1 h 1 m 1,0 h 5 m 5,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m -24,1 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m -19,1 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m 2,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m 2,0 h 2 m -24,1 h 1 m 2,0 h 5 m 4,0 h 4 m 3,0 h 1 m 1,0 h 2 m -23,1 h 1 m 18,0 h 1 m -23,1 h 1 m 1,0 h 1 m 3,0 h 1 m 3,0 h 1 m 5,0 h 1 m 4,0 h 1 m -19,1 h 4 m 2,0 h 2 m 5,0 h 1 m 3,0 h 1 m 2,0 h 1 m -23,1 h 3 m 3,0 h 3 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 2 m -23,1 h 2 m 1,0 h 1 m 2,0 h 2 m 2,0 h 1 m 1,0 h 1 m 3,0 h 3 m 2,0 h 1 m -17,1 h 8 m 1,0 h 2 m 1,0 h 1 m 1,0 h 1 m -9,1 h 1 m -10,1 h 2 m 1,0 h 2 m 8,0 h 5 m -16,1 h 1 m 1,0 h 2 m 6,0 h 4 m -7,1 h 2 m -7,1 h 1 m 2,0 h 2 m 5,0 h 1 m 1,0 h 2 m -16,1 h 4 m 1,0 h 2 m 1,0 h 3 m 2,0 h 1 m -7,1 h 2 m 1,0 h 2 m -6,1 h 1 m 1,0 h 1 m 2,0 h 1 m -6,1 h 1 m 2,0 h 3 m -7,1 h 1 m 3,0 h 1 m -6,1 h 1 m 3,0 h 2 m -6,1 h 1 m 1,0 h 1 m 1,0 h 1 m 0,-27 h 1 m 2,0 h 1 m -2,1 h 1 m -2,5 h 1 m -17,5 h 1 m 0,1 h 1 m 16,1 h 1 m -13,2 h 1 m 8,0 h 1 m -10,2 h 1 m 0,1 h 1 m 11,2 h 1 m 1,-20 h 1 m -11,1 h 1 m -2,2 h 1 m 4,0 h 1 m -15,3 h 1 m 10,1 h 1 m -1,12 h 1 m -1,3 h 1 m -2,5 h 1 m 1,0 h 1 m 1,-26 h 1 m -11,1 h 1 m 14,2 h 1 m -10,4 h 1 m -9,2 h 1 m 2,1 h 1 m 9,1 h 1 m -10,1 h 1 m 14,1 h 1 m -15,8 h 1 m 6,1 h 1 m -5,1 h 1 m 6,-18 h 1 m -9,19 h 1"/><path class="x" stroke="#fff" d="m 135.5,123.5 h 1 m 7,0 h 1 m 4,0 h 1 m -18,1 h 2 m 3,0 h 1 m 2,0 h 1 m 3,0 h 1 m -16,1 h 1 m 3,0 h 1 m 3,0 h 1 m 3,0 h 1 m 7,0 h 1 m -20,1 h 1 m 17,0 h 1 m -15,1 h 9 m 2,0 h 1 m 7,0 h 1 m -27,1 h 2 m 2,0 h 3 m 2,0 h 1 m 6,0 h 1 m 2,0 h 2 m 3,0 h 2 m -25,1 h 1 m 1,0 h 2 m 3,0 h 1 m 1,0 h 2 m 3,0 h 4 m 2,0 h 2 m -20,1 h 1 m 2,0 h 2 m 1,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -21,1 h 1 m 3,0 h 2 m 1,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -21,1 h 1 m 4,0 h 4 m 4,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -23,1 h 1 m 1,0 h 1 m 5,0 h 3 m 4,0 h 4 m 3,0 h 1 m -23,1 h 1 m 1,0 h 1 m 3,0 h 1 m -7,1 h 1 m 1,0 h 2 m 2,0 h 1 m 4,0 h 1 m 3,0 h 1 m 4,0 h 2 m 2,0 h 2 m -26,1 h 1 m 2,0 h 3 m 1,0 h 1 m 3,0 h 1 m 4,0 h 1 m 2,0 h 2 m 2,0 h 2 m -24,1 h 1 m 2,0 h 2 m 1,0 h 4 m 1,0 h 1 m 1,0 h 1 m 2,0 h 4 m -19,1 h 2 m 4,0 h 1 m 1,0 h 7 m 2,0 h 1 m -19,1 h 2 m 5,0 h 1 m 4,0 h 1 m 3,0 h 3 m -15,2 h 3 m 7,0 h 4 m -12,1 h 3 m 4,0 h 4 m -16,1 h 1 m 9,0 h 1 m -10,1 h 1 m 1,0 h 2 m 4,0 h 2 m 4,0 h 1 m 2,0 h 1 m -18,1 h 3 m 5,0 h 2 m 1,0 h 1 m 2,0 h 1 m 1,0 h 2 m -8,1 h 3 m -7,1 h 6 m -7,1 h 2 m 4,0 h 1 m -7,1 h 1 m 4,0 h 2 m -6,1 h 5 m -4,-27 h 1 m 3,1 h 1 m 7,0 h 1 m -6,1 h 1 m -1,2 h 1 m 7,0 h 1 m -19,1 h 1 m 2,0 h 1 m -2,1 h 1 m -5,6 h 1 m 16,1 h 1 m -1,1 h 2 m -15,2 h 1 m -4,3 h 1 m 6,-19 h 1 m 7,2 h 1 m -20,5 h 1 m 8,2 h 1 m -9,5 h 1 m 5,1 h 1 m -2,3 h 1 m 4,4 h 1 m 4,0 h 1 m -7,1 h 1 m 3,-19 h 1 m -10,2 h 1 m 10,1 h 1 m 3,4 h 1 m -8,2 h 1 m 5,0 h 1 m -16,1 h 1 m 9,0 h 1 m -5,2 h 1 m -10,4 h 1 m -3,-5 h 1"/><style>   @keyframes cf{0%{stroke: #303030;}10%{stroke: #0974f8;}20%{stroke: #fe81dd;}30%{stroke: #ff9000;}40%{stroke: #006e15;}50%{stroke: #fe81dd;}60%{stroke: #fbd81c;}70%{stroke: #608a1a;}80%{stroke: #202020;}90%{stroke: #e4e6f2;}}       .bg{animation:bg .05s .025s steps(1) infinite;} @keyframes bg{0%{fill: #161616;}50%{fill: #171717;}}   .x{animation: fr .3s steps(1) infinite,m2 .7s steps(2) infinite, cf 1s steps(1) infinite alternate;}   .y{animation: fr .3s .15s steps(1) infinite,m2 1s steps(3) infinite,cf 1s steps(1) infinite alternate;}   @keyframes m2{0%{transform: translate(0%, 0%)}50%{transform: translate(0%, -3%)}}   @keyframes fr {0%{opacity: 0;}50%{opacity: 1.0;}};} </style></svg>';

    fallback() external payable {}
    receive() external payable {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: TOKEN DATA
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice A placeholder tokenURI endpoint while tokens are not revealed
    /// @param tokenId The token ID
    /// @return A base64 encoded JSON string
    function prerevealURI(uint tokenId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,', 
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Terraform #',
                        ToString.toString(tokenId), 
                        '","description": "Terraforms by Mathcastles. Onchain land art from a dynamically generated, onchain 3D world."',
                        ',"image": "data:image/svg+xml;base64,',
                        Base64.encode(
                            abi.encodePacked(prerevealSVG)
                        ),
                        '"}'
                    )
                )
            )
        );
    }

    /// @notice Returns a token's tokenURI
    /// @param tokenId The token ID
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A base64 encoded JSON string
    function tokenURI(
        uint tokenId,
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        public 
        view 
        returns (string memory result) 
    {
        tokenURIContext memory ctx; // Track local variables

        ctx.p = svgParameters( // Generate parameters for creating SVG
            status,
            placement, 
            seed, 
            decay, 
            canvas
        );

        ctx.a = animationParameters(placement, seed); // Generate anim params

        // If there is no external URL for animation or image, we are returning
        // an SVG from the contract, so generate the SVG
        // SVG is returned in sections, so we can assemble static and animated
        // images
        if (bytes(animationURL).length == 0 || bytes(imageURL).length == 0){
            (
                ctx.svgMain, 
                ctx.animations,
                ctx.script
            ) = terraformsSVG.makeSVG(ctx.p, ctx.a);
        }
        
        // If there is no external animation URL, return an animated SVG
        if (bytes(animationURL).length == 0){
            ctx.animationURI = string(
                abi.encodePacked(
                    ', "animation_url":"data:text/html;charset=utf-8,<html><head><meta charset=\'UTF-8\'><style>html,body,svg{margin:0;padding:0; height:100%;text-align:center;}</style></head><body>',
                    ctx.svgMain, 
                    ctx.animations,
                    '</style>',
                    ctx.script,
                    '</svg></body></html>"'
                )
            );
        } else { // Otherwise, include the external URL with the tokenId
            ctx.animationURI = string(
                abi.encodePacked(
                    ', "animation_url":"',
                    animationURL, 
                    ToString.toString(tokenId),
                    '"'
                )
            );
        }

        // If there is no external image URL, return an SVG w/o animation or JS    
       if (bytes(imageURL).length == 0){
            ctx.imageURI = string(
                abi.encodePacked(
                    '}], "image": "data:image/svg+xml;base64,',
                    Base64.encode(
                        abi.encodePacked(ctx.svgMain,'</style></svg>')
                    ),
                    '"'
                )
            );
        } else { // Otherwise, include the external URL with the tokenId
            ctx.imageURI = string(
                abi.encodePacked(
                    '}], "image":"',
                    imageURL, 
                    ToString.toString(tokenId),
                    '"'
                )
            );
        }

        // Determine the token's activation
        if (ctx.a.activation == ITerraformsSVG.Activation.Plague) {
            ctx.activation = "Plague";
        } else if (ctx.a.duration == durations[0]){
            ctx.activation = "Hyper";
        } else if (ctx.a.duration == durations[1]) {
            ctx.activation = "Pulse";
        } else {
            ctx.activation = "Flow";
        }

        // Determine the token's status
        if (ctx.p.status == 0) {
            ctx.mode = "Terrain";
        } else if (ctx.p.status == 1) {
            ctx.mode = "Daydream";
        } else if (ctx.p.status == 2) {
            ctx.mode = "Terraform";
        } else if (ctx.p.status == 3) {
            ctx.mode = "Origin Daydream";
        } else {
            ctx.mode = "Origin Terraform";
        }

        ctx.name = string(
            abi.encodePacked(
                'Level ',
                ToString.toString(ctx.p.level + 1),
                ' at {',
                ToString.toString(
                    ctx.p.tile % levelDimensions[ctx.p.level]
                ),
                ', ',
                ToString.toString(
                    ctx.p.tile / levelDimensions[ctx.p.level]
                ),
                '}'
            )
        );

        // Generate tokenURI string
        result = string(
            abi.encodePacked(
                'data:application/json;base64,', 
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        ctx.name,
                        '","description": "Terraforms by Mathcastles. Onchain land art from a dynamically generated, onchain 3D world."',
                        ctx.animationURI,
                        ', "aspect_ratio":0.6929, "attributes": [{"trait_type":"Level","value":',
                        ToString.toString(ctx.p.level + 1),
                        '},{"trait_type":"X Coordinate","value":"',
                        ToString.toString(
                            ctx.p.tile % levelDimensions[ctx.p.level]
                        ),
                        '"},{"trait_type":"Y Coordinate","value":"',
                        ToString.toString(
                            ctx.p.tile / levelDimensions[ctx.p.level]
                        ),
                        '"},{"trait_type":"Mode","value":"',
                        ctx.mode,
                        '"},{"trait_type":"Zone","value":"',
                        ctx.p.zoneName,
                        '"},{"trait_type":"Biome","value":"',
                        ToString.toString(ctx.p.charsIndex),
                        '"},{"trait_type":"Chroma","value":"',
                        ctx.activation,
                         '"},{"trait_type":"',
                        resourceName,
                         '","value":',
                        ToString.toString(ctx.p.resourceLvl),         
                        ctx.imageURI,
                        '}'
                    )
                )
            )
        );
    }

    /// @notice Returns an SVG of a token
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return A plaintext SVG string
    function tokenSVG(
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        public 
        view 
        returns (string memory) 
    {
        // Generate parameters for SVG
        ITerraformsSVG.SVGParams memory p = svgParameters(
            status,
            placement, 
            seed, 
            decay, 
            canvas
        );

        // Generate parameters for animation
        ITerraformsSVG.AnimParams memory a = animationParameters(
            placement, 
            seed
        );

        // SVG is in sections, so we can assemble static and animated images
        (
            string memory svgMain, 
            string memory animations,
            string memory script
        ) = terraformsSVG.makeSVG(p, a);

        return string(
            abi.encodePacked
            (svgMain, 
            animations, 
            '</style>',
            script,
            '</svg>')); 
    }

    /// @notice Returns HTML with the token's SVG as plaintext
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return A plaintext HTML string
    function tokenHTML(
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        public 
        view 
        returns (string memory) 
    {
        ITerraformsSVG.SVGParams memory p = svgParameters(
            status,
            placement, 
            seed, 
            decay, 
            canvas
        );

        ITerraformsSVG.AnimParams memory a = animationParameters(
            placement, 
            seed
        );

        (
            string memory svgMain, 
            string memory animations,
            string memory script
        ) = terraformsSVG.makeSVG(p, a);

        // Wrap the SVG in HTML tags
        return string(
            abi.encodePacked(
                "<html><head><meta charset='UTF-8'><style>html,body,svg{margin:0;padding:0; height:100%;text-align:center;}</style></head><body>",
                svgMain,
                animations,
                '</style>',
                script,
                "</svg></body></html>"
            )
        );
    }

    /// @notice Returns the characters of a token
    /// @param status The token's status
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Seed used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A 2D array of characters (strings)
    function tokenCharacters(
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        public 
        view 
        returns (string[32][32] memory result) 
    {
        // Get the token's character set
        (string[9] memory chars, , , ) = characterSet(placement, seed);

        // Get the token's heightmap (values correspond to character indices)
        uint[32][32] memory indices = tokenHeightmapIndices(
            status,
            placement, 
            seed, 
            decay, 
            canvas
        );

        // Translate the indices to characters. If the index is 9, it represents
        // the background, so we put a space instead
        for (uint y; y < TOKEN_DIMS; y++) {
    	    for (uint x; x < TOKEN_DIMS; x++) {
                result[y][x] = indices[y][x] < 9 ? chars[indices[y][x]] : " ";
    	    }
    	}

    	return result;
    }

    /// @notice Returns the numbers used to create a token's topography
    /// @dev Values are positions in 3D space. Not applicable to dreaming tokens
    /// @param placement Placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @return result A 2D array of ints
    function tokenTerrain(uint placement, uint seed, uint decay) 
        public 
        view 
        returns (int[32][32] memory result) 
    {
        // The step is the increment in the noise space between each element
        // of the token
        int step = STEP;

        // If the structure has decayed for more than 100 years, the step sizes
        // become larger, causing the token surface to collapse inward
        if (decay > 100) { 
            step += int(decay - 99) * 100;
        }
        
        // Determine the level and tile on which the token is located
        (uint level, uint tile) = levelAndTile(placement, seed);
        
        // Obtain the XYZ origin for the token
        int initX = xOrigin(level, tile, seed);
        int yPos = yOrigin(level, tile, seed);
        int zPos = zOrigin(level, tile, seed, decay, block.timestamp);
        int xPos;

        // Populate 2D array
    	for (uint y; y < TOKEN_DIMS; y++) {
    	    xPos = initX; // Reset X for row alignment on each iteration
    	    for (uint x; x < TOKEN_DIMS; x++) {
    	    	result[y][x] = perlinNoise.noise3d(xPos, yPos, zPos);
    	    	xPos += step;
    	    }
            yPos += step;
    	}
    	return result;
    }

    /// @notice Returns a 2D array of indices into a char array
    /// @param status The token's status
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return result A 2D array of uints to index into a char array
    function tokenHeightmapIndices(
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        public 
        view 
        returns (uint[32][32] memory result) 
    {
        // If the token is in terrain mode, generate terrain
        if (Status(status) == Status.Terrain){
            int[32][32] memory values = tokenTerrain(placement, seed, decay);

            // Convert terrain values to heightmap indices
            for (uint y; y < TOKEN_DIMS; y++) {
                for (uint x; x < TOKEN_DIMS; x++) {
                    result[y][x] = heightmapIndexFromTerrainValue(values[y][x]);
                }
            }
        } else if (canvas.length == 16){ // If token is terraformed, draw it
            uint digits;
            uint counter;
             // Iterate through canvas data
            for (uint rowPair; rowPair < 16; rowPair++){
                // Canvas data is from left to right, so we need to reverse
                // the integers so we can isolate (modulo) the leftmost digits
                digits = reverseUint(canvas[rowPair]);
                for (uint digit; digit < 64; digit++){ // Read 64 digits
                    result[counter / 32][counter % 32] = digits % 10;
                    digits = digits / 10; // Shift down one digit
                    counter += 1;
                }
            }
        }
        return result;
    }

    /// @notice Returns the XYZ origins of a level in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return Three ints representing the level's XYZ origins in 3D space
    function tileOrigin(
        uint level, 
        uint tile, 
        uint seed, 
        uint decay, 
        uint timestamp
    )
        public
        view
        returns (int, int, int)
    {
        return (
            xOrigin(level, tile, seed),
            yOrigin(level, tile, seed),
            zOrigin(level, tile, seed, decay, timestamp)
        );
    }

    /// @notice Returns the x origin of a token in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return A uint representing the tile's x origin in 3D space
    function xOrigin(uint level, uint tile, uint seed) 
        public 
        view 
        returns (int)
    {
        // Determine the dimensions (edge length) of the level
        uint dimensions = levelDimensions[level];

        // A token's x origin is measured in token lengths (STEP * TOKEN_DIMS)
        // multiplied by a pseudorandom offset (seed), and then placed on the
        // appropriate x coordinate on a level (tile % dimensions).
        // Tiles are centered by adding (MAX_LEVEL_DIMS - dimensions) / 2
        return STEP * int(TOKEN_DIMS) * int(
            seed + // This is a pseudorandom value to offset the structure
            (
                (MAX_LEVEL_DIMS - dimensions) / 2 + // This centers the levels
                (tile % dimensions) // This gets the x coordinate on the level
            )
        );
    }
    
    /// @notice Returns the y origin of a token in 3D space 
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return An int representing the tile's y origin in 3D space
    function yOrigin(uint level, uint tile, uint seed) 
        public 
        view 
        returns (int)
    {
        // A token's y origin is measured in token lengths (STEP * TOKEN_DIMS)
        // multiplied by a pseudorandom offset (seed), and then placed on the
        // appropriate y coordinate on a level (tile / dimensions).
        // Tiles are centered by adding (MAX_LEVEL_DIMS - dimensions) / 2
        uint dimensions = levelDimensions[level];
        return STEP * int(TOKEN_DIMS) * int(
            seed +
            (
                (MAX_LEVEL_DIMS - dimensions) / 2 +
                (tile / dimensions)
            )
        );
    }

    /// @notice Returns the z origin of a token in 3D space
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return An int representing the tile's z origin in 3D space
    function zOrigin(
        uint level, 
        uint tile, 
        uint seed, 
        uint decay, 
        uint timestamp
    ) 
        public 
        view 
        returns (int)
    {
        int zDecay;

        // Check if structure is decaying
        if (decay > 0) {
            // If decay is less than 100 years, structure is collapsing
            if (decay <= 100){ 
                zDecay = (STEP / 100) * int(decay);
            } else {
                // Otherwise it has collapsed, and only the oscillation remains
                return zOscillation(level, decay, timestamp);
            }
        }

        return (
            int(
                (   // Provide a gap of 7 TOKEN_DIMS between layers
                    (level + 1) * 7 + seed // Add seed for pseudorandom offset
                ) * TOKEN_DIMS
            // Create level topography: 3/4 * TOKEN_DIMS * elevation
            ) + (24 * tokenElevation(level, tile, seed))
        ) * 
        (STEP - zDecay) + // Reduce stepsize by amount of decay (collapse)
        zOscillation(level, decay, timestamp); // Add structure oscillation
    }

    /// @notice Changes a token's elevation on a level according to its zone
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @return A signed integer in range +-4
    function tokenElevation(uint level, uint tile, uint seed) 
        public 
        view 
        returns (int) 
    {   
        // Elevation is determined by the token's position on the level
        // Elevation ranges from 4 (for heightmap index 0) to -4 (index 8)
        return 4 - int(
            heightmapIndexFromTerrainValue(
                perlinPlacement(level, tile, seed, 1)
            )
        );
    }

    /// @notice Returns a token's zone, including its name and color scheme
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return An array of hexadecimal strings and a string
    function tokenZone(uint placement, uint seed) 
        public
        view
        returns (string[10] memory, string memory)
    {
        // Get level and tile from placement and seed
        (uint level, uint tile) =  levelAndTile(placement, seed);

        // Get perlin noise value for token's location on level
        int perlin = perlinPlacement(level, tile, seed, 1);

        // Determine zone from token's position
        (
            string[10] memory colors, 
            string memory name
        ) = terraformsZones.tokenZone(
            zoneStartingIndex[level] + 
            heightmapIndexFromTerrainValue(perlin) % zonesOnLevel[level]
        );

        return (colors, name);
    }

    /// @notice Returns a token's character set
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return charset An array of strings
    /// @return font The index of the token's font
    /// @return fontsize The token's font size
    /// @return index The index of the character set in the storage array
    function characterSet(uint placement, uint seed) 
        public 
        view 
        returns (
            string[9] memory charset,
            uint font, 
            uint fontsize,
            uint index
        )
    {
        // Characters are determined by level, so obtain it
        (uint level, ) = levelAndTile(placement, seed);

        // Pseudorandomly select placement into level's character distribution
        uint rand = uint(
            keccak256(abi.encodePacked(placement, seed, "chars"))
        ) % 100;

        // Character distributions are weighted per level. 
        // Iterate through  until the sum exceeds our random placement
        for (uint i; i < 9; i++){
            index += charsetWeights[level][i];
            if (rand < index) {
                index = charsetIndices[i] + rand % charsetLengths[i];
                (charset, font) = terraformsCharacters.characterSet(index);
                fontsize = charsetFontsizes[index]; // Fontsize for these chars
                return (charset, font, fontsize, index);
            }
        }
    }

    /// @notice Determines a token's level and its position on the level
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return level The token's level number
    /// @return tile The token's tile number
    function levelAndTile(uint placement, uint seed) 
        public 
        view 
        returns (uint level, uint tile) 
    {
        // Rotate a token's placement by pseudorandom seed value
        uint rotated = rotatePlacement(placement, seed);
        uint cur;
        uint last;

        // Determine level and tile from rotated placement by summing the tiles
        // on each level until we find the level it's on
        for (uint levelIndex; levelIndex < 20; levelIndex++){
            cur += levelDimensions[levelIndex] ** 2;
            if (rotated < cur){ // Found the level
                // The tile is the rotated placement minus the placement of the
                // first tile on the level
                (level, tile) = (levelIndex, rotated - last);
                return (level, tile);
            }
            last = cur; // track the last sum so we can find tile placement
        }
    }

    /// @notice Returns the position on the z axis of a 2D level
    /// @dev Z offset cycles over a two year period
    /// @dev Intensity of the offset increases farther from center levels
    /// @param level The level of the superstructure
    /// @param decay Amount of decay affecting the superstructure
    /// @param timestamp The time queried (structure floats and decays in time)
    /// @return result An int representing the altitude of the level
    function zOscillation(uint level, uint decay, uint timestamp) 
        public 
        view 
        returns (int result) 
    {
        int increment = 6; // base Z oscillation
        int levelIntensifier; // levels at ends move a greater distance
        int daysInCycle = 3650; // cycles every 10 years
        int locationInCycle = int( // current day mod length of cycle
            ((timestamp - INIT_TIME) / (1 days)) % uint(daysInCycle)
        );

        // if we're in the first half, the structure is floating up
        if (locationInCycle < daysInCycle/2){
            if (level > 9) { // top half moves faster when going up
                // intensifier will be 5% per level away from center
                levelIntensifier = int(level - 9); 
            }
        } else { // if we are in the last half we are floating down
            increment *= -1; // change direction to downward
            locationInCycle -= daysInCycle/2; // subtract 1/2 for simpler math
            if (level < 9){ // bottom half moves faster when going down
                levelIntensifier = int(9 - level); 
            }
        } 

        // Structure pivots at 1/4 and 3/4 through the cycle
        result = daysInCycle/4 - locationInCycle;
        if (result < 0){ // take absolute val of distance from pivot
            result *= -1;
        }

        // Z position is distance from pivot point multiplied by increment
        result = (daysInCycle/4 - result) * increment;

        // Add an intensifier based on distance from center
        // Multiply and then divide by 20 since we can't do floating pt math
        result += (result * levelIntensifier)/20;

        // Dampen the result according to the level of decay
        result = result / int(decay + 1);
        
        return result;
    }

    /// @notice Determines the amount of resource present on a token
    /// @dev Queries external contract for amount, if address is present
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return An unsigned integer
    function resourceLevel(uint placement, uint seed) 
        public 
        view
        returns (uint) 
    {
        // Resource level is determined by the token's location
        (uint level, uint tile) = levelAndTile(placement, seed);

        // Check if we are using an external source for resource values
        if (resourceAddress == address(0)) { // If not, use perlin noise
            int p = perlinPlacement(level, tile, seed, 3);
            p = p < 0 ? -p : p; // Take absolute value
            p = 54_000 - p; // Subtract from 54_000 (a high perlin value)
            p = p < 0 ? -p : p; // Take absolute value again
            return uint(p);
        } else { // Otherwise, call that contract
            return ITerraformsResource(resourceAddress).amount(
                rotatePlacement(placement, seed)
            );
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: ADMINISTRATIVE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Sets external URL for token animations
    /// @dev If set to the empty string, onchain animation will be used
    /// @param url is the base URL for token animations
    function setAnimationURL(string memory url) public onlyOwner {
        animationURL = url;
    }

    /// @notice Sets external URL for token animations
    /// @dev If set to the empty string, onchain image will be used
    /// @param url is the base URL for token images
    function setImageURL(string memory url) public onlyOwner {
        imageURL = url;
    }

    /// @notice Sets resource name
    /// @param name The resource name
    function setResourceName(string memory name) public onlyOwner {
        resourceName = name;
    }

    /// @notice Sets resource contract address
    /// @param contractAddress The resource contract address
    function setResourceAddress(address contractAddress) public onlyOwner {
        resourceAddress = contractAddress;
    }

    /// @notice Transfers the contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INTERNAL: TOKEN DATA HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns a perlin noise value for a token
    /// @param level The level of the superstructure
    /// @param tile The token's tile placement
    /// @param seed Value used to rotate initial token placement
    /// @param scale Multiplier for step size
    /// @return An int representing a height value
    function perlinPlacement(uint level, uint tile, uint seed, int scale) 
        internal 
        view 
        returns (int)
    {
        // Stretch/shrink the step size to the size of the token's level
        int stepsize = (STEP * int(TOKEN_DIMS)) / int(levelDimensions[level]);

        // The reference XY is set as the center of the current level
        // i.e. STEP*TOKEN_DIMS (a token width) * MAX_LEVEL_DIMS/2 (level midpt)
        // + STEP*14 (the midpoint of the middle token) + 6619/2
        // + 6619/2 (halfway through the middle step)
        int refXY = STEP * 
            (14 + int(seed + MAX_LEVEL_DIMS/2) * int(TOKEN_DIMS)) +
            3309;
        
        int result = perlinNoise.noise3d(
            refXY + int(tile % levelDimensions[level]) * stepsize * scale, // x
            refXY + int(tile / levelDimensions[level]) * stepsize * scale, // y
            int((level+1) * TOKEN_DIMS * 2 + (seed*TOKEN_DIMS)) * STEP * scale // z
        );

        return result;
    }

    /// @notice Converts a numeric value into an index into a char array 
    /// @dev Converts terrain values into characters
    /// @param terrainValue An int from perlin noise
    /// @return An integer to index into a character array
    function heightmapIndexFromTerrainValue(int256 terrainValue) 
        internal 
        view 
        returns (uint) 
    {
        // Iterate through the topography array until we find an elem less than
        // value
        for (uint i; i < 8; i++) {
            if (terrainValue > topography[i]) {
                return i;
            }
        }
        return 8; // if we fall through, return 8 (the lowest height value)
    }

    /// @notice Determines the direction of a tokens' resource animation
    /// @dev Direction oscillates from 0-5 over a 10 day period
    /// @return result an integer from 0 to 5 inclusive
    function resourceDirection() internal view returns (int result) {
        uint base = (block.timestamp % (10 days)) / (1 days);
        int oscillator = 5 - int(base); // Pivot around 5 day point
        result = oscillator < 0 ? -oscillator : oscillator; // absolute value
    }
    
    /// @notice Returns a 2D array of characters
    /// @param indices A 2D array of indices into a character array
    /// @param chars A character array
    /// @return result A 2D array of characters (strings)
    function charsFromHeighmapIndices(
        uint[32][32] memory indices, 
        string[9] memory chars
    ) 
        internal 
        pure 
        returns (string[32][32] memory result) 
    {
        // Translate heightmap indices to characters. Each heightmap index
        // corresponds to an index into a character array. If the index is 9,
        // it indicates the background, so return a space.
    	for (uint y; y < TOKEN_DIMS; y++) {
    	    for (uint x; x < TOKEN_DIMS; x++) {
                result[y][x] = indices[y][x] < 9 ? chars[indices[y][x]] : " ";
    	    }
    	}
    	return result;
    }

    /// @notice Determines the animation style of a token  
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return An Animation enum representing the type of animation
    function getActivation(uint placement, uint seed) 
        internal 
        pure 
        returns (ITerraformsSVG.Activation) 
    {
        // Pseudorandom selection, "activation" is a nonce
        uint activation = uint(
            keccak256(abi.encodePacked(placement, seed, "activation"))
        ) % 10_000;

        // 0.1% are Plague, the rest are Cascade
        if (activation >= 9_990){
            return  ITerraformsSVG.Activation.Plague;
        } else {
            return  ITerraformsSVG.Activation.Cascade;
        }
    }

    /// @notice Reverses an unsigned integer of up to 64 digits
    /// @dev Digits past the 64th will be ignored
    /// @param i The int to be reversed
    /// @return result The reversed int
    function reverseUint(uint i) internal pure returns (uint result) {
        for (uint digit; digit < 64; digit++){
            result = result * 10 + i % 10;
            i = i / 10;
        }

        return result;        
    }

    /// @notice Determines the animation style of a token  
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return A uint representing the final rotated placement
    function rotatePlacement(uint placement, uint seed)
        internal 
        pure 
        returns (uint)
    {
        return (placement + seed) % MAX_SUPPLY;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INTERNAL: HELPERS FOR SVG ASSEMBLY
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns the token's parameters to create the tokenURI and SVG
    /// @param status The token's status
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @param decay Amount of decay affecting the superstructure
    /// @param canvas The canvas data of a (dreaming) token
    /// @return p A SVGParams struct
    function svgParameters(
        uint status,
        uint placement, 
        uint seed, 
        uint decay, 
        uint[] memory canvas
    ) 
        internal 
        view 
        returns (ITerraformsSVG.SVGParams memory p) 
    {
        p.status = status;
        (p.level, p.tile) = levelAndTile(placement, seed);
        p.resourceLvl = resourceLevel(placement, seed);
        p.resourceDirection = uint(resourceDirection()); 
        (p.zoneColors, p.zoneName) = tokenZone(placement, seed);
        (p.chars, p.font, p.fontSize, p.charsIndex) = characterSet(
            placement, 
            seed
        );
        p.heightmapIndices = tokenHeightmapIndices(
            status, 
            placement, 
            seed, 
            decay, 
            canvas
        );
        
        return p;
    }

    /// @notice Determines CSS styles based on a token's animation type
    /// @param placement The placement of token on level/tile before rotation
    /// @param seed Value used to rotate initial token placement
    /// @return a An AnimParams struct
    function animationParameters(uint placement, uint seed) 
        internal 
        view 
        returns (ITerraformsSVG.AnimParams memory a) 
    {
        // Use pseudorandom value for determining animation
        uint sorter = uint(keccak256(abi.encodePacked(placement, seed)));
        a.activation = getActivation(placement, seed);

        // Baseline animation keyframes ('ms' is for string concatenation later)
        a.easing = 'ms steps(1)';

        if (a.activation == ITerraformsSVG.Activation.Plague) {
            a.classesAnimated = 876543210; // All classes are animated
            a.duration = 100 + (sorter % 400); // Speed from 100 to 500 ms
            a.durationInc = a.duration; // Duration increases for each class
            if (sorter % 2 == 0){ // Half of the animations are delayed by 2-4s
                a.delay = 2000 + (sorter % 2000);
                a.delayInc = a.delay;
                a.bgDelay = a.delay * 11;
            }
            a.bgDuration = 50; // Backgrounds are animated at high speed
            a.altColors = altColors[(sorter / 10) % 7]; // Alternate colors
        } else { // If token activation is not plague, determine animation amt
            if ((sorter / 1000) % 100 < 50){
                a.classesAnimated = animatedClasses[2];
            } else if ((sorter / 1000) % 100 < 80){
                a.classesAnimated = animatedClasses[1];
            } else {
                a.classesAnimated = animatedClasses[0];
            }
            
            // Determine animation speed
            if (sorter % 100 < 60){
                a.duration = durations[2];
            } else if (sorter % 100 < 90) {
                a.duration = durations[1];
            } else {
                a.duration = durations[0];
            }
            
            // Determine animation rhythm
            if ((sorter / 10_000) % 100 < 10){
                a.delayInc = a.duration / 10;
            } else {
                if (a.classesAnimated > 100_000){
                    a.delayInc = a.duration / 7;
                } else if (a.classesAnimated > 10_000){
                    a.delayInc = a.duration / 5;
                } else {
                    a.delayInc = a.duration / 4;
                }
            }
            
            // Use linear keyframes for all slow animations and for half of
            // medium animations
            if (
                a.duration == durations[2] ||
                (a.duration == durations[1] && (sorter / 100) % 100 >= 50)
            ) {
                a.easing = 'ms linear alternate both';
            }

            // Add a duration increment to 25% of tokens that are cascade
            // and not fast animations
            if(
                a.activation == ITerraformsSVG.Activation.Cascade &&
                sorter % 4 == 0 &&
                a.duration != durations[0]
            ) {
                a.durationInc = a.duration / 5;
            }
        }

        return a; 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraformsSVG {
    struct SVGParams {
        uint[32][32] heightmapIndices;
        uint level;
        uint tile;
        uint resourceLvl;
        uint resourceDirection;
        uint status;
        uint font;
        uint fontSize;
        uint charsIndex;
        string zoneName;
        string[9] chars;
        string[10] zoneColors;
    }

    struct AnimParams {
        Activation activation; // Token's animation type
        uint classesAnimated; // Classes animated
        uint duration; // Base animation duration for first class
        uint durationInc; // Duration increment for each class
        uint delay; // Base delay for first class
        uint delayInc; // Delay increment for each class
        uint bgDuration; // Animation duration for background
        uint bgDelay; // Delay for background
        string easing; // Animation mode, e.g. steps(), linear, ease-in-out
        string[2] altColors;
    }

    enum Activation {Cascade, Plague}
    
    function makeSVG(SVGParams memory, AnimParams memory) 
        external 
        view 
        returns (string memory, string memory, string memory);
}

interface ITerraformsZones {
    function tokenZone(uint index) 
        external 
        view 
        returns (string[10] memory, string memory);
}

interface ITerraformsCharacters {
    function characterSet(uint index) 
        external 
        view 
        returns (string[9] memory, uint);
}

interface IPerlinNoise {
    function noise3d(int256, int256, int256) external view returns (int256);
}

interface ITerraformsResource {
    function amount(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TerraformsDataStorage {   
    uint[9] charsetIndices = [0, 21, 43, 50, 59, 66, 73, 77, 83];
    uint[9] charsetLengths = [21, 22, 7, 9, 7, 7, 4, 6, 9];

    uint[3] durations = [300, 800, 8_000];

    uint[3] animatedClasses = [7651,65432,7654321];

    string[2][7] altColors = [
        ["#ffffff","#202020"],
        ["#b169ff","#ff2436"], 
        ["#eb048d","#05a98d"],
        ["#0000ff","#ffffff"], 
        ["#ff0000","#ffffff"], 
        ["#eb8034","#0000ff"],
        ["#ffb8ff ","#202020"]
    ];

    uint[20] public levelDimensions = [
        4, 
        8, 
        8, 
        16, 
        16, 
        24, 
        24, 
        24, 
        16, 
        32, 
        32, 
        16, 
        48, 
        48, 
        24, 
        24, 
        16, 
        8, 
        8, 
        4
    ]; 
    
    int[8] public topography = [
        int(18_000), 
        int(12_000), 
        int(4_000), 
        -4_000, 
        -12_000, 
        -20_000, 
        -22_000, 
        -26_000
    ];

    uint[20] zoneStartingIndex = [
        74, 
        74, 
        74, 
        74, 
        71, 
        65, 
        60, 
        54, 
        51, 
        43, 
        36, 
        34, 
        25, 
        17, 
        8, 
        1, 
        0, 
        0, 
        0, 
        0
    ];

    uint[20] zonesOnLevel = [
        1, 
        1, 
        1, 
        1, 
        3, 
        6, 
        5, 
        6, 
        3, 
        8, 
        7, 
        2, 
        9, 
        8, 
        9, 
        7, 
        1, 
        1, 
        1, 
        1
    ];

    uint[9][20] charsetWeights = [
        [0, 50, 0, 0, 0, 0, 0, 0, 50], 
        [22, 11, 11, 11, 11, 11, 1, 11, 11], 
        [22, 11, 11, 11, 11, 11, 1, 11, 11], 
        [5, 0, 5, 90, 0, 0, 0, 0, 0], 
        [10, 3, 1, 5, 1, 2, 1, 0, 77], 
        [30, 55, 5, 5, 2, 2, 1, 0, 0], 
        [20, 18, 30, 20, 5, 5, 1, 1, 0], 
        [25, 32, 5, 5, 30, 2, 1, 0, 0], 
        [10, 3, 1, 5, 1, 2, 1, 0, 77], 
        [20, 20, 14, 14, 10, 10, 1, 1, 10], 
        [20, 20, 14, 14, 10, 10, 1, 1, 10], 
        [30, 55, 5, 5, 2, 2, 1, 0, 0], 
        [10, 20, 18, 25, 15, 10, 1, 1, 0], 
        [10, 30, 25, 18, 5, 10, 1, 1, 0], 
        [10, 30, 25, 18, 5, 10, 1, 1, 0], 
        [10, 20, 18, 25, 15, 10, 1, 1, 0], 
        [22, 11, 11, 11, 11, 11, 1, 11, 11], 
        [5, 5, 10, 5, 5, 14, 1, 5, 50], 
        [50, 25, 0, 0, 0, 0, 0, 0, 25], 
        [0, 100, 0, 0, 0, 0, 0, 0, 0]
    ];       

    uint[92] charsetFontsizes = [
        27,
        18,
        18,
        18,
        26,
        23,
        23,
        18,
        22,
        18,
        18,
        18,
        22,
        18,
        17,
        18,
        18,
        26,
        14,
        18,
        20,
        20,
        22,
        18,
        13,
        20,
        22,
        22,
        22,
        22,
        20,
        22,
        15,
        15,
        18,
        24,
        23,
        14,
        18,
        18,
        16,
        20,
        25,
        14,
        15,
        16,
        12,
        12,
        12,
        18,
        15,
        16,
        16,
        16,
        11,
        12,
        15,
        12,
        14,
        14,
        16,
        16,
        13,
        13,
        14,
        12,
        13,
        11,
        12,
        12,
        10,
        9,
        9,
        14,
        11,
        12,
        14,
        16,
        12,
        12,
        12,
        14,
        14,
        12,
        14,
        15,
        17,
        22,
        17,
        14,
        14,
        14
    ];
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToString {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}