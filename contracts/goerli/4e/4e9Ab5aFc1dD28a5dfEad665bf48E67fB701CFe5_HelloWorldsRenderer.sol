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

            // '%22image%22%3A%22https%3A%2F%2Floremflickr.com%2Fcache%2Fresized%2F65535_51821270379_dc9b1cd908_320_240_nofilter.jpg%22%2C', 
            // "image":"https://loremflickr.com/cache/resized/65535_51821270379_dc9b1cd908_320_240_nofilter.jpg",

            string.concat(
                '%22animation_url%22%3A%22', // "animation_url":"
                    compiler.HTML_HEAD(),

                    compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
                        threejs,
                    compiler.END_SCRIPT_DATA_COMPRESSED(),

                    '%253Cscript%253E', // <script>
                        compiler.SCRIPT_VAR('tokenId', tokenIdStr, true),
                    '%253C%252Fscript%253E', // </script>

                    // '<style>* { margin: 0; padding: 0 } canvas { width: 100%; height: 100% }</style>',
                    // "%3Cstyle%3E%2A%20%7B%20margin%3A%200%3B%20padding%3A%200%20%7D%20canvas%20%7B%20width%3A%20100%25%3B%20height%3A%20100%25%20%7D%3C%2Fstyle%3E",
                    // "<script>setTimeout(()=>{const e=window.innerWidth,n=window.innerHeight,t=450;let i,o,a,r=0,c=window.innerHeight/2;function d(){c=window.innerHeight/2,i.aspect=window.innerWidth/window.innerHeight,i.updateProjectionMatrix(),a.setSize(window.innerWidth,window.innerHeight)}function s(e){!1!==e.isPrimary&&(r=e.clientY-c)}!function(){(i=new THREE.PerspectiveCamera(80,e/n,1,3e3)).position.z=1e3,o=new THREE.Scene;const r=[[.25,16742144,1],[.5,16750848,1],[.75,16755200,.75],[1,16755200,.5],[1.25,2099,.8],[3,11184810,.75],[3.5,16777215,.5],[4.5,16777215,.25],[5.5,16777215,.125]],c=function(){const e=new THREE.BufferGeometry,n=[],i=new THREE.Vector3;for(let e=0;e<1500;e++)i.x=2*Math.random()-1,i.y=2*Math.random()-1,i.z=2*Math.random()-1,i.normalize(),i.multiplyScalar(t),n.push(i.x,i.y,i.z),i.multiplyScalar(.09*Math.random()+1),n.push(i.x,i.y,i.z);return e.setAttribute('position',new THREE.Float32BufferAttribute(n,3)),e}();for(let e=0;e<r.length;++e){const n=r[e],t=new THREE.LineBasicMaterial({color:n[1],opacity:n[2]}),i=new THREE.LineSegments(c,t);i.scale.x=i.scale.y=i.scale.z=n[0],i.userData.originalScale=n[0],i.rotation.y=Math.random()*Math.PI,i.updateMatrix(),o.add(i)}(a=new THREE.WebGLRenderer({antialias:!0})).setPixelRatio(window.devicePixelRatio),a.setSize(e,n),document.body.appendChild(a.domElement),document.body.style.touchAction='none',document.body.addEventListener('pointermove',s),window.addEventListener('resize',d)}(),function e(){requestAnimationFrame(e);!function(){i.position.y+=.05*(200-r-i.position.y),i.lookAt(o.position),a.render(o,i);const e=1e-4*Date.now();for(let n=0;n<o.children.length;n++){const t=o.children[n];if(t.isLine&&(t.rotation.y=e*(n<4?n+1:-(n+1)),n<5)){const i=t.userData.originalScale*(n/5+1)*(1+.5*Math.sin(7*e));t.scale.x=t.scale.y=t.scale.z=i}}}()}()},1e3);</script>",
                    // "%253Cscript%253EsetTimeout%2528%2528%2529%253D%253E%257Bconst%2520e%253Dwindow.innerWidth%252Cn%253Dwindow.innerHeight%252Ct%253D450%253Blet%2520i%252Co%252Ca%252Cr%253D0%252Cc%253Dwindow.innerHeight%252F2%253Bfunction%2520d%2528%2529%257Bc%253Dwindow.innerHeight%252F2%252Ci.aspect%253Dwindow.innerWidth%252Fwindow.innerHeight%252Ci.updateProjectionMatrix%2528%2529%252Ca.setSize%2528window.innerWidth%252Cwindow.innerHeight%2529%257Dfunction%2520s%2528e%2529%257B%25211%2521%253D%253De.isPrimary%2526%2526%2528r%253De.clientY-c%2529%257D%2521function%2528%2529%257B%2528i%253Dnew%2520THREE.PerspectiveCamera%252880%252Ce%252Fn%252C1%252C3e3%2529%2529.position.z%253D1e3%252Co%253Dnew%2520THREE.Scene%253Bconst%2520r%253D%255B%255B.25%252C16742144%252C1%255D%252C%255B.5%252C16750848%252C1%255D%252C%255B.75%252C16755200%252C.75%255D%252C%255B1%252C16755200%252C.5%255D%252C%255B1.25%252C2099%252C.8%255D%252C%255B3%252C11184810%252C.75%255D%252C%255B3.5%252C16777215%252C.5%255D%252C%255B4.5%252C16777215%252C.25%255D%252C%255B5.5%252C16777215%252C.125%255D%255D%252Cc%253Dfunction%2528%2529%257Bconst%2520e%253Dnew%2520THREE.BufferGeometry%252Cn%253D%255B%255D%252Ci%253Dnew%2520THREE.Vector3%253Bfor%2528let%2520e%253D0%253Be%253C1500%253Be%252B%252B%2529i.x%253D2%252AMath.random%2528%2529-1%252Ci.y%253D2%252AMath.random%2528%2529-1%252Ci.z%253D2%252AMath.random%2528%2529-1%252Ci.normalize%2528%2529%252Ci.multiplyScalar%2528t%2529%252Cn.push%2528i.x%252Ci.y%252Ci.z%2529%252Ci.multiplyScalar%2528.09%252AMath.random%2528%2529%252B1%2529%252Cn.push%2528i.x%252Ci.y%252Ci.z%2529%253Breturn%2520e.setAttribute%2528%2527position%2527%252Cnew%2520THREE.Float32BufferAttribute%2528n%252C3%2529%2529%252Ce%257D%2528%2529%253Bfor%2528let%2520e%253D0%253Be%253Cr.length%253B%252B%252Be%2529%257Bconst%2520n%253Dr%255Be%255D%252Ct%253Dnew%2520THREE.LineBasicMaterial%2528%257Bcolor%253An%255B1%255D%252Copacity%253An%255B2%255D%257D%2529%252Ci%253Dnew%2520THREE.LineSegments%2528c%252Ct%2529%253Bi.scale.x%253Di.scale.y%253Di.scale.z%253Dn%255B0%255D%252Ci.userData.originalScale%253Dn%255B0%255D%252Ci.rotation.y%253DMath.random%2528%2529%252AMath.PI%252Ci.updateMatrix%2528%2529%252Co.add%2528i%2529%257D%2528a%253Dnew%2520THREE.WebGLRenderer%2528%257Bantialias%253A%25210%257D%2529%2529.setPixelRatio%2528window.devicePixelRatio%2529%252Ca.setSize%2528e%252Cn%2529%252Cdocument.body.appendChild%2528a.domElement%2529%252Cdocument.body.style.touchAction%253D%2527none%2527%252Cdocument.body.addEventListener%2528%2527pointermove%2527%252Cs%2529%252Cwindow.addEventListener%2528%2527resize%2527%252Cd%2529%257D%2528%2529%252Cfunction%2520e%2528%2529%257BrequestAnimationFrame%2528e%2529%253B%2521function%2528%2529%257Bi.position.y%252B%253D.05%252A%2528200-r-i.position.y%2529%252Ci.lookAt%2528o.position%2529%252Ca.render%2528o%252Ci%2529%253Bconst%2520e%253D1e-4%252ADate.now%2528%2529%253Bfor%2528let%2520n%253D0%253Bn%253Co.children.length%253Bn%252B%252B%2529%257Bconst%2520t%253Do.children%255Bn%255D%253Bif%2528t.isLine%2526%2526%2528t.rotation.y%253De%252A%2528n%253C4%253Fn%252B1%253A-%2528n%252B1%2529%2529%252Cn%253C5%2529%2529%257Bconst%2520i%253Dt.userData.originalScale%252A%2528n%252F5%252B1%2529%252A%25281%252B.5%252AMath.sin%25287%252Ae%2529%2529%253Bt.scale.x%253Dt.scale.y%253Dt.scale.z%253Di%257D%257D%257D%2528%2529%257D%2528%2529%257D%252C1e3%2529%253B%253C%252Fscript%253E",

                    '%253Cstyle%253E%252A%2520%257B%2520margin%253A%25200%253B%2520padding%253A%25200%2520%257D%2520canvas%2520%257B%2520width%253A%2520100%2525%253B%2520height%253A%2520100%2525%2520%257D%253C%252Fstyle%253E%253Cscript%253EsetTimeout%2528%2528%2529%253D%253E%257Bconst%2520e%253Dwindow.innerWidth%252Cn%253Dwindow.innerHeight%252Ct%253D450%253Blet%2520i%252Co%252Ca%252Cr%253D0%252Cc%253Dwindow.innerHeight%252F2%253Bfunction%2520d%2528%2529%257Bc%253Dwindow.innerHeight%252F2%252Ci.aspect%253Dwindow.innerWidth%252Fwindow.innerHeight%252Ci.updateProjectionMatrix%2528%2529%252Ca.setSize%2528window.innerWidth%252Cwindow.innerHeight%2529%257Dfunction%2520s%2528e%2529%257B%25211%2521%253D%253De.isPrimary%2526%2526%2528r%253De.clientY-c%2529%257D%2521function%2528%2529%257B%2528i%253Dnew%2520THREE.PerspectiveCamera%252880%252Ce%252Fn%252C1%252C3e3%2529%2529.position.z%253D1e3%252Co%253Dnew%2520THREE.Scene%253Bconst%2520r%253D%255B%255B.25%252C16742144%252C1%255D%252C%255B.5%252C16750848%252C1%255D%252C%255B.75%252C16755200%252C.75%255D%252C%255B1%252C16755200%252C.5%255D%252C%255B1.25%252C2099%252C.8%255D%252C%255B3%252C11184810%252C.75%255D%252C%255B3.5%252C16777215%252C.5%255D%252C%255B4.5%252C16777215%252C.25%255D%252C%255B5.5%252C16777215%252C.125%255D%255D%252Cc%253Dfunction%2528%2529%257Bconst%2520e%253Dnew%2520THREE.BufferGeometry%252Cn%253D%255B%255D%252Ci%253Dnew%2520THREE.Vector3%253Bfor%2528let%2520e%253D0%253Be%253C1500%253Be%252B%252B%2529i.x%253D2%252AMath.random%2528%2529-1%252Ci.y%253D2%252AMath.random%2528%2529-1%252Ci.z%253D2%252AMath.random%2528%2529-1%252Ci.normalize%2528%2529%252Ci.multiplyScalar%2528t%2529%252Cn.push%2528i.x%252Ci.y%252Ci.z%2529%252Ci.multiplyScalar%2528.09%252AMath.random%2528%2529%252B1%2529%252Cn.push%2528i.x%252Ci.y%252Ci.z%2529%253Breturn%2520e.setAttribute%2528%2527position%2527%252Cnew%2520THREE.Float32BufferAttribute%2528n%252C3%2529%2529%252Ce%257D%2528%2529%253Bfor%2528let%2520e%253D0%253Be%253Cr.length%253B%252B%252Be%2529%257Bconst%2520n%253Dr%255Be%255D%252Ct%253Dnew%2520THREE.LineBasicMaterial%2528%257Bcolor%253An%255B1%255D%252Copacity%253An%255B2%255D%257D%2529%252Ci%253Dnew%2520THREE.LineSegments%2528c%252Ct%2529%253Bi.scale.x%253Di.scale.y%253Di.scale.z%253Dn%255B0%255D%252Ci.userData.originalScale%253Dn%255B0%255D%252Ci.rotation.y%253DMath.random%2528%2529%252AMath.PI%252Ci.updateMatrix%2528%2529%252Co.add%2528i%2529%257D%2528a%253Dnew%2520THREE.WebGLRenderer%2528%257Bantialias%253A%25210%257D%2529%2529.setPixelRatio%2528window.devicePixelRatio%2529%252Ca.setSize%2528e%252Cn%2529%252Cdocument.body.appendChild%2528a.domElement%2529%252Cdocument.body.style.touchAction%253D%2527none%2527%252Cdocument.body.addEventListener%2528%2527pointermove%2527%252Cs%2529%252Cwindow.addEventListener%2528%2527resize%2527%252Cd%2529%257D%2528%2529%252Cfunction%2520e%2528%2529%257BrequestAnimationFrame%2528e%2529%253B%2521function%2528%2529%257Bi.position.y%252B%253D.05%252A%2528200-r-i.position.y%2529%252Ci.lookAt%2528o.position%2529%252Ca.render%2528o%252Ci%2529%253Bconst%2520e%253D1e-4%252ADate.now%2528%2529%253Bfor%2528let%2520n%253D0%253Bn%253Co.children.length%253Bn%252B%252B%2529%257Bconst%2520t%253Do.children%255Bn%255D%253Bif%2528t.isLine%2526%2526%2528t.rotation.y%253De%252A%2528n%253C4%253Fn%252B1%253A-%2528n%252B1%2529%2529%252Cn%253C5%2529%2529%257Bconst%2520i%253Dt.userData.originalScale%252A%2528n%252F5%252B1%2529%252A%25281%252B.5%252AMath.sin%25287%252Ae%2529%2529%253Bt.scale.x%253Dt.scale.y%253Dt.scale.z%253Di%257D%257D%257D%2528%2529%257D%2528%2529%257D%252C1e3%2529%253B%253C%252Fscript%253E'

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