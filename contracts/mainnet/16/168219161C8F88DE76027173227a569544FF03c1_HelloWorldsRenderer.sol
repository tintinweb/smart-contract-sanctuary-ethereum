// SPDX-License-Identifier: Unlicense
// by dom; use however you like

pragma solidity ^0.8.12;

interface IDataChunk {
    function data() external view returns (string memory);
}

interface IDataChunkCompiler {
    function BEGIN_JSON() external view returns (string memory);
    function END_JSON() external view returns (string memory);
    function HTML_HEAD() external view returns (string memory);
    function BEGIN_SCRIPT() external view returns (string memory);
    function END_SCRIPT() external view returns (string memory);
    function BEGIN_SCRIPT_DATA() external view returns (string memory);
    function END_SCRIPT_DATA() external view returns (string memory);
    function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function SCRIPT_VAR(string memory name, string memory value, bool omitQuotes) external pure returns (string memory);
    function BEGIN_METADATA_VAR(string memory name, bool omitQuotes) external pure returns (string memory);
    function END_METADATA_VAR(bool omitQuotes) external pure returns (string memory);

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
            compiler.BEGIN_JSON(),

            string.concat(
                compiler.BEGIN_METADATA_VAR("animation_url", false),
                    compiler.HTML_HEAD(),

                    string.concat(
                        compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
                            threejs,
                        compiler.END_SCRIPT_DATA_COMPRESSED(),
                        
                        compiler.BEGIN_SCRIPT(),
                            compiler.SCRIPT_VAR('tokenId', tokenIdStr, true),
                        compiler.END_SCRIPT()
                    ),

                    '%253Cstyle%253E%252A%257Bmargin%253A0%253Bpadding%253A0%257Dcanvas%257Bwidth%253A100%2525%253Bheight%253A100%2525%257D%253C%252Fstyle%253E%253Cscript%253Ewindow.onload%253D%2528%2528%2529%253D%253E%257Bconst%2520o%253Do%253D%253E%2528void%25200%2521%253D%253Do%2526%2526%2528l%253Do%25252147483647%2529%253C%253D0%2526%2526%2528l%252B%253D2147483646%2529%252C%2528%2528l%253D16807%252Al%25252147483647%2529-1%2529%252F2147483646%2529%253Bo%2528tokenId%2529%253Bconst%2520t%253D2%252AMath.PI%252Ci%253Dwindow.innerWidth%252Cn%253Dwindow.innerHeight%253Blet%2520e%252Ca%252Cr%252Cs%253D0%252Cd%253D0%252CE%253Dwindow.innerHeight%252F2%252Cp%253Dwindow.innerWidth%252F2%252Cc%253D%25211%252Cw%253D%255B%255D%253Bfunction%2520h%2528%2529%257BE%253Dwindow.innerHeight%252F2%252Cp%253Dwindow.innerWidth%252F2%252Ce.aspect%253Dwindow.innerWidth%252Fwindow.innerHeight%252Ce.updateProjectionMatrix%2528%2529%252Cr.setSize%2528window.innerWidth%252Cwindow.innerHeight%2529%257Dfunction%2520y%2528o%2529%257B%25211%2521%253D%253Do.isPrimary%2526%2526%2528s%253Do.clientY-E%252Cd%253Do.clientX-p%2529%257D%2521function%2528%2529%257Bvar%2520s%253Do%2528%2529%253E.88%252Cd%253Do%2528%2529%253E.9%253Bc%253Do%2528%2529%253E.7%252C%2528e%253Dnew%2520THREE.PerspectiveCamera%252880%252Ci%252Fn%252C1%252C3e3%2529%2529.position.z%253D1500%252C%2528a%253Dnew%2520THREE.Scene%2529.background%253Dnew%2520THREE.Color%2528s%253F16777215%253A0%2529%253Bconst%2520l%253Dnew%2520THREE.HemisphereLight%252816777147%252C526368%252C1%2529%253Bl.position.y%253D1e3%252Ca.add%2528l%2529%253Bvar%2520E%253Dnew%2520THREE.MeshPhongMaterial%253BE.color.set%252839168%2529%253Bvar%2520p%253Dnew%2520THREE.MeshPhongMaterial%253Bp.color.set%252865280%2529%253Bvar%2520H%253Dnew%2520THREE.MeshPhongMaterial%253BH.color.set%252816711680%2529%252CH.shading%253DTHREE.FlatShading%253Bconst%2520m%253Dnew%2520THREE.MeshBasicMaterial%253Bm.transparent%253D%25210%252Cm.opacity%253D.2%252B.2%252Ao%2528%2529%252Cm.blending%253DTHREE.AdditiveBlending%252Cm.color.set%252816777147%2529%253Bvar%2520M%253Dnew%2520THREE.LineBasicMaterial%253BM.color.set%252816777147%2529%252CM.transparent%253D%25210%252CM.opacity%253D.2%252CM.blending%253DTHREE.AdditiveBlending%252Cs%2526%2526%2528%2528M%253Dnew%2520THREE.LineBasicMaterial%2529.color.set%25280%2529%252CM.transparent%253D%25210%252CM.opacity%253D.2%252CM.blending%253DTHREE.NormalBlending%252Cm.blending%253DTHREE.NormalBlending%252Cm.color.set%25280%2529%2529%253Bd%2526%2526%2528E%253Dnew%2520THREE.MeshNormalMaterial%252Cp%253Dnew%2520THREE.MeshNormalMaterial%252CH%253Dnew%2520THREE.MeshNormalMaterial%2529%253Bfor%2528var%2520R%253D2%252CT%253D0%253BT%253C20%253BT%252B%252B%2529%257Bconst%2520i%253Dnew%2520THREE.BoxGeometry%252810%252B50%252Ao%2528%2529%252C50%252B50%252Ao%2528%2529%252C10%252B50%252Ao%2528%2529%2529%252Cn%253Dnew%2520THREE.Mesh%2528i%252CE%2529%253Bn.position.y%253D50%252AT-600%252Cn.rotation.x%253Do%2528%2529%252At%252Cn.rotation.y%253Do%2528%2529%252At%252Cn.rotation.z%253Do%2528%2529%252At%252Ca.add%2528n%2529%253Bconst%2520e%253Dnew%2520THREE.WireframeGeometry%2528i%2529%252Cr%253Dnew%2520THREE.LineSegments%2528e%2529%253Br.material%253DM%252Cr.position.x%253Dn.position.x%252Cr.position.y%253Dn.position.y%252Cr.position.z%253Dn.position.z%252Cr.rotation.x%253Dn.rotation.x%252Cr.rotation.y%253Dn.rotation.y%252Cr.rotation.z%253Dn.rotation.z%252Cr.scale.multiplyScalar%2528R%2529%252Ca.add%2528r%2529%257Dfor%2528var%2520R%253D2%252Cv%253D3%252BMath.ceil%25283%252Ao%2528%2529%2529%252CT%253D0%253BT%253Cv%253BT%252B%252B%2529for%2528var%2520f%253Do%2528%2529%252At%252Cx%253D700%252Ao%2528%2529-500%252Cg%253D4%252BMath.ceil%25284%252Ao%2528%2529%2529%252Cz%253D20%252B20%252Ao%2528%2529%252Cu%253D1%253Bu%253Cg%253Bu%252B%252B%2529%257Bconst%2520i%253Dnew%2520THREE.TetrahedronGeometry%2528z%252Bo%2528%2529%252Az%252C0%2529%252Cn%253Dnew%2520THREE.Mesh%2528i%252Cp%2529%253Bn.position.y%253Dx%252Cn.rotation.x%253Do%2528%2529%252At%252Cn.rotation.y%253Do%2528%2529%252At%252Cn.rotation.z%253Do%2528%2529%252At%252Cn.position.x%253Dz%252Au%252AMath.cos%2528f%2529%252Cn.position.z%253Dz%252Au%252AMath.sin%2528f%2529%252Cx%252B%253D5%252Au%252Ca.add%2528n%2529%253Bconst%2520e%253Dnew%2520THREE.WireframeGeometry%2528i%2529%252Cr%253Dnew%2520THREE.LineSegments%2528e%2529%253Br.material%253DM%252Cr.position.x%253Dn.position.x%252Cr.position.y%253Dn.position.y%252Cr.position.z%253Dn.position.z%252Cr.rotation.x%253Dn.rotation.x%252Cr.rotation.y%253Dn.rotation.y%252Cr.rotation.z%253Dn.rotation.z%252Cr.scale.multiplyScalar%2528R%2529%252Ca.add%2528r%2529%257Dfor%2528var%2520R%253D2%252CT%253D0%253BT%253C20%253BT%252B%252B%2529for%2528var%2520f%253Do%2528%2529%252At%252Cx%253D400%252Cg%253D4%252BMath.ceil%25284%252Ao%2528%2529%2529%252CS%253D20%252B20%252Ao%2528%2529%252Cu%253D1%253Bu%253Cg%253Bu%252B%252B%2529%257Bconst%2520i%253Dnew%2520THREE.BoxGeometry%252810%252B50%252Ao%2528%2529%252C50%252B50%252Ao%2528%2529%252C10%252B50%252Ao%2528%2529%2529%252Cn%253Dnew%2520THREE.Mesh%2528i%252CH%2529%253Bn.position.x%253DS%252Au%252AMath.cos%2528f%2529%252Cn.position.z%253DS%252Au%252AMath.sin%2528f%2529%252Cn.position.y%253Dx%252Cn.rotation.x%253Do%2528%2529%252At%252Cn.rotation.y%253Do%2528%2529%252At%252Cn.rotation.z%253Do%2528%2529%252At%252Ca.add%2528n%2529%252Cx%252B%253D10%252Au%253Bconst%2520e%253Dnew%2520THREE.WireframeGeometry%2528i%2529%252Cr%253Dnew%2520THREE.LineSegments%2528e%2529%253Br.material%253DM%252Cr.position.x%253Dn.position.x%252Cr.position.y%253Dn.position.y%252Cr.position.z%253Dn.position.z%252Cr.rotation.x%253Dn.rotation.x%252Cr.rotation.y%253Dn.rotation.y%252Cr.rotation.z%253Dn.rotation.z%252Cr.scale.multiplyScalar%2528R%2529%252Ca.add%2528r%2529%257Dvar%2520B%253D50%252BMath.ceil%252850%252Ao%2528%2529%2529%253Bo%2528%2529%253C.5%2526%2526%2528B%253D0%2529%253Bfor%2528var%2520b%253Do%2528%2529%253E.8%252CT%253D0%253BT%253CB%253BT%252B%252B%2529%257Bvar%2520f%253Do%2528%2529%252At%252Cx%253D-600%252Cg%253D4%252BMath.ceil%25284%252Ao%2528%2529%2529%252CS%253D20%252B500%252Ao%2528%2529%252CG%253D5%253Bb%2526%2526o%2528%2529%253E.8%2526%2526%2528G%253D20%2529%253Bfor%2528var%2520u%253D1%253Bu%253Cg%253Bu%252B%252B%2529%257Bconst%2520i%253Dnew%2520THREE.BoxGeometry%2528G%252CG%252CG%2529%252Cn%253Dnew%2520THREE.Mesh%2528i%252Cm%2529%253Bn.position.x%253DS%252Au%252AMath.cos%2528f%2529%252Cn.position.z%253DS%252Au%252AMath.sin%2528f%2529%252Cn.position.y%253Dx%252Cn.rotation.x%253Do%2528%2529%252At%252Cn.rotation.y%253Do%2528%2529%252At%252Cn.rotation.z%253Do%2528%2529%252At%252Ca.add%2528n%2529%252Cx%252B%253D100%252Au%252Cn.floatAmount%253Do%2528%2529%252Cn.floatSpeed%253Do%2528%2529%252Cw.push%2528n%2529%257D%257Dgeometry%253Dnew%2520THREE.SphereGeometry%2528500%252C3%2529%253Bvar%2520L%253Dnew%2520THREE.MeshBasicMaterial%2528%257Bcolor%253A16777215%257D%2529%252CP%253Dnew%2520THREE.Mesh%2528geometry%252CL%2529%253BP.position.x%253D-100%252CP.position.y%253D130%252CP.position.z%253D500%252C%2528r%253Dnew%2520THREE.WebGLRenderer%2528%257Bantialias%253A%25210%257D%2529%2529.setPixelRatio%2528window.devicePixelRatio%2529%252Cr.setSize%2528i%252Cn%2529%252Cdocument.body.appendChild%2528r.domElement%2529%252Cdocument.body.style.touchAction%253D%2522none%2522%252Cdocument.body.addEventListener%2528%2522pointermove%2522%252Cy%2529%252Cwindow.addEventListener%2528%2522resize%2522%252Ch%2529%257D%2528%2529%252Cfunction%2520o%2528%2529%257BrequestAnimationFrame%2528o%2529%253B%2521function%2528%2529%257Be.position.y%252B%253D.05%252A%2528200-s-e.position.y%2529%252Ca.rotation.y-%253D.005%252Ce.lookAt%2528a.position%2529%252Cr.render%2528a%252Ce%2529%253Bconst%2520o%253D.001%252ADate.now%2528%2529%253Bvar%2520t%253DMath.sin%2528o%2529%253Bfor%2528var%2520i%2520of%2520w%2529%257Bvar%2520n%253Di.position.y%253Bn%252F%253D100%253Bvar%2520d%253DMath.sin%2528o%252Ai.floatSpeed%2529%252Cl%253DMath.cos%2528o%252Ai.floatSpeed%252A2%2529%253Bi.position.y-%253Dd%252Ai.floatAmount%252Ci.position.x-%253Dl%252Ai.floatAmount%257Dif%2528%2521c%2529return%253Bfor%2528var%2520E%2520of%2520a.children%2529%257Bif%2528-1%2521%253Dw.indexOf%2528E%2529%2529return%253Bvar%2520n%253DE.position.y%252B500%253Bn%252F%253D1e4%252CE.position.y%252B%253D10%252At%252An%252CE.rotation.y%252B%253D.1%252An%257D%257D%2528%2529%257D%2528%2529%257D%2529%253B%253C%252Fscript%253E',

                compiler.END_METADATA_VAR(false)
            ),

            string.concat(
                compiler.BEGIN_METADATA_VAR("name", false),
                    'Rose%20', tokenIdStr,
                '%22' // trailing comma breaks things...
            ),

            compiler.END_JSON()
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