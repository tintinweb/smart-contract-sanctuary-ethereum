// SPDX-License-Identifier: Unlicense
// by dom; use however you like

pragma solidity ^0.8.12;

import "./Base64.sol";

interface IDataChunk {
    function data() external view returns (string memory);
}

interface IDataChunkCompiler {
    function HTML_HEAD() external view returns (string memory);
    function BEGIN_SCRIPT_DATA() external view returns (string memory);
    function END_SCRIPT_DATA() external view returns (string memory);
    function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function SCRIPT_VAR(string memory name, string memory value, bool omitQuotes) external pure returns (string memory);

    function compile2(address chunk1, address chunk2) external view returns (string memory);
    function compile3(address chunk1, address chunk2, address chunk3) external returns (string memory);
    function compile4(address chunk1, address chunk2, address chunk3, address chunk4)
        external view returns (string memory);
    function compile5(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5)
        external view returns (string memory);
    function compile6(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6)
        external view returns (string memory);
    function compile7(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7)
        external view returns (string memory);
    function compile8(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8)
        external view returns (string memory);
    function compile9(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8, address chunk9)
        external view returns (string memory);
}


contract HelloWorldsRenderer {
    address public owner;

    IDataChunkCompiler private compiler;

    address[9] private threeAddresses;

    constructor() {
        owner = msg.sender;
    }

    function setCompilerAddress(address newAddress) public {
        require(msg.sender == owner);
        compiler = IDataChunkCompiler(newAddress);
    }

    function setThreeAddress(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8, address chunk9) public {
        require(msg.sender == owner);
        threeAddresses[0] = chunk1;
        threeAddresses[1] = chunk2;
        threeAddresses[2] = chunk3;
        threeAddresses[3] = chunk4;
        threeAddresses[4] = chunk5;
        threeAddresses[5] = chunk6;
        threeAddresses[6] = chunk7;
        threeAddresses[7] = chunk8;
        threeAddresses[8] = chunk9;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory threejs = compiler.compile9(
            threeAddresses[0],
            threeAddresses[1],
            threeAddresses[2],
            threeAddresses[3],
            threeAddresses[4],
            threeAddresses[5],
            threeAddresses[6],
            threeAddresses[7],
            threeAddresses[8]
        );

        string memory tokenIdStr = uint2str(tokenId);

        return string.concat(
            "data:application/json,%7B", // data:application/json,{

            '%22image%22%3A%22https%3A%2F%2Floremflickr.com%2Fcache%2Fresized%2F65535_51821270379_dc9b1cd908_320_240_nofilter.jpg%22%2C', 
            // "image":"https://loremflickr.com/cache/resized/65535_51821270379_dc9b1cd908_320_240_nofilter.jpg",

            string.concat(
                '%22animation_url%22%3A%22', // "animation_url":"
                    compiler.HTML_HEAD(),

                    compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
                        threejs,
                    compiler.END_SCRIPT_DATA_COMPRESSED(),

                    '%3Cscript%3E', // <script>
                        compiler.SCRIPT_VAR('tokenId', tokenIdStr, true),
                    '%3C%2Fscript%3E', // </script>

                    // '<style>* { margin: 0; padding: 0 } canvas { width: 100%; height: 100% }</style>',
                    "%3Cstyle%3E%2A%20%7B%20margin%3A%200%3B%20padding%3A%200%20%7D%20canvas%20%7B%20width%3A%20100%25%3B%20height%3A%20100%25%20%7D%3C%2Fstyle%3E",
                    // "<script>setTimeout(()=>{const e=window.innerWidth,n=window.innerHeight,t=450;let i,o,a,r=0,c=window.innerHeight/2;function d(){c=window.innerHeight/2,i.aspect=window.innerWidth/window.innerHeight,i.updateProjectionMatrix(),a.setSize(window.innerWidth,window.innerHeight)}function s(e){!1!==e.isPrimary&&(r=e.clientY-c)}!function(){(i=new THREE.PerspectiveCamera(80,e/n,1,3e3)).position.z=1e3,o=new THREE.Scene;const r=[[.25,16742144,1],[.5,16750848,1],[.75,16755200,.75],[1,16755200,.5],[1.25,2099,.8],[3,11184810,.75],[3.5,16777215,.5],[4.5,16777215,.25],[5.5,16777215,.125]],c=function(){const e=new THREE.BufferGeometry,n=[],i=new THREE.Vector3;for(let e=0;e<1500;e++)i.x=2*Math.random()-1,i.y=2*Math.random()-1,i.z=2*Math.random()-1,i.normalize(),i.multiplyScalar(t),n.push(i.x,i.y,i.z),i.multiplyScalar(.09*Math.random()+1),n.push(i.x,i.y,i.z);return e.setAttribute('position',new THREE.Float32BufferAttribute(n,3)),e}();for(let e=0;e<r.length;++e){const n=r[e],t=new THREE.LineBasicMaterial({color:n[1],opacity:n[2]}),i=new THREE.LineSegments(c,t);i.scale.x=i.scale.y=i.scale.z=n[0],i.userData.originalScale=n[0],i.rotation.y=Math.random()*Math.PI,i.updateMatrix(),o.add(i)}(a=new THREE.WebGLRenderer({antialias:!0})).setPixelRatio(window.devicePixelRatio),a.setSize(e,n),document.body.appendChild(a.domElement),document.body.style.touchAction='none',document.body.addEventListener('pointermove',s),window.addEventListener('resize',d)}(),function e(){requestAnimationFrame(e);!function(){i.position.y+=.05*(200-r-i.position.y),i.lookAt(o.position),a.render(o,i);const e=1e-4*Date.now();for(let n=0;n<o.children.length;n++){const t=o.children[n];if(t.isLine&&(t.rotation.y=e*(n<4?n+1:-(n+1)),n<5)){const i=t.userData.originalScale*(n/5+1)*(1+.5*Math.sin(7*e));t.scale.x=t.scale.y=t.scale.z=i}}}()}()},1e3);</script>",
                    "%3Cscript%3EsetTimeout%28%28%29%3D%3E%7Bconst%20e%3Dwindow.innerWidth%2Cn%3Dwindow.innerHeight%2Ct%3D450%3Blet%20i%2Co%2Ca%2Cr%3D0%2Cc%3Dwindow.innerHeight%2F2%3Bfunction%20d%28%29%7Bc%3Dwindow.innerHeight%2F2%2Ci.aspect%3Dwindow.innerWidth%2Fwindow.innerHeight%2Ci.updateProjectionMatrix%28%29%2Ca.setSize%28window.innerWidth%2Cwindow.innerHeight%29%7Dfunction%20s%28e%29%7B%211%21%3D%3De.isPrimary%26%26%28r%3De.clientY-c%29%7D%21function%28%29%7B%28i%3Dnew%20THREE.PerspectiveCamera%2880%2Ce%2Fn%2C1%2C3e3%29%29.position.z%3D1e3%2Co%3Dnew%20THREE.Scene%3Bconst%20r%3D%5B%5B.25%2C16742144%2C1%5D%2C%5B.5%2C16750848%2C1%5D%2C%5B.75%2C16755200%2C.75%5D%2C%5B1%2C16755200%2C.5%5D%2C%5B1.25%2C2099%2C.8%5D%2C%5B3%2C11184810%2C.75%5D%2C%5B3.5%2C16777215%2C.5%5D%2C%5B4.5%2C16777215%2C.25%5D%2C%5B5.5%2C16777215%2C.125%5D%5D%2Cc%3Dfunction%28%29%7Bconst%20e%3Dnew%20THREE.BufferGeometry%2Cn%3D%5B%5D%2Ci%3Dnew%20THREE.Vector3%3Bfor%28let%20e%3D0%3Be%3C1500%3Be%2B%2B%29i.x%3D2%2AMath.random%28%29-1%2Ci.y%3D2%2AMath.random%28%29-1%2Ci.z%3D2%2AMath.random%28%29-1%2Ci.normalize%28%29%2Ci.multiplyScalar%28t%29%2Cn.push%28i.x%2Ci.y%2Ci.z%29%2Ci.multiplyScalar%28.09%2AMath.random%28%29%2B1%29%2Cn.push%28i.x%2Ci.y%2Ci.z%29%3Breturn%20e.setAttribute%28%27position%27%2Cnew%20THREE.Float32BufferAttribute%28n%2C3%29%29%2Ce%7D%28%29%3Bfor%28let%20e%3D0%3Be%3Cr.length%3B%2B%2Be%29%7Bconst%20n%3Dr%5Be%5D%2Ct%3Dnew%20THREE.LineBasicMaterial%28%7Bcolor%3An%5B1%5D%2Copacity%3An%5B2%5D%7D%29%2Ci%3Dnew%20THREE.LineSegments%28c%2Ct%29%3Bi.scale.x%3Di.scale.y%3Di.scale.z%3Dn%5B0%5D%2Ci.userData.originalScale%3Dn%5B0%5D%2Ci.rotation.y%3DMath.random%28%29%2AMath.PI%2Ci.updateMatrix%28%29%2Co.add%28i%29%7D%28a%3Dnew%20THREE.WebGLRenderer%28%7Bantialias%3A%210%7D%29%29.setPixelRatio%28window.devicePixelRatio%29%2Ca.setSize%28e%2Cn%29%2Cdocument.body.appendChild%28a.domElement%29%2Cdocument.body.style.touchAction%3D%27none%27%2Cdocument.body.addEventListener%28%27pointermove%27%2Cs%29%2Cwindow.addEventListener%28%27resize%27%2Cd%29%7D%28%29%2Cfunction%20e%28%29%7BrequestAnimationFrame%28e%29%3B%21function%28%29%7Bi.position.y%2B%3D.05%2A%28200-r-i.position.y%29%2Ci.lookAt%28o.position%29%2Ca.render%28o%2Ci%29%3Bconst%20e%3D1e-4%2ADate.now%28%29%3Bfor%28let%20n%3D0%3Bn%3Co.children.length%3Bn%2B%2B%29%7Bconst%20t%3Do.children%5Bn%5D%3Bif%28t.isLine%26%26%28t.rotation.y%3De%2A%28n%3C4%3Fn%2B1%3A-%28n%2B1%29%29%2Cn%3C5%29%29%7Bconst%20i%3Dt.userData.originalScale%2A%28n%2F5%2B1%29%2A%281%2B.5%2AMath.sin%287%2Ae%29%29%3Bt.scale.x%3Dt.scale.y%3Dt.scale.z%3Di%7D%7D%7D%28%29%7D%28%29%7D%2C1e3%29%3B%3C%2Fscript%3E",
                '%22%2C' // ",
            ),

            string.concat(
                '%22name%22%3A%22', // "name":"
                    'Token%20', tokenIdStr,
                '%22' // "
            ),

            "%7D" // }
        );
    }

    // via https://stackoverflow.com/a/65707309
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

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