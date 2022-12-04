// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// @author: white lights (whitelights.eth)
// @shoutout: dom aka dhof (dhof.eth)

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
    string private description =
        "A%20genart%20collaboration%20between%20White%20Lights%20and%20GPT-3.%20Core%20code%20was%20generated%20by%20the%20prompt%20'write%20threejs%20code%20that%20creates%20a%20fractal'%20with%20GPT-3.%20The%20code%20was%20concatenated%20together%20and%20then%20minorly%20modified%20by%20White%20Lights%20to%20ensure%20pleasing%20resizing%20behavior%20on%20all%20screens.";
    string private script =
        "%20%3Cscript%3Ewindow.onload%3D()%3D%3E%7Bvar%20e%3Dnew%20THREE.Scene%2Cn%3Dnew%20THREE.PerspectiveCamera(70%2Cwindow.innerWidth%2Fwindow.innerHeight%2C.1%2C1e3)%2Ci%3Dnew%20THREE.WebGLRenderer%3Bfunction%20r()%7Bn.aspect%3Dwindow.innerWidth%2Fwindow.innerHeight%2Cn.updateProjectionMatrix()%2Ci.setSize(window.innerWidth%2Cwindow.innerHeight)%7Dfunction%20t(e%2Cn)%7Bif(0%3D%3Dn)%7Bvar%20i%3Dnew%20THREE.BoxGeometry(e%2Ce%2Ce)%2Cr%3Dnew%20THREE.MeshBasicMaterial(%7Bcolor%3A65280%7D)%2Co%3Dnew%20THREE.Mesh(i%2Cr)%3Breturn%20o%7Dfor(var%20a%3Dnew%20THREE.Group%2Cd%3D-1%3Bd%3C%3D1%3Bd%2B%2B)for(var%20%24%3D-1%3B%24%3C%3D1%3B%24%2B%2B)for(var%20h%3D-1%3Bh%3C%3D1%3Bh%2B%2B)if(!(Math.abs(d)%2BMath.abs(%24)%2BMath.abs(h)%3E1))%7Bvar%20s%3De%2F3%2Co%3Dt(s%2Cn-1)%3Bo.position.set(d*s%2C%24*s%2Ch*s)%2Ca.add(o)%7Dreturn%20a%7Di.setSize(window.innerWidth%2Cwindow.innerHeight)%2Cdocument.body.appendChild(i.domElement)%2Cdocument.body.style.touchAction%3D'none'%2Cwindow.addEventListener('resize'%2Cr)%2Cdocument.body.style%3D'touchAction%3A%20none%3B%20margin%3A%200%3B%20padding%3A%200%3B%20overflow%3A%20hidden%3B%20height%3A%20100%25%3B%20width%3A%20100%25%3B'%2Cn.position.z%3D2%3Bvar%20o%3Dt(1%2C5)%3Bfunction%20a()%7BrequestAnimationFrame(a)%2Co.rotation.x%2B%3D.01%2Co.rotation.y%2B%3D.01%2Ci.render(e%2Cn)%7De.add(o)%2Ca()%7D%3B%3C%2Fscript%3E";
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

    function setCompilerAddress(address newAddress) public {
        require(msg.sender == owner);
        compiler = IDataChunkCompiler(newAddress);
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