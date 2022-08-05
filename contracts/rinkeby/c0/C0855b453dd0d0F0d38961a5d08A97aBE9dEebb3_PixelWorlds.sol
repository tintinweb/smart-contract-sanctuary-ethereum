// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

library colorGenerator {
    function getColors(uint256 tokenId)
        internal
        pure
        returns (string memory color)
    {
        color = getSlice(3, 8, toString(abi.encodePacked(tokenId)));
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

contract PixelWorldsRight {
    string public dataR =
        ';var ctx=document["getElementById"]("game")["getContext"]("2d");var canvas=document["getElementById"]("game");canvas["setAttribute"]("width",String(N));canvas["setAttribute"]("height",String(N));let stages=0x20;let fps=0x3c;let delta_time=0x3e8/fps;let k_time=0x64;let time=(Date["now"]()-new Date()["getTimezoneOffset"]()*0x3c*0x3e8)%0x5265c00;const k_clouds=0.4;const grass_level=0.4;let colormap_land=[{"index":0x0,"rgb":[0xf,0xf,0xf0]},{"index":0.299,"rgb":[0x19,0x46,0xff]},{"index":0.3,"rgb":[0xf0,0xe6,0xdc]},{"index":0.4,"rgb":[0xc8,0xb4,0xa0]},{"index":0x1,"rgb":[0xc8,0xb4,0xa0]}];let colormap_clouds=[{"index":0x0,"rgb":[0x3c,0x3c,0x3c]},{"index":k_clouds+0.1,"rgb":[0xf0,0xf8,0xff]},{"index":0x1,"rgb":[0xf2,0xf3,0xf4]}];let colormap_grass=[{"index":0x0,"rgb":[0x0,0x80,0x66]},{"index":0x1,"rgb":[0xff,0xff,0x66]}];let color_land=createColormap({"colormap":colormap_land,"nshades":stages,"format":"hex","alpha":0x1});let color_clouds=createColormap({"colormap":colormap_clouds,"nshades":stages,"format":"hex","alpha":0x1});let color_grass=createColormap({"colormap":colormap_grass,"nshades":stages,"format":"hex","alpha":0x1});function componentToHex(a){var b=a["toString"](0x10);return b["length"]==0x1?"0"+b:b;}function hexToRgb(a){var b=/^#?([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})$/i["exec"](a);return b?[parseInt(b[0x1],0x10),parseInt(b[0x2],0x10),parseInt(b[0x3],0x10)]:null;}function rgbToHex(a){return"#"+componentToHex(a[0x0])+componentToHex(a[0x1])+componentToHex(a[0x2]);}function applyTime(a,b){let d=Math["sin"](b%0x5265c00/0x5265c00*Math["PI"]*0x2-Math["PI"]/0x2)/0xa*0x8+0x1;if(d>0x1)d=0x1;return rgbToHex(hexToRgb(a)["map"](e=>Math["round"](e*d)));}let stop=![];function animate(){if(stop)return;time+=delta_time;let a=time/k_time;for(let h=0x0;h<N;h++){for(let k=0x0;k<N;k++){var b=(Math["abs"](noise["perlin3"](h/N*m_land,k/N*m_land,a*s_land))+Math["abs"](noise["simplex2"](h/N*n_land,k/N*n_land)))/0x2;var c=Math["max"](0x0,Math["min"](stages-0x1,Math["round"](b*stages)));var d=Math["abs"](noise["perlin2"](h/N*m_clouds+a/0x60,k/N*m_clouds+a/0x60));var e=Math["max"](0x0,Math["min"](stages-0x1,Math["round"](d*stages)-0x1));var f=Math["abs"](noise["perlin3"](h/N*m_grass,k/N*m_grass,a/0x64+0x64)+0x1)/0x2;var g=Math["max"](0x0,Math["min"](stages-0x1,Math["round"](f*stages)-0x1));if(d>=k_clouds){ctx["fillStyle"]=applyTime(color_clouds[e],time);ctx["fillRect"](k*0x1,h*0x1,0x1,0x1);}else{if(b>=grass_level){ctx["fillStyle"]=applyTime(color_grass[g],time);ctx["fillRect"](k*0x1,h*0x1,0x1,0x1);}else{ctx["fillStyle"]=applyTime(color_land[c],time);ctx["fillRect"](k*0x1,h*0x1,0x1,0x1);}}}}setTimeout(function(){requestAnimationFrame(animate);},0x3e8/fps);}animate();</script></body></html>';
}

contract PixelWorldsMiddle {
    string public dataM =
        '";randomness=randomness["slice"](-0xf,-0x1);randomness=parseInt(randomness);noise["seed"](randomness);var m_land=randomness%0x19;var n_land=randomness%0x9;var m_clouds=randomness%0x11;var m_grass=randomness%0x17;var s_land=0x1/0x4/(0x1+randomness%0x16d);let N=';
}

contract PixelWorldsLeft {
    string public dataL =
        '<!DOCTYPE html><html><head> <meta charset="utf-8"> <style> body, html { width: 100%; height: 100%; margin: 0; padding: 0; background-color: black } canvas { display: block; width: 100%; height: auto; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; image-rendering: pixelated; image-rendering: crisp-edges; left: 0; top: 0; } </style> <title>PixelWorld</title></head><body> <canvas id="game" width="128" height="128"></canvas> <script>(function(a){var b=a["noise"]={};function c(o,q,r){this["x"]=o;this["y"]=q;this["z"]=r;}c["prototype"]["dot2"]=function(o,q){return this["x"]*o+this["y"]*q;};c["prototype"]["dot3"]=function(o,q,r){return this["x"]*o+this["y"]*q+this["z"]*r;};var d=[new c(0x1,0x1,0x0),new c(-0x1,0x1,0x0),new c(0x1,-0x1,0x0),new c(-0x1,-0x1,0x0),new c(0x1,0x0,0x1),new c(-0x1,0x0,0x1),new c(0x1,0x0,-0x1),new c(-0x1,0x0,-0x1),new c(0x0,0x1,0x1),new c(0x0,-0x1,0x1),new c(0x0,0x1,-0x1),new c(0x0,-0x1,-0x1)];var e=[0x97,0xa0,0x89,0x5b,0x5a,0xf,0x83,0xd,0xc9,0x5f,0x60,0x35,0xc2,0xe9,0x7,0xe1,0x8c,0x24,0x67,0x1e,0x45,0x8e,0x8,0x63,0x25,0xf0,0x15,0xa,0x17,0xbe,0x6,0x94,0xf7,0x78,0xea,0x4b,0x0,0x1a,0xc5,0x3e,0x5e,0xfc,0xdb,0xcb,0x75,0x23,0xb,0x20,0x39,0xb1,0x21,0x58,0xed,0x95,0x38,0x57,0xae,0x14,0x7d,0x88,0xab,0xa8,0x44,0xaf,0x4a,0xa5,0x47,0x86,0x8b,0x30,0x1b,0xa6,0x4d,0x92,0x9e,0xe7,0x53,0x6f,0xe5,0x7a,0x3c,0xd3,0x85,0xe6,0xdc,0x69,0x5c,0x29,0x37,0x2e,0xf5,0x28,0xf4,0x66,0x8f,0x36,0x41,0x19,0x3f,0xa1,0x1,0xd8,0x50,0x49,0xd1,0x4c,0x84,0xbb,0xd0,0x59,0x12,0xa9,0xc8,0xc4,0x87,0x82,0x74,0xbc,0x9f,0x56,0xa4,0x64,0x6d,0xc6,0xad,0xba,0x3,0x40,0x34,0xd9,0xe2,0xfa,0x7c,0x7b,0x5,0xca,0x26,0x93,0x76,0x7e,0xff,0x52,0x55,0xd4,0xcf,0xce,0x3b,0xe3,0x2f,0x10,0x3a,0x11,0xb6,0xbd,0x1c,0x2a,0xdf,0xb7,0xaa,0xd5,0x77,0xf8,0x98,0x2,0x2c,0x9a,0xa3,0x46,0xdd,0x99,0x65,0x9b,0xa7,0x2b,0xac,0x9,0x81,0x16,0x27,0xfd,0x13,0x62,0x6c,0x6e,0x4f,0x71,0xe0,0xe8,0xb2,0xb9,0x70,0x68,0xda,0xf6,0x61,0xe4,0xfb,0x22,0xf2,0xc1,0xee,0xd2,0x90,0xc,0xbf,0xb3,0xa2,0xf1,0x51,0x33,0x91,0xeb,0xf9,0xe,0xef,0x6b,0x31,0xc0,0xd6,0x1f,0xb5,0xc7,0x6a,0x9d,0xb8,0x54,0xcc,0xb0,0x73,0x79,0x32,0x2d,0x7f,0x4,0x96,0xfe,0x8a,0xec,0xcd,0x5d,0xde,0x72,0x43,0x1d,0x18,0x48,0xf3,0x8d,0x80,0xc3,0x4e,0x42,0xd7,0x3d,0x9c,0xb4];var f=new Array(0x200);var g=new Array(0x200);b["seed"]=function(o){if(o>0x0&&o<0x1){o*=0x10000;}o=Math["floor"](o);if(o<0x100){o|=o<<0x8;}for(var q=0x0;q<0x100;q++){var r;if(q&0x1){r=e[q]^o&0xff;}else{r=e[q]^o>>0x8&0xff;}f[q]=f[q+0x100]=r;g[q]=g[q+0x100]=d[r%0xc];}};b["seed"](0x0);var h=0.5*(Math["sqrt"](0x3)-0x1);var i=(0x3-Math["sqrt"](0x3))/0x6;var j=0x1/0x3;var k=0x1/0x6;function l(o){return o*o*o*(o*(o*0x6-0xf)+0xa);}function m(o,q,r){return(0x1-r)*o+r*q;}function n(o,q,r){let s=r*r*r*(r*(r*0x6-0xf)+0xa);return o+s*(q-o);}b["simplex2"]=function(o,q){var r,u,v;var w=(o+q)*h;var x=Math["floor"](o+w);var y=Math["floor"](q+w);var z=(x+y)*i;var A=o-x+z;var B=q-y+z;var C,D;if(A>B){C=0x1;D=0x0;}else{C=0x0;D=0x1;}var E=A-C+i;var F=B-D+i;var G=A-0x1+0x2*i;var H=B-0x1+0x2*i;x&=0xff;y&=0xff;var I=g[x+f[y]];var J=g[x+C+f[y+D]];var K=g[x+0x1+f[y+0x1]];var L=0.5-A*A-B*B;if(L<0x0){r=0x0;}else{L*=L;r=L*L*I["dot2"](A,B);}var M=0.5-E*E-F*F;if(M<0x0){u=0x0;}else{M*=M;u=M*M*J["dot2"](E,F);}var O=0.5-G*G-H*H;if(O<0x0){v=0x0;}else{O*=O;v=O*O*K["dot2"](G,H);}return 0x46*(r+u+v);};b["perlin2"]=function(o,q){var r=Math["floor"](o),s=Math["floor"](q);o=o-r;q=q-s;r=r&0xff;s=s&0xff;var t=g[r+f[s]]["dot2"](o,q);var v=g[r+f[s+0x1]]["dot2"](o,q-0x1);var w=g[r+0x1+f[s]]["dot2"](o-0x1,q);var z=g[r+0x1+f[s+0x1]]["dot2"](o-0x1,q-0x1);var A=l(o);return n(n(t,w,A),n(v,z,A),l(q));};b["perlin3"]=function(o,q,r){var s=Math["floor"](o),t=Math["floor"](q),A=Math["floor"](r);o=o-s;q=q-t;r=r-A;s=s&0xff;t=t&0xff;A=A&0xff;var B=g[s+f[t+f[A]]]["dot3"](o,q,r);var C=g[s+f[t+f[A+0x1]]]["dot3"](o,q,r-0x1);var D=g[s+f[t+0x1+f[A]]]["dot3"](o,q-0x1,r);var E=g[s+f[t+0x1+f[A+0x1]]]["dot3"](o,q-0x1,r-0x1);var F=g[s+0x1+f[t+f[A]]]["dot3"](o-0x1,q,r);var G=g[s+0x1+f[t+f[A+0x1]]]["dot3"](o-0x1,q,r-0x1);var H=g[s+0x1+f[t+0x1+f[A]]]["dot3"](o-0x1,q-0x1,r);var I=g[s+0x1+f[t+0x1+f[A+0x1]]]["dot3"](o-0x1,q-0x1,r-0x1);var J=l(o);var K=l(q);var L=l(r);return m(m(m(B,F,J),m(C,G,J),L),m(m(D,H,J),m(E,I,J),L),K);};}(this));function lerp(c,d,e){return(0x1-e)*c+e*d;}function createColormap(a){var b,c,d,e,f,g,h,k,l,m,n;if(!a)a={};k=(a["nshades"]||0x48)-0x1;h=a["format"]||"hex";g=a["colormap"];f=g;if(f["length"]>k+0x1){throw new Error(g+"errr"+f["length"]);}if(!Array["isArray"](a["alpha"])){if(typeof a["alpha"]==="number"){m=[a["alpha"],a["alpha"]];}else{m=[0x1,0x1];}}else if(a["alpha"]["length"]!==0x2){m=[0x1,0x1];}else{m=a["alpha"]["slice"]();}b=f["map"](function(r){return Math["round"](r["index"]*k);});m[0x0]=Math["min"](Math["max"](m[0x0],0x0),0x1);m[0x1]=Math["min"](Math["max"](m[0x1],0x0),0x1);var o=f["map"](function(r,s){var t=f[s]["index"];var u=f[s]["rgb"]["slice"]();if(u["length"]===0x4&&u[0x3]>=0x0&&u[0x3]<=0x1){return u;}u[0x3]=m[0x0]+(m[0x1]-m[0x0])*t;return u;});var l=[];for(n=0x0;n<b["length"]-0x1;++n){e=b[n+0x1]-b[n];c=o[n];d=o[n+0x1];for(var p=0x0;p<e;p++){var q=p/e;l["push"]([Math["round"](lerp(c[0x0],d[0x0],q)),Math["round"](lerp(c[0x1],d[0x1],q)),Math["round"](lerp(c[0x2],d[0x2],q)),lerp(c[0x3],d[0x3],q)]);}}l["push"](f[f["length"]-0x1]["rgb"]["concat"](m[0x1]));if(h==="hex")l=l["map"](rgb2hex);else if(h==="rgbaString")l=l["map"](rgbaStr);else if(h==="float")l=l["map"](rgb2float);return l;};function rgb2float(a){return[a[0x0]/0xff,a[0x1]/0xff,a[0x2]/0xff,a[0x3]];}function rgb2hex(a){var b,c="#";for(var d=0x0;d<0x3;++d){b=a[d];b=b["toString"](0x10);c+=("00"+b)["substr"](b["length"]);}return c;}function rgbaStr(a){return"rgba("+a["join"](",")+")";}let randomness="';
}

contract PixelWorlds is
    ERC721,
    PixelWorldsRight,
    PixelWorldsMiddle,
    PixelWorldsLeft
{
    modifier onlyOwner() {
        require(owner == msg.sender, "owner");
        _;
    }

    mapping(uint256 => uint256) data;

    address public owner;
    uint256 public immutable maxSupply = 100;
    uint256 public numClaimed = 0;

    bool public sale;
    mapping(address => uint8) public numOfMintedByWallet;

    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory ptr)
    {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for {
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)
        }
    }

    function generateHTMLandSVG(uint256 tokenId)
        internal
        view
        returns (string memory, string memory)
    {
        return (
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background-color: grey;text-align: center;"><rect x="0" y="0" width="350" height="350" style="fill:#',
                    colorGenerator.getColors(data[tokenId]),
                    ';"></rect><rect x="105" y="105" width="140" height="140" style="fill:#AAAAAA;"></rect><rect x="111" y="111" width="128" height="128" style="fill:#9b7653;"></rect><rect x="111" y="111" width="128" height="48" style="fill:#63b521;"></rect><text x="50%" y="60%" style="font-size:27px; font-family:Arial; text-anchor:middle">Open to inspect</text></svg>'
                )
            ),
            string(
                abi.encodePacked(
                    PixelWorldsLeft.dataL,
                    Strings.toString(data[tokenId]),
                    PixelWorldsMiddle.dataM,
                    Strings.toString(getSize(tokenId)),
                    PixelWorldsRight.dataR
                )
            )
        );
    }

    function getSize(uint256 tokenId) public view returns (uint256) {
        return 32 * ((data[tokenId] % 7) + 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        (string memory svg, string memory html) = generateHTMLandSVG(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Pixel World | ",
                                _toString(tokenId),
                                "",
                                '", "description":"Be a god of your pixel world!", "image":"',
                                string(
                                    abi.encodePacked(
                                        "data:image/svg+xml;base64,",
                                        Base64.encode(
                                            bytes(string(abi.encodePacked(svg)))
                                        )
                                    )
                                ),
                                '", "animation_url":"',
                                string(
                                    abi.encodePacked(
                                        "data:text/html;base64,",
                                        Base64.encode(
                                            bytes(
                                                string(abi.encodePacked(html))
                                            )
                                        )
                                    )
                                ),
                                '","attributes": [{"trait_type": "Grid size", "value": "',
                                _toString(getSize(tokenId)),
                                '"}]}'
                            )
                        )
                    )
                )
            );
    }

    function setSale(bool _set) public onlyOwner {
        sale = _set;
    }

    function setOwner(address _address) public onlyOwner {
        owner = _address;
    }

    function mint() public {
        require(numOfMintedByWallet[msg.sender] == 0, "RE");
        require(tx.origin == msg.sender, "BOT");
        require(numClaimed < maxSupply, "IC");
        require(sale == true, "ST");

        uint256 nonce = uint256(uint160(tx.origin));
        uint256 randomness = uint(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, nonce)
            )
        );

        numOfMintedByWallet[msg.sender]++;
        numClaimed += 1;
        data[numClaimed] = randomness;
        _safeMint(msg.sender, numClaimed);
    }

    constructor() ERC721("Pixel Worlds", "PW") {
        owner = msg.sender;
    }
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