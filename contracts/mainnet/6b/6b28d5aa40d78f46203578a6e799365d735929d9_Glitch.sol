// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Metadata} from "src/interfaces/IERC721.sol";
import {IRenderer} from "src/interfaces/IRenderer.sol";

contract Glitch is IRenderer {
    string internal constant firstHtmlPart =
        '<html lang="en"> <head> <meta charset="utf-8"/> <meta name="viewport" content="width=device-width, initial-scale=1"/> <title>FLTRS - Glitch</title> <meta name="description" content="Glitch"/> <meta name="author" content="cmichel"/> <style>html{box-sizing: border-box; height: 100vh;}*, *:before, *:after{box-sizing: inherit; user-select: none;}body{width: 100vw; height: 100vh; margin: 0;}canvas{width: 100vw; height: 100vh; display: block; max-width: 100vw; border: none;}</style> </head> <body> <canvas id="canvas"></canvas> <script type="text/javascript">var vertexShaderSource=`#version 300 es\n\n// an attribute is an input (in) to a vertex shader.\n// It will receive data from a buffer\nin vec2 a_position;\nin vec2 a_texCoord;\n\n// Used to pass in the resolution of the canvas\nuniform vec2 u_resolution;\n\n// Used to pass the texture coordinates to the fragment shader\nout vec2 v_texCoord;\n\n// all shaders have a main function\nvoid main() {\n\n  // convert the position from pixels to 0.0 to 1.0\n  vec2 zeroToOne = a_position / u_resolution;\n\n  // convert from 0->1 to 0->2\n  vec2 zeroToTwo = zeroToOne * 2.0;\n\n  // convert from 0->2 to -1->+1 (clipspace)\n  vec2 clipSpace = zeroToTwo - 1.0;\n\n  gl_Position = vec4(clipSpace * vec2(1, -1), 0, 1);\n\n  // pass the texCoord to the fragment shader\n  // The GPU will interpolate this value between points.\n  v_texCoord = a_texCoord;\n}\n`,fragmentShaderSource=`#version 300 es\n\n// fragment shaders dont have a default precision so we need\n// to pick one. highp is a good default. It means "high precision"\nprecision highp float;\n\n// our texture\nuniform sampler2D u_image;\n\n// the time\nuniform float u_time;\n\n// the texCoords passed in from the vertex shader.\nin vec2 v_texCoord;\n\n// we need to declare an output for the fragment shader\nout vec4 outColor;\n\nvec3 mod289(vec3 x) {\n  return x - floor(x * (1.0 / 289.0)) * 289.0;\n}\n\nvec2 mod289(vec2 x) {\n  return x - floor(x * (1.0 / 289.0)) * 289.0;\n}\n\nvec3 permute(vec3 x) {\n  return mod289(((x*34.0)+1.0)*x);\n}\n\nfloat snoise(vec2 v)\n  {\n  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0\n                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)\n                      -0.577350269189626,  // -1.0 + 2.0 * C.x\n                      0.024390243902439); // 1.0 / 41.0\n  // First corner\n  vec2 i  = floor(v + dot(v, C.yy) );\n  vec2 x0 = v -   i + dot(i, C.xx);\n\n  // Other corners\n  vec2 i1;\n  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0\n  //i1.y = 1.0 - i1.x;\n  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);\n  // x0 = x0 - 0.0 + 0.0 * C.xx ;\n  // x1 = x0 - i1 + 1.0 * C.xx ;\n  // x2 = x0 - 1.0 + 2.0 * C.xx ;\n  vec4 x12 = x0.xyxy + C.xxzz;\n  x12.xy -= i1;\n\n  // Permutations\n  i = mod289(i); // Avoid truncation effects in permutation\n  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))\n    + i.x + vec3(0.0, i1.x, 1.0 ));\n\n  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);\n  m = m*m ;\n  m = m*m ;\n\n  // Gradients: 41 points uniformly over a line, mapped onto a diamond.\n  // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)\n\n  vec3 x = 2.0 * fract(p * C.www) - 1.0;\n  vec3 h = abs(x) - 0.5;\n  vec3 ox = floor(x + 0.5);\n  vec3 a0 = x - ox;\n\n  // Normalise gradients implicitly by scaling m\n  // Approximation of: m *= inversesqrt( a0*a0 + h*h );\n  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );\n\n  // Compute final noise value at P\n  vec3 g;\n  g.x  = a0.x  * x0.x  + h.x  * x0.y;\n  g.yz = a0.yz * x12.xz + h.yz * x12.yw;\n  return 130.0 * dot(m, g);\n}\n\nfloat rand(vec2 co)\n{\n   return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);\n}\n\nvoid main() {\n    // runs from 0.0 to 1.0 on both axis\n    vec2 uv = v_texCoord.xy;\n    float time = u_time * 2.0;\n\n    // Create large, incidental noise waves\n    float noise = max(0.0, snoise(vec2(time, uv.y * 0.3)) - 0.3) * (1.0 / 0.7);\n\n    // Offset by smaller, constant noise waves\n    noise = noise + (snoise(vec2(time*10.0, uv.y * 2.4)) - 0.5) * 0.15;\n\n    // Apply the noise as x displacement for every line\n    float xpos = uv.x - noise * noise * 0.25;\n    outColor = texture(u_image, vec2(xpos, uv.y));\n\n    // Mix in some random interference for lines\n    outColor.rgb = mix(outColor.rgb, vec3(rand(vec2(uv.y * time))), noise * 0.3).rgb;\n\n    // Apply a running line pattern, duration is 8 seconds. sin(0, pi) goes to (0.0, 1.0, 0.0)\n    float line_start_y = mod(0.125 * time, 3.14);\n    line_start_y = sin(line_start_y);\n    if (v_texCoord.y > line_start_y && v_texCoord.y < line_start_y + 0.03 + 0.01 * (0.5 - noise))\n    {\n      // take colors 3% from the right to give a shift effect\n      outColor.rgba = mix(outColor.rgba, texture(u_image, vec2(xpos + 0.03 - noise * 0.03, uv.y)).rgba, 0.8);\n      outColor.g = mix(outColor.r, texture(u_image, vec2(xpos + noise * 0.05, uv.y)).g, 0.5);\n      outColor.b = mix(outColor.r, texture(u_image, vec2(xpos - noise * 0.05, uv.y)).b, 0.5);\n    } else {\n      outColor.g = mix(outColor.r, texture(u_image, vec2(xpos + noise * 0.05, uv.y)).g, 0.6);\n      outColor.b = mix(outColor.r, texture(u_image, vec2(xpos - noise * 0.05, uv.y)).b, 0.6);\n    }\n\n    float interpolation = mod(time, 8.0);\n    float amplifier = 5.0;\n    if(interpolation <= 7.0) {\n      interpolation = interpolation * interpolation / 49.0;\n    } else {\n      interpolation = 8.0 - interpolation;\n    }\n    outColor.rgb = mix(outColor.rgb, texture(u_image, vec2(xpos + noise * 0.05, uv.y)).rgb, amplifier * interpolation);\n}\n`;function resizeCanvasToDisplaySize(e,n){n=n||1;const t=e.clientWidth*n|0,o=e.clientHeight*n|0;return(e.width!==t||e.height!==o)&&(e.width=t,e.height=o,!0)}function render(e){var n=document.querySelector("#canvas"),t=n.getContext("webgl2");if(!t)return;const o=t.createShader(t.VERTEX_SHADER);t.shaderSource(o,vertexShaderSource),t.compileShader(o);const r=t.createShader(t.FRAGMENT_SHADER);t.shaderSource(r,fragmentShaderSource),t.compileShader(r);var i=t.createProgram();t.attachShader(i,o),t.attachShader(i,r),t.linkProgram(i);var a=t.getAttribLocation(i,"a_position"),s=t.getAttribLocation(i,"a_texCoord"),c=t.getUniformLocation(i,"u_resolution"),x=t.getUniformLocation(i,"u_image"),u=t.getUniformLocation(i,"u_time"),v=t.createVertexArray();t.bindVertexArray(v);var m=t.createBuffer();t.enableVertexAttribArray(a),t.bindBuffer(t.ARRAY_BUFFER,m);var l=2,f=t.FLOAT,d=!1,h=0,p=0;t.vertexAttribPointer(a,l,f,d,h,p);var g=t.createBuffer();t.bindBuffer(t.ARRAY_BUFFER,g),t.bufferData(t.ARRAY_BUFFER,new Float32Array([0,0,1,0,0,1,0,1,1,0,1,1]),t.STATIC_DRAW),t.enableVertexAttribArray(s);l=2,f=t.FLOAT,d=!1,h=0,p=0;t.vertexAttribPointer(s,l,f,d,h,p);var _=t.createTexture();t.activeTexture(t.TEXTURE0+0),t.bindTexture(t.TEXTURE_2D,_),t.texParameteri(t.TEXTURE_2D,t.TEXTURE_WRAP_S,t.CLAMP_TO_EDGE),t.texParameteri(t.TEXTURE_2D,t.TEXTURE_WRAP_T,t.CLAMP_TO_EDGE),t.texParameteri(t.TEXTURE_2D,t.TEXTURE_MIN_FILTER,t.NEAREST),t.texParameteri(t.TEXTURE_2D,t.TEXTURE_MAG_FILTER,t.NEAREST);var T=t.RGBA,y=t.RGBA,E=t.UNSIGNED_BYTE;t.texImage2D(t.TEXTURE_2D,0,T,y,E,e);requestAnimationFrame(function o(r){r*=.001;r,resizeCanvasToDisplaySize(t.canvas),t.viewport(0,0,t.canvas.width,t.canvas.height),t.clearColor(0,0,0,0),t.clear(t.COLOR_BUFFER_BIT|t.DEPTH_BUFFER_BIT),t.useProgram(i),t.bindVertexArray(v),t.uniform2f(c,t.canvas.width,t.canvas.height),t.uniform1f(u,r),t.uniform1i(x,0),t.bindBuffer(t.ARRAY_BUFFER,m),setRectangle(t,0,0,e.width,e.height,n.width,n.height);var a=t.TRIANGLES;t.drawArrays(a,0,6),requestAnimationFrame(o)})}function setRectangle(e,n,t,o,r,i,a){var s=o/r,c=a,x=c*s;x>i&&(c=(x=i)/s);var u=n,v=n+x,m=t,l=t+c;e.bufferData(e.ARRAY_BUFFER,new Float32Array([u,m,v,m,u,l,u,l,v,m,v,l]),e.STATIC_DRAW)}const uri2url=e=>e.startsWith("ipfs://")?e.replace("ipfs://","https://ipfs.io/ipfs/"):e,TOKEN_URI="';
    string internal constant secondHtmlPart =
        '";var image=new Image;fetch(uri2url(TOKEN_URI)).then(e=>e.json()).then(e=>new Promise(n=>{const t=uri2url(e.image);image.crossOrigin="anonymous",image.src=t,image.onload=function(){n(image)}})).then(e=>{render(e)}).catch(e=>console.error(e));</script> </body></html>';

    function render(
        uint256, /* tokenId */
        address, /* underlyingTokenContract */
        uint256, /* underlyingTokenId */
        string calldata underlyingTokenURI,
        bool /* ownsUnderlying */
    )
        external
        pure
        returns (string memory html)
    {
        return string(
            abi.encodePacked(firstHtmlPart, underlyingTokenURI, secondHtmlPart)
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

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
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

    // /**
    //  * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    //  */
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    //  */
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    //  */
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    )
        external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IRenderer {
    function render(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId,
        string calldata underlyingTokenURI,
        bool ownsUnderlying
    )
        external
        pure
        returns (string memory html);
}