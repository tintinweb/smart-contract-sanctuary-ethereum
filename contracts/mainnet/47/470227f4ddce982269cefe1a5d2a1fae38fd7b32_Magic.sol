/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/magic.sol



// @title: Magic
// @author: crazytoli
//
// Onchain Omnichain PFP collection of 10k unique profile images with the following properties:
//   - First Onchain Omnichain PFP NFT Project
//   - all metadata on chain
//   - all images on chain in svg optimized format
//   - all 10,000 OOCrazySnails are unique
//   - there are 8 traits with 125 values
//   - the traits have distribution and rarities interesting for collecting
//   - everything on chain can be used in other apps and collections in the future

pragma solidity ^0.8.15;


library Magic {

    // Background SVG
    function getBG(uint256 id) external pure returns (string memory){
        string memory p = '<path d="M0 0h1800v1800H0V0z" fill="#';
        string memory f = '" fill-rule="evenodd"/>';
        string[10] memory c = ['9adcff', 'd5a37b', 'b97a95', '716f81', 'c4d473', 'fec99a', 'f2d2fa', 'b388eb', '98f5e1', 'E7EAAF'];
        return string(abi.encodePacked(p,c[id-1],f));
    }

    // Background Info
    function infoBG(uint256 id) external pure returns (string memory){
        string memory des = '", "description": "OOCrazySnails the first Omnichain Onchain PFP NFT';
        string memory s = '", "attributes": [{"trait_type": "Background","value": "';
        string[10] memory c = ['blue', 'brown', 'cherry', 'gray', 'green', 'orange', 'pink', 'purple', 'turquoise', 'yellow'];
        return string(abi.encodePacked(des,s,c[id-1]));
    }

    // Body SVG
    function getBO(uint256 id) external pure returns (string memory){
        string memory p = '<path d="M562.5 450H450v168.75h112.5V1350h56.25v56.25H675v56.25h1012.5v-56.25h-56.25V1350H1575v-56.25h-56.25v-56.25H900V450H787.5v168.75h-225" fill="#';
        string memory f = '" fill-rule="evenodd"/>';
        string[11] memory c = ['00bbd4','15345a','33691e','000000','607d8b','4caf4f','f90','ce93d8','ff8b80','eee','ffeb3b'];
        return string(abi.encodePacked(p,c[id-1],f));
    }

    // Body Info
    function infoBO(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Body","value": "';
        string[11] memory  a = ["blue", "dark blue", "dark green", "dark", "gray", "green", "orange", "pink", "red", "white", "yellow"];
        return string(abi.encodePacked(s,a[id-1]));
    }

    // Ear SVG
    function getEar(uint256 id) external pure returns (string memory){
        string memory p = '<path d="M843.75 618.75H900V675h-56.25v-56.25z" fill="#';
        string memory f = '" fill-rule="evenodd"/>';
        string[2] memory c = ['fce50a','e0e0e0'];
        if(id == 3){
            return "";
        }
        else{
            return string(abi.encodePacked(p,c[id-1],f));
        }
    }

    // Ear Info
    function infoEar(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Ear","value": "';
        string[3] memory c = ['gold earring','silver earring','without earring'];
        return string(abi.encodePacked(s,c[id-1]));
    }

    // Mouth SVG
    function getM(uint256 id) external pure returns (string memory){
        string memory s = '';
        if(id == 2){
            s = '<g fill-rule="evenodd"><path d="M506.25 731.25h56.25v56.25h-56.25v-56.25z" fill="#fbc12d"/><path d="M337.5 731.25h168.75v56.25H337.5v-56.25z" fill="#eee"/><path d="M281.25 731.25h56.25v56.25h-56.25v-56.25z" fill="#f97e10"/><path d="M112.5 450v56.25h56.25V450H112.5zm56.25 56.25v112.5H225v-112.5h-56.25zM225 618.75V675h56.25v-56.25H225z" fill="#e9e5e3"/></g>';
        }
        if(id == 3){
            s = '<g fill-rule="evenodd"><path d="M506.25 731.25h56.25v56.25h-56.25v-56.25z" fill="#616161"/><path d="M337.5 731.25h168.75v56.25H337.5v-56.25z" fill="#78909c"/><path d="M281.25 731.25h56.25v56.25h-56.25v-56.25z" fill="#00b8d4"/><path d="M112.5 450v56.25h56.25V450H112.5zm56.25 56.25v112.5H225v-112.5h-56.25zM225 618.75V675h56.25v-56.25H225z" fill="#e7e5e4"/></g>';
        }
        return s;
    }

    // Mouth Info
    function infoM(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Mouth","value": "';
        string[3] memory c = ["nothing", "cigar", "e-cigar"];
        return string(abi.encodePacked(s,c[id-1]));
    }

    // Eyes SVG
    function getE(uint256 id) external pure returns (string memory){
        string memory s = '';
        string memory normal = '" fill-rule="evenodd"><path d="M450 337.5h112.5V450H450V337.5zM787.5 337.5H900V450H787.5V337.5z"/></g>';
        string memory gf = '<g fill="#';
        string memory gg = '"/></g>';
        string memory rare = '<g fill-rule="evenodd"><path d="M450 337.5V450h56.25v-56.25h56.25V337.5H450zM787.5 337.5V450h56.25v-56.25H900V337.5H787.5z" fill="#0a0a0a"/><path d="M506.25 393.75h56.25V450h-56.25v-56.25zM843.75 393.75H900V450h-56.25v-56.25z" fill="#';
        if(id == 1){
            s = '<g fill-rule="evenodd"><path d="M393.75 337.5v225h225v-56.25h112.5v56.25h225v-56.25h56.25V450h-56.25V337.5h-225V450h-112.5V337.5h-225zm618.75 168.75v56.25h56.25v-56.25h-56.25z" fill="#fafafa"/><path d="M450 393.75h112.5v112.5H450v-112.5z" fill="#536cfe"/><path d="M787.5 393.75H900v112.5H787.5v-112.5z" fill="#ff1745"/></g>';
        }
        if(id == 2){
            s = '<g fill-rule="evenodd"><path d="M450 337.5h112.5v56.25H450V337.5z"/><path d="M506.25 393.75h56.25V450h-56.25v-56.25z" fill="#78909c"/><path d="M450 393.75h56.25V450H450v-56.25z" fill="#3e2723"/><path d="M787.5 337.5H900v56.25H787.5V337.5z"/><path d="M843.75 393.75H900V450h-56.25v-56.25z" fill="#78909c"/><path d="M787.5 393.75h56.25V450H787.5v-56.25z" fill="#3e2723"/></g>';
        }
        if(id == 3){
            s = '<g fill-rule="evenodd"><path d="M450 337.5h112.5v56.25H450V337.5z" fill="#43a048"/><path d="M506.25 393.75h56.25V450h-56.25v-56.25z" fill="#f1f8e9"/><path d="M450 393.75h56.25V450H450v-56.25z" fill="#3f51b5"/><path d="M787.5 337.5H900v56.25H787.5V337.5z" fill="#43a048"/><path d="M843.75 393.75H900V450h-56.25v-56.25z" fill="#f1f8e9"/><path d="M787.5 393.75h56.25V450H787.5v-56.25z" fill="#4caf4f"/></g>';
        }
        if(id == 4){
            s = '<g fill-rule="evenodd"><path d="M450 337.5h112.5v56.25H450V337.5z" fill="#7b1fa2"/><path d="M506.25 393.75h56.25V450h-56.25v-56.25z"/><path d="M450 393.75h56.25V450H450v-56.25z" fill="#d50000"/><path d="M787.5 337.5H900v56.25H787.5V337.5z" fill="#7b1fa2"/><path d="M843.75 393.75H900V450h-56.25v-56.25z"/><path d="M787.5 393.75h56.25V450H787.5v-56.25z" fill="#b488ff"/></g>';
        }
        if(id == 5){
            s = '<g fill-rule="evenodd"><path d="M393.75 281.25h225v56.25h-225v-56.25zM731.25 281.25h225v56.25h-225v-56.25z" fill="#212121"/><path d="M393.75 337.5h225v168.75h-225V337.5zM731.25 337.5h225v168.75h-225V337.5z" fill="#424242"/><path d="M618.75 393.75h112.5V450h-112.5v-56.25zM956.25 393.75V450h56.25v-56.25h-56.25zM1012.5 450v56.25h56.25V450h-56.25z" fill="#212121"/></g>';
        }
        if(id == 6){
            s = '<g fill-rule="evenodd"><path d="M393.75 337.5h562.5v168.75h-562.5V337.5z" fill="#e6e5e5"/><path d="M450 393.75h337.5V450H450v-56.25z" fill="#29b5f6"/><path d="M787.5 393.75h56.25V450H787.5v-56.25z" fill="#039ae5"/><path d="M843.75 393.75H900V450h-56.25v-56.25z" fill="#0288d1"/></g>';
        }
        if(id == 7){
            s = '<g fill-rule="evenodd"><path d="M393.75 337.5h562.5v168.75h-562.5V337.5z" fill="#e6e5e5"/><path d="M450 393.75h337.5V450H450v-56.25z" fill="#d84315"/><path d="M787.5 393.75h56.25V450H787.5v-56.25z" fill="#972f0f"/><path d="M843.75 393.75H900V450h-56.25v-56.25z" fill="#69220a"/></g>';
        }
        if(id == 8){
            s = '<g fill-rule="evenodd"><path d="M450 337.5h56.25V450H450V337.5zM787.5 337.5h56.25V450H787.5V337.5z" fill="#00bbd4"/><path d="M506.25 337.5h56.25V450h-56.25V337.5zM843.75 337.5H900V450h-56.25V337.5z" fill="#3f51b5"/></g>';
        }
        if(id == 9){
            s = string(abi.encodePacked(gf,'2127b2',normal));
        }
        if(id == 10){
            s = string(abi.encodePacked(gf,'000000',normal));
        }
        if(id == 11){
            s = string(abi.encodePacked(gf,'21b242',normal));
        }
        if(id == 12){
            s = string(abi.encodePacked(gf,'f88f06',normal));
        }
        if(id == 13){
            s = string(abi.encodePacked(gf,'f806f1',normal));
        }
        if(id == 14){
            s = string(abi.encodePacked(gf,'9006f8',normal));
        }
        if(id == 15){
            s = string(abi.encodePacked(gf,'fe2f2f',normal));
        }
        if(id == 16){
            s = string(abi.encodePacked(gf,'fef52f',normal));
        }
        if(id == 17){
            s = '<g fill-rule="evenodd"><path d="M393.75 281.25h225v56.25h-225v-56.25zM731.25 281.25h225v56.25h-225v-56.25z" fill="#4a148c"/><path d="M393.75 337.5h225v168.75h-225V337.5zM731.25 337.5h225v168.75h-225V337.5z" fill="#7b1fa2"/><path d="M618.75 393.75h112.5V450h-112.5v-56.25zM956.25 393.75V450h56.25v-56.25h-56.25zM1012.5 450v56.25h56.25V450h-56.25z" fill="#4a148c"/></g>';
        }
        if(id == 18){
            s = '<g fill-rule="evenodd"><path d="M393.75 281.25h225v56.25h-225v-56.25z" fill="#4a148c"/><path d="M393.75 337.5H450v168.75h-56.25V337.5z" fill="#ffa200"/><path d="M450 337.5h56.25v168.75H450V337.5z" fill="#ff0"/><path d="M506.25 337.5h56.25v168.75h-56.25V337.5z" fill="#63dd17"/><path d="M562.5 337.5h56.25v168.75H562.5V337.5z" fill="#29b5f6"/><path d="M787.5 337.5V450h56.25v-56.25H900V337.5H787.5z" fill="#0a0a0a"/><path d="M843.75 393.75H900V450h-56.25v-56.25z" fill="#fff"/><path d="M731.25 281.25h225v56.25h-225v-56.25z" fill="#4a148c"/><path d="M731.25 337.5h56.25v168.75h-56.25V337.5z" fill="#ffa200"/><path d="M787.5 337.5h56.25v168.75H787.5V337.5z" fill="#ff0"/><path d="M843.75 337.5H900v168.75h-56.25V337.5z" fill="#63dd17"/><path d="M900 337.5h56.25v168.75H900V337.5z" fill="#29b5f6"/><path d="M618.75 393.75h112.5V450h-112.5v-56.25zM956.25 393.75V450h56.25v-56.25h-56.25zM1012.5 450v56.25h56.25V450h-56.25z" fill="#522da8"/></g>';
        }
        if(id == 19){
            s = string(abi.encodePacked(rare,'4c7de6',gg));
        }
        if(id == 20){
            s = string(abi.encodePacked(rare,'afe67c',gg));
        }
        if(id == 21){
            s = string(abi.encodePacked(rare,'e67cd8',gg));
        }
        if(id == 22){
            s = string(abi.encodePacked(rare,'be52f9',gg));
        }
        if(id == 23){
            s = string(abi.encodePacked(rare,'f50000',gg));
        }
        if(id == 24){
            s = string(abi.encodePacked(rare,'fff',gg));
        }
        if(id == 25){
            s = string(abi.encodePacked(rare,'e6df4c',gg));
        }
        return s;
    }

    // Eyes Info
    function infoE(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Eyes","value": "';
        string[25] memory c = ['3d','crazy dark','crazy green','crazy purple','dark glasses','laser blue','laser red','mega crazy','blue','dark','green','orange','pink','purple','red','yellow','purple glasses','rainbow','rare blue','rare green','rare pink','rare purple','rare red','rare white','rare yellow'];
        return string(abi.encodePacked(s,c[id-1]));
    }

    //Clothes SVG
    function getC(uint256 id) external pure returns (string memory){
        string memory s = '';
        if(id == 1){
            s = '<g fill-rule="evenodd"><path d="M562.5 900v450h56.25v56.25H675v56.25h562.5v-225H900V900H562.5z" fill="#2b2c2c"/><path d="M562.5 843.75H675V900H562.5v-56.25zM731.25 843.75H900V900H731.25v-56.25z" fill="#f1f7f8"/><path d="M675 843.75h56.25V900H675v-56.25z" fill="#38aa73"/><path d="M675 900h56.25v281.25H675V900z" fill="#37c14d"/><path d="M787.5 1012.5H900v56.25H787.5v-56.25z" fill="#3d3d3d"/><path d="M562.5 1237.5H900v56.25H562.5v-56.25z" fill="#1d1d1d"/><path d="M675 1237.5h112.5v56.25H675v-56.25z" fill="#505050"/></g>';
        }
        if(id == 2){
            s = '<g fill-rule="evenodd"><path d="M562.5 900v450h56.25v56.25H675v56.25h562.5v-225H900V900H562.5z" fill="#2b2c2c"/><path d="M562.5 843.75H675V900H562.5v-56.25zM731.25 843.75H900V900H731.25v-56.25z" fill="#f1f7f8"/><path d="M675 843.75h56.25V900H675v-56.25z" fill="#9738aa"/><path d="M675 900h56.25v281.25H675V900z" fill="#b737c1"/><path d="M787.5 1012.5H900v56.25H787.5v-56.25z" fill="#3d3d3d"/><path d="M562.5 1237.5H900v56.25H562.5v-56.25z" fill="#1d1d1d"/><path d="M675 1237.5h112.5v56.25H675v-56.25z" fill="#505050"/></g>';
        }
        if(id == 3){
            s = '<g fill-rule="evenodd"><path d="M562.5 900v450h56.25v56.25H675v56.25h562.5v-225H900V900H562.5z" fill="#2b2c2c"/><path d="M562.5 843.75H675V900H562.5v-56.25zM731.25 843.75H900V900H731.25v-56.25z" fill="#f1f7f8"/><path d="M675 843.75h56.25V900H675v-56.25z" fill="#aa384d"/><path d="M675 900h56.25v281.25H675V900z" fill="#c13737"/><path d="M787.5 1012.5H900v56.25H787.5v-56.25z" fill="#3d3d3d"/><path d="M562.5 1237.5H900v56.25H562.5v-56.25z" fill="#1d1d1d"/><path d="M675 1237.5h112.5v56.25H675v-56.25z" fill="#505050"/></g>';
        }
        if(id == 4){
            s = '<g fill-rule="evenodd"><path d="M562.5 900v450h56.25v56.25H675v56.25h562.5v-225H900V900H562.5z" fill="#2b2c2c"/><path d="M562.5 843.75H675V900H562.5v-56.25zM731.25 843.75H900V900H731.25v-56.25z" fill="#f1f7f8"/><path d="M675 843.75h56.25V900H675v-56.25z" fill="#389caa"/><path d="M675 900h56.25v281.25H675V900z" fill="#37b0c1"/><path d="M787.5 1012.5H900v56.25H787.5v-56.25z" fill="#3d3d3d"/><path d="M562.5 1237.5H900v56.25H562.5v-56.25z" fill="#1d1d1d"/><path d="M675 1237.5h112.5v56.25H675v-56.25z" fill="#505050"/></g>';
        }
        if(id == 5){
            s = '<path d="M562.5 843.75V900h56.25v-56.25H562.5zM618.75 900v56.25H675V900h-56.25zM675 956.25v56.25h112.5v-56.25H675zm112.5 0h56.25V900H787.5v56.25zM843.75 900H900v-56.25h-56.25V900z" fill="#ffc300" fill-rule="evenodd"/>';
        }
        if(id == 6){
            s = '<g fill-rule="evenodd"><path d="M562.5 787.5V1350h56.25v56.25H675v56.25h1012.5v-56.25h-56.25V1350H1575v-56.25h-56.25v-56.25H900v-450H562.5z"/><path d="M787.5 900H900v56.25H787.5V900zM562.5 900h56.25v56.25H562.5V900zM787.5 1012.5H900v56.25H787.5v-56.25zM787.5 1125H900v56.25H787.5V1125zM562.5 1012.5h56.25v56.25H562.5v-56.25zM562.5 1125h56.25v56.25H562.5V1125zM675 900h56.25v393.75H675V900zM731.25 1293.75h56.25V1350h-56.25v-56.25zM843.75 1293.75h168.75V1350H843.75v-56.25zM1068.75 1293.75h112.5V1350h-112.5v-56.25zM1237.5 1293.75h168.75V1350H1237.5v-56.25z" fill="#eee"/></g>';
        }
        if(id == 7){
            s = '<g fill="#ff5252" fill-opacity=".5" fill-rule="evenodd"><path d="M450 450h112.5v56.25H450V450zM787.5 450H900v56.25H787.5V450zM618.75 787.5v56.25H562.5v112.5h56.25v56.25H675v56.25h56.25v-56.25h56.25v-56.25h56.25v-112.5H787.5V787.5h-56.25v56.25H675V787.5h-56.25zM618.75 1237.5v56.25H562.5V1350h56.25v56.25h112.5v-112.5H675v-56.25h-56.25zM900 1293.75V1350h-56.25v56.25H900v56.25h225v-56.25h-56.25V1350h-56.25v-56.25H900zM1350 1237.5v56.25h56.25V1350H1575v-56.25h-56.25v-56.25H1350z"/></g>';
        }
        if(id == 8){
            s = '<path d="M562.5 787.5V1350h56.25v56.25H675v56.25h618.75v-225H900v-450H562.5z" fill="#2b2c2c" fill-rule="evenodd"/>';
        }
        if(id == 9){
            s = '<g fill="#7b7b7b" fill-opacity=".5" fill-rule="evenodd"><path d="M450 562.5h56.25v56.25H450V562.5zM843.75 675v56.25H900V675h-56.25zm0 56.25H787.5v56.25h56.25v-56.25zM787.5 787.5h-56.25v168.75h56.25V787.5zm0 168.75v56.25h56.25v-56.25H787.5zm56.25 56.25v56.25H900v-56.25h-56.25zm0-168.75V900H900v-56.25h-56.25zM562.5 1068.75V1125h56.25v-56.25H562.5zm56.25 56.25v56.25H675V1125h-56.25zm56.25 56.25V1350h56.25v-168.75H675zm0 168.75h-56.25v56.25H675V1350zm-112.5-112.5v56.25h56.25v-56.25H562.5zM956.25 1237.5v56.25h56.25v-56.25h-56.25zm56.25 56.25V1350h56.25v-56.25h-56.25zm56.25 56.25v56.25h168.75V1350h-168.75zm168.75 0h56.25v-56.25h-56.25V1350zm56.25-56.25H1350v-56.25h-56.25v56.25zM1125 1237.5v56.25h56.25v-56.25H1125z"/></g>';
        }
        if(id == 10){
            s = '<g fill="#fff" fill-opacity=".566" fill-rule="evenodd"><path d="M731.25 675h56.25v56.25h-56.25V675zM618.75 731.25H675v56.25h-56.25v-56.25zM787.5 787.5h56.25v56.25H787.5V787.5zM618.75 843.75H675V900h-56.25v-56.25zM675 956.25h56.25v56.25H675v-56.25zM787.5 1125h56.25v56.25H787.5V1125zM618.75 1181.25H675v56.25h-56.25v-56.25zM731.25 1293.75h56.25V1350h-56.25v-56.25zM900 1350h56.25v56.25H900V1350zM1012.5 1350h56.25v56.25h-56.25V1350zM1125 1293.75h56.25V1350H1125v-56.25zM1237.5 1350h56.25v56.25h-56.25V1350zM1350 1293.75h56.25V1350H1350v-56.25zM1518.75 1350H1575v56.25h-56.25V1350z"/></g>';
        }
        if(id == 11){
            s = '<g fill-opacity=".542" fill-rule="evenodd"><path d="M450 562.5h112.5v56.25H450V562.5zM787.5 562.5H900v56.25H787.5V562.5zM787.5 843.75V900h-56.25v112.5h56.25v56.25H900v-225H787.5zM562.5 1012.5v225h56.25v-56.25H675v-112.5h-56.25v-56.25H562.5zM956.25 1350v56.25H900v56.25h281.25v-56.25H1125V1350H956.25zM1293.75 1237.5v56.25H1350V1350h225v-56.25h-56.25v-56.25h-225z"/></g>';
        }
        if(id == 12){
            s = '<g fill-rule="evenodd"><path d="M562.5 900v450h56.25v56.25H675v56.25h225V900H731.25v281.25H675V900H562.5z" fill="#f11717"/><path d="M506.25 843.75V900H675v281.25H562.5v56.25H900v-56.25H731.25V900H900v-56.25H506.25z" fill="#fff"/><path d="M562.5 1237.5H900v56.25H562.5v-56.25z" fill="#0a0a0a"/><path d="M675 1237.5h56.25v56.25H675v-56.25z" fill="#fbc12d"/><path d="M900 1237.5h393.75v225H900v-225z" fill="#f11717"/><path d="M900 1237.5h56.25v225H900v-225z" fill="#fff"/></g>';
        }
        if(id == 13){
            s = '<path d="M506.25 843.75V1125h112.5v-112.5H900V843.75H506.25z" fill="#3f73de" fill-rule="evenodd"/>';
        }
        if(id == 14){
            s = '<path d="M506.25 843.75V1125h112.5v-112.5H900V843.75H506.25z" fill="#335e35" fill-rule="evenodd"/>';
        }
        if(id == 15){
            s = '<path d="M506.25 843.75V1125h112.5v-112.5H900V843.75H506.25z" fill="#49196b" fill-rule="evenodd"/>';
        }
        if(id == 16){
            s = '<path d="M562.5 843.75V900h56.25v-56.25H562.5zM618.75 900v56.25H675V900h-56.25zM675 956.25v56.25h112.5v-56.25H675zm112.5 0h56.25V900H787.5v56.25zM843.75 900H900v-56.25h-56.25V900z" fill="#dcd9d0" fill-rule="evenodd"/>';
        }
        if(id == 17){
            s = '<g fill-opacity=".542" fill-rule="evenodd"><path d="M450 450h56.25v168.75H450V450zM787.5 450h56.25v168.75H787.5V450zM843.75 731.25v56.25H900v-56.25h-56.25zm0 56.25h-112.5v56.25h112.5V787.5zM562.5 787.5h56.25v56.25H562.5V787.5zM562.5 956.25h56.25v56.25H562.5v-56.25zM843.75 900v56.25H900V900h-56.25zm0 56.25h-112.5v56.25h112.5v-56.25zM562.5 1125h56.25v56.25H562.5V1125zM843.75 1068.75V1125H900v-56.25h-56.25zm0 56.25h-112.5v56.25h112.5V1125zM562.5 1293.75H675V1350H562.5v-56.25zM900 1237.5v56.25h56.25v-56.25H900zm0 56.25H787.5V1350H900v-56.25zM1068.75 1237.5v56.25H1125v-56.25h-56.25zm0 56.25h-56.25v112.5h56.25v-112.5zM1237.5 1237.5v56.25h56.25v-56.25h-56.25zm0 56.25h-56.25v112.5h56.25v-112.5zM1406.25 1237.5v56.25h56.25v-56.25h-56.25zm0 56.25H1350v112.5h56.25v-112.5z"/></g>';
        }
        if(id == 18){
            s = '<g fill="#4caf4f" fill-rule="evenodd"><path d="M450 506.25h112.5v56.25H450v-56.25zM787.5 506.25H900v56.25H787.5v-56.25zM562.5 843.75H900v112.5H562.5v-112.5zM900 1237.5h618.75v56.25H900v-56.25zM1237.5 1293.75H1575V1350h-337.5v-56.25z"/></g>';
        }
        if(id == 19){
            s = '<g fill="#ff1f20" fill-rule="evenodd"><path d="M450 506.25h112.5v56.25H450v-56.25zM787.5 506.25H900v56.25H787.5v-56.25zM562.5 843.75H900v112.5H562.5v-112.5zM900 1237.5h618.75v56.25H900v-56.25zM1237.5 1293.75H1575V1350h-337.5v-56.25z"/></g>';
        }
        if(id == 20){
            s = '<g fill="#1fe4ff" fill-rule="evenodd"><path d="M450 506.25h112.5v56.25H450v-56.25zM787.5 506.25H900v56.25H787.5v-56.25zM562.5 843.75H900v112.5H562.5v-112.5zM900 1237.5h618.75v56.25H900v-56.25zM1237.5 1293.75H1575V1350h-337.5v-56.25z"/></g>';
        }
        if(id == 21){
            s = '<g fill-opacity=".542" fill-rule="evenodd"><path d="M618.75 787.5v56.25H562.5V900h56.25v56.25H675V900h112.5v56.25h56.25V900H900v-56.25h-56.25V787.5H787.5v56.25H675V787.5h-56.25zM1012.5 1237.5V1350h-56.25v56.25h56.25v56.25h56.25v-56.25H1125V1350h-56.25v-112.5h-56.25zM1350 1237.5V1350h-56.25v56.25H1350v56.25h56.25v-56.25h56.25V1350h-56.25v-112.5H1350z"/></g>';
        }
        return s;
    }

    // Clothes Info
    function infoC(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Clothes","value": "';
        string[22] memory a = ["elegant green", "elegant pink", "elegant red", "elegant turquoise", "golden necklace", "halloween", "hearths", "hipster", "look me", "pointed", "snake", "santa", "scarf blue", "scarf green", "scarf purple", "silver necklace", "striped", "tecno green", "tecno red", "tecno turquoise", "zombie", "naked"];
        return string(abi.encodePacked(s,a[id-1]));
    }

    function infoChain(uint256 id) external pure returns(string memory){
        string memory s = '"},{"trait_type": "Birth Network","value": "';
        string memory c;
        if(id>=1 && id<=4000){
            c = "ETH";
        }
        if(id>=4001 && id<=5300){
            c = "BNB";
        }
        if(id>=5301 && id<=7300){
            c = "Polygon";
        }
        if(id>=7301 && id<=8800){
            c = "Arbitrum";
        }
        if(id>=8801 && id<=9300){
            c = "AVAX";
        }
        if(id>=9301 && id<=9500){
            c = "FTM";
        }
        if(id>=9501 && id<=10000){
            c = "OPT";
        }
        return string(abi.encodePacked(s,c));
    }
}