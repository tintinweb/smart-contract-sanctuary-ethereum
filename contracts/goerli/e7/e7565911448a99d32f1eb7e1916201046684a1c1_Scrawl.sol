// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AnonymiceLibrary.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

interface IScrawlArt {
    function scrawlArtCode() external view returns (string memory);
}

contract Scrawl is ERC721, Ownable {
    /*
 ▄▀▀▀▀▄  ▄▀▄▄▄▄   ▄▀▀▄▀▀▀▄  ▄▀▀█▄   ▄▀▀▄    ▄▀▀▄  ▄▀▀▀▀▄                                                       
█ █   ▐ █ █    ▌ █   █   █ ▐ ▄▀ ▀▄ █   █    ▐  █ █    █                                                        
   ▀▄   ▐ █      ▐  █▀▀█▀    █▄▄▄█ ▐  █        █ ▐    █                                                        
▀▄   █    █       ▄▀    █   ▄▀   █   █   ▄    █      █                                                         
 █▀▀▀    ▄▀▄▄▄▄▀ █     █   █   ▄▀     ▀▄▀ ▀▄ ▄▀    ▄▀▄▄▄▄▄▄▀                                                   
 ▐      █     ▐  ▐     ▐   ▐   ▐            ▀      █                                                           
        ▐                                          ▐                                                           
 ▄▀▀█▄▄   ▄▀▀▄ ▀▀▄      ▄▀▀▄▀▀▀▄  ▄▀▀█▀▄   ▄▀▀▄  ▄▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▀▀▄   ▄▀▀▄    ▄▀▀▄  ▄▀▀█▄   ▄▀▀▄ ▀▄  ▄▀▀▄ █ 
▐ ▄▀   █ █   ▀▄ ▄▀     █   █   █ █   █  █ █    █   █ ▐  ▄▀   ▐ █    █   █   █    ▐  █ ▐ ▄▀ ▀▄ █  █ █ █ █  █ ▄▀ 
  █▄▄▄▀  ▐     █       ▐  █▀▀▀▀  ▐   █  ▐ ▐     ▀▄▀    █▄▄▄▄▄  ▐    █   ▐  █        █   █▄▄▄█ ▐  █  ▀█ ▐  █▀▄  
  █   █        █          █          █         ▄▀ █    █    ▌      █      █   ▄    █   ▄▀   █   █   █    █   █ 
 ▄▀▄▄▄▀      ▄▀         ▄▀        ▄▀▀▀▀▀▄     █  ▄▀   ▄▀▄▄▄▄     ▄▀▄▄▄▄▄▄▀ ▀▄▀ ▀▄ ▄▀  █   ▄▀  ▄▀   █   ▄▀   █  
█    ▐       █         █         █       █  ▄▀  ▄▀    █    ▐     █               ▀    ▐   ▐   █    ▐   █    ▐  
▐            ▐         ▐         ▐       ▐ █    ▐     ▐          ▐                            ▐        ▐       
*/
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    struct HashNeeds {
        uint16 startHash;
        uint16 startNonce;
    }

    // address for p5 code stored in separate contract
    address public scrawlArt;

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(address => uint256) private lastWrite;

    //Mint Checks
    mapping(address => bool) addressCircSaleMinted;
    mapping(address => bool) addressFreelistMinted;
    mapping(address => bool) addressAllowlistMinted;
    uint256 public totalSupply = 0;

    //uint256s
    uint256 public constant MAX_SUPPLY = 420;
    uint256 public constant CIRCOLORS_PRESALE_COST = 0.0256 ether;
    uint256 public constant GENERAL_MINT_COST = 0.0365 ether;

    //public mint start timestamp
    uint256 public SALE_START;

    bool initStart = false;

    mapping(uint256 => HashNeeds) tokenIdToHashNeeds;
    uint16 SEED_NONCE = 0;

    //minting flag
    bool griffMinted = false;
    bool public MINTING_LIVE = false;

    //uint arrays
    uint16[][7] TIERS;

    //p5js url
    string p5jsUrl =
        "https%3A%2F%2Fcdnjs.cloudflare.com%2Fajax%2Flibs%2Fp5.js%2F1.4.0%2Fp5.js";
    string p5jsIntegrity =
        "sha256-maU2GxaUCz5WChkAGR40nt9sbWRPEfF8qo%2FprxhoKPQ%3D";
    string animationUrl =
        "https://circolors.mypinata.cloud/ipfs/QmayAdMcP5QpWRcjf8W8hkcWLipLEMcNcm1XatTwLBP1zG?x=";
    string imageUrl = "https://scrawl-by-pixelwank.s3.amazonaws.com/output/";

    bytes32 constant circPresaleRoot =
        0x033224e2e1b8ce2132962703f35f45128bdc39b20dff36738793fabec0431486;

    bytes32 constant freelistRoot =
        0x546956aa5de7e3d03fc608e2dde183f412cddcb51b1fa425c67999f44710f295;

    bytes32 constant generalMintlistRoot =
        0xd5a3f650c9366b35260f7de176ca096cd5c16fbf149981b7423a743c91b9b1c2;

    constructor(address _scrawlArt) payable ERC721("SCRAWL", "SCRAWL") {
        scrawlArt = _scrawlArt;
        //Declare all the rarity tiers

        //Palettes
        TIERS[0] = [
            250,
            500,
            500,
            500,
            500,
            750,
            500,
            250,
            500,
            500,
            500,
            250,
            600,
            750,
            500,
            500,
            500,
            250,
            500,
            500,
            400
        ];
        //Bg
        TIERS[1] = [5500, 3500, 700, 300];
        //Depth
        TIERS[2] = [1000, 3500, 5500];
        //Passes
        TIERS[3] = [4200, 3300, 2000, 500];
        //Tidy
        TIERS[4] = [5000, 5000];
        //Shape
        TIERS[5] = [7500, 500, 700, 1300];
        //Border
        TIERS[6] = [2500, 2000, 500, 5000];
    }

    //prevents someone calling read functions the same block they mint
    modifier disallowIfStateIsChanging() {
        require(
            owner() == msg.sender || lastWrite[msg.sender] < block.number,
            "not so fast!"
        );
        _;
    }

    /*
 __    __     __     __   __     ______   __     __   __     ______    
/\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
\ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/  \/_/   \/_/   \/_/ \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/ 
                                                                                                                                                                                                                                               
   */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;

        uint256 length = TIERS[_rarityTier].length;
        for (uint8 i = 0; i < length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @param _a The address to be used within the hash.
     */
    function hash(address _a) internal view returns (uint16) {
        uint16 _randinput = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, _a)
                )
            ) % 10000
        );

        return _randinput;
    }

    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 8 character string.
        string memory currentHash = "";
        uint256 rInput = tokenIdToHashNeeds[_t].startHash;
        uint256 _nonce = tokenIdToHashNeeds[_t].startNonce;

        for (uint8 i = 0; i < 7; i++) {
            ++_nonce;
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(rInput, _t, _nonce))) % 10000
            );

            if (i == 0) {
                uint8 rar = rarityGen(_randinput, i);
                if (rar > 9) {
                    currentHash = string(
                        abi.encodePacked(currentHash, rar.toString())
                    );
                } else {
                    currentHash = string(
                        abi.encodePacked(currentHash, "0", rar.toString())
                    );
                }
            } else {
                currentHash = string(
                    abi.encodePacked(
                        currentHash,
                        rarityGen(_randinput, i).toString()
                    )
                );
            }
        }
        return currentHash;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        require(
            MINTING_LIVE == true || msg.sender == owner(),
            "Minting not live"
        );
        require(initStart, "Minting not begun");
        require(block.timestamp < SALE_START + 72 hours, "Minting over");

        uint256 thisTokenId = totalSupply;

        require(thisTokenId < MAX_SUPPLY, "Minted out");

        tokenIdToHashNeeds[thisTokenId] = HashNeeds(
            hash(msg.sender),
            SEED_NONCE
        );

        lastWrite[msg.sender] = block.number;
        SEED_NONCE += 8;

        _mint(msg.sender, thisTokenId);
        ++totalSupply;
    }

    function mintGriff() external {
        require(!griffMinted, "You already minted knobhead");
        require(msg.sender == 0xdb4782d463628cc5b1de8f1220f755BA3bA4728E);

        uint256 firstId = totalSupply;
        require(firstId + 5 < MAX_SUPPLY, "Minted out");

        for (uint256 i = 0; i < 5; i++) {
            tokenIdToHashNeeds[firstId + i] = HashNeeds(
                hash(msg.sender),
                SEED_NONCE
            );

            SEED_NONCE += 8;

            _mint(msg.sender, firstId + i);
        }
        totalSupply += 5;
        griffMinted = true;
    }

    /**
     * @dev Mints new tokens.
     */
    function mintCircolorsPresale(
        address account,
        bytes32[] calldata merkleProof
    ) external payable {
        // Check address is on the merkle root
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, circPresaleRoot, node),
            "Not on Circolors Presale list"
        );
        require(account == msg.sender, "Self mint only");
        require(msg.value == CIRCOLORS_PRESALE_COST, "Mint is 0.0256eth");
        require(
            addressCircSaleMinted[msg.sender] != true,
            "Address already minted presale"
        );

        addressCircSaleMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintFreelist(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, freelistRoot, node),
            "Not on Free mint list"
        );
        require(account == msg.sender, "Self mint only");
        require(
            addressFreelistMinted[msg.sender] != true,
            "Address already free minted"
        );

        addressFreelistMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintAllowlist(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, generalMintlistRoot, node),
            "Not on Allowlist"
        );
        require(account == msg.sender, "Self mint only");
        require(msg.value == GENERAL_MINT_COST, "Mint is 0.0365eth");
        require(
            addressAllowlistMinted[msg.sender] != true,
            "Address already minted allow list"
        );
        require(
            block.timestamp > SALE_START + 24 hours,
            "Allowlist mint not started yet"
        );

        addressAllowlistMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintPublic() external payable {
        require(msg.value == GENERAL_MINT_COST, "Mint is 0.0365eth");
        require(
            block.timestamp > SALE_START + 48 hours,
            "Public mint not started"
        );
        return mintInternal();
    }

    /*
 ______     ______     ______     _____     __     __   __     ______    
/\  == \   /\  ___\   /\  __ \   /\  __-.  /\ \   /\ "-.\ \   /\  ___\   
\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/ /_/   \/_____/   \/_/\/_/   \/____/   \/_/   \/_/ \/_/   \/_____/                                                                    
                                                                                           
*/
    function allowlistStart() external view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 24 hours;
    }

    function generalSaleStart() external view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 48 hours;
    }

    function mintDeadline() public view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 72 hours;
    }

    /**
     * @dev Hash to HTML function
     */
    function hashToHTML(string memory _hash, uint256 _tokenId)
        external
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory htmlString = string(
            abi.encodePacked(
                "data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22",
                p5jsUrl,
                "%22%20integrity%3D%22",
                p5jsIntegrity,
                "%22%20crossorigin%3D%22anonymous%22%3E%0A%3C%2Fscript%3E%0A%3Cstyle%3E%0Abody%20%7B%0A%20%20margin%3A%200%3B%0A%20%20padding%3A%200%3B%0A%20%20background%3A%20%23000%3B%0A%20%20overflow%3A%20hidden%3B%0A%7D%0A%0A%23fs%20%7B%0A%20%20position%3A%20fixed%3B%0A%20%20top%3A%200%3B%0A%20%20right%3A%200%3B%0A%20%20bottom%3A%200%3B%0A%20%20left%3A%200%3B%0A%20%20background-color%3A%20black%3B%0A%20%20display%3A%20flex%3B%0A%20%20justify-content%3A%20center%3B%0A%20%20align-items%3A%20center%3B%0A%7D%0A%0A%23fs%20canvas%20%7B%0A%20%20object-fit%3A%20contain%3B%0A%20%20max-height%3A%20100%25%3B%0A%20%20max-width%3A%20100%25%3B%0A%7D%0A%3C%2Fstyle%3E%3C%2Fhead%3E%3Cbody%3E%3Cdiv%20id%3D%22fs%22%3E%3C%2Fdiv%3E%3Cscript%3Evar%20tI%3D",
                AnonymiceLibrary.toString(_tokenId),
                "%3Bvar%20h%3D%22",
                _hash,
                "%22%3B"
            )
        );

        string memory artCode = IScrawlArt(scrawlArt).scrawlArtCode();

        htmlString = string(abi.encodePacked(htmlString, artCode));

        return htmlString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;

        uint8 paletteTraitIndex = AnonymiceLibrary.parseInt(
            AnonymiceLibrary.substring(_hash, 0, 2)
        );

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"',
                traitTypes[0][paletteTraitIndex].traitType,
                '","value":"',
                traitTypes[0][paletteTraitIndex].traitName,
                '"},'
            )
        );

        for (uint8 i = 2; i < 7; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 6)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the image and metadata for a token Id
     * @param _tokenId The tokenId to return the image and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply, "non existant id");

        string memory tokenHash = _tokenIdToHash(_tokenId);

        string
            memory description = '", "description": "420 SCRAWL pieces by pixelwank x Circolors. Traits generated on chain & metadata, images mirrored on chain permanently.",';

        string memory encodedTokenId = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(AnonymiceLibrary.toString(_tokenId))))
        );
        string memory encodedHash = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(tokenHash)))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "SCRAWL #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '"animation_url":"',
                                    animationUrl,
                                    encodedTokenId,
                                    "&t=",
                                    encodedHash,
                                    '","image":"',
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    '.png","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        require(_tokenId < totalSupply, "non existant id");
        string memory tokenHash = buildHash(_tokenId);

        return tokenHash;
    }

    /*
 ______     __     __     __   __     ______     ______    
/\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
\ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
 \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
  \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                           
    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] calldata traits)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function initStartTimes() external onlyOwner {
        require(!initStart, "mint time already started");
        SALE_START = block.timestamp;
        initStart = true;
    }

    function flipMintingSwitch() external payable onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    /**
     * @dev Sets the p5js url
     * @param _p5jsUrl The address of the p5js file hosted on CDN
     */

    function setJsAddress(string memory _p5jsUrl) external payable onlyOwner {
        p5jsUrl = _p5jsUrl;
    }

    /**
     * @dev Sets the p5js resource integrity
     * @param _p5jsIntegrity The hash of the p5js file (to protect w subresource integrity)
     */

    function setJsIntegrity(string memory _p5jsIntegrity)
        external
        payable
        onlyOwner
    {
        p5jsIntegrity = _p5jsIntegrity;
    }

    /**
     * @dev Sets the base image url
     * @param _imageUrl The base url for image field
     */

    function setImageUrl(string memory _imageUrl) external payable onlyOwner {
        imageUrl = _imageUrl;
    }

    function setAnimationUrl(string memory _animationUrl)
        external
        payable
        onlyOwner
    {
        animationUrl = _animationUrl;
    }

    function withdraw() external payable onlyOwner {
        uint256 sixty = (address(this).balance / 100) * 60;
        uint256 twentyFive = (address(this).balance / 100) * 25;
        uint256 ten = (address(this).balance / 100) * 10;
        uint256 five = (address(this).balance / 100) * 5;
        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: twentyFive}("");
        require(sentT, "Failed to send");
        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: ten}("");
        require(sentI, "Failed to send");
        (bool sentC, ) = payable(
            address(0x888f8AA938dbb18b28bdD111fa4A0D3B8e10C871)
        ).call{value: five}("");
        require(sentC, "Failed to send");
        (bool sentG, ) = payable(
            address(0xdb4782d463628cc5b1de8f1220f755BA3bA4728E)
        ).call{value: sixty}("");
        require(sentG, "Failed to send");
    }
}

pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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