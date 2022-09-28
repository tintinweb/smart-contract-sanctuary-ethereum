// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/math/SafeMath.sol";
import "@openzeppelin/[email protected]/math/Math.sol";
import "@openzeppelin/[email protected]/utils/Arrays.sol";
import "@openzeppelin/[email protected]/utils/ReentrancyGuard.sol";
import "./CryptopunksData.sol";
import "./BleachBackground.sol";

contract Sample01 is ERC721, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1000;

    uint256 private price = 1; // 1 Wei

    address public renderingContractAddress;
    address public backgroundContractAddress;

    constructor() ERC721("Sample01", "s01") Ownable() {}

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function setBackgroundContractAddress(address _backgroundContractAddress) public onlyOwner {
        backgroundContractAddress = _backgroundContractAddress;
    }

    // Mint functionality

    function mint(uint256 _count) public payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Random function

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Random punk

    function randomPunk(uint256 tokenId) public view returns (uint16) {
        uint256 v = uint(keccak256(abi.encodePacked("a0867ed705a0", block.timestamp, block.difficulty, toString(tokenId)))) % 10000;
        uint16 original = uint16(v);
        return original;
    }

    // Background color

    function backgroundColor(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["1", "6", "3", "9", "c", "4", "b", "d", "e", "8", "5", "0", "a", "f", "2", "7", "b", "7", "5", "1", "8", "d", "2", "a", "6", "c", "4", "f", "9", "0", "e", "3"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f09ceaa019e6", block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory m = r[16];
      string memory f = "f";
      string memory o = "0";
      string memory j;

      if (keccak256(bytes(m)) == keccak256(bytes(f))) {
          j = "ffffff";
      } else if (keccak256(bytes(m)) == keccak256(bytes(o))) {
          j = "000000";
      } else {
          j = string(abi.encodePacked(r[5],r[11],r[7],r[4],r[10],r[15]));
      }

      return j;

    }

    // Make Attributes

    function makeAttributes(uint256 tokenId) private view returns (string memory) {

        string[2] memory traits;
        string memory originalPunk = toString(randomPunk(tokenId));

        traits[0] = string(abi.encodePacked('{"trait_type":"Background Color: #","value":"', backgroundColor(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Original Punk: #","value":"', originalPunk, '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1]));

        return attributes;
    }

    function replaceValue(string memory svg,uint256 position, string memory replace) internal pure returns (string memory) {
        string memory t = _stringReplace(svg,position,replace);
        return t;
    }

    function getBleach(uint256 tokenId) public view returns (string memory) {

        BleachBackground bleachBackground = BleachBackground(backgroundContractAddress);

        uint16 t = uint16(tokenId);

        string memory b = bleachBackground.getBleach(t);
        return b;
    }


    function getPlain(uint256 tokenId) public view returns (string memory) {

        CryptopunksData cryptopunksData = CryptopunksData(renderingContractAddress); // Running

        uint16 t = randomPunk(tokenId);

        string memory punkSvg = cryptopunksData.punkImageSvg(t); // Running

        // Add replacement values
        string[24] memory r = ["<","s","v","g",">","<","r","e","c","t",">","<","/","r","e","c","t",">","<","/","s","v","g",">"];

        string memory a = replaceValue(punkSvg,0,r[0]);
        a = replaceValue(a,1,r[1]);
        a = replaceValue(a,2,r[2]);
        a = replaceValue(a,3,r[3]);
        a = replaceValue(a,4,r[4]);
        a = replaceValue(a,5,r[5]);
        a = replaceValue(a,6,r[6]);
        a = replaceValue(a,7,r[7]);
        a = replaceValue(a,8,r[8]);
        a = replaceValue(a,9,r[9]);
        a = replaceValue(a,10,r[10]);
        a = replaceValue(a,11,r[11]);
        a = replaceValue(a,12,r[12]);
        a = replaceValue(a,13,r[13]);
        a = replaceValue(a,14,r[14]);
        a = replaceValue(a,15,r[15]);
        a = replaceValue(a,16,r[16]);
        a = replaceValue(a,17,r[17]);
        a = replaceValue(a,18,r[18]);
        a = replaceValue(a,19,r[19]);
        a = replaceValue(a,20,r[20]);
        a = replaceValue(a,21,r[21]);
        a = replaceValue(a,22,r[22]);
        a = replaceValue(a,23,r[23]);

        return a;

    }

    function getDescription(uint256 tokenId) public view returns (string memory) {

        string memory description;
        string memory a = "We create and perceive our world simultaneously. And our mind does this so well that we don't even know that it's happening.";
        string memory b = "You create the world of the dream. We bring the subject into that dream and they fill it with their subconcious.";
        string memory c = "Well, dreams they feel real while we're in them, right? It's only when we wake up that we realize something was actually strange?";
        string memory d = "You never really remember the beginning of a dream, do you? You always wind up right in the middle of what's going on.";

        uint256 v = uint(keccak256(abi.encodePacked("a70c1946af4f", block.timestamp, block.difficulty, toString(tokenId)))) % 4;

        if (v == 0) {
            description = a;
        } else if (v == 1) {
            description = b;
        } else if (v == 2) {
            description = c;
        } else {
            description = d;
        }

        return description;

    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {

        string[12] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" viewBox="0 0 600 600"><defs><pattern id="bleach" x="0" y="0" width="0.125" height="0.125"><image x="0" y="0" width="75" height="75" xlink:href="';
        
        p[1] = getBleach(tokenId);

        p[2] = '" /></pattern></defs><rect viewBox="0 0 600 600" width="600" height="600" fill="#';

        p[3] = backgroundColor(tokenId);

        p[4] = '" /><rect viewBox="0 0 600 600" width="600" height="600" fill="url(#bleach)" /><svg x="60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[5] = getPlain(tokenId);

        p[6] = '</svg>';

        p[7] = getPlain(tokenId);

        p[8] = '<svg x="-60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[9] = getPlain(tokenId);

        p[10] = '</svg></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        o = string(abi.encodePacked(o, p[9], p[10]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Pandemic Warhol #', toString(tokenId), '", "description": "', getDescription(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    // to String utility

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    // Replace string utility

    function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
                result[i] = _stringBytes[i];
                if(i==_pos)
                result[i]=bytes(_letter)[0];
            }
            return  string(result);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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

pragma solidity 0.7.6;


contract BleachBackground {

    function getBleach(uint16 index) external pure returns (string memory bleach) {

        bleach = string(abi.encodePacked('data:image/png;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeD0iMHB4IiB5PSIwcHgiIHdpZHRoPSI2MTJweCIgaGVpZ2h0PSI3OTJweCIgdmlld0JveD0iMCAwIDYxMiA3OTIiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDYxMiA3OTIiIHhtbDpzcGFjZT0icHJlc2VydmUiPiAgPGltYWdlIGlkPSJpbWFnZTAiIHdpZHRoPSI2MTIiIGhlaWdodD0iNzkyIiB4PSIwIiB5PSIwIgogICAgaHJlZj0iZGF0YTppbWFnZS9wbmc7YmFzZTY0LGlWQk9SdzBLR2dvQUFBQU5TVWhFVWdBQUFtUUFBQU1ZQ0FBQUFBQkE3YVJ1QUFBQUlHTklVazBBQUhvbUFBQ0FoQUFBK2dBQUFJRG8KQUFCMU1BQUE2bUFBQURxWUFBQVhjSnk2VVR3QUFBQUNZa3RIUkFEL2g0L012d0FBQUFsd1NGbHpBQUFBU0FBQUFFZ0FSc2xyUGdBQQpBQWQwU1UxRkIrWUpIQWtURlJqMVJwOEFBQUIzZEVWWWRGSmhkeUJ3Y205bWFXeGxJSFI1Y0dVZ09HSnBiUUFLT0dKcGJRb2dJQ0FnCklDQTBNQW96T0RReU5EazBaREEwTURRd01EQXdNREF3TURBd01EQXpPRFF5TkRrMFpEQTBNalV3TURBd01EQXdNREF3TVRCa05ERmsKT0dOa09UaG1NREJpTWpBMFpUazRNREE1T1RnS1pXTm1PRFF5TjJVS3BsUERqZ0FBQUNWMFJWaDBVbUYzSUhCeWIyWnBiR1VnZEhsdwpaU0JwY0hSakFBcHBjSFJqQ2lBZ0lDQWdJQ0F3Q3NEVy9HWUFBSUFBU1VSQlZIamE3SDEzZkZSRjkvNHpkemViVFFJaEpLR0ZKSVF1CkFnbmQ4cXFnQVJTa2c5SnNkTERRMU5lQ1NzQ0dnZ3BFTE5pb2lpS0JnTkpDRStrbElYMTMwOHZ1cHZkdHllNDl2ei91N21helNRRGYKOTQzczE5OTlQaC9JM3JreloyYnVQSGZ1M0RuM25NTUlJa1MwTExnNzNRQVIvM3lJSkJQUjRoQkpKcUxGSVpKTVJJdERKSm1JRm9kSQpNaEV0RHBGa0lsb2NJc2xFdERoRWtvbG9jWWdrRTlIaUVFa21vc1Voa2t4RWkwTWttWWdXaDBneUVTME9rV1FpV2h3aXlVUzBPRVNTCmlXaHhpQ1FUMGVJUVNTYWl4U0dTVEVTTFF5U1ppQmFIU0RJUkxRNlJaQ0phSENMSlJMUTRSSktKYUhHSUpCUFI0aEJKSnFMRklaSk0KUkl0REpKbUlGb2RJTWhFdERwRmtJbG9jSXNsRXREaEVrb2xvY1lna0U5SGlFRWttb3NVaGtreEVpME1rbVlnV2gwZ3lFUzBPa1dRaQpXaHdpeVVTME9FU1NpV2h4aUNRVDBlSVFTU2FpeFNHU1RFU0xReVNaaUJhSFNESVJMUTZSWkNKYUhDTEpSTFE0UkpLSmFIR0lKQlBSCjRoQkpKcUxGSVpKTVJJdERKSm1JRm9kSU1oRXREcEZrSWxvY0lzbEV0RGhFa29sb2NZZ2tFOUhpRUVrbW9zVWhra3hFaTBNa21ZZ1cKaDBneUVTME9rV1FpV2h3aXlVUzBPRVNTaVdoeGlDUVQwZUlRU1NhaXhTR1NURVNMUXlTWmlCYUhTRElSTFE2UlpDSmFIQ0xKUkxRNApSSktKYUhHSUpCUFI0aEJKSnFMRklaSk1SSXRESkptSUZvZElNaEV0RHBGa0lsb2NJc2xFdERoRWtvbG9jWWdrRTlIaUVFa21vc1VoCmtreEVpME1rbVlnV2gwZ3lFUzBPa1dRaVdod3VSVEs2WmNKZkYvRTNsdjZmZC8rZkFoY2lHWUU1SjdHL1ZyNit4RzJORnpYS3lHNi8KOEYvSWQ2dHlaRTFoLzFTZXVRakpDUFhYbUpxKzFOVGdUeE5ubWNPcDIySW5hNXlSYnJ0d2MvbHVUUk55THNmcVUrcFBVV05CMU14dgpsNGRMa0l6QXFKNG56SDZwRzlDTk9meHBmSW1iSUV4emJIVTQ3d1FlREhSYlBHbitGTU10QkJCcnNreWp0TWJ6bXEzcjVGamtWcDEwCkJiZ0V5UmlJQWN6NndLeS9iTXp4enJiK3NjNDFEYTRzT2QvNHdvT1EzV3hPb3NhalRaelFBa2IvNVFQenBzODkxc3dVUmJlVkZjeUoKayt5dnJTbnVDRnlDWkxiN24xbC9zMlp5UUxqQm5VRU1ZSm04WXdJMUltSmplWTFYZ0dTbEI3dlZ1TmxXZnVhS2twdm5hUEpVby91QgpRWmVtWjFyYm9mME1ieXFyZGp5MlpKYUJkUC9kbGI0VGNBV1NFZWozQnhuck5pSmc1RGNXNEhUWFE4M3k0ODArRmNJUGg4Y0ZHSUNhCnNLTzJsS0t4WHF6dHc3NWRYalA5MVhicy94ZGpQZTV2TmVEWG05SnpjVERqd2gvdnptU1VmMC9iaC85eWIwMERYM0FVendBb0hoeHoKYU03SG94cjBDMkQ0T2NSL25jUHg3ckR2UGhtN2U4Yi83THIvZlNBWGdRZk84ZnF1K0l6b1hiYVNpTlFibXNvVmhrdE5GLzhXMCtvUApadU5sc3J5STUyOVI1Y3BHS1JZNUxsTkZkNXkrYWJsZjBZMklJbUVpUGRlMzhXbCsxL1dibFZZZ3lEbkZZN0NCYUJGTWpmTHV3K3YxCkJ4bnVxVVRwYmNJYjFkZk10WElkdU1KTUJnRGdJR01lWTNFRW1QL3ZwUUFPcGdHTlYrRWIxdzV0dXZodVJCZlpEMlNRZ25zRzMxdWEKdTdFQUFNVTdHemRDQWluYVRNSFdCdnNienUrMVVyZ0JlTEYvTlR3a2p1dDg2MS8yZmNWTmFrWHZqNzkwT3JIQ3NGUk8rTUJMNzVCVgp5TnphY1dZNzNQRXVvUHNIWm1lWnpIcXRYUGNGd0dWSUJoRGdqVUZBeDNWZGdJb2QxdmZGaG0rVHc5L20wTlFhV1JsMGI5MHVoM1FDCldxTk9EelNWVzFqeDArZmtrTnNSclZtbHNEcXp2OUNTd3d1ZDhCS3NYNExoTmJDZGIvQTM3cXhOWXNNS21KVzNyejZPQnJkUC9CRTgKRGdiZkJ3ejIzS3pCdTRQMVIxSHVhUUN6M1J5YnlnRDd0V0lOOHJzUzUxeUlaQXhGdi9lYWovUW5IdjhJRjN0Y1BQWHNKN0JFRHA3eAo3QjZRNmJVK0QwMCtDL3c0ZGZSRmZETXh2SGpqc01VYTRKZndOR3ZaNytiTnhROE90ejBERW5GL2ErUk1IUGJvWmdKeUp3eDdkQlB3CjJhUkh0SitOU2dLQXVzSHZWajc3YkMzU3h3KzhkMGxwZzRiRTB4aUdRd05HUDM0SndNRUJqNDY5eERCajdLczNsai9Gdy9icWVDZ0QKNzNRaUlnSndhT0Rvc1pjQlhCbzVjdjRyL05xaGxuWFBucjg0ZGRUdlA4MzRCdGczNklHSE5qSWtQakY2ei9uSFI1OW1lSEhDNHdCSwo1dzlkOUp3S0FKQUlOejhBK0xjbjhQVy9wdzc1bW9FdVBqOXQyakNBZ085N2hSNEJBTkFnZW5URXgxZTlqK1BYWjUrWm8vcngyV2N6CjhjV0N4eGJNdjlqajRzbG5QZ0VPRFJnOTVoSXVUaDExNnVpWTBlZjRpS0d2bExvSzBlNzA4OW9HTDR3YXhUMlNUVVEvcytlbyttZk0Kek5EU1NseWw1MXVYMGtTcGduOUJmb3hNMC9FNzFVN0JFeC9PeGIrSkhzZlh4Qk1SMVQ3QVYzclVMOWZtWWtyVXUyM3V5NlRxNEQ3RwpRcmFkcnc2Nnk2VGx0bFBkUkx5bWtMeER4Qk9mMmE1dGVpYXY5ZjJYdnF6bjNhVkV4Qk5QWHZqa3gyZlpDaVBGNEhYNjNDOVgrT3ViClM4VmVveGY4eEJLSWlPZ0FXaitFVVR3UmtWcy9vaGk4VGx0ODgvaHprbi9UYWZ5b2ZSYTdNcXBwTzVadG10cUhkbUVkbmNLTFJMdHcKLy9PYlBic1JGZnQ2RXVsNzl0R2JPMDRtSXFLMzBZNG5JaUtlRHJQRC9MTklKN28zbnpMYkdPazQrcXpiSVIwc2ROSThGd0Q2cEZMZAo0L2lHTEpOM1VOWURQSDA5dmtxNFZqRjRnOS9pbTJ2ZWpQRFY2NlZkbHYzd0JENjYwNE5xaFF1UjdBckZqNWQ4UUh3aW5pTTZoNFZFCmVhdzcwZUllaHF0c01ORTVqT1BwSGZ4TzlCcDdsYXJkQmhJcFA2c21JdUpwLzc4TENpZXpoVFpaY3pEeGw0TnBQTkVXdHBDbzAyTzAKQlF1SkFoNGplcDB0NUE4VzhqelBFOS9abDRqK2pYVkV5N0NkaERRdmZQakx5UklpR29FVDlDZStveEU0UWVmd0hmSGRQUTVXLzhJVApFVThIMEt0MDVXZ2lFa2cyQWlmb1QvWXQvUXR4L0dIZkdGckdUaERSZFhRMEpsMmtyc2drNmlTcDVxK3hyc1JQUURyeGQza1JiY0liCnZENW9PUkVSYllEYzJtNysydWhVV29WZnFWWit6OGRYazgxMEhBOFFEZWZLcmVjdnZUYlVEZjVtaW1mM1U5MTBudlpMWjIvTGk2ZnoKV0VROGpVQU0vWW52NkNBbUVZMWd1eWdYNGJkMTVWc2UwanM5azlyQmdOQ0lRMnZtdDdNdUtqZ2dIdTJCTDRGVThnUDhjZFc2UzByMApFTFh5cWdKNjliS1czT0gzTnVTMDUxTXZtN0M3bmdCQUxJVXVQVzNxMnhZcHVQaDA3ZDF0QWRCZGJEenV1UUtzZlp0QURLbndBL3pZCnRTMVhnSGRYTVdEMElBQkFLalp0cXg1Wml4UnMvS0Y2WkMwWURBTmJQV0Z0SitENzcyZHg5dktyWk10YUZWNkhPT2JQeHBUWTFuSWMKUXR6dmhpRUx2b0MvTnZZaG9vZUlkVVNsVUQ0TzdabEhydERXUGpCVytBQTQyYUhmb0VXclc2ZkRRbTVMTmw3RzQzczlHTzRIZkhpZApENGpoOVhlRzNZUFN1UWV2M2hzNlpkK0pzbW1NSHU2OWU3ZDBVMy9oSVo2S3lHMDFJMnZCY0Jlb0U0V2lFNnJ1OUpoYTRUb2tJd0JkCm1DbnBZYXN5ai9COWQ2b2dzQ0xjalJxZ0dvSDJSWmVjQVl3WWFRTUFBRnEzYndBa0pPOTdwb0ZBaHM3b3ZSTXdXLy9XQVVCWEFCK1UKQW4wQnNQUHQ3ejVVQTlSUTV3OUtnWDRPcjNLZENwOTZFakNqYzlIVFR3Sm1BRzZCRG04QzZQQURqZ1FJN1Frb2ZPcEprQVZlK2lxQQpKWVFDTUViTkluUUZJNDl1bWJvMnFFRXdHR1QyRndSaW5pZ25ocVM3T1FEaDNUT09UUWV3YmorOSt1bjN6NzMrQjdHS0pSTU9IL3o5CjJDU0N4TjRYU3RxMUVQQmJmZENOMk9xb05ZRzd3UExQSEQzKzI3L25jUUIrbUJOUU9QdEprQVVBWjN0aGNuaDV1YU53bVlXL0JSYkMKZHVyd0FPb0FCbDlVbUU0UDdxUlVNTHd0R2RnMzJZaExtQytNTmxsZ0JpeDFERXNDRHdFQVB1NE1BSE50T3crd3dBS0FBZE05VCtxZwpYb0RwbnFkMDBDd0VDQnlBOENlZmZMSXZmUFcxZTN5ZWtGOEhMbm8vRWY3a2swL2VEZkN3Ym52TXhXL0FyejlnanZDWHdEUDdnRm1JCkJ6cWQzK2dKbm5nSVdmYjlnQW1JQXJibHdBL2xWOHVGbWhpZXdUVm9jaC9wQWpQTXNQN0hNNXFBMzgzSS81WURBUGN2M1Q3UkFkSDMKdFdKNzZFRmROTXpRakI3OHNlS2UxckFJaFhoQjJmWHZaQUNIdzBJWitrMDlOMXdDN0gxNzlvNzQxdkJGZWUwcGV6TXNxQU1zSUtFdgpyc0F4RjFqNDg4UVR4WXdGaHMwZUZEcFBUZWxENFBzbDhhTWt2ZjZrODkwOW5wMTducWdvZk1CaS80K0pkclpIMkkyTi91aDdlUUl3Cmp4YXhnMFJFejNLeXNVVHJld0lqRFR4UjBmUTI2REF6bVlpSWpuZnhuenVybE9oNGlQL2NXYVgwZmdjTStNQlc4ZGNJZW9Qb2VJOFoKai9ROUs3VGs0R1BBNEVYRUU1SGxIYy9CYzFjVFdkN3hHRHhuTmRWTVloaC9nb2dub3BkN2d4cy84MThjZHZPaklYbkpsb1hLSm1MRQpraytKMHZ4OGhsZWRHSXkyTTNWRTlIcVg1VUhUaStqeVFQaHNqUFRHd0l4NUhLWVJmZVFSOVB5Q2FrRWdYUnZVWSs3WWQrcUkxcmdGClBIYTY5WUNmY2pxT2Z2M2x1WFM4UDlydldPMkpCMHA1SXBxd2EvNjhOZUZUYzRtSUVqb2FpR2pEd1BIdlByMkQrSkZjcjNOa2VjZGoKOE56VmRLb3YvTGUvNzQzN0VzTGg5Z1ovcDBlWGlJaVlxN3psTmlKL1pxQTdRUG51N1FFQU9uVzN4azkyS3V6WVpGSEgyN2ZBMjFQNAoyOGFqL2p3eEVFTVJhd2NRVTdPQUpnb1Ryd2xrQU1Dcmc1cHJvdTBiSFl1bU13Y0FGU1U5QU1DZzdlYVF5NUxScVhVVGhXdXpnK1gxClI5V2FibTRBVUZVUmpHcHRMM05KdTR6T1hnM3JRcFUzRE5uQlhrQkY0b08vNWJ3QW9OU3JUdHVUQWNnSWtnR3dXRnZzY25BZGtqVzUKZXJBbU5qaG4zVXR0WXNWaFBkUGdSTU1zdDF5aU5KR2hjUnZxNjdFZTNsUnNvN2JjcktlM09rTU0rT2lOSzE5K1c5OEVZbVQ5Sk0wbApGbUJOd0hWSWh1WXVrdlAxSTlZVTYremYxVHFlYXNqRXh1S0ZHYTFoQmRSd3dKcW1xMk9XQmlXRnh0bUVPbGJRbElUR2JVSHpONGc5CmszWmRtNWZhT1RUMUp0ZlROV2puTWlSekhnREhDMlM3K001cFRRNkNJd0djTWpsZDlPWkd3RnBSRTdtSjJULzdhTGJ4VGxVNUQzU2oKQ2JHSmR0di91ODM1eWFrR01GZGhseFV1UXpLZzJjdDVrd3ZtUktqbTh2K1ZoMG1qWnlGdThxdlowamZKYkp2dW11bGc4eE52L1lSSQp0Nks1UzNITVJValcrTHJmeGtqZTdEbFluOTcwek5GazJxMEc2bGJMcHRzZDJWdTFvL2xyY3BPRzMvSmkzRUhjZVpLMTVFVnBjZ2F6CnJaWnZiNlh0Zk82bW4zUTNlc0EzSjdiUktzMzVYbkFtUEc1K3Ivd04xL0svd0owbm1ZaC9QRnhteDEvRVB4Y2l5VVMwT0VTU2lXaHgKaUNRVDBlSVFTU2FpeFNHU1RFU0xReVNaaUJhSFNESVJMUTZSWkNKYUhDTEpSTFE0UkpLSmFIR0lKQlBSNGhCSkpxTEZJWkpNUkl0RApKSm1JRm9kSXNrWm8xdTIwK09uZGZ3aVJaTGNFdVlnWjl2OWRpRi9HTnNhdFBtSjIwWStjWFJmaVROWUFCTnpNcXA2b1NZczRFVGVICk9KTTFCWEd1K3A5Q25Na2NZTC9oYm5ucmliZm1YNEU0ay8zSEVLZTcyNFU0a3pYQTdtL1dmZU9jWm56cE93Q0tWd0NjbTZrQ2pyMWUKQWdBNzV0M3B4djZmZ1VneVI4UW5MM2hKQ3dDZ2VxN0p1d0hBWFJzQVBOQnBVaFZHK3ZrRHdBQmpnNksySjhMeDdEdmRDZGVEU0RKSApXSFpmOEhvT2wvWi9TZXQybmFmb2JWcWsvLzRCM0F6djdFYk1EZ0lRUEgwV0w1SGgwb0V2SVlWbDR5VmoxT2ZKWmVzdXJqaDVlbGt1Cmt2Y2RwcnpuRDFVazd6c3NMa0ljSVpLc0hvUkI3NDJiNDRFdkp2K2VQcmJydjk0TG5qMmlkTk1EUGNCbnZmVStzZE1NQUxkYS9oYUEKTFpOK1N3TTcxZmZlMzl6dStiRE4yY0kzNWdjLzhGbnBwcWw1cndmMW4yRFpPRFh2OVR2ZEY1ZUNTTEo2TUtwOVdta2FRNnYzR25VQQpmdW5xOXErakk0Y1p3ZnJJMmxYNVdxT0liRC84RXhDeDE2U2pqTWlSbUdwT3FPRmEzOVhlcDN1dnNqTWVHTHNQUkdjOE1YYmZuZTZMClMwRWttUVBZOFFMLzNiWFZMendSU0NEMHZvYldRVDFQYkxrS3F6OXVCZ0JlMFcrWWRjOC9FVVJjOTU2ZjRpTzNrV0FNeElORDcxaDQKQm9QamUxK0hWL0NkN29wTHdYVmNyTHNFVms0dFhleXBqU2kvOU9TMUU2Lyt1NlRkUTA5UGY2ekhWbG1PNW5wR2VtVWI1Qis4YjFpWApIVGZjQ3lQS0xza3lQaHJhcXUzblk5UkptVmQ0cmZKS2VtREkyNTZmVWU5UDN1djZ0dGRuZDdvakxnVnhuOHdSUnJuVzF4MW1CZ25NClVyTG92V0VwOTJ1MEhWWXJNek9TQWlBR2s3dEZjTFZQRENocnk0QTZONVQ1aUE4SVI0Z2srNC9nNEFoV3hDMGhrcXdwaUFUNm4wS2MKMSt0UkgwZlZHcHJ5UDc4Qi81dXkvenlJTTFueklJYnZMbjRMWU54djFwUzBkS25NSE56elRqZnMveHJFbWF3eHZvRTE3akpoc0JFQQo3Qnc3LzlpbzRRK1g1d0N3elhzRUFqVWRKZGNod1BULzU1QkUzT2tXdUFxb0ppYkdwK2IwNGY2WFh1eDYxOWtMZFoxdy9IeHg2L01WCiswZWtmUFBROFQrdjd4OUJHMWZ5KzlRL3pyelVJeVhoZElidkZza25iam1mOVZWdkR2aWpLZ2l3WERqbTdaZjBaM1ozMVJlU0RiMmoKZmhrdWdmaDlvd0J4SnJPQi9kUm1iT1htQjJqUDhQWlQvb2lmdGVHSTZzcnNLcFkvTmVkaXQrMlFmVGM4N1Z6OC9WaDFqM3NoTTF0VwpoQ2VWK1A5UitNYUM0QWMrNjF1N0wrTmVBSnZhUGZSZDJhYXBlVzkwK1M1ZytQTlRxNDdjNlE2NURrU1MyVEg4aGEvQ0lrNnBkUUQyCkJXUE12dUEvWjl5UHdEWmRpanprOE8zV28wL1orWDlka3dhZkhndFFlcTFmTDdjMmQzWHc2ZDY3RE85OU41b0JPTmlqOTdyVFhoajcKcTd4dHQ3dDlmWHFWL3JmdCtlZEFKSmtkL0tXeVRkTWZHMEFnOUxvR3IrRENxRWZuQTBMWVNnQUUvOW9UOStYc2UrVG9NT21iK3g4SgpGOUlBWFBod3VSbEF4OU5JN24yTlBMdEFOQVJ3Z2tneU93NXN2Ky9CZHYrT1Q2bHUvZFhNYzF1dkw4OTdwZWU0cTVtNXFkZFRjN011Clp1U2xYbnZvM1BBOUpZOGY3NUtJTFQ5OXRiTTg4MHFxV25rMS9ZKzlNMXE5WUJqR0wzMStSbFcvYnU5cy9TdzlUM2tsS3o4eGpyL1QKSFhJWmlGc1lkbGowTW5lWTNDMFNzeFJVNWdlTHhkREdkazdZbmQwMXNpT0FQN3F5UzQrVjducVRjenlsODRLWmwxazFTdzdwSWlDUwp6QUhVUkhBMXB4QTArOTNiWjJzZUdIUnU3VDA5dXo3WWRFYlJGTGd4UkpMWklZUW1iVG9XbHoxa21OYmRGd0EwQVkxQ3UvMmxFR1QvCmYwRWttUVBzWWJYZ0VJbXJ5V2l0Y0U1eUNGRXBLcytkSVpLc01acGxVNU54S1JzOFkxMDZTdk1kZy9oMjZZd21GMVhzVERnQXRrRGIKSU5kMyt3RXdDTkdwQlUwVWhFY25pZmV1QThTWjdHYW9uNU5xNzdzdUhHeGQwQ0IyYzROODVHcHhtVjBFb3U3U0NXZC82dk5kV3VnMgphV1MzRThmN1hicjJXMjNaMTkwcnQ5L0R2bW16djcvdXM3dXZMdTNhSi9GVWNiZXlJOWQ3MFhhZGJpdi8yYUJXWUhUd1VvZldKODRlCjlzbElQbGZZNDA3M3dkVWdQaTZkY085UGJUb2t3OWhQVWZuQTNsYnEwVjRKZzM5clV6MlFXSGtvWHZPSjBRMXZOeVh1L0pOZjRJWEgKaDQyUVptZUVmQ1h0OHpXQTk0Tm5qeWlUZlR2SnRHM001a0R4MndzbmlDUnpnbXpzMGRxalJaMHhmMmNha3V0YXovNjFzdU9QVng5awoxUGJ1Vnk5SXZRSFFqMkdTWDB1VjdqMUxORzNnNGZmQVhlVUUvTnpWN1lIRFB0MzZ1dWNpcExPNFUrWUVrV1RPbVBPbDdMRVZqMkxVCm4ybHZyK3pQZkxwOHZPMEhPVUJBeldnd2dGaVAzNURtVVdSa3Z1MDRBTVFSQTNwZmgxY3dBMEx2UC94KzJ6dmRBNWVEU0RKbjlISWYKUDZlakc3aFJvYU05QnhIbStMWHJOL0s3THlXdGY5bjdVbW4yTmJUK2F2SWY0ZWM5MzNycXg2VXNJUzRwSi9PcW9ub1kvMnJFbmc0UApYVTB1VlAzODNTY1g3blFQWEE3aTIyVWpHTjJaVVE2WTNLSDNCS2hPWnZDb0l4bEsvVUFNc0VoQUJrOUFKM1czYi9UcnZHRFd0UUdBCm84R2RpbzR1dTlNOWNEV0lKR3NHOWZ2MnpXNUtDRm1FWFF2clp2K204ME5DK3Q5OXA5dnVhaEJKOXArZytjMnd1a3IvTzkwNDE0TkkKTWhFdERuSGhMNkxGSVpKTVJJdERKSm1JRm9kSU1oRXREcEZrSWxvY0lzbEV0RGhFa29sb2NZZ2tFOUhpRUVrbW9zVWhra3hFaTBNawptWWdXaDBneUVTME9rV1FpV2h3aXlVUzBPRVNTaVdoeGlDUVQwZUlRU1NhaXhTR1NURVNMUXlTWmlCYUhTRElSTFE2UlpDSmFIQ0xKClJMUTRSSktKYUhHSUpCUFI0aEJKSnFMRklaSk1SSXRESkptSUZvZElNaEV0RHBGa0lsb2NJc2xFdERoRWtvbG9jYmdzeWVndm5td1EKQTRSdW80QVFwdjQvYmNGZjdBWTFtZHBzM3NaOW9XYXovOCtiL0wrSHk1SE1kcDF1NnFhOHFjQTBqbW1OWFBzMUVTM0pGckNtaWJxcAphU0dOc3RMTlRnSWd1MHRHaGx0a2hTMHVFOEFhWm1mMmVEcE45WWthM0NzdTZ0dmQ1VWptRUV1bTBTelF6SHgwVXluV0hHVC8wMVFPCjJDTWprZTJ2TFhwbE05V3hwbVRZcW1IMk9waERHYXIvWjBzbXNIcU9OQ1BTbm1adnYrTzl3SnE0VjF3T0xrY3lLOGcrTnhFVHJpNDEKdU5yMVlFMlJrQnhIbGdtNUdOQmcwQnNLRXFZUll2VlREN05OUkVRT0JHV05xbkI4empIYnpBT0hCbGluTTZGK3NqV1lpQkZ6bkUrYgp1S2ZJdWJJR1JMUTJqbXpVYzlHSHBhdVNyQktNVitRSnY1bDFkT3FIb3VHTlcxZGhPMkY3M2dpL3pQdUUwckNKSVpCQUdHSU5CTm5HCjNHbE9JR0xXS1kweFdJNDJxTlpLM2ZLb0hFQWcwWjlhcDhFWFNBcGlWNHNkZUVtMmgySDVFV2FQOWtVTmlwM1RBclg3N0QydmkwTGEKZFRDQU1RZk9rZTNHKzdQUWNremd0UXRQYUs1SE1nSXdzeHpjcDR0dHgzc2NUek0wUEVaVXBHMktzUVZuWm1BZ1ZFYzQzZDNNT2xTTQpBYUM2UE50cDZ6ekRuQjVHak5sblQyR3ljSmhwck94Y055SWFBQmpCK0hXTy9XeUdiV3BoeE1EQXc0RkdkcUtVZm1CdnNlUGNaNVZVCkUyR1hWcjBheDJLY1oxSEdCSy91elBoMWRuTkxOaGVDNjVHTUFkZGp0b0s4Y1NPVjZPU2Y3T09QNDY5Y3o3K0I1QU9sUUdJeWZmeFIKdkdQKzlCOHRBRUFsNVRlb1JBVkZCVlJaTlpUSSsvcENwVVJlQVFDWU5DbEdvQ0FmS0ZURGxKMElZTlVaQXlYcEdjamhwQ2tWcHB3awpBRlN1TEs1UkVDVmFTSm1weTArb2tuUUhjaldBc2tRaEVNTVVSMGlNcjFrS0FKU3Vsd2NCbEdBQkVrM1ZDMVNtM0VTWTRrQWxwYkY2CmRIVkRiWUwxY1p0UkFzVGx3WEk1cXdkWHBDUUFxRkNVS3pKcUZYV21PREtvalBuNThrQ1FSZXNuOUMwckNiNis2QTRnUVE5VmxsWlIKcFJZaWJwYW5BQ1dsc1FaNUlDVGRVVndhcXdlZklENHUvd29TbnZ6Y3dwQ3ZIaGovMGFXVE5Rck8vY3lrVDM4KzlKRm1MSlpyUnlxVQpFcmxEM3RqaDRRZEFnT0hwemQvTzhabUpzOXV2VFRpZzJDcWRBSWJMRzNIVUFnRHZ2eFkxbEQ5WXRlSEV3Y3IxSnlKWDdxdEduUjRzCm92WGE0MkI0LzNYclNlV1orSWpJNWZ1cUFlWTVwOUxqS0xaS0oxNmZHSDN5bERyNXo1ZXdPL3ZrdXF2VG91WVdFQmgwYTN5ZVVSdXMKcTZ2ZHNra1ZCUDVyNlVUTFdxOHhGajBpVit3cldPUHpUT2JpRDQ2OXJwK2JxdHFSOHpvQWhvMXNWc2xTL3pubDYzdnVRZm5GeGNVQQo0UGFFN09janNoK05hOW8rVS9wSnZPRWxBSGtidlpRQWdMM1hkeHdWNXJzSTc3WEh6L3pnOXFUSGhVSUFTTjFsbW1WYy9NR3gxMEQ0Cjh5WGo0ZytPdmM1L0l4MS9wOGV0T2JnaXlmTGxNL0wzQW9HUGR6emU3bTJKWjZmV2Q3bGJQdjF3d01qNFRQM1gzYy8xNk5pcXQwUG0KWDdTZHRvQUJubmROMlB3SDc0ME9HTkp4aGI1QU84VU1QS1dxNFRzRHdLQkJiL1crSEowM29uVjAzb2hXdy9xL3ZDMnkzTCtMUGpaawoydWNuSXFNSEQzeXI5NVhvdkJHdDloaDlRNGVGUnJRR0lIdGw3OWxaNXdxMFV3WjBYREU0c216SU1HREw4SmxmRC9SYitHQU9BQnp6CjdScTJwNXQzRnhDZ1A1bytwd3I0czFBNzlXUnc5eU0rSHIySDlWOTlvVzNYc0FQOXh5OVA4K3lIYlNNbnJBV0FLa1czMy96ZVVNbEsKOVV1bnczZmlrQndBYVBWY1ROK1lsQ2RpMm9hRS9leUxEZ0REam51NzNBVUFHTldKeXdNQVZob2JNbTN6Y3hlOHZhNWJCZ0RBbC9jTgpyRXJwUDM1NUdoaUdRZDUvL1BLMFB3dTBVK3J1OU1nMUExY2syZEZPM3NNK0JRZ1UvT2lXZCtNWXdQd0J6VGNQa2RUOXorNGNZeFNYClpWdm5GSWM5OFpZbEdRREFzL3Zkd0lNSGc1czJmQ1FEMklMbkJ3QUFHSStnYnBvK2svdzFmU2ExWjNEcjM4K0RrWHNtZ3R3RCs0V0EKUjFCWDlkMFQyN3NaUncrd0xkb24vbDdRM2szN3lFakd3QjA1dEJNZ2FhNDBVTW9nSVFiQUp3V0I3c0ppaUZqbWlLa2NJTk9HaDh1dgpvSkFBRHN3bkZZRnlEaHdQUUg0WldnQndpN05ZaWxZTkRxVEYwNmNTSURVREFKN2VTWjYvOS9OUklGRE8xUkVQUW1VVzR3RUEyODJoClFzL2ttUWowa1BYOU9QS2pkb0N0ZWc0U1hyZ0lFa2g0TjIxNE9PZWlEMHdYSk5tNTZQNzNEN3Y2bFlUMmgwN2UxbXBFeUpDY1U2bGwKWmJoV2tHZktYLzMybXlWRHNrKy8rWVYxcld0YzdnZEx0NlhGQU5qdnB4OW5ZYTljVHI2UnBiMVhHMzZpSWxlQjZkWDNBZ0RvL0xrdQpIWmFOWENwWkZyNlVTMGl3REIvaDNXMjdjY21HM1JGM1BSeUc4K2RDT2l4L1pEbjMxUHBaT1lrSk5RQUF5ZGhnM0tzWkdhUEkwaVIrCk1ibDNzcm9pWXVNdlMrSTF1ZW1KSUdDNHp6YkZjNWNVdVFDWXgvaEJhLzNUNHUvVmhNYzhrRFgrQXJwdHVwRlFNOXhuVytxc3BJUmsKVFVGNjBsTWZ6U2tCQUkreEQzelNvWHh6Y2V6YmJhYWthUEl5aEh1anZkZm91VzNZOERiYlVwOGQ4bkZVampZOWZ1NzNueFRIQVlCNQoyNDBVYmE0aVdlVzJaTVB1Q015dEcrdytBZ0N3NFBLdjNYb2xKU1pwaXRMams5V0ZDUW1KbXJzMDRTYzVGNDB2NDRyTkVvSmhtV1FWCmJXRXl1OG5BQzV0WHhIakdkQjRjZUZZclkwNzVnUlhUQjdnelZFdmRPUUF3ZUFERUtvNC9DUUIwTUgyQk56R1RWSUphaWNTNmJjVnoKTU1nQmh1ajBCZDZBU1NvQlRPNTJpU1ozbXhTK3p1SkZETVNiM1IycTAzblZOMENvREFZUHdPak9pRGdoZzIyN24zaUxteEFPek9BQgpNa3M0UzRXZlEvTk43cWlWQVRwUGhtb3Zrd2VJbWV0NFFYcXR6TUlKK3h3R09SaU1jcU83TmE2WXZYcXl2MWthUE9DaUFkQ2xkN29CClRVQjRQWGVudG9DN2pObG5Xd1lPNUFVQ0IzZDdYZ0lESXdiVVpLWGVDNkMxOVRIcUFXTHNEY01Hb1dSQ25nY1kzQUhJYk9MQkNCNEEKUUFsNWNrQVFLWVAxSE9BT0VQTUF3Q1FTSVkxekp3aTdFZ0RnaGZvQjloQlNQUUNTdzlaZUw5dEdCMk1TaWRBcmVBRE1EU1R4ZzNXSApBMExOTXF2QVZrd09NRWl0bzBJeVNJUW5NandBa0p6a1ZrSGtDWHRUN2Exd1ZZNjU1RXhtZzlNMUUvWmEyVjh1MHVDUFBYYWdZNGFiCkNtMWE1RzNrL0t0ZEpEc3JiUzF0bUtGQlp3UysveCtCSzVQc0w4RnhOTUNhR25GN1N2MFR4cG0zOVVFdW15NU16S0Z3NDZ3TmEvZ3IKOTBOakxqbm5ia3BSeXByKzYzSndPWkxkL0VyOTFldDRxL3gvZlZ4czh3bHVQY0UxUjZOYnBUWXh2VGJYemx1UzB5WGdjbStYVGhyQwo1czg2NWtxTnY3azBRdGx4L0U0TkJaY2RkNUFYRzgzYlRqbDl6TlgwUnlDTU5WbFJnM3dNUU9abFI5VzJYWDEwcFJqQStWdzArYUdICklPdHFzWE42NXBWR2RURGdmRzZ6bDhaVjRISWtBeHBvak1sNWpEUHN4M1hDMVdVRVJQL1JWSGtDa0M3b3kwbTd3ZWt6bnd5b1A2dlAKZjZTNklzZCt5Z0hNTnRmYkZZVE1KaitqdmlwclN4ekZDNmN5Y09vM1IzN1pQL0VnSU1PNExjMVJZRjFPUTExcmc0OFZHWkNCVTRlRQpwQWJLU3VNUGFjNzlkam00SXNteTFZWGc0L0tnVWxCdVlicnhpaVV0bjFDb1pzYmN0TUxxQlFyazNhZ0VRS3ZPNkNsQlI4U0Ezb2l2CkJRclZBQUR6NVd4UVBFRnB1b3EwbC9QQWlLRmFCdXJKYW5NU1lWUUFTRENscjh6clNXV0tFcjNTQXJES3ZaVlAxbVhxS0VHUDJ1d00KdGZHS0JRQmdpaVVVbGQ3UUF5b0RBQ0NyV2dXVVhUWkRWYVpZb014WEdFcXloSllZVExIV1NTOHprVXpaYVlWQWJnSFNYODdyQldVUgpVS2ltMGtJRlFDWmxVVWFxT2EwaXhDMTlaWEVndTJvRUplaVFXbDZxb2xWLzZNSEErQnNHb0R3VkNKRVpjOU1LR1FvRkVsVXZVUGFDCm9nZ2xoVXFXbzRXZ3BkWEg4L0pnWEJNYVYzWlozUEcvYlp5ZUVSV3VXT1kvcCt6eVoreG80ZGdqdTE2Tm00UkRWUnRpSXBlZG5tYlIKc2F3em1oUUF0WHJpSXJ6Zk84RUlZTmQvdTU4L1ZMVStCZ0EyOU56RGYrMDJydWl4SFZ1aVdoVVF3UEQ3SHhuUWpzSG1GYjllUHhPMwpobC9yTmNhekFJQjhlcTM3enhJQ3lJRGtDZEdLQ085M2ozL3hldHk0SXo5dEpZQjBhM3lmU1gvK3d5TnYwQzdaeEFvQTZsRy92UGg5Ci92c2xieFdPM1hkZXgvUXpQZFEzQUtyVFE3L1c5MWsxR0xEMytvN2ptMWVlbWtxN00wK3M4OVFDNlVremNLaHF3OUhGbTZNQjV2WmUKVXQ1cTZVSGR2QlNQQW5BWExyK0JpTmJ2SFkvOXhtdDZuWjRrQU9qNTRINi9wKzR5enRMTlM0bGNkbW9hSFRwL2VGSVJBSXNPTEQxNQpobkh4NXVoZDJUSHIyc3pBMmUwRjc2SmZQTHQ0NlEwQXlQK2c1SjA3UFhUTndBVkpOcWpEMHNVSDNsREp5cDVLcTZhd2JvOC93ejNaCnVlcEE3bkR2b1FNV2NqNmV2V1dieXdZRGNQZnZxb3NObWJJWkRPQUhyUnAwK1VET2lOWUVRTDkwK3A5RjJtbStYUlkrbWQ3Sk14Z0EKdmg0VGpvQWdET3UvNW5lalgvK1k0TzZIQXp5REFNOTN0cDk2Q2d6dzhlMDVwT09La05pUUtadUhkWCtpODhoblZBeGd4OXFHaEIzcwpOMjZsMG5Ra1kxNFZnTTZCOHo3N3VlT015dndPd1F2bWVmYnErZURGeTVNQkp2UHY4b2RQU09oUEFEQXFRSm96TkhTUmhHMFpNZlByCkRwNUJYSStwUFBiblB0UTJkT1JyQUxqbEIvMlZOU0dkKzNPZFBZTnczM09xMHRpdVV5SjlJZmVSK1lYSUFOUWsrSVk5OU9WOUE2dVYKL2RqUXNFVWMrOU56V0doN0VIeThlcVBIVkY0ZUd2N2FGOE5uZmMxNW93TmlxVjlRR04zM2JEb0I2RGk5TXM5Rm41Z3VTRExpRWRCOQoxZUJBbnMxL01ReEVIQ0FoVFo5SjdTUThPTUNxU3dSZzhjaEVzQndBR0VmZWZUUjNUMm9QQUl1bVQzRlRoNGN6RGxLejlhSnJDOEFECllJRFVNSHFBNXhVVUMydTlLVWVTdWxrckJRZDVKb0k4T09JNUppZ0IyeWdRNk02QkkyU05tTUlCQUk4T3ZXSlBqaURoYTEzMnl2dHUKMW5kTm4xUjA5Z0NBN1hYOUdRY3dTSE9sZ1JJQ1R3QzBmU2EzdHk2aUJpZmZXUFRDdzliVkY3bVo1WmtJbHJ2VmdiZnVlN1dlY0hSRgphNThVZEhabnhCRTRMTGxRdFJ3T0x3ak1LaG84OFkvV25ka0lrSHNkQXhCN2NnUzU2UExmQlVuR0tjNHF4cGR2THI2QjZaWDNsbXNTCkU5TFZlWW5Md3BkeXNXbTUrYXB1bStLL25IUVhBSFRmWVZ6eXlhNElBQWk0Y2pMVVova2pTemtHNEIzdmFmY1ZoTWRVNUNVa3FjejYKR0FENDk1SnYxSXA4VlVLQzdxa05zM1B1enhwM251bFBKR3RLMkhOZEFRQVZpdFBKbVJxdkpSdDJSU1NtYWRXSmllbEdnRWEwMlpZNgpPeWtoU1dNWVAyaHRKd0F3SElwZVlJazVxRlZwTDZMYlJnUjNHZ3NBNkw0OTFHZWI0amtRWU40V24zSlZsYXRXcmRtNGR3bDBNY25wCnVlcTBaZUhMek1xTFF1L0dkWjR0OWExTlN5TDlFVVZTa3FadXlZYWRFWGNkL0w0NHBmdjJNZ0NXZlQvdlZ5eTQvR3UzSHFxazJMUzgKZkZWMFl0UlBBSUJ1R3hQU2M5WEp5b3RZczNIdkVneDQrV3JpdFVzLzdpbFZKaVZxeWdGWVlnNXFTKy8wMkRVRGNqbFVUQ2dub2xvegpVY1hQUkVROEVSR1pMTUpaM21JMjZJU2ZaaUs5Y0pKTU9pSXltWGtpSW5NcEVlbkpub2VJU0cvVzJjUWJlT0wxdGhQZldjOWJ4ZGpFCjJWQmorMkVWTjd6S1FtUVN5dklXb3EvcmE3RmxOZG1xckRQWWF4Y2FMOGl1SlRJNHRvejBQRkdOcGNhYWtIS3NRdldkUThXMDJhRDkKdXB5MzFtZXJ6a0JFVlhyTGo1cVN5NGZ0cWZhYVhRNHVxTHU4b1RZRGNBUGUxSDBLMko0QU1vTHd4VEdEeEpxUmc2QjlCQ0NUUWRBQQpBcEQ0b3Y2RU5hOEhQSVZiaWtFT01BOUFRZ3pxcDFaYnp6TmJOdHV0Snp5OHZHeEtBZUdFT2svVEc1QUpRaGs3K04wWDliWFlGTmJXCnN5Q3AxRjY3cldYRUFEZEE3dGd5ZUFEd2doY2dBWWpWN1BwajJCaWJOR0pBN3RKNysvZ0k5ZG12a0VRQ29EVmdXblYzejNIMlZKbGQKcEt2QjVYYjhtOGJ0S1JCdFdxSm1ONzl2b2Y2czE4L2NjZ05mU01IdDdjM1hxNXYrWjB1bUJrclAyMURxM2xHNDRKcXN5VTN3cHN6ZwpiSHV1WkRPc3RPNldrbVB1QmdXYk1tMTAyUFJrOXExUFp0dnNKNmZDRFp2QkdweXc3cmM2MmFZNXJzWlpneDNXaG9hNXR1emtrTmk4CmtYZ2p4WWdMYzh3bFNVWTNEaDZ5c2NpdW9pRmNLUUlKeWlDQS9jN2JYN2tZMDhRNTJGMy94bHM1NG5EeHF4UUtOUS9nTjhIdTZIS1IKSUJ4cDEyeWx0SEZXTmhDRVBYWHJGejlONm4zcVcvbzdBYlg3R2d3OE9kaW1XZmZtNjQ1ZEFnQ3FPTXJzcG5zQU1RSURTN3R1NjZrbQpEb0k1bFUyQU1kb3V4WXE2S0NHQkhNM0dtYlZuTGdzWEpCa2RxU292Wk00Ryt3d2tBUVBVbjlxT2JmOW5FT3phcGd6QlB0SFpETEgxCjUxOGtMWGplYlB2MkRCd3l3RUE0ZXNLV2cyZjFFb2t4MU9aWnVkYU1kc3RxVFVjTVZCM0JITTFyYldxaURMdW1tOTRkSGdPZ0xyL2sKZlFETU5wOHhZa1JFeDJJRVM5QU1tMWxvUFgycVZ3TWdZZ1FTK3BkUkhjRVRpQkZqRFpTaExtMTE2WklrcS9xMThza0hxYmc4MWdEago1UW9vamRjQUpKZ29oRU5tSW5vS0Y3TUhLeTZMMWFQNmNtSDZ5bnhmdi9RVjZRcGpYbjcxQWlXNk0rUnBBWVh4YXIxSTF1V3VSNzhyClhvZnVESVo0bmtJazBaR2xGSmVQWHNMcHhIajQrNEtQTjZDNE5OYUEya3NWOU5hWnREeWp5bFJjcENCaktpRTVBUUNRbFYrRTJweEUKbEtjeW96S0hGRFU5QWI3QUQwalhBV0NVazFjSVpDYWhOamN4ZldVZUdNQW5HRmpCcWV5M0FYcnJkR2V1U0Vsa1NtVUFZTG1VVGJVMwpHT3VCRWhWVGxLZS9uT2ZyUjBqVU0xTnVXcUhRcm5adEt6S1FsNjlYbVE1RmxnS0kzc3o3RzY2RDhZazhBTlJscFdtTlZ5d291MXlMCjdzeVltMTRvYnNiZUxuZ0R0R05OaTk4Lzlocm1CVTBwSExNak1zcXkxbXVzWVo3aTErczdqd3JUZ09aeDQrTDNqNzFPbXdLaVBBdG8KL1c2UFF0bW44WWFYZUIwMDQyaDMxb2tQQzhmdStEeXFYaVlETUNORzh6Z0szMFcvUy9NVU9qT1crczh0RjZhcW5SNzc4UEZ1TEFudQp0My94QjhkZW83bkJVK3IwakMxMGZ6ZCt5ZVpvMWVuNE5UdmQ5d0hBcVJuN0hsRkVydGgzZFpkeGx2dTNNZXhZMlZqSzN1aWx4RTYzCnlSVUF6ank1UDF5eE4zYkgwY2psKy9nQ0FNQWE3elV4ZkswRlFKMk9jZVVYRmhlclRzVkhBTUQ2M252MGE5bytwUVo4WnVMUEhaNEYKMkxDYlJYaXZQYjU1eGFscEFFQ0FlZCtMMjdtRkh1OHFhaXdBb0xNd2R2S2JhUDRiNlFRQTJQSkcvT05IZnR5YS8zN0pPNXJIRWJucwo1RFFYWFpxNUlNbmErdmJvMWxuZWYvenlOTHlkVU5NaGVPR010SlBCM1E5NzlrTjRKeTVQZUhBRkJNajdqMStXeHM1K056dkFNM2dZCk9uc0d0MlVkMGNhemQwQUEyeko4MWxhL0xndW5PMzZlUUlBdU9LQXpybFAvb1B2Nm9aTy83eHNxdHhJQURQQ2ZOeExEVUozVU5teGsKL3duTDA5anFoQnFaZjNCbmNPM2NROE5mMjJQeURmV2ZQeElBQm5kY3R2akFzSDRSTys4YldCWDdhblI1bitET2JOZTlJWDMweHpMbQpWQU1ZMUducDR2MmpPbko1dy9wSDlQSU1BbEFhR3pKdGMyZXZ2Z0JrL3NIdXZwT0c1T3d4K1lZQ2dPNmw2Y2Q4UXdiOHpFanFqWFlzCndETm9LRXBqUTZaRkRnMWR4RUZvbWR1OGIzN3lBMnVQQUg4L0FKM2ErV0hjQk5XZkJkcXBaZ0REdWszclBPcFpWY2NabFhrQm5URTAKYkpFTERpWUFseVNaMEN3T0hGKzliclFuT0VoNCtSVVVFbU03emFHMmp3VTVjSkR5bHUvbEwxZy9RNFcwbG5nQXhNRm12TWJieFRFdwo0S2RuSU1HamRhYytBd01EZTNOd29GVlc2QmNybFF5dHh4OWQyWm9qQ1YvendXaFBnQ1JtZ0djTU11UG9BYUZmckZRQ0JCNEJQUmlEClR3b0M1UjI4dndvSGg4cHNXTGpNRVZNWkFQQUk2TG5kSEZyLzdpdlBSR2U3S1RJQmtKcGx4dEVEQUdEeDlDbHRVaERvVGd6Z21RVUUKeGp3eUVTam5TQmdWQWdDM0lSSXppTGM2bkxGSzBJYUhDNzBDQjQ1aVQ0NGdjT0JjZGpCZHNWMFZ5dFBhdk9Ta2hHUnRWZUlXL2RXOApoQ1RsdmRuakw5U21KZFp0aTArOW9TNEZxQ1F2T1NraFNWdTgvTUg3WURpZXBERHJZd2F2MzVkWDJtMVRhWjVxemNhOVMwcno0NU9WCmx6K0FzR2F2dlB6bkQzTW1qQ3pOVmNWZjN2TnpVVnB5MEtuVWlzMUZzVW1LV2dBL3FDWUhKQ2xyOS8yOEx5a3hJVWxUbWJqRmtONTkKZTQzeHM2ekx5b3VZdlg1Mjd2ZXFTWjBBUnNxemluSHhDYnI1bDMvdDFoY3ZrS1FrVnpYdnUwK0tGZU1HcmUwRUFwUm5GZVBNMitKVAo0eEowcEk4QjRMVmt3NDhSV1NuWEFhRDc5Z3VhM0l6a3B6NmVuUU1RM21remJZVFA5dFJua3hXMUExNjVrbGluajBsS2xUMi9mbmRFCm5DbzNUN1h5WnpBZzhPZm9SVExqWjFteFFTZFRHUkIwNnFJbU1VazVSRHN5UmdvZ0tTMWZuWkNZcm84NXFGWG1LZU5VdWZuS096MTIKVGNNVk4yT0YyWW9ZWUpaWXBNTE9xTUVEQUdwbEZna2NOemZOK2pZd1M0bkJ3ckdxVmtaUFFZVnVxWk1MdGhnbXViUHNuMGJJTWtzZQpZOFJMVU1lczZnNnpyalZqcE1pN3AvalBPY1NBT2lrdklaNHptd1hETktwMU4rdTh3WURLWjdiN0NFVjBYZ0JNN3NSQWxqcmV5OW84CjRYeWRtMFVDd0N4SU43cmJkM1l0MWgxNXdmRE9VdWxyczJ5akdxbWNDVDB6eW9Yc0ZhZW1BRUNGRDFCbjVyMkVzc1J6Z2lpOXArUG0KYTYyYkxkMUY5MlJkVUsxazljN0RBRWdodGI2Y0M1YU5ib0lCdDlVWkRqSG0xZ2FRRWdNa2dEYzhCWXRIV0kzWXdPUjJ1eC9iZC9PMQpiL2J0K1RnRGt3QlNHNVdsYlFDd21sMW5oejVHVEtnRlRBS3BtM1dyUVNia0FHN2ttNjJTdkFDUU94akFwRkxZOUZIeGFqTXhTQVgxCmpsVEk2bTczRUdYVCtwQmcwTWY1d3FZK1lxMEJTRUNNQkpNNEFpdWVESUJZR3dCdVVtWXR5MndTUEVsdzZ5TUlsa0ZpNzZNcmNzd0YKWnpLNzF5NzczOXRTQkRsTGFHZ3dKQWk3cVRiS1dVWGswQW9uSXpvbjh5WjdSYmRqTmRSUUZBbk8rVzVwa3Rjd2cxT3ZibDNwbllicgprY3dKalMwVEhUblJSTmFiMk1LaDZmTzMyd3hIZzdnbXFPOXdWOXkwRnczU211UytVNFB0cW9SR1NrckhCQmRtbVl1VGpCcE9SMmo0Cmk5ak5KdzNIdjhRYTVXN0NFTE9wV3BvUVRFM21iN0xSOWMydzZRS2FudTl1MDh6WWljbTNiM2w4SitHQ2I1ZkZKNFcvZG5ldlFObisKUzNHTzZ3MzdjREdiTXRNQnZ4UE14eTQ1ZTlka1RwcVhzdVBDWWRabGdHbmloTVN6R3VkYTdDMnhXOVNSNEREeFNuSFpjYVJkZDg0RgpBalEzNmxQVHJ0bWJJV2puR1hPVzNyQ1ZaelgyMjc3NEpCcDBqNkZlZlNUOFh4YURLOFVObEVzdUNSY2tXY1lXNFcrOWoxUmFOK0s0Cm96RmNBOWlVbWJDWnBoR3dkbmlNZzd3R2RtWTJLZG9Od3JtVHY5WG5OSDZiN2FTWXFjMkZmWktCclZrQU1oaEIvU21PSHJmTGRkQ20KT2tvNEh1T2dXWFhJN0d6ZGFXdTc4ZHRzKzh5WDhVV0Q3alh4ekxFYStya290K3h3UVpMMVJuWXBVS0NHb01SVDZaQ1lVUDJxWC9VQwpKUkp2QUlEcFVnVktDbFZXRTdpZUFDWG9nZndibFcrZTBRUG95VFNuc3Q4R2tKRUlBdEpYNXBVVzNsQVk4L0pSYzZrb09yS1VpdktCClNqY0FxRjZnNmdWbEVkcjZRWldwUTJaSElqQ1RKc2tJMDZWS2xCU212blZHclNneEtDMEFlakwrY2hZQmxIK2pNanF5Tk1TdEYxa1YKcWNvc0hSSjRrRWFwVVphV3F1RG5DMVZwUHBRNklLYzlNU0Q5NVR4a2F3QUFXZFZLcXMxT0JDWHhhb1d1S0F1bVZDQ3RSRUdyemhnQQpzTXlPUUVVcURBcGpmbjV2eWk1Rkx3QktIVURncjJRaU83K1F5SmdLcUVvVVFLVU02T0pteWtrcmhNMXl6aVhoZ2lTRDV0RG8xSU5WCkcwNXNYbjVxR25iSkpsY1lRZXQzVzNUWTZSRUZBSE9ESnhzWGJ6NXdzR0s5OWNHNnV2WGE0MW1uTkRlTTRFQ2FzVUF0VDhEZTJKMUgKR09CWllGeTArZWluQ1lZWDhWbm5LSjJGZml2LzVNVHZmMllDZ0VWSFhGclNEUHBrOTdXSjBhbXJmQzh6Qm56dytvRWgvTnpnU2NiRgptNk1NVnJNNVFETVdIL1g4aVFIWnB6VEpOUmI5dkZTZUUyYVhhNVAzcDJ5VlRzQlhKWHUzWGZuR2F3Ylc3eTRjdS8vY1R2bmt5dlhtCldBRHcxR0ozenNtUEFLaEgvdnpTdHNpWDkxVnVsWXpITk0vQ2RPV3ArTlZYcDBUTnpkTXpCdEFxM3l0STJXbWNKZjhrM3ZBU2FRK08KU2lXR25mTEpsV0JZMytPWFU5T2p3cFZwWitJanJrNkptcXY5L2M4TTZCZWtScTQ0UFJXSExoeWVWSEtuQjY0NXVDTEpPcjIwOHNEQgovT0d0aG9ZdFl2cGpHWE9xUXRwMEdjWjhQSHEzbXpjU0FONU8wTWxEdzErTFZnOFgvRGVWeG5XZEZpbmJYSGFmYnhkM3NJRE82T1IxCk53TkdkZUx5QVFSNDlnaDc1UFcyZkFlR2M5ODlGZUR2ZjBEelVLdXZIbjBFQUh3OGUxT3ZxVHdieW9hMFgySHk3UGdBUUJnNDZLMCsKbDk5SjBNbjdqM3pUcjR2ZjZoMm5uaUlnSUJER2wyYUNJSXNzRzl6Wkw2Z3ZHQS9HRVRDazNVcDlnWFpLelkzUVlWdzdUdDRHdzFpSAo0SG5qajZmTkxialFMUndBQWp3RHZ4Zys4NnM2SUNCby9xZDdodldOdUZHZ25kcitrWXNwby9hWTJnNFk2ci93d1FLL1lIZmd2R2ZICmYrR3Ird2RXeGZsU0IrSTZ2clR5QU1od0xIMXV4ZmJJNjRhbFR3N3V1SFR4L2g5TnZtRkQyeTE4TUhmcm80K1FaMThNQ1Ywb3dWbVAKWWFIK2Qzcmdtb01Ma293NHVBMVI5NTdVbmlOSXVJeUhwM0tjZFQrcC81Y3JsVUROUjZNOXdUaG9lazl1RDRDUlBBT0JjdTdZb1oyYwo5V014WVEyMTNSektBeUJpa0VCcUJzOS9KMThDSWsydnllMExDdTJ1TDNrQWpJZUV5bk1BSGd5Y0JZRWQxNDMyZ0FRTVJKTVBKM2NUCmdqb3NtREVaRE56UlE3dGczVHZsaVFHUWtFd2JQbEtYQWtZU0V3Z2NEOGFrR1k5TU1hY3huZ2NBbmtueXBJRnVBQ04wNnMwNHVCZUUKajJRdmJKSkRabmcwRklERXdvZ0JsZGtBM3pZWmdlNVNNNGpubVBzUUFKa2pKa3Q2OS9OZk9IMHFlSFR1Nlc0WUhRWkF3bXNLT2RpVQpsczlmcUZ4K3B3ZXVXYmdneWVUVng5UWpsNDFjeXNXbDVlYm5qaCs0dHRPRjFMd2toYm5icHUrVUV6c0JYTUlYK2hUbEJTd2I5UklICklGbGpmR0hEN29pa0x5YmQxWFY3R1ZDU3A4cEt1UTR3ODdaNFJTM0FESWRWRnpCby9iN2NnaFVQL2l2NGxHTFpxSmU0VjVkc3pTOEcKMEcxVFFucXVPaTFKR1o5Wk1Eci9yWVFiQU9qOHVTN3Q0N2NZVWhRWDBYMTdPWnNUQWpDVTVLbFd0NTRHSVBHTFNYY0ZuWXBYSmFYawpsNmNvYW9Ia2pJTDd0T0VuT3ZTZCtnZjZIUHErTURsUldhQTlMeHMvNE4yN0hsdDRPTVVFZ3VING1zOStXUXdBK2tQNzV5ZmMwTjJqCkhoa2o3YzJQeE93TnMvUGlDL0xUa3Jwdkt5T01VcitWRURmdjhxL2QrZzcrT0NwUFgzMHNmMlN5V2o5KzBMdWQ3bjI0eXp2ZVU2RTQKbXpwdTlvYlp1ZkhhL1BTa2Z5L1ptcCt2U29wVDV1V3BvaFAzLzFnMy9VNFBYWE80MCtaU1RZQ3ZKT0p0Sm5Da3Q5bXI4ZWE2Q2dzUgpVUzB2Mkg3WnM1RGV3cHNOT3Q3Ukpvd25xaFdPNjRpSXFNS3NwOW9LSWpPUmtlZEpaOVlURWU5Z1owWkVWVFZFUlBzM1ZOYlhVY2ZiCnpPWjRNcGNRRVprTk9zRjhqWGVzUzA4ODZZNi9UelhtQm1aMFZRWXpFWkdaeUd3azRvbUdWMXJxenhxSmlEZFlSWm1KZUtJcUhSRlYKRTFHbFJVOThwWkRYYWtOWFFoVVRLdXFQaVhRV20rVWZ2OW1nL2JwTVI2NEpGNXpKd0x3QkpoTmFSdkN3YjNoTHBHMDRBSEJqSEFDQwpqTE85MW50d1RDTDNZSkEwMkRLcVZ5SUNhQ1B4Z0ZzYlFBSzRNd1pQaVFjQXhocjB2N1VYQUQ1UktRZmNySHBDcWViaGJzSXZKbmpoCmhFVHVLYWdTRzZpSFBNRGdtWkJXNnlXeCs1TDFBTkJhTGdFQUNTQnhCeGpVZVZxdS9xdzdBR2J6MENrQkdOREtFMEFyQU42Y0I1aTMKa0ZkT0FFSGlaN1VXaEUzdDc4a0pEa2tCbHZ2U2tUNXRQZS8weURVM29LNjk0Mi9IemEzYzdMOWF4dWFzeGNyYzJlYitiWERGbVF4QQpvNjFINXJ4NWFkdlJaUFY1NjBONE5TR2tpWi9VV0tEVG5xc3RoWnh5TjlwT3Ric2ZvOFlTSFNRNGwyTk5kYlhaTk1kVDVPU3Q3K1pXClZYY1lMa2d5clVLalZ1U3pERldETWJIU3grNUx6dEdFMHY2SDFVYlpqMzV2Nkg3RTRmT3IvYnhEVXRseHUwQTZXU3dZblpIeitGbTMKL0Fsbk5lbzRtMnFIMVp0bUVoaGczQStnL0xpUWtUblVUZ3hnanVWczZiWUtxTUZ0NCtBdXI1NmFEaGtFUXk0R01MSWJVVjNNY2VWOQpmeGNrbWVlb0t2Y0hqVWhTT0k0SmdXeVJJc25KeE5BK1ZqeW9acldRVUpkck5aMjFqVnlHL2M3UDBFVTRUbG9GRyt4aTlGOFZDR1pvCkR0SGM2dVV6Qm1iOEx0dk9MZnVYR0l5SWdZaXFJZ0NvUHlGaXR1aWF0b1paLzNjeUZ5Wm03UWpab2kyQ3dES0lXVCsySmtkdHBmMHEKTUFBc1E3QU9aY3dxb3ZiN05PZnAxcFhnZ2lUemZ1cUMvNlRyS0JxdjBnRXdxWk9OcENwVEkwOEw1T1FYQVpWS2hxb3JoVUFDQWVEago4a0VnZFZ3RjhqWE0xdytLMG5JVi8rWnBRMCtHUEExalN1TTFZcWhlb0VLNUVpQkVSL0wreHFzQUpmQ01RSlZ1SUVyVVExRmFsdVlWCllFcUVueTlnVENVd1FIMmpvcVRzQmpHazFVQnB2RWFnelBiTXR5M1NTaFNNZFBFOEErbzB5VWFVRnFjaVQ4dmF0NjFJUjAvR1dFRSsKNnJMVDFNYXJGcUJVQ1VVNUV1TmhMNWRJQUpDWkNBYVdVNjBDakFvaVF5cEJsYWxqU0YraFJyNkdnUUc1VldtQUlaVkE4VHlVbVRxdwo0dkxySmlDdHBtcUJLbDlScGlvcXowQmVBYUFxTGVyS0Z5cE1jTlhaekFWSnhwNzZDWkxkWUx0a2t5dUE5OS9ZUDdSZzdQNXp1N05PCnJqczFmVis0SW1XbmZoWkZkb3JpdjVhT0I3RE1iMDQ1UTg0SmJjcVBtU2MvQkhEdFc4OFpaajNUanNXUG1hZldGWTdaOGZrQndLSkQKeWk3OVRERG9MRURNdHdmNHJXNFR3T2p3bnhuRUlscXZQWDd0VzYvcHdKRnY1aEdnUEJPL0ZrRFdDVTNzMDVIZnphRWQwaW1xTVRzKwpQMEJ2KzE2amozKzZPaVZxVGtIUmUrZ1hEN3ozeHY2aCtzVWJEKzdPT3JrTzVuMHY3U0RDd2VwUFRuN3hSdnk0dzd1M0FtMW00dXlPCm5SNzdZQ3YzTHZWTkFINjl2dk1ZSVQvOGx4ZC9VUDV4WTAzYUgvRnJyMDA0b0FBOEMzbWhINlIrWk8vejI1Ui94Sy9sdDdwTnVEcngKZ0FMR3hlL0Z2SW9kYmxQTDlhaCszdnY1RXNQUjNWa24xaFdPM1grTzJJRUt1WXZPWTY3NStYWGZpcE5QTHpuZWQwdkFuQ29mREc2Nwo0a1oyOEZ4Mi93Vnp6NFVkbDBuM2E1OFpWQlY3cG03bG4xcnRGTE1VYjZUS1N0ckM3Zk5sSTErNVlPNzVLdUNubHJlUnRRdnUxaG1SCkY4MDlYd2xlR0pRQStIajJYdnJNb09ycmd4SGc3OGZHdTZXY0xkQk1zVWpZMS92d2FXbnNtbWxybDZqbGJZQ0pvV0VXaGoxaHZ2MU8KS0lLR2JGbjY1S0VKWWQycmpuV2VJdzllR0pSdzNyUGovZXlldUtIK0N6TnlTaWcwS0l6WTRMWXJic1NIUHZESS9SZnFlcjNxTnUvUgorZE1ab2oySGV3MHJtclp0ZE5mdGdOUWJIYkw5NTcwTFd6bjBEK29QakV6a2Noa0ZCczI3NStYY01MLytQNFg1OVIvU2NlV0p5T0NKCm5zR1JGK3Q2alR2RHZSQTg3NTZYYzhKOCsvNVpvSjB5cU9OS1FON3Y0V0ZUOWNjRDV6Q1AzdkFwRzNDbzU2S0hMcGg3dmhJOGo3Mi8KNmZWN1hmY04wd1ZuTW1ENm12dWYyREJRQ0w0R0hrSGRHQVQzZ2p3NjlmUkpRYURzQi9rTHNvTHdrUUJXRFE0a0VIZmswRTVwcmpSUQpDa2pyd0FNRURtNjUwa0FKQjZtd3p2ZEpRYUFjTnNNMHVUWjhKQUhhUWlFRW03dFFDalJVQ3NpTW93Y0c5dTNDSFQ2MEV6eDNuM3ZXCmlLa2NCd2xmbVVYTXdnQUdDZjlZM2NtTllOYldNVWh6M1FJbGdOc1FBalIzVDJyUHJQb2VBRHo0MEM5V0t1emxUbTFrd0haTEtJSEIKZ2s2OVpNYlJBMlhHVVFQQUVOZ3ZCQVMzWExmQWR2MzZrZlhrSUprMmZDUXhFRWdDS2M4eWgwL2hBRHo5N3BPSHpWS3I5Ujh3WnJYUgpSWitWQUNRUmQ3b0ZUYUJMeVNPQmxlRkZTN1VUR0pTSE91c0hSQTRLQ3RsUk5halhoMkd4ei9iKzJZREhGMDUzbS96dHQxNURnRzI1CkdlMzY0dEtCKzdzL3RLTnFjTUNHUnp1dmxaeDQySGlnN3hkakJ1K29HaFQ0eVlqTHllTTQvSms5YTY4ZWt3SEx4ajY3SHJ5Y3N1ajcKYjcyR0FENGZWSjE0eXVOczR2ekF0WklURDFkZDE0WDViSGgwOE5LejNZWjI3WGp4d1AzZFUvTE1uUWNXdlZSdy8yY2pMcVc4OUswaQoza3ViRkx4OTRoNXY3cHZDM0VGeUtBOTExai8wdmZHaGtCMVZnL3Fmckl1ZmtiMXpldEFzMWYyWHIveHI2MkRsMlNsU3hKMG95a3gzCjh4dDVORGw0KzZRZlcxdkxuVHRlVS9pSUJGOTF2RFpoMk5LejNZZS9kTGE3ZnN2MGtLNGQ4VVZJK0k3cVFmZDFEV0ZmZHJ3MlllaXkKUDdzOThPMTNuaDVmVEc4Tnk1ZnU4cDFQVjc5VU1QNWM5ajA5dDYzSWVOUS9aRWZWb0U2Umc5cC8zNjc3eGdmblAzR25CNjQ1M0dtVgpReVB3UkdRa01samRHeDdZVUNra21nMTg1WVJ5SWlJZFVXMEYyZHdmMXBxSlNGQXFHWGdpb2hwTERTOG9hY3oxbmhONUN5KzRMK1R0CkhnNkppRWhuMWprNE82eXlualNRSUpPV1g5VGJzL0kydlJNUjBVK0NrOFBvRFJYQ3NkbEFST1hDYjFORFhaV2VOMWRZSE1zZDRXMXUKRVlkWFczamlEVmJsa2lESUtzdnExcEdNOXZxSkZ6UlplaUxlUXJ5QmpFUkNuK3RQdUNaY2IwM0dpTUdkbUZ3SXZrWUplUjRBR0NDUgpJRTV0SVFaNEFHNXRZTE5EY3dNeHdmZWdSTkQvMk53V01rZzg3RnZoakVGd3RzaHNocHRDVURWUDhuUndkdGdhQUlpUkhBQTRPZFZrCnB0NEx3TU1hc3g2dDdVdHI0NnE3ZXo0T2lzK3pxbklrRW9COGJDWnFqcXVqMW9Da0RSeks5UnJMckc0UjFYbnEzb0ppaWRuajNrbHMKL1JEY09zTGQzbEZieUM0UFlUdEZEbmRibjYwbjVLNjY4ZStLYWlYYmxlSzVKdE9kclVnY0xDc2EyeVU1V2FHUTFRU3RpY0d3UjErcgpOMDF5THR0VUkrMUh4QnlOcVJ3VkJzeXg2UTJFMWhzczJZdldXK0ExMDhZbWc0NDV0OWkxNElJa3E3Y3JhbDVoQ1diTDFkaHdxTEVGClQ5UDBhR2pGMU1DWTBabStqUTJtSEMySG5FUmJUVFdkMjNBYjYzTEhsam44cGx0R0hheHZzVXV1L2wyUVpBQWFtWlUxYWJQVzVCQTcKSGhHRE13OXZWYWZ6Wk5GZ3ltaDZibkUwVUhmTVptVnJrM09qUStzY3hUUjdEWno3N0tKVFZqTnd3UzJNQ29WQ29TZzRuK3VnMjJHTworbCtIS1FmbUtCNDI5Wjc2aG5QTUs2dldzZWtieWE3aElZY1NBQVBVOFFEQWJJR3lDSUoxbXQya3JtNmZnMm9vNHhJRDFEY0VBVUlKClJrREZFVmdkTVRJYlZSZ08xOWRlM3pxSFErZVBBb0FycFEzN0RDYlV6Z0RnZDk2cFJPeEJ5NTBldkNiaGdpUTdxTnI3bnZyYkg5TFEKa0I2Q0tSb2NFeGhxMWxxc3Z6SlFyeVMwSWNPeGFBUFUxWnU2T1h2Q3pMQU50czFDa3NGbXBtZHRUYzBhdTFNcWh0Ty9OMmlTOEtjMgp0K1FEUng1WmwzdDh3MlkxQW11b0N3ZHNia1FkdVZTemhyZnBYcDFhZnJpNkxCZXVDQmNrMmFRSnZRUERsd1hUTlFPUXBnTUF3Y3NtCjBuUlZDNVNxYksyaVNsMkFIQTJnS3F0cGh5d0ZBS1N2elBQMVE1cmhpaVV0SHloVXczSTVxM3FCRXBtSmdLb2tHZGVya1oxZkNDVEcKZ3dCYWRjYVFWcVkyWGFvVXZJWG0zNmlrdUh5Z05wNmlJMHY5L0dDS0k1aHkwZ3BSZmJrUXNKcnBxWlRJTFFEUTF0OXdEU2k3WEl2cQp5NFc5b0N3aVB6L0JSazBYendPd2VlNEVqS21velU2elJwMWo2TWxNT2FyQzZnVkttT0tzUk1sTUZPb0JBT1JvR0pURzY0QXVnUWR5Ck5FQ0ltekVuclFoTVdXemxYa1pwVzMvRGRTQXpFZWpKaE9zQ2dCSU1xUHkxWW5yWE96MTRUY0lGU2VaTkFIbXpTeGZlcEoyeXlSVUEKaklzL09QWWFkcmhOTHRmaHpQZHVUM3BjS05pZGZXcGQ0ZGlvYzZqZDFZcEE4Q3pBaHQxRmp4L2Q5V3JjSkJ5c1hCK3p2dWNlaXc1NwpZM2NldXpIbHdvdmZ4TTAvTlQwcVhMRkR2bzhZVUtkSDBkaW9jM09ESnhXTzJSRVpsWFZLbTd6VS83bHk1WTZjMTNVV2ZQeWpibzNQCk0rck5LMDVObzAyZDlnTUFOSWRHcFY3K2xJNWFBSUNkK0NZNi8vMlNkMmhUd0g2V25qU2RmYno3NnBTb3VRVUY3N0YrQ1NEVTZSa3IKdjdpb1NIazZQdUtMTitMSEg5bXpGUUEwWTdGNXhlbXBGaDEwYTlvK2swOEE5bDdmZVhUejhsTlRBUUM3czArdUt4eXpJektxOEQzMAppOStkZmZKRC9melV5QlducHVETlZvdFhNUUQ0ak0wb1lTZStqZDU3ZmVkUnpWalQ0dmVQdndZQUZPRzk1amdaR08rYUsyd1hKSm4xCklYUHZQSlhoV01hY1NvRGMrNDFmbHFZL25qR0hlZlorN29LM1Y2eGx3SmJoTTc3eUM1bzNBd3VYQnpJQUFaNUJROUV1NVBHbnVTYzcKVng3TUhkRmF2M1M2ajFmdjBSMjUzQUYrRXg3dk5LOWdjTWVsUzZMYUx4akpBTWphaFhRSm5qZmpuWGpCVzZqczg5SWhiNmhrSlR0RwpUbGpiMmQvdkhqcm0yelZzejlEUVJSek9majhiQUJEdzBzc0hua3F2NFRzREFNWlBVSGFjVVpuSHpuNDNDejJtRW9aaXFQL0NCM0ppCjBTOG9GQXd5L3hDNTc4UmhPVCtiZk1PR2RaMFdNT29wRlFBRWRNYlEvb3VrUHA2OWovbUdoUDNNQUJyZGllVU5EVnNrN0ZaK01Yem0KMTM1ZEZzNUl1MDc5ZzhLMkRKKzUxYTB2aG9ZdWNxTS92SWVHQTBDMXN0dnZmbXo4ZU5Xb2ppd3ZJTkM5LzRSbEtnQW91eDd5UktTUApiM2V2djN5dC94YTRJc2tBQUl4SnpWem1pS2tTZ0RFcDNIaE8wR1hLK240Y3VhNGRwRG5TSUNrSHdwalh5Yjd3WVJ3a0RCemwzejJwCnc2SVpVNGpITmtzb0VTZFl5Vm5RcVZlL3oxY3FBSUFzNEZEejRhT3RJQUhIYzRjUDdWdzFPSWpjcjBCTEJHSStLUWlVU3dERy95Qi8KWG1nTjNBWmozb3NEcksyVFdtSlBqaURMOThKWkNISGgrRWRyVDI4RUFCQVBRR0tSR2tlRk1wQmRmY29nRVQ1Vjgwa1Y5S2hzbTNtQQpVQmdBSkRuU1FDa2pDZjlvM2FtTmtPWklPN3N4eGdIRVZ1N3Y5ekFBdU1YeGxtSkFhdDdPaDRFQURoTEJhMmdXT3N2Slpnem9jbkJGCmtoblAzU2lyUzBsTTBwaUU2R3hVbDVDUUlJUnE2N2FaNXRZTmtZMmdOWnQrV1ZLcXZWaXF1VHY3QXdNQTZJNG5LVXJ5NGhQUzFPckUKNWVGTDJUdXRwckVlbStxK2owOU56czlQVFVqUEwxS2RWWTdibGo2cE13RHF2aU5OZlpGTDNGSjlOU2NoV1huankwbDl5aU1MYnp6MQo0ZHppb0ZPSzVOUi8rV3hMZlRaV2xhdEpYZmJnL1FBZ3F6cXVIczFtVk4wTEFHV2F4Q1NGS2VhZ3RtejVnLzlLVE10VnB5VXFybXR6Ck01SnVYUDV4VHdVQTlOeCtYcE9ibWZUMCtxZHlrOUkwNm9UNFRDT0FFclhxdWlwWHJlcXg2Y0UyMjFLZkJRRHp0aHNwVjFXNWFpVUEKck5uOHk1TFMzTVFrWmZ5bFBYc3ExMno2NVFWVFdrS3NLbGVqaW9vNWNnd0E1R1B2KzRUTFQweFMxdjV3STBXclRrcEtTTktVQS9CYwpzbUYzUktYaXBQbE9EMTNUY05WOU11dTduOEhESWNYZ0FlSWxNTWxxM1FHTDJiM0Ixci9GSVhvVjFVazVTMVZiOE9CTTdoYUpzSDFWCjljeU9OckJVZTNNQWlKbWx4RkRueG5NZ1Jud3RlYUtPa3hCcTNhMHVNNjErTmxtZDNsdW9wY29icUR6dW9JS3VsVmtrZFhwdlIyT0EKbng5eXp5aDdqQmlJbHdpN1pFYTVZM2RzKzJqRVdlWGJISlJhZTJJeEM5cWxueDkwenlnZFl6c0NERHRubDBRdnRWMERvWWN5U3dNWApuZ2I1TFhkczd4eGNUM2NKT094TmVqaW1lWUFnQVdUTUhZREUvbXhnTm9zeWUwWW1BMG5hQWh6Z0RvbjFZWHBEWFV1UStGaUxTTUVBCk4rRlJ4U1J5SnVoQXlSMU1HSE9ybjAxQlNRb0EzdmFvZFZaT3lDQ0JXeHZIZlZGbWVMdFB6M0ZnQUpOWVhWWFYrNngxc0V0Z0RQQ3kKRnBNNVd0ZEpyTThWL1Z0Mzl4eG5Qd0pNRnhJZkdDbmNUQjVDOWN3TkhIUGNBdlp3MWE5aUFWZWR5WnBUd3psb0J4M3ozcmJRLzZnbAoveXRadCtQdDg3K3EyR1duTWxkY2t6WGNESGZjbldUc3R0eHhOWTdUaHRzcDFrU1p4b1dFeHJBbXNqWjNiRXRtelluOGkxZW0yZmE2CjVvUUJseVJaeFJIYkw3THJVSXBQTlRBVnF3OFg1d0RoRXB1UFhiTHQ0VnVFNEd5T3Bwbm1mZmJOZXZPeFN3MHRNTTFISFlRMXl3UUcKZ0ZuZElXWmNkckw4QkpxZVQ0ejdIWGZ1Q2VmejdCV1RROHd1cXR0WGYwdVlqd0xJdk96WU44ZWZCSnpWQ09xME9OZzFXcTRKRnlSWgp5WWUyWDh5dXdjblk0c0F2WVdDMTYyMlpyRE9kWUw2NHh1cGtrWUNJNFRGb0VKRVFwSHZYL2dLMlpuaU16ZUt4b1pGdFkwMk9zd21lCjRkdHNCbVRRNmQrc0NxTzZmTmpuVCtZMGoyWUFxSXBnRGgvOE1OTTJXMVFIQnNhWVhUM0VxdGM0dElXUWJsZGFXZnVlV2YrVHdmaHQKanMxZzFKYnNvbE9aQzVLc0J5dFNndUx5Z0tSNFFZTUQzSVhzRWxCV0lpRXhFYXhRUTZpUWNRQk1taVFqMHNyeUtFZERRSUlCbXRQWgpid05raW1QUW5zbCtDMHlWVzZDc3pOZFFqZ1pRbFZlMzQ3SVVJQUNhMDlsdjE4WUJaWVVLVTFaYXZ2RUtMKzJPNHRMckJqQmxNUUJXCmU3a1NCRkpsNmlpSkJ6SktpWEswZ0NyVGdPeU9BS29YcFBVa1pRRW9Mby9lT21VQVdHMENVSDdaeEpTbENrRlhSQWw2cEwrY0I3UnYKVzVGQk1BblVLc21RQlhIWDlEQmRyaFJpMmRFTkk2aEFRN0JvMmdMSVY1UXJDaXJTSmQyckY2cDZrcUlJbEtPbTNEeUR3aGk5dVJTQQpLbE5IaVJZZ3N4T1A4bFNnclIrejZiUmNkQ3B6UVpLaC9PS1NvcGY4NWxUc2xPOERPL0ZOTkFEU0hCcWRzdS9xem1NN1BYN0Z3Y3FQClR2MTJMb01IOE1GckI0WVdqSTA2LzFQT3lZOFIwV2JOTVRMeElCald0SDFhelJ0NUJweitUanJONjFMeGo5a25CVFdVYVZkcllnVHcKSmw2M3h1ZVpqRVdibzc5Y0ZULyt5STlmLy9HU1lja0hNYS9oelZhTFZ3SDBYTkFrTU1ST1BKaXlsWnVBejlqTXNwK3lUNnk3UHVGZwo4cXEyVjBDdzZIbEpadkpzTFBWN3JsakhNVUMxSStlMS9QZEtJcTVPaTVwYnNIbkZ5YWtVNGIzMnVLY1dBSm1qWHR5aFBIVmpEWUNmCk03ODZ5czVmV0lXNWdaTUtIOSt4SlFxTHU5eDkrRkQxeDZkeU5yWktJNkRxZWU4WFMvWEgvbnpKVWtOY1JzcE0vSlI5Nm1PMjBQMWQKcGM0QzROckU2SlN2dVltMHl2Y3lsN0xMT0l2V0N6b3RyV0NrNTRwd1JaTDVUaHljL1dhYXJOaC8za2hnL0FSVjZ1ZGZvTk5MTDBlSApCMGp5L09lTnBPaThoNzIyUGhyT0FBd2EvRmJ2ek9CNU16NGZQdk9yMHRndVQzemV1ZFhkSno0L2NMUnRTTmllenEzdVBoRjVZTzRGCjc5Wlh6V0ZiaHMvOHlpOWszZ3dzV2g3QXdJREFWbmNmOCtrYWRpQTAvTFdoWGFaMUh2V3M2bDdtMFcvOHNqVDg0VDBrSEdDckUzUUEKQm5kWXJpOG9uRkttN1BhYjcrZkRaMzRWMW1HNXlhdmp2OERnNDNFWDMzMktHVyttdVZmNUI4bUJiU01uck8wNHN6Sm5xTy9DQjNPRwpoaTZXbEYwUG1SWVo0QlVFTUxlNTMveTB4K1RiSDhDQllSK05vdnZucXZCT1lrMkhvSVV6MHFxVGZRWStjREIzaE5mT2UwTjZNY0xkCmJjdkNEbDFhZEE5OHZIcFR0eWtXZkQ1ODVwZHR3VmxqeFExcHYwSmZXRERsRDYrTy82S3Y3eDlZRlRzTVEvMFhQSmdUUjZGQllYZDYKNkpxR0s1SU1rRnJlSEJ3SUlUYWIxTnkyYjE4d3VBM1pXZGVQUXI5WW1hYnBNNm05dGxENGNNWXNHTXk1NVVvRDVaa1VLQWRSWUw5dQpQZ3AwOWdBaHNGOVh0NzRmYjE3ZkR0SmNhWkNVQUR6MnVuMXQ1Nk5Bb0p3eFNCZzRjRVFFRGhJZUsvYUhQUXpVckJzdDJBUkFwbjFrCnBGc2NieW1XNWtxRHBCd3FzbUQ5YUljak1MdzVxTFB3UVk3OENqU3hNU01ZR0NROHg4QzVaeU5RRG91d1VISWJZZzBQVjZ6bDhobmMKek5VZmp2WWlEaHkxSG45c3ViZTZ6NlQybFZsQ0ROK24xajU1MkN5dFgwdEtjNlZCN21iQSt2a1lCNWttZkdSVkZtQnBrNHhBT1FNeApKdUVmclR1NThVNlBXek53UVpJbGEzSXpraXMyRjhkOXI1cmtya2xNVkxaN2VMaDd6VEgxeUxydENhbmZxQ1oxWEI2K2xIdDF5VGZxCllnQVh6Z1ZMdFJjUnNYSHZFcThsbit5T3lFcUp2ZXZoME9GdHRpbWV5VXE5ZnRmRFlaaGJOOFJ0Qk5aczJydWtSSHV4V0hOMzludXAKdzNrZ0svWDY4RGJiVW1jcUx5SXhUYTFPU0V5UFZSY2xKU1NweXcvRS9INE00QksyNk5PQjVDek52ZHJ3bU5aajcvK2svWnFOZTVjawpaNmtmVmIrVkVBZEN0MDN4NmJucXRQTElraHM5dHBjQlQzMDRwOVJ5NHFEbVRFRmVlbEtjTWpkZnMzakQ3Z2dZVGtBSTl6WjcvZXdjCkFNdEhMZk5RSkNacHFoTzM2Sy9sSlNZcFRQdCtqbElzQzEvS3pmbCtRM0U4Z0hIYWV4NGNnR1IxZWJkTkNXbTU2clNJamI4c2NUTisKbGhVYmRDb1ZTTTdTM2xzUUhqTkcvWFpDM1B6THYzYnJtNlNJMWVhbEo4VmYyck9uOGs2UFhkTncyYjJWT2s1aXFXbHRENjFBMWQ1QQpyY3lDbWxZUzFFbzU2TjFObmtCMCtnTEJVWnlsVGs3TUlMZXZmSFgxSHlTWTNFM3VBRjlidi91K2M2WlYwVkhUQ25EKzBOcXc4Nm1TCkEwdUZXSEhXL0FZUDRaL1pMTWlvNXJ3QTJEd0kxakdwTlloYnJUdHFaV1lISllyZWcxbjFYUlUreENBb21ZenVRazIyQ2xMejdpazYKTjZkV3lzRmNKOFNsRTFvTUVBbGVjQzIxSGc2eDRtd3RxdWE4SFB2NTB3aFpSdW1ZT3oxc1RjSkZTWGE3bTlkcjg3ZEliMkUzMGxocwpkVTJuaHRrYkZLaFkzdnFCL25mLzVaWTBuN3M1NHc0YnQ2OXU3akwwbm82M1ZWMlRsa3JXWDl2UDlPMDVUZ0pYaEl1U1RNQk5iZEthClRtbmFuS1NwVTAwbC8xWEZUTlA1LzVLVXBtK0tla3VxMjY3Y1paVktMcmttSTlqMndGbTlSb2dFd3hFblY0V08xbzJ3RjNKTVpPUmcKb1dIZG15ZW5zdldwdHhvbjV4MWFaM09wQmxvSndQNk5mdE5pYkpZcXJQRW1xblZ6OXFiRWFianI2OEljK3o4eGt6V3ZLLzd2cm14VApabzYzTm5Lc2YyUTV4TUs4bWNuYVRVeUpHODFZRFEyVm03YysvUi9xN2Y4R3VPQk1CdUI4RGdCbmI1MTJtQVdkSkFPeDB2M1pRbHI5CkZHZU9zamdvaU5KVFV4V0tJZ2RiTkp6Vk9pdS9tV01kRE95OHplYm5TckZET1lkU1pQOW9CMm14OWNVZEpsL1dvSUJ6QjhpeGEzWEgKTDlseW1JOEpxc3JNeTlidU9VK005blkwd1ZxSUpuRi9CUm0xMjlKdmRuN05RMWIxSk1OSHd3OEthZldXWjdxMXZNTUQ2S3ZTTWRxRApzUitTL1ZsbTNKcmp0SmF4L2wrWFkwMHcvV0NMaGNVNzVyT1d5bWc0WHh5dEQwZG50N0N6RldpbzFYYXdkS3ZYOGdONDk2RVlXMGFoCll4azQ5WnMxV3hNNlZVRnM0K2NQQXc3WFZJZ21jYmVKOUpXRlFRNzJjQ1oxa3BGVVpmbVVvQU5NTndpYTB6bHZBeWhMWlVpTXIxa0sKcUxLMXlpcTFGamxhZ2pKVDJoNVo5ZTVtMzM3QTgvNVgvOFVWSzhHTUNnQ1FCeEpNY2J5Z3BvU3lHTXlZQXVRblZLejZ3d0FBcFJudQp3Ymh1Z09saUpYVjFFeXpkWUkzS1ZxNUE5UUlsR0VBSmVwaXkwd3FwSjhxVUpYcUZCWUE2dmhMR1ZKaHlFOU1VbEYySVFnM0lhb0VYCnB3YVM0Z0VHa3piWkNGVlpQbkswWUtZNGd1WlU5dHNNb0VROXRLZHozZ2FxRnloN1Exa0VheEE4NU1kVm9VQU44RmN6U3BSUWxBTUoKUEZTbWEwQnRQSUVTaERrOFFZL0tYeXVlRUUzaWJoT2VCV0FYTDc2Sm5XNlRLd0M4LzhhQm9RVmpvODVGZUw5N1hMZkc1eG0xRUFNdQpaYmR4RnZTTUFQenh2ZHNUSGhjS2QyZWYrT2pheEdnRjFlNXVaUmZXQmlEV3V2emk0aUxsSC9FUkFBQ21pMmo3Yk1iaUQ0NExha3JsCkh3a1JXYWZ5NC9YRUFQbzUvYXNqM01VTGIySnVsMG1HK2FsWHAwVE5MUUJ3ZFVyVTNJS1VYWVpaRnNFUU5NSjc3ZkhOSzA5Tlk0RDcKRTdYdXYwaUFyRlBxWk9XWitJaklaZnRpMzJOL3NvTVY2MC9zOHRnSEJpejFmNjU4cDhjK0FIai90ZjFEdFdPaXp1M09QckZPdDZidApNMnFxNVFFZ292WGFHTjdFQTdEb3dLVW56Y0RCeXZVbkNjZzZyVTArVkxYK1JINmtmN2pQVEp6ZHdYOHRuVkE0Wm50a2xHcEh6dXY4ClZ1bDRXM3ZJY0tkSHJqbTRJTWtDUElOdy94eVYvbGo2M0NxQUJnOThxM2QyOE54UnNTSFRJby81aG9UdENXaDE5OG5JNksvdUcxaDEKclp0MzhQYklhODllOEc1MTNUSmd5L0NaWHcvb3VHSXdMVjRXNkNpUEFMK0pRM0wyR0h4RGhjT2pmaUZoQi9xUFg1NkdQMW9QRGQrago5dzExanl5LzN6OUVEckFEOTFnMWkyOG42RHo3WXFqZndnZHlBQXoxVy9oZ3psZjNENnhLOSt3TlVHbHN5TFRJb2FHTE9BQmVFZHRQClB3VkFGbGsyZEkvUk4zUlk2T29uOC9UdTdhTHpSclR5bnpzU0FONVV5a3I4NTQyRXRUZFpYZWJOK0h6NHpLK1Arb2FFN2Vuc2RUY0IKcGJFaDB6WjNiblUzaE1oMVBhZnlPSmc3d29zQnNzMWxRL2JualdpMWEzUzNibEp2ZE1DZmhkb3B2c0VMWjZSdEd6bGg3WjlhN1JRegpvVFMyeTdSSUg5OGVMaHFTeEFWSlJqd0FOek9YOGNoa0NZR0JSMUIzeGp3eTBkbkRKd1ZCSGlBSzdCZmlrNExPbnNSWXIzNytzcjRmCmIvNjRIYVI1MGtBSkE3aEhYMnNnamdONFNNMHk0K2dCZ2hsWjJ4UUV5amxJQ0NzUDlIOVlaaG85Z0IwNXRFUElYVnpBMU9DbFp0MjYKMFI1Z0FBZXBSYmhPRXQ0bkdZRWVBSUhKTXhIb3dWazlzVTgrbXRnTkFEdDhhSWU3Y1hRWUI4Wm0vWHNBMDl3OXFYM29seXVWQU40WQpFa2o5djFpcGdLMDNnQ3hYMnJsdENnTGxndThNajB3RU9qZ1c1a0hJN3pleFBRSHN5TUZkMmo0VDJ4ZG1nd2Q0a0V3YkhzNDRTSGo1ClZkTEtDc0xEd1NEUFlJRWV0MzJCLzNhNEhNa0l6SEJZbVppa01VMFk4RjVIQnVEOHVSQk9lOUZ6eWZvZjN4bnVzejNsbWF5VTJONFAKaDgyLy9HdjNQcGRUOHU1N09BUno2NFpJUjFERVo3OHVTY25TRk9mZm5mUHUrZmR0OGxJS2ppTzVJRGN6ZWZiNldUbGdxRk1sRFBmNQpJWFdXWFUwNWUvM3NuS1N2SnQzVmJYc1pnT1VqbDdzcmtwSTFGWWxiREVscFNmSGF2UFJrQUFuYXZQU2srWmYzZHV2YmJSTUF6eVhyCmQ2K09VK1pxVkttS1dqelhGUUNTdjVwMDE4ejFzM0xqRTNSNHVyQW5MUXRmeHYyZ21oUkFRT1hta2h2YjBpWjFCb0FMNTBLazJndFkKdlhIdjh3KzEzWmI2YkZieWRXTHdYTEorMStxczFPc0EwSFZUZkVhdU5tMzV3OHM1QmtyK2NrcXZaZUhMdWVmZTJsQ0JzRmV1Smc3VwpQbkt5S2k4aFNUbjkvZmtsOTJyQ1QwZ0JyK2MzN0Y1ZG9UaGRkNmRIcjJtNDRqNlpvS0d6MlpORnB5OW96YXhXWHlDOWwvMDFUdWRwCjMxNHl1ZGZLQUV1ZHUzMjd5bVRUVkZvZGlRRU1na0lReEtEeklvREJzUE9wMHYxTFlaU2J6YnludFZxanV5QzF6azFRUWpxNmtpSzkKbDAxamFUTkJJMGJzdStja0FNeG0zaE5XOVNSTTdrQ3RsRFByQk8xckhaTmFhbHB6UW0rOEJYMWtuVHVEenNzdXY5Nm1UZEJZRXF1VgpjZ0RNWm9zWGFxVWMxVXJEejZCYTRzRmdrQXZ2Tlh5ZE82QVhIcEZHZDlmY0lnUGdtaVp4MXFoc2dqMFpuNURuSWJ6TGV3QmdYckR2CkFIalY3MWU2d3czRXJPNDhRWXpxM1dNS3UxaldYRUlLTVUraG1PbEMwdjBqQVRta1VudTFjcXRJTjBnYk9INENBNWlYa0lCNkV6UUcKelZNUlFqQTZLVURNNmxMVEhjUmtnTlJxVU9kbWMrbEpDYmtDUTBnaUFUSFArazA2RC91V0xHT0NHa0FHbTFqSUFPWmVwRkgyYnNWQQp6UFlaQU9jT3E0OVNhK0E0RjkyTGRjbVp6STViS2hWdjM3M2RmM3Y5bmJUY1RlM3lOMVdnb1RKYlNHN0dQV05EWFlLRDNBWmFnVVoxCnVTcXhIT0hTSkFPYUdNcmIrRTdoZG9YK2IvVGgvNUdvbXduNnY4Q2J2d1NYVy9nNzdXYVRUVUhqZU9VYkdLODFCRHVyRWNxZEtHNVMKWXIxeTNIejBFZ1BxcmM1dUxWdVl6TEorcldwQ3NIbWZ3MFo4MnZYYnNSc2lBR2UxOVJLc3lyS2tWSU5Pb2Nqbm9WTGtvMGhSY0J0UwpxQmd1RFJja1dRTXdBRERuTnZSOENXcmdyZEJ4UUkzZlpRTUFHYjdTMmhSSkdZNXFuSHFxcmhuaHFNTWhBT25DaUZFalQ0aU9uenNVCkhBZzUyN0IxQUpBdTJPNVpKOGlqTVEwVlF0WThqYnRtM0pwanp5Zm9sRFRQOFhXejgrTVhKNDVJMFQvaURaK1BXamZ1WTZNTHhNWlYKLyswRDgxZmdnaVJqbE1DckZicWliSmdVTU9Xa0ZkR3FNNGI4RzVVQThoVVZpb0x5REVuMzZnVktxRW9Vb0VJMUtEa2VWWmNMUVFrVwpJTE85WUpmcDJia3VnZVdxRFlyYTZNaFNDTFp6VEZXV2oxd05ZSW9qRW16bnFoWXFlMEZaQkxxUmgralBTeGdnNmFaYklKaXVaWmJDCmRLa1M2WVlybGpRMVlGSVFnTHI5WlYxN2xlWUxqaDVMa3VsNk5RQWMrSnozTjF3SFdaVThQUW5sbDJ1aEtsUHI0bmxCUDVRVVg3MVEKQ1FCWlZTckFHRWVFWEEza1FRQUVwWkRtVE03YkFHYStGaHE2aWUvYVljeUlYN3EyOTRic0hpOFFUSnJrV2lCSGErcy9UQXFDTWxObgp1Mkl4WFhZQmxPaWl0a291U1RKK3EzUThUZk1zU0ZPZWpsdXplY1dwcVdZOWNrNnBrd0ZVdnREcXhUTEQwYk5MelRwMmRVclUzSUxmCnF0YWYyQzJQNGpjSDdPZTNTaWZTS3Q5ck5yWHlrVy9uc1FXeTkxTDBQR0JUVHUwN3Z6dno1THFhdFcyZjBaTEpBaEJmQTVhZU9BTkwKL2VlVTZTMGNBWDh1cXhNRzd6T2FXVHkzeTZUaU1VZDMvVHR1SXBTbmI2d0JRQ2FZeCs0L3R6djd4THI0S1JkZS9EWnVQZ0hRVzRBVApYMGZUMTlKeElEQ3cvUGRLM2k0Y0cvWGJlK2dYZjZocXc0bGQ4bjFtSFNOQVBmTFhGMzZvZWRmbkdlMnV6Sk1mV2ZkRElyelh4cENSCkI2Z20vaTRndUErTUdlY21DdDZZaVJnK2VIMy9FTnFWZldKZDFmT3RYaXd6SEZXZXZySDIrcVJvaGUyS0tUN2JDdHJ0RVhXblI2NDUKdU9BV3hwOEYycWtkSDdtVU8zMU5tTC9NVDdmb1I3ZDJYVnBITGhzRm9LOTNlVmgwejBWbXZxMW5ML2d2VE04OU1ITkU2OXI1YTdtego1cFYvRm1pbm5QWHFlQjlaMzhUR2h3M3dnYVFkNitUckIyQ3d6NG9iV2NIejJmMFh6RDE3dHdrSi9lbmwxbjBCNXVQWnE2akh0TS94CnVrSlcxdEhmRjhBd2F1dlpHNkJxWmZmZjNkNk8xN1hyT2k1b3o1TzdLL2VFK2ZZSElBdHc3eEE4ajkxL3dkenpaYi94cWs3amRqRmkKQ1BEMzR5YTRwZnhacEoxcWxvSVlPczVJVTNmb011OW9kcitnc0Uyemg3ZnluYisycldjdkFKMkQ1Z3g3MmNlbmE5aFAreTVZZXJ3QwpDNERTMkRYVEluNXJmVGZBbUJzQUFpemxSOXlORnRzcjVhQTJLMjVjK3VLQ3VlZkxiY3JEb25zdGVuK0FYNy9CSFZiWUZxclphUmY0ClA0Yjd6WHZYVlY4WlhIQW1rMm5EUitMRno5eEpaaGcxa0FNNEVIRkhEdTBFZ0dmV1BublVJbVVjQURCSXpacStrOXFGYlZtWjhvUDgKQlprbWZHUmxGZ1RIK1F6Z01FUnVCaXoybDFJaG5GdU9OTENORXNIeWhwL2R2RFU0a09jY3Y5UmlzbGkrcm1qZGFFK0FPQVlKdVJsSApEd1JzbjlxNjVVb0QzVGdtSWJKdVZZQklhcFpwd3NNQk1HSnhKMGZ3Qkl3eW45NEliWjlKN2NJK1gybjFUR0JoblhxMVVTQlFMczJWCkJBcXUwK1NaRk9naHJBZTk3anNQTXBSU3E4RXl5QTNFckY4YkVRdnFKczJWQnJvOXUvYUpvMmFwekRCcW9NTlhjTDl0blBiWkZvUisKc1ZMcG1oeHpSWkxkcXdtUGtmYkNLRFo3dyt5Y09GVnV2cXI3OXZOZlRyb0xBTVpwNzNsZ0FKTHl5N3R0dXFITlMwOWU5c2hTN252Vgo1SGJMSHJ6djNvTHdFMk0wYnlYRTdsMEJBRDMzL1Q1ZGF2d3NLeTd3VkNvQWR2NWNGNm5tQXRaczJydGtlSnR0S2M5bXBWd25BTjAyCkphVG5xdFBLTnhmZkNEeVZDbEJTZmxtM2pRVEl4OTMvYWF2RUxmcnJtb1RFdFB5OHhLZld6OG9GWUw1MnBkUnFncWZLejB0SnpNZ3IKQkNIbzlFVk5VcEp5aURiOGhCUkFTcW9oSmxxcktyaVFlUEduUFpYTHdwZEt2aytiMUtuYkpnSmdPcmgvL25EdmJhblBydDI0ZDNGdApSandBcnlXZjdvN0lTcmtPTUVTdTMzVDRncy9wVkMwRFhvODR1R0VzQU1LNWMxMDZyTjI0ZHpFZTE5Nzd3QUNhdlg1MlRuSlc5cFBDCloycVhUK3BZNFA1OTM2c21CdHpwb1dzR0xybFBadkFRRkRNMkpRMHNxT09GclcwSGF6R0FHTlZKSkJaZEs2NU83dzFtOENCV3pYbVoKOXp3RkFOV2VITFBha1JGcllEdm5ZRWhHc05xMW1TRzFtYmpaZ2pvWlBCek40dW9iVXkvRzRWRGlsRWZ3b0xobnVGdG02WmhhS1dlcAphYzBKOGtjYzh1S0VCamlJTU1vRS80OEFVTjdLelpiTWwva0RzQm4rV2Vyazl2NGI1ZGJMVlArQXRPcXRYQkV1dUNZVEZFanVBT3lPCkNpVjJSNHJ1VnVVUXM2cUxaSURFMng0MWpxRTFVRFFKZ0JEeHpjME5nQVNNa0pCbmxTV1JBR1EzVm1RMllrbnJnMFBZcG5jUHdNMWEKci9CVWMyeWl4Tkg0akpqdHlKNUg4S0JvV25WM3ozR1FFU1J0clBLdHNkKzhHb29RaWduMXQ2Mlh5d2tjbzRSOHVTMi91OE9GOFlEagpsb3hES0RwWGd5dk9aRTNFUTJvY3BzdFpWOVJJZ2VOYzdIWnF2ZGxaNXdxYXMrOXdzQ3l4NmFLY1F5bzFVNlh6SVpyc0tHemg2QnpDCmdqVWZWODRsNElva2M0eUIxYnhSWWlNclNxY1J2dDFBWDJqbUpEa05KSnlDeDkyazlDMVZRemNuV3BPRXVabk0vOXh3OU8rQlN6N0cKcmZjbGlEbUU2NEw5aCswRjBDSEpabC9KSEY2Nkd1Z0loR3prcktDQ2d3aXl1ZGR6TEdVVlo5MFhzV1loNXpZNWVmK3Nielk1V2w3YQpyVW5zYzdFMVM0T3UyNzBtTnJ6OUhXVTZWZXJRSVpma21DdVNyQzZxM3VMTURyc08weUhLbGUyaVh5NkZOYWdiZnhSQXc5R0pQY2dUCnlIeEpVMWF0VXBReFU2cWlITmtLdS9xUjdBYTVKSHhpQXdLdTJuU0I5azBOSmpTSENmUTNSeUh0bXZWTTJuVUNVaEtzdWNsdW1rY1EKVGpKbU4vRmxkZnRZZzM0eDJHdTFHVFNUN1NhaEp1emw0WEFicU9QSXhrUFdpSFl1Qmhja1dkVnFPTjM5OVRGSFlQdmpNQUtNTEFBUgpZeUNla05Id2RqNWNYWjdEOE1mcm5WS250ZHEwOVdDNDVlanIzbWoxU1N2WUdDUjhRMDBDZVVtb3lXNjlhRGVuQkFDa1c1K2VxRjZOCm95ZXNKNDRmWThEQk05YmNqRFZvNFBGandxd2t0Q2lqWm8zWktpL1Qxam1IZTRmWlpxdE1vVXdqMHpkV3o4OE1jcHpibUZXZ2F6NHMKWFpKa2ZyNWd1Vm9JOGRMMDhUd2pCdE9sU2xndVp3R2dza3UxQUtBcVRjYjFhcGd1VlZJM09VdzNnT0pDcGJSYjlYeGx2c0pRa2drQQpPUnBVL2xyNVpGZFVMVjdYNVpIWFdVaXZPWFZYdW9kSTRUK1lBNUNUWHdRcVQwV1pvbEtSYVZMVVVTTFAwc3J5QVhTVHdhb0l6Q2dGCmNyV0NSVnowNTJXcThqemthdURyaTU0QXBldUFuUFlBMEpzbDFKb1V1VkJVd1dZOWx3b2dwejBIbHNCYlE4MGRqT1Q5amRlQTdDU2sKTDg4RFFQRjVLQ2xVd3BRS2dFdzU2WVZBamhicEsvSUJvQ1NMa0ZNQVVMd0JRb1M3UWpWTXVZbklURVQ2aW54ZmUyQTZBbEE5WHdsVAo3SjBldWViZ2dpUUR3NjZzRStzS3grellIRlh3SHZyRk0yQnU4Q1NzNzdtSEFQWDdaZThBdURIbC9JdmZ4TTNIM09CSnhnV0p1alZ0Cm44bFlzam42ejZVV1BYUXo1ZW80Z0habm4xeEhSaEJ3dnJzVWJEUlFkYm5xWHZ2c2RHckcva2NVcWJ1TXMyUlB5SDQrS3Z1UmZTT1oKVURBMjZoeWduNXRpTldEN2pNMHMyWjBkcys3cWxLaTVCVHBMNGRpbzg3dXpUNjRUVm1tNzNDWlhiRERIZ1FpNGR1aCt5U2ZuNkZjUAp1L1djY1JiV20yT0p2cFpPb0UwQit3SFVXTUJPZkJ1OTk5cU9vNTZGQUxEVWI0NTI4ZVlEeWpQeEVRRGJ2UHprTk96T1BySE9zd0FBCmZzNzQ4dGp1N0poMWlHaXo1dmpKNlZIaGlvT1Y2MDlFTHQrMzQvck9vNTZGV0c4TFRJZStDUUN2UTgwYTMyZlVkM3JvbW9aTDdwUGgKaXd2bW5xOEVMd3hLa0ZQL29EQUE3eVRvWUZpNmxnRWRwNmZuQXhqZ04wSFZhZHhPdkpPZzgraUhZNzRoWVFkQ0gzakVDQi9QM25qZwpVdUo4Z0cyNVlPNzVTdHNlbm9DNzlhbWprOGN4bVFYQ2MyVlErNWRZVk1FekE2dVV6eDN2dDJQRUUrZTEyaW4rd2ZNWTROa1AvdlBlCkJWQ2w3UGFiYk1zRmM4OVgvQmRtNUFTMDYyUFZXcjRDZ09tUEJjd3BPdi9LdzFjWmlJWXN6YjY2ZHRIWW5tN0FVUCtGR1RtN254bFkKZGY3aXE0OWNQVnVnbldJNWExNEpJTURmRitQZFVoWWtjWG1QZVFZQmVDTkZWaFA2d0NOclEzMURBUXpUTGRxTkxSZk1QVi94Q2dKdwo0S2VoL0VNWHpEM254SzZadG1aWHg2WGMvblN2RWEyR1ZVZFVKTEc4eHp5RGh0NFk2cjh3STZjVS9ZTkNnVGFldmFOOFE4TDJ2SHluClI2NUp1TjVNUmlDNDVVb0RwUnc0SVY0YVVQUGhhRThzbkQ2RmdOaFRJd2dnY09BSXJHYmRhQTl3NUpNcU9PWUV3SUJYMzNmakFFaHoKcFlIQ1BUUTh2UnhRVzZoVEdFTkhOYWkwTFFCR0NPalZKb1VDNVUvdDVMMSs3Kyt1SFRuUy9uWW9lQkoxaXlOTGtWdXVORkRLSU9YQgpnd20rTlNVZ2dNc2NNYlZXQ2ZBRXhoaDgrblRxL001RUloQUhDZStUUW9GTUNmQXliZmhJeS9jZUx3QUFNY2FrNXUzbVVPdGE2ODBoCm5Ra01ib0tiVHpDU2tEUlhHaWlFbENzdTRQS2x1ZExBVnBrSWxNT0NnSjZhdXlhMTQ0RHQ1Z0U4U0FqWUk2RkhhMDl0Rks2YkxmS2MKQzhMMVNNWks4NVFSRy9jdUtjMkxUMUhFWHZwNVR5WEFFcmZvTTk3eG5zWUFQdWFncGhSTWxaZVhtcFNSVTV5d3haQU9ibmliYmFtegpWQmVSckM3dnVwbUNPejBPQWlJMjdsMVNxVGhkQzBpK25MUDl0MkxkMVVzMXdJREFyL2QvT3hrQUZHY1Y0eFpjM3RldGJ3ZXYwYysxCndUM2FSMDVVYUM4Q01LVWxmYStjRkNBRVpXc2ZzWEh2a25oTlhscFMwTW1MMm90WTg5bmVSV1c1eW1RRk4zN1EyajZQTC9vdHBSWUkKdUJMVHo0ZGVrY2daUTZJbU56MXB3ZVY5M2U0ZnUvaTNsSUdhOEJoYThjQjlBSUpPWGxUSEp5bE0yMjZrMU9wakFGUnNMcjJtdW9qWgo2MmZsQUloWDV1V3IxbXpjdXdUNkdBS1dqMXptdldiajNzVmV6Mi80TVFLcXM2bmpsbzFjS29sUHFERnZpMVBVNm1PU2xOZTF1ZWtKCk5pZWUzVFk5MU9ZSElmS2NDNEpjRFR3UjhXWUQ4VHdSL2FRcHVmSTdFZFZhekx5NWxJaUlUR1IyeUYzTG0rbXRFcUlhNG5tZWVDTGUKUXZ6WHdqbUxnWGppaGQ5RjllSU5sY1FUVHhVVHlvbDRxaUdlakVTMVJMeStYbXhkcFlVbkl0NUF4RnNNMWtTaFhyUEIya2pTRTFHVgp3Y3dUVHlZOUVaMU5kZWhERFU5VWFUUVQ2WW1NbFE3bHlVUm1NaE5QeE5lWmhWNGFiYTBrc2hpSUxFUkV2SkczMXFVbnZtSkNPZkZrCnNsakxXOGhNUWtuNlVWMXk2VEFSOFJhaW1qczlkTTNCQldjeUFJeVRDeHRNeGxVL3FCOER5STNqbU1RWGdFMHJhSU1iSzM5K2lCL2cKQldZMUplTU9UbnJjS2tsT1RIQy9ST1J2YzQzRElQY21Cb1o0dFpuQTRBVUdkOEFOWUE0MjJOTFdIQ09BdVFPTWM3ZHVvd29CVERtNQpiZWZCZzREVzdoSkdEREk1OExqaUxudHdGSkFYQTNuTEpJQUh5TDAxQUpDMTNUS1NrRVNJSlNjUmRqZGtEbHZBN3J3d0pzeWRBUkk1CkFSNWdOelJtTUpKeEFFQXl3VmMzWXlCQzdWcy9GSTRHd0RqQVJlUDJ1cWhheVFhYklzZFJwWEl6RDZ3TjFUNjNZVnZrNk12TzZkU3QKVzlWSW5CRGlzajdOUVVYVXRKYkJ5UVR1MWhVMzFVQW53N24velpYLzM4SUZTZWJrdS9EbVYrNzJyNnBkcjl5OEdHZDNzN2V3OW5TNApCMjVheXQ0aFovYmZyZ3ZKMnlDUWE3TExDdGQ3WElJNWJla1R1NWdMV04vSXp1YzZaM2E2UzRnQVpEbWF1Vm1qemduQlRFbFpGK1VVCllLNWVROVZRVHlxMFE3Q1lzMVlpV0xEWkZFV3NDZEptWHJGNVRhdzNyV00yWFJHcjEwWUpIYk8xMTdsUFRxb0doc29qemVnbE5RcUYKUWxGNVB0ZVZPZWFLSkFNQVpLRGU2cTMyQnlVQU1DQ2ozZ3VpSFF3Mko0bjFuMC8vRVcwL1haZGI4b0h0TjRGS1hxcGVEZlduRFFYVQorMkVVa09uUURNRmlUaGhEbXdXYjQ3ZG5BQmpxY20zYTdsTy9OZGFlTzlEaitQRUc1WkRSVUpJajZuSlp2UkZkK2Z2TjVOcFc4T2JoCjVQMk5yNHBMd1FWSlJ1V1hhOU5YNWgyTUxEVmRxZ1F5eW1SZFVLZ3dFQkFkV1JPTWF3YWlCT0hUZDFXSkFpalUwS28vTklvS1pVYXQKb3E0MkRxeWtRTm1UMVNoS0JXbXJ6blRtaXBXQU1SVXFKZklzOXdvNklRRGdieGlzdXBxMFFvWWlOVW9LRlJTWGgraklVcWgwQkNCOQpaVjR2S0l0dFhnL2xnYUJ5QlZCY0dpdDRhU1JUS3BBWWoxVm5ER0JBWFR4NlFWVUVpc3VGcER1VXhtc0FDSHhjbmhBMXpxcUVJcFNuCm9sZ0pSVm5heWx5VE90a0kwOFZLSUtQTTdsM1JkTEdTVnAxSmZ5VVBHUWxBYlR5RlNDeUtYQ3JNaHlrN0VVa090bTh2ak9oMDk5UXAKd1hUTkFLaDBMcW9oZDBHU2FkNHRlY2V6QURVV3pPMHlDWit4bVNYQWdRb1BBRG9MMk1XTGI5Slc2UVFBZEhWSzFOeUNnNVVmSDlYRAo3UW5abmlPeUg0MXIyajZkc1RqeUFCQjdwUTBJUUswZXJQekNraUxWbVlTSXk1L2htT1dGK25sbGNaZCtodzlXcmorNWVjWEpKM0N3CmN2M2h4WnVqbC9yTktkZFpzTk45Y2lVRXA0L3BTZE54c0hMRFNXRzJTOTFsbUdsYzlPSFIxL0JtcXlXclZLZmlJM1o2Uk5YcXdRQ28KdHVlOHh0S1RadEpTdjdubGY3NVlPR1pINUQ2QVlabi9uSXJOSzA1TnczcHpMQUN3bEYzR1dXMW40dXd1cndMdS9UZWpodkx6dWt5aQp6ekNqNUZEbCtoTUFhRzZYU1hWNmVHcXdOM2JYTWRXT25OZkFDdmI3L2xieHlZbklsZnUyeXZjQnNFNlZiY0FUdk5tbGkyOWlsMnh5CnBXcytOVjJRWk8xblZ1WjE4Z3dLOFBkN08xNVhwZXo2bXo4MjliMFhqQkRnNzRmNzU2ck9GbXFuV0FBMnROM0NCM09pODBlMDllL1MKN3JuamQ1OUllU0ttYlVqWWdkRHcxM0Q1OGpOU01BQXkveTV5MzRrRHMzOHl0ZzE3S3EzYTBybUR0UlpDZFVyYnNBZWk4MGEwR2hxNgpHSWpPRys0Ykd2N2FHMm15a2dCL2oyTnBjeXNoT0gzc09aVW9PdjhoTDJFTjl0VjlBNnVUUXg5ZnFjSlo3eUVqZjZyMURmT2JGeTd6CjcrSU9ZTnZJQ2U5U3o2a1c5a2FhckdRbzF5RjQ0WXdNQUhoREpTc2VHcnBRWXJqWTdSRUF3RmYzRGF4SzhFWkhQc0F6Y0ZEWTI3MHYKdjVXZ3ExWjAvODN2UVA2SVZnRFkyL0U2bVYrWEFLL0FVUjI1bkI5R1RYZ1hGVysvMFdxL2VuaXJZZjBqZ3VhRk82d2ppZU1BZHY5YwpsZjVveHB6S096MTJUY01GU1hianhBaGhkNnY2bzlHZWJuR3dGR0hNTzBiYnQ0TzgxT0toQ1ErM1BoY2t2S2IzcFBZZ2VtWW5rLy9lCjN5ZkZxbDRLUFdKZnBSQUk3aFozNCtoUXR1REZBYkM5VURPMGZ2eklDbS9OWFpQYWNRUUpxZSthM0o1aldEVzRNNEc0akVjbUMwN1MKQUI3RU5MMG50eGVrK2FRZ1VNNXhITEJpZi84UmN2M28wTEF2WGxhQ1p3RGtWMGpMOFFTOE5TZ1FFaUlPRWdzQXJCb2NTQXlNR1ZWVwpFN2UyS1FoMEIwOEVBaU1FZGZob3RLZmJEZDVTb3I1clVuc0FOUjg5NWduR2cyZmJMYUhrY1JsYStNaC9KazN2U1IwWUVQckZLMWJiCk53TEFlQjRna3BxNXJCRlRYWEEwQVJja0dhSHVaSFJCaWY1NDBNbTArQzE2OWRqN1BtbWpNSTJaV1FRZzZGUzhNaWxKM2N0cWVYWkQKbTVlZXRIelVVa24zYlJYdHZFYk9hNFBoUHR0U1p5b3ZVcHc2WWx6U3d5b0E2TDc5Z2pZM1BXWFcrdGw1OUdUbHZhRFNiRldTdWhTQQorY0F2VVlwbEkxL2k0dEp5ODlPV2ozckpyTGhJNVpFbE40Sk9aVTRZK0Y0QVFOREhKR2JrcXRPV2oxektBYWhOajU5LzVkZnV2Wkp2CkpLc3I5c2NjUGpicms5bDUzeXNuZE9xMm94VEE3QS9ubFNTazUrZW5sMFlXeFNWcU12TVNrbFJtQUJXYmkyL2NVT1hsRjQ5WitIdUsKQ2NDOHk3OTI2eHYyeXBXa09sME1uVDhYMHNIYVVmL2w0VXM1QUZ6QzUvcjA3anRLamNmTjJ4SVVUMzA0cnlSSi9kcXJCNWVQWE1vUwo0blhmcXlaMCt1S1U3V08wd3NUenRiV0t4R1NOWWR5Z3RaMWNjMUhtZ3Z0a3FKVlpKQllKek5JNktTK0JFUHBOMkRHMUdhZ1pySnZ6CnhJQmFLUWVMQkNaM01rdVpZT3dtYkJwZGs0VUNEdFpxN3F6eTJKTU9XM0NwdWZjVW5aOVQ2Mlo5N2dpT0RWSEhTV0N4MVdvdmJEMEoKd09ZZFViL3JxWkw5eTJCeXQ5UzA1cXdONCt2Y0FSQlluWVN6YlJzVEE1azVxNWhxTnplSlRRaXFwZTZjUlJLZHZzQmJNTDB6ZUFBbQpONDZZRUVDT2VJbEZnbHFaUlNLSXRmdGU1S3RiY3lhcEJJMDJ4L1F1NnBmWUpVbldHSTJ0S0c3bTFzNTZSbkdYVS9xYnVrKzUrcTErCnVoWVpOR3hZcDBiRm1qbDBSc1h5MWcvMDYzdXpqRTBGNFdxMEgwenY1MzR1YTFSaDQyMWVaNnVaeGhXNzhIYXM2NUhzYjdsWS81TUkKYXpjTGV0U0VXZC9mMjBOWGdzdXR5WndpdjhGaFY1T2FXM0U0eFk2emg0eHIvZ1ppelI3ZTVLWnpGc2lhU0hYVVFMQm1DbHFOQ3Y2RAo5Vk5EaXhFSFN3aVhteW9hd1BWSTFwQXRkdnN4Y2xEak9MT1BXVmZCMUdDRW1aUE9xVkVnUStjejFuSU9lWnlqR2pVMUJUbFVZemU0Cm80WlZzM3FwTnJzN0J2dFRoQm8yOG1ZWHBxRzluc01ycHQzZ3lTWGhnaVN6UDhFRm5yQjZENXcybGFRMkRvQXRpSnJxT2hCN2lMZVAKWGIxaDVPKzhvOE5Ec29waTVpUENjUHhtR3hSaVlMV096cjNzWktxMzhLUUdMVU9Cb2hhZ2NrVzFRejZxWjQ2RDh0V1JhNm54WUE0SwpUMktndEd2RUhIbHROL2lqQmt5bms4V05iaU1Dd1h6OFVubDBkcjJ5MVRWWjVvSWtzOFZCSTJRUVdia2tUQUJuclNIaENNZ0FCR05iCkhEdUIzNnZMYzRqVnp5UTJrbkJXVzBqSGdTZkhTYTVlTDE3empzMXVNcU5oSUxZTUlRZHJhUG5iWnVibkFKdTF4WXRzRFNLYkRyU0oKSjdGTlhQUWZ0cDRCMXJlWjQ4Y2Q3UHhnTStoajFOQTZFL292dE5iZkRLQU1PK25YUGhTejdzRm9NQkFCR2E2NjJuTkZraWxMRlVDUgpta1ZIWmlqTFU3T01xanJURFlhNjdLUWVxRmFVQXZEenExcWdSR0lpc1RROWVsTGx2cW9uUXhoS0NwVW9WRFBvcnVjTDRkUzZVMm1oCkVvVWFocVFFQWxCYWVyMjZKQmxjTnlpTTE4QjZzTnJzTkxYeENrOVppZkQxQXpFZ0tiRjZnUkxLN05SY2c5S0UybmorWUdSK3FqRXYKbjVUWk9xYlMyNXZvTWVNYkV4STlRamlXcG9QbGNqYnk0eXY1dUh5UVBwNG5GS3BodVp3SkFLWkxGU2dwVktKSXpRRDBab2wxS0NsUwpzRndOWUxwY0NaYmREa0NDQ2FaTGxhaStYSGd3c2hRQXlsTVpGTWFyc0VrQXZJTHFFZ0FTek9zeVYrYURBU1lGYVU5bFQ0eXZXVmFlCkNwWldscmRBOUU5MjI3ZzZMV3B1d2NISzlTZDBGcmNuM0g4NTRyN2J1S2J0VStyTkszL1ZJKzVLR3dBZjcrWjEyQ24vbGUyVVRhNEUKeUVERVlGeThPZnBnNWZvVFI4OVV6Vzg3QTMvczBEeGV1Mmp6d1lPVjYwL3M5UGlWQWJYUGYzRjk2cmtWS2VkZUtoeTdJM0tmNW5GOAo4VWI4dUNNL2ZmWHJ0WjFIaFRsaXA4ZXZGaDJ1VFR5UXZjajlYWVZxWjg0Yk5SYjV4bmpEUzljbjdsZnNjSjlVWVc5azJ6RS80dVFqCndFNjNLUlhyZSs3SlBxVkpXdTQvcDZ6d1BmUkxPRmk1UG1aOWo1OEJZRzd3Wk9QaXpkRUhLOWFmQUlDckIrL1ZMOTRjdlR2NzVEck0KRFpxRTlaWTRXTlo2amNYYzRFbTBLV0MvemdJQUtidU1zd3JIN3ZnOFNwQXdCUURvOERmeithM1NDYlFwSU1xakFBQ1VaMjZzcFZyZQp3UGprWFlaWmhXT2pMdWorMG1YK0crR0NKQnZxdC9EQm5JTjVJMW9GK0hkNTduamY0eWxQeHZpR0ROaHpULzhJejh1WG41RUNHQVlmCno5NytDMGJxajJVOFY4a2doRWVUaDRhL0ZwMDNvdFZQai84TGtqYm9nSURPc3REd2YwZm5qV2dsUkdoekM3dG5vWEhTMkxSaDZCQzgKY0daNlFHY002enF0ODZobjBrWjE0dktFNTVuL3ZKRStIcjJIZEZ3eEhGd0gyaFkrWVcyQXYzOWJkTUNRaml2N0hFK2ZVMjEvZDJBcgpOK1lGTXVpUFpUeFhwVjg2M2UzenNxR3ZwOGxLWTZsL1VHaDAzb2pXK21YVEFlQ2RCSjA4VEdnWEFBeDVhMUI4YVBocm56ODBjNnY1Cm5VU2Q0V0wzUjNBeXVQdGh2SjJnWTJlL205WEozdytDYWpPL3k4THBhWUtFR2dEQXBNaHJwd3UwVXl4bnY1c2Q0QmtFWUkvUnQzOW4Kcjd1N2VZZDhmZCtncXZ6Z2VkTTllOS9wb1dzR0xrZ3lNRWdzNmo2VDJqUEMwenZoK1h1L05pbm9MQWNCWVlKS2tnRkE2SmFWZVpragpwbkwyOVJNRE5IMG10UmNXNHp6andUSEdRZFBIRnF5Tk1ZSUVITTlndGFjREEzSGdhTHM1MUxyZUNyTzV4SlNhUVNTL0FpMElranJ3CllPQXlSMHhsOVMreWdXRXJKZ2wyY2R5aTZWUFk0VU03VncwS3BFZnJUbTFrbWo2VDJpK2FQb1dzcG54ZzBQU1oxRjVvcE0vZGpFR1cKSysxcy9IQzBoMGtKOFBJcktLeFpOOXJUOHIzOFJXdWVGQXFTTTBoNTJDUUFJQXp4MElhUHRId3ZmMEhJSlRNSWxuUldmU3BydEMvagpPbkJCa3NWcjg5S1RsNFV2NVFKUHByYjNHald2RFliN2JGYzhHNStraTgrUGVEd0pRSkxDM0gzVGQ2cEpuY1lOV3RzcFJWR1VlcVlPCnFGVmV3ckx3cGR5U01kdEJZYTljU2RMbUpTa3ZZRm40VXU0SDVhU09nRm1ScE1yTFMwMU1VcWZuSnlRcEN2S1ZTV2thZFVKaWhtRmIKZktvMlZ3SGdPOVdrVHQwMkplWm9aSWJQc21KbmZ6aTNKT2hVNnVEMXYrYWV6OUxLeHc5YTIybCt1VENVMllmei96M2NlT2xLN2ZoQgphenU5NHowdDZjdEpkNVZ2S3I0UmIvWGZ5YjNUWmhvRHVNUXRoaFRsUlN3TFg4cUJJZUJxVEg4UGhlQU1sQ1Z1TVpTTVhmUjd5dERzCjhSZFk0aFo5MXZJSDd3MDZtUXJDL012N3VuYk1TMGhTV2dBdWNZcytIVUN2cU4rbTM2Y05qOEdLaCs2RFBnYkE3QTJ6YzdKVHJsMVUKNU02Ly9HdTNEdHFMNkxySk5WOHVYZldsRjFRbjVZaVh3Q1NEMlEyb2FkWHdMT05CTmEwNXV4TFRobG9wQjUzYitHTlU0eWF6M2orMQpFb2xaNStUcHNtRUlIVEs3V1hXVVZqMGtNZFJaTEY3Z2ErVXdTMUh0WmZJQUFJT0hZMzFXR1FZUFdDcDl6V2JlRTNXYzVLY1I3dWxsCmo1bmNPRXVsTHdDWUpSWUpnMTMzV1d2MnRJYUlrd3Y2eWhvM3FRUjZUOVJKU0ZLbjl3WnhJR2JYandLd2V4U3Rhc1VKSGtiMWJXd2EKMVhyL29vSjdVdUlsY0VtNEtNbHN0aGZOVy9rMGJSaENETUMxK1NmOGI2c08yeStlYTZ3Y2JNYUxvK05oRS9Wdi8rUHVIdVBxWFQvVQpPMHRFZzhxc0tjUnNIUVZ6RXQydzlxYTNKbTRlMmN1RjRJb2tzMjExOFZ5REpLY2NUcjhkT2NmYjNmdzZxcEliRm1wc0RkZUVFVklqClRlVE43WWJzSlJ1WXdUU1o2eVozai9VM21xaSt5ZnpOOWRGMTRJb2tBK0IwWWV1bnRKdjQrV3plOFdlREpHZnRVQlBCQVowcmIwYmUKYll4b3c1RjM1a0VEbzh6bUhNdmVUTGlqZjFvWGppN25nZ3YvNGhPQWZZUCtTckZ3WVBjcUtQeXRPT2FzWkN3N3pocHEvcXh1QzYwKwpOR3VqYkhvYm0vTEZ0dmx1ZnkwclBXN2Z2bWZBNVJJQ0FIV2NvMzdvUW01RFpiaXRxb1ozcXRVR1QrQ3ZZejZHS3lWbE1VaS83aWpBCnRyVnZ1OTBKN0RkaVRuckk4NDRWcDEyekZYZlFnWXB2bDM4SkdWODRIRFQrcG9FQmdPWVQ1MFR0QmpTOHpNekJFU2RRdmRxQmxIYjEKc3QyNUlRRW8zT0JvZmRuUW5TWUJEQm0xMzZjMU5mTm5PSm0xVmJ6bjJJUUdNZWVJMUovaVNFeVQvYllLTWVjNmRreW93UFJEbWtQQwowUlBPMThhV3IyVUc1TCtHQzVLc04yV1hnT0x5Z0lRYkNIRkRZcnp0MDVpc1JDQ3RSQUZVeW9STHJEUmVBMHh4SktSQXBVUDE1U0pCClNvSUp4a3VWVUJxdkVRRDQrUUtGYXJETVJLUXJLTHZRWm54R2dybGFFVkJwWGErblplcWcwcUdiREtZNGdxOGZsTVpyWUFDaUkydTYKNEpvUlVBbGI2d3JUTllBUytQU1ZlYXBzcmFKS3JhVUVQYURLYkNmbEZZSU5jbVlpckVIcUZFVVpDck9xTXNTdEo5RFRSZy9UcFFxZwpORVA0WjB5RlNaTmtwRlZuREQyWktTZTlDRkNXQUFEU1Z4WUZ3MnJ6QmdBOUdVeHhoTnJjdEVLZ01BMUFBby84RzVWV3BaVHJ3UVZKCkJ1MmgwYWxML2VlVTcvQ00wczlMM2VrUlpWMjIvSHB0NTdHcms2UG1GdjUrVGxBa0Y0N1pFUmxWczhiM0djM3ZmMllBTzJXVHl6Y0gKN0FNQXkxcXZNWmdiUEtsd3pJN0kvUUFBaG9PVjYwL3N2Yjd6YU9wNzdFOTJVREErdzFML09lV2JWNXljaHQvUFpRRUFybzJQVnV5VQpUZFl1U05KRnRIMUd2WDUzNFppZGtmc0JrTjRNZHZIaW05Z3BtMUlCb0hEc2pzajlscTNTQ1o0Rk9QTzkyNU1lRjRvaXZOY2V2elloCldzRzArLzBBWU8vMW5VZDFGZ0lnZlQ4cGI3WDBVTTI4Vk9HakQ0Rm1jNE1uNCtmMHI0LzhuUGJWRWVXWitJajNYNDhlYXRLamZBeHQKWG41aUtsYTFXclFLRUF6ekhDb0dTTGVtN1RQcVRTdE9UY1BCODRjbkZXNlZUc2c2cVVtdXNiam9BdHNWU1JidzBzcjliNmhrSmUzbgpqL1RzQi84RjRkYWw4YWhPWE81US80VVBabjg5T2h3QTBDRjQ0Y3kwNDM1ZHduNzYrdEZIb0QrV1BxZjZ6UGV6QWVCa1VQY2pXSjJnCjZ4QzhjS2JOYmlrNmIwU3JVWjI0dlBGNWVsbjc2THlIV3dIQUd5cFp5ZERReFJ5K0hpMllxdzN1dUtMUHNZdzVkZjNZTWIrUXNEMzMKb0gyWEJUTlZBRmluZHI3c3Zya3EvYkdNNTZvQWRBaWVQMU4xcmtBenBiMW4wSnp6M2w3WCtjNnhJZE1paDNSY01ianlyVGU4Q01EbwpUbHhlZ0w4L0FaTGxCLzBWMWNHZCswRllRZ2tkZWlkZWh3UDNyQnQxNE41MW8zNDIrb1lPSHZobTd6ai9MZ0ZCYkVqb1lpbk90QmthCkRnQ2R2QUxKb1dLQUhmTU5DZHN6dFA4aUR1Yzg3d2xWRkdnbnl6NHZHOXpaNzNaMmJ1NEFYSkZrZ0d6b3FrRkIxTy96bFVxRy9wRXYKSzRTVjBIWkxLQkdEaE5jV2doZmNPSUh4UHNub0xOY1djanlYK2ZCVS9PRCtBZ0RJcjZLdzVzUFJucENBczkzZW1yc210ZDl1RGdQTgplblVnTkgwbXRnY0lidzRPSkFuQVFWdkllTnMxeVJ3eGxlT29iUW82eXdIR3dQR0E5YXN5TnpPWFlUVTk0eGhJVmpCeUpBQzNmaDlICmZ1VHZrWUZBT1FGbzQvRUxHSUJ0bGxEcnF3VU5TcjZ4K01XUjlXdElBcWptdzBlOVVLemw4a3Uwa253MzQrZ0JqR2RCM2NBVElHVUEKWG83cS96QUFZanhqa0pxNXpCSFRySHRzZ21FZUE4T1NDNVhMWlFYaG83Z2p2KzBpVjkwcWNFR1N1VmNmVTQ4cy83d29ibHY2Wk4rMAp4RzNwRXp1djNBc0E1aDl1cEY3WDVxVW52YkprcTZZRVFGbHVRb3J5WHo3YmxNKyt1bVNydW5yODREWCt5eCs2SHdBZXlKNXdnVXZjCm9ydWFrNUNjYWlaUVdhNWkyY2lsblBtSEc4bDFUeGYxd3JMd3BRekVVQkZaSEJlcnlzMVh2ckprcTZZWVFFcTJSajVoME5wT1lBLzYKYkZNOG02UW96RTFJVnRZQjZId3lRWkdZcURGT0hMaTJJd0ZsdVFtcHFVUFU0VEZTWFF6bTFnMlJqZkI2ZnNQdWlKUnNUWkw2dFplagpBY0Q4Zlh4cXgxTUtBSXlOQzVnbGJXdEtTMHhXbHlZcmxBOFJ3TGlrTFRYcHkwWXY4MTQ2YXBuM1V4dG01L0RuejNYcDBHTkhtVm9aCnE4clRxS0ppamh3RHdLQTdyRWhNMHBnbURGclRDU0FrSysvejJaYjZiSndxVjYyS1RvamFmYThtUENieHk0bDNCWjFRL0llWHZLVngKcDczd05RRytrb2hxTFdTdXRQQkU1Z29MbGY5S1JBNU9GblZtblVOK0hSSHB6RFZFZXFLNkNtdWlucWpXN3BPUkp5TGlUUllpSTVtSgpOeElKYmd0NW9scGJIcDI1eHA1YlQxYjNqUTFndG9xeWVXVGtlYUVlTS9Ga0lDUHhwTGQ2ZTdTVnFDV3p0UlJ2SWpMV2k5cFJ5eE12CjlNZkFrMURPd0VkdnFDTGl6WUlQUmRKdjFlVnNJaUxlM2cyOVhiQzlhWnVOMnEvTFNFOFdnNDdJekpOTHdsVm4ySVpJNnduY2ROUGIKYVkvbzl2WmxuU3pPSEhPVXZQUG9CTmJJVVJycXQrdHZzZmZwN0F2UDZWeTFybU1UemFMMzhtem1jWUJnZE5mLzd1YUVXd3UrV241Lwp6d2ViNjUrcndEVkpkcnR1NzI1bDh2Z1h4TjQyTTI5U3Zoa25pUCs1QUdkSnQra1owTlhnZ2lScnFjdDNheStmVFJhNUhWTC90YlkzCkUwUFJsUjF5L25kd3dZVy9vMUVPTmQ3WGJtUmoyR1Q0S21wV0xuTXVlNVBiek1IcUNMZ2RBamlyZzV4Tkk2Mm1MZzN0aytyTDJscjUKRDRNTGtndzJmWjR0U0JYaGVyVHR3cHVQWFhLT0JNZ3VabHQvVUwyT3p4N29yUW01c0plL2ZwQzNNaWMybXJjS3JJdHlIR1M3SHJLUgpzYWZ0NEErdC9lQmNMaGl1RnRkRzJlOE5abk0vU3ZaUUZyWlZaT09IU0JPZitmd3o0Sm9rczVxczJsaDB1S1lpMnpwc0VjTlAyRjlXCnJIOXJ2MCszMlpqVjJuVjg5Uk5ISTFyVTJ3UWZycW5JRlhiZkQxZFg1RmdOT1hXcnlTb2dnNENTRCtwTmU1MG5Ob0FCeHUrenJCVXkKMDdZMEFEelZyTFpwcXpNRjk2T0MwL1VHbHBXTXlHSFNJb2QvcnF2bi9vL2hpaVRMemk5RVdhRUNGU3FBRXZXbzJGZjVaRmVnOWdZUAp6Ui9aYnpOU0s4cVZCZVhwcUZTQVZHVkZYZmtpaFFGQVdZYXNDNjRaWWJ4VWlSQVowa29VREVEWlZSUGx4MVhVeTJYbHFTQktNS0R5CjE0b25Rb0RjQWxUK1d2bEVWNk9pS0N2VnJFSjczWFdnN0dwZDJnbzEwSU1yVENOa0psR3RKdFZJMmRVcXdUQk5KWGdJSlVKbUI0RHkKbGVYS292SzhZRncxb0t2TTF3OG95QWVRdmx4UU9qS1Zya3hSWmxUd0tGT1VwV2JVcGRaU0FqRlZhUjdTYWdDUUxwRUhKZXBCYWNVSwprREgxbi9iQWRFR1NuWm9lRlI2L2NITjB5azdkTEVTMFhuc2NCaENnVytQenJKcE1QSWhWdnRENmhWTERzWlNkaGxsRlk2UE9FVHRRCjRRSDhuUDdWRVZ5OCtBYm1CVS9TejB1OU9qbHFyaGJJZjcvNG5leFRCU2wydVFkVGR4bG1zUWp2TmNkaDRFRFluWFZpSFJrQnVIK1EKbkxOYWVnZzR1VFU2Ny8zaWQ3d0tDYUR5UzR1SzkxN2ZjZXk5MTZPR3FzTi9lZkVIZnF0MHd0VXArK2RvbFgvRXI4VXEzeXNBcTF6Uworb1VTdzFGMjhkS2IrbmtwSUJ5czNuQUM4Q3kwS2gzZEpodW1tMlMvY0pBOUlkOTcxTzBudDYzUzhZVmpEMXdRdEpGRjcxSGYrQWp2CnRjZXZUOTQvcDBCMTVzYWFmOWhrNW9Ja0c5eGg2ZUxEWVkrODl0VjlnNnBPeG9aTWkvUnAyeU1uY3N0eDM1Q3dQWjI5N2o3eGVYUmYKNy9Ld1F4Y1hmWG5md0txODRIa3pzUEh1ZXdGRTMvUFJhTnczVjRWM0VuU2UvVERVZitHRGVVREhHUlg1YnBHbFEyeHl3Ly85MVgyRApxcTdIaGt5TGJPUGJ3NU5oeS9DWlg3ZHEyOE1UYkhsMGUyVjFsellZTjBIVmFVWmxYb0JuRU1EYVRoaWFQYW9UbHpkNDRGdTk4NExtCmZicm56d0x0bElIK0N4N00zV1B3N1gvQnErTy9BUFQxS1IvdzI4VWx1RytPeXJNZndIQXdkNFNYNEEzMHZqa3EvYkhNT1piVjIwNDkKQmJSNjduaWY0NmxQbkMzUVR2VUxuanYrV09hY0t1QTZoUVlIQng5dlN3QUFnQUJKUkVGVXhvWk0rM3h3dXdVUDVld3grdlVYWjdJVwpCMUhubm95RFR3b0N2VE9GMEdkdCsxbnQ0b0RBZmlGNFp1MlRoODNTdGlrSTlHQUFHN1BhQ0tDb2dNc0RKT2FhRDBaN2dBR01wQllnCjl1VERKRGx5YUtkTkxrT2JGQXAwRitRU0FHbWVMWmpjNE9TNFJTOCt3c0NrNXRpVEl3ZzhRR0JNWXRsdURpUHdDT3BtUWFmZU1tMzQKU0RBbTRXWEcwUU1xc2dBZWhLZlhQdm03V1FLNG1RWG5KK28ra3pwWTM1SGR6Q3p6NGFuYzVHTkozUUE4dlpONUh1cnZyZzBmQ1FZdQpjL2hVRG5pMDd1UkdlU1lDM1JsakV0N2RPSHFBT0pPMU5FajVaK3BvNVVYTXYveHJ0NkZMTnV5T3FGQ2M5bnQ0K0hDZmJhblBacWRjCnYrdmhNSXpUM3ZQZ1FGaE53VXlwdFdObUZBSExSeTd6VUNRbWE2dVN0aGlTMDVQaXRmbHB5WUFsNXFBMjhjdEpkem5LM2RldG4xVnUKSGJEbXM3MUxLaFNuYXdHTTd6eGI2bHVtU1V4U21tSU9ha3NNSjhDU05Ia1p5ZVp0Y2FsMTU4OTFhVzg2dEgvK3ZkcndtR1J0WGtiUwo3UFd6Y3g1VnZ4VWZCNFp4Mm5zZUhGQ25TRXpTRktZbGxlWXFsb1V2WTJEUUgxRWtKbWxNNHdldTdjU2VEUUdBOWw2ajV2cmdIbTE0ClRJWDJvbno4d0xVZGllSXY3ZGxqWHJKaGQwUzhOaTg5YWViNjJUblhQL2p2THFHcjRVN3J0UnBEQ0lsR3ZLQ2dhMEpmUjhRYkJVVmcKRFRrb0NzbkFDL3JFT3Q0eGpweUp6R2FEN2laeXpZYjZySGI5b3NtdWRTVGl5VWptQXhzcWlVWlVXY2lxdTdUcUxhbEs1OWlnK2xwNQpJcUk2YTNQMVJQeDNackpHaEtzVml2TEVrNDZJNkNkTjhlVWpaTERZT21Ob0VMRHVId0FYbk1sdXFNM1dyNks5QVBLb2YzVFVSMEZqCjduQzNwZFI3QXBNendWT1hoRWxRdjFNaGcwUWk5N3lKWEluTmZKRmtFTVNTRUl0T1l0dXBJM2R3Q1NvUHFITTFISUU4Ykh1NmNnQ3QKUFJ3YlpKTUVtV0NJYm5WYTVVSHFSN3BKd0FDNGc3a0I4QkQyWkQySkFPT3E3ZHBSSk9kZzNiNlFOd2hZOXcrQUM2cVZtalBjdVdtcwpOVEEwcGMyK3RkeW1BMjZCRWJOK0NjWnVwbE5zV0s3aFZpK3pHa0xkVENmcXFFcjY1MjNDMnVDQ001bjFrejdoVndOYkg4YzdndUN3CnVVbU1DVnVwTnFNUUFFUjJPVVJFemNsbGpSVTVqS3loTTVsTjUrQWdGbzBjaGRadnFES0hQR0N3aVlGdEQ1Z2NNOWE3MWFOL3JrTEoKZGtIdmRBc2F3VDV4T0dtMG01NVFibWx2MkhnbXZMbGN3WnF4aVNueDlqK0JhUGdwVURNdXJKdEkvNmZPWlM1SXNpYndYem1ydnZVWApOTTR5YnkzL1pzNnRHMGxvL3ZPUHhzYnJ0Mmp3LzAzOG55RFpyYTk2ODI3dmIwNkYvM1EwLzBLNWZ4aGgvaFA4bnlDWmlQL2JjTW1GCnY0aC9Ga1NTaVdoeGlDUVQwZUlRU1NhaXhTR1NURVNMUXlTWmlCYUhTRElSTFE2UlpDSmFIQ0xKUkxRNFJKS0phSEdJSkJQUjRoQkoKSnFMRklaSk1SSXRESkptSUZvZElNaEV0anIrVFpPVHcveTF5MG0xbWRNb2tmaHpua3ZnN1NlWVk4TU1Kamc3SmJINldtakdzY0tCcQpmZWg1NjZINEVhcEw0dS84TXJaNWU0bkVMQ0JnU0hObmlRSEZ4L1hEZXpsOWxFOE1RRWxOU0ZOMWlIQWgvTDB6V2NiK3lmRk5FZHY3CjBxVGYydGh6NGF3dDNXNi9ScDdHaFZjRjYwb2huY0RBL2dBd1MzRExheE1wZms3dWd2aDdGLzduZm9zMm9Ja25adkE5MUsrbi9TaHAKay9EWCt2Z2pBdUExR29LSnBUMnlHaUVwRXNEcVRTQ0EyZGtuc3N6MUlQM3ZSZndGUEJ2d2ZaUHBqRUNvTzFFMU5pMWxVcXVUcjdZNgozY3NjTDcvdnlFTWRMSHN5Qnp3bVErVjIvaEVBZnhUZDFmMTAxU2cvVlAxU2NzL0RKMTlwZmJxWHBJSUh3L2xUZ1k4R0NPVW5lLzIxCkpvbG9lZHlKTFF4cStwQzdQdU9OSDE0YkQ1UVlDd3hzNCtwMUIxZWJIL3JwMmU5R1ZlT3hMNEkvQXBEOTVHODRPVHVUNWZmVnZqeG4KTjVVWUN3ellQQnY0ZU9JRVEvOHI3UHFNTjM1NGJWeFRWWWk0cy9oNy9ic2N4NFhHaVR6UmZtemtLUTVyNlgySm52cFBJYUpWN21jVQpHYnZ3QS8yRW45THdNZjJPWGFUREIzUWNsMmsrOGl5UEhxYitVNGo0MVRLcWtZd2xnM1FLeFdFTnZTLzVaem5FK1VmZzczeGMybDJRCk9LWFdiMjBNUUZ2ZTVBR0N3UU9tQVcyd0h5RUlSTG9aSGRESjZwS2lGa0MyckFOM2hBR0F3UU5BcVNVRWN2ODBBSVBRMW1MNlozbkUKK1NmZ2I5NG5Zd3dNSitaYkdxWUtIcDhBU0FBQzNQamFUd0JKRzJBRVV5TUJENHlTSk9FMzFKSGNXMlhaeDRnbTFsNUR4ZmVRbVdzLwpBVUJCM2RWVVV2QVFBTzRmN0xYay96TCt4bG1UcHg5SFkrcE9lczI5ME9uRXdYQU0zVlV4QmFNdURzTlMrc2h6Z2pLbUg1WVhFWDAzCitJT0pXNG5XQnovME1lNVY4Nit4Z2I5aVZGWDUwMkZyVnVscG5kY0VaV3cvYkNERjROZWZmcUc2WWdwR1hSaUdsKzcwdzBHRU0vN1cKTjM2YjU1R3FOczNtQUFPb3lGZHE4MjNCbDdSakFDeDFjcDFNeXFqYW0vVHVVc0JnYmcyZ3dNL05XcTdZVitKUS9sYU9ma1Q4dmZpNwp0NVY0RGsxRzFoTFkzcVJublhwbktqZnhwVVBNeGpEOHd6M0svUi9FMzBleTI0dHRCZGF3QURYbHE3QXB4MHgvc1NJUmZ5UHVoTzd5Ckw1MTM4bnpaNkJqNHgvdVErejhQbDlYQ0VMdjlyeXBFZHJrMlhKWmtJdjQ1RUwrTUZkSGlFRWttb3NVaGtreEVpME1rbVlnV2gwZ3kKRVMwT2tXUWlXaHdpeVVTME9QNWVrbFZ2K1gvc3ZYZGNsRmYyQi95OU0wTnZRMUZRa0NvZHdZNG9kck94SlZFMGFteTdHODN1V21LYQptbVN6dXpIWkpNWnNqR0NNQlNVYlltSlg3S2dvVFJTRUFRVUVVWkZlaEFHa0RYWG1PZThmejFTS210M2ZUdmJkOTcyZmp6alBmZTQ5Cjk5eDd6OVB1OTM3UGlZNzZXODFUaS9UUHVPeDRNMHB6Y0hiZWRlMUtwQ3NBQUw1ZjlTK3JtVGxXUjRmSDQ4djYwbEwzUjQ5aWM3WDAKWG51dzcyYmlUc3lkMWVlSmw3VGtGV3pVdEVOQVZJeDJxM09lWTVYemplbytzL1c2UHFyUExSL3RjM0tJdnJoTHFpQ1ZuUHAvblQ5OQpKdWxKK21hL01sNGxFVFhiS0N2djY2UE81V0lpeWxyV3Z6Q2RocVFuZTdYcnA2VVFSelNydEM5MWVzbFRGK3NoYlZ0MFg4MFN6YVhLCnA2bll1MWxlMDMzS28zMzAxTnI5OWxmL1NiaEZqd1o5OXZZN3hJSkZwbWZUSEl4L3JqaHlkOEFucG80L1Z4ek5HN2pGeExYeHhqV2YKcE9RTFZtYkpWN3lGNldmdHJRQWszWlFQdXBxY0dUT0ZvV05GclZleC9QempZZktNYy9aV0FQZmR4bnY3RlR0R1NUYTQrK2JHZGhwSAp0UDFjVW5Pd0lnaTVzWjNjWW10dlk5U25OSjJhMm5uMm11bEFTV3JhQ0FBNThWSzNodGhNVHh3cVA1bzM0Rk1UbCtickNkNkdhRjlaCjY4MHVaM29hQVBmMjFlUTczcmptWXhpNUpqb2xxUHJZS0NCZGtqU2FqczdPaXM4OU5HcnJ3MUYwTnMzZTRtSGE4VEVycFY2MlFGbEMKcmxkVXFzZmVRT0hOUzFZMlIrWmNmVGg0ajUzTjVaczFuWkdUanNVTmUzeHFSRzVzcDFPYWFmTVB2ampnWThod1BVVXhLQzRsTTJZSwpBODVGRHhUdm4zUTFPVE5tU3VmWmEyYUNjSVB0MWs0dHlYRmVqeUlubGNWZkNEQTZQTmNLdUpMaWQ3RG1ZSGxRWWRyUnNTdHF2YzYwCmw3enBsdjl3OEI2N25BMXVpSnhFWjlQc2pRN1dIS3dJYW9tTHM3SURNdExTUmpTbXhIc2xKNTh2UCtHTEgyeS84N3R4UFRObUNydDUKTjZWbUtMR09zOWRNQjJha3BZM1E0N3pyOVhGNTNZOFlETzArYzE0K3BiVXlmdk0vNzcvL3JrRmwvS2J2NzcvL0RyNzFyWXcwMmovUApmdE1NNjBzSHJJZXVBNUNZdmZTcldGSFVwQWNwSU9OcDQ3eFk4Vjgrb3dQV0h1c0FjQVRYUFNMZnZaTUh6TSs2TjJXbFdVTGJDMlduCjFuekdaZDJidW5KUXdGd3hRSlZoNVRmUGk4WnR4YTc1NWdSa3BTN2FqWFZ6eGt3eHFFalk5UDM5emUreWIvMHJJZ0dUYVNHZWEyZVAKbVVLQTYxNXYzMTIrbGZzQVREcHNWT2NPNEx0NTV4OHd3T2pndlBZZEgreHIrc3g1K2VTR25hRmVKdFBHZVFIeUg4Wkc1Y3pjZTJtcQpXY1NBeWZzQjJGK3lLQzkrSUZuYTRoNU5VMzh5cXcvS3VqZDFwWnpZK0ZPR1J0MFdqQkp2TC9zcTF1REFwQWNwQUY2eVhPb1dEVkhVCnBBY3BGMFRqdGxySDU3MytaMnlhSWI3a0ZvMklpWFFVQWc2QUlGRlVlbXJ0WjF6RUJDL2o2ZU9HbGhST0doRG1jTW15dkhqS3dEQzMKYUh6bXZIeEthL21wdFg5WEhCYlBhZ0ZoMTN4ejJ1VlhFV2tZT1c5NkxBeU1uSzdLREtJbVBVZ3AvbUhtdDA1Z09HOHdiaXQyelRQWAo1N3pyejhnSTVGZkxBTERqYnFMUUM5YWV4dTd1ZytTdzlqUjJjeCtrYUw5ZUZ6YmYyaVBBcElJdFdYU216WDRiZ0pNdW1IM1N4dDNUCnQ0SG56SEgraG5iTlovbHpEREN4RGZWcEFCQWpiem9xdEF3Y0x3NXhjR2lPa1RjZTVYaGdmYkI0U0YyWUlsc0dwMkJuQmh3SkZKNm8KdTIva1ZWZHU0Mm5zN2pGSTNwWXNEUXNEQ0Z6REF5UHZ1a3JBeEM3UUkxa2FGZ1lHTjUra3BHa0FQajdlMlFZd1d3Y3IzeUdtVGczSAozRVFUTDA0ZjEwYmdBQ1ExU2JlNU9XODROb0xPZW5wdEkwQkl6SUJ6VG41dHZKRUpzd3U0bmpQeXRMenBtRndBMFhzUlo4TUFkdElWCmMwN2FlSGo2TmdDQWdFeE1ZT1B1NmZza1RKSGRLclNZT3F5dXNZSXRXV1JpZ28rdlZjcEFBZ0EyRUZpSDJBOXVuaDdjQmlLQm1QR1QKSnVJQW1KamdtSnRvNGtYTGNRTUhOMDllRnhrSVJrT0NuVHVTcFdGaDF1NEJEbXVqNGw0Um1jUEczZE92b2FXTXVUZ0JDT3ZPbG1GSQppRE0vSmY5clJzYkE1aVkvQWFTMVhoS1lPVVBUU3dFUmpDb2RoelVCc0hqWWlMdDJ0VUhkQUx3ellPYXNaSm93QUFKaUFyS3BEZXFDCjZsV2ZFUWl1dVVFV1hVUUFCd0ZjYzRNc3VzSHhZb1gwbGNFTXdyS0laWExBN1R3ZW10YTBNMXQ3RGdCSE1LbDBDbXdFR0dCWjAwNTIKZGdBQTQwckhZYzBnWVBQSDVneG9YZmVxSTZtZGVBamhMWUhaRU8vTGV6SUJBSzRTUDk5YU9abWRZdzd4N0M1ak1PZ0FSNDlQL1dZMQpBOWo2cjZ6Z2NqZlFYTTR4TEQzN1lBamZJMU5uOWU0U2haSzd6SGcxR1NPQjVjTW55QU93NU1VUkhBU3FmWndFQnUrNGZSazhkNWtnCmFnZkg4WjMwbHNEVW1ZRXhScW4xRVFTMkxHS1pxTkl4c0FtTThOcnhPakVKK1UwUXc4WmYrRndNWUp2aGRLSmw0Y3NVQkwyNUR0SG4KblF5RHZsbSs5MVQrd0UyZkhyRVB1Wk5UVVpLZVgzbi9UblpGVVhwZVpjbDdvMWFiWitROUZyd3phdFdnTjkrYVh3UGd0WlQ5bVcrbgpQcXJJeXdEZy9YUHVuZXlTcXN3TmI4MnZCUkR6SkMyL3RGQnl2OVZpNy95YkliSHRKZkhka3V6U3lveXcxSkJZYzU5dm5nQVpqOHJ2ClpkcDllN3FxY2szWFNoR3dNSEg2VFpPL3JqajBKc3ZPcVNqSnlLOHNlWGZFS25NQTNqOFYvbVhsNFhYR29QeVNIUGJlcU5XbUJXV0YKOEhZTUEyQmN2YVhoVm4zeExVbHhaZmJ0aWhMSnhrK1AyRS8rUFBjMzNsNC9GUUR1L243dnUvNWg2anUveTlpd2RrbExmY2t0TDhtMgpSNmtWR3oxZnVsZFdqTkUwQzJFM1EyS044akxsb3Q4TkI0RFhVaUlsYjZjK0tzK1hBRWd1enJ4WFZweGFWSkVuc2QxMXVpcjNZWHBXCmRkVTdvMWZaM3lzdEh2Qis5cjJTNGxzQU1ncWxranNsbFJsZjVQN0cxL3ZRL1p6YkNvczlYaG5iaXROZ3NUZXZySGpUcDBmc1F5UjMKU3FzeVluNEltY2lBdFowckRkNGJ0Y284STA4SzQ1bkRVRitjZWFPb1BGOVNlUFNmMjFNQkRQajJiRlgxbXE2VlFuMXVqOUx6aDBZMQpSMFJkalQwL2VUaWlOdVdSaklnVTdmenZPcTBDM2NwZnFuUEthbkpsRlhXT2pFaGRscWlENUZ5blZDTzV0VU5MR1dXVDNVUXRIZHFaCkhCRnhPNG1JcUVzdTE5Ry91NUZJTHVWVVRhaGI3dTdrTzlIUnpDazZsZDFyMHlyeHJZTGpORDNTL3RiamxHb3FmOHZVZXBOT0lVMmoKY3FLMmppWlNGdWhXTmtieTVuYmlpTHBxTlIwakxRN3F4YnlHZ2gyOFpBWFhKZjFQekcyLzZiOWhQOWt6ZGxkcnhXYnVPN3h1UDVzYgorOXZLMkdlUTVwNkZQOHVKR1BRTDkwSStwZmlsblJ1blFiMmgvSGxyYVpWNFhsWDZMeGQrWTdUck1MOWYxS0gvcy9SZllHUzlOMVEvClpVZzFHLy83T05GMzd0TmE3VkdMVkZ3bmFqVXc3cTllZjVIRSsrOFk1QzNXenlqeEhDUDBmQlNaZnZld2R6Y08wRHF0MTgzRWVqWXkKZmdiN0lvZjBGZUs1bHpIMWpOV3RlNjZIM0Y0QnhqVTNyVDRqM2o4cmtIMWY3QUwwcFY5UGUrK0hwdEN6YitqWk9lM3U5ODl3ZUxxOQpxRytlVHlmZi9HZVRmbUVsWXJ6Yko2WjhUcXNzUEdVeUFBYWk3SkVNd09wcUFHQjBjNUx5RXRiOTJINmpTdlhKcFJFTVlyd2ZBL1VzCmdHbnE2Zmg0WkloY3k1OWcvQ3VwVGlQM05vTEFxQS9YbzB5Vm9UWHpPcFBWdlgxZC9hR3dlN2o1bDlSUmZEY3l4NmpMRStIN042RDYKSnRZUm8xUlg5eDdEb1BMb1FDQ0EvZmc2UUJyallHb0FMbkt0RXJjaTlSL1ZYK1VIWk5RZlZCV0tEeTNNNXNkS3IvY1d2Um9aRjZYMgphOGVJQVpGTU9UQWhqUUNBdUxLZ0RnSndZQkEvMnNwc1JocjdRQ1N3ZjdBeWx4ZTJId0NEeW1oVmprR1pOc2UzaDJmWkVaMmF1OGJWClV0V2tNZ1lRK1g0TnBySWVVcmVodWlKMGJ2eGNsSzVnZzVjdTJTNUtFOE5vYWtnN0FCd1lOS3BOM1R6Ymp4RWR5dG5WV0tsS2JxVGEKZ3NFMERhcXVKUVpnZUFmQUdQV3dId1lhMFdIc29xbW9mVG1wekhaa0c1U3VUN2RPL2Q2RGRLNUZ2U1M5d2twZm5uUk5Lb2t5aXhsMwpzTllqN2tadCtWdXVmcm14SFU3TlA1V2svQWxBMlNJYnI0UCtPMGEyN2ZDN21YUlJiSEt3NVBxZkFFZ2pqTDl4SEpnbWlSOXpOZWxpCjRjZHV0dUcrWnJteG5VNlN0TFNSQUpMZWRQTk5UcEVQWWdDdVpzWGVIcDZZZEVGc0VKdnBhZEJ5L1lxM1VlN0ZMcWYwVzZrak0zaHMKQ2FVSmQvMnJNMTVwVExubVk1Z1RYeWRjYkUwL1Z1ZjVuVWx6TUR4WWM3QWk2RXJLOEpia0s5NUdJSGJsZHV6dDRkM25yNWwxZm0wMQo2RWZGUWVFT1lXbTR2MlZUeWpXZnBPdVNtQ25iVG5wMnB4NmZCUFhkeC9id0NLZXp3akduWDJYNy9jSkh5bmI0bWU1Ykk4ODROMUFNCklHbUQyNEFiVFRGVDJOMkxYWU1aZ0l5ME5OdnRWb09qTFFwdnBUWnZjUFBOamUyeS83bmljTDdkcHlhdUFDdmQ3aDUvZVZocXJ0ZVoKVkFlakgwdWl2Ry9OMjBsRDRtNUlQVUFzK3JiajF3YTJ1L3dmSitiNlA1YThmTXMwQ0FES0UrNE9QVmh6c0NLSXpxUTZXSng2NkxEWAp6am8xTjZWR2ZLTXhaZ29EY0d1UDVkRHE2OFdlOXlKcjh2ejFPTzk2dlpQTmRwOWNrYkpvN0FHSUV4NmtMMnVlWWhlV2xUZDFaZmZhCkJTRWNBRGdIekJHM093NC9ZSDIxMVhEL3ZJRnJGNFp3QU1IcTFPTVhGbUQzS3hjZkd1NmZOM3RBbUUxY2UxYmUxSlhkMzgwM0F3aVQKQjRRbDNsbTJQUlpFYVBuK3BRc25EUGJQSDdodXpwZ3B0R202OWFXcy9Ha3J1M2ZQdDhCM1llWUFTQjRkSEpYRmdGMStWZnV5VWhkOQo1eHd3ZDhSdUg3L1BYSlpQYWk2TFdmTjNoU0FSbTJaWVh3SVlXcU5lT24veXZIRGNGME1lMXpEcDhJU2F6Vzg0VDlqQmR2bFZSUnBFClRYbVFNc3Q5UWtTb0o2QzZMeENXSGFvZTh6TTRobmJId0NpYnEyMWcyQy8yZUJNQUpnOElROFdDMHRTc3ZLbkw1UUN3YTc3NWtNYzEKa0hyc25tYytlVUJZVnQ2MEZWUVovLzczRHphL0F3QXVCVTNqVDVwWFR2N01aY1hrNXNxVVJVYVU0Qi95SUgxcE00Rmg5Tm1CTmEzRwpGcWJSWTZPeTFMZHIrUTlqRCtTVW5WcnpkKzd2cml1bU5BeU10U292S3ZsaDlyZE9LRjlRbWtvQUJkc3ZGTzFZVVBHQit4NHZmZHFZCnZ2ZVRDYXo4eHhvSUlJTHo5Y1hqQWNSUTQvSG1ZbXRIOWYzZDJNTlpLcktDdFllL2ViRzFvd0JnTURTYk5OT3diTXZ4RHBtMWg3OEQKSUxMa1lxanhHT2NVN0tKODFUanBqSmtud1Jpc3ZieFhYN1h4OERjb01QS3V1MWZCbGl5SzRScVBjVTdCem5BS2RnSEFrcHFrMjF5QQp0bVRwdkFWSEFnVW5BR1prRnhod3pFMDA4Wkk0MkdGd2l3MmFLdGlTVndIQXh0djdqYmdGaW13WlB0eFI3U3dVK3poWWVYZzF0Q1ZMCjU0WFp1QS8xYldCZzA0UGJOUTlqaGlVbnozL1NjSFFzZzdHSFM2M0lrZ0E2MTJhL1ZkVjdKeXNYYVF6WGVKd0RnQ0hCenV6REhWWE8KY0FwMkJoQkRUNDZUdGFleHU5c2czdWZSNm9PRlhKN2M4cGliYU9JbEs3K3hCa1U3WDREejlTWGpHUUQvSncwMlVmRnpsWjFSdHAvVQpLTjNtSmg3bk1MajV1S3NvOUtJUUVLRzVEQzVPY0xKeWtTb2ZrWW5tbUgzUzJDN29mOWpJT0JBQkNpZ1VOYWRtdmdHQ2EwNlFPUlcxClFlbExTZ0ZBd1BIRElWSm5Nems4YmRZdUdxSjJxODVjYzRQTXU1ZEZMRk5XODg2QXVUTUFNQVVNUXdHSXBlMndkWHY0QkhtdU9ZSG0KM2NzaWxzbVhSU3hWQUhETjlQZVJBaWFWamtHTjdoZFlZYWNhblRGekJ2OVZZdkh3Q2ZLVjZoaUViak9ZVG5DMy8vQVZ2aWtHazBxbgpvRWIrdFkyRDk1VTlHZEM4Umcvd3p6VmIrdlZZQWlEZ1h5U1piVzJnbkQ5SklBaklOU2ZJdkJzQWxrVXNVN2piZi9nS0xZdFlwdUJICm9sdlpRUURBQzBtRmYzdDNHTHdseXI2NWUzNk5tbE16VndNQWxyMjc5UEhkUWE0U1B4K3B1bzVySm4vRTRKMEpNMmVEZG5DS3dQRVgKUGhlRDhRZ1ZBUEtXd05SWnIzTU92Um9ad1Nrek52ZG1CNXcyM2NxN3YzSG9IRmpzblpjYUVtdTNNU3lpOWhGQThQbm1WdmtEeVlQUwpFa2xHWG8zeHh2a1Iwa2NBZ01PWFhqS3UzdEtRbHBGWEE0czlkU1dTK1RkRFlzM1hkcTBVQW9ERjNzVTNJalBlQmdCMkt6RTNMQ092ClJ2aVg1WWZXbTd3N2VwVkRXQ3BmVXJTMmE2V1FBQTgvM3crR1pqMXNlRy9VS3ZPRkNUTlNqSHkycDVibVlOT25oKzFESkhkS0t6TXkKQ3B2ZkdiM0tBUUNRbm5nM3pHN1htZW9LYkxZM2FueVVubDk1UDZPd2FlUEkxZVkzSDFYa1p6aGxYdjNpN291K1VYdlYzNmRZTmhOTApYd1FyS0g4Z3VWOVNrbEZROXVqTkRRc2VBd0RNOTZVWGx4VmtocVdOdTJnT0F0WjJyUlJpczRNUlc5dTlVc2lQaFBHZG5JcVNqTHpLCllnQVF6QnoyRzVNUjJQanBFZnR4MlRjN1VvdmUzYjZ2ZUtQbkhBREE0bmJmMzNyQTNkL3ZnNkZaRDJ0emI4c0JlUGo3ZmVBaXVWTmEKbGJIcGt5UDJrN3d5dGhXbkZSNzk1L2EwaktLeWU1a0FVUHJvZ3JmYlh5TjM1SlhrNk5mSzlJb3Y4RmlNdktsTkx1OXNKSklyWVpSbQpSYlAyZWRWMndSWTVuejI1VWthY0N0L2gvM0l5b3M1YS9xZWNpS1E4amhML2xncUlhdTNnQ3hFbkkrcVM4ditJSXlJWkw3NmQvNjFxCnM3dVJpRlB0bTFTaU1mRnYxUkZ4blNRbk9sK28xWXMyMWRiSmJwSkxGZFRaU1dxMXUrVGFXQTVIUktUbzBPbWJHampxa2hMUitVS08KdXFSRTNWeXZlbHdIbjhYalJueVQ4czRueWhMdDFDVlg5VkFOVThtVWZlQzZHNG1vcmIyWkx1VFg4MkNTWmt0b3ZmNzNMK3IxVGtaQwpBQ0NoaFlsQWFHaEZFRExBRkFRTGdRVmZSS1MxZ3NSZ0xyUWdBQjJORGFiRURJUzhCekwrTHpNRkRBZndQNFVBN1BoN1NVMk5XUG00Ck1UTWlNRlBpU3hyWThmK0lBVERsRnlhTUdRaW1VUG4vRmxsQjgxM1BML1pUeldNeHdBd2hySjFTN2dITmc4eUU4ZDdlU1FTQm5RQ0cKaHNwOEJoZ0lBSTA3VVFZUUNZeVVmVk9OZ2lrdng4Q09hcWFVZVRBWTJCRkVyRWM5Z0JueFdTSXJmaDJER0NBd0ZDdEh5QmdHUXI1egpXbXZMcHNyVk5pYXlBbUJpYkVFUC9yci85b3ZxTlVVR2dLejE3emhFYnl2K1dtdlZuRUJyRGFpdlFweEE2NURxNm96Y3RjdXFSbHg3CkVady9Td1hNMFp6MXdEdTFSZmVCZ0txREF4QVlNWlVUUFFERTdna0dXZkEvcFFPSjZTcmJ2ek1ZVXEvUTlkRTlsV2hsQ2VtQUhpcjEKQnpXUTlncndVOTFsS1F1clN2Rmdra2JwZnFEYS8yelNMNnlrMDhVZS9lMExrTlN0MW8rQVBndjNzREt0ZWoyaHlqNlJJVjNGZXAxUwpIajJQMjZHZUNKcnF1Qy9sK3dPYTFLZDFoZlcyejc2TlQyUGJmVW5WUTlLN084K24rZHJzY3piK2xVYWUyek5ldi9QZFErVm5TM3AyCmovcUY5ZEhyV2tBUERMYm5mYlJmZVUvTC8xZjc4TzhudlM1aE1HaGpSSDJmMXo3UUhLc1lacjB1Q1IzQ0Y0R0E3Mk1lankvTEd0dEwKZE55SnVSZE96TzBnSFVFTWlEdnhVbnMvK255L1dvbmRLSXUvVVEyQTRmdlZ2NmpIMGlrUGxMOVpuK2UxQUZCMlpOY0dKWXlaUFZKVApoaGhZWDNVWnFDeXdwWGYramNsOWF4TytFUUFvYzZ5KzcyVjYvOVRRVGp5eGpDTzZVcXo4YXRLYzQ5U0grM1RxOVB3NDRpSzFEaTRYCkV4RTNxNVQ4ZW4xRHphWEtPWDF4MFBvbHB1MmpyR1Y5bnVnam0rTjZzK1RVYWY3OTV4Z0tqb2lvOGc5VXdmZWpoS2ZsOVJ3cXZxUjIKWXlITnZXVXBBdnR1NDlvR3ZxZCtwTitrVit3eVB2N3V6Nk8zUGh4Slo5UHNMVnF1eHBtOExmV3lCUmpLRjFranVpYlBNdjc4c09UcgptVEZUMkpVVXFkUFphMllERlRjdlc5NTkwNDMyVDZTemFRT05mcW81V0Q2OE1QWEVSSlZFNlE2L25hYzgrZFhGd3RUanJvdXR2USsxCk9SK1pZeFc1QmdDSVphU2xPbnc3UENOMjlObm9BUTAvMkkrL0c5dHBITkYyWkxCYXh0bm9nYkxyNThWMXlhVkRuMFFJdnhHVjd2QzMKQW9qeFlHTmp6QlNXRzl2cHhEY1d6clBMNm00Mm5wcktTaE56UFE4V1JZMHZ1TlJwRkdIMHRmV0FGVkpQT3dCSU91SWI5U0RvQjVGaAp5alVmN2t5ODJjQlQwNHJQVys0ejNHN3RwRWcvNjJCMUpVVTZNQzdPeWk0bnRzc3hJeTF0T0g5YnliOWU0dEgyYmU3Z0lBQW9XMlR0Ci9hTmZ4RWl6eHV2eDNvWUEwTEZDT3VCZzI0LzNqZG9qSnNyaVZDTUhJTnB6ajR0ZG1pUmhUT3VWT0xGdGJteW5VOU5QeGRmL0JCQkQKd1hlaXI3MWlqazRSNWwwdkhjcnlMOTNwbUZXYW1PdFArLytrM3h1WlhoK1hSZ2RmYnYvbWc3MU5uenN2bjlwdzJISlc1OVN4WGdDQQpJY05lR3I3SHl5ODhsQjBWUlUxOGVPTkJ4b3JtY3diQlh5Qml3S1NveVFQRDNIN0FaODdMcHphWHhxejVUQkV4MFVQOTFCUmZsYzEyCkMrVVBJMEs5aGd4N3liS2tFRkR2YU1CMzh5d0d4N2NOajhiTFZzdGVzbDU2TzMvcWNyT0V0dWtSb1VPVkVsNjJXbW9VT1U4VXZyRDAKQTZ1azJnL2VjSm00Z3o4eGVXQVlWU3dvVGMzS243SzhHd0JnSFNjempKcjRNRVZRdnFBc1ZSNDlOaXFuNHVhaXZQd3BLeXppYzFkLwphRGc5MkJzQU1QNklsWDArT2dKMitWWHZPMjh3Yml0eHJjbkwzT1B2cnZvUWtkWkQxejVJWDlGMFdEeXo1ZmE5cWN1N2Q4L2p2MS9SCnNHTkIyWi9OWHZDYURnQndIalpYM09FMExBcTcvS3NqQVFERzA4YU9TbWlmWFpmdmVsWnhTRHlyYzFxd2w3SUROR01ldnB0My91RWgKOGF6bXJQeXBLN3JYTGh6SEFXQ0EyejhIVDM1elFYTnNYZmlDc2c4VTc2L3dJbm4wMkFOWmV0K29xamNqSXdDMkRtTGZJYVl1RGNmZApST05qSjYrUERHUUNwVGx3ek1nMktHREx0UXFacmJ1WFQvMlE1RmNuTEpEbnRPTHNVTzh2UVRBeHdYRTMwWVJMMXNIMmc1dW5qK2xTCnYxTVlXUEsyQkFLbWoyMWpIQVRXVElucUFBQ2N4ZzBoRVlTcVFpY1ZqU2VFRnNOQ3BvL3QwTHpnV1E4TnVHZUd1U2NFVmo3MlluZlAKQnI0d09EQW5LNWU2R0dvNndaY1VXWksxdTVkUEErZGs1VktYMUZqM2xadVY3OWp6MUhnY2x0UDlHOVN2MndhekxuVmZxbldVSlV0ZgpXYmhBbnRQSzJGc1R6SVNXMHdJYWNLN05mcHR6OHFzVEpxODdFSGlLR28rVDR6aitKb2tFYzVwelFqTll4R0RzNFZyVGRsMzZ5Z0xsCjdpV0J5R0xZT0NFZ3hKUjErd00xNzNkalh4eFFzZVZZcDJ6eXV2MkJNVnpqOFpZaXNTTS9xMlJrNWU0cnR2S3VUekxEN0pPSlErRW8KU0c2cSs4cFo3OXVoOVdaa3l0MVBCSkJ3YUNZc2hpaHUxa2RBcnZ3TUVDakFnRVd6UjNBQUNWQjdhdmJyWHhwT1o3Q1BwendBWU9RcApnYmtMTVNaZ1h0ZDJwZk9EeUg4bWNmeGVLZksrdWlkRG9BQTRwdlZGdUR4aU9RbmJTYUUwS2JmY0lQTXVDTWo3MnU1MFRXaHBEdDZaCk1IYmx0MnRwandoQnFIRE5Eakx2MG5TQy8zWVRjSzVaUHQ1MUFOeHlnc3psakRFUWxCZ2xmci9IWU9ZN0w1cFdPQVk5K2RKb09nRWYKcmEzakc3T3REZXFxUFQxN3RlSm1YWVJMZHFCRjE3S0lGVHorNnBQSlRKMDEzeU1DRGdRQlRNb2RneHFWRzhEa0FJTkJPMGpCcFVvagpvTkRBOHM3VzZ4WU5BWGRUR3VHYUUyVEdsYlF4SmVaTGpBOEY2aVdCcVl0NUZsaTNpOFRIdXc3Yy8vS214WXlTcXR3N0ZlVzMzdDl5ClpPQ2tNd2RESm5vZmZzRDMxdXViMUpJY0ROeVVmUy9oVVVXZXBHeWorOHNEdmoxVFdmbld1dGVhWWJIM1htbnA1azhQMjQvTHZGMWEKa2ZIbG5SZjkzdDFDSUFiVWwwZ2NNNi95eTlsZjVMemc2NzJqTWVkT2ZXbGFRZmtqL3ZyL1U5ZEtObkhqMGVyUzVLTE01S0tzK1draApzZTBsVjlrWDJTOG9TUlZKUlZrWjkyb0NYUCs2LzVzbmo5THpxKzZuRnpieVo4ejNwaGVYNW1lRnBZYkU4bnpyK2xKSjZxT0svTXowCm90SjdtUjcrL2g4T3liblpNVDkxZkd6SGcxdVpqNnQ4RHQvbkszb1p2Znk2Z3lIYk9QcDFpd0hmbnE3S0xxcGI5a3JHZzNUSjQvSTMKMzVvdkxYdlBmZTZaZytNbkxrZ2RmOUY4VGRjS0hzTHdkLzFMNUE1RlVtWXAvNDNzdmYxVzVRTkpRZHZHVWF2TStXdkI2OGpOa3FzWQp0M3R2MjQzVFA0NmY2SDNvUG0rU2dmdGlsaGxWYjJsSVBYMXdRbWhZYXNnbHUvZkNkdktZTHowcWU1QmVYSkdiNWUvKzE4anRZKzFmClAvbkExcy8vejBNTEtoNGQyS2ZQZWY4VmlDVEVpR3UxZ3FMTndJakpWVkhxNUNJQTFHWElDVUVNQ2tXSEpUcU5GRUxJT1VNb2hBQ2cKYUxYaTcwL3lSbHNtTy9GYnRUU1ZERVhEQUtVY1RVdm9icklETlZuSjFMVDhObE1BVUR5eDdSR1dva0VzMEFVS2lCTXc3U3Fhb2lwSgpKa3ozdEZ6Rlpld3dZaDNHUUxzeDR6dWhxY2gxR1NzVUhaWUttYUV4MEdhSzdpWTdsYmdHYSswbERsVS8ya3hVdVh4T2syV3JoVUptCmFLenA2Qk1yQWVRTVFrV2J5SVJZbXluUWFpcXo2S0Z1Z3pVRG1veUVCa3F0dThrUStrdi9CV3lsWDVKVWc1YnZiUDRjcGZyanU2bXoKbnMzQndET0w5VjJsejZ5blFSVFAxMDR2YVUvai9mM1h4R3I1OVNLUy9JSWU2L0NXL3M5RzZubDRtZjNiNHRQb2s4ODJyS2VlZTZyVgpQWHNRLzZWSy85R2s1M2lYeWw1cUg1SHVTeWdSOVZHUmFaYmQrM2xwMVZySjE2THQ2SnpySmJVUDEza2FEeEdrQVh6Nm9xUG9UcHR1CkVkWkxacCtwUDJZMTAvbEZXditnVFZQcVI3TStxRWlrcHFub3NxMmdwL2QvUFh0YTNCVWQ5YmNhZm5vMXRDS0cvV3ZWWFdhTVZXdGMKRnBKcVJMVkpQbHBEcG1HQU1ZbzZsVFFORE5VVHluczJxN3Q5UW1QRmY2aEdEN3ZvTWNIUXNkaWVONEQ5YTFST0ZGbWZSZjVRL2ZYNwpZSGdjV3Raak1wVngwblZ3cHJnVEwvMitMNStJOU1kcWdLRjk3VThBcVZFMDNqNExObW8zKzBhMWFwU1l0dldvTGh2Tkh5MWw5SFJQCjB5ZTgwRDQ3bTdndjduSzl2Q3JlK2oyZnNZL1A3c096SWZGd1NnL1BqSnl1UDQyT2tVVGF0ZFUrRkxtZWtvZ29rbE5uYzcyYjZwSEoKRVYwdTZsa3E3WFhhRnMzMUtLdno4OUs3UkJ6Tkt1dTdPMFJhR3lYbmNocDBxeTk5Tk80YVZUVWlOVjNrK3RCT1N4RFhTK3psNHVlZQp0UCtEcEZkWTZVek8yMkRqQkdabjAreU5mNm80bGp2Z0V4UFRuWVk3QnRzL3puaWw4Y1kxMzMvRWVBNU9QMjl2ZFdSMnpnKys3SUNQCkVlNUZjanRHbXVWZkwvRW8yRWM3UnBvemRQMVk4djM0eHdtNU50OFlEZm5Ceml6am5IM1Z2c2Q1YldscGZnZGIzZlpablJwbWNtU08KVmM3RkxrZUdqdVZTdTUvYUQ3c2tYQnhXRk1udEdHbWVucFk2OHVLdE1rL3V4aFdMdSt2ZDdjTDlUTTdlR21nUmx5S0ptZElhRnllMgpKZFp4OXBxWklLTDk4UGowOHdQRlFINGs3UmhwOXVUaWJjL0hpNjI5alhGdjMrTThyNHh6OWxZWDA4dThhbTdOdTJYYUhPMkxBNzVHCnFQbldjTWRnKzRiWUxFOVJSbHJxeUl6VU5LZHd2NGE4ekllQjdPaHNwVUlBV3VLdWlHc2l4eDJzT1ZnWnFMaHh4ZEsyUENIWG54ak8KUkR0NEtWR3J6blBYVEZtRTRkZGlKeTdsaWlVWDdpYzRrMkEyOEpacEVGQWI3bmZqZWxiTUZNVGRxRHNTTS9SK2lzOXlxZFhQbzlJdgpEMXhzNHhydVo1Si92WFJvUVNUdEdHVjI1VWF0QjhES2syOEZsc2RmRENpSzVMNFpXUlpKTzBhWjNiMWU0bEcrMk5yYldIL3ZabnJkCkdadmlCY0JnNE4rZGwwOXBya3JZRlAzZy9YZkZKMnRudkFvQXUzeXI5czUxQzkxdjdiRWVKQmgveXRDdzJ3SnczU3Z5MjljUXZxRDgKUTlkSWtlOCtnRVNWMTE4Vi9qRDIrK3FtU3NpSDdCZDdySGZiNStPM2U3NjVZVkV4MXhUSTNnZFlWc0cwRlFyQWVQclkwZkd0TTNaTwo1STY0N2hYNTdzUHVlUmJWU1VzM3MvQ0JrNzZmUERETU9rNzJtZk95cWZVR0J5WS9URGtzbnRVTVJ1ZEY0N2FLRTFwbkhMRHhlQk9BCjIxNmg3ejYyYnU2b0tVTUNYcklDdWUzejlqdGc3YkcrT3ZtMVRTQUJDT05qREkyNkxRRHJrOUlaQzdGdXp1Z3AyRFBmQXJ2RHpLM2oKWklxUzE4NGZaVURXdldrcitRWFN3K0xaemU3Um9yS1lOWjl5RVFNblJzbi9PZmI3VEVaNFJmeWFWWnhNRkRYcHdZM3p3dUN0TnZHNQpiM3lFOElHVG9xempaT2NOZ3IvZ24zRTJjVEtEcUVrUFV4Nm1MMnVhNnpaUmtHZzhmZXpFK0phZ2Z3NEptR3R6VmZZa2ZFSFpoNjU3ClJiNTc3NmN2YlNhZzY2dTUyYVVSb1hUVWRhL0liNS9iWHFIdjN2cUlCZVYvZGc1NFNhekhqejQ5R2htRGJ6MEJVQ0pFbnNadWJvUGsKaHVZVFo0bktsQncxQXM2MTJXOEZJOUY3TzgrR0FUQzJDZlY2a21pTzJTZE5yRU45R202dFhGbHE1VC8yWmxQdGx5N3JJaXZkY0U1bQp2OVhZZGxpQVk3QUxzeVltOXR0NEU0eGlGSTNIRlNDQWlTeUdqOXR5clZMR2UyVjBHdWM4YU81NUJaMGY2djBsQUpFbGpybUtRbU50ClBUeDlHaWF2alF3RTJBSkZkcXZJSW1qY0dabjlWZ0FtTnFFK0RmVUZSajUxRlFRR1ptd2JGSEN1elg3cm9Ebm5PWDZTUk85K2V6YU0KQ0labUUyWVo1aFFZK2RSVk9BWVBnV093czhnS3pOUGp6UVJpTElaclBNWWIyZVMxa1lIR0pnSnhzTVBnNXJNZVBsOG10VWkvZE9OdgpLUWFXc0hVZjZsdS9RSkVyRTFwTzk2L0RXUS92TDBXV1dNQmx5L2kzSjVFbGJOdzlmUnFjVTVhTUo4QVdBSU9BaVJnQWtRVVN6REhyCmhJbnRCSjhHRjU0N2QzVVEyKzZ5SmFHQzc3K0piYWpQazBSenpEN0JYL1AvZzA3d0FMeWMyQWhJYTcwellUNUVuU21IMXhBbFJ3MGMKMmRZR3ljR0FwV2NlREFIQUJCQ1FUd1pNbmNIQUVMajFTeWNHdUVyOGZhUWVobnVud1ZZYXFBQ0FaUkZMRlF3TWFQME5DRzQ1UVdiZApZQUFIY0ZnOGM0VHloWGhaeExMazh5OGJNL3Q0NVBHM0J1OU1tRGtUZ1lGTHE0OEFzTTFnQmdHQVhXMlFuTDh5R0Urd0c4QTRwY0syCnRVSHlHK2RmVm5uOVdYcjZ3UkRHQUthQXA1KzBBN1lEbDRVdlY2ajVlZzB2TVpCcmpncWFJcjRaQUF3T2laVG5tdUhuVTh1ZzhUdkEKc00xZ09ta0tnR0diYUFieDRKbktGVUhOeVptcmxlL3ZIQXpiT1FYQWdUR2xhMG9BTmFkbXZnSEEvWXBDVnI3NHhSSHFEd0pHdkxOSApjUHJjSDZ0WEkzTUlYN2JuVlA3QVRaOGN0aDkvSjd1aUpEMi9zZ2lITDczRXNoNCtlVy9VS25PbnpHdHZ2alcvcHI3a0ZwU3VDZk5MCkNpVUZMbTUvamZ3bXYvUlJab0hDMFpIdTNPeHc5L2Y3WUNqV2l4bmVmQ3ZzY1g1Skx0WjJyVlRrM09Zc2poMS9zNzcwMW53bEV1UjkKNkdaeFBBWnN6czdQS0MyVUZMU3U3VnBwZldVSGQyZkR1aVhOc05nckxaVnMrdlNJL2FUVVIrWDVrdFBSSVJNQjJIMFhVNVZUY2cxSwpaNC81cFlXU2d2YVBWaHhhYitTei9RbVFYNUtETjkrZVgyTjVaUWZkdnYyd0lmZTJYUFM3SUw1M2h5KzlMUHBvK2FIMVJ1dTZWZ3JYCmRLMTRVaUp4eUw5WVBMZStKRDBzTlNUV0l1UXlnSmpva0luM3loOUk3cFJXWm14WSsxcXpSNERmQjBNQlhDL0tsSlpJMGdyTDh5VjIKdk52RnpNY1ZHOWErMWxSWElySGJkYnFxSkM5TEFkU1ZaTjU4Vko0dktkODRkSzZUNUZwR1lhUDM0WUlKRzQ5VmwvcHNyeXZKQ09BSApxakN6NFA3R29YTUErSGlNL014NXdPYnNleG1saFpLQ2pPSkNTWUdyNjE4anY0SFA5aWZRMXdJRzlMNXBzWnBUTWJhVVh6dVRLMXY1CkgyMjhKMEdWSThWdkZacXZ5ZDQwTGhrUmNaMmtMcTV5SFZpbmRaNVVOTFFPa3ZOZmNWMVNwUXZEN2k2MW84SW5TajNrelIwNlBnKzEKSFRyeS9oblZuRFpGQjNGOE1ZNklhSmVDK0k2b1BEbDJTWlVPRDRua2pScUZLazRUN3c5Um5lU2RwT01tVXBuVVhoYTU3azRpVWpWRwpta0dUZHpieU5EcWlicUluWEl0S3UzcmxwNmRjNWN4U1JyMjhOdFp6MnAzUlI5SjMyQnNIcG1KczhiNmRPcDg4TWVQWHpVd1lJQUlFClJpRFFwZG0rQXFXL01ZQmdyVjRhVXlaVEVERkRBQUlqQW5qQ0c1UnZLZng1QUNvYW1oR0VZSXdJQm5iOEFVUUdwT1RXaWNUS2RUZWgKaFJFREFVYjh6WjBKakxYYU16TUNTS1JhbGhNWWdobVJrSC9BWFpybEl3Q0F6b1lHVTRETWpFQUdkb0FCVHhJU1dta1VxbjZaQ0VJTApKVU9PUUJBYWFsVFZYUFV3Z2xDNWFpb3lCRURNU0ttcytqMUthR2dKaUJoQUVBRmlaczVUQlFrMnlxVXlvWUdWdWwxU1YxZCtQVEFWCk9WRmZTZDlzSlZMdGxsRTZlWlBXR2JycjhMVDQzL0ptbXo2cjkwZERVbzFoM3h3MEZVV045WTNtY1FMdENqM1c4cC9LM3lBd1hsTmkKdFU4TTNKL21QRSszajMxd21MUkg0SmN0THVqaWxGbys5UHJTNDlkSWVqU3lQb2x3L08vbkJLcDdaR3VHc3grSGh6MjlOdmJDR3pVVwp5MHZwZ3k2bGhabXFqM3FjNlVkTlRYczY4OTRUaGlYTk5kYTM4ZlhtWlBZdTFiZER4WDdVNHhtbWVqUTUvUmxaNzBsQWo4R0dydVd3CnZneXlmOGxLaXE3V3pHcU1BdHBXMXcrTHMxZERUOGU4bjJQSEJIcGF4MU90b0w5aGV2WUkvQktMK1ZWdVo3OWlLRUwyZlF5QUc1T1YKSFZmK1VacER5bVFXRmFNY0VLYU1sS1llS0FCQStDWjZvd3JxbWtyU21HYTgxUTRGQ2V6YnJ6N2FzT1BkSDFhckdpSnRwRmdOSDJ0UAp3SkZkRzNTbWd6K29HTkZRc0ZHbGFRK3RBQ0RxbEhZVnB0TU1WTHVEbnpFcXZFN2F3ZUY2UUk3VXV3cmJ2MGE3N1RlcUFZMTYydVh2CmpPbzlrSHBJK3Z6SzZDdjFROTlTQkpMeVM2by9wdG0xRGRRTDVkTWh6MmxEZGZUOVczUWxhN2x1YVU2SkhGTHZadFRjdEI2aUpqYW8KZmtYMlB2bk1wSTBoN3V1TmptcCtSL2FScVp0NmpFcmE3N1ZLY3pvOFFWM0VVdDlzT0NMU00zYlpjZmFhcWVJYm95SFJOb3BZaVJkRgp5NXlWOUMwQThmRzVoMFp2ZlRnS09iR2RUbzAvRlY5L1BWcm1jdkZXbWZNS3FWZm1EY2NJdyszV1R2VnBpWVdXL0dkVDNwVTc3YVBECi9jeXVwRWlMc21LemhwOHVITFRITG5lRG0yOXViS2VUTWdpYTVxYmhnVHMxTXozcWRCbHVxRWhPRzg2ejgrTGlUTjdtQ1czRThxNlgKREczZm1UczRrQUVvMkMza1NXV2xpYm4rK1BIaHBkOWZUeG1lSmtrWXMvV1VaMEhLY0RxYlptLzBVODNCQ242cHJPdEhtU3lTMnpIUwp2Q1g1aXR2UmtxangxUWwzL2N2aUwvZ2JYMG1SZXVUR2Rqb1ZwaDZmQkFZZ2FZTmJaZklGY2JFa0llaGd6Y0dLb05hNE9MRXMva0tBClVYbHkydkF2VDNrV3BBeHZpTTMwYWdvMzNHNnRWTGVjVjNlZ1JldVZPSk8zcFY1RmFhbHFBbkJOeHF4b21TVlA2UXZvQ3ZmZGVjcXoKSU1YM3A1cURGVUdLK0l6YzdrRUFVTFpZN1AyalgvaElzOUxFblA5ZEozam5SY0ZiSFJvcjBlMjhiczdZS2FLU0lxeGRFQUlBSUJnZApmS1Y5eHdkN24yVGRtN3E4ZTkyQ0VFNVU4cWc2YWVrbTQybkJYb0pFOGJYY1ZSOWlrNWZOT1g1cFFQSEI4cUVReDhudXB5OXZidm5uCjNBc243V010eTRzbUR3aTduVDkxUmRldStlYlFldDFVUHhYS3cwcFRzL0tucnVnR0NPajY2cVdja3MrY2wwOXBPQ0tlMVRHTko3U3gKK3ZBRjVSK1l2dUExblFHQTI0SEJrOWN2YUw0b2p3Nk95dHBqczZBTGdrVGFQZS9DdzlsdW9ZSkUrc3hsK1pUbXNwZzFmNWVEQUlpSwpIcm51RmZuc3c2WVoxbGNyYnl3U1JnZEhaVVdFNHRpRDlPWE5XZmxUVjNZcDNYOENrd2VFR1J3SUc3aDczc1hpMHBnMWYxY2NFczl1CmlnakYwYTZ2NXVhVXpIWUxGU1JpM2R3eFU2empjMWQ5eU5kUXFUdTEvcEI0VnNlMHNaN2Z6YmZRR2x0UnlTUExwTWNmL01FNTlCdnIKT05sc3QxQkJva0ZaekovK3JqajArSVZQUEFBQXpnRXZpenVjaGgrUVI0LzlQdXQvMXNnV2NOa3l0ajZ5MHIyK3dNaXJya3BNc21KcgpSK1U1V3dleHI1T3BjMk1NMTNpeXBjaDZzRUFneHFDNUZ6Z0FzQ0dSNVl5QUJyU1UyYmtZQXdBbERzVVFNckNFeS9YRjQyMjlmRmJICkNRRURBRGpKTlI2bkljSE9wUFdLeFlpSGJlQWtkcGJHY0kwbmVGK09Wd2ZoYTlkamJxS0pzUlBYUmdhcExESFJITE5QcW0rQ1JqYnUKdnRaaTd5ZEpUYlhiWEE1TllvNndBZnY0UkllTUFUWmd4MXhGb1pmRXdRNkRXdmtJWTliTXhDYlV0NkdwZ2kxWmJPazc5a1pUN1RhWApMZkVWTXVlVXhlTmp1TWJqTkQxWTR4TEJ4dDNQWWN2eDluYnJZSWZCTFpQWDdndjZPTDVDRmplWWJYY0ZZSVA2QWdQdittckw2UUVOCmZQRzRRZGp1ZXRSTkZCbzdhVzFrRUJoekdxc005VVlnTUlFWVFrdGZld3NQcndhUnBRQkVOaENJeHc0YTNOcGNadTVpcGQ2UVoremgKTEUxdXJOM204cjlxWlBTVjhBV0NoK0hlcVdKcEI3TWR3RWhVM01aenUzaGdqUkdEVzA2UUtWY2lZd293dW5IK0pTT0FBNzlmbHJBaAp2ZnNqM216TU0wRUVoc2VuWnEybWJoaE9OR2lEZ2dONDJISlorREt1NS81RC9raElyamxCcGp4WDF6MU8wVmJxa3dtVElVaHJDRmRCCms5N3BNSE1HNmU3WEpWZUp2MCtkaFlUQU1jaldMWEFtNHNDSWh6N0JTS2k1YWZJT1FSdVJ6eGk1WlFUNFNCZlBIRUUxSjJldGRzMEoKTXV2MnZySW5YVm1TUUpDdGZkV1p3Q0FBcGRWSExKazVrdk80b21ncmdRSU1ZbWtIYkFab05nNFB2YUtRbGZwa3dzeVowdXJEd1dIWgp6bVVLOEo4NmpLZnlDWlFPTWhpQmR4SXZJTWE5MXBMOG83TC94SUVnSUpjc2Y5NExxTDZTWHJkZjIrNCtYVjJKOVdJbS9HajVvZlVzCko5dmczYkJ3YVRFQUlMT29NdnRPVmFsa2ZtcklaYnQzRjBSSTcrWGNNYit5Zys1NEhTcVFGQllWWm1UV1ZrUmZpZnlLeDVtREI3MSsKTXIrb1dGS3gwV011SklrNTg3eXl0aFhmaFBuZStha2hsOHpYZHE4VWp1VzBtMjVLektoRVJsSFp2Y3o1YVNHWGVSS0tqOXZJdjd0cwozSExFWWRLcDZPREpYb2Z1QVFBQ1BQNjZkNGNpNlhZNUEwQ1B5dTluRkZYY3ZlM201L09CeHp0LzIxcVRrbEhZOGZoVGFacFQ1dFdNCm9zWk5XNDdZaDBpeXlpdjQwSVRkdVhmdWxqN0tLR2g3WitRcW0rd2JYZTRCdmg4TXRkdWNuWDkvby92YytXa2hsODIzNXI2b3BPSloKUktibjF4Zzkva1I2VTVKVldpR0ppUTZaT09EOTJ3V09icU0rZFhXNmZUVzlzT1dqNVQrLzJmSXdJN09XMytucjdUN3lNNWROVzQ0TQpuSFQ2eDVCSlhvZnVyKzFhS1F5NXdwdFAxc09hN05zTmo5SUxLdTVuUENvcWtRekp2Q29wbEVxeXlpc2w1NVAyZjFISnQrbXovVmJGCkE4a0RCejhlTDlWZjB1dG5SZ2ZKaWJnT1RoV3RqYU1XcnJrM0xzbXBISHp5UUtQcUE2azdvcjN5OEcxbHFjYjJMaUtTZHpaeUNSdnEKU0N0d21veTRMaWxSSy9FTjlFNXQ2bTlLR1hIVTNVaWthTzdnMFR5T2lMajZQbXZKaUtpanZaa2pvdTV1dVJMODQrUlBkRXR4V3FWVgpqa0U3cUZ2ZTJVaEVNbzZUUzFWN2U1WFFhYmNTVnBRM2R4QjFVTGRTS1NJaWF1M1U3WUdNK0FCNzh1WU9JamwxUzVWNGFGK3BTNjNSCjd1YmFPLzlVSG5Rcjl4SzNrVjdUcitFRVR3VXU5WFdXMEdPQlZDczlXUlRnYXhmV2EySDA4TG1Ed3Q1MW5zMTVlNXIzUGQyMWVHaXYKby9aVCtEbDdyZHV5Sm03S1V5bEcvYmxjSXlZWjlaU0ZXUDdNQ3BOaEExOFU5OGpYcnljOGZhNzQ2eUkwejFkSDkxZU5uYkRIYVdKMApuNXdzOEh6MjlGeHRQcy80L3d1Y1RQUnBKODlSL09rRXUyZm5OQXZNdGZKL2pTWC9YNUhjKzY5M1Y0Zm96ZnFROWt3RTcxOEFkNTRMCmIzNitQdjJMUGYvbERoU2ZFd0Q3VDZkZkUxYnFGOWRRaDNlalh2bUFEdFNwQVluVWZFU2RDRmw5dE5sTFhGOFVUYWJGMmV1cktwNk4KRCtuMlJFZiswNjlzNmxXZG5xOTBiNzZuOXNYNFBPcitoNUplalV6RlllVDVnb1Q3bTZpUDNwUEdreWNEcVhpU1JFcWVKSDh1TTFqMQpTeFZHamEvYncyZm0zRDYwZUtOYVovUzFIMzNoR3pYSXB5cnluTHBaNkpwbDNJbTVGMDYrMUFFQU5STUxvZGxCcmQwVmZ1ZFF3U2JlCjYyWlV6T01KWlZoZHJjTy9QYkpyZzY0NWEweVFHQjVQS0ZONzMreTl3d0RFajROdVVncFE5b3NSb1dEVFV5NXBQU1M5Zm1iMGljVngKUEhXUjQzb1cxZVVoN3RPbGEvb1NSeHIrb0pyOHFDMGtVbGVBTXJhNGVyc3R4Mm1mSlNJbEhxcXB3RjB1NWk0WDkzWWdTa1JFTDNHVgpjN2hLSXBLZXBKY2Y5cVJxcW1GS1pkTXFyNXM4S1RTU2I1MGpqaXIvUU9XcXpxb1YwdXJLckZMT1QwdVNWZ044SVQ4aTRtZ2ZwK2xnCnp5SVVxYzd0MFk2K2tsNnh5MnVKT1lkSGIzMHcra3FLVTdqUjEyS25LeW5PRWNKdlJHWGhmbTNmanNxNDdCWWgzQzRxMitGdkJlREsKN2Rpc2tZbEo1NjB6VlR6SkRlNjJFYjVtMlFsMWJtbVNoREhZL3ljR2xDKzJvUjhlNTdWSUVzZkVLZm1JVWtmZURlZ2x5N3R2dW5INwpKOUhadElGR1A5ZEdWdzREWThoSVN4c1M3bC8zODZNckhVTXl6dHRiQVNqamFZazdScHJuWDhwcG13VUFPZkYxUnQrT1NMOHljSWw0CjhHSnJ1ejMrTjY1bnhrd1czTXhMcmhrS0FHZlQ3QzNPUk52WFJkdVBKOWF4b3M0ejNtdW5yYU9jcDJwMi90eXd1OXNMWjI4TnRDaTgKZVhMaW85VGprNjdjQ1ByUmM3ZUxaYlRNK2NpY3JnaS9pRk9lQ2RkSFZCMGJCZGEyTTNmdzhETzNCbHJFSjEyd2NpRFdFaGNudnBPWQplMmpVRnc5SGw4VmZDREE4T2tlOC8wOEFXRXZ5Rlc4NmU4MXNZRVphS282Tis3bkdJelV6WVF6Yi95ZUFKVzF3UitUai9KYk1oREZ4Cktaa3hrOXV1eElsTnp5YVkycmNrWC9IKzVwVG52UnZEK1hHb09WZzU3TkhORTVQK2grOWtOeVkvV2ZjWDJZZ25jYitWVDk5L2R5ckYKL2JiN3haakhyb1ZIM3FicDFjMGhpcGt4ajEwS2o3eE5SSFJ5NXIyWmg1SkM3dDdaclBDbHJ3c0szcWZoMUQyNUpHdXZmQUd0b0RrUApLSkNJSTVwWDNPNlluYnVDNWp4SUNIMndPT24rMzd0UEhqK1RzWlMyRjl4N240S296Wk0reWVyMmttNzVZL1ZRT1JIUmJ4Vkh1eWVYCjVMV1dqR3pZWFhEcEpTS2lkMnYvRVNsenVyNW5pM3d1L2JTQmlDaHpyM3dCTi8xeFV3ak5LNlo1eGQyVFN4SkNIeXhPS25xRFJ1UVMKRVgyYTFlMVZUMEZFUVVSRUZQNVBDb3NwbWtHN0N5Ni9URVR5ZHo3S0hsTHhhVmEzZC8zNnhpTzBydkVvRi9jN21oaDMyWmY3Nnc4MAp0N1JyU3NtZDMxSnhLR1ZkSlNKS1dVZWZaSFY3MVNlRjVEMG1vbjNKajlKVEpqOVoveGZaaUlaM2E3K0twSmRLS1pDSWlQc0RkL2pvCjhUTVpTK20zOG1QY01EcnpvWG9jaUNpSTJoMnpjMWZTbkFjSm9ROFhKKzlMTGt3L2ZpWjlHZjJSTzN3cyszZGMzRy81UnJiOHNYcW8KZkgzalVUM2Z5ZlQ2VG1iaklQWWJZdXI4eElZSnJLYjcxOE1XSXJHUHZaV0hUd09FVEFTQmxmZEFzWWQzQXdGazQrWHpScHkxaDMrZwptaWRKRUZyaWNLRHdCRDQrMWlGVFhpRU14bmFCL244NzFpRlQ4UkZERmlpeVpUZzcxT2RMUU9rR05QU1M5VGdIeHhZQWNBcDJGbG5DCnozREZYdXV6YlE1YkFXQkxmSVhNMURiVTUwblNVT0w1WkVjQ2hTZVlBQWJRSlR1MmxNSEZDUUNPdVlrbVhGUzlrL012T2dFdWRUalgKWnY4RkFLSGw2TUI1VjQrNWlTWmNuQjdjZ1JuQjdjeUdFWTM5alYybEdBQU1MQmdCcnA1SlNkTUFnREdjY0JPRlhyVDI4QnNJd3VSMQprVUYyOW1KZkoxUG5wby9qSzJYcUY2bm1TclprMFFKRnRneE80NFl3QmdQZzQrT3FjUUJnYkJjWThMZmpIVEliZHcrZnVzbnI5Z2VGCmNibXRUUlZzeWF2RU1Sc0JqcnVKUWk5YUJ6czR0bWpqcC9wSmV2VVp5NVI3K1BoWGFxYjlLbXZRemluNGpZZkt6WVlLR0lRQ3VLbmgKU1JKamNMdUF3cloxaTV6Vkg0RWNnTGIxZkpoQ2hwcVRNOS80MG1BRzRKRElNeXNKM2hsazVxeU8zcjBzWXBtQ0FlKy9PcWJlcmphbwpHNENHbG1tYUJWSUFnTnNGRkhZYXRuTUtFQWR3L0JnSk1HekNoYy9GQU9BdGdia0w0NGt3aklFNEFBS0NyWktxQ1RrTVE3MGxNSFAyCmp0dWQ0UjIzSjRNUll3ek9UdnpMT0NQR0FlOS96THRRSklLWFZoeEVMcTArZ2hqQUlPQ1d6QnloV2JTemVQZ0VlZHRFTXdqTHdwZkwKNWVBVXNuV3ZEdEg1UUZabE1NYWwxZS84U2pTZExCNCtRUjVQMmRFRVcvU08yeVBSN3plQTZOOFg4WHlKQWNnb3Fjd1JWcFJtTkJVKwplcGplOExoQ1VsaFNsRTZWOXpNS0d5ZHNuRk9kb3pvUUF5dzlNV2ZkcWJ3YXl5c08zSjAzZnoveUxWanNXMUNTOGVvck0xWXNxOTVTCmQ4dWsvSkVIQTN5Mkx5L0o4YXZlVW44TGo4cnp1KzIrWER6SFlOZXN5c29OdngveEZpejJUaW92M3JTcDNqN2tnSFZaWmNZTEFOWisKdlBKSmlTVDMzQmZSOU9aSzN6WEVnQUdielZveVNnc2xCUUgycTgwS0dzWEFxNi9NV1A2N0NSdm5WSmQ2Yi8vTVovczd4Wks2b3ZLOApMdjhqMlZhclF3QnMybFJuUHpHNUtGTldsRGtLZ00vWHZzVVpqWThyMzF6cHV3WUFjTkZ1Z01lbVRYVU9rMVlzZWRGM3paSVhmUThWCk5nWHVjMS9XbFdzMXQrU1dhVW5HMU15ck03d2R3d0JBa1p4WnRtbFRuZjJrNy9OcTdBR2NGb2Y0U1lvcmM0UVZKWmtETnB1MmxwVGMKYWl0NzVNNGdlR2YwbEsvc3ZwdFZWYm4yNHhXaUladU04N3VxUDY1UE15bDc1QUhBWXUvRWtoemZ4MXZxYjdGSEZmbmQ5OFRqL08vdQptbFZWL2M3b0tWOGg4MnBSWWRPbXpYWDI0NkxFcFpVWlA3NzJnczk3bGx2MGFXVjZmanhySmQzdm5DZGNxL2JKaEExMWZJRU9UazRrCjd5Q1NxeUlKVXBkQ3JxN1pUVVRVTFZjaGdGMk5TZ1N3dTFPYldhbE9uVkpOMnlwbXBZYVcyTmpleFl1VkVWR2prczJvWmlqRzVqZmMKMjhHTGJOVDVsdTFXZlVyeUFqOCsza2hFWFUrSTVGSU5XbG12OWFuTGRSTnhPelZhZFRlUjZsdFEzc1FMNFRnaTZpQ0ZsdTR5SW1vbgpPWFZKaWVSTmJRcnFWc2hWbmVHNW9wcHhhRzRuNnVEa2ZLVWU0eUNYY3RUNmd6NW5Xdi9ZcFJiVnBsK2lDTEZENTM0UzluTlNrOTBICnVOUGZVcjFXVTcwSkhqM0s5cjF5VGp1dmozRWQ1cWVzM3grY0NORGFnSFY5eXlOMTdDNWluK1dFRCs3VmJuOTRyblp3T1IzYVVUOEwKd3NxRmFxWmVEK3dGbGVVUHNZRCswcS9uemxNcnF6ZENUUGZaWUF1dFFtcStrYmFjL21CMmJmeFpwMTNkMXA3dENyT0hlY3FmRE9pMwpWVTFXYXlXR0NyVXllMTBPQkFhMEdEemRkWk5tdmJoLytFckR4OUpxbzNjUGRJUEU5VHNWLzhHa2IreVNXTSs5QnpxRVFQUmdzZlVhCkVoNFQ3d2RHN0l1WnFKVUhoajV1QkdyWXBiZWw5MkFkSzBuQTJsUStiU3FtYmp1OU5OZTVoL2U0YW5UdXJiMHNzOWVXRUNodHRiOXQKSjczNG0wb3NRc3NtOVdwbCtzWXVHU2svSVZPbThDWUZwZ3E2Um1DTXFUOUIyUnRWS2dCVE15QmZmY0JVTVJEVUYwZkZpQ2RhV0pBUwo2Mk5xbDdBOG5CSVZvK1RNRVFQUS91WUJxT2VRNFhGSW1mS3M3c2d6c0xnVEwzVW9zNU9tQ1FBY2lLbWVVS0ZDcTdSWmQrcGFwQW5vCmxqdENZMU5FT3AvVGpHbUJyRXpuSW1FQTdtOHNDMnhtb1AxclZGMWcybDVNUVF4TUcwMVRkMVRwOXFmcm4yLy9wQ29LRUdNcXliK0cKamVuWnlFalR1L0dOZkw4ak1hSkRPZTdRK1gvL1lOS2RBZ0REdS9nQzJ0UGxaS0VsbnBmUE5NTytuLzkvMVh3Vk5nMUNwSW1iVmpzRQpCMnNBdXY2UVZWYThjK0ZlSXlWVVByNEpBSzJlUDBoTU9FOTFwMVRsQUZ3cDFhcXE5V3dZMXFYSjdCRkxVQWZuVkMyNGFYSjh2bmEyCllBUVcxTmx6Yk5SclA3cHdKd0YxcHpRdlh5ZU50OCtBY3NXazU3VkR2WEwrMDBtdnNGTEh1V3ZtZ25ERDdUYU9UVDhycVhCSkc5d0cKcGpUR1RHR2xpYm4yRVczSEp0Njl5RFBXcE9GK1hGeWMyQllBeXVJdkJCZ0JRR2wrNXNQQStLUUw0cnJySlVOeFM1STRtZzQrdlBSNwprN3NYTzAwaTJvNU1CaGhha3E5NEd5WGQ3QjZFeXpla3gvZ1FjbDNSU3E0YUFKYTB3VTBtdjFBVkNKNGN4NEFqYzZ3U1V4V0RXcS9FCmlRMzVOaG1JeDQ0R1RtQUFLNCsvRUdDODMrclVNRkcwelBuSW5NcjlZMWRJemIrM0dCeHRZUU9nYkxHMTk2MmI4a0VBZ1BqNHV6K04KMmZwd1ZGbjhoUUNqeURYSDd3K3RTTXoxQndPNkR0WWNMQStpczJuMmhpb1czYjNJbWp6SGxHcytwNjhFUFQ0OVBEZTJ3M2luN09oZwpIb2lLOXR6dFl2YzQ0NVhHRkQ1UVhPZkJKN3U3dk1vU0xnVGMrc0dYSGJEY0xmcmErOVRSS2NMYzJFN2pjS1B0MW5ZcnBGNUZQQmNRCkpkODJPVnZIWm5vMlJiUWRuUVMrNllvZ09wdG1iOFQvMHErUjZaa1NOMjZyVFh6dXFnK3dOaXlFdnhJbkQrQmpzU21peDBZVkpiUlAKeThyakdXdGtIZGQyMkhwMkV3QWdJaFJIZVFrbHI1MDdhcmgvdmloOFFma0hiUGU4Q3cvMzJvUjFJU3R2NmdyVEJOa0xBSUJOTTZ3dgpKV1F2L1RyMlFjYnk1dGx1b1FBZ0tpbDAzV3ZndTAvVkpFbysrcHl5N2sxZDBhM1VMREZuNlQ5aUQ0bG5OUjhSejJ3R0FIem1zbnh5Cnd5dmlwUUNBSGFGMEZFOEMyZnVpa2tjQXVmOWdQQzE0U25VdDZqd0F3RG5ncGV6c3BmK0lCUUFZSFh5bC9ac1A5amJ5T2o5c25zK2kKZzZPeUFFQlVGclBtTThWbnpzdW50UEFzT3NCdGo1ZmZMcitxZlZOK05xMGZscFUvZGFWWmZOdjBpRkJQQ0JJQWVtRWV3TERMcjNJZgpBSWh5cjYxWVZ4a1JpcU1UWWd3TnUxMmpCazFaRjlaeU1UTi82Z3J6K054Vkh4cFBDL2I2Ymo2L1A5RTFhR0xBdWpsanBvZ1QycWVyCm12NVU4Ym16a3NDbjBQTU9NNzBhV1pnaXUxVmdNVDJnb2JYWTJsSHpRdUZrNVNwTmJKSnU4N0FZTmk2R2F6ck9BWXdKcldqS24vYngKcE5sUDRpdVUrSW1ueDRZRXNZZi9QVFBNUG9tUGo3ZkxEazBVT0NLR2F6ek9MSUxHQWtCVEJWdXk2SlF6WnAxMHZyNTR2S3FYWW1aaQpPOEduUWYwYzlER3lhNDVSTkI1WHNrM1lTV2ZNT2psNVhXVGdwTFdSZkp2SFhFUVRMNnBVL0NTK1FnWnJ2NDAzQkdJQUFtTVRBUGh3ClIvVVFLQjliSjV3eDZ5UUJnSzJEcGQ4UVUrY25uOFNYeTZCWXRaQWxOU2tKYUFKeHNNT2dsbU51UEl0dWNPdjdLNzR4dGcxeVQ1Yk8KV3pEUVB5VjNWQXpYZUVKZ0VUaHVlbkE3YkFBS2ZuRkFCYmkyWk9uOE1JQ0hxMTYrdGlXK1FpWjhkK2ZaTUNOcmR4OXJhNitHMDF6agpDV1k1TGFDQkFEZ0ZPNnRVcmk4dzhxNTdiREZzSElodjJySGxxSnNvTkZZYzdEQzQ1ZjBWMi9VNTczbzFzcThNWnZBdkRZWkZiVHlDCm8xck9JVmVKbjQ4VWdFdE9vSGszQURCQWZrdnArdkpWSHZrQkFEVE1aUVN2VEpnNnQ2NTcxWm5NTXdHRmEwNlFtVUw1b21IeDRBbnkKdkNVd2RhNDVOWE1WT0doZXNKV3ZhNHdBQVUrTzQ1c0NnN2NFcHM3Y3pmb0lSZHFUY0FDQVZ5Yk1uVlV2UG90bmppUUFyYjhCVTBVNQpKTGpiZi9nSytOY2t6bHNDTTJldGJWOE1pMmFPSkJKdVdzbTVTbng5YTVWZGhRRGVFcGk1QUdEMDNwZS9oWUI0UDZicnY3U0NpOUlKCnFmZlZQUklHQ0JpY25jQk1LaDJIOGZkenlHRTBZZkhNRWNUN09sVitXN3JtQkpuSitTVXhEcndUVVFKQXZBOVNsVDRBR0hsTFlPWkMKQU1ON1gvNU9uL091VnlPejIzVzY2dTdEOU16SE5adkNkdFlXQVFCWjdFMHY0WU91ZlNBdXZZcUZxU0dYekFDZ3JrUnk5b2NRUHJ6dQp3TTEzN3JVQWdFUGV4ZUtYTS9KcmhybjhOWEtIOGVOUHBHbnYvZldMbWh0aHFlTXZ5MHF1OGgxNmQvUXFoeVVwa1psdmwyOGErckpUCjVsVXdvRFBuOXQyU1FrbEJLd0RBZkhkMlZtbWxKT3ptdUZoekFxaStKRzNKalgyWmI1LytjZHpFTTlIQkV3a0FObjl5ZE9ERTVFY1MKQU1DQXpkbjVyZWJIVG16b3pMMWRYM3pyWGxteHo2RUMybXpQTzdSajN0dG5wa1JLM2dJQVNFb3FjdTVVbEVnR2JzNitKeW56eGpwcgp2NEQzdlFDZ08vTk9hVVhHcGsrT0RCeVhlYWUwTW5QQVlOdjhvaHk4TjNxVk9ZMWhMMkxoelpCTGJTVlg4Y1dkRjMzU0h6VU8yM05xCkdiSWVObTRjOVlZeWpsUnM0Z0NQQVp1ejgxdEZ2eCtPUnlVUGJ4V1gzODJhbnhweXFlMWhldGJqQ3U5RDk5ZDJyeFFDUUpNa3NlV2oKbFlmV041ZGNBd0IwU2JKTEt6TTNmWHJFUGlUclRtbGx4a0JIVytneDZYZWRyTk5JdGRiVWF0YkdEeDBuVUg1eHFvS3RxWUt2RVZPMApHUmdESUlZT1kyV3NOYTdGaWwvTmJCQXpLQ0JnckpQcnRpU21xcVFXVUc4TFR0NXVwUnMxamhlcitZelRxa1ZQYktDUUdSbkoyMVdyCnBQSldzYmJpQ2lIcWJWVWlBTWhGdU9DdFlpL0tSZFNnbWphK2g4UTZqTldSM2t5MWwvemxNaXRkNUtQTm1ERzBtWUlQOFFZb250Z3kKQUhoaUtRUkFyTjJJSDdNdC9pK0lDWjNHQ2lHK1hhZitXQ1VtTTFQK1VnZ1ZqWFlhbldVaW94NU9xeFN0VnZnMTBxOURKSGtLeGFidgpSUnp0RmRQKzVCRFRXaG5vYTcyMjU3cXN6bG80OWJXMDJWc0JUWGJONHNWcitoUGZZN240cVI5enZhQ2lmbGlCM0xwaGZIQWdYSTdZCk5GV252dFlhYmw5TW1kNlltNTYvTG44bHRsTGZLK0g5QUIvOUFTdlBOVlRQbkdEMWZ6ME1BK3lwVW9oSkJ6eWx1YWNJNjRrVjlmYXYKMkxOUkFnTms1ZkRrYjIzeUZ2R3o4VXZkL21uakdmcG5MLzJhOFM3N3Zsdjgwakg0dDRpUHp6ejl2RG85RjJHdW45UFBjZHZycjhndgp1U3lWWjM0Rmh0eXZESkQvQjZvL0cvZitQOVBvMzVEVEw0VzRiKzVrZnlmNkxmMmY3ZTh2VFBxT2Q5bTNUOHI3RzhzQ1d3QmxaTCsrCjdYNnV6c1d2L3E5Z2NjempOVjkyTnYzbDFsd0NhaVlXcW9yVlRDeFV4eXRrZmJUNVJ2VS9QbUFBM3FqS0hJdjdHM1dFQWdDdW5KamIKb2NycGNVcjVmNmN5RWlFWU90Nk0wdFpPYTJjMkFOeVlEQURna2RCZVk5RnprTFFhSTZYdXN0L0Y2TmpIemJBSHhIQjdTWllLckNVQQpkMGIyTThiVTM1anFLZWtkSUZkMld2VS9Qd2plWHp1Yk01Q3hxNjZQVmFpR0VBQ2QxNjZoZWJ2d0ViVTQrSlVhV2xvRW4yZDFKKzF0CmxXWHFUdG5iS3ZGbTllWEwxTE5IQVBZUENwSVRBZnNIajJxRDk5ZTRVc0o0dTFBVi8zWmhwS0Z1OEZLTkpGNk1vYXNLdzk5djVLNmgKSXl2Sm4xcG9aVWdqQUdEbnduM0dLb2liVVgyTWRqZXA3cVRPR0VHMXV4c0FWTkZzMUdsODBWY00rRDVubEhLVEFSaEF3enQxeG8wTwphRUtLcXVCejVWbnBLZWd6NlJXN3ZKcDBRV3lVY3MwMTZ0R3c1QkxYM05odW8vRDJJNE5UajArNmtqSTgydk03VjdzMHM2QW5ONjc1CkdnQXRjWEZpMjl6WUxwT0k5b081ajRZbGxiWkhUcEtuWHJheUtVMjg2MWVZZW55U2FqYkk5TWZYMnI1NFYxWnVHRG5tdDNVZUNWNDcKYlIyQmpwWFNvZkZlTzIwY2xlTHVIYXI1S2NEMFhuS0pKeVEzMDBkY3VTRzFEUGVUM3MwcURLeVA4RFhkdCtaeWlzMWk2N3JEdm15LwpyeEd4K3Rnc1Q0T3pQOWlQWnlpSXJMbnJlQ1BlKzh5VndNY3hJM0ppdTR3ajJvK011SEpWYkhvdXdkUSsxV3c0QUdKYlk3eHF1aTlXCkJ5alN6dzBVZzBsM0dtNjNkbnB5NDVxUDRkMkxYWTdOQjB1Uy93VGdiUFNBQ1VtcDhrRlhreTVZMjZOelJaM2R3YmFEOTQwNklpWTkKU2pzZXZLSnVxQjFRbUhwczNNR0czWjN1QjRzUGhGWW41ZmlYeFY4WVpoaDNPeUhROS9JTnFZZDZLRnVPTHJJb0tzOWJnOXpZTHVPSQp0cU9UY3VLbGJwRitPMGFiM3BJa0J2MVllN0FpYUd1TVo5ZXRvNU9JVVh4QzdxRXhueGQ2ZjIvWUVUR3hLUFg0Mk4vV2V0cjlTelA0CnJ5Vzkzc21NOXMrMy84NnZLdHI1SnBVSForVlBYVzZXS0pzUk1jRUxna1NBZTJFZUFIem5WN1VYd0dIcldjMVorVk9YbVNiSVpycmMKUk1WWTEyaDhhenRwdnp4NnpJR3NpRkJQOVgyRHZaaFZmMmZVMWZOejNYNHdtVHJHaDdXODlSY0F4bFBIZUF0YTMvb0x2dk9yMmdPUQovUTRuOXRlR0hRdktOMk5YbU9rRHlmSVc2N2hXbEw1MjdwajRpZ3dnWVpKendOeVpNWWFHQ2dzd3JKODdaakpldGw0S3dHMlBkOEJ1CnY4cTlrMzgycXgrV2RXL3FjdFBFMXVtSGJXWTFYeFNOL1ZLOVdXaU8yM2lVL3ZrejdMZjIyQUNRN2RYYzF6L0VkMzZWKzdMeXBpN3IKWHJNZ21BRGdaZXRsaWRtdi9TUFdhUDk4TzhCNDJwaFJpVzJ6cFBlY3ozWkhoSG9aVFJ2akRTQWkxRXVRRTc5aWZYVkZ5aElXUGViNwpySjBUMk9GN2NRdHQ2VUhHOG1iTlVCcitNUnduRndLMzg2Y3VOVXRvbTNFN2RkRnVkRGdPMzg5Mnp6dGZYQjZ6NXUrS09lNmhPOGQ3CmdSRXpQaml2L2VzUDl5anE3am1mVVVTRWVocFA1WDJYL2s4YW1aV0h2MFZTM2J3Rkw5MlFLWXhqdU1iakFvdWc0T25qMm1BRElQZzMKQThvWjJwS2w4eGVBTUhsTjVMQVlydkdrd0NJdytLVWJNb1dKaVFsT2UzcHZTMnFxMitZOFBiaGROYjJBWU1GUm85ZU8xTm1hbUFJTQpGT0FpVlhhTUFseWtiY25TZVFzSnNMRWE5ZGExUkRQTU9ZVWhZNTJkazVlRWlDd1pQRDNldW1aZ0NZRFpBR0NDZDNlZW5ROVF3ejBqCjcvb0tYbVZqdTBDM3hMcDVDd2Y2WDg4WkdjTTFIaGVZQlkyYi9LZklZV0dLM0JhdDV6cURyNUZkMC9rMmh5OEF4c1RUaHpYSWtxWHoKRjhSd1RTZWFpc1ZPcXBmQ0U4NllkVkxzNFQ4SUFBUWk4NkJ4SW1JaU5uMWNtL0pwUGoyNFhXUTVLdkRsSkN1L01XbE4wbTB1SHllVQp0eDBPaFNNYm9vRmlDY0NhUTBWV0l1QVUxM2hLWUJFNDl2QXc0UWtZRDNXUjR1UGpYVzNpWUlmQnpVU1lPcTRkWUxCeHNQUjFObldwCkZ4SXpCTitXUHFkZHYwYkdBSk9xd1VHTmdxVi9uQVNYbkNEemJoQjhydXpKNEJjVG5ZY1FUQ3FkQWh2Qm9FaXIzNm4wdk1rRVMvODQKQ1FBR0pWQ2VpOFRQcDg0cmJrK0dSdXJ5djc0dzc1SWRDTHpuVHdFUGVpc0FFcEJ4NWVDZ1JnWUdCVVFUdlNVd2NjYlNuY3RyVHI2NAptdCthVmZleVpyc3N4L2o0aDh5cXZoMDJBOVR2K3laVmc0SWFhZjAyUythU0cyVGV4UWlLVy9VN3R4bE1ZNW8zU3c0QUJNeGFHaVFICndEZ0FwcFdPUVUydU9ZSG1ncUoyS0lGYStFaTBYcThVQUpGQk96aTU5NVU5RWlnWVFONXhlOUtoZ05GNEFDNFNQOTRicUhrbW1LTDIKNUV6VjdrNEdrSGpSNG1YZ29jdHVnTGxmUkdFbklDRFp1bGVkQUlBeFJ1UnpaVThHMU5FUm1FRW5GQXJ2SzNzelZNQ3hucEplZmNabQo1Tld3ZDBldE1xZFYzYTVZa0RvK3RyMzRHajdQL1kxdlJtRmpZT1NwWmQyNVdZcjNScTR5QjNBbU9tUmlXRnJJcGJiaWE0UlZYYTY0ClYxYThZZTFyelVQOS9UNFl1alhuTjc1UmUxUml4OHp5TkowN0Z3VmxKZDZIVWtzeUpEV1ZBTHdQcFJablpqeXVlbS8wS25NQXFMcHcKZEcyQTI5OGlkMkJ0MThyeVRSNXo2b29sZy9JdmxzeXRLNVVVbEJWbEZEWjZiMytpakg4by9QT0tRMjhhWFgrVVJRejVKVG5zM2RHcgp6TmtZek1hQ215R3hIU1hYY0NZNlpLTGRyak9WSlRsWjVlNjFESERLdkpSOXA3Uks4dGFHK1RVQTZnclRNeDlYdmpkcWxXbFlha2lzCnpjYXdDT2tqQXBJZlpiNldFaWw1T3lPdkJyeUtKZGZZdU4xNzIyOThrZk1iSCsvREJRRDdJdWMzZnJpWU9HREluWnNkSHY1K0gzZ08KMkp5ZC8wclNwbHUzU2pjTm5WdXdBZ0FZY0RPMjZwM1p4dWZLYm9lbGhzUzJGMS9Ed29RWktjWGxEeVQzNWRWYjZtOUs3cFJXWmpoSwpybjJSK3h0ZkFKTGl5cHpzaWpMSnVPLzJ0S1ZzemZtTnI4L1BCWHExTW4xU280aUlxSjBqcFQ5Sm1aS2h4ZWMzS0RsamJaeWExS1VPCjA4Zm5xVVAzeWFVSzZ1elVTRlQ3cDlRS3VkZXRxY29SVVdDRGduaGVXcWVVaitSSFJMck9PTHVKZGltVWxMaE83Uk44ODIxRXhNazQKNG9qa3pXMXFKbDFNSlpIS2V5WkhpbmF0a0EzdFNnb2ZOU3MwUGt2cmU2cllTTTBrbDNMS1E3bVU0N1ljVitrbEk0N2FTVTdVMk13cgpyVU1iVkpYUi9WL05pNk51VXZIeFZCbzFjdHB0NlMzcG5SS25HNGZ0YVF2bC9jWlNlNHIwL282cng5MHo2Zk5GUkx2T3BaMGJwejJmClpFMityTVMvUjVuK25KVSt0OUtLOVNxUXNzZFk5Szd4ekZaK3BkWFhIa212UnZhY3BLeisrV3A5Z3lMUHdPU0lBU1VkMXZaQXo5WHoKSGpYa0xkWjl5SDA2V3RDRFdOa3JrR0UvMXZHMHBBSXBkZXIwa05JVGtPK25nVjhOcmRSTmVzY3UreWUwOWNycGd6RFk3M0NwNTFkNQovK3U1NFVERDNkUnNWOUNZUUE5NllpK2s4SGttUy90T3BzdUQxTjFqMFgvdm55Mis5MFdpbTlQTDd2cDhNdWpkNXZSOEordTlONGM5CnE4b3o4M3ZkSC91OXNKOE85ZlcyeTZmdjlGQ3B6OXUzVHN2OU5kMlRPdm04OTZKblF1aDliRmJTN29tZWx5eDZKcjB1WVh6OWdXYnoKQ3RUYm9iVWhObFdLT3pHM0U0VDJONzlYNWF5dTBoSEZldnpVanZxbkJmN3dERXRvb1VPUHg1ZmhKVkxCVmNxNkhXOUdhVjF2S2xpbgo1TWpDTzMyaG5ocXdCZ3lJT2czR0NLempuMi8vcUxFeDBxNzJSblVQelRyZVBLRHRoWlRmaUhObmxGYTMxT2lUamcvY3grUExBTm52CnRmQW9KV2JLNjZKV1Z1WEZWTlVUWFJzTDd4MUQ4VCtiOUdwa1FkMDk1cEgvM1VmbXpvV1JCc0IrRXcvMTlCNFkzSmV6WXA3K1NJQzIKcjFpdEVpYnVQVVU3aUJuT0tjRkZsZW50TjNaWFQ2Vlc1UzhtUjNtb3EydWp6am9tdEdvK2J5U25qTDU1UWQwbExadTZVb0xJUWJyagpFR25zcm5QVFlRQXVsdzd2VUdQcXBLcXZvbjZybFFkZzVxeHVucFNhNnlTbXhIbDFQU3Ryd2ZXQjNkQnYwaXQyV1phWDlUQ1EzWTN0CmRBTEt2bmEvZG5sWWFxNXAvSVZoUlpFMVNXZXRlQlpqUTJ5bXA4SFo2SUhqR2I0ODVmbFlmcUVxVUo1KzFyNHIzSzgwc2liUEgyaE4KdnVMNHMxRkh4RVJaWEp6SjIxSXZtN05wRHNZL1Z4ekpzL3ZFMUtVeDVacFAwdlh6NGpJbEFSRVMrWVdxWVoyOEY4eTBFVmRTcEI1SAo1bFJHVG9xN25oa3poYVhlVGFrWkNtdzk2Vm1yYXVmeGJ1SFgzaWVQVFJFQXQvWllla0ZKWHB6STVEK1hIOG16KzhURTVVbXN4SXNPCkZrZU5meERiNmFTaGROYnQ0cW1PT0ZnYzFYMmRENnZZY2ZhYVdmdGlhN2NJUDlPa1ZMbERnWkw2cVNSK0R1czhlODFNb0l3MVdMYkUKMnZ0SHYvQlJacVdKT1c3aDFYN0pEOTNSdHFPcllaOTdjM1J3MGszNW9KT0ZnL2JZMlJ5WlkzWDVUa0tnTDREa20vSkJXMk40elpFYgoyMmtjMFhZd282dGhuMGZUanhhUmt3cFRqMC9pa1ZUYzI4ZnRHR2xlbHBqckwwOC9PMUNjSDV2ZFBrdS9ScVpmNzljbHI1MDdjcHVQCkJlaGMwQlI2d3J4eWNuZ29qcnJ0OFpyMHVBWlNEd0RyNW95ZGpKZkZTd0dhN1JiS1NqNzZuUFpiRDExdkhTZHoyK1BsQjJEVERPdVUKdW55WHMvTEQ0bG1kMDRLOVBuZGVQcVc1TW43ejl3L2VmeHU3L0tyMkdrWE9IL2hkbUpKOGdkS1BQc2Q1NGJndjhOMDhzd2ZweTVzQgpjb3VHUWRTa2h5bkZQOHo2MWdtZzJlNmhLUG5vY3pwZ1BYUzlhOVRneWVzV05sOEFFR3kvY0NCUFhteWJ4aUNxVE5qOC9ZUDMzMlhyCjVveWRJcXBJV1pTWFAyVkZOeUFxZWVTNlYrUzd6elZ3WXNEYTJXT21DQ3RTRnBzZm5OLyt6UWQ3RzgrTHhuM2hNdXdsMnpoWlF2WnIKLzdqc3VsZmt1dzhxNHVjWE9DOGM5NFVxMXFCendFdmlEcWVnQS9Mb3NkOFhERTVId1JpQ3FWbk9xUFBpbGhHSjJVdi9FV3NmYTFsZQpCQ0R2NmtJYkFFak1YdnFQMkRsdXZPWlorVk5YbUNXMHpUYkxHWFhlcW1XNFd6UWlRajJ4MzNyb2VnQ3UrMFMrKytUUlk2T3k5bHNQCmZWUHgvc3FoK3Q3NW8wY2pJOERUZlVQaWFUNFdJRllmZkVENTNaYWZ4RmZJakcyREFqNzRwc3FaZ1BwN1JsNzFGWm9YRVY4anUrYnoKYmZaYlJaWXd0ZzBLVVBJcUJZQ0lUVjRiT1F6QVVUZFJhS3kxcDdHNzZ5QkZXN0owM2tKcmQzOEhwekVxOE1iSHlLNGxUSkhkQ3FkeApMaTQ4L0dkaVFqYnVuajROeldYazRxVFZ6dGsyKzYxRzF1NisxbUl2WmZnL0pYa3hNQVJnMXA3Rzd1NkQ1UFVGUnQ1MTFXSy9zUmU0CnBoTWNJQkREeERiVXV3RkEvWDFqNzdvcUs3OHhBeDBzZkllWU9qOVpvTWlXZ1VGb2lWUE9tSFhDeERiVXUwRTV2YjVHdHMwTHVHeVoKMEVJZGF4QkdIaTdTcENicE5wZkZDVTF0Vmd4WWRxTEo0V2RKNkVsbnpEb3BCRVFBNFVnb25BakFTV2ZNT3FuVXZJbkhnUU9EbDUxbwpkUGhaTXRIRUJOT0MyM0d1emVGTEFDYTJvVDROU2MzU2JTN24ydXkvU0J5S0lmcitFTkNqa1RFQXJHR3VTMDZRcVJ6QUM4a1BQMzRuCkVJdG1qaUFJUUI2RC92d3lBOFIxS3JvZ2lJOE95TWk2TmtnT3B2UnZhL0h3Q2ZJTTI4RXBGR24xTzhIQld3S3pJYng0TXFsMENtb0UKZ0dVN2x5bFVXOUdFM0ZlRzA0SGxFVXNmbjVxNVdoMlhrTEhBa0l1Zmk5WHRDTW0yTmtpdSt4NGpsbmJBVG1zclB3ZXlxbTJIclIxQgpTWlBVR2tZU1N6dkkxbzRZdjRXTkJMVE5ZQVlSY1dCcXpGTEFmMlNDTVFocG04RU0wa3dBQndZQnp6OFYvWEhwSkFBUU8yLzdQdHFRCmVVdGc1bXpRRGs0QkFjd2xQRkxxSTRHcE14UUFnd0E4aFpSQjdQeVBmMFliQW9EUDFUMFp0cldCQ29CM1FPS1c0ZWNqdGEwTlVwaG4KS1pGV1BTYTlQaTRkOGk0VXZ4UjJjL3hsVXdDQ0Z3TmZNQm1CQVp1ejcyVVU1VEJzdERjR0lQekxpa1ByRFpNZlpRTE1NZk5TOXAzUwo2c3kzM3A1ZlUxK2FlYTg0QndCN1ovUXErM0c3OTdhbm5Qa2haS0wzb1lMTm54d2RPT0YyZGtXUkpLK3ErTDJScTh3ejhtdXhwbXRsCmpVY3RTSjU5cDdRaTAyN1htYXFxTlYyL0xkL2tNYmVoNU5hOTh1TFVvdkw4OU1KajMyOVBWYmRUa2JuKzdmazFqOG9lcEplVTUyVXAKZ0pLaUM5eEh5dyt0YnltOUNrQitPN3VpUkhLM3F1d3ZLdzZ0RitUYzZGakFNMFM3Y3JQdWxoWks3bGRtSnJiOFpmbmg5Y0tjR3gyUwowb3FjN01yaUxMdGRwNnVxZkxiWGwwaVdwRVJLM3M0ckxaVGNid1ZnOGQzdHJOSktpZDJ1bUtyY0IrbVpqOHNCK0d5L1ZmNUFjdC9CCnorOERUMW9wNGdNL3YyNXI3LzhDTGJrUktYbmJLM05iY1ZwRHlhMFYxemRuM09JSVMyNUVacjNsbEhVcE82dTBLak1zTmVSU1c4bFYKb3RldEIvci9odTZWRlgrUi9hTGYrcmZuUHdad3IrU1JwR0Nndjk4SG5odmVtbDhUYlAvNnlYdU5ZL1dLa090M01WYlJhc2xVOUVKMApHS1BkQk9nMDVJUUFzWXRlSHZ4T1l3TkRWWEVWY1pIck10SzZ2N2VaQWsyV3JSYUtOa01qeUlYZ2xHeENZbEJTS1lsMU45bmg5RmkxCkw4Tk9JNFZBM215clVIUllxQmUzZ0V0REhHdGkzOVpxUnlFMzdMbmFKUk1aYWVsUERDQ1pnUkcvTUtaaWltb1NUM1hVTE90MkdpbUUKa0l1SVFjUExCS0Fra2Fwb3FIeDVEVXNUcUUxWXpMZlhiZGh1QXI1eXU2RExBZ0NvV1dnT0FQVEVta0V1VXE3VEtYVlJWZ0FValRZTQppbTVqamVZeU0ySmNsekhRWkdnZ1VuRTE5WlAwdXhqYkUzVFIvSzU5ZGNrYW5hdytsbFdmUlJ2VVhlcHNLL0h2M2FST3FmQWJvMTJICitlb3N6aitkcjZpemxOOTNzejF6K2x3NDdaTURxSlVXT240ajFOS2RXRy9kTkJtNlEvYU1GZVJudGZ5ZlNiOG1KVTRIc2FrYjBPZnAKZm1ic1dkUFlqNEFlWmJvYkJ6eWxSQzlzNW1tTjZqcHEvTVVrTjkxVWI5dFhhNzFzdTAvbzZEbUdYTzlKbi9FdS84MnEvUXkxcnZCZgoyRXIvOC84VWxQVC9vRWYvcm9yUFU2bC9sRlRmNUV2OXZmanozUXJ2OS96OWpjK29xdnlyRzZsUEJaeWc4NTl2L3dqZzZLNE4vQmxWCnNZb1JUd0FVYkh5YVpPMTBmWkxLZlNhZVVTWHFORlFRVGN1S2N3QXl4K3FzUDEzNzg5Y3JkdjBoY2NTL05seTgza3BrdjFmcTc5YWcKRFo2b0ZGMWRyY29yZU85ZjArWGZUbnJkdlVaMXRsZDFkdEVSUjNTNVNEZXJ6OStxcEFvTFJ6M0wvWHhJWGtWVThRZXE2RkY3WWtOZgppaWdEeHFsLzcxT2RVQVQyYUZ3VGdJN1RQVUZFNnJoeUg1NGxJdElONTNaVlVSUkVENHY4K3U2TzFsSGR5YjRVbk5oQWZUVElQYnVxCmV0ZGtwRzUrWk04Q2VrdDZoWldBSDE3K2NUR0lJU2UrenJYNWVyeDNjdkxGOXZYV1hnbHA1VjVYVXB5VUVJczB3bkRINElGTjErTjkKa3BNdWlzMlM0cnlNY21JN215TzViMGJWTDdiMnZwWmU2dDJkSU1tUjIyV2NkYkFDY0MrcGRHanBya1puZDliMmJlNkE3Skx2eDhlbApsdzMrd2FnOVlpTDc4ZEdsMzVzQVYxS0daOXhLSFFIZ1lscTVseUwxc3BWTmVYTGE4TzZNc3c2VmgydC85cy9ZNE82Ykc5dnAxUFJUCmNmSWFBR21TeERFdGNYRmlXOGkrTjJxUG1IanRlbWJNbEs2ejEwd1YzeGc3UmRzb0xtVjZVblRia0h1WHNqdG1YcnhWNnAwcy9Gbm8Kam4xcjVPbG5CbGtwSDBidXJQSG9uMnlzSS8zQ1I1azFwbHp6NmJ4NlJXeVZmdGJCQ3FDS3BGdkQ2V3lhdlVWaDJyRXhLNlNlSmFscApJd0NLVFN0eis3SDJZSGtRL1ZoNDZmY21yUE9uaHQxZDNxV0o1d1BTb24zWkFYWkF1TjByNXVnVVlXbGk3dENmYWc1V2VLMm85YlJECjliY2pNaTY1aGh0c0Z6dTFKTWQ1R3VkZTZqQ0phRHVhRXVPSitBc0J6ZUYrTjY1bnhrelpHdU5Wa0RKY2Z1dWN2Zmp5elZxUGYyc2EKZjJIU0w3bFgwYlkwdXh3TVdhbUx2bVBmQmxUdU45dy9iM2pBM0k2a1pac2hTTFNKejEzOVp3QldNYlV6RnJKZC9wV1JCdnRmR2JoeApodmhTNXIycEs1MzJHdmp0ZGZaL3FUMTUyV1ljcnBuK2lYdVV0ZWRhQVBYaEM4dmVkdzJjR01ESTlBV3ZGNnBTRmpZa0w5dGtYcHZ2CmVsYXgxMjUrRndBSUV2SGRLK1lBcXBPV2JVYUUzZVQ5blYrOWxGMFVaZTI1MXVHYndmUzNLUVBtWjkyYnVrSytkbUVJQXdpNzU1MS8KZUZnOHF4a3dyY3QzUGFzd2lKcjBNT1c4YU56V1FZMFY2SFplTzJ2c1ZJT1NoL1QrQ2srdU9tbnArNkNxMzY2ckFNTUJhODkxbWcwMgpBSUFPcDZEOStNNnZNdkt3NWV6bUE5WkQxd0hvM3ZaeWR2Rm56c3VuTkVSTThES1pGdXo5N1h4ekVCNG5MZHRzVUg1cXplZmNYcnV3CkxnQUdPZGRXcnF2NGRqeU9Ub2d4TXV3Ty9IN3dsSFVMV2k0cW9zZEc1WmJGclAyNzBiUVFiMkJRZk51d0g4UUplYXYrZ3MwenhKZXoKN2sxZWFaclFObTJ1VytqT1VCd1ZYNVVaUmsxOGVIMnUyd1JCSWc3WURGMTNYN0swK1YrWnZmK1hHTm5aN2tQRDk0SndKRkI0UXBaYwp1MkMrdFllL1BXT0Q1cDVYa0EwRWx0UDk2d0F5TkEyZFpWaVFMQTJiYitzUllGTEpsaXc2bzJnOGFtUTd3YWNCQWpabzdsa09MYVVXCnpsWm4yZ1o4QlNEUkJMTlBnUUNPRVNDMDhBOTJubnRPQVFQQUFJY25DQnhCZ0EzZ05NNFp3S0M1NXhVNDQrbTE3ZHBnZk9OK3RtM2cKTmh1cjBSdXVFbkJLMFhpOHNWanNTQ0NHajQ5M3lTYXZqUXdDbUJBUThXSGl3aFRaclZnZldlRmUvOERZUzFvcEZpUU1oU01iTlBlOApIQmdSdURnUndOazIreTlWVzlxVld6ZU1QVnlrYlVuU3NQbVQxMFVHbm0yei94TEFWVWQ4NDNiTVRUVHg0dlRnTmdMQktkZ1pEQTV6Cnp5bVlPTVRCb2Zud0JJRWpBSUhsNklDWDR6OU9xSlNKM28wNE85L1F5dDNIUnV4Vm45Z3MzZVptTlc3Z29DWndJRUJFQmhCYVRBMlEKTnBhekpZdE95NXVQQ1N3Q1E0andjWHlGek1BYzF1NWV2azg0Z2cxd3BzMSttMHZ5YXhQK2Q0Mk1DajVjc1R1Nmc4SDlBZ3BGbFU0QgpUV0FFanJ0eC9tVmo1WjRuQWNEQUZQRDBxblFhMWt5QXhZTkd5bmZKRGJMbzVxZE5jZVA4SzhaWTNKcDhrQWJVRHU4RTRKMEpVMmN3CmdvQVlDQUpDeXZtWFRTRnFoMEpobGdVb0dNQUl5OEtYS1lBYjUxODJ3YUJyeUhPL3JHZ3R0YTBONmdaSEJwTVk0SllUWkM0b2JnTUgKUnJKMXJ6b1JsMW9mRG9KQk8zRUtFQmkrTXB3QmVCanNtMkpkMnc2N0FRTE9JaE5NZnVQQ3k2WUFxUFVGTU5qV0JuV3JsbUpCU2wraQpRaktwY0JyV3hLVTFSTmpXQm5VQmNMK3NrSlY2UzJBNnhQdktYZ2tEbGtjc1V3QTN6NzlpQ2hBRU1Mc05ua2JITWFNSmkyY081N0QwCnpBTm5aYnc2NXByaDUxUEhPQ1lROExZczdPQVVnQURNOHVFVDVMbmtEck5RN3FsYVBITUVCeUd2aFFBa0FPeHFnN3ByVHYxbTFmK3EKa1JIMjNHOUhOM3UzSFFzVFpxUVliUnk1Mmp6OWJpMTh2bVpYZG5CM01oNFZQYnlWV1YwQkFJY3Z2U0o0YjhRYnBobDVOWUozUnEyMgpEMHNOaVMwckxaUVV0UHBzeDVVZDNPMExDZnUvcUY3MzlyeGFBQUZ1ZjQzYzBaU1oyRWhNa1pSVmVPZG1oL2pLRHNXZGNidjN0S2U4Cjk5Y3ZhbElBWkJRMThxNHVMYS9zVU56WnNINUpzNC9IeU05ZDNueDdmZzBxTHg1ZEEvTzk4MU5EWXEzZld4QWhmUVJtVkwybEllMzAKanlFVHdUQnU5NzcybE5TaTh2eE11NTJucXlyeHBsZ2crR2pGeit0WTlwM1JnMTQvY1o5ZDNxRzQ3WFVtZHBoOVFjbWo5Vy9OcjBFdwpqN21DdTFoMmh4V1VQMGkvMzdaeDVCdG1aMzRjTi9ITnQrYlhBdkR4R1BtWnk2WlBEOXRQK2lKM2hxL1h6d1ZydW5qbHZsRmtTTzZVClZHYTg5NWN2YW00QXdJWEVnZTRETm1mZmF4SCtiamdlbGQ1UEw2N0l2dTNtNy8rQnN5Uzd0UEtXOTg4RkFFTGZPMXAxKytHdHpPcXEKZDBhdmNnaExIUi9iWG5vTmpobFhCMnpPdmxkY25KbGFWSDVQNGlpNWxsN1krT1piODJzcU5uck8vVmNuOFYrYytsOG55VWhOZEtQdQpIdUhRYUhLbGpEajFhUmtSY1NyQ0YzVlRCOGxwZDNQdDdYK3E0N3pWSzdTK3FZZ2o2aVE1VVNQWFROVFIzcUtxeUZQdjFESGtxSTJJCkZPM0VCVFlvT0pLVERudXRXeTVYc3ZLVWNvaUl1QTZTRTNFZFJOVGF3V2MxdG5meDNMZzJKU21QYXlkcTdSRTluZmkreXB2Yk5hSHAKWk1RSG01UFhjVVRkMUtWU1RrVm42K2hvSmlMNitNUVRWZmEzMmtPa3BzYngzTFlubktxWE1pSWlHYWM2cHpXd1hEZEhSSnlpbmVTZApUL1E3MmIvdWlyK1dyV3N0Z0hhT1BlVGY1M2xOV21FeWJPQnZySjlQNmpQT1Y0KzdaL3FMSy81YjNYeCs2ZHc2VmNRNUZWM3ZxV3ZFCmZlSlAvd1hwdjhDZFp5OFVUbHB2Nk42N21LbzB2OGpZTEREdmphczhpOGZSWnlwcHR4M1l1M0FmeStYOXJxSnJ3MDRxSzNwT2l1Z3oKWUZBTk82NG5YVSszOUxQb05ob3U2SFBxOTMrYmZxMDcyZE82K1ZUT25IcTAwQmZ0N2FuUytyUEpYaENsMW9tZWpMYW5OTkRUNko4TAo2dW9mME80cnMyZW50VzZNT3BkQUR4eXVQOVJUWDBuZlR2QlVTY3RaU1k4L0JFWTg2NEcwS1VVcWQ0RktCZ2d4cG5yVXF5RWc5UVdqCnZmT1FORVFNTlFTbExLQjBlcWVWcnhURE5CV1lpbDlDeXVoaldyN3VsUGxhOVVnN0RwZTZneW9CV2tsOXdKU2hUN1ZKTWhwdE5TNFMKbFhtTVZFcHI0VjRNeWtoNmFvSUwwNUxBZjF0ckR3bURmbTNzVnpNeWZ0ais4V2VvTGpqMUg4WjdwQ25ZQ01aU0pxdkdZOGRHQmpBMQoxWXVZeGs1MVJoc2dvRHhRcG01REEwVFNnUmhOUWRVRzFUc2pkUlI2b3hwUVRudm1XRzJ1SG1POFBmQU1JbjVLK1h3Q0NQLzRRSG1ECllFeHRLYVJ5SktxTXJhaHVxR2JpSTYyYkl6RWxZMDV0cityN0VkZ2ZxaG40TTByN1VZWnlKR2liczNUS1F3WUFITk8rRXJRdUlLWjEKVVpQK25YdnExYXNQb0hNOUFZR2RxbXVNZWpnMlpUNWZBeGpmcU1vYUxnZFVWQy93MXlhcGYrb2tCamliNjNqaFZFVytYRDFmMTQwcQpneXE0b2Jydy9rR0FralU1U3FiTjFlT25qZW1HcldUSzlobUN1a0JLeTQxVXp5dlRNUnJOYmRiZVZtdi9NMk44bzFBR0s5UzZtVEVnCmNoQUJ3QUVWUis1S0NWTmRPaXB6SnNET2h2OHBVSkU1bVlxNDE5T2FHTUFPNk5zOW1WNHBjUXc1OFZLM05Fbmk2TGpybVRGVHdLZzgKUCt0aG9ERHZZcWNUQTd0NHE5eDU5Nk5oU2FVdVoxTWRMSzZrREcvNnFlajZHdm10Yy9aVytaZHV0ODBDM1lzY2Q1QVA0dGR4cUdGUApsNWZpMWpuN3FuM1N1OGFweHljMXhHWjZOb1ViZmlOMkFoRHQ5WjJMNlE2ZVdGYjk3WWhibDBkbDNFcjFWOFVqek0rTmYrUWhRc0hQCnRUOEZtTzN6Q3grWitZTXYyKytiZEtQV010elBOQ2RlNm5aTGtqQUdrV3NZSUw5NTJiTDAyTGlEdFYzN2F2TE90UjJkZERlMjB6amMKNEJ1eFUwdnlGYStqS1VIVngwWUJLTTNQZkJTUWZXemN3ZHFLRFc2K29LdlhNMk9tc0tTYjhrRkF0NHF2MTV4eXpjY3dKN0hXN1pqWApUaHRIOVRqVTdmRGpyc1JaNWNUbkhocTk5ZUZvQVBMMGMvWVZPeDBTbTR6Qy9iaTRPS3Y5cHp5N1VvOVBJbGEyMk5xcktLWEVnd0gzCmR3dS85bzQ1T3FYNzNEV3pnU2VtbDV4MzYrUTlsMTdKaXMwYUxqOTd6YXhqdTlYZ0h5MGloZCtJU3NMOXJjb1NjajBQMWh5c0NOcDYKeXF0TDZRNVZYMG12ajh1czFFVzdzWHZlK1VLRHFFa1BVeGdZbGJ4MjdxZ3krbUIxMHJKTnhxNDNVUkg4bWZPS0tRMkNCS3hkTUo1dwp3SHJvZXU3OUZWNE1nRnUwcUN4bXpkOFZJSVBzYXl2V1ZrWGFERjN2dHRmVEx6elVFK3ZtakpsaUhaLzcrb2NBQU82RithYU82WGd3CkJoZ1VMeHYrQTc2Ylo2NGlyM0h2VEx0Ylp3alloenZpcitod0Nqb3cvcFNob2J3cWZWbXo5VldaVXNlTGhiektPd2RNaWhwNUFPSUUKdDcxZWZnbHQwMi9uVDExcEhwLzMrb2ZZTk1QNjhxUWpSblg4aDNESjByUEhSaDZBT0dIeWdEQ0FHVVJOZXBpU3lNY25GUEY4dlhmWgp0MzVWKzdKU1g5ME4xdnJXWHpUallITlZka2c4cThYbzRMejJiejdZMndqUUFldWg2LzA3WW9wQ2JPSmtoNjFudGN4MkM0MElIUXBHCnpnRXZjZUZoNVI4Q2NJMGFQSG45Z3BhTDV3M0dmUUcwSmkrejJlVmJ0UWRBNi9kekw1dzhMeHIzaGZQakd0UzVKdFY4OEliTGhCM3kKSDhaRzVaVEZyUDI3WXJiYmhJaFFUMzFPdTM2TjdFaWc4QVErUHQ0aHMzSDM5R2tBK05DQ01WempjUTRZTlBjY2g3azNXaFhHeDl4RQpvUmR0R0IrdjhHejd3SzBKUStFRWdKbVlDTVRCRG9OYndJU1dvd0pmdVhxK3pmNUxZN3VnZ09uQjdmVUZSdDcxMVZZcWZ0bllGKzBxCmxpUTB0Vm9CRUVJRU9BVTc4K1ExbjNwNjFHWHJKUUJzckVadHVBWmpEeGVwNkwyZFo4T2NyeThlTDdLZ0k0SEM0L2o0ZURzZjZ3dG4KaDNwL0NRR0VNTFlMQ3JBSUhIZUthenpHTEtjRk5EUlZzQ1dMM0x5U2txWUJJSGk2YjBpQUFLcElUamJ1bmo0TkoxMHc2NlNTVE9jMgpTTjZXTEoyMzRFaWc4QVFRNEN6Rng4YzdXbTNjUFgwYWhKYVl2RFl5ME5iQnluZUlxZk1UZ0oxdHM5K0tMNkplWkNKTE5ubE5aQ0NBCjZjSEtNTlVKWnBoOUVvQ1J0WnV2dGRpcmZrRjN0Z3pzclFsbWJVblNlUXNCMkhqNXJJNWJxTWlXNGNOdnFvWUlyWHpzTFQyOEdwS2EKcE52Y3hNSDJnMXNBVEE5dS85ODFNdmNMS0d4WTk2b3pwN1Vwc0dHdVMwNlF1UnhJT2YreU1RVEwvalNKandMSVlGQWtBd2ViMnVGeQo4MHhBcnBiQ3YwdHpNSnBnWFJQVURRSjg0dlkrbExiRFpvRFdSNXV6ay9DUHl5WUNnRUU3cDhEU2lHVUsva3RmSVBnd1p1cDBBcUNBCjRVUXdDUGpZZnJXblpxNEdZKzRYOEVpMjd0VWhTbEVPOGNpREFtci9seTdaeXZpRmxnK2ZJQStidDVpcjlnYzJ6SVVDbkVMTk4yUHcKemxENzdpUUFKcFdPUVkzdUY2aXdnMEZJc25XdkRpSFY1eXVYVmgrdUdTYXlyUW1TNDhZWGIzZURFWmRXSHdHT2ZPTDJaQkFBNHFsdwpmQU1NQXJiTmNBWUJmMWxieDhjMDVMc1YrcVhCRElLN3c0ZXZxR2JaVmVMclU4ZVBPUWZ2SzN1MTNLSCs1NU5lald4aC9Jd1V5Nm90CjBsdXBSV1gzSkFBYzhpOFd6MTJRRmhKckJsaGQyY0hkd2V0ZHJ0ajh5WkdCa3pJS096WXVqS2g5OU5iYjgydkdEbnI5eFAxRzRGN1oKQThtZDBrb0ppT0ZpNGdDUHQ5NlpYNU5mbW9QUHMxOFk5dEdLUSt0YkhxWm4xbFFBQ054M2FobXdRalFLQUNac09sNWRzcTVycFNMbgo5dDNTb294N3N1OE83enZJQUZSZU9MTDJmdG1EelBzeTBlK0dvMktqeDV6NkVzbUNoQmszaktxMzFLY1ZsQlVDZUhQOWttWTRiVTdMCnl5akprUlpmeFlLMGtOaU93dlRNbXNwM1JxOXlnTS9nc0hlMzhCMHBlZ2xPbTlQeVdpMzNFcEQ2cUN4ZjhscktQc25iZ1B4T2RrVnAKZWw1RjhYdWpWNWt2VEhnaHBmVlJodVN4dEhwTC9hMmJqOHJ2U2VwS01rNUhoMHlTRkZmbVpsZVVTMERzemJmbjFkdytzY1JzZlhtSgpKQ1o2M0VTbnpHdWY1L3pHaHhGOHYzWjArMnZrRGdDRlpRWHBSUlU1dDIyK1BWT1o4MGk2N09XaWphTldtUU5nNllrNTgrMitQVjFWClJac2RqSjRVcGQrcnVwLyt5TmJQL3dQbmpEdWxWUmxPbWRjK3o1M2hxODk1MXpOMktTT3VXNjVHR2ptU054SVJ4K04rUEhEWFJqeW8KUjBUVXBHam0wVDZ1c2IyTGRMWjBiam4raE9NNGVUc1JjVHdzMmRKQnhHOWY1WWdhRk1UUjR5UDhadFluaWxicWxLcTNtWlllYXk3KwpURUVxRjUvRUVVZmZ5a25lMWNnM0lPT29XNjZHL0xvN2lSUk5iV3BIb1p4TXRhTlh4aEhSdDlUNkF4Rng4a1lpa2plMnliVThaWEpVCjE2djNSREtPM3p1cmNidEpKRy91VUFwVitpM3RVTyt3N1c1dVZ6dm01RGpxNW4yU2FnMUdCNmRRaXljaWl0OVFSMFFkbkp6b1hLRlcKU1MyNFUrVkJWVjlKOU8rYjZTOUpwbUFpMWVvVkE0UFFpc0NZQ1FEQUNFSUFKZ0NKclBnRkJrdFlFQk1ZQTh5cUI5MkxlMnduQmlBVQpBbUFRMlFIZ25WOG8xNzJ0QWJiQTZSdisrU0NHR1F4dDFjc0o1UWR5aDA0V0FOV054Z0krNi9MT2pVSVNDcFNObUlKRTZpVU9Fb0dZCndGSzFzc0RBVEZRcnRLYkE1M2ZDVWJvQUFCTllFWVBRaWhoRUtneUhHR3pVYTNSZ0FKa1NYNDBZTWZYckd6R1EwRUpuNVJkQ0liOU0KeXdDUkJZRkVKTFRqbFJlQnJKbHk1Wlh2cXlIVERDNEExTlNLUWN3SXdwckZTK1lxKzB3TU1GT3BJWUxRN3Y4VGxMaW5Ja2ZQZ2ZEeQpvRjZmeUl0NmhiYk9SdEJMSFArcmFqQ2dkdkVKb0x1MVA2ejlLWG9TQTFvTURmdlY5RmxFdXA1Z0ZqUVlWdjlVUEswalR0QVhvQVR1CkFSek4rUnlwM1hPR2EveFBwMThycUdxZnJnSDdtb1RlQlhyeERQdWFqTjdFeUw1MkovUVR2N1NQaHZ1TTV0cWZ2bjNFTnRYdWJ4KzkKN25rWlBHc3ZSUjhJWm44RCtTdVFlWHVtLzVhdFBrOUp6M0tycVM3MnRNUG5xZkp2YVBnTHhUNEx5ditsOHZ1cCtWOXhHOE92aVYzMgpTTlJ2TGxPL3EranU1NHlLMFRsVURXak54RUx0UTNYcVVNVU5CRUI0b3hyb2VDc0svYWQrcmo0VkgxSzdJTk4xYXZqc3FXVy9JTGYzCkNmYThOZjlMYkV6ZjJHV2ZQTlUrNHcveWlXbG5hRWNqckR1RlZmUDdiTUxldHFjUVBobTdhanZMM0QrSTlodTc2VWFHcFAxYVlpS1oKdGxCY0tWRWVPRm4wa2gycHZCRCsreDhLdjFMU0wzYVpmRk0rNkZoY1lIWE04TnhMbmNZUmJVY25BYmNraVdNQXRDUmY4VFpLdWlrZgo5T0E3bmx5WUZKLzc4K2l0RDczL2FkUWVQdUhIMmgvTEErOUZUdVJ1WHJheXVYaXIxSGxGcmRlWk51ZTg2NlZENjhNTnZ4RTdaZHhLCkc4NkEzR3RTMXhPZVBESTRKdTU2WnN6VWE4bVpNVk5ZYm15blU1cnBjTFR0NktyZjY5a1U3Ujd1dS9QVTBGcjVoZXBoZENiTm5uMXYKM0JZeDhjc1lMMmZnNHEweUw0YWtEVzVWU1JlNmo0ekl1RFFxODJhYTdXSnJMMmxDcmo5K2ZIanA5eWFRN2pUY01kZytUWkl3NWxyUwpoVWQvYzVORys3QW9INk4vZTRUK1Y1TSsxMHNTSXVpMWk3V2pLRXVTZWFURXErMkZVNmxFdElKbVB5U2lQM0tIanlhRzA1S0xIYzZQClRyNzRaTTNwbE1tTjYvL2FOckx4MDhNMHN2T1RQMVo3S3RvOTZadUNnczFWbXhXK0ZQNVB4Vi8vV2JlYTlteVdUeitRTzVWK3F6aEMKSEdYdWxTK2dCVEhGTTJnRnpYbVFFSHAvVVZMQ3hBZUxraVJIaWoyN3YvNlJJOW9WVHFNYWM2OTNUeW5OL2kzdGZMZkRsL3YwZHJkWAovZCtQME1qTzdOOFJVZFZtaFM4UlVSQWxoZHl0bnZHNEtZUitxemhLODRybFd5cGZ6Tng5anZOcUlPb2NmZmFpTjYza1p0OVBHcDliClBaenJDbnpTRmE3ZnRhZi9OeVc5dnBPZGRNR3NrM2IrS2JtalloU054d1NXZ2VNQWZIeThxMVhwcGZPRUsrYWNOQks3ZTl0WWVUWFkKT2xqNU9wazROUmd3Q0NFZTV6QzR5ZGdFWjRaNmJ4czA5N3ljUUFLeElORVVjMDRLTGFjRjFNTXAyQVVNUjRLRUowRERuT3Q0aE5URAp5Ni9CeHMzVDk4bHBSZk14QlNNR0xEdlJaSDhvTTFSa1Rod0l2b1oyemNkZFJhRVhSWUFJSEFIZ3BZTUE2NkgrRGdJWWdJWUVPNE1oCnNVWDZwY3VoVU9ZSXdOQXNkSlpoMmQ5T2RMWmJ1d2M0Y016Z3ZZaXpZZi8vMDdLL3BGY2o4MG1IbVF0YnY4MFNycmxCWnQwY0NHaGQKOTZvakFSWVBuMUMrZHdaTW5TR0FRTFV4RHhCQzFBNVNRTGxYenlFQmQxTXV2R3pDQUFqSU93c216Z0RBc0N4aXFRSndPNGZDVG5BQwpIaGxVN1YxbDVKb2JhTkhOTVFMRXpsLzk4d2NEUUFnQnh3QW1JQzhKekp4RjdlQVVBZzQ4TVpPcE4yTVp0SE55dGpSaUdVZWNXNGFmCnI5VDh0aExHVkdDb3pmcFhoM0RLMVkybForNFArVzk1emY3dlMvb3pNZ0tXM0lpVXZJVXhOQXRocVNHWDJrdXZNY0RrOFpZbmFRVEIKTzZOWDJ5OUppWlM4WFZoeS8xWkpSYzV0UG41ZWlXVGNkL3ZhVWlUWkpaVVo5MHBMTjZ4YjBtSjFlWWNpMi91bmd1dzd2bTUvMmIrago3bUY2NXVPS3RWMi9GUUlMazJha3RCUm5TaDdYVlcrcFQwdDlWSjR2U1MycXlKZUVwWWJFR3VWSk9BSmV0eG5vL3lMcWlpU0RNMk56CjdwUlZaVzc2OU1qQVNlTjI3MjFMY1pSY0paNllDY0I4YjNwK0RTWnNQUGE0ZEczWFN1YXozZHJmLzMzUGQvL3loZlFHQUJ5KzlJcHgKMVpiNnRJeThXcGp2SmRIdlJrYnQrYlhqeWYvWEpqMnZrOVhiQW1nM1pyelhTZ0NBbkVFSUFHMm14UGp6UFZLVFphdUYra0RPR1ZLbgpzVUtvOUg3WklGWmVKZDFOZHNTZ0VhdVNDdVZxa2JvNWxZZE1obTREWlZHWkZkOEljUUlHZEJvcGhGQzczR3kwa3BsM045a0JjaEhhClRJRU9kSnN6WU1vaHNRbFR0YUVRQXJ2V0tzZ1EvMy9xTS8wM0xjWStEMHZ5WHhMNlhJSi95WXFxaGhuS0Y5TUVNZFNobnYwYi92TDYKWVJUOXE4NytmdDMwNnhrWnFRSXo5NGJtaUtIL2FGVEszNXBaN0cvZ2Uwb2lwZ3dsUitxR24yRUZPaTFxcitUVjFhbVlvWHl4dmxpUgp3RE9YOEg4cEt2RmNSdHNYVjVYaE9Tcis1OUovejUyc1Y2elZQbUxLOVZtUHFZR241Mkt1OWdVVDlqNTZpb0w5VDdXT2lMNGd5VDZMCjl4OWp0bC84cUE4RVhTT216MUZUbi80MXJPeFhoSlhxM3Y2eTVmTTFVbTVmMUQ5WFE4a1o0OStkNXlwcFFEcmp3UUJFcUx4eVZveG8KQUJCMUNzcU5MTnI3WkJoWXg5cUR1bDQvb1pZTmRtK2o4a2pESlZLeUk2bW5lMjRkZlprU1BWS1Rpb2dSV2xhYzA3Q3RWQUlyUmpTbwpOeDJwZVZPOUk4M3g4dFJjT1ZXQjcxZXJBcjMxaVI4UmdHTzdOZ0JScDFTYU1KNnpwNlI4TWRsdlk5VDl2WFppYm9lUzBxZHBWTi9wClZ6UXlPLzhINXZNU0JnaTRSVUVkQUU5VHZGcWlDWElHUmlyT2x4SVFvbUhkeWhsMXNoQUFXQldtQ3RxbW5tYytHYnRxY1lmalN0VlcKeEFDUTc5Zjh1b2JHK0lnM01MVVpxZkxyVDZxRXFPbDNCelIwTldJY2c4VVFkUnhBRFVibFpDRlFpWVdhdUthNWhuZ0JrY3BhV2x2RwplYVZIZEJBRHpxbGFKVlhQTkJUQXF2ajFIMmozSGl4UzJSNERHSm01YU9TRkw0dzBSb01tbGg3ZkNUM2JtVDVocFo1cDZOc2J4SCtlClB6QXR0RDZsNmRTVXJuUFh6RHNXVzNzYlV3RWY1QXhVRUtrSUgyVldscGpycjBnL1oyK1Zmem03ZlZacFlxNC9EajY4OUhzVGRFVzMKdXNUZGtMb3gxbkh1cWtYOWZrWDRTSE1BZHk5ME9hV1pERzlNdWVacm1CdGZKMXhzalI5cTh3YkZabnJTd2NjSEs0T3VwQXh2U2I3aQpaWXl1bnhwMmQzcVhKVndNU0l2MlpWR0NLTkhYWGpGSHB3cHlMM1laUnhoK1kyMjN2TTdMRmkxeGNWWVhyZyt2T3VaMTVhcDQveW5QCndSbm43QjkvSi9xSDkrbkQwd1JBa3ZCbmdVZDUvSVVBbzdpVU9uZVZkcjh6WnF6aGNxWm5VN2poZG1zbllxaElUdk0vV0J4Vm5EcTgKK2xoRFZtelc4T3NiM0h5VGJpZ2NXT3JkbEpxU3BBdFdwWktFWVQvVjcrbnlxazlwaXBsU0VEbEpjVFBPd2hhNG1oVjdlM2hpMGdXeApZV3ltcDhHVDJFeXY3bTl6QmdlaEsxcldGc250R0dVV2wxSlh0c0hOOTI1c3AxT2FKR0UwaTdzZEgrZ0wwSmswZTR1elB3NGNqNDRWCnRYWUgyNDVLSHc3K2JxQkJYSng0LzBsdjUzOTc4bjVKK2pWM1lWaE51SHpoVDRkSzNSaFZMaWk3ZFY0NDduUG5nSmZFWUs3UkNBLzEKQkpqTFhnUGZ2UW8rdnBuN2VzWG1GWjZRL3pnMkttdXZ6WUl1Z0VRbFJRL1Nsell4NEx3bzVIT1hQUWErK3dCazNaMjJvaHNNMy9sVgo3YzI2dWVnNzU0Q1hndlo1K2EyYk0yYUtxT3owbWs4VmdpUnNtaUcrREloeXJxMVlYeGtSU2tkRFR4a1lkUVVjR0RSbC9ZTFdDMW41CjAxYVlYOHRkOWFIeDlHQXY0TEI0VnN1a28wYjE3anc1YmNKK2E0LzFydDhQbnJvK1RIWUJJSHI4dS9WbDRhRTQraUI5V1pNOFdxa2QKWThDNjJXT20yTVRucnZvUWpMcTJ2WlJUVnBHeWFPcFJvenIzbHFpNTUwOU9HUkNXbUwzc0g1ZUxmNWoxclpOaDVIeUg3K2FkTDgySgpYN0d1a3F0WVVKcnFHbzN3QWFGUkFKcWpYanAvMGpCeS9zQjFjOFpNb2JWenhrd3huZUUxSFRBb0tYTFpKL0xkOCtEVzhxWXBBOEt5CjhxZXU3UDV1M29YQ3ZMaUZ0Z0R3bWN1S3lRMHZXeTBGakthTkc1MGdtMjUveWJLcThMQjRWdk1zZC8wNld2eDEzUlFzTzFTMThlaWwKM3hCenRIS3BXY0JsdC9FM2RCTVR6QWh1QjJCcUcrclRrTmdrM2VaeXJzMWhhNklubkpEVUpOM21jbWdpY3dRWUU4UGwrcEx4QU1LNApiSm1KN1FTZkJnQXgxSGljQTlxUzFBUTBHTnNHRFNvdzhxNnJFZ2M3REdxeG9hWUs5dG9pUUdnNU92RGxxMXZpSzJUQzk3NDlFMlprCjdlNWpMZmFzaitFYWp3c3NwL3NyZzdkTlhoc1o2T2FWbkRSdHl0cjl3d0IyVG1hL1ZWbTBBV0JzZU9EaTVFL2lLMlRPMTVlRUpEVkoKdDdueTJ2RVI1aW90cHdjMGdOaFZSMnozc1BJYjYrV1ZsRFRkeHR2bmpUandnZDVPdEpUQnhjbDZxTC85eDhjNzJ5MUhCNzU4alRsWgp1VWhOVEhCdXFNK1hBR3g5dlA5d3hYcW92MEdCa1hmZDNYdEczblVWQUFBbUpoT2JVSjhuenRjWFR3QVF3elVlNDdZYzc1QWRDWVVUCkFCeHpFMDY4cUJwcW9VWFFPQ0VnWkpQWFJnYnEvZFgvMXpNeUJzeTVidTNvWEdqSUdJT0FiVE9ZUVFRbDljdzdiaytHc3BTcmhJOXYKeGhQalhDVytQbEx6VEVBQk1JYkhwMmF1QnZDVjZBVlNkY1l0SjhpOFcwVkFPNC9DVG5BQXJLWHRzQjBBQmdFWXpCOCtRUjRBS0dBVQp1bVRtQ01MU00vZUhxSHhXdU9ZRW1YZXBaZ2ZnMHVvajhQN2Z6SmtpclM0Q0hObElnK1JRdnZId0wxU3RMeXlhTlpKcVRyMzRocXZFCno2ZVcxNDdFMG5Zb25WSXhlRnhXeUVvQjRQMlB6WG5TR2dCdkNjeWNoNDIvOExrWUFBK0VLV0EwQVVwL0F3NEp2Skp5R0lRQ0VFdmIKWWV2QkI5RlR2aFlTd0ZBVE0zTVZpQThVdCs3VklXUXU0VDJCZWt0ZzVzeS90VEdPQVRCb0I2ZmdHWGIvdS9FdU5mT21Tb2J6NTJMNQpiNEQwb3RKN0VydGRwNnVxZmJZL0FmTExpcmZtL01ZUHlDOHR6Q2h3OFBmN1lPaWJiODJ2Q1I3MCtza0h0djcrSHd4Vk9ydnN5cjFkCnVuSG9YQUIydTA1VkpaUStTaTlvQmVhbmpvczF5czFTdkRkeWxmbkN4T2szakh5MnA1YmtDRDVhZVdpOUlQTjJhVldHcExENW5kR3IKSEFEZ1l1SUFEN3ZOMmZrdG90K05RR0g1L2ZUaWl0emI4OUpDWWpzZXBtYytydkQrdVlCd09qcGtJcndkdzNBbU9tU2lVK2ExRFcvTgpyeWtzZTNDcnVDTDNEakY0bjdrUVlEOWcwNTM4Kys5NXpmWHc5L3ZBODcyL2Z2SDRCaUQ4YU9YUDYxc2VwbWMrcmdDOFBVWitOaWo3ClpnZThIY09BV3dtNVlURGZzeVFsVXZKTzRkRi9mcDJha1ZkalZQMUpReG91Smc3MHlDZ3FLOGk4VjFxOFllMlNKaENRbnBpeklDT3YKVnZqUmlrUHJUVDlhY1dpOUtDbXJET2pNdVoxZldpZ3B1TDl4NkZ4WTdKMmZHbkxadUhwTFE5cnk1TTJTTkE2MDZkTWo5cE9TaXpJQgplQis2V1h3TlhobGZGYWVkamc2WjZKUVY5OTRXL1U3NnI1VTRJbW9uNmxEejNEcEpybkpQeVRQQVZLbVZpQlFkeER2UEpCa1JkYlEzCks3bGpuWTBjY1VRZEpOZTQwRlI2MW14WEVNOWI2eWFPTkI0NGlTT2VlRWYwOGZFbnBPMHNVeVdpVFNXcW00aVR0M1J3SEJkQjFOM1UKd1ZHM3lpT254bEZuRzNIVVFYTGVTV1licngwUnFVaDZ5cUl5L2hjWG9TS3RkUk5SSGRIRnZDY0YzeEFSZGNubDlQR3hKMXFpdTdxSQppT0kzMUNtcGNxMXFSNkxhNFI2Nk94dDVZVEtpcm00NUVUVTI4U2NhMVNQQ2oycDdleFBKVzlxSnVuZ2VuOTZTbmlseFdva0JNQWFVCk8vMkl3UkJDbm9GR0RFSmJyU1Y5TXdBQ1F3QldBRThwTTJURy9FbWgwQkJneEl4SXFDcE5Tb1lkakJnSXBnQkVVRW5oR3lid1JiamEKR2pHSUdaSHdVc1FtcFNOcGJRRWdFY0NFNXFEUGM4SUJvU1VBRWNDTXdidmc0ZGZ4VEVBTVJpU0UwQkNBQ1FBanZsTmtydktLcFdUQwpBZXp6N0hDZ3RzYWFsd1JiNEg3VVdKZVpBR0FBY0RWMllpMUhkenkyV2lNVjg0OW1tSUVZbVlHWTBvVWEzMXNSRElpSkFESlIxaUErCk1pTkVWdW9laTVRRFlreENjd0FpbnNlbnY2blcrOUpjWDZ2YUduQ3A3NkJHdWt2NVBmRWxUYjR1VnFTRlBHbld1N1Vha0pXeG9mencKOXdNTHFhVTBHeHIxYkxsdmY0MHFVcExHZjZadWFqWTBZbFRBSEMwMG5aWS9zVk81Q3BXVkNUeEVQWUdEK3pURXZDK2QrdEpVeGZKOApOa0hwL3d1OFM5MmU5Z2FDbmhhbXN1Y0lhV1lYZlFLZVR4L3lQbkU5QWxpL0U2bUNRUHVnNHVuWWxvWkYyWk52MVJQNDZkbWZ2Z0Q3CnAwR3VmUk0wZFpHdFh0ZUNIdE4vRDNhSkhnQmJQMWIxWFBRNEhhRTk3YUYvdVBqcEUvQ01abjg1Q3YwOEcwVDZhcUd2a2VtVDlmbk0KTHVrcDZmM3JzbVB0d2Nmank3VXlDR28zbTR5cGtUNWQ0STdwL05RYy9hSDY4Zml5ekdBKzBxQUdFZXBCVUNQTTBmSUMyME1ZWDE1NQpTRDNhQllDVVNUM0pkN3IwT21WNjR6R0E3MWYzVkZlVHFVbzFFd3Q3S2tPQWt1SDMvUnQ5RGhwUDgxT0oxZVpSTVNCbE1nREdoMkpVClV3aDFlcWg3b3lTb0lpanFLK2sxSWdsQU1IWWxCN0gyN1pOaDlYemRNZW02REVUUkFBQkJWa2xFUVZTVklqVUNkS1FoY3BDREdLTmEKNGZNUEtKRTdBRVM2bm5jakdTNW93OW9hNWhzdWwraTJxdjI4VkJVYjM2UWszNmx2K25XbmpGMDVYVVdBL1lPNC9SalJsOTh2bmN5NgpHSHNiYmFmTUdraHgxWHhFS3N0cUxwSkl2ajE3bTc0SGxBRkFTQ01BbkRUZS9rS3Y4YVA5Mm1QRzk1d3hBSUhkLy9JMC9ndEpqOWdsClErZVplTk9CYVdaQlIrWllKZDFRREVvKzRodjFJT2dIaXRWMXM5bHg5cXE1SU54d3V6WDN0WGhRdElVTmt0NTB1NVUxK0J2aGdHLzkKQzYrWERBVllkTmJnN1NMYlhmYTcvVTJQekxIYS84ZTRHMDdoUmw5Yk85YW5KajIwdEdMNWgycC9DakM3ZUt2VS9XQnhGUGVPTysyZgpLRTgvYTI5MStZYlVBK3pMVTE1RHp0Nnl0d0RLRmxzanVpYXZSWkl3SnU1NjVxa3ByWEZYcmN6T1hqTWIySko4eFh2SEtVOW5vT21uCjR1dXZSN2ZKSW12eXZEUE8ybHVWSjZmNXJKQjZQVFJyK3NHWEhmQXhRblRXNE8xQ3UxMzJ1LzEybnZJeXVkRVlNNFVCamRmamZlaHMKdk5tQTF1UXIzaTNLVERxWGFtK3dvdFlyWWVoT0cwZEYram43cXNpYVBIOWNQNndhaGVJTmJnTnVOTVpNWVVrM0ZZT3lqZ2NmbEpadgpjUE5GeHdxcFo0TG50emFPamRmamZRelJkYkRteC9JZ3hhMXo5dUxTcEZ6L3BvTWwxLzlFclBpN1JtZWIyTXloM0U5RlVlTU5VUlovCkljQ1FZZHNwMTZTaXFOcVNRWHNHMkZ5NVhuZnNwTmZnOUhQMlZ2bXgyUjB6OVdoa2VuMWNuak1NM3NwZmJZblp5LzRSRzNMWWFtQSsKT29KS0hybnROZkRkUjBvM20rZEZJVjlZWDh0WjlhRnp6V05JUFFpVDdNTkduN04vM0dabzFSMitvT3hEeGpEcW5IMk56TmpDT1U0RwpBQndUSklyamMxZC95RFo3MjV3ZkNBemE0WWkvVlNjdDNTeXN1TEZvbXYxOHR4K3czOFpqM1lPTTVjMEFacnROK054NTJkUjZ3SG5ZCjNLQzlYbjY3WDdudzBDQnFVbUhLWWZHTHplZEZ3VnV4YVliMXBkbHVvUURXTFF3aFVjbER0ejFlZnBFMlE5ZDNmZlZTVHZXMFlDK3cKa0JoRHcyNExZTlE1KzVwMll3dm5PTmxzdHdtb0NDdE5CV2lYZi9YZWM2TGdMOWltRjZ3dm9TS3M3Q2FBejV5V1QybWJGdXlGMXJmKwpnbjAyN3V2YzkzajVBZU9PV05yem96QjVRQmdxd2twVEUzT1cvaU4yWkNURThaTUhoZ0hHMDRLOTBicmhML2cyb0dvdllGQjJldTFuCmlraWJvZXNWUDQ2T3lscTdNSVFEZzF2Z3hJQTFjOFpNTTZ5NCthb1JFQkdLSXd5WTVUYTU0c2FyVHJHVzVZOGVwSzlzbnVNK1liKzEKeDNyRit5czlPVUIveS81NlpaQXZsT2ZJK0UxYnA1eHAxaW1EV1pma2wyb2RCV0ptYkR2QnA0RXI3TEx6RWdBTEZObXRRcXNaQVExNApQN3pLR1F5TW80QW5EVGI3RTJZbG10TGNFd0FDbmpUWUhJaWZJN0lrTUpDQXJDR3ltdTVmaitZeVd4Y2p3TnBxMUlhcmcrWmU0QVJXCnZtTU5PUmdiNDd6TVladHo4aUlsTW56TVRUamhFZ0F3WTV1Z2dJOVBLQjJNVGw1N0lIQ0JJcWVscVFKTEZ2R0lVWkdWSXhPSUJVWjIKUVFIblpmWmZYaDJFcjkzQUFNN2czWjFudzNoVmJBOWNteXV5QkFCeUVydElnWTVrNlNzTEZ5aXlXNXNxYU1tcmNCSVBxUWR3ekVNNApJUllNQ0hDUjRvTE1ZWnVSYlZBQVlEanJjamMvQ2dDWWs5aFplc0taWnA2RUNDTHdBQkJqWUFHdTByYVUybm12QWhDUGRoalVmSzdOCjRjdkV4dnB0dHNYV2pqd2JnZFUvTVBLdXJiVHlEVFlBdGx5cmJBZUlRV0RsRjJ6RVNNU2NrMThkVDZEemJmWmJFejNKaVY4VzFKT1oKNmRQSTJKY0cwd2tDQnNCTHdzeUg0UGQ3UkRQZmVSR01Bd01nL0hQTTFPa0F0aG5NNEl2RFkrQ2ZYd0dCR01PeWQxK3J6UjNzbmNsTQpYQURRc3ZlVzF1UU9WcjZwYzB3QUlqQUJObVRJL3d3QUNoaE11bkYrcm9sU0RtTmtVeFBVVlh0Njlpb0E0T0FsWVdaTy9FOEJsSTQxCmlSR1hLbzNZWmpDRG1UOXNSQjQ0QWd5SzJpRUhVekFBdHJXQlhlNVhGRzJsa0FNTXI1MTVNQVFBbHIyNzlISCtJQWg0WVJBUVlGVHAKRk5UNHBjRU1XRDVzUWo0QWtRS0FkenF6Y0lLY2o1Wm9VeHZVcFh5RCt2MGVnNW52dk1qM2hRT0VuSStFbVR0RFRweEM2ZjVBRGdJagprM0xIb0NjQUl5RUptVzF0WUplcnhNZTdxYWlOOTNSS0NuRk5PK3dHOEVJWHp3N2kxQnZ5REdSTTBWMGJNM3MxT0daVEc5UnRrY0hRCnJiVnQ4My9LeUdqQXQyZXJTbkl5NjB0dnZaWVNtZkUydkl4ZmVkM0JzQ3NuTzYvNFlWWkI2KzdEZTM4Q1lQZnQ2YXJjaCttWlZSWFkKUE5BSURNeDhEeTF1OTE4K0ZBRnVmOTMvRFFGc1VadmZTay9VRldmV2w2UVhWRHpLZUZUME1EMnp1dUxIeTVILzZBSlFkZUhvR3NzcgpFZktNN0pzZE1OdDdyNnowemJmbjE1WnU5SmdMd0NuejZxWlBqOWhQQnVDelBiVTR4L2p4bHZxMG00OHE4aVZuZnB3d3llN2JNeFUxCjc0eGU1ZUNVZVJVdzJoaTJzNjRnSi90dVNRN2VmQ3VzMXNkajFHY3Uza2Z1NTJiSkRYNDNIQUN3cU4xM3BUdnFpeVZPbVZmVGk4cnUKWllFRTc0MWNaVDVnMTVuS3FuZEdyWEtRRkpYbFp3SFk5UGNqQXlkN0gwNHR5WkE4cm56enJmbTE5MHB5QU1ETDZLWFhIUXk3Y201ego1bnNsUldYM3NsNUxpWlM4RGFmM1UvT2F6ZmNTNEgwNHRUaEQ4cmhxNCtqWHpZSHVyS3pTaW93MzM1cGY2K0h2LzJlL2pXRVIwa2RBClUxWlN5MTlYSEZySHNtOTBFREJnVTg2OUZzQkpFcHQ5czhNcjg2dlNXNlViM2VjNlpjYTkrZGI4MmpHRGYzL3lRYU0rM2JIb0U4UGkKT3BRNElnL2JFYlZyQWc0U2xSMXJMdjVNVG55MFFENmcrL2xDSWlKT1RrVHQxQ1VuM3BjbGozcDJxZjFtcWlVb0l0cXFEdDhtcGFQTwpUazVCSEJISmlZZ2pycDBIT29sSVRsdzNEKzlSTnhGeDNYSTVIOFcrdTdtZHVFNlNjM3lrUU9LSXFGblJyQmJmUnFSMVJoVWJzSjI2CmVPQ3pXNlVPMzZzT2txc2hTNzZ4Um5WZFRVeENJbXBYUldXVXE3cFRSMFNLeG5ZNW44TjFLUXZ5cGJUcXkzUVZWTUt6SEtuQlhGNmkKckxPWjVFcUlVOUZPUkkzdG5mcWNkLzB1eHZhN1lFa01TUG43V0UrM2lWcVpOWXNYLytsWmw1dU9tQ2VML1AxdHcvcUpMdmlMTlh6NgpHcWFHQmZlY1Vuc3M4eXNmVms5M0E5anZVbXB2ck9TWjBBYlE5K3EvSHRLdjVXbXh6Nk5xWmZ3WFZZWjBRSC8xMFd0Vm0vOWJZeWVFCnRxUE9QcHA3dGxkRjl1d2NYYmp6T1ZHSWY1ZVo5clQ2enlmd1YxcjYvNitDbGRURG9BTmRQaStoOVhsSDhCbHVDZnNYMDl0V2Z3RisKcE5XNTNsMzh0M3JWQng5Vis1emVBdy8yVG5xR2xhaS9BOTJvZ3F5WGpaSHVoYXdqUmlkYVYvK05ra2FlcnRjS0hvcFF4YnRpZmRWVgpONkROTGVyUGM1OWFwRmFMV2dKMHUwaTk2dXBtcU9NdHFrL29GaVpkV0YvWmhsYm9NWTEvUG8yay8rRW9jUUE2MzR3Q1NPbVhrOGwrCnB3WUZtZnF2OXFnVENPOUdyTnZ5K1hkTUIvTlJiUXZpaVdEcUNJV2s4N2NtOUpHT0UwZWxjU25maHRRaWlOUVJCblhOaUs5RW1NdmIKc1RvMlpzZmFIMnZHbDJtS3ZWRk5LbXFhcGhxVUxEbkNYQTNyVmpKV0EyOXBtWUU2czVlSFNjMllNRDZDSURFOG5sQUd0UDIyRjk2cgpwZ1pDRTdGVGZXci9tbzYxUDJyR1dNL1BMNzBhR2UwM2RpZUEwWGwrVEhtQ0lDbkhUMmt6QnpRelJnekFyTGRhaDMva0RWS1dVMzZzCmtDb1lBQjNRUkNoa1duL3JUOW5iY3FyWmkxU09PRk81djRlNkJqRmxqaXEwbjZvNlArbVJET2Y1MjQ0cXpDU01YSm05bURSMnZuOFEKVSs1TlZIV1Q1NUFDeENKVmZRVUFOcnFOZU5tTU5JUkxMUnRSbVliU1FKUlhDeW5WVkNybllBV1FxWXU2Z0NhMjdKVXk1ZVk1TUZ3cApWUThqZ1RDODA5aFZjL21SbmgrZytzTXVpZUhMVTU2MThndFZnZmNpeC8xWUVqVSs4VTU4b0MvQTRtN0habzBRWGtvdnRZMW9QM0xqCnBIZkM5UkZWeDBaQmVjUHh3R2xmbjg1OXRYY3RFeTRFSkYvUGlwbkNydDZvZFR4M3pXeGdTM0tjMTQ2VFhxMlJrK2hNbXIzUndjY0gKeTROYTR1S3M3SUNPRlZLdkJNK2RObzVsOFJjQzB6YTQrUUtzL2Z3MU0wRkUrNUh4NmVjZHJBQ2dJamwxT0oxTmRiQ0lqODg5Tkdycgp3MkUvTmV6dUd2UlB3L2J3c1N1bG5tM3hGd1BTTnJoUjVDUTZrK3BnZkxEbVlFVlF4OWw0OHdHM1RJT096RG1kUEx6NjJDZ0dTSGY0CnBmRlJCSWY5MUxDN3kvVmcwVC9IeDk4cTgrSnVYcmJNM2VERzlrOUVUa0tkVzVva1lRejJyZ1d2bWlBMnk5TUFRTmZCNHFqeDkyTTcKUk51TmhrVGJjamZpZlpLVExsam5wa2c5U2hOei9RRWdPc3R4dThqMjIyRnBOK1dEN2h3YmQ3RFc0OWdjcXl2WkNZRytqTmlWck5pcwpFUThpYS9JR3hVcThxeFpiK1hha1hQTXh6SW12RlMyMjlqRUdjUFdHMUwwc01jL3ZjY1lyYVdaQnBVbTVuZ2VMb3lZazNxejEwS2VSCjZlOU94b0RaYmhOUTh1ZlB5UzFhV0pteXFQQXFUeEJFNi9keno1K3NUbGl5V1J3dm16N2JmZnlrSTRiMWJocmpCQUMzdlY3K0VhRjAKMU9EQTVJZlhIOTVhMW54ZU5PNXpiSHpCNnRKczl3bHUwZmpNWmZtVWxyTFRhejVUSEJiUGFnRmdQQzNZRTYxdi9RWGhvVGd5ZVVBWQpRTGdnSFBlRk9FRTJmYisxeHpvQTZOdzJKNmZrTStjVlV4cU1EczVyMy9IQm52YWNheXZYTnRmZGN6MG5taGJzSFJGS1J5Y1BESE9MCnhtY3VLNlkwbGNXcy9idml2R2pjWi94VGFkSXhaUlJDNjJ0dHlpaUNyYm5YVnF5cnFieXhzQ0hodFUwc1lzQ2txQ2tEd2x4L1FGYnEKb3Urd2U5NkZoL3hkMG5oYXNOZTZPYU9uRUFCUlJjcWl2UHlwSzIwYks5RHQ5SjFmMVQ3RHlIbXRhY3ViNWRGam83SUFIaHR0TmJhVQpaQy85T25iRUFZZ1R3Q0h2NmdJYkFBeXRVWFBQbjNUZDQrVzNiczdZeVVNQ1hyYmE1VmUxTHl0MTBSN25nSmVzQUR4SVc5WW9qeDU3CklBc0FvZnZnbU85ektsSVdsYVF2YTlLbmplbjVjUW5BMTlpdTJjUkVhT2szOW1Rb25FQUFiTHg4M3JnNjZLVUxDcEZsNERpQXVma2sKSlU3WE5rN0EyQzRvWUV0OHBjekdZNmp2a3lIWEY0OWZvTWh1YTZyRWE0c0FtSmpnbUpzb05OWTYyR0Z3eStTMSt3TDV0aGdGdUVqeApTWHlGVENsbmdTSmJKcklJSEhldXpYNHJBRnh6Wk50ZGo3dUpRaS9hT2xqNU9wdTZQTEVjUGV5VmEwSkFSQUMyeEZmS1FEQXh3VEYzClVlaGw4VGo3d1MwTEZObHQvS3UwbTFkUzBqUUNJTElnV3djclh5ZFQ1MmFMMFlFdkoxajZCVHUvZElIamd4Z0NKaWJLQ0l6SE9tVHEKUHZHY1RBQUNLNyt4NTduRzQ5ejYvWlZ1N1VsMTh4YllEQTBZbWJKNGZGS1RkSnNMZ1lkcHY3ODI5NVF6WGp6Snh6cGtwS1JXRW15OApmZDZJTTdIaldhV1ZnRXdUN1pBQmdIUEs0Z21KVGRKdExnQVlraHVsWDdwWitZMzFTRm1zWDNhdlhtRWx4akVldVFNWVlKNEpLQmdBCktHQTA0Y2I1bDNtb2tRTTJmMnl1ODkzR3Ywc3Nuam1DLzFFVE0zUDFOb01aWlBId0NmTEFBY1NUREltUDZ0Y1FBWUFIUkFVY1g0dXYKdDAwMGd3REF0alpJRGdEdWx4U3lFcDZlQ0tXekZRNUdFd3phd0hIRVlmSE00Y3FhM2hrd0d3SUNBMDhPQlJqdy9zZm1UT3NUazRHQgpLV21UTjg2L2JNelRKZ2tBM0MvZ29XemRvaUhxdHk5T3pMTkErZVNhRTJRdTl6RGNPODIwMGpHb2tZQ2FVeSt1ZHBYNCtrZ1p3R09qCmVZTzhKVEIzaGdJS0JSaXBlS2RxQnFkU0htZktSenRFWVNjVUlLRG0xTXpWYmhsK1BsSytJUW4vcStia0xOMTlsUC9wcEZlQTNDbnoKVW5aMmFWWG12Ykw3MlRjN2xpZHRsdHppQU9CV1l2WUN5eXM3dVBpU3EzREt2QVp2eDdCVjJWQjlEUlRueExmbWwrUmd3T2JzL0lSSAo1Zm1TOHZlR3pyWGJkYnFxV2dreDNpc3YyZlQzdy9ZaGtqdWxsUm1ubzhkUEJBRHZRNm5GRWtsTnBkMm03UHhXODcwRXdPNjcwNVhaCnhkZXcvcTM1TlFEZzR6SHljOWRObng2eDU4TUFscGRLY0NGeG9FZkkzcjF0S1Q2SENnWnN6czV2c2RoN3I2eDQwNmRIN0VNeTc1UlcKWnRqdU9sMVZrcHRWWDNLTFoxQUNxQ3VSOEo1SFN5VzRtRGhnU0hacWgrV1ZiN2c3RzlZdWFZYkYzdnl5NG9VSk0yNHFveHMrQWdEdgp3dzgvV25Gb25SR0FydXliSFdHcElSZk44S2FZMGNZUnE4MHo4bXJLTjNuT2RmZjNmMzhvQUdCeHUrOXYzYUhFTXpmZHlpc3B5VmllCnRGbHlTd0VBNlFrNVlYa2xPY0tQVmh4YWIraXp2Zkc5VWF2TUZpWk12MkhrdS8wSkE4bzNEcDNySHVEM3dkQ3NodzI1V1M3K2ZoODQKWjkvc0tPY3hYRDBtZldKWXBBbm9SeHlwQ1lMeGI5V1JLaEloejNXTTRGcDcxT1NJVTJPYThzNUd2ampYeHFtWW1sMk5mQmhDa2plMwo4d2lmQ2lUc0lMbXFYVlVUQ2hVRlUwWTY5RVNlaU1rMVVqTlJOMUVuZFN1bGQ2dWs4ODBTY1R5RFVsVlB1em9SUngyazRFamVTZFROCnFkcnBrc3VWSlRucTFtS0JFc2VIS09RNlNVa1Y1ZnVuREN4SWF0UzJqb2hUTkxYeGdDay9jbHpDaGpxbGpOWU9mdWphT0ZLUlRZbTQKN3M0bnBJeUFxTzZ2U3I0ZWsxNTVsNlFWMkl4QlJSQ2ttaG94VkpFSUFSRSt6NDVnWmozVzFCa1lHVUVFQm1KQ29TRXhJMDRJWmdLUQppQmdBZy8rbnZmT09yNkpLLy8vbjNOejBuZ0NwaFBST29vRFVVQVNVcnJTdmROU2Y3SzRnd1ZVcHJxdGZ5NnF3S2xKVUlBRmNFWllpCnpRVkNxQ21BbERRZ0dFZ282UW1rOTV0QTdwM245OGZjbW9LUjNibXNmcy83OVZKdVpzNmNPWFBtYzJmbW5tYyt6N0dIZU9NeVVlZVgKWlhKeFlJeVpReWJXckhGbmdtUm02cHF0aU9uYkU0WHlNZ2VBMlpNTklDZG1Ccm02ZitUMm1ydWlPWm1JUDNvL3lWeWozVTZ6ZVZsMwpCd0JnWkU0eWNUNUJ1VGdJYndXWWttWThua0ZPV2hjb01YVXptQ2tBMFhoblltSkdERmFhWUpXRmFLZDBCaGl6VmU5TGJETzdWKzZnCkhsMjJCakhJMVpaUjBXd0tNRG5NQ013S21pQ29GVEdBeFBxTmlER0g1ZHJieGNSalYvc1F0VFRJTGR0dFo1QjhzZVBjbTJBR3Jzb3UKeHdwMWNaZW1RcWFlNExDRFVCYUI2V2N6ckRmVldvQTFNbFBiSmcyc24xckQ4TU1pb20zOFJSMEdKc1ZoTDJhd2lOM1FPamdONnlRWQpkcFJocnhrOXpHVFVzVjh4S1NCcmR4SU1PcW5OdXdRZHhPTDB5M1hXWlFZRk9qYmlHbjRBNjlwSjZDenlpWFpCOHE1R0o5Rk9EUHBmCndRNitLdHJsN2MxdkhUZnhvYjVQSTJEVUlReVd2MnQ2cHNaZERXaHpXZWJ2bkM0KzU2dmpQWVN6STlUZG9UY3hsdUtsZzlwNEVOTjkKUFhMYXU3dkVYNHE2aUdFN041TDJ4V09tdFp0cFMvM2hibHZMajhFbkJnQ2JGd0lvZnJKVzc5REVIVTVFZW4vdG91UlIrakdxQlhjTgphdFdWMHd2UDZoNGxHTkQwOGtFQUJya1lDVHJ0TXUyUmFReDJSUkVObWpVR3BrQXd2ZTdJbXIzMWdiR3ZaTWFOWGE1OGVxdWZ1bXMwCi8ya1hHempUaHRScVB1bStkMVplTUFqdk1nQzBHY0ZmdE50TnV6U3M3ZEgxczladXB2VzJkVnBVK3lueVBnQlAyL2JWSDBGZmhmYVAKd1Fadm4yNXhNd2hOOTIxcXV3ZDEyYW9ENnFYV1lqckU0d1c2Q0paK3Ara21ybU5xNjV4ZU9nT0d0bGRWRFdFNUE0dyszNER4d2tvQQpMbTIwdzU1N1dhR0hMcnBZL0xONGQxYTNEeTI5aWVIU1Jqdm43eFY3dkJQaXdyTitHTGk5M0s5dVI5N1pWOFZOTHFZbFBuWHliTWFCCnA5bnhLNG1Sd1dDVjZ4UjdoaVdmVjdydHYrMjJzVnZzUWYvc2N5RTd5cllYUjdhbUhuS3hCNkJLT2VSaWYrSmNoVjltUXJuZCtpYXgKc05wREYyYU9WczJPYTgrZERqTExQRjNoc3k5Z3ZaTkhVY0tSM3JteHdwbyt6V3REVlNkUE9sd1ZJMFY5YjEvWU81UUJLRHB6OFFrNgpkTkdGZld2ZXZHNW9lZXJ6SktZVUJRcVNyb1VWSnNTRm01ODRWM0UvZGhoaVhseDdOL1RNTFYrUWJJdmRnZDZXNnZoUTVaclE0ZzBtClh3UWQzRFBpZEVaOHhwTW1zUXVWS1lkYzduMGoveUx3NEo0UkpnVkoxd0sybDIwdkRwcFhFU2cvZHpyWVREeGVGTTUwQ2xURXB3ZVkKTXVCRVJuekdFNG5KY1E0VlovUDlpMlk0QnBVbFh3dFRuVDl1OS9NU254QUEzL3R2NlBYZ3F5ZFRqb1dzdlJ0NjVwWlh5aUdYMHRpeQpMTVhGaTMwMFltUFlPcjA4VmxqVHgwYjlwekV3Nm1Ec2dCN1QrMjBNQ3YyNDE5d1I5U1VKeTcrOXVlSk5BQmpRWTNwQVl0T285VkhZCjAyY0xIQkt4YU5vZ3pYc0tHeVlmdlNYZk92VDIyYXhUMDUwRUFBNkppbEZKVjJkOUh1OFNiMXVVTzk0N1NwWmtXbmp3MWIrcHRqajYKUlFOQWpLUC80cHlVdWZVWkYxN1k1SkNnR0pWMGRmYm54L29lZGlsck1yZTFBK1FsQ2N1L3ZibjhUWHdWV3JvNTQ4S01EVURUNis5aQpiUlRiNHgwakQ0bHhQTm0weTM1Y3ZmbjJ5WW8xYjhmVXJJc0tZQUFlZkRZcE0rOWpyN2tqSGxUZTZQVXZBWUE2cFNpVTIvcC9tN0UrCkNudHlVdWJXKzN4SGdKVjdLbktlQXNDcUk5Z0tUWHpJL21TVDl4YjM0WXVuMVI5dC9IWmkzRDRBbXgzOUYzdC82ejVzOGJTR284cnYKQjJ6TkxEeTQ4RyttSS9zSHJnOHRqZEVjcjFmWVJJZlhKajQxSEFBMWZqc3hici9abGlueWRkT0svdUlWUHNsbTIxTmJNOVoxSDc1MQplUGVwQUVEMHpQUHVDVTJSL3hDYnNOblJmN0hQeHNEUWI2Wm9MM0VNQlBpcUU1OGE3ZG5NdUxkTEJvdHVrZUUvZU11SHhqc0dtdnY2CnVpblZtY2psTms4TWVEK2h1QWt5eU5HWTUrakIxQjN5d2Q3bUptZmZnT0RxM1ZId2tBRXdzWWtjZU1DTGpkdHZJbzVTa0JOa0R2M2QKM0J1UEtGdy9CWUREQ3RlVjNtZG5ETmtkWWJMWHhEWmk0SUZlR0xjdnZLYmFhV3ZDUkFETU1jREMxOGRkcFRoWE9XV0tHSUVKN1ZXQgo5eE9LbXl3ZG80S3I1WFlZL2xwTWhMT0xmYWluVmMvYVVRTmFBTUpKZDZ6MitjRkhIblhVaEpncHdMQnpHUE1nTUNUWGxhL3E5WDVDClVWT3Zzek1HVzFvekVHYWVybXV5QnhnNWhyNTFQcm0yL08rOVFEQzFnNW16YjRpalEzQ05VMkRRSDA0Q09DSW1CZzExZEFpc1RxNHQKKzd1di9RQlg5d1ppaXJNVlU2WnFqaGVNVldXYkJWWVZBY3dwTUhqQlNVZWZzQnZXR0w4UFFISmR4U3F2dzM2QnF6VDlPMkJNajJJNQpNMkUwTTZHdXllNnd3bVdsZWJmSWNJOEJtZ2NOaUhtMm5JY0UxNGluNC9jbk1zMERhVkFhckx4QW1oUmJZQ0NTRVpzeDVrbUNDcVF5CnkxVkFSU0F3TkM2YTdpVyswR0tUVGpJbEFDWVRFSkFPYXkvVFpxaFVKREFHUUVaTWNLcUlVQUpBdC9JSTViMERZeGY0eHVGMkt5TUUKcE1LNkY4MTVZOWE5TFAybkxjdGk5NGg2TVFMRFpJU1pZNThVSUNNWklDTzZXTDJPWk9MWVhPREpiMUxCNEg5Q3BTZ0lUb2QxTDlObQpDSzBnMktTSjU4MDdMU3k0WXNiWXZrTFpnYkVMU0FBWVpLL09HcWJlUzlPenZUTENReXEwUDJqQVFNUlVURDRVZ0ZObHBGS1RHZDA3ClBUeTRqREhJaUFsV3hSNFJkWnJqQlpUMkZjMU1UQXlxaE5sUU1BcEtoYlVYUWZCT0N3MnBkRW5HZGUyTG0ranBLVmVRaXBuOGFmWXcKMXEwaVVza0FtcnR1amtyM1U1Y0pqSkhNcUMrVUdmVktsbjhuN21wQkpwWjl0THZINEN0WGkvTlRzb3B6QWVUbnh0M05UYUR1SzY3YwphUEJjZWlHcjVhMnBheXZ5QnAwQVlIbnZvNHFMRis0VTM4aVltN3ppMGlVQnFNaE5wRGxuWXRQK0hKaTJLditpWi9xcHROc1ZhUmxGCkpXblJTNmFXQVVEMDYxUEtpNWI2VDV5ZU5QcGNYVzRpelRrWG0vbzZtOUVTTnQ4ZklMU0tPeTdLZTZ2dkF1dnBpYVBQTmVTbHB0NHIKN2I3aTZvM1V2TnlVN1B5ODlBUGJCZzFOdjFPU2VibWtJR05WNXBnUUVJSjgrbnpVNjYwUGQ3c01IYmhoaytLbmpGdlZiNzMzNmIxegpBUHpDUXQ3MjY3N2ljbmJPVXYrSk9VVjUyWVc1Ykw3cGt3REE3SDdZRyswZkdyTGNIMEJWZnVxZG9welUzT0pyVjVTcGlUOVB5UzY4CkV4MDlwZXgyMGMyMDNPSnJWM3hDZzkvMlNiMWNXSndXdERON1dkOEZOcHJqUmZDWFRYK2R0M094R1VCSVRjcWNuSnBWRWU3M2Jzd2EKRnJ6YUtUVDBiZjhscjg2c0k1c1lBaEN4NmNCY0RGbTI1MjRCNXBuMm9jVkxwcFJkejg5a2l4N01OMWx3VlgwT3J1YWV5aXk0azVyVAphTXdUYjl3QWd4aE9hcTAxU0VoSllyeEZhS0ZXVXRVMUswV2JWL0dQUkFLMUtwWHFqYWkyWGwyT1JNOVljMHU5TnYwbmthQTFtYW1hCjJ3Um1Lb2tFYWhZZUtBMzNLVVpnTkgrMWtGTFF1TTNxbTdXdGFxMFF3MG5VU0VTdE5VUlVLNGpCTUUzU1RqRy9LQ24xZ2pWbHUzUjcKMW8vcXFIZVFGRjJsYmFtdUk3UXQwUVNITk1lckMwSWxSbGVxcTZraUloSnptd3F0OTdYeHVtb1ZFZFVJalNTVTdTTFJ3eWNRUGFnUQpxSkYwbldkMGpEM2kzL0Z5N1NpalpneVNHTkw2c25aYkVkTWZnK3lpczRzNkhHYnR3UHRHYlhiWXFTVkkzY0tPYWlNR1RQZjQwa1NUCitRNGRHSmwySGRwaFlyQy85bU94SGV3UXdLNUQvNVIxelJjeTNlTkxFOTFmajl0Sjh0L21WZ0x3S3pybFZ4clJIbkUzRHpNK2RrU2wKODBNcnBod1lodEc2NnRpakhQSzA3VXJMaVZVNmQ4R0dhVFQxL1ZlSzdLRjBQUk9pSkYyb0RRUCtKNnhtdnhESmVraWd0b09jdEkvNwpldFU1ajNQYUcwRDNxNmh0OUthejhnK3hvYlhyWTgwWGlEclp3SEJwRjc5dG1xaVdtRHIySWUxODJGRnIvdEhHekpoMmhiWXRaSGhICk42eVZHUTcrR3h5L2ZtQkJOL1VYZGFFZnBNTElJbXVKM2dJQ1RkSjBnRjRBeURCNlErM3RnVzE4WjJSZ2pXc0hJWDJBOWpVaE1SK24KUnFGa0lPaVd4VnZWYzN1QUFEUzlmRkMzTm5ra2dIdURpdlRPbEs2Um10RE4ycVdreWZlcDlsM3BaK2xFVVdRRDFORk96VDYxN1FMQQphS3RtRGplUWVuU1FHSFNSSWIzLzY2VFlybU0wMzlhMVMvSEh1N3FBSi92RHZTL2UxZ2lTUWFPMWN5T01jclkxR0Zka1d5eDhBUVoyCkdPcGUxRG9sR2ZTKzRJQm9VQk5QbGM1TkNNTkFZcnR3dDI1ekVFUGZCb0NJVUhsQWs0OVRlOW5Zb2xQTVpncy9yY0lZQWRhZTJsTkoKTkxBZUlGZEg5VW1udHEwVVAwWW8yZitib202SkptcE4yZ2FqcHpVQWlyeXYyNFlaTnZTVnFXS2pvTGJFNlQvNHcvREF4QlNqYlM5dwptdWt1QWFDM0VwdmRBR0lRczVGdWR1dmRxdDZXc0ZtanRjRzFSajN0Um8xZHJqd1FVSzQ4V3RyNyt1YWhkeTdzSFFhVWYyVzJ4dDNsClFrYmlVeWN5amw3dVk1SjU5SUhaZXNXZVlRRE83QXJibWhQNW5kenNmRUtRR2JHVEdmRVpmUktUNHh3cXorWUZaTzhzMzlIYnFqWSsKUGNBMDdmekZKMnQvU2dneUF5NWtKRDRGb09uRVNRZW5ReGQ3MkNKMjhsZDlVNDZIemFzTStGSGhsWFUyMzc5cXZkbHErNTZnTTR2OQpRcExQQzY0QVZoNFVtNlJNUGV4aUQ0WVRsNU43aHlUOXBITEwyRGRnUjBWQWpQMkJDTXZkRSt3emp6N3dZQXkzTCt3ZDhNK3FqUThDCmxTbEhYRXBqaFRWOXJhOGZ1OW84Y3JzbUlXbG00aDAvT1dYdkxOOFJYaGhUZHQwdFBqM0FkRnZBaGw3ZDdxVk1ydmtwTWVoY3dyV2QKZlZmZTdBZVVmdFUzOVhqZjIrZjNEZnkreVdxdDJXcjducFVYazI3YjJRTnhLWVdCUVBsNnM3VnVMclhuRW9MTXJoMTlZTEZPc1djWQpzT3BBUU05REYzdllBblJqVjltT2NPdkNwR3RoeXBRakxxVXhaVmxod1BWam1ZcSthOE1zVC81VStjTkIvMXZKY2NJL1E2dXowbTlHClh2bGg0STZLb3NVK0labng5ejNydDJ0RHc4YkJxRmV5Q2I1UkxQK2RUK0MzamEwYkdnREFjWC81Nk9uWTlIemN6Y1ovVElyYmV6bDcKNUR5N1JNVW9BQmk0eTY3N0Rib2YvazFJU1F3WUdyNmRHTGZYYlBOVStkcHB4Vy8zV09PT2Q5bWlpZjFHNE9zcE52ZzZwQ1NHZ0kzUAp4OTBDc05OaFhOM0hYbk5IVmdOdUNZMlIzMW1NN085WGNLZHE3YlRpdDUxT1hYdmxYWUFOZDVtU2xEbjdzM2dBRTMyamtQL09KOWppCjVMZVlnS3lUMHgyUmxEbm44Nk45TnNQaE5OWDJaaXNBWkdTUG5LY0NzQzRxUUg0MWNkNXJ4WnNkL2FLOU44bEROcXBXekF1QVdkNGQKNzAzeWtFM0NHNk4rcmpRRGMxbmpnZmQ4TmdXRnZEYWgzd2lBbnBsQ3hQQk5hSEdNK2Zibm05ZStIVk1MdUNjMFJIeUx0VU1ENUxsMwpIQk15WDNrWHl3T2REM2NIU3MvTVdnN0FZWC81cU9uNE9yUWtKdVA2eUhrMmlZclJBTWI3Um4zc05mZnBhb0M1ZnVuQjNsTisxMzlyCittWkgzOFUrbTRKQ0FkWHllZjV3T3RWd0syVnUzWGp2S05QTlUveE9OcW55WngzWjNXY0xIRTRQZDVtYWNlUHBlYTBMcHcvNkhUK1QKa1FBS01lOVdiMkdKVWYyYkFjaHRvc2FhRmI2M3QwWGhGQkM4NE5SK1ZlMWVaaHN4RUFETXhoOVR4bGU2SzVMTEowOEY0QndZdE9DVQpvMi9vRFd1TTMrOXMxMi9KNmNvY3MrREtZcytCWHMxbktxWk1ZOEQ3ZTF1YUFCcStLRGJpQngvNWtLTWcwVUlHbURpd0pHdU0yeSt6Ckh4VldCUUJFKzNwaS9INkk5OU1RODI3MWg1dGNWekpnOTFCNFluOVBqRDBBR1V3WkhNT1dYZ0J3VUZXN3QyYmUvQ09qQmpTYjJQV04KZUM3aHNNTGxVd3VucU9DYVpIOTRhbWNGcE52M25RTmxnSk45M3lXbkxaeDd1MldiQjFjVW8vK1liaVVNaWpNVlU2WTV1enFFZUZoNQoxWUJnd3VRTW93YzB5eHlaekc1MGVCWHFpNXg3V1JEY0o4YXBBSmpaUkkwenpUbGJNWG5hUWFGdUw3T05DSmsvTDQ2SWZ2Q1dSeDFkCk1XKzFrMzNmNk5ObjZpdis3bjFZNGJMU29sdEVPSkFjUUo2UTJ6S3Zzek1HQStUb0Y5YlREckpBdnlXSmtFSE9RRGlvcXQxYm4rZmcKWWR3Zm9zWjlKdE1salFnNnNURVZZRkN4QUtmRi85TlRJQlhNaHZoa1J0cHFjMysvdk5Gc3pKL0hXSlo0UnRZQklCWE1vc0RFdUNjSgpNQjNxV05ZTTUrNXoxczJSbDdwSDFKSjZMajlpd3NXcTlhTFBqY0c4V2FVQ0JEQkJqSmRxVTJDdzREUlk5UUlBUVl4OU9wZEhLZ213ClNRTlVRZWxhK3huUStBd1l2RE1qYmN4WHJSd1JkSEpqS2dTWUQzRXVqMVF5QmdicmRFQUZKazUzWlBMT3YwYU9BZ0FWVEllQ01ZZUsKWm5UckRzRExVejAzSXFCOWhkQzBXVkFoNk9UR1ZNMHoyT3VweW5mQThOT1I1eXhJckNRd29OZ2pzdFk3TThLNkZiQlp1V280RXhDVQpEbXV2TjFlOUNCVk1oL1pLRFEydWNDNS9RajFydHJveFZIWnc3QUx4d0NBREVhb25pa2REOEw0V2FZTmNoV2JHeDkranlEelRqMSs1ClVuQTMvVVpoM3FmWG5nMEJnRjNIbnJPNCswRlZDa3RKeXB3MjljTEFvODM1cHcrT0JBR0I1aE5mY1ROamIvVmRZQTBDVXBJenA2Wm0KbFlmN3ZCZTdCcVZ4ZXhhWnZEdHY1Mkt6UlEvbW03N1o3eFViQnZPN0gxUmRCTU9QMndZTlhmYlJicGRoMllWM0JpL2RlN2NnY0dkMgo1cFZRbi9kaTExU3FKd2FFN2FhWjUyTFRYZ2ZnbVg0czgwcEJhWHIwNjFQS0dHaHU4b3JVU3pQT3hhYjltVHlYWGN4cXRQMWhYM1JWCi9xV3BGd2JGMjNsNDJIeDY3ZGtReENWMTg0dCtmVXJaOWNMYjZkbGhidjl2WDNaNTVwV2ZDKzZrWlRkdTJMbHBPd0NVeHUxZWRGM3QKVkRPUGlEMHdGeG0zYXQ3cSs0cU5hSjdMVHdNd1pPbWV1d1dmWmo3cmwzbTUvTmFsOUh2RjI4UmNwSFluMWdoWDFWMGplN1BQS3paVApMd3c2MXB4L1d1YmhZZU9aZm5yWlI3dGRodlh3NkliU3VEMkwvTlRUTkpabkZXUUNiSURiSy91eTd4U2tGNzNsUDlFei9WUmFWbGxsClhwcnI5YU41aytDNTdGSldnKzJtS1JjR3hUdS9OWFZkUmE1UlZXYlVJTllEYmZSTW5HdFFHRjdTUk5TcVZGTGlraW9TU0dnU2lBVGwKSmlJU3MxeVNKb2RsMHBJcWRkaXRTbENuNjZUR1pxSUhGV0lSZ2FoVnFTSkI3WWxUKzl5RUdxRkJIZDhVcXZUQ2RrcUJxRUpzaVNiNApxV29XUTR1MTlTUlFKUkVwNnhSS0VrVExHUWxpV2s1bGhVRHY3NjBsUFZjZDFTbzAyVGJGaEtRQ2tTQzJqOVJCUjgwZkNxMTNqZ1FpCnFoRWFTRm11WGtlQ2NtMUx5YTdMcEo2U2tXaDRTWk42RzZGSjIvUldvbFl4SjZtNkQ1b00ya0sxemExRTFQcWdWdXZHSTFMV0VwR3EKVGlFNkE1dUlxRUZWYjlRWXBuR25JalNGNW9abDBnM0VjTCs2eGwzMGpkMHR0NGZvSFFNcm13QUFzQUFzaVVFMEJaV1UyNm5qbGs3QQozVnB6R1FBckJzaTdBYkFrTUVBdWpqR1kyRUk3RFI5emdBMGdCekV3SjlLNU0weEFySnZZRWswSHlDeEVoNHM5d09BTVlpWjJBSml6CmV2UktuRW5RcEJ1RXN1NzJBR1JtbXFpTnZlN3dDamRuQmd4andEMnhmVkRQZitpb1hxMnhOekZ4bU1JQk5qRFI1cEprOVVmeXdweWYKQUdBR0V3RDNhNnJkMVVmUGRMbEo1ZHBEMC9RQkFKazVOSU52OXVwUzlyb0RFNmRRbE5rUkl4bUlXWUdZRFF6Q1dwSmo3Snl4aG5IbAppbXBUWHdBZzVEQjNXMktHc1dLOVFEamRKRTlyYlN3dS83NkRpNjVLNkgvVXhsdjB3eTRkUm9EYVoydlZwVURVdG9RMDQxYzYyMXdSCkJjZzczaEpBcVRzQTVMYzRkVGNZekRKd0dVRjdISnFBdURxZlZZV3ppYTY1bFZXbVBoMEh5c1VLOHU4Nzl1ajRTRFNWRzhaR0RONEgKTUhMMlJTUEhMdHNlbTU0TWRPOHJ0SFYraVgvcGVSNDdEdG85SkJEWTNyVFpxUmRPYi9YRFl0WHRUaURwamFLcU00ckJzQ1lEQzJmYgpTanEwc1dtK01XMzNwbCtkNFZwRFBYZlVCLy8yS1h3RWpPdTdiTnVyblprWURYdXFmU3k0WFcwUFg5UCtvdFZtL2NOZlJPNHNEdDJaCng5aWdMREZBa0xVNUd1MXEzUmRHYzgzVUs5Titpelk5OGJCWEFqbzlwc2VnTStQNkxpRk9HcWorM0VFd1RwT3owcUEzMUs5bEdSUUUKMm5laW9UK3hYWEpNYXIraEpzTEhBT0FQZDl2VXA0azNNb1A2R1hCeTM4UVc5Zkk4MFRKYU52UzJMaDRHQXBWRnFTY1BGRWRJb0FscQpwZmZYYXphYnlMUzFiM2xOZTVRQUE4NE4xNmFMMWFUcGJQbjJqZSsxTVZaMU1XcmJOazBITTMyOUFUajl6dWZ6dnY1alVoK2p2ZGh2CmNHYU1oVUFreEhaeGFkc3liWDhMeFFpYWpSOUN4ZjZ1TkN0R3JPWjRYdHRtRVYxNnVaTTlUS1FTemNjL2xOWTJrQkJMejkxcVU2YmQKQW5XOW9aMjA0OUxMZXNjakNLU0thRmZrbnp1VnBVUXhEK3NwZzY0MGFQeHBWVzRrM2NvTnBjZUE4V0tYREZoMUlDRDdYSmllOFRINAovc21URHBzUEJDQWhMangvZzhrWGdhSXJNZjFKRStEMmhiM0RWS0p6OEZ5Y2VjL3ZIYTFURHJuY2pTbkxDa055dEc5SThubWxLd05hCkUxT3V0WFpQT2VSU0dpdXM2V05UZSs2MDc1NjhyWU5QWFNyMG1sY1JhSEx1ZExBWm9EcC8zTTQ1NjJ5Ky84ME5KcXZWKzhoNDR1b1AKQTdlWEZ5L3g4VGw4MnJwbGhxUHp4bENyNUF0S3R4dXh0S2FQemRGTGhZSDNVcDludUw2emZIdDRZVXhabGx0OGVxQ2NEbDEwc1QzMApuY3RnZ0E1ZGNMVzl0TkV1MEJHcjlnZWtCS3gzOGxDbWlOYlB6TVJ5bjMwQjY1M00xeW4yREQxMDBjVjhlOW4yNGtna24xZTZJWFloCkhiN2dZdHVhbUhxdHRTWjJtT3I4TVR2bm81ZUtBdStsUGcrR3JMUDUvdG14WlZrOS81bDM5bFZseWlHWDFPUTRCeGNnNjJ5K2Y4SFgKdFY1K1NGcmlVNUljNTVDbjhhTTJuanpwb0RkOW9uL091U2VxNDlNRGE5ZVlyM2IwdkgxaHI4YlM0c05xOXJ6cTVCQWJ1cmFQZFVGUwpadGp2ODBwR1JGZGVwSk12Q1N2ZmFPbDNyTFFQZlZUOHdlcVlzM2RTcjc1SWI1Wi9IdHZTODg2K3NUV3YvbmhnN0kyeE80bG9jZTBlCjJwQjlmRkt6eDVWcmY5NUxtMmxqOXJGSnpSNVhyaEZSSkNXdW8xbEhpV2piOXVxZzJnM1p4eWNwUE05dS9KRCtWdkxCNTM5NzgxTEIKY2xVd3Jma0gvYTNrZzlWRXREbzdlMFhsSzdScGVZdlhuWDFqYXhiK3VIL3NqYkU3S1p3Ty9ZVWlhZCsvVW1mVDVEemw4UHpFZFRUcgpxTUx6N01ZUFM1ZXJnb1cwbDBpZ3FsNXA3LzZ4MmVQS3RWa3QyZjNwbzR6V3dFcUtKQ0w2NlBLRHdFb2FYU0VRWFhtUnBoM01mWVkyCjNEZzJpWWpTTnltbjBkU0R1YzhvbnpsdzRhT00xc0NLRDErOUc2Qk1YRWV6NGltQ1BzcG9EYXphdHIwcXFFWVJRS3V6czFlVUxGY0YKVS9yTEpGRGxBdHEwdk5uanlyVTVOY1c5YVVQMnNVbkpnMzYrUzFTNWdEYXRvSS8zRWhGRlV0S2duKy9PbzRrM0U2SnV6a3lPT1hzbgpkZSsvVW1iVG40UmRlNjY4U0tkZW9wbjNzL3NyUjIyKzlqUXRydDJqNi8zY0NDSUt2UDJQVDFvL0xCbVRic3p6YnV5WEZwM0FIQUxOCmZYeGRsWXB6bFpPbkRsOFVHMEhBQjRuRkNuTm4zMUFuKzZBYXg4RGdQNXdFTUdwQUN3NHJYRlphZEk4TVh4eGI2a09IRkc2ckxMcEgKaGdFRTdQZkN1UDBnMUJkYTliSS9ySEJaYWVrVUZWemRmS1ppOHYvWWhmYnZPZW1JQ2d5S3M1VlRwZ0k0NUIrMEtza1c0L1pyWEk2TwpnY0VMVG1wU1NrMVJYVzBDWUdMTDludlJ1UDJXVGxGQjFhNFRqd2ppRzJOaUhMSmJwRnUyZVdCbDhSNGZlVlM4ZUNSN3ZFMmo0clhQClBrSjRyd29jYm5aYkNXQlhoTWsrVUxoWHBZbHR4SUE5UHZLb1l3NzlYZDBiRDNqUnVIMGc3UEdXUjhVM0ZOcjBjckMweENIL29GWHUKazQ0STRtdG9TZFlZdDkraVc2UjNyb01IdytFbXQ1V09mcUd1UUpJTnh1L1R2TGhJVG41aHJsby82ckJGc1pIVFZKbE5kY1ZzNWdzQQpIRkNWYlJaWWVkZDJWSGcxUmcxbzBidWNNQUNXZmw0VloyckwvOTdMbUNmZGFDSWpnS0RTUGN3eXl5S1B5RHE2V0xVT0FtWTgyMGNRClUzOHpnaEttUXdFRW5keVE2bHdlb1lRQStKbHRITW1jeXlNZWFFYXhvSWxPem1vNCs3MlluMU5HTWxnVXUwZldNdUQ4NGVjc0FNR3EKeUQyaURvQnJJcktDVW1IZEM0QUFNSktwWURZVUtuR1N2OC9rendpQUNpWVVsTWFzdmNCSVR1ZVBQR2VoL3VFaGlNMXhLRzltenQxRAowc2phU3p6YndlbXc5bEwvZGhEQUlBTTVsMGNvQ2ZDTHcrMzdNcGdJNmlDcHRSZGprQWtCYWN6S0MwemNjR2JqbWU5QkJOY2taUDBrCjdvd3hCS2JDMmdzRTA5d21DSEN1N04wcXZqVVhsQUpyTC9VTGRjVEEwS1QxbytKaTFkcS95MGNMZHJkcWtBVVZaSENvYUdITzNSbUIKRUhoeVE0cjJES2pUdGNpb1YwYVlPc0dua1REYWlEOERtT2ZsVTdtNWxWZFlVWDVLYTNIZXNyNmozdG5yTUNqVU0rTms5N2N0bTY0VQo1cVRrRmwrejdwV1dsTGtJd01xWlkwS2o1NFV1eWlySWpNRGk2d3pSODBNV1poVmtSb0RCZHRQTTZiSDVid000a3B6cnVqeDZmc2lpCkczbTVxVGxOUy91TmZpdFROY2Z1aEN1dUJxNGV2S3p2NkhjQXZQNWluOWNIK2I1bjllV2R3cHkwM09KcjF0NnBTWm12d1hPWitZMEcKMnhqbkRXUHZGUWV2K1hOZTJxeHBzZmx2MzhqUHZYUlRmc0pWeUV5L1ZlMEVsTVFWTDhyS3o0ejQ2N3lwMGVaTGwxYTZERXUrazk0WApXTGFzb3Nld2dqdEg1cGpDTTMxZlhtcnQzZExGTDRhK3lvRHBrMGZQbVpTYlduc3ZNeS9SYjluU3loNkROenM5WFp3K1oycHMvdHM1CmhibkxsbGE0RE4yV2RNZDFSWDFSN3V2eiswWGJIM2NWTXROdVZUdWh0OTk3Vm11eUNqSWpsazRmVTNFbmVsN1lxMFZaWlM1QW1OOTcKVm12cU1rcEhPd0sybTB4L0xuTzYrMUhGUmRtZDRodktiSWRCb1Q5dkdIdTM1STIrVDMrR2pGTzV0eHIrT21kYWRNT3R0T3J5b2xVegpudzFkc0NRQ0lBYlZvYUlyVDJRWDMweTc2Um9hT3ZGelk0ck0rTEZMSFFxQmxQVXRSSzNpN0lOcUVxTXJpUVIxZEZQanBSUmFTR01qCjFNeXdKMFlWTjlTWFhmNkhXRXdnZ1VpZDdyS0ZsRG9ESTFIcmZSSzlpdW9mWEFsTDFNa3hsYVFrYWxZWDFsWksycW44aUNpaVdoMXIKYkx4UCtzay9SUmVtb0xGR0VwR3V1Vm9QSmFsRGg2UmZlMnN0MFRmMTVaZS9KU0pCZVYrWFpwU0lLdFU3cTFmVkU2a1VncWJKVmJyNgp4RG8wZmxSbGZUTlJpNkFVajdXVkJCS0V4aFpOdXlvRW9WRXYzNmdtYnFvdzZsazN1dSt5RTUrVzNyampya003VExyb3FBU3hlWmE5CmV6enIyRkZwd3p4NUJpRW5yZk94cytGUFBYVFRHcllkdm1zYjdYbTQ4NmpOaXZrV3ZidVBkWGhJZWIzcWZxRUFPaDE1N1dSTVY1Y2cKd2tqOE4xamlES01tT2ZDdzZYSVBFS3VYV1hla2o0ZkprMkRvZkh4bytLaWcyWEJhdzE5cWYxZUwxTXRzSHI1ZG0yL0lMMFJISGxMSAo0emZPUFRhUkVYdUVidnVQOU5Bdlh4Ny9ZM1YzMlFyYTZYSThwSSs2SmxLSmp2VFhZT1FaU2JSVFNPbm4yOVN6RzI0OWFMaTQ0MW82CjRON2dRbTFGMUZuNWx1aXRhQnNsYXYrSGVuM3hreldkMUhOdmNLRkJNazVRamw2d1RIOFZJOTFCYXhhUXJzSDZnYStPanVybWhoMHgKZjZ2OWFPSFhYN2JlbVB0Vk00Nzl1VnpmcDJsd3Y5U1BwTkc5b2JmMWcyZHQrNy9Oa1VxTzhVUkd1aHlub210c3M3WmptTGJYWHBtaQpwNUwyYW12Ny9kWDFtcXNqSUtZOUZtTjliVVZESUlLRnI4N1BabkNOaU5VM1NxcUxlTnEyV2FLT0ZCSmNIY1ZrbkpxVm0xbVFYa3BSCi9UeWR1c1N1b2llTk5tdU5mSzRPaGllWkdZZ0JBSkQ3MnZ4NWY4cDJjRE5kblBPL0ljV1JsaGpUb3dkcFc5RStLNncyU0x2RjFWbFAKVDdybmJ2WllBcGRHSE1JQUF4cVNDcDQ5My9qSHN2aFp5UVhQN0Q4V01pamx5dmlXSDU3ZUczMG01Mk5UQUhpd0l6QXFQYi9oWlFCQQpRMUxoTTM2cGw4ZDdGVitwbnJaamlPMjI1WHZzejMxWWRibjFmOFFLajlZNFRMaWRjL2xkc1NNWklia2s1TW1USmNyQzkwM08xNVc1CmpnV0lvZUR5blQvWUhiL24vZ3dZQUxuaWY0Tm0wK0hxY2M0NzNDLzR6bTlOejVqb2RmeWV1OW1IM2FZQ1FIWE1xTjJ6bnFwSlVreTMKb08xV3RWQ21YaG5mNi9nOXQyY0JBTXFMTjU3Mno4cTJHc3NZWUNLdWJMaDRhOTdYeDBJVXBXTTJQek5vMndpNzlQeFoxbkxGQnUvcAp5VXB4ZHFpR1M3Zm0ycDRwRG5ueVZMRXEvOE5WeC8wTDdNNS9VSGpEY2h4VGY3MWJkem1uZHgremZ2THdtaVRGOU1iWXZta3IwdEluCmlkbGkxNDZ4QVZzRlU4QTNCK2FteEppbDZOTTlYbDlnOFVlekd6Y3N4NSs1OE1wdSszbi9lTW9qSTNmMmhhTGl5YjBCWUZWOGlLemcKbTluOUN6TnUvNm40d0pDRDc0Z1BsWVVadC85VWRIREl3WGR5RWwrMStXNitFZDliTk9ydGNwZlRoSVlSdTgycS9IWTVqRytZNEJNVgo2K1M3eEh1eis3QWxVeHVPQWdEaytibjRlcG9WcVV1UGE0aDE4bHVpL0d4U1prWGxkZTkveVlyUHpUVDV2di9XeXdRQWQ1Tm52b1YxClVZRnE2N1ZNbG5SMTl1ZnhwbHVINS95VXUyM3Nlay94V3JWK0NPMjVsVHEzUWYzRkwvanJKL2pFYS82d3V1S0RmL3BZdGNYUlAvcG0KMnR6NjRkMm5BQUFjVGw5N1pRVjdiZnhUdzdESmFWb0xOanY3TGJtWk5sZWR5dXVyN3NOaXE5ZE1LM2diTW9CaGk3UGZFbG8yMnZubwpPSjhvV2JKYlRRbGFlMjBJTGQ0RVp1V1dRamY3aVh0Y1Bzb3hQdW5LN0MvaVRiWU92M1Z1Z3MvdzR2TXZOSDQ1cldpRjVxSWlMMDFZCnZ2WFdpcVZzMFlTbmhqc2tOWTNhN0Jpd1dGeDFMaFJBVDZEZ3UrdEx3WFN2VlpEaTI0bHgrNnUvbkZhMFlzQk94eDdYY1QvOG01RFMKR0xQTlU3dURBSnJnR3lWci9QTzdXRGNZdTd3M3lVTml4YzNXRDJhN2ZEZkpRellOUG1obXByTFZYaEYvWnlJYnZqQ210M2ZBbWFTUgp3eGZGaEJOd1dPSDJpYm16YjRpOVEyQzEyQm9IUXMrbnZNWHVIUDVxYlBqaEpwZFBUcnBqdFk4SllBcjcwSDduYXl2KzNwTUJnTnZFCm80VFJBNXNaQUFZSWRNQUw0L1k3Ky9pSFZqY1ZzRjQ5eFYxK2tGRFMxUFBzekVIcVcwbXdlYmU2SDN4a1E0L1pEWFJ6YXpqYzdQcXAKMTVrWmc3WHZoRHVNQ3ErcHVtRVJWRjI4YXlqenhKRW0xMCs4enM0WUpGYjFvMy9RWjRrMm1MQmZQREdIbTF3L2FTaGlNMll3Z2hPdwpPTGJZUjVGVU1XVTZDRE1UNmh2Rk9VenFDdG5NRnc1NFlld0JaeC8vNEdwQVpoL2MvNXdOSmh6UVBJWXkrMEFMWHgrM0IxWFo1a0ZWCjkyeWVHSGhZMFdPVnVBZjFzRHp6ZW1sYktDeVZoRlpUY1JPSHdPQUZKeE50TUg2LytmajRCOGZMUFJUSmxaT25PZnFGdW1weXp3dmgKWGhYNElMRllZZWtjRlZ3bFZ2ZCtZcEhDM0RrcXVFYis1bGVIcHFCTkx1M2ZoOGdJSkZ5c1dvZS8vSzhORXk1V3JZY0E1L0lJbGZxVgpVdlhCTXNMc3IyYUxoaTNoVXRWWHpoV1JLdC9qcXFZQzAyWUlCTEJlYWFIQmxRUUFQeDJaWklIQUV4dFR4Yk1sWTRGcHNQSWl4b0R3CndVYytzUmY3YitiWVNDbzdNRVl6S3hxRERFRnB6TnFMRWNuZ1ZCYWhMRHN3ZG9IQkx4S0hTZ1VjdTF1bkF5cW44Z2hsMmY2eDZvM2QKRWlrcktBMVdYdUx6bTFONWhNcjZkZzJ5QUpLQi9NeGlSbG1XZWtUV2dwSEp3dG5EeFcxc2I5Y2dLekFOMWoxSkJnWUlnQXpCcWJEMAowZ1E5MVU5TXpLR3lHWTdkR01HNS9JbFc4U2x1OGo0Q2NsckZoOUNlZVF5M3ZOVlB0Z0xNb3NUQTJzc2J6Wjk5WTR6bFhmZklXdDFNCjBRVEdaQ1JPY3dkdGVIWEcyQ2ZWejdPemY3elpzLzNQQU9rdzVqTVorOUZoVUNnRmVrekJqdzZEUWozVFQwWFBEMWw0dXlnbkpiZmsKbXRWOEdZQUhtZmJDb3Zmbml3T2xCeDBIaFE2Ykg3THdXYisrWTFjTmZMTlprWENWNXZpSGhVNzhuQUdBM1FsWDRjcnFtYytHZ0FGVQpuWDloMXZUWS9MZDMzU202M2hxMko5Tit3U0JpQUxvdHQyNElXelZEbkJXdDlhcEZRV242MHVXVkxvTzJPQmFXcEM2Wkg3S3dZZFdNCmliRGQ5Q2NBcUx5VlVuM3Y3anZ6cDBhYnYvWGV4YktmbHN3TFdkaTRhc1lFY1NoM3lVdDlYaC9rODU3bG1xcjhTNHJDM09qNUlRc2oKMytnMzRqT2tuYzY5WGVld09BdnNyYjZqMzhrdXlQV2JmMGlkMDF6MlJyOFJuODJhRnB2LzlxN2JoZGRiaDZiSFg2WFo0Yjd2V2EycAp5ci9Va3dGTWVZVVY1NmUwbGhUOGRkN1U2SWI4MDM3UjgwTVdpdjMxd3MvengxaUVLaEp2RlhzQzc3N0toQkxOVGZaU1V1WnJEajd2CldhMUJvUG5FSnphWjRjMitvOTlKL3JsTWZPdmZNM1YvWGtyTnZaTHV5NjBiVWd0dXA5OW90QUdBN3N1dEcxTUxicWRuTjlxOEZDQ2UKRUdPTllSZ3p2S0NzYnlZUzFxc1RaaW8xWVJqRE53TWZWR3BMdDZoTEtJaW9WcWdURTJzMmFVSWtMYVJTTytzMGFMWThtbFdkdlZiOQoyVERSSmhIcGg0WlVMZFI2djFadjlqb2lVdnZZV2hUMVJDcUYvcFJxRCs2VDZNaFRiOXlzYmsyckpodXBOb3lsemVjcEZoQXFORzBXCjQwOUNGWFdBWnVJNFRXeUtpSlJsZXV1cnRjRWc5ZVJ3VlFMcGpJTzZjb0kyeXRWc2VHQzY2TlhYS2pJbVJoK00vVGh6blZ1bks3dWEKYzdDekxIVHFCV3ZQUGVYZE83Uk5KWjNZUy80RFk3UHRTaGdtMDlRdmlTN3Q4cGZRUmNYRTJqcnlOTFFQZ21uL1ByWis2Y2gvcndHLwpFcU9Mck1IVVFwMUE3aGZpSVowUG52K3l3VVJaMDczTk5oMVc5REQrbldTWWxVNk1QYVRrTHliai9JVWl3azFOVk96aGplenNXOWphCjZHRGM4VExqaDVVNnkwT3ByNnVPWFRjUHoyRFo1bk5IR20zcjBRUURJSFF4MTI5biszM1lYbi9GeG0wcTZMQXVuUkhWOEpLUGg5WDQKeTd1Vm5NZml1eFJrR2o5cngzM1FVV1N1Zy91ZVRpaHR2WlI2TWVWMlZyTXVkN2FtY0NjYWJMZTQ4eFA2Q3k2NkxxMXNYKzZSVldOMAp1Um41OVd2eHQ3bE1NL01mb3paclJFZFgyOGljNFo4R1lhVTkzeXpSTHRLdVlGVHg5RTMxQXFZM0drUU1BR3Q2OGFCMjgwN1FKREFVCk4rajRtOWhPZWt3M0VOS1Z0bmZjT1hwdDZEaWhLWUdZWG5Za2d4Yi9pcE5nVkl3b011b2dKTmttTUt5ZVdMRExPWUpaYWVKcks4UVIKbjhxRHFOUWtYeVhXM2FtalNzVHJuYlczd2Q5dFc2bi9lTTdhRnRSM2lMYVRIbXNyOXZaYmRmM2dETDRkZXMxZ1lKcFV1MjFDbngwZQp5MzhGUmt5NHdvRE1MSmVSMVVtS2FaYlZTWXJwOWQrTzJQdFM3N3Ewdk5rWEMwcWZVOXk3dTNEVnNSREYzVms3M2M3N3oydE5yaEtDCitoQzdmaS9QTGlBdVNQWENvWm94dGp1RzJHNWI5b05YL1BDSkFMS3lMY2NyWXZNU1JnSHgxUTZqWDNFUFcrWWVYbDFXdWhDWldTNGoKNVVqUG1DNUx5NXQ5b2Fqa3VRaWNLaEx5UDVRbGw0UThpUk1OV1UvZ1ducklnTlNpbWxjNmJDWFRma0xibXlEcm9Od3ZRWWEvQW43VgpkYVNqTzF2WDczYVA3eW5NRUtQZUxqTXV2TEFScjAzb053S3ZUWGhxdU1PK3lsSFQ4VlZvYVl6cGxza3VHeWJIM1JydkV5VkxraGNlClhQZzM1YTU3ejN6a0J5YThNZkxueW9DTkFXRWZlODBkOGFEcXV2Y2hsbmxxM21zbFFOWGFhVVVycko0SkhBWGNUWjY5MUdMa2dNQ1IKQXdJM1BCOTNTNXhmc1BITUhLZXZRMHRqekRaUDZRSEl2eDEyNjF6UzFkbWZ4MmVkbXU2RWpCdFB6MnY5Wm5KWFlzU3N3NCsvaG4vbgpWTE11THZ2dnhyZ0I4dDRtZTZ1eXpZTXFyOTB3RDZvcXR4a3kzaXpuYk1Ya2FZNis0Uzd2NzIxUlFMVE1EWEIxYTZvcnRQR3lCK2oyCkErZEFhK2ZJOEI5ODVGRnhEREExc2VzZjhkeHBJTW1heHU4WHEzV2JlRVJ6WTNoL1gwdlQ3dDZ5ZmNDU0lkWk5aeXNuVDNQd0MzTUYKbkh3RGdxdjNlMkhjL3QxUjhNU1BxdHE5S3M4Qlh2ODlkNVRmTlVhZFZOWC9LTzVZVmlpWXMxOWxNNXk2YXhOV0FtaGFOTDJuaWducQpCT1V5bXQxNFpoc0lKdThjSERtS1pFQmdPcXk5ekpxaFZLRVY1a09Bb0hSbUpiNFJnNStPUEdjQkNBQTFMWnJXazN6amNlYytlMjloCnBiWGFJS2M1MHFBMFdIdFpwd09xWHBrUk5xbzU2K2FxZm9PWGhkOGdKaDhZYjErczE2cGQ5djB0djFUMjYydTlXdG12NzNkQ3RjZVQKVm5PdWpUNGZOOFYyVFZtdTFjQlBnN0tTbnZ0SFhlZzNUNlR0dTNPMXR4MW9RZEcxUnJQUEo3aDR2Mk45Zjc3d3NlcW4wS0xMdHJVVApHWG9rWEw0VzNXMUg4clAycVA5Q2NYbXdSVXgvZWN6QTdXVzVWdE5YN3JiMytpYmMvNzJuM1dmL1BPcDgzR1FiMEkvSnovenovb0xWCkQ3S1dobng1NCtxREJWL0VXa2E5TU5UKzZWZThYUi8zR2ZnL2dKSEh5UlJXUUpQY0hLUXdOY09JblE1V1FMTUZBd0FsbUl3cE5iOUQKYU5PYyt5VlhYa0xSeGJIVk8vNGlBNkJzc2dmcTdCcnNQZ2g3VnN3bldPV2ttWWZ0Z1puS0JFbzVsUEpXR1V6RXZRREU2TDY1d2ZBdQoxVGd5WW5VbTFtQUtLeWhydTVIQytuR2ZnUDhMR0RXZEp6RXJZckFtZ0ZtREhsVFh1a09iNUZJT0FITE5MeWQyL25MdkhzOERoVnV1CitRK1RBZW9zbHZhd1U2ZlRCT0NzZlVmSUZDWmlwa3VZQWdDc05PTmJGcm85Z3hneEp4Q0RQUUN5QkV5NmdYR05HUVBqWGNuYWpiWlgKVkpuNTZxMXVNN3BaWnlMT3ppNG15TlE2SjlGVWhBQVRkUGJqM2pBSElReisvWlVEL3B6L0dJL0RFcWRXUXRkZWduaDRMWjB2N1RDVQowMVhUTU9jL3luK0R1WmZ6TytjeHozZkorYjhBRnhsSGNyaklPSkxEUmNhUkhDNHlqdVJ3a1hFa2g0dU1JemxjWkJ6SjRTTGpTQTRYCkdVZHl1TWc0a3NORnhwRWNMaktPNUhDUmNTU0hpNHdqT1Z4a0hNbmhJdU5JRGhjWlIzSzR5RGlTdzBYR2tSd3VNbzdrY0pGeEpJZUwKakNNNVhHUWN5ZUVpNDBnT0Z4bEhjcmpJT0pMRFJjYVJIQzR5anVSd2tYRWtoNHVNSXpsY1pCeko0U0xqU0E0WEdVZHl1TWc0a3NORgp4cEVjTGpLTzVIQ1JjU1NIaTR3ak9WeGtITW5oSXVOSURoY1pSM0s0eURpU3cwWEdrUnd1TW83a2NKRnhKSWVMakNNNVhHUWN5ZUVpCjQwZ09GeGxIY3JqSU9KTERSY2FSSEM0eWp1UndrWEVraDR1TUl6bGNaQnpKNFNMalNBNFhHVWR5dU1nNGtzTkZ4cEVjTGpLTzVIQ1IKY1NTSGk0d2pPVnhrand5QkhuY1RmaU13M2xHUERMSEgzWUxmQ1B4Szl1Z3dmaW5yR2x4a2p3b0I0SmV5THNGdmx4eko0VmV5UitUUQpYeDkzQzM0N2NKRTlJcjVwajdzRnZ4MjR5QjZSN28rN0FiOGh1TWdlRWY0dzIzVzR5QjRWL3N1eXkzQ1JQU0w4UXRaMXVNZ2VrZVNpCmdzZmRoTjhNL05IaUVTRit3K3d5WEdRY3llRzNTNDdrY0pFOU92d20wRVg0N1pJak9meEt4cEVjTGpLTzVIQ1JjU1NIaTR3ak9WeGsKSE1uaEl1TklEaGNaUjNLNHlEaVN3MFhHa1J3dU1vN2tjSkZ4SkllTGpDTTVYR1FjeWVFaTQwZ09GeGxIY3JqSU9KTERSY2FSSEM0eQpqdVJ3a1hFa2g0dU1JemxjWkJ6SjRTTGpTQTRYR1VkeXVNZzRrc05GeHBFY0xqS081SENSY1NTSGk0d2pPVnhrSE1uaEl1TklEaGNaClIzSzR5RGlTdzBYR2tSd3VNbzdrY0pGeEpJZUxqQ001WEdRY3llRWk0MGdPRnhsSGNyaklPSkxEUmNhUkhDNHlqdVJ3a1hFa2g0dU0KSXpsY1pCeko0U0xqU0E0WEdVZHl1TWc0a3NORnhwRWNMaktPNUhDUmNTU0hpNHdqT1Z4a0hNbmhJdU5JRGhjWlIzSzR5RGlTdzBYRwprUnd1TW83a2NKRnhKSWVMakNNNVhHUWN5ZUVpNDBnT0Z4bEhjcmpJT0pMRFJjYVJIQzR5anVSd2tYRWtoNHVNSXpsY1pCeko0U0xqClNBNFhHVWR5L2o5WnRIZW04Nkdta1FBQUFFUmxXRWxtVFUwQUtnQUFBQWdBQVlkcEFBUUFBQUFCQUFBQUdnQUFBQUFBQTZBQkFBTUEKQUFBQkFBRUFBS0FDQUFRQUFBQUJBQUFDWktBREFBUUFBQUFCQUFBREdBQUFBQUNRMmNxaUFBQUFKWFJGV0hSa1lYUmxPbU55WldGMApaUUF5TURJeUxUQTVMVEk0VkRBM09qRTVPakl4S3pBeU9qQXdWUk1MTndBQUFDVjBSVmgwWkdGMFpUcHRiMlJwWm5rQU1qQXlNaTB3Ck9TMHlPRlF3TnpveE9Ub3lNU3N3TWpvd01DUk9zNHNBQUFBUmRFVllkR1Y0YVdZNlEyOXNiM0pUY0dGalpRQXhENXNDU1FBQUFCSjAKUlZoMFpYaHBaanBGZUdsbVQyWm1jMlYwQURJMlV4dWlaUUFBQUJoMFJWaDBaWGhwWmpwUWFYaGxiRmhFYVcxbGJuTnBiMjRBTmpFeQp0R2dHaFFBQUFCaDBSVmgwWlhocFpqcFFhWGhsYkZsRWFXMWxibk5wYjI0QU56a3k0SHdIekFBQUFBQkpSVTVFcmtKZ2dnPT0iIC8+Cjwvc3ZnPgo='));

    }

}

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.7.6;

/**
 *   ____                  _                          _          ____        _
 *  / ___|_ __ _   _ _ __ | |_ ___  _ __  _   _ _ __ | | _____  |  _ \  __ _| |_ __ _
 * | |   | '__| | | | '_ \| __/ _ \| '_ \| | | | '_ \| |/ / __| | | | |/ _` | __/ _` |
 * | |___| |  | |_| | |_) | || (_) | |_) | |_| | | | |   <\__ \ | |_| | (_| | || (_| |
 *  \____|_|   \__, | .__/ \__\___/| .__/ \__,_|_| |_|_|\_\___/ |____/ \__,_|\__\__,_|
 *             |___/|_|            |_|
 *
 * On-chain Cryptopunk images and attributes, by Larva Labs.
 *
 * This contract holds the image and attribute data for the Cryptopunks on-chain.
 * The Cryptopunk images are available as raw RGBA pixels, or in SVG format.
 * The punk attributes are available as a comma-separated list.
 * Included in the attribute list is the head type (various color male and female heads,
 * plus the rare zombie, ape, and alien types).
 *
 * This contract was motivated by community members snowfro and 0xdeafbeef, including a proof-of-concept contract created by 0xdeafbeef.
 * Without their involvement, the project would not have come to fruition.
 */
contract CryptopunksData {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = '</svg>';

    bytes private palette;
    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    mapping(uint64 => uint32) private composites;
    mapping(uint8 => bytes) private punks;

    address payable internal deployer;
    bool private contractSealed = false;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setPalette(bytes memory _palette) external onlyDeployer unsealed {
        palette = _palette;
    }

    function addAsset(uint8 index, bytes memory encoding, string memory name) external onlyDeployer unsealed {
        assets[index] = encoding;
        assetNames[index] = name;
    }

    function addComposites(uint64 key1, uint32 value1, uint64 key2, uint32 value2, uint64 key3, uint32 value3, uint64 key4, uint32 value4) external onlyDeployer unsealed {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }

    function addPunks(uint8 index, bytes memory _punks) external onlyDeployer unsealed {
        punks[index] = _punks;
    }

    function sealContract() external onlyDeployer unsealed {
        contractSealed = true;
    }

    /**
     * The Cryptopunk image for the given index.
     * The image is represented in a row-major byte array where each set of 4 bytes is a pixel in RGBA format.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkImage(uint16 index) public view returns (bytes memory) {
        require(index >= 0 && index < 10000);
        bytes memory pixels = new bytes(2304);
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[uint8(index / 100)][(index % 100) * 8 + j]);
            if (asset > 0) {
                bytes storage a = assets[asset];
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3]) & 0xF),
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            uint p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(a[i * 3 + 1],
                                        pixels[p],
                                        pixels[p + 1],
                                        pixels[p + 2],
                                        pixels[p + 3]
                                    );
                                pixels[p] = c[0];
                                pixels[p+1] = c[1];
                                pixels[p+2] = c[2];
                                pixels[p+3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p+1] = 0;
                                pixels[p+2] = 0;
                                pixels[p+3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }

    /**
     * The Cryptopunk image for the given index, in SVG format.
     * In the SVG, each "pixel" is represented as a 1x1 rectangle.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkImageSvg(uint16 index) external view returns (string memory svg) {
        // bytes memory pixels = punkImage(index);
        svg = string(abi.encodePacked(SVG_HEADER));
        // bytes memory buffer = new bytes(8);
        // for (uint y = 0; y < 24; y++) {
        //     for (uint x = 0; x < 24; x++) {
        //         uint p = (y * 24 + x) * 4;
        //         if (uint8(pixels[p + 3]) > 0) {
        //             for (uint i = 0; i < 4; i++) {
        //                 uint8 value = uint8(pixels[p + i]);
        //                 buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
        //                 value >>= 4;
        //                 buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
        //             }
        //             svg = string(abi.encodePacked(svg,
        //                 '<rect x="', toString(x), '" y="', toString(y),'" width="1" height="1" shape-rendering="crispEdges" fill="#', string(buffer),'"/>'));
        //         }
        //     }
        // }
        svg = string(abi.encodePacked(svg,'<rect x="9" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="11" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="13" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="14" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="9" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="11" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="13" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="14" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="15" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="9" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="11" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="13" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="14" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="15" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="16" y="7" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="9" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="11" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="13" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="14" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="16" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="11" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="13" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="12" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="10" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="11" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="8" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#507c33ff"/><rect x="10" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#507c33ff"/><rect x="11" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#507c33ff"/><rect x="15" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#507c33ff"/><rect x="16" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="12" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="8" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="10" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#5d8b43ff"/><rect x="11" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="15" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#5d8b43ff"/><rect x="16" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="13" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="14" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="18" y="15" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="9" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="13" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="18" y="16" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="4" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="5" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="9" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="16" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="17" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="18" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="19" y="17" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="6" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="7" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="9" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="10" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#5f1d09ff"/><rect x="12" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#5f1d09ff"/><rect x="13" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#5f1d09ff"/><rect x="14" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="16" y="18" width="1" height="1" shape-rendering="crispEdges" fill="#fff68eff"/><rect x="8" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="9" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="15" y="19" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="8" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="9" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="11" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="13" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="14" y="20" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="8" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="9" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="12" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="13" y="21" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="8" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="9" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="8" y="23" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/><rect x="9" y="23" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="10" y="23" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="11" y="23" width="1" height="1" shape-rendering="crispEdges" fill="#ae8b61ff"/><rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'));

        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    /**
     * The Cryptopunk attributes for the given index.
     * The attributes are a comma-separated list in UTF-8 string format.
     * The first entry listed is not technically an attribute, but the "head type" of the Cryptopunk.
     * @param index the punk index, 0 <= index < 10000
     */
    // function punkAttributes(uint16 index) external view returns (string memory text) {
    //     require(index >= 0 && index < 10000);
    //     uint8 cell = uint8(index / 100);
    //     uint offset = (index % 100) * 8;
    //     for (uint j = 0; j < 8; j++) {
    //         uint8 asset = uint8(punks[cell][offset + j]);
    //         if (asset > 0) {
    //             if (j > 0) {
    //                 text = string(abi.encodePacked(text, ", ", assetNames[asset]));
    //             } else {
    //                 text = assetNames[asset];
    //             }
    //         } else {
    //             break;
    //         }
    //     }
    // }

    function punkAttributes(uint16 index) external view returns (string memory text) {
        require(index >= 0 && index < 10000);
        // uint8 cell = uint8(index / 100);
        // uint offset = (index % 100) * 8;
        // for (uint j = 0; j < 8; j++) {
        //     uint8 asset = uint8(punks[cell][offset + j]);
        //     if (asset > 0) {
        //         if (j > 0) {
        //             text = string(abi.encodePacked("Female 2, Spots, Wild White Hair, Clown Eyes Blue"));
        //         } else {
        //             text = assetNames[asset];
        //         }
        //     } else {
        //         break;
        //     }
        // }
        string memory text = string(abi.encodePacked("Female 2, Spots, Wild White Hair, Clown Eyes Blue"));
        return  text;

    }

    function composite(byte index, byte yr, byte yg, byte yb, byte ya) internal view returns (bytes4 rgba) {
        uint x = uint(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        if (xAlpha == 0xFF) {
            rgba = bytes4(uint32(
                    (uint(uint8(palette[x])) << 24) |
                    (uint(uint8(palette[x+1])) << 16) |
                    (uint(uint8(palette[x+2])) << 8) |
                    xAlpha
                ));
        } else {
            uint64 key =
                (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(xAlpha) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    }

    //// String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}