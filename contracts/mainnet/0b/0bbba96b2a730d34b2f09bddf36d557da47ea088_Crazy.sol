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

// File: contracts/crazy.sol



// @title: Crazy
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


library Crazy {

    // Shell SVG
    function getS(uint256 id) external pure returns (string memory){
        string memory s = '';
        string memory f = '<g fill-rule="evenodd">';
        if(id == 1){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#5c6bc0"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#3948ab"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#303f9f"/></g>';
        }
        if(id == 2){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#263238"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#d32f2f"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#fce4ec"/></g>';
        }
        if(id == 3){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#37474f"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#455a64"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#546e7a"/></g>';
        }
        if(id == 4){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#455a64"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#cfd8dc"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#455a64"/></g>';
        }
        if(id == 5){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#33691e"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#8bc34a"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#b9f6ca"/></g>';
        }
        if(id == 6){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#424242"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#e8eaf6"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#424242"/></g>';
        }
        if(id == 7){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#f44236"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#ff5622"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#ccdc39"/></g>';
        }
        if(id == 8){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#06b2c9"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#03a8f4"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#2195f3"/></g>';
        }
        if(id == 9){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#69f0af"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#00c853"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#43a048"/></g>';
        }
        if(id == 10){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#f48fb0"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#f06291"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#ec4079"/></g>';
        }
        if(id == 11){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#ce93d8"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#ba68c8"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#7b1fa2"/></g>';
        }
        if(id == 12){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#ffff87"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#ffa200"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#e65100"/></g>';
        }
        if(id == 13){
            s = '<path d="M900 731.25v506.25h506.25V731.25H900z" fill="#f44236"/><path d="M956.25 787.5H1350v393.75H956.25V787.5z" fill="#ccdc39"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#4caf4f"/><path d="M1068.75 900h168.75v168.75h-168.75V900z" fill="#00bbd4"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#683ab7"/></g>';
        }
        if(id == 14){
            s = '<path d="M900 731.25v506.25h506.25V731.25H900z" fill="#c3291c"/><path d="M950.625 787.5h404.995v393.75H950.625V787.5z" fill="#c3291c"/><path d="M956.25 787.5H1350v393.75H956.25V787.5z" fill="#fff"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#c3291c"/><path d="M1068.75 900h168.75v168.75h-168.75V900z" fill="#fff"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z"/></g>';
        }
        if(id == 15){
            s = '<path d="M900 731.25h506.25v506.25H900V731.25z" fill="#37474f"/><path d="M1012.5 843.75h281.25V1125H1012.5V843.75z" fill="#63dd17"/><path d="M1125 956.25h56.25v56.25H1125v-56.25z" fill="#37474f"/></g>';
        }
        return string(abi.encodePacked(f,s));
    }

    // Shell Info
    function infoS(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Shell","value": "';
        string memory c = "";
        if(id == 1){
            c = "blue";
        }
        if(id == 2){
            c = "classic";
        }
        if(id == 3){
            c = "dark";
        }
        if(id == 4){
            c = "gray";
        }
        if(id == 5){
            c = "grinch";
        }
        if(id == 6){
            c = "monocrom";
        }
        if(id == 7){
            c = "red";
        }
        if(id == 8){
            c = "sweet blue";
        }
        if(id == 9){
            c = "sweet green";
        }
        if(id == 10){
            c = "sweet pink";
        }
        if(id == 11){
            c = "sweet purple";
        }
        if(id == 12){
            c = "sweet yellow";
        }
        if(id == 13){
            c = "rainbow";
        }
        if(id == 14){
            c = "target";
        }
        if(id == 15){
            c = "zumba";
        }
        return string(abi.encodePacked(s,c));
    }

    // Shell Accessory SVG
    function getSA(uint256 id) external pure returns (string memory){
        string memory s = '';
        if(id == 2){
            s = '<path d="M1125 506.25v56.25h337.5v-56.25H1125zm337.5 56.25v56.25h56.25V562.5h-56.25zm0 56.25H1125V675h337.5v-56.25zm-337.5 0V562.5h-56.25v56.25H1125z" fill="#ffcb0e" fill-rule="evenodd"/>';
        }
        if(id == 3){
            s = '<g fill-rule="evenodd"><path d="M1181.25 675V450H1125v281.25h337.5V675h56.25v-56.25h-56.25v-112.5h56.25v112.5H1575V450h-112.5v-56.25h-56.25V675h-225z" fill="#81d4fa"/><path d="M1237.5 393.75V450h-56.25v225h225V393.75H1237.5z" fill="#fdd835"/><path d="M1462.5 281.25v112.5h-225V450H1125v-56.25h56.25V337.5h56.25v-56.25h225z" fill="#fff"/><path d="M1181.25 281.25v56.25h56.25v-56.25h-56.25zm0 56.25H1125v56.25h56.25V337.5z" fill="#e3f2fd"/><path d="M1125 281.25v56.25h56.25v-56.25H1125zm0 56.25h-56.25v56.25H1125V337.5z" fill="#e8eaf6"/><path d="M1181.25 506.25h56.25V675h-56.25V506.25zM1293.75 506.25H1350V675h-56.25V506.25z" fill="#fbc12d"/><path d="M1181.25 675h56.25v56.25h-56.25V675zM1293.75 675H1350v56.25h-56.25V675z" fill="#4fc2f7"/></g>';
        }
        if(id == 4){
            s = '<g fill-rule="evenodd"><path d="M1012.5 618.75V675h56.25v56.25h393.75V675h-281.25v-56.25H1012.5z" fill="#596987"/><path d="M1181.25 618.75h337.5V675h-337.5v-56.25z" fill="#78909c"/><path d="M1068.75 337.5h112.5v281.25h-112.5V337.5z" fill="#e7b795"/><path d="M1181.25 337.5h281.25v281.25h-281.25V337.5z" fill="#e9d4aa"/><path d="M1237.5 281.25h56.25v56.25h-56.25v-56.25z" fill="#ff6f00"/><path d="M1237.5 168.75h56.25v112.5h-56.25v-112.5z" fill="#ff0"/><path d="M1181.25 225h56.25v56.25h-56.25V225z" fill="#ffac40"/><path d="M1293.75 168.75H1350v112.5h-56.25v-112.5z" fill="#ff9100"/><path d="M1237.5 112.5v56.25H1350V112.5h-112.5zm0 56.25h-56.25V225h56.25v-56.25z" fill="#ff6f00"/></g>';
        }
        if(id == 5){
            s = '<g fill-rule="evenodd"><path d="M956.25 450v281.25h506.25V450h-56.25v56.25H1350v56.25h-56.25v-56.25h-56.25V450h-56.25v56.25H1125v56.25h-56.25v-56.25h-56.25V450h-56.25z" fill="#ffc107"/><path d="M956.25 618.75h56.25V675h-56.25v-56.25zM1406.25 618.75h56.25V675h-56.25v-56.25z" fill="#ff5252"/><path d="M1012.5 618.75h56.25V675h-56.25v-56.25z" fill="#ffd64f"/><path d="M1350 618.75h56.25V675H1350v-56.25z" fill="#f5ef3d"/><path d="M1068.75 618.75H1125V675h-56.25v-56.25zM1293.75 618.75H1350V675h-56.25v-56.25z" fill="#4caf4f"/><path d="M1181.25 618.75h56.25V675h-56.25v-56.25z" fill="#03a8f4"/></g>';
        }
        if(id == 6){
            s = '<g fill-rule="evenodd"><path d="M1012.5 675v56.25h393.75V675H1350V393.75h-281.25V675h-56.25z" fill="#212121"/><path d="M1068.75 618.75H1350V675h-281.25v-56.25z" fill="#424242"/></g>';
        }
        if(id == 7){
            s = '<g fill-rule="evenodd"><path d="M1125 731.25V675h-56.25V562.5H1125v56.25h56.25V675h56.25v-56.25h225V562.5h56.25V675h-56.25v56.25H1125z" fill="#fb761e"/><path d="M1068.75 337.5v225H1125v56.25h56.25V675h56.25v-56.25h225V562.5h56.25v-225h-56.25v-56.25H1125v56.25h-56.25z" fill="#442632"/><path d="M1237.5 393.75H1350v112.5h-112.5v-112.5z" fill="#b54e2f"/></g>';
        }
        if(id == 8){
            s = '<g fill-rule="evenodd"><path d="M1181.25 450v168.75h56.25v112.5h225V675h56.25V562.5H1350V450h-168.75z" fill="#ffeb3b"/><path d="M1237.5 506.25h56.25v56.25h-56.25v-56.25z"/><path d="M1125 506.25h56.25v56.25H1125v-56.25z" fill="#f44236"/></g>';
        }
        if(id == 9){
            s = '<g fill-rule="evenodd"><path d="M1125 618.75V675H956.25v56.25h562.5v56.25H1575V675h-56.25v-56.25H1125z" fill="#ffebee"/><path d="M1237.5 506.25v56.25h-56.25v56.25h281.25V562.5h-56.25v-56.25H1237.5z" fill="#ffc107"/></g>';
        }
        if(id == 10){
            s = '<g fill-rule="evenodd"><path d="M956.25 618.75v112.5h112.5v1H1125V676h-56.25v-57.25h-112.5z" fill="#ff5622"/><path d="M1125 450h168.75v281.25H1125V450z" fill="#ffccbc"/><path d="M1293.75 618.75h112.5v112.5h-112.5v-112.5z" fill="#efebe9"/><path d="M1293.75 450v56.25h-56.25v56.25h-56.25v56.25h337.5V562.5h-56.25v-56.25h-56.25V450h-112.5z" fill="#ff6d40"/><path d="M1237.5 562.5h56.25v56.25h-56.25V562.5zM1350 506.25h56.25v56.25H1350v-56.25z" fill="#ff8965"/><path d="M1125 225v56.25h-56.25v56.25h-56.25v56.25h-56.25V450h562.5v-56.25h-56.25V337.5h-56.25v-56.25H1350V225h-225z" fill="#dd2c00"/><path d="M1068.75 393.75H1125V450h-56.25v-56.25zM1181.25 281.25h56.25v56.25h-56.25v-56.25zM1293.75 337.5H1350v56.25h-56.25V337.5z" fill="#e53835"/></g>';
        }
        if(id == 11){
            s = '<g fill-rule="evenodd"><path d="M1012.5 675v56.25h393.75V675H1350V393.75h-281.25V675h-56.25z" fill="#ffca41"/><path d="M1068.75 618.75H1350V675h-281.25v-56.25z" fill="#f0ac00"/></g>';
        }
        if(id == 12){
            s = '<g fill-rule="evenodd"><path d="M1181.25 225v56.25H1125v56.25h-56.25V675h393.75V337.5h-56.25v-56.25H1350V225h-168.75z" fill="#bdbdbd"/><path d="M1293.75 562.5H1350v56.25h-56.25V562.5zM1125 562.5h112.5v56.25H1125V562.5zM1125 450h225v56.25h-225V450zM1181.25 337.5h112.5v56.25h-112.5V337.5z" fill="#9e9e9e"/><path d="M1125 229v52.25h-56.25v56.25H1125v-52.25h56.25V229H1125zm-56.25 108.5h-56.25v393.75h450V675h-393.75V337.5z" fill="#9e9e9e"/></g>';
        }
        if(id == 13){
            s = '<g fill-rule="evenodd"><path d="M1012.5 675v56.25h393.75V675H1350V393.75h-281.25V675h-56.25z" fill="#212121"/><path d="M1068.75 618.75H1350V675h-281.25v-56.25z" fill="#eee"/></g>';
        }
        if(id == 14){
            s = '<g fill-rule="evenodd"><path d="M1068.75 675h450v56.25h-450V675z" fill="#e3a579"/><path d="M1068.75 618.75H1125V675h-56.25v-56.25zM1462.5 618.75h56.25V675h-56.25v-56.25z" fill="#bc675e"/><path d="M1125 618.75h337.5V675H1125v-56.25z" fill="#7b3945"/><path d="M1068.75 562.5H1125v56.25h-56.25V562.5z" fill="#fa313b"/><path d="M1125 562.5h168.75v56.25H1125V562.5zM1462.5 562.5h56.25v56.25h-56.25V562.5z" fill="#348b3d"/><path d="M1293.75 562.5h168.75v56.25h-168.75V562.5z" fill="#ffac26"/><path d="M1462.5 450v56.25h-393.75v56.25h450V450h-56.25z" fill="#f1d5a2"/><path d="M1068.75 337.5v168.75h393.75V450h56.25V337.5h-56.25v-56.25H1125v56.25" fill="#e3a579"/><path d="M1350 281.25h56.25v56.25H1350v-56.25zM1181.25 337.5h56.25v56.25h-56.25V337.5zM1293.75 393.75H1350V450h-56.25v-56.25z" fill="#f1d5a2"/></g>';
        }
        if(id == 15){
            s = '<g fill-rule="evenodd"><path d="M1068.75 450v225h-56.25v56.25h506.25V675h-56.25V562.5h-56.25v-56.25h-112.5V450h-225z" fill="#63dd17"/><path d="M1068.75 562.5H1125V675h-56.25V562.5z" fill="#ffea00"/><path d="M1125 618.75h337.5V675H1125v-56.25z" fill="#424242"/></g>';
        }
        if(id == 16){
            s = '<g fill-rule="evenodd"><path d="M1068.75 618.75v112.5h112.5v-112.5h56.25V562.5H1125v56.25h-56.25z" fill="#d50000"/><path d="M1237.5 562.5v56.25h-56.25v112.5h112.5V562.5h-56.25z" fill="#ffeb3b"/><path d="M1125 450v56.25h112.5V450H1125zm112.5 56.25v56.25h56.25v-56.25h-56.25zm56.25 0h112.5V450h-112.5v56.25zm0 56.25v168.75h168.75v-112.5h-56.25V562.5h-112.5z" fill="#3f51b5"/></g>';
        }
        if(id == 17){
            s = '<g fill-rule="evenodd"><path d="M1068.75 731.25V675h-56.25V506.25h56.25V450H1125V337.5h56.25v-56.25h112.5v56.25H1350V450h56.25v56.25h56.25V675h-56.25v56.25h-337.5z" fill="#004d40"/><path d="M1125 450h56.25v112.5H1125V450zM1293.75 450H1350v112.5h-56.25V450z" fill="#18ffff"/></g>';
        }
        if(id == 18){
            s = '<g fill-rule="evenodd"><path d="M1125 337.5V450h56.25v112.5H1125v56.25h112.5v112.5h168.75v-112.5H1350V450h-112.5V337.5H1125zM1350 450h112.5V337.5H1350V450z" fill="#cfd8dc"/><path d="M1518.75 618.75V675H1575v-56.25h-56.25zm0 56.25h-112.5v56.25h112.5V675z" fill="#b0bec5"/><path d="M1125 506.25h56.25v56.25H1125v-56.25zM1237.5 506.25h56.25v56.25h-56.25v-56.25z" fill="#263238"/><path d="M1181.25 393.75h56.25V450h-56.25v-56.25zM1350 393.75h56.25V450H1350v-56.25z" fill="#ffab91"/></g>';
        }
        if(id == 19){
            s = '<g fill-rule="evenodd"><path d="M1125 281.25v56.25h225v-56.25h-225zm225 56.25v56.25h56.25V337.5H1350zm56.25 56.25v225h56.25v-225h-56.25zm0 225H1350V675h56.25v-56.25zM1350 675h-225v56.25h225V675zm-225 0v-56.25h-56.25V675H1125zm-56.25-56.25v-225h-56.25v225h56.25zm0-225H1125V337.5h-56.25v56.25z" fill="#00838f"/><path d="M1125 337.5v56.25h-56.25v225H1125V675h225v-56.25h56.25v-225H1350V337.5h-225z" fill="#006164"/><path d="M1125 393.75v112.5h56.25V450h56.25v-56.25H1125zM1237.5 506.25v56.25h56.25v-56.25h-56.25z" fill="#18ffff"/></g>';
        }
        if(id == 20){
            s = '<g fill-rule="evenodd"><path d="M956.25 618.75v112.5H1575v-112.5h-112.5v-112.5h-56.25V450H1125v56.25h-56.25v112.5h-112.5z"/><path d="M1181.25 506.25v56.25h56.25v56.25h56.25V562.5H1350v-56.25h-168.75zm112.5 112.5V675H1350v-56.25h-56.25zm-56.25 0h-56.25V675h56.25v-56.25z" fill="#fff"/><path d="M1125 393.75V450h112.5v-56.25H1125zm0 56.25h-56.25v56.25H1125V450zm-56.25 56.25h-56.25v112.5h56.25v-112.5zm225-112.5V450h112.5v-56.25h-112.5zm112.5 56.25v56.25h56.25V450h-56.25zm56.25 56.25v112.5h56.25v-112.5h-56.25z" fill="#ffd640"/></g>';
        }
        if(id == 21){
            s = '<g fill-rule="evenodd"><path d="M1125 450h337.5v281.25H1125V450z" fill="#ef8183"/><path d="M1068.75 393.75V450h112.5v281.25h56.25V450h56.25v281.25H1350V450h56.25v281.25h56.25V450h56.25v-56.25h-450z" fill="#f0f3f5"/><path d="M1181.25 225v56.25H1125v56.25h-56.25v56.25h450V337.5h-56.25v-56.25h-56.25V225h-225z" fill="#eed1a5"/><path d="M1181.25 225v56.25H1125v56.25h-56.25v56.25h112.5V337.5h56.25V225h-56.25zm56.25 112.5v56.25h56.25V337.5h-56.25zm56.25 0H1350v-56.25h-56.25v56.25z" fill="#e7b898"/></g>';
        }
        if(id == 22){
            s = '<g fill-rule="evenodd"><path d="M1012.5 675v56.25h393.75V675H1350V393.75h-281.25V675h-56.25z" fill="#212121"/><path d="M1068.75 618.75H1350V675h-281.25v-56.25z" fill="#dd2c00"/></g>';
        }
        if(id == 23){
            s = '<g fill-rule="evenodd"><path d="M1068.75 675h450v56.25h-450V675z" fill="#fff"/><path d="M1125 675v-56.25h56.25v-112.5h56.25V450H1350v-56.25h56.25V337.5H1575v56.25h-56.25v112.5h-56.25V675H1125z" fill="#f11717"/><path d="M1575 337.5h56.25v56.25H1575V337.5z" fill="#fff"/></g>';
        }
        if(id == 24){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#3f51b5" fill-rule="evenodd"/>';
        }
        if(id == 25){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#ad1456" fill-rule="evenodd"/>';
        }
        if(id == 26){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#546e7a" fill-rule="evenodd"/>';
        }
        if(id == 27){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#004d40" fill-rule="evenodd"/>';
        }
        if(id == 28){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#ff6f00" fill-rule="evenodd"/>';
        }
        if(id == 29){
            s = '<path d="M1125 731.25V562.5h56.25v-56.25H1350v56.25h56.25v56.25h56.25V675H1575v56.25h-450z" fill="#9c27b0" fill-rule="evenodd"/>';
        }
        if(id == 30){
            s = '<g fill-rule="evenodd"><path d="M1068.75 450v225H1125v56.25h337.5V675h56.25V450h-56.25v56.25H1125V450h-56.25z" fill="#1f2d4a"/><path d="M1125 281.25v56.25h-56.25V450H1125v56.25h337.5V450h56.25V337.5h-56.25v-56.25H1125z" fill="#e6daaa"/><path d="M1181.25 337.5h225V450h-225V337.5z" fill="#ff6f76"/></g>';
        }
        if(id == 31){
            s = '<g fill-rule="evenodd"><path d="M1125 675h337.5v56.25H1125V675z" fill="#9e9e9e"/><path d="M1181.25 506.25v112.5H1125V675h337.5v-56.25h-56.25v-112.5h-225z" fill="#795548"/><path d="M1068.75 506.25v112.5h112.5V562.5H1125v-56.25h-56.25zM1462.5 507.25v55.25h-56.25v56.25h112.5v-111.5h-56.25z" fill="#e1f5fe"/></g>';
        }
        if(id == 32){
            s = '<g fill-rule="evenodd"><path d="M956.25 675v56.25h675V675H1462.5V506.25h56.25V450H1575V337.5h-56.25v56.25H1350V450h-112.5v56.25h-56.25v56.25H1125v56.25h-56.25V675h-112.5z" fill="#283493"/><path d="M1068.75 618.75h450V675h-450v-56.25z" fill="#1a237e"/><path d="M1237.5 618.75h56.25V675h-56.25v-56.25z" fill="#ccdc39"/></g>';
        }
        if(id == 33){
            s = '<g fill-rule="evenodd"><path d="M956.25 675v56.25h675V675H1462.5V506.25h56.25V450H1575V337.5h-56.25v56.25H1350V450h-112.5v56.25h-56.25v56.25H1125v56.25h-56.25V675h-112.5z" fill="#616161"/><path d="M1068.75 618.75h450V675h-450v-56.25z" fill="#424242"/><path d="M1237.5 618.75h56.25V675h-56.25v-56.25z" fill="#ccdc39"/></g>';
        }
        if(id == 34){
            s = '<g fill-rule="evenodd"><path d="M956.25 675v56.25h675V675H1462.5V506.25h56.25V450H1575V337.5h-56.25v56.25H1350V450h-112.5v56.25h-56.25v56.25H1125v56.25h-56.25V675h-112.5z" fill="#aa47bc"/><path d="M1068.75 618.75h450V675h-450v-56.25z" fill="#7b1fa2"/><path d="M1237.5 618.75h56.25V675h-56.25v-56.25z" fill="#ccdc39"/></g>';
        }
        if(id == 35){
            s = '<g fill-rule="evenodd"><path d="M1012.5 675v56.25h393.75V675H1350V393.75h-281.25V675h-56.25z" fill="#212121"/><path d="M1068.75 618.75H1350V675h-281.25v-56.25z" fill="#ffeb3b"/></g>';
        }
        if(id == 36){
            s = '<g fill-rule="evenodd"><path d="M1125 675h56.25v56.25H1125V675zM1350 675h56.25v56.25H1350V675zM1406.25 562.5h56.25v56.25h-56.25V562.5zM1012.5 562.5h56.25v56.25h-56.25V562.5z" fill="#ffe0b2"/><path d="M1125 618.75h281.25V675H1125v-56.25z" fill="#0d48a0"/><path d="M1125 506.25h281.25v112.5H1125v-112.5z" fill="#2098f3"/><path d="M1181.25 393.75h225v112.5h-225v-112.5z" fill="#ffe0b2"/><path d="M1125 281.25v225h56.25v-112.5h225v-110.5H1350v54.25h-168.75v-56.25H1125z" fill="#fff"/><path d="M1350 393.75h56.25V450H1350v-56.25zM1181.25 393.75h56.25V450h-56.25v-56.25z"/><path d="M1068.75 450H1125v56.25h-56.25V450z" fill="#7cb342"/><path d="M1012.5 450h56.25v56.25h-56.25V450z" fill="#8ac24a"/><path d="M1068.75 506.25H1125v56.25h-56.25v-56.25z" fill="#add580"/><path d="M1012.5 506.25v56.25h56.25v-56.25h-56.25zm56.25 57.25v56.25H1125V563.5h-56.25z" fill="#1a5e20"/></g>';
        }
        
        return s;
    }

    // Shell Accessory Info
    function infoSA(uint256 id) external pure returns (string memory){
        string memory s = '"},{"trait_type": "Accesory","value": "';
        string memory c = "";
        if(id == 1){
            c = "nothing";
        }
        if(id == 2){
            c = "aureole";
        }
        if(id == 3){
            c = "beer";
        }
        if(id == 4){
            c = "candle";
        }
        if(id == 5){
            c = "crown";
        }
        if(id == 6){
            c = "dark elegant";
        }
        if(id == 7){
            c = "donut";
        }
        if(id == 8){
            c = "ducky";
        }
        if(id == 9){
            c = "egg";
        }
        if(id == 10){
            c = "fungus";
        }
        if(id == 11){
            c = "golden elegant";
        }
        if(id == 12){
            c = "grave";
        }
        if(id == 13){
            c = "gray elegant";
        }
        if(id == 14){
            c = "hamburguer";
        }
        if(id == 15){
            c = "irish";
        }
        if(id == 16){
            c = "kid";
        }
        if(id == 17){
            c = "mob";
        }
        if(id == 18){
            c = "mouse";
        }
        if(id == 19){
            c = "orb";
        }
        if(id == 20){
            c = "pirate";
        }
        if(id == 21){
            c = "popcorn";
        }
        if(id == 22){
            c = "red elegant";
        }
        if(id == 23){
            c = "santa";
        }
        if(id == 24){
            c = "blue";
        }
        if(id == 25){
            c = "cherry";
        }
        if(id == 26){
            c = "gray";
        }
        if(id == 27){
            c = "green";
        }
        if(id == 28){
            c = "orange";
        }
        if(id == 29){
            c = "purple";
        }
        if(id == 30){
            c = "sushi";
        }
        if(id == 31){
            c = "viking";
        }
        if(id == 32){
            c = "witch blue";
        }
        if(id == 33){
            c = "witch gray";
        }
        if(id == 34){
            c = "witch purple";
        }
        if(id == 35){
            c = "yellow elegant";
        }
        if(id == 36){
            c = "adventure";
        }
        return string(abi.encodePacked(s,c));
    }
}