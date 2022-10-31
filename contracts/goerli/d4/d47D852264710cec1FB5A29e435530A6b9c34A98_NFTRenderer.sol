import "./interfaces/IDataChunkCompiler.sol";

contract NFTRenderer {
    /**
     * @dev owner is the owner of the contract
     */
    address public owner;

    /**
     * @dev compiler is the instance of the DataChunkCompiler contract on Goerli by ROSES
     * url:https://goerli.etherscan.io/address/0xEeA6556f135AaEcA7819b369a3CfaEd43B02d169#code
     */
    IDataChunkCompiler private compiler = IDataChunkCompiler(0xEeA6556f135AaEcA7819b369a3CfaEd43B02d169);

    /**
     * @dev threeAddressed is the address list of the Threejs library contract data which is gzip compressed and Base64 encoded data on Goerli by ROSES
     */
    address[9] private threeAddresses = [
        0xA27ce71ce7D92793404B224d3F31043c7F5Fa15b,
        0x740E1b93Bf77686B409Adce96341bC4047dA2464,
        0x248930e364D2B1a0C5b672687080E45e7CaFBB7b,
        0x03728478F23B6CE057217792A53d9be9eD124e97,
        0xd4b8AF84DD5C024eB2c0485b27DD5f5266929065,
        0xa08582200014f3865D61BAF88e12c67CdA023aF9,
        0x1174727f22A9F80Bc158386BE728Bd81154fa0D8,
        0x11958611287b1798696d66456a2b5458988822bc,
        0x6743dBEc9432f098bcB66eAEa7c25Dbece63a2aE
    ];


    constructor( ) {
        owner = msg.sender;
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

                    '%253Cstyle%253E%250D%250A%2B%2B%2B%2B%2B%2B%252A%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bmargin%253A%2B0%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bpadding%253A%2B0%253B%250D%250A%2B%2B%2B%2B%2B%2B%257D%250D%250A%2B%2B%2B%2B%2B%2Bcanvas%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bwidth%253A%2B100%2525%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bheight%253A%2B100%2525%253B%250D%250A%2B%2B%2B%2B%2B%2B%257D%250D%250A%2B%2B%2B%2B%253C%252Fstyle%253E%250D%250A%2B%2B%2B%2B%253Cscript%253E%250D%250A%2B%2B%2B%2B%2B%2Bwindow.onload%2B%253D%2B%2528%2529%2B%253D%253E%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bscene%2B%253D%2Bnew%2BTHREE.Scene%2528%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bo%2B%253D%2B%2528o%2529%2B%253D%253E%2B%2528%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bvoid%2B0%2B%2521%253D%253D%2Bo%2B%2526%2526%2B%2528l%2B%253D%2Bo%2B%2525%2B2147483647%2529%2B%253C%253D%2B0%2B%2526%2526%2B%2528l%2B%252B%253D%2B2147483646%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2528%2528l%2B%253D%2B%252816807%2B%252A%2Bl%2529%2B%2525%2B2147483647%2529%2B-%2B1%2529%2B%252F%2B2147483646%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcolor%2B%253D%2B%2522%2523%2522%2B%252B%2Bo%2528tokenId%2529.toString%2528%2529.slice%2528-6%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcar%2B%253D%2BcreateCar%2528color%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bscene.add%2528car%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BambientLight%2B%253D%2Bnew%2BTHREE.AmbientLight%25280xffffff%252C%2B0.6%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bscene.add%2528ambientLight%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BdirLight%2B%253D%2Bnew%2BTHREE.DirectionalLight%25280xffffff%252C%2B0.8%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2BdirLight.position.set%2528200%252C%2B500%252C%2B300%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bscene.add%2528dirLight%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BaspectRatio%2B%253D%2Bwindow.innerWidth%2B%252F%2Bwindow.innerHeight%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcameraWidth%2B%253D%2B150%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcameraHeight%2B%253D%2BcameraWidth%2B%252F%2BaspectRatio%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcamera%2B%253D%2Bnew%2BTHREE.OrthographicCamera%2528%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcameraWidth%2B%252F%2B-2%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcameraWidth%2B%252F%2B2%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcameraHeight%2B%252F%2B2%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcameraHeight%2B%252F%2B-2%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B0%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B1000%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bcamera.position.set%2528200%252C%2B200%252C%2B200%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bcamera.lookAt%25280%252C%2B10%252C%2B0%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Brenderer%2B%253D%2Bnew%2BTHREE.WebGLRenderer%2528%257B%2Bantialias%253A%2Btrue%2B%257D%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Brenderer.setSize%2528window.innerWidth%252C%2Bwindow.innerHeight%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Brenderer.render%2528scene%252C%2Bcamera%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Brenderer.setAnimationLoop%2528%2528%2529%2B%253D%253E%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcar.rotation.y%2B-%253D%2B0.007%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Brenderer.render%2528scene%252C%2Bcamera%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%257D%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bdocument.body.appendChild%2528renderer.domElement%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bfunction%2BcreateCar%2528color%2529%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcar%2B%253D%2Bnew%2BTHREE.Group%2528%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BbackWheel%2B%253D%2BcreateWheels%2528%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BbackWheel.position.y%2B%253D%2B6%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BbackWheel.position.x%2B%253D%2B-18%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcar.add%2528backWheel%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BfrontWheel%2B%253D%2BcreateWheels%2528%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BfrontWheel.position.y%2B%253D%2B6%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BfrontWheel.position.x%2B%253D%2B18%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcar.add%2528frontWheel%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bmain%2B%253D%2Bnew%2BTHREE.Mesh%2528%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.BoxGeometry%252860%252C%2B15%252C%2B30%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bcolor%253A%2Bcolor%2B%257D%2529%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bmain.position.y%2B%253D%2B12%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcar.add%2528main%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcarFrontTexture%2B%253D%2BgetCarFrontTexture%2528%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcarBackTexture%2B%253D%2BgetCarFrontTexture%2528%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcarRightSideTexture%2B%253D%2BgetCarSideTexture%2528%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2BcarLeftSideTexture%2B%253D%2BgetCarSideTexture%2528%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcarLeftSideTexture.center%2B%253D%2Bnew%2BTHREE.Vector2%25280.5%252C%2B0.5%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcarLeftSideTexture.rotation%2B%253D%2BMath.PI%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2BcarLeftSideTexture.flipY%2B%253D%2Bfalse%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcabin%2B%253D%2Bnew%2BTHREE.Mesh%2528new%2BTHREE.BoxGeometry%252833%252C%2B12%252C%2B24%2529%252C%2B%255B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bmap%253A%2BcarFrontTexture%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bmap%253A%2BcarBackTexture%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bcolor%253A%2Bcolor%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bcolor%253A%2Bcolor%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bmap%253A%2BcarRightSideTexture%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bmap%253A%2BcarLeftSideTexture%2B%257D%2529%252C%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2B%255D%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcabin.position.x%2B%253D%2B-6%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcabin.position.y%2B%253D%2B25.5%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcar.add%2528cabin%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Breturn%2Bcar%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%257D%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bfunction%2BcreateWheels%2528%2529%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bgeometry%2B%253D%2Bnew%2BTHREE.BoxGeometry%252812%252C%2B12%252C%2B33%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bmaterial%2B%253D%2Bnew%2BTHREE.MeshLambertMaterial%2528%257B%2Bcolor%253A%2B0x333333%2B%257D%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bwheel%2B%253D%2Bnew%2BTHREE.Mesh%2528geometry%252C%2Bmaterial%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Breturn%2Bwheel%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%257D%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bfunction%2BgetCarFrontTexture%2528%2529%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcanvas%2B%253D%2Bdocument.createElement%2528%2522canvas%2522%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcanvas.width%2B%253D%2B64%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcanvas.height%2B%253D%2B32%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcontext%2B%253D%2Bcanvas.getContext%2528%25222d%2522%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillStyle%2B%253D%2B%2522%2523ffffff%2522%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillRect%25280%252C%2B0%252C%2B64%252C%2B32%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillStyle%2B%253D%2B%2522%2523666666%2522%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillRect%25288%252C%2B8%252C%2B48%252C%2B24%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Breturn%2Bnew%2BTHREE.CanvasTexture%2528canvas%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%257D%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2Bfunction%2BgetCarSideTexture%2528%2529%2B%257B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcanvas%2B%253D%2Bdocument.createElement%2528%2522canvas%2522%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcanvas.width%2B%253D%2B128%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcanvas.height%2B%253D%2B32%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bconst%2Bcontext%2B%253D%2Bcanvas.getContext%2528%25222d%2522%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillStyle%2B%253D%2B%2522%2523ffffff%2522%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillRect%25280%252C%2B0%252C%2B128%252C%2B32%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillStyle%2B%253D%2B%2522%2523666666%2522%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillRect%252810%252C%2B8%252C%2B38%252C%2B24%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Bcontext.fillRect%252858%252C%2B8%252C%2B60%252C%2B24%2529%253B%250D%250A%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%2B%2Breturn%2Bnew%2BTHREE.CanvasTexture%2528canvas%2529%253B%250D%250A%2B%2B%2B%2B%2B%2B%2B%2B%257D%250D%250A%2B%2B%2B%2B%2B%2B%257D%253B%250D%250A%2B%2B%2B%2B%253C%252Fscript%253E',

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