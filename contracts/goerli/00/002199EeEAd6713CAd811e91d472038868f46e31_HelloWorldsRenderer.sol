// SPDX-License-Identifier: Unlicense
// by dom; use however you like

pragma solidity ^0.8.12;

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
            "{",

            string.concat(
                '"animation_url":"',
                    compiler.HTML_HEAD(),

                    compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
                        threejs,
                    compiler.END_SCRIPT_DATA_COMPRESSED(),

                    '<script>',
                        compiler.SCRIPT_VAR('tokenId', tokenIdStr, true),
                    '</script>',

                    '<style>* { margin: 0; padding: 0 } canvas { width: 100%; height: 100% }</style>',
                    "<script>setTimeout(()=>{const e=window.innerWidth,n=window.innerHeight,t=450;let i,o,a,r=0,c=window.innerHeight/2;function d(){c=window.innerHeight/2,i.aspect=window.innerWidth/window.innerHeight,i.updateProjectionMatrix(),a.setSize(window.innerWidth,window.innerHeight)}function s(e){!1!==e.isPrimary&&(r=e.clientY-c)}!function(){(i=new THREE.PerspectiveCamera(80,e/n,1,3e3)).position.z=1e3,o=new THREE.Scene;const r=[[.25,16742144,1],[.5,16750848,1],[.75,16755200,.75],[1,16755200,.5],[1.25,2099,.8],[3,11184810,.75],[3.5,16777215,.5],[4.5,16777215,.25],[5.5,16777215,.125]],c=function(){const e=new THREE.BufferGeometry,n=[],i=new THREE.Vector3;for(let e=0;e<1500;e++)i.x=2*Math.random()-1,i.y=2*Math.random()-1,i.z=2*Math.random()-1,i.normalize(),i.multiplyScalar(t),n.push(i.x,i.y,i.z),i.multiplyScalar(.09*Math.random()+1),n.push(i.x,i.y,i.z);return e.setAttribute('position',new THREE.Float32BufferAttribute(n,3)),e}();for(let e=0;e<r.length;++e){const n=r[e],t=new THREE.LineBasicMaterial({color:n[1],opacity:n[2]}),i=new THREE.LineSegments(c,t);i.scale.x=i.scale.y=i.scale.z=n[0],i.userData.originalScale=n[0],i.rotation.y=Math.random()*Math.PI,i.updateMatrix(),o.add(i)}(a=new THREE.WebGLRenderer({antialias:!0})).setPixelRatio(window.devicePixelRatio),a.setSize(e,n),document.body.appendChild(a.domElement),document.body.style.touchAction='none',document.body.addEventListener('pointermove',s),window.addEventListener('resize',d)}(),function e(){requestAnimationFrame(e);!function(){i.position.y+=.05*(200-r-i.position.y),i.lookAt(o.position),a.render(o,i);const e=1e-4*Date.now();for(let n=0;n<o.children.length;n++){const t=o.children[n];if(t.isLine&&(t.rotation.y=e*(n<4?n+1:-(n+1)),n<5)){const i=t.userData.originalScale*(n/5+1)*(1+.5*Math.sin(7*e));t.scale.x=t.scale.y=t.scale.z=i}}}()}()},1e3);</script>",
                '",'
            ),

            string.concat(
                '"name":"',
                    'Token #', tokenIdStr,
                '"'
            ),

            "}"
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