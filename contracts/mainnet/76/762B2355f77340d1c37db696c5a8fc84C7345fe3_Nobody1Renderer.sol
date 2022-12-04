// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// @author: white lights (whitelights.eth)
// @shoutout: dom aka dhof (dom.eth)

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▐     //
//    ▌ ██  NOBODY                                                                   ▐     //
//    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █╟█▌█████████████████████████████████████████████████████████████████████████  ▐     //
//    ██████▀███████████▌██████▌█▌████████▌███▌████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    ██▀▀██╙███▌████│╬╜▌██▌█╫█▌█▌█▌██╠╠██▀█╟█▌████║▀██████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █▌█▄▄▌█▄▄█╣▄▄██████▄███▄▄█▄██▄▄███▄██████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █▌█████▌█████████████████████▌███║███████████████████████████████████████████  ▐     //
//    █╣███████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    ███╣╬▌██║██████████████║█████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████▌███████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █ C:\> █                                                                       ▐     //
//    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀     //
//                                                                                         //
//    a collaboration between white lights and nobody (a.i.)                               //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

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

    function BEGIN_SCRIPT_DATA_COMPRESSED()
        external
        view
        returns (string memory);

    function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);

    function SCRIPT_VAR(
        string memory name,
        string memory value,
        bool omitQuotes
    ) external pure returns (string memory);

    function BEGIN_METADATA_VAR(string memory name, bool omitQuotes)
        external
        pure
        returns (string memory);

    function END_METADATA_VAR(bool omitQuotes)
        external
        pure
        returns (string memory);

    function compile2(address chunk1, address chunk2)
        external
        view
        returns (string memory);

    function compile3(
        address chunk1,
        address chunk2,
        address chunk3
    ) external returns (string memory);

    function compile4(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4
    ) external view returns (string memory);

    function compile5(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4,
        address chunk5
    ) external view returns (string memory);

    function compile6(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4,
        address chunk5,
        address chunk6
    ) external view returns (string memory);

    function compile7(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4,
        address chunk5,
        address chunk6,
        address chunk7
    ) external view returns (string memory);

    function compile8(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4,
        address chunk5,
        address chunk6,
        address chunk7,
        address chunk8
    ) external view returns (string memory);

    function compile9(
        address chunk1,
        address chunk2,
        address chunk3,
        address chunk4,
        address chunk5,
        address chunk6,
        address chunk7,
        address chunk8,
        address chunk9
    ) external view returns (string memory);
}

contract Nobody1Renderer {
    address public owner;

    string private name = "Fractal%20Study%2001";
    string private image =
        "https://arweave.net/FsmxO5iF_wCdKb4-Q9KYLoADDv_e8hepSFPPoJet03o"; // since this is just for platform display layers and not the artwork itself, I'm okay with this being on Arweave.
    string private description =
        "A%20genart%20collaboration%20between%20White%20Lights%20and%20GPT-3%20artificial%20intelligence.%20The%20code%20that%20creates%20this%20artwork%20was%20generated%20by%20prompting%20OpenAI%20GPT-3%20to%20'write%20threejs%20code%20that%20creates%20a%20fractal'.%20The%20outputs%20were%20concatenated%20together%20and%20then%20slightly%20modified%20by%20White%20Lights%20to%20ensure%20pleasing%20resizing%20behavior%20on%20all%20screens.%20The%20script%20and%20its%20rendering%20engine%20are%20served%20on-chain%20using%20permanent%20Ethereum%20contract%20storage%20without%20dependencies%2C%20ensuring%20the%20artwork%20lasts%20as%20long%20as%20the%20chain.%20Thank%20you%20to%20dhof.eth%20for%20his%20ingenious%20open-source%20smart%20contracts%20which%20allow%20this%20on-chain%20rendering%20to%20be%20possible.";
    string private script =
        "%253Cscript%253Ewindow.onload%253D()%253D%253E%257Bvar%2520e%253Dnew%2520THREE.Scene%252Cn%253Dnew%2520THREE.PerspectiveCamera(70%252Cwindow.innerWidth%252Fwindow.innerHeight%252C.1%252C10)%252Ci%253Dnew%2520THREE.WebGLRenderer%253Bfunction%2520t()%257Bn.aspect%253Dwindow.innerWidth%252Fwindow.innerHeight%252Cn.updateProjectionMatrix()%252Ci.setSize(window.innerWidth%252Cwindow.innerHeight)%257Dfunction%2520r(e%252Cn)%257Bif(0%253D%253Dn)%257Bvar%2520i%253Dnew%2520THREE.BoxGeometry(e%252Ce%252Ce)%252Ct%253Dnew%2520THREE.MeshBasicMaterial(%257Bcolor%253A65280%257D)%252Co%253Dnew%2520THREE.Mesh(i%252Ct)%253Breturn%2520o%257Dfor(var%2520a%253Dnew%2520THREE.Group%252Cd%253D-1%253Bd%253C%253D1%253Bd%252B%252B)for(var%2520%2524%253D-1%253B%2524%253C%253D1%253B%2524%252B%252B)for(var%2520h%253D-1%253Bh%253C%253D1%253Bh%252B%252B)if(!(Math.abs(d)%252BMath.abs(%2524)%252BMath.abs(h)%253E1))%257Bvar%2520s%253De%252F3%252Co%253Dr(s%252Cn-1)%253Bo.position.set(d*s%252C%2524*s%252Ch*s)%252Ca.add(o)%257Dreturn%2520a%257Di.setSize(window.innerWidth%252Cwindow.innerHeight)%252Ci.setPixelRatio(1)%252Cdocument.body.appendChild(i.domElement)%252Cdocument.body.style.touchAction%253D'none'%252Cwindow.addEventListener('resize'%252Ct)%252Cdocument.body.style%253D'touchAction%253A%2520none%253B%2520margin%253A%25200%253B%2520padding%253A%25200%253B%2520overflow%253A%2520hidden%253B%2520height%253A%2520100%2525%253B%2520width%253A%2520100%2525%253B'%252Cn.position.z%253D2%253Bvar%2520o%253Dr(1%252Cwindow.innerWidth%253E%253D500%253F4%253A3)%253Bfunction%2520a()%257BrequestAnimationFrame(a)%252Co.rotation.x%252B%253D.005%252Co.rotation.y%252B%253D.005%252Ci.render(e%252Cn)%257De.add(o)%252Ca()%257D%253B%253C%252Fscript%253E";
    IDataChunkCompiler private compiler =
        IDataChunkCompiler(0xeC8EF4c339508224E063e43e30E2dCBe19D9c087);

    address[9] private threeAddresses = [
        0xA32bb79b33B29e483d0949C99EC0C439b29e2B33,
        0x0d104Dea962b090bC46c67a12e800ff16eeffB75,
        0x1D11a1c75e439A50734AEF3469aed9ca4fFe39fc,
        0x6bAb43D4F3587f9f3ca1152C63E52BF7F8de2Dc1,
        0x57beAe62670Ff6cCf8311411a2A2aAb453413987,
        0xF3A95B30E1Fc2EdCea41fF93270249b6Ab979730,
        0x52a31D845f4bdC1D47Ee21dB7C25Bde2423A91Ae,
        0x6CcCc7eA426E14F1E07528296c7d226677fd2fF6,
        0xc230862406bBe44f499943Ae4E9E6317a95BC7Ad
    ];

    constructor() {
        owner = msg.sender;
    }

    function setDescription(string memory des) public {
        require(msg.sender == owner);
        description = des;
    }

    function setScript(string memory scr) public {
        require(msg.sender == owner);
        script = scr;
    }

    function setName(string memory n) public {
        require(msg.sender == owner);
        name = n;
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

        return
            string.concat(
                compiler.BEGIN_JSON(),
                string.concat(
                    compiler.BEGIN_METADATA_VAR("animation_url", false),
                    compiler.HTML_HEAD(),
                    string.concat(
                        compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
                        threejs,
                        compiler.END_SCRIPT_DATA_COMPRESSED(),
                        compiler.BEGIN_SCRIPT(),
                        compiler.SCRIPT_VAR("tokenId", tokenIdStr, true),
                        compiler.END_SCRIPT()
                    ),
                    script,
                    compiler.END_METADATA_VAR(false)
                ),
                string.concat(
                    compiler.BEGIN_METADATA_VAR("artist", false),
                    "NOBODY",
                    compiler.END_METADATA_VAR(false)
                ),
                string.concat(
                    compiler.BEGIN_METADATA_VAR("description", false),
                    description,
                    compiler.END_METADATA_VAR(false)
                ),
                string.concat(
                    compiler.BEGIN_METADATA_VAR("image", false),
                    image,
                    compiler.END_METADATA_VAR(false)
                ),
                string.concat(
                    compiler.BEGIN_METADATA_VAR("name", false),
                    name,
                    "%22" // @WARN: do not put a trailing comma here as that's not valid JSON
                ),
                compiler.END_JSON()
            );
    }

    function uint2str(uint _i)
        public
        pure
        returns (string memory _uintAsString)
    {
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}